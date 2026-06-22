# Python server for KriaDAQ
# Sam Harris sdh25@ic.ac.uk
# Last updated: 04/06/2026

from http.server import BaseHTTPRequestHandler, HTTPServer
import os
import sys
import inspect

hostName = "127.0.0.1"
serverPort = 8080

FileTypes = { ".json":"application/json",
              ".js": "application/javascript",
              ".css":"text/css",
              ".htm": "text/html",
              ".html": "text/html",
              ".png": "image/png",
              ".jpg": "image/jpeg",
              ".jpeg": "image/jpeg",
              ".gif": "image/gif",
              ".ico": "image/x-icon",
              ".txt": "text/plain"
              }

class MyServer(BaseHTTPRequestHandler):
    def do_GET(self):
        path = os.path.normpath(self.path.strip("/")).split(os.sep)  # Segment path

        ext = ''

        for i, seg in enumerate(path):  # Find file extension regardless of path format
            e = os.path.splitext(seg)[1]
            if e:
                ext = e
                break

        if ext == '':  # Default to HTML if no extension provided
            ext = ".html" 
            self.path += ".html"


        # Address format is /module.ext/function for Python scripts or folder1/folder2/.../module.ext for all other files

        if ext == ".py":

            module = os.path.splitext(path[0])[0]

            if len(path) == 2:
                function = path[1]
            else:
                function = module  # If no function, default to module name

            if module not in sys.modules:  # Check if module is already imported
                try:
                    __import__(module)
                except Exception as e:
                    self.send_response(500)
                    self.end_headers()
                    self.wfile.write(bytes(f"<h1>500 - Internal Server Error: Failed to import module '{module}'</h1><p>{e}</p>", "utf-8"))
                    return
            mod = sys.modules[module]

            if hasattr(mod, function):  # Check if function exists in module
                func = getattr(mod, function)
                params = inspect.signature(func).parameters
                try:
                    if "self" in params:
                        func(self)
                    else:
                        func()
                        self.send_response(200)
                        self.end_headers()
                        self.wfile.write(bytes(f"<h1>200 - Successfully executed '{function}' in module '{module}'</h1>", "utf-8"))
                except Exception as e:
                    self.send_response(500)
                    self.end_headers()
                    self.wfile.write(bytes(f"<h1>500 - Internal Server Error: Failed to execute function '{function}' in module '{module}'</h1><p>{e}</p>", "utf-8"))
            else:
                self.send_response(404)
                self.end_headers()
                self.wfile.write(bytes(f"<h1>404 - Not Found: Function '{function}' not found in module '{module}'</h1>", "utf-8"))


        elif ext in FileTypes:  # All other non-Python files
            if os.path.exists(self.path.strip("/")) and os.path.isfile(self.path.strip("/")):
                self.send_response(200)
                self.send_header("Content-type", FileTypes[ext])
                self.end_headers()
                with open(self.path.strip("/"), "rb") as f:
                    self.wfile.write(f.read()) #Reads the file defined by path
            else:
                self.send_response(404)
                self.end_headers()
                self.wfile.write(b"<h1>404 - File Not Found</h1>")



if __name__ == "__main__":  # Start the server
    webServer = HTTPServer((hostName, serverPort), MyServer)
    print("Server started http://%s:%s" % (hostName, serverPort))

    try:
        webServer.serve_forever()
    except KeyboardInterrupt:
        pass

    webServer.server_close()
    print("Server stopped.")
