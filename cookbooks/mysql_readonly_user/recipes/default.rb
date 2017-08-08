#
# Cookbook Name:: mysql_readonly_user
# Recipe:: default
#


reporting_user = 'reporting'
app = node['engineyard']['environment']['apps'].first
database_name = app['database_name']
database_username = 'root'
database_password = app['database_password']
sql = <<-EOL
GRANT SELECT ON *.* TO #{reporting_user} IDENTIFIED BY '!0QpalKsow92';
EOL

if node[:instance_role] == 'db_master'
  user_exists = `mysql -u #{database_username} --password=#{database_password} -n -s -e 'SELECT EXISTS(SELECT 1 FROM mysql.user WHERE user = "#{reporting_user}");'`
  unless user_exists.strip == 1.to_s
    execute "mysql" do
      command %Q{mysql -u #{database_username} --password=#{database_password} -e "#{sql}"}
    end
  end
end
