#
# Cookbook Name:: nginx_custom
# Recipe:: default
#

if (['app_master', 'app'].include?(node[:instance_role]))
  node[:engineyard][:environment][:apps].each do |app|
    template "/etc/nginx/servers/#{app[:name]}/custom.conf" do
      source 'custom.conf.erb'
      owner node[:users][0][:username]
      group node[:users][0][:username]
      mode 0644
    end

    execute "sudo /etc/init.d/nginx reload"
  end
end
