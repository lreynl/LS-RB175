require 'yaml'
require 'tilt/erubis'
require 'sinatra'
require 'sinatra/reloader'

helpers do

end

get '/' do
  @user_list = YAML.load_file('users.yaml')
  @users = @user_list.keys
  
  erb :home
end

get '/users/'
