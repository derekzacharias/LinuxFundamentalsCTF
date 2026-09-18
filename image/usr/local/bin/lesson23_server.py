#!/usr/bin/env python3
# Lesson 23: HTTP server on 127.0.0.1:9099 that only answers
# when the request Host header is flag.service.local
import http.server, socketserver, sys

FLAG = "FLAG{lesson_23_net_operative}"

class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        host = self.headers.get("Host", "")
        if host.split(":")[0] != "flag.service.local":
            self.send_response(421)
            self.end_headers()
            self.wfile.write(b"Misdirected request: this service only answers for host flag.service.local\n")
            return
        self.send_response(200)
        self.end_headers()
        self.wfile.write((FLAG + "\n").encode())
    def log_message(self, fmt, *args):
        sys.stderr.write("lesson23: %s\n" % (fmt % args))

if __name__ == "__main__":
    with socketserver.TCPServer(("127.0.0.1", 9099), Handler) as srv:
        srv.serve_forever()
