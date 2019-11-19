require 'tilt/erubis'
require "sinatra"
require "sinatra/reloader"

get "/" do
  @title = "The Adventures of Sherlock Holmes"
  #@toc = File.read("data/toc.txt").split("\n")
  @toc = File.readlines("data/toc.txt")
  erb :home
end

get "/chapters/:number" do
  number = params[:number]
  @toc = File.readlines("data/toc.txt")
  @title = "Chapter #{number}: #{@toc[number.to_i - 1]}"
  @chapter = File.read("data/chp#{number}.txt")
  erb :chapter
end