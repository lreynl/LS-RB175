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

get "/" do
  @files = Dir.glob("#{files_path}/*.*")
  @files.map! { |file| File.basename(file) }
  
  erb :index, layout: :layout
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
  @path = "#{params[:filename]}"
  @path = File.join(files_path, @path)
  @filename = File.basename(@path)
  @text = File.read(@path)
  erb :edit, layout: :layout
end

post "/:filename" do
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