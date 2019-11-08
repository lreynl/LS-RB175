require "socket"

server = TCPServer.new("localhost", 3003)
loop do
  client = server.accept

  request_line = client.gets
  next if !request_line || request_line =~ /favicon/

  http_method, path_params, ver = request_line.split(' ')
  path, params = path_params.split('?')
  params = params.split('&')
  params = params.each_with_object({}) do |pair, obj|
    key, val = pair.split('=')
    obj[key] = val
  end

  client.puts "HTTP/1.1 200 OK"
  client.puts "Content-Type: text/html"
  client.puts
  #client.puts request_line
  client.puts "<html>"
  client.puts "<body>"
  client.puts "<pre>"
  client.puts "<h1>"
  client.puts params
  client.puts rand(6) + 1
  client.puts rand(6) + 1
  client.puts "</h1>"
  client.puts "</pre>"
  client.puts "</body>"
  client.puts "</html>"
  #puts request_line
  puts params
  client.close
end
