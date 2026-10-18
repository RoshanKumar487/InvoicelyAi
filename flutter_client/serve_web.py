import os
import http.server
import socketserver
from urllib.parse import unquote

DIRECTORY = os.path.abspath(os.path.join(os.path.dirname(__file__), 'build', 'web'))
PORT = 3000

class SPAHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def do_GET(self):
        # Strip query parameters and hash
        raw_path = self.path.split('?')[0].split('#')[0]
        local_path = os.path.normpath(os.path.join(DIRECTORY, unquote(raw_path.lstrip('/'))))
        
        # If path doesn't exist on disk, fallback to index.html for Flutter SPA client routing
        if not os.path.exists(local_path) and not raw_path.startswith('/api'):
            self.path = '/index.html'
            
        return super().do_GET()

    def end_headers(self):
        self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
        self.send_header('Access-Control-Allow-Origin', '*')
        super().end_headers()

class ThreadedTCPServer(socketserver.ThreadingMixIn, socketserver.TCPServer):
    daemon_threads = True
    allow_reuse_address = True

if __name__ == '__main__':
    with ThreadedTCPServer(('0.0.0.0', PORT), SPAHandler) as httpd:
        print(f"Serving Flutter Web at http://localhost:{PORT}", flush=True)
        httpd.serve_forever()
