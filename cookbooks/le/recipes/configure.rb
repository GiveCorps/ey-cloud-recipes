#
# Cookbook Name:: le
# Recipe:: configure
#
#
env = node[:environment][:framework_env]

execute "le register --account-key" do
  command "le register --account-key #{node[:rails_config]['api_key']} --hostname #{node[:hostname]} --name #{node[:applications].keys.first}"
  action :run
  not_if { File.exists?('/etc/le/config') }
end

follow_paths = [
  "/var/log/syslog",
  "/var/log/auth.log",
  "/var/log/daemon.log",
  "/var/log/chef.custom.log",
  "/var/log/chef.main.log"
]

case node[:instance_role]
when 'app', 'app_master', 'solo'
  ["/var/log/nginx/passenger.log"].each { |file| follow_paths << file }

  (node[:applications] || []).each do |app_name, app_info|
    follow_paths << "/var/log/nginx/#{app_name}.access.log"
    follow_paths << "/var/log/nginx/#{app_name}.error.log"
    follow_paths << "/var/log/engineyard/apps/#{app_name}/oink.log"
    follow_paths << "/var/log/engineyard/apps/#{app_name}/production.log"
    follow_paths << "/var/log/engineyard/apps/#{app_name}/production_cron_tasks.log"
    follow_paths << "/var/log/engineyard/apps/#{app_name}/#{env}.log" unless env == 'production'
  end
when 'util'
  (node[:applications] || []).each do |app_name, app_info|
    %w(0 1 2 3 scheduler).each do |log_suffix|
      follow_paths << "/var/log/engineyard/apps/#{app_name}/resque_#{log_suffix}.log"
    end
  end
  ["/data/redis/redis.log"].each { |file| follow_paths << file }
when 'db_master', 'db_slave'
  [
    '/db/mysql/5.5/log/mysqld.err',
    '/db/mysql/5.5/log/slow_query.log'
  ].each { |file| follow_paths << file }
end

follow_paths.each do |path|
  execute "le follow #{path}" do
    command "le follow #{path}; true"
    ignore_failure true
    action :run
  end
end
