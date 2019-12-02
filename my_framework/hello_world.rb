# hello_world.rb

require_relative 'advice'
require_relative 'methods'

class HelloWorld < MyMethods
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
end
