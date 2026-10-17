import http.server
import socketserver
import os
import sys

PORT = 3000
WEB_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), 'build', 'web'))

class SPAHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=WEB_DIR, **kwargs)

    def end_headers(self):
        # Enable CORS and caching headers for local development
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'X-Requested-With, Content-Type')
        self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
        super().end_headers()

    def do_GET(self):
        # If requested path does not exist, serve index.html for Flutter web routing
        requested_path = self.translate_path(self.path)
        if not os.path.exists(requested_path) and '.' not in os.path.basename(self.path):
            self.path = '/index.html'
        return super().do_GET()

def run():
    socketserver.TCPServer.allow_reuse_address = True
    print(f"Starting Invoicely Web Server on http://localhost:{PORT}")
    print(f"Serving static web artifacts from: {WEB_DIR}")
    sys.stdout.flush()

    with socketserver.TCPServer(("", PORT), SPAHandler) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            pass
        finally:
            httpd.server_close()

if __name__ == '__main__':
    run()
