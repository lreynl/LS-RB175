require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/content_for'
require 'tilt/erubis'
require "redcarpet"
require "yaml"
require 'bcrypt'

enable :sessions

def files_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/files", __FILE__)
  else
    File.expand_path("../files", __FILE__)
  end
end

def render_markdown(md)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(md)
end

def valid_filename?(filename)
  if filename.empty?
    session[:message] = "A file name is required."
    return false
  elsif File.extname(filename).empty?
    session[:message] = "A file extension is required."
    return false
  end
  true
end

def signed_in?
  session[:username] == "admin"
end

def valid_signin?(user, pw)
  users = YAML.load_file("users.yaml")
  users.key?(user) && BCrypt::Password.new(users[user]) == pw
  #user == "admin" && pw == "secret"
end

def must_be_signed_in
  unless signed_in?
    session[:message] = "You must be signed in to do that."
    redirect "/"
  end
end

get "/" do
  redirect "/signin" unless signed_in?
  @files = Dir.glob("#{files_path}/*.*")
  @files.map! { |file| File.basename(file) }
  
  erb :index, layout: :layout
end

get "/signin" do
  erb :signin
end

post "/signin/" do
  username = params[:username]
  password = params[:password]
  if valid_signin?(username, password)
    session[:username] = username
    session[:password] = password
    session[:message] = "Welcome!"
  else
    session[:message] = "Invalid user name or password."
  end
  redirect "/"
end

get "/files/:filename" do
  path = "#{params[:filename]}"
  path = File.join(files_path, path)
  if File.exist?(path)
    file = File.read(path)
    case File.extname(path)
    when ".txt"
      headers["Content-Type"] = "text/plain"
      file
    when ".md"
      headers["Content-Type"] = "text/html;charset=utf-8"
      render_markdown(file)
    end
  else
    session[:message] = "#{File.basename(path)} does not exist."
    redirect "/"
  end
end

get "/edit/:filename" do
  must_be_signed_in
  @path = "#{params[:filename]}"
  @path = File.join(files_path, @path)
  @filename = File.basename(@path)
  @text = File.read(@path)
  erb :edit, layout: :layout
end

get "/newfile" do
  must_be_signed_in
  erb :newfile
end

post "/newfile/" do
  must_be_signed_in
  filename = params[:filename]
  redirect "/newfile" unless valid_filename?(filename)
  path = File.join(files_path, filename)
  File.new(path, 'w')
  session[:message] = "#{filename} was created."
  redirect "/"
end

post "/:filename" do
  must_be_signed_in
  filename = params[:filename]
  path = "#{filename}"
  path = File.join(files_path, path)
  text = params[:text_box]
  File.open(path, "w") do |file| 
    file.puts(text) 
    file.close
  end
  session[:success] = filename + " was updated."
  redirect "/"
end 

post "/delete/:filename" do
  must_be_signed_in
  filename = params[:filename]
  path = File.join(files_path, filename)
  File.delete(path)
  session[:message] = "#{filename} was deleted."
  redirect "/"
end

post "/signout/" do
  session.delete(:username)
  session.delete(:password)
  session[:message] = "You have been signed out."
  redirect "/"
end
