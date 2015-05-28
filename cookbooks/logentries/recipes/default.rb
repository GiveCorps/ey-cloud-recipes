#
# Cookbook Name:: logentries
# Recipe:: default
#
# Adapted from the papertrail/loggly recipe
#
# This recipe configures an EngineYard Gentoo instance to send logs to Logentries (logentries.com).
# * rsyslog is used to monitor syslog

require 'yaml'

app_name = node[:applications].keys.first
env = node[:environment][:framework_env]
rails_config =  YAML::load_file(File.join(File.dirname(__FILE__), '../../../', 'cookbooks/api-keys-yml/templates/default/api-keys.yml.erb'))[env]["logentries"]
LOGENTRIES_CONFIG = {
  :env                       => env,
  :rsyslog_version           => '7.2.2-r1',
  :hostname                  => [app_name, node[:instance_role], `hostname`.chomp].join('_'),
}.merge!(rails_config.inject({}) {|config, (k,v)| config[k.to_sym] = v; config })

# Make sure you have the EngineYard "enable_package" recipe
enable_package 'app-admin/rsyslog' do
  version LOGENTRIES_CONFIG[:rsyslog_version]
  override_hardmask true
end

package 'app-admin/rsyslog' do
  version LOGENTRIES_CONFIG[:rsyslog_version]
  action :install
end

if %w(app app_master solo util).include?(node[:instance_role])
  template '/etc/rsyslog.d/22-rails-logentries.conf' do
    source 'rails-logentries.conf.erb'
    mode '0644'
    variables({
      oink_token: rails_config["oink"]["token"],
      cron_token: rails_config["cron"]["token"],
      syslog_token: rails_config["syslog"]["token"],
      nginx_token: rails_config["nginx"]["token"],
      passenger_token: rails_config["passenger"]["token"],
    })
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
