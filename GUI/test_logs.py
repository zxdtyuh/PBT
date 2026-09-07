import urllib.request
import json
import time

try:
    req = urllib.request.Request("http://127.0.0.1:8080/list")
    response = urllib.request.urlopen(req)
    pages = json.loads(response.read())
    print([p['title'] for p in pages])
except Exception as e:
    print(f"Failed: {e}")
