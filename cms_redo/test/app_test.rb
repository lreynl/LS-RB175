ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"
require "fileutils"

require_relative "../cms"

class AppTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def session
    last_request.env["rack.session"]
  end
  
  def setup
    FileUtils.mkdir_p(files_path)
  end
  
  def teardown
    FileUtils.rm_rf(files_path)
  end

  def admin_session
    { "rack.session" => { username: "admin" } }
  end
  
  def create_file(name, content = "")
    File.open(File.join(files_path, name), "w") do |file|
      file.write(content)
    end
  end
    
  def test_index
    create_file "about.md"
    create_file "about.txt"
    get "/", {}, admin_session
    assert_equal 200, last_response.status
    assert_equal last_response["Content-Type"], "text/html;charset=utf-8"
    assert_includes last_response.body, "about.txt"
    assert_includes last_response.body, "about.md"
  end

  def test_not_exist
    get "/files/stuff.txt", {}, admin_session
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_equal 200, last_response.status
    assert_includes last_response.body, "stuff.txt does not exist"

    get "/"
    refute_includes last_response.body, "stuff.txt does not exist"
  end

  def test_md
    create_file("example.md", "<h1>Heading</h1>")   
    get "/files/example.md"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "<h1>Heading</h1>"
    assert_equal last_response["Content-Type"], "text/html;charset=utf-8"
  end

  def test_edit
    get "/", {}, admin_session
    create_file("about.txt")
    get "edit/about.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, '<form action='
  end

  def test_update
    create_file("about.txt")
    get "/", {}, admin_session
    post "/about.txt", text_box: "new stuff"
    assert_equal 302, last_response.status

    #get last_response["Location"]
    #assert_equal 200, last_response.status
    #assert_includes last_response.body, "about.txt was updated"
    assert_includes session[:success], "about.txt was updated"

    get "/files/about.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "new stuff"
  end

  def test_newfile_form
    get "/", {}, admin_session
    get "/newfile"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "Add a new document"
    assert_includes last_response.body, "<input type="
  end

  def test_make_newfile
    get "/", {}, admin_session
    post "/newfile/", filename: "testing.txt"
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_equal 200, last_response.status
    assert_includes last_response.body, "testing.txt was created"

    get "/"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "testing.txt"
    refute_includes last_response.body, "was created"
  end

  def test_empty_filename
    get "/", {}, admin_session
    post "/newfile/", filename: ""
    assert_equal 302, last_response.status

    #get last_response["Location"]
    #assert_equal 200, last_response.status
    #assert_includes last_response.body, "A file name is required"
    assert_includes session[:message], "A file name is required"
  end

  def test_no_file_extension
    get "/", {}, admin_session
    post "/newfile/", filename: "stuff_and_things"
    assert_equal 302, last_response.status

    #get last_response["Location"]
    #assert_equal 200, last_response.status
    #assert_includes last_response.body, "A file extension is required"
    assert_includes session[:message], "A file extension is required"
  end

  def test_delete
    create_file("delete_me.txt")
    post "/delete/delete_me.txt", {}, admin_session
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_includes last_response.body, "delete_me.txt was deleted"
    #assert_includes session[:message], "delete_me.txt was deleted"

    get "/"
    assert_equal 200, last_response.status
    refute_includes last_response.body, "delete_me.txt"
  end

  def test_not_signed_in
    get "/"
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_includes last_response.body, "<form style="
    assert_includes last_response.body, "User name"
  end

  def test_invalid_signin  
    post "/signin/", username: "admin", password: "stuffandthings"
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_equal 302, last_response.status
    #assert_includes last_response.body, "Invalid user name or password"
    #assert_includes last_response.body, "<form style="
    #assert_includes last_response.body, "User name"

    post "/signin/", username: "", password: ""
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_equal 302, last_response.status
    get last_response["Location"]
    assert_includes last_response.body, "Invalid user name or password"
    assert_includes last_response.body, "<form style="
    assert_includes last_response.body, "User name"
    
    post "/signin/", username: "", password: "secret"
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_equal 302, last_response.status
    get last_response["Location"]
    assert_includes last_response.body, "Invalid user name or password"
    assert_includes last_response.body, "<form style="
    assert_includes last_response.body, "User name"
  end

  def test_edit_not_signed_in
    post "/test.txt", text_box: "new stuff"
    assert_equal 302, last_response.status

    assert_includes session[:message], "You must be signed in to do that"
  end

  def test_edit_page_not_signed_in
    get "/edit/test.txt"
    assert_equal 302, last_response.status

    assert_includes session[:message], "You must be signed in to do that"
  end

  def test_delete_not_signed_in
    post "/delete/test.txt"
    assert_equal 302, last_response.status

    assert_includes session[:message], "You must be signed in to do that"
  end

  def test_newfile_not_signed_in
    post "/newfile", filename: "test.txt"
    assert_equal 302, last_response.status

    assert_includes session[:message], "You must be signed in to do that"
  end

  def test_newfile_page_not_signed_in
    get "/newfile"
    assert_equal 302, last_response.status

    assert_includes session[:message], "You must be signed in to do that"
  end
end

    