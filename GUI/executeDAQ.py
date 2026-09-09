import subprocess
import urllib.parse

v4dir   = ""
script  = "executeFTDI.sh"

_process = None  # Track the running process

def start(self):
    global _process

    length = int(self.headers.get('Content-Length', 0))
    body = self.rfile.read(length).decode('utf-8')
    params = urllib.parse.parse_qs(body)

    filename     = params.get('filename',     [''])[0]
    boards       = params.get('boards',       [''])[0]
    FSR          = params.get('FSR',          [''])[0]
    tINT         = params.get('tINT',         [''])[0]
    measurements = params.get('measurements', [''])[0]
    refresh      = params.get('refresh',      [''])[0]

    _process = subprocess.Popen(
        ["bash", script, filename, FSR, tINT, measurements, refresh, boards],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL
    )

    self.send_response(200)
    self.send_header("Content-type", "text/plain")
    self.send_header("Cache-Control", "no-cache, no-store")
    self.end_headers()
    self.wfile.write(b"DAQ started.")

def stop(self):
    global _process

    if _process is not None:
        _process.terminate()
        _process = None

    # Backup kill
    subprocess.run(["pkill", "-f", "executeFTDI.sh"])

    self.send_response(200)
    self.send_header("Content-type", "text/plain")
    self.send_header("Cache-Control", "no-cache, no-store")
    self.end_headers()
    self.wfile.write(b"DAQ stopped.")

