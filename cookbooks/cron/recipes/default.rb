#
# Cookbook Name:: cron
# Recipe:: default
#

# Find all cron jobs specified in attributes/cron.rb where current node name matches instance_name
#crons = node[:custom_crons].find_all {|c| c[:instance_name] == "#{node[:name]}" }
crons = {}

crons.each do |cron|
  cron cron[:name] do
    user     node['owner_name']
    action   :create
    minute   cron[:time].split[0]
    hour     cron[:time].split[1]
    day      cron[:time].split[2]
    month    cron[:time].split[3]
    weekday  cron[:time].split[4]
    command  cron[:command]
  end
end

files = {
  'clean_rails_cache_dir.sh' => '/etc/cron.daily',
  'rake_cleanup_tmp.sh' => '/etc/cron.weekly',
  'rake_cleanup_sessions.sh' => '/etc/cron.weekly'
}

files.each do |template_name, destination_dir|
  node[:applications].keys.each do |app_name|
    template "#{destination_dir}/#{template_name}" do
      source "#{template_name}.erb"
      variables({
        app_dir: "/data/#{app_name}/current",
        cache_dir: "/data/#{app_name}/shared/tmp/cache",
        environment: node[:environment][:framework_env]
      })
      mode '0755'
    end
  end
end
