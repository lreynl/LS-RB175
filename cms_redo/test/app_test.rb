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
  
  def setup
    FileUtils.mkdir_p(files_path)
  end
  
  def teardown
    FileUtils.rm_rf(files_path)
  end
  
  def create_file(name, content = "")
    File.open(File.join(files_path, name), "w") do |file|
      file.write(content)
    end
  end
    
  def test_index
    create_file "about.md"
    create_file "about.txt"
    get "/"
    assert_equal 200, last_response.status
    assert_equal last_response["Content-Type"], "text/html;charset=utf-8"
    assert_includes last_response.body, "about.txt"
    assert_includes last_response.body, "about.md"
  end

  def test_not_exist
    get "/files/stuff.txt"
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
    create_file("about.txt")
    get "edit/about.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, '<form action='
  end

  def test_update
    create_file("about.txt")
    post "/about.txt", text_box: "new stuff"
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_equal 200, last_response.status
    assert_includes last_response.body, "about.txt was updated"

    get "/files/about.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "new stuff"
  end
end

    