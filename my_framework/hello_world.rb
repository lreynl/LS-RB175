# hello_world.rb

require_relative 'advice'

class HelloWorld
  def call(env)
    case env['REQUEST_PATH']
    when '/'
      status = '200'
      headers = {"Content-Type" => 'text/html'}
      response(status, headers) do
        erb(:index)
      end
    when '/advice'
      some_advice = Advice.new.generate
      status = '200'
      headers = {"Content-Type" => 'text/html'}
      response(status, headers) do
        erb(:advice, {message: some_advice})
      end
    else
      not_found_text = erb(:not_found)
      status = '404'
      headers = {"Content-Type" => 'text/html', "Content-Length" => "#{not_found_text.length}"}
      response(status, headers) do
        not_found_text
      end
    end
  end

  private

  def erb(file_name, local = {})
    b = binding
    message = local[:message]
    content = File.read("views/#{file_name}.erb")
    ERB.new(content).result(b)
  end

  def response(status, headers, body = '')
    body = yield if block_given?
    [status, headers, [body]]
  end
end
