#
# Cookbook Name:: crontab_custom
# Recipe:: default
#

case node[:instance_role]
when 'app', 'app_master', 'solo'
  app_dir = "/data/#{node[:app_name]}/current"

  %w(rake_cleanup_tmp.sh rake_cleanup_sessions.sh).each do |shell_script|
    template "/etc/cron.weekly/#{shell_script}" do
      mode 755
      source "#{shell_script}.erb"
      variables({
        app_dir: app_dir
      })
    end
  end

end
