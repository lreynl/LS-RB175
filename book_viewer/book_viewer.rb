require 'tilt/erubis'
require "sinatra"
require "sinatra/reloader"

before do
  @toc = File.readlines("data/toc.txt")
end

helpers do
  def in_paragraphs(txt)
    txt = txt.split("\n\n")
    txt.map { |paragraph| "<p>#{paragraph}</p>" }.join
  end
end

get "/" do
  @title = "The Adventures of Sherlock Holmes"
  erb :home
end

get "/chapters/:number" do
  number = params[:number].to_i
  redirect "/" unless (1..@toc.length).cover? number
  @title = "Chapter #{number}: #{@toc[number - 1]}"
  @chapter = File.read("data/chp#{number}.txt")
  erb :chapter
end

get "/search/:query" do
  query = params[:query]
  search_results = []
  (1..@toc.length).to_a.each do |chapter_number|
    chapter = File.read("data/chp#{number}.txt")
    search_results << @toc[chapter_number - 1] if chapter.include?(query)
  end
  
  erb :search
end

not_found do
  redirect "/"
end
