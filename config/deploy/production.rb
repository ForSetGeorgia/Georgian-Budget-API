set :domain, 'delta.jumpstart.ge'
set :user, 'budget'
set :application, 'Budget-API-Production'
# easier to use https; if you use ssh then you have to create key on server
set :repository, 'https://github.com/ForSetGeorgia/Georgian-Budget-API'
set :branch, 'master'
set :web_url, ENV['PRODUCTION_WEB_URL']
set :use_ssl, true
set :puma_worker_count, '2'
set :puma_thread_count_min, '1'
set :puma_thread_count_max, '8'
