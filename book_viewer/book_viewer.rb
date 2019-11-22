require 'tilt/erubis'
require "sinatra"
require "sinatra/reloader"

set :bind, '0.0.0.0'

before do
  @toc = File.readlines("data/toc.txt")
end

helpers do
  def in_paragraphs(txt)
    txt = txt.split("\n\n")
    txt.map { |paragraph| "<p>#{paragraph}</p>" }.join
  end
  
  def make_link_list(hash)
    links_array = hash.map do |key, val|
      '<li><a href="data/chp#{key}">val</a></li>'
    end
    "<ul>" + links_array.join + "</ul>"
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

get "/search" do
  erb :search
end

get "/search/:query" do
  @query = params[:query]
  @search_results = {}
  (1..@toc.length).to_a.each do |chapter_number|
    chapter = File.read("data/chp#{number}.txt")
    @search_results[chapter_number] = @toc[chapter_number - 1] if chapter.include?(@query)
  end
  
  erb :search_results
end

not_found do
  redirect "/"
end
