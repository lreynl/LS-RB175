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

get "/" do
  @files = Dir["./files/*.*"]
  @files.map! { |file| file.split("/")[-1] }
  erb :file_list#, layout: :layout
end

get "/:filename" do
  @name = "files/" + params[:filename]
  #@text = ""
  if File.exist?(@name)
    #@text = File.readlines(name)
    erb :view_text #, layout: :layout
  else
    session[:not_found] = "#{params[:filename]} not found."
    redirect "/"
  end
end