require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/content_for'
require 'tilt/erubis'
require "redcarpet"

enable :sessions

helpers do
  def render_markdown(md)
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    markdown.render(md)
  end
end

def files_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/files", __FILE__)
  else
    File.expand_path("../files", __FILE__)
  end
end

get "/" do
  if session[:username] == "admin" && session[:password] == "secret"
    @user = session[:username]
    path = files_path + "*.*"
    @files = Dir["./files/*.*"]
    @files.map! { |file| file.split("/")[-1] }
    erb :file_list#, layout: :layout
  elsif session[:signedin] == false
    session[:success] = "You have been signed out."
    redirect "/users/signin"
  else
    session[:not_found] = "Username or password is invalid."
    redirect "/users/signin"
  end
end

get "/users/signin" do
  erb :login
end

get "/:filename" do
  @name = File.join(files_path, params[:filename])
  if File.exist?(@name)
    text = File.read(@name)
    case File.extname(@name)
    when ".txt"
      headers["Content-Type"] = "text/plain"
      text
    when ".md"
      erb render_markdown(text)
    end
  else
    session[:not_found] = "#{params[:filename]} not found."
    redirect "/"
  end
end

get "/edit/:filename" do
  @filename = params[:filename]
  path = File.join(files_path, @filename)
  @text = File.read(path)
  erb :edit
end

get "/newfile/" do
  erb :new_file
end

post "/users/signin" do
  session[:username] = params[:username]
  session[:password] = params[:password]
  session[:signedin] = true
  redirect "/"
  #params.to_s
end

post "/logout/" do
  session.delete(:username)
  session.delete(:password)
  session[:signedin] = false
  redirect "/"
end

post "/createfile/" do
  filename = params[:filename]
  if filename.empty?
    session[:error] = "A name is required."
    redirect "/newfile/"
  elsif File.extname(filename).empty?
    session[:error] = "A file extension is required."
    redirect "/newfile/"
  else
    path = File.join(files_path, filename)
    File.open(path, "w") {}
    session[:success] = filename + " was created."
    redirect "/"
  end
end

post "/:filename" do
  filename = params[:filename]
  path = File.join(files_path, filename)
  text = params[:content] || params[:text_box]
  File.open(path, "w") do |file| 
    file.puts(text) 
    file.close
  end
  session[:success] = filename + " was updated."
  redirect "/"
end

post "/delete/" do
  filename = params[:filename]
  path = File.join(files_path, filename)
  File.delete(path)
  session[:success] = filename + " was deleted."
  redirect "/"
end
