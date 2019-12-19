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
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "1993 - Yukihiro Matsumoto dreams up Ruby."
  end

  def test_not_found
    get "/testing.txt"
    assert_equal 302, last_response.status
    get last_response["Location"]
    assert_equal 200, last_response.status
    assert_includes last_response.body, "testing.txt not found"
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
  
    get last_response["Location"]
      
    assert_includes last_response.body, "changes.txt was updated"
      
    get "/changes.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "new content"
  end
end