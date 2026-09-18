#!/usr/bin/env python3
import http.server, urllib.parse, sys

LOG = "/var/log/lesson12_access.log"

class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path != "/flag":
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b"Not Found\n")
            return
        qs = urllib.parse.parse_qs(parsed.query)
        token = qs.get("token", [""])[0]
        resp = b"Unauthorized\n"
        code = 401
        if token == "lesson12":
            resp = b"FLAG{lesson_12_network_ready}\n"
            code = 200
        self.send_response(code)
        self.end_headers()
        self.wfile.write(resp)
        try:
            with open(LOG, "a") as f:
                f.write(f"path={parsed.path} token={token} code={code}\n")
        except Exception as e:
            sys.stderr.write(str(e)+"\n")

if __name__ == "__main__":
    http.server.HTTPServer(("127.0.0.1", 8080), Handler).serve_forever()

