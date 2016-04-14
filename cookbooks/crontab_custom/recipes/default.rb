#
# Cookbook Name:: crontab_custom
# Recipe:: default
#

case node[:instance_role]
when 'app', 'app_master', 'solo'
  node[:applications].each do |app_name, data|
    %w(rake_cleanup_tmp.sh).each do |shell_script|
      template "/etc/cron.daily/#{shell_script}" do
        mode 0755
        source "#{shell_script}.erb"
        variables({
          app_dir: "/data/#{app_name}/current",
          environment: node[:environment][:framework_env]
        })
      end
    end

    %w(rake_cleanup_sessions.sh).each do |shell_script|
      template "/etc/cron.weekly/#{shell_script}" do
        mode 0755
        source "#{shell_script}.erb"
        variables({
          app_dir: "/data/#{app_name}/current",
          environment: node[:environment][:framework_env]
        })
      end
    end
  end
end
