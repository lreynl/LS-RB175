ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"
require "erubis"

require_relative "../cms"

class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_index
    get "/"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "about.txt"
    assert_includes last_response.body, "history.txt"
    assert_includes last_response.body, "changes.txt"
  end

  def test_history
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
    get "/example.md"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "<h1>Heading</h1>"
    assert_includes last_response.body, "<h2>Sub-heading</h2>"
    assert_includes last_response.body, "<code>monospace</code>"
  end

  def test_edit
    get "/edit/about.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, '<textarea name='
  end

  def test_update
    post "/about.txt", content: "new content"
    assert_equal 302, last_response.status
    
    get last_response["Location"]
    assert_includes last_response.body, "about.txt was updated"

    #get "/about.txt"
    #assert_equal 200, last_response.status
    #assert_includes last_response.body, "new content"
  end
end