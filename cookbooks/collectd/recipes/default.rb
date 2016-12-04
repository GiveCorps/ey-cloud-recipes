#
# Cookbook Name:: collectd
# Recipe:: default
#

case node[:instance_role]
when 'util'
  load_thresholds = { :warning => 9, :failure => 15 }
else
  load_thresholds = { :warning => 8, :failure => 10 }
end

collectd 'default' do
  load load_thresholds
  db_space ['1.3GB', '500MB']
  data_space [3000000000, 1500000000]
  root_space :warning => '1245MB', :failure => '500MB'
  mnt_space :warning => 400000, :failure => 200000
end