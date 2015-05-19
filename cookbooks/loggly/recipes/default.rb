#
# Cookbook Name:: loggly
# Recipe:: default
#
# Adapted from the papertrail recipe
#
# This recipe configures an EngineYard Gentoo instance to send logs to Loggly (loggly.com).
# * rsyslog is used to monitor syslog

require 'yaml'

rails_config =  YAML::load_file(File.join(File.dirname(__FILE__), '../../../', 'cookbooks/api-keys-yml/templates/default/api-keys.yml.erb'))["defaults"]["loggly"]
app_name = node[:applications].keys.first
env = node[:environment][:framework_env]
LOGGLY_CONFIG = {
  :env                       => env,
  :rsyslog_version           => '7.2.2-r1',
  :hostname                  => [app_name, node[:instance_role], `hostname`.chomp].join('_'),
}.merge!(rails_config.inject({}) {|config, (k,v)| config[k.to_sym] = v; config })

# EngineYard Gentoo Portage only recently added a new version of syslog-ng, so you have to update it even on new instances
execute 'get-latest-portage' do
  command 'emerge --sync'
end

# Make sure you have the EngineYard "enable_package" recipe
enable_package 'app-admin/rsyslog' do
  version LOGGLY_CONFIG[:rsyslog_version]
  override_hardmask true
end

package 'app-admin/rsyslog' do
  version LOGGLY_CONFIG[:rsyslog_version]
  action :install
end

# Loggly setup script

remote_file '/home/deploy/loggly-configure-linux.sh' do
  source 'https://www.loggly.com/install/configure-linux.sh'
  checksum '5cc00ca4dad7fb8014db9ee1831e4401'
  mode '0755'
end

if %w(app app_master solo util).include?(node[:instance_role])
  template '/etc/rsyslog.d/21-rails.conf' do
    source 'rails.conf.erb'
    mode '0644'
    variables(LOGGLY_CONFIG)
  end
end

# EngineYard Gentoo instances use sysklogd by default
execute 'stop-sysklogd' do
  command %{/etc/init.d/sysklogd stop}
  ignore_failure true
end

execute 'restart-rsyslog' do
  command %{sudo kill -9 `pidof rsyslogd`; sudo /etc/init.d/rsyslog stop; sudo /etc/init.d/rsyslog start}
end

execute 'configure-loggly' do
  command %{sudo bash /home/deploy/loggly-configure-linux.sh -s -a '#{LOGGLY_CONFIG[:account]}' -t '#{LOGGLY_CONFIG[:token]}' -u '#{LOGGLY_CONFIG[:user]}' -p '#{LOGGLY_CONFIG[:password]}' >>/tmp/loggly.log}
end
