# methods for framework

class MyMethods
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
