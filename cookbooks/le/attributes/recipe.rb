rails_config(YAML::load_file(File.join(File.dirname(__FILE__), '../../../', 'cookbooks/api-keys-yml/templates/default/api-keys.yml.erb'))[node[:environment][:framework_env]]["logentries"])
# Read more at https://logentries.com/doc/engineyard/
