import os
import json


def list(self, file_ext="json"):
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