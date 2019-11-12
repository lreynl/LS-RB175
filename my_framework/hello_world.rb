# hello_world.rb

require_relative 'advice'

class HelloWorld
  def call(env)
    case env['REQUEST_PATH']
    when '/'
      ['200', {"Content-Type" => 'text/html'}, [erb(:index)] ]
    when '/advice'
      some_advice = Advice.new.generate
      ['200', {"Content-Type" => 'text/html'}, 
      [erb(:advice, message: some_advice)]
      ]
    else
      not_found_text = erb(:not_found)
      [
        '404',
        {"Content-Type" => 'text/html', "Content-Length" => "#{not_found_text.length}"},
        ["#{not_found_text}"]
      ]
    end
  end

  private

  def erb(file_name, local = {})
    b = binding
    message = local[:message]
    content = File.read("views/#{file_name}.erb")
    ERB.new(content).result(b)
  end
end
