set :domain, 'beta.forset.ge'
set :user, 'deploy'
set :application, 'Budget-API'
# easier to use https; if you use ssh then you have to create key on server
set :repository, 'https://github.com/ForSetGeorgia/Georgian-Budget-API'
set :branch, 'master'
set :web_url, ENV['STAGING_WEB_URL']
set :visible_to_robots, false
set :use_ssl, true
