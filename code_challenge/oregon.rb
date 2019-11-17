require 'tilt/erubis'
require "sinatra"
require "sinatra/reloader"

get '/' do
  @files = Dir.glob('public/*.*')
  @title = "Some Things in Oregon"
  @sort_order = params['sort']
  @sort_order = 'ascending' if @sort_order.nil?
  if @sort_order == 'ascending'
    @files.sort! do |a, b|
      a <=> b
    end
  else
    @files.sort! do |a, b|
      b <=> a
    end
  end
  erb :home
end

get '/files/trees' do
  @files = File.readlines("public/trees.txt")
  @title = "Trees"
  erb :file
end

get '/files/rocks' do
  @files = File.readlines("public/rocks.txt")
  @title = "Rocks"
  erb :file
end

get '/files/mammals' do
  @files = File.readlines("public/mammals.txt")
  @title = "Mammals"
  erb :file
end

get '/files/fish' do
  @files = File.readlines("public/fish.txt")
  @title = "Fish"
  erb :file
end

get '/files/reptiles' do
  @files = File.readlines("public/reptiles.txt")
  @title = "Reptiles"
  erb :file
end
