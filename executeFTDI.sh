#!/bin/bash
# QuARC v4 — launch FTDI_GUI with parameters from the live GUI
# Manual usage: bash executeFTDI.sh Run001 12.5 170 10000 25 2

cd /home/pi/GUI/v4

filename=$1      # e.g. Run001
FSR=$2           # e.g. 12.5
tINT=$3          # e.g. 170
measurements=$4  # e.g. 10000
refresh=$5       # e.g. 25
boards=$6        # e.g. 2

# Add 1 to measurements to account for the configuration header line
((measurements += 1))

# Ensure demo directory exists
if [ ! -d "demo" ]; then
    mkdir -p "demo"
fi

# Log start time and parameters
echo "Acquisition started: $(date +'%d-%m-%Y %H:%M:%S')" > outputFTDI.txt
echo "file=$filename FSR=$FSR tINT=$tINT measurements=$measurements refresh=$refresh boards=$boards" >> outputFTDI.txt

# Run FTDI_GUI — writes raw .txt files and bars_live.json at each refresh interval
sudo ./FTDI_GUI USB104ZMOD "$boards" "$FSR" "$tINT" "$measurements" "$refresh" "$filename.txt" revC 2

echo "Acquisition completed." >> outputFTDI.txt
