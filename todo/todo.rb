require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubis"

set :bind, '0.0.0.0'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  session[:lists] ||= []
end

helpers do
  def list_complete?(list)
    list[:todos].size > 0 && list[:todos].all? { |todo| todo[:completed] }
  end

  def list_class(list)
    "complete" if list_complete?(list)
    
  end

  def todos_remaining_count(list)
    list[:todos].select { |todo| todo[:completed] }.size.to_s
  end

  def sort_list(lists, &block)
    complete_lists, incomplete_lists = lists.partition { |list| list_complete?(list) }
    incomplete_lists.each { |list| yield list, lists.index(list) }
    complete_lists.each { |list| yield list, lists.index(list) }
  end

  def sort_todos(todos, &block)
    complete_todos, incomplete_todos = todos.partition { |todo| todo[:completed] }
    incomplete_todos.each { |todo| yield todo, todos.index(todo) }
    complete_todos.each { |todo| yield todo, todos.index(todo) }
  end

end

get "/" do
  redirect "/lists"
end

get "/lists" do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

get "/lists/new" do
  erb :new_list, layout: :layout
end

get "/lists/:id" do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]
  erb :list, layout: :layout
end

get "/lists/:id/edit" do
  id = params[:id].to_i
  @list = session[:lists][id]
  erb :edit_list, layout: :layout
end 

post "/lists/:id" do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  id = params[:id].to_i
  @list = session[:lists][id]
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    @list[:name] = list_name
    session[:success] = "The list has been updated."
    redirect "/lists/#{id}"
  end
end

post "/lists/:id/delete" do
  id = params[:id].to_i
  session[:lists].delete_at(id)
  session[:success] = "List was deleted."
  redirect "/lists"
end

def error_for_todo_name(text)
  if !(1..100).cover? text.length
    "Todo name must be between 1 and 100 characters"
  end  
end

def error_for_list_name(name)
  if !(1..100).cover? name.length
    "List name must be between 1 and 100 characters"
  elsif session[:lists].any? { |list| list[:name] == name }
    "List name must be unique"
  end
end

post "/lists" do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = "The list has been created."
    redirect "/lists"
  end
end

post "/lists/:list_id/todos" do
  @list_id = params[:list_id].to_i || params[:id].to_i
  text = params[:todo].strip
  @list = session[:lists][@list_id]
  error = error_for_todo_name(text)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    session[:lists][@list_id][:todos] << { name: text, completed: false } 
    session[:success] = "Todo item has been added."
    redirect "/lists/#{@list_id}"
  end
end

post "/lists/:list_id/delete_todo/:todo_id" do
  list_id = params[:list_id].to_i
  todo_id = params[:todo_id].to_i
  deleted = session[:lists][list_id][:todos].delete_at(todo_id)[:name]
  session[:success] = "Todo '#{deleted}' was deleted"
  redirect "/lists/#{list_id}"
end

post "/lists/:list_id/toggle/:todo_id" do
  list_id = params[:list_id].to_i
  todo_id = params[:todo_id].to_i
  is_completed = params[:completed] == 'true'
  session[:lists][list_id][:todos][todo_id][:completed] = is_completed
  session[:success] = "Todo has been updated"
  redirect "/lists/#{list_id}"
end

post "/lists/:list_id/complete_all" do
  list_id = params[:list_id].to_i
  session[:lists][list_id][:todos].each do |todo_item|
    todo_item[:completed] = true
  end
  session[:success] = "All todos have been completed."
  redirect "/lists/#{list_id}"
end