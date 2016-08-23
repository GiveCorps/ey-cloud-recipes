#
# Cookbook Name:: le
# Recipe:: configure
#
#
env = node[:environment][:framework_env]
rails_config = node[:config_hash]['defaults'].deep_merge(node[:config_hash][env])

template '/etc/le/config' do
	source 'config.erb'
	variables({
		user_key: rails_config['logentries']['api_key'],
		agent_key: rails_config['logentries']['agent_key'],
	})
	mode '0644'
end

execute "le register --account-key" do
  command "le register --account-key #{rails_config['logentries']['api_key']} --hostname #{node[:hostname]} --name #{node[:applications].keys.first} --force"
  action :run
  not_if { File.exists?('/etc/le/config') }
end

follow_paths = [
  "/var/log/syslog",
  "/var/log/auth.log",
  "/var/log/daemon.log",
]

case node[:instance_role]
when 'app', 'app_master', 'solo'
  ["/var/log/nginx/passenger.log"].each { |file| follow_paths << file }

  (node[:applications] || []).each do |app_name, app_info|
    follow_paths << "/var/log/nginx/#{app_name}.error.log"
    case env
    when 'production'
      follow_paths << "/var/log/engineyard/apps/#{app_name}/production.log"
      follow_paths << "/var/log/engineyard/apps/#{app_name}/production_cron_tasks.log"
    else
      follow_paths << "/var/log/engineyard/apps/#{app_name}/#{env}.log"
    end
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
    not_if "le followed #{path}"
  end
end
