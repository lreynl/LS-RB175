# hello_world.rb

require_relative 'advice'

class HelloWorld
  def call(env)
    case env['REQUEST_PATH']
    when '/'
      ['200', {"Content-Type" => 'text/html'}, [erb(:index)] ]
    when '/advice'
      some_advice = Advice.new.generate
      ['200', {"Content-Type" => 'text/html'}, ["<html><body><b><em>#{some_advice}</em></b></body></html>"]]
    else
      not_found_text = "<html><body><h4>404 Not Found</h4></body></html>"
      [
        '404',
        {"Content-Type" => 'text/html', "Content-Length" => "#{not_found_text.length}"},
        ["#{not_found_text}"]
      ]
    end
  end
  #def call(env)
  #  ['200', {'Content-Type' => 'text/plain'}, ["Hello World!"]]
  #end

  private

  def erb(file_name)
    template = File.read("views/#{file_name}.erb")
    ERB.new(template).result
  end
end
