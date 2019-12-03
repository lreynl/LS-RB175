require 'yaml'
require 'tilt/erubis'
require 'sinatra'
require 'sinatra/reloader'

set :bind, '0.0.0.0'

helpers do

end

get '/' do
  @user_list = YAML.load_file('users.yaml')
  @users = @user_list.keys
  
  erb :home
end

get '/users/:user' do
  redirect '/' unless params[:user]
  @info = @user_list[:user]
  @user = :user
  erb :info
end

not_found do
  redirect '/'
end