# Python server for replay.html
# Sam Harris sdh25@ic.ac.uk
from http.server import BaseHTTPRequestHandler, HTTPServer
import json
import time
import os

hostName = "127.0.0.1"
serverPort = 8080

class MyServer(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/list": #Listfiles goes to /list path and forces this function
            self.server_file_list()
        else:
            self.server_file()
    
    def server_file_list(self, file_ext="json"):
        result = {}
        for entry in os.scandir("GUIData"): #Scans the GUIData folder for subfolders and files (must be in same directory as PythonWebserver.py)
            if entry.is_dir():
                files = [f for f in os.listdir(entry.path) if f.endswith("." + file_ext)]
                if files: 
                    result[entry.name] = files #Adds the subfolder and its files to the result dictionary if it contains files with the specified extension
        root_files = [f for f in os.listdir("GUIData") if f.endswith("." + file_ext) and os.path.isfile(os.path.join("GUIData", f))]
        if root_files:
            result["Local Data Folder"] = root_files #Adds any json files that are in the root GUIdata folder
        self.send_response(200)
        self.send_header("Content-type", "application/json")
        self.end_headers()
        self.wfile.write(bytes(json.dumps(result), "utf-8"))

    def server_file(self):
        path = self.path.strip("/") or "replay.html" #replay.html is the home page 
        if os.path.exists(path) and os.path.isfile(path):
            self.send_response(200)
            #Tell Python the filetype so the browser knows what it's reading
            if path.endswith(".json"):
                self.send_header("Content-type", "application/json")
            elif path.endswith(".js"):
                self.send_header("Content-type", "application/javascript")
            elif path.endswith(".css"):
                self.send_header("Content-type", "text/css")
            else:
                self.send_header("Content-type", "text/html")
            self.end_headers()
            with open(path, "rb") as f:
                self.wfile.write(f.read()) #Reads the file defined by path
        
        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b"<h1>404 - File Not Found</h1>")

if __name__ == "__main__":
    webServer = HTTPServer((hostName, serverPort), MyServer)
    print("Server started http://%s:%s" % (hostName, serverPort))

    try:
        webServer.serve_forever()
    except KeyboardInterrupt:
        pass

    webServer.server_close()
    print("Server stopped.")
