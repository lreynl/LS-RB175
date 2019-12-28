ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"
require "erubis"
require "fileutils"

require_relative "../cms"

class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    FileUtils.mkdir_p(files_path)
  end

  def teardown
    FileUtils.rm_rf(files_path)
  end

  def create_document(name, text = "")
    File.open(File.join(files_path, name), 'w') { |file| file.write(text) }
  end

  def session
    last_request.env["rack.session"]
  end

  def test_index
    create_document "example.md"
    create_document "about.txt"
    
    get "/"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "about.txt"
    assert_includes last_response.body, "history.txt"
    assert_includes last_response.body, "changes.txt"
  end

  def test_history
    create_document "history.txt", "1993 - Yukihiro Matsumoto dreams up Ruby."
    get "/history.txt"
    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["Content-Type"]
    assert_includes last_response.body, "1993 - Yukihiro Matsumoto dreams up Ruby."
  end

  def test_not_found
    get "/testing.txt"
    assert_equal 302, last_response.status
    
    assert_equal "testing.txt not found.", session[:not_found]
    
    get "/"
    refute_includes last_response.body, "testing.txt not found"
  end

  def test_md
    create_document "example.md", "<h1>Heading</h1><h2>Sub-heading</h2><code>monospace</code>"
    get "/example.md"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "<h1>Heading</h1>"
    assert_includes last_response.body, "<h2>Sub-heading</h2>"
    assert_includes last_response.body, "<code>monospace</code>"
  end

  def test_edit
    create_document "about.txt", '<textarea name='
    get "/edit/about.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, '<textarea name='
  end

  def test_updating_document
    create_document "changes.txt"
    post "/changes.txt", content: "new content"
  
    assert_equal 302, last_response.status
    assert_equal "changes.txt was updated.", session[:success]
    
    get "/changes.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "new content"  
  end

  def test_newfile_form
    get "/newfile/"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "<form action="
  end

  def test_empty_filename
    post "/createfile/", filename: ""
    assert_equal 302, last_response.status

    get last_response["Location"]

    assert_equal 200, last_response.status
    assert_includes last_response.body, "A name is required"
  end

  def test_create_new_file
    post "/createfile/test.txt"#, filename: "test.txt"
    assert_equal 302, last_response.status

    assert_includes session[:success], "test.txt was created"

    get "/"
    assert_includes last_response.body, "test.txt"
  end

  def test_empty_extension
    post "/createfile/", filename: "a_new_file"
    assert_equal 302, last_response.status

    get last_response["Location"]

    assert_equal 200, last_response.status
    assert_includes last_response.body, "A file extension"
  end

  def test_delete_file
    create_document "some_file.txt", "placeholder"

    post "/delete/", filename: "some_file.txt"
    assert_equal 302, last_response.status

    get last_response["Location"]

    assert_equal 200, last_response.status
    assert_includes last_response.body, "some_file.txt was deleted"

    get "/"
    assert_equal 200, last_response.status
    refute_includes last_response.body, "some_file.txt"
  end

  def test_signin
    post "/users/signin", username: "admin", password: "secret"
    assert_equal 302, last_response.status
    assert_equal "Welcome!", session[:message]
    assert_equal "admin", session[:username]

    get last_response["Location"]
    assert_includes last_response.body, "Signed in as admin"
  end



  def test_signin_with_bad_credentials
    post "/users/signin", username: "guest", password: "shhhh"
    assert_equal 422, last_response.status
    assert_nil session[:username]
    assert_includes last_response.body, "is invalid"
  end

  def test_signout
    get "/", {}, {"rack.session" => { username: "admin" } }
    assert_includes last_response.body, "Signed in as admin"

    post "/users/signout"
    assert_equal "You have been signed out", session[:message]

    get last_response["Location"]
    assert_nil session[:username]
    assert_includes last_response.body, "Sign In"
  end

  def test_editing_document_signed_out
    create_document "changes.txt"

    get "/changes.txt/edit"

    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:message]
  end

  def test_updating_document_signed_out
    post "/changes.txt", {content: "new content"}

    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:message]
  end

  def test_view_new_document_form_signed_out
    get "/newfile"

    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:message]
  end
  
  def test_create_new_document_signed_out
    post "/create", {filename: "test.txt"}

    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:message]
  end
  
  def test_deleting_document_signed_out
    create_document("test.txt")

    post "/test.txt/delete"
    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:message]
  end
end