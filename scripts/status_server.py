#!/usr/bin/env python3
"""
BossCat Status Dashboard HTTP Server

Simple HTTP server to serve the generated JSON status files.
This allows the status.html dashboard to fetch data via HTTP requests.

Usage:
    python status_server.py [port]
    
Default port: 3003
"""

import http.server
import socketserver
import os
import sys
from pathlib import Path

# Configuration
DEFAULT_PORT = 3003
STATUS_DIR = "docs/status"

class StatusHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    """Custom HTTP request handler for status files."""
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=STATUS_DIR, **kwargs)
    
    def end_headers(self):
        # Add CORS headers to allow cross-origin requests
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        super().end_headers()
    
    def do_GET(self):
        """Handle GET requests."""
        if self.path == '/':
            # Serve index.html if it exists, otherwise list files
            index_path = os.path.join(STATUS_DIR, 'index.html')
            if os.path.exists(index_path):
                self.path = '/index.html'
            else:
                # Generate a simple file listing
                self.send_response(200)
                self.send_header('Content-type', 'text/html')
                self.end_headers()
                
                files = os.listdir(STATUS_DIR)
                html = f"""
                <html>
                <head><title>BossCat Status Dashboard</title></head>
                <body>
                    <h1>BossCat Status Dashboard</h1>
                    <h2>Available JSON Files:</h2>
                    <ul>
                """
                for file in sorted(files):
                    if file.endswith('.json'):
                        html += f'<li><a href="/{file}">{file}</a></li>'
                html += """
                    </ul>
                    <p><em>BossCat OEM Status Server</em></p>
                </body>
                </html>
                """
                self.wfile.write(html.encode())
                return
        
        super().do_GET()
    
    def log_message(self, format, *args):
        """Custom log format."""
        print(f"[{self.log_date_time_string()}] BossCat Status Server: {format % args}")

def main():
    """Main server function."""
    port = DEFAULT_PORT
    
    if len(sys.argv) > 1:
        try:
            port = int(sys.argv[1])
        except ValueError:
            print(f"Invalid port number: {sys.argv[1]}")
            print(f"Using default port: {DEFAULT_PORT}")
    
    # Check if status directory exists
    if not os.path.exists(STATUS_DIR):
        print(f"Error: Status directory '{STATUS_DIR}' not found")
        print("Please run generate_status_jsons.py first to create status files")
        sys.exit(1)
    
    # Change to the repository root directory
    repo_root = Path(__file__).parent.parent
    os.chdir(repo_root)
    
    print("BossCat Status Dashboard HTTP Server")
    print("=" * 40)
    print(f"Serving directory: {STATUS_DIR}")
    print(f"Port: {port}")
    print(f"URL: http://localhost:{port}")
    print("=" * 40)
    print("Press Ctrl+C to stop the server")
    print()
    
    try:
        with socketserver.TCPServer(("", port), StatusHTTPRequestHandler) as httpd:
            print(f"BossCat Status Server running on port {port}")
            httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nBossCat Status Server stopped")
    except OSError as e:
        if e.errno == 10048:  # Port already in use
            print(f"Error: Port {port} is already in use")
            print("Please choose a different port or stop the existing server")
        else:
            print(f"Error starting server: {e}")

if __name__ == "__main__":
    main()
