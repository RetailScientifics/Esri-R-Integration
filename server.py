import http.server, ssl

port = 8000

server_address = ('localhost', port)
httpd = http.server.HTTPServer(server_address, http.server.SimpleHTTPRequestHandler)
httpd.socket = ssl.wrap_socket(
    httpd.socket,
    server_side=True,
    certfile='server.pem',
    ssl_version=ssl.PROTOCOL_TLSv1
)
print( 'Now serving at https://localhost:%s' %(port) )
httpd.serve_forever()
