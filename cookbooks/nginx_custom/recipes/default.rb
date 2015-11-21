#
# Cookbook Name:: nginx_custom
# Recipe:: default
#

def create_custom_nginx_template(filename)
  node[:engineyard][:environment][:apps].each do |app|
    template "/etc/nginx/servers/#{app[:name]}/#{filename}" do
      source "#{filename}".erb
      owner node[:users][0][:username]
      group node[:users][0][:username]
      mode 0644
    end
  end
end

if (['app_master', 'app', 'solo'].include?(node[:instance_role]))
  %w(custom.conf custom.ssl.conf).each do |filename|
    create_custom_nginx_template(filename)
  end

  execute "sudo /etc/init.d/nginx reload"
end


