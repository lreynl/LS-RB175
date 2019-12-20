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
  path = files_path + "*.*"
  @files = Dir["./files/*.*"]
  @files.map! { |file| file.split("/")[-1] }
  erb :file_list#, layout: :layout
end

get "/:filename" do
  #@name = "files/" + params[:filename]
  #@name = File.join(files_path, params[:filename])
  @name = File.join(files_path, params[:filename])
  if File.exist?(@name)
    erb :view_text #, layout: :layout
  else
    session[:not_found] = "#{params[:filename]} not found."
    redirect "/"
    #erb @name
  end
end

get "/edit/:filename" do
  @filename = params[:filename]
  path = File.join(files_path, @filename)
  @text = File.read(path)
  erb :edit
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