#
# Cookbook Name:: crontab_custom
# Recipe:: default
#

case node[:instance_role]
when 'app', 'app_master', 'solo'
  %w(rake_cleanup_tmp.sh rake_cleanup_sessions.sh).each do |shell_script|
    template "/etc/cron.weekly/#{shell_script}" do
      mode 0755
      source "#{shell_script}.erb"
      variables({
        app_dir: "/data/#{node[:app_name]}/current"
      })
    end
  end

end
