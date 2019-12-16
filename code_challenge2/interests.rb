require 'yaml'
require 'tilt/erubis'
require 'sinatra'
require 'sinatra/reloader'

set :bind, '0.0.0.0'

before do
  @user_list = YAML.load_file('users.yaml')
end

helpers do
  def count_interests
    interest_count = 0
    users = @user_list.keys
    users.each { |user| interest_count += @user_list[user][:interests].length }
    { "user_count" => @user_list.keys.length,
      "interest_count" => interest_count }
  end
end

get '/' do
  @users = @user_list.keys
  erb :home
end

get '/users/:user' do
  redirect '/' unless params[:user]
  @name = params[:user]
  @info = @user_list[@name.to_sym]
  erb :info
end

not_found do
  redirect '/'
end