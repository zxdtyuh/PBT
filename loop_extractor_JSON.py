"""
V12.1 Live DAQ Extractor (25Hz)

Extracts single frames from the full DAQ JSON dataset at 25Hz to simulate a live 
streaming backend for the GUI. 

The GUI reads `bars_live.json` while this script constantly rewrites it.
Controlled via `logfile_runningStatus.txt` (watched for "Stopping").
"""

import json
import time
from pathlib import Path


class Simple25HzExtractor:
    # Extracts sequential frames to create a live-streaming illusion
    def __init__(self):
        base_dir = Path(__file__).parent

        #=======================================================================
        # Input data file (relative to this folder)
        self.input_json = base_dir / "GUIdata" / "UCLH_2025-05-24" / "20250524_Run071_fitted_50Hz.json"
        # Output file read by the GUI (must sit next to HTML/JS)
        self.temp_output = base_dir / "bars_live.json"

        # Status file (written by PHP, read by Python)
        self.status_file = base_dir / "logfile_runningStatus.txt"

        # Loop configuration 
        self.detector = "left"
        self.measurement_number = 1 
        self.max_measurement_number = 250

        # Memory buffer
        self.full_data = None
        self.extracted = None

    def load_full_json(self):
        # Load the entire dataset once at startup
        with open(self.input_json, "r") as f:
            self.full_data = json.load(f)
            
        # Dynamically set max measurement number based on loaded data
        if self.detector in self.full_data and "data" in self.full_data[self.detector]:
            self.max_measurement_number = self.full_data[self.detector]["data"].get("measurements", 250)
        else:
            self.max_measurement_number = 250 # fallback

    def extract_measurement(self):
        # Output one frame in the exact structure plotGraph() expects:
        # { left: { pdy, pdsigmay, kelleter, bortfeld }, right: {...}, pdx, fitx, bandwidths }
        if not self.full_data:
            raise RuntimeError("Full JSON not loaded")

        m_key = str(self.measurement_number)

        def extract_side(side_name):
            if side_name not in self.full_data:
                return None
            s_data = self.full_data[side_name]["data"]
            if m_key not in s_data:
                return None
            measurement = s_data[m_key]
            return {
                "pdy":      measurement["pdy"],
                "pdsigmay": measurement["pdsigmay"],
                "kelleter": measurement["kelleter"],
                "bortfeld": measurement["bortfeld"]
            }

        left  = extract_side("left")
        right = extract_side("right")

        # Use pdx/fitx from whichever side is available
        side_data = self.full_data.get("left", self.full_data.get("right", {}))
        s_data = side_data.get("data", {})
        pdx  = s_data.get("pdx",  [])
        fitx = s_data.get("fitx", [])

        output = {
            "meta": {
                "measurement": self.measurement_number,
                "timestamp":   time.time()
            },
            "left":  left  or {"pdy": [], "pdsigmay": [], "kelleter": [], "bortfeld": []},
            "right": right or {"pdy": [], "pdsigmay": [], "kelleter": [], "bortfeld": []},
            "pdx":  pdx,
            "fitx": fitx
        }

        self.extracted = output

    def write_temp_json(self):
        # Atomic swap — write to .tmp then rename to avoid mid-write browser reads
        temp_path = self.temp_output.with_suffix(".tmp")
        with open(temp_path, "w") as f:
            json.dump(self.extracted, f, indent=2)
        temp_path.replace(self.temp_output)

    def check_status(self):
        # Returns True to keep running, False to exit cleanly
        try:
            with open(self.status_file, 'r') as f:
                status = f.read().strip()
                if "Stopping" in status:
                    print("\n✓ Stop signal received from backend")
                    return False
        except FileNotFoundError:
            pass
        return True

    def run(self):
        self.load_full_json()
        print(" Starting 25 Hz rewrite loop")
        print("  Press Ctrl+C to stop manually")
        try:
            while True:
                start = time.time()
                if not self.check_status():
                    print("✓ Exiting cleanly due to stop signal")
                    break
                self.extract_measurement()
                self.write_temp_json()
                elapsed = time.time() - start
                sleep_time = max(0.0, 0.04 - elapsed)
                time.sleep(sleep_time)
                print(
                    f"\r[Live DAQ] Wrote frame {self.extracted['meta']['measurement']} "
                    f"in {elapsed:.3f}s",
                    end="", flush=True
                )
                self.measurement_number += 1
                if self.measurement_number > self.max_measurement_number:
                    self.measurement_number = 1

        except KeyboardInterrupt:
            print("\n✓ Stopped via Ctrl+C")


if __name__ == "__main__":
    extractor = Simple25HzExtractor()
    extractor.run()
