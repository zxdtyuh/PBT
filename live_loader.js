// V13 Live Loader — QuARC v4
// Polls bars_live.json, handles DAQ config inputs and PHP backend launch.

// Global variables required by quarcD3GUI
let fileLoaded = true;
let dataJSON = null;
let graphInitialized = false;

// Auto-incrementing run number for file name field
let runCounter = 1;

function pad(num, size) {
    let s = num + "";
    while (s.length < size) s = "0" + s;
    return s;
}

// Auto-fill file name on first click
function setInitialFileName() {
    const fileInput = document.getElementById("fileName");
    if (fileInput.value === "") {
        fileInput.value = "Run" + pad(runCounter, 3);
        runCounter++;
    }
}

// Auto-set tINT minimum based on number of boards
function updateTINT() {
    const boards = parseInt(document.getElementById("boardsInput").value);
    const tINTInput = document.getElementById("tINTInput");
    const minTINT = boards <= 4 ? 170 : boards === 5 ? 190 : boards === 6 ? 220 : boards === 7 ? 250 : 280;
    tINTInput.min = minTINT;
    if (parseInt(tINTInput.value) < minTINT) tINTInput.value = minTINT;
}

// Link measurements <-> run time via tINT
function updateRunTime() {
    const meas = parseFloat(document.getElementById("measInput").value);
    const tINT = parseFloat(document.getElementById("tINTInput").value);
    if (!isNaN(meas) && !isNaN(tINT)) {
        document.getElementById("measTimeInput").value = (meas * tINT * 1e-6).toFixed(1);
    }
}

function updateMeasurements() {
    const t = parseFloat(document.getElementById("measTimeInput").value);
    const tINT = parseFloat(document.getElementById("tINTInput").value);
    if (!isNaN(t) && !isNaN(tINT) && tINT > 0) {
        document.getElementById("measInput").value = Math.round(t / tINT * 1e6);
    }
}

// Validate tINT on input
function validateTINT() {
    const tINTInput = document.getElementById("tINTInput");
    const errSpan = document.getElementById("error-tINT");
    if (parseInt(tINTInput.value) < parseInt(tINTInput.min)) {
        errSpan.style.display = "inline";
        setTimeout(() => {
            tINTInput.value = tINTInput.min;
            errSpan.style.display = "none";
            updateRunTime();
        }, 1000);
    } else {
        errSpan.style.display = "none";
        updateRunTime();
    }
}

// Button state
function setButtonState() {
    let daqButton = document.getElementById("DAQbutton");
    daqButton.classList.remove("grey", "green", "red");
    if (isRunning) {
        daqButton.classList.add("red");
        daqButton.innerText = "Stop";
    } else {
        daqButton.classList.add("green");
        daqButton.innerText = "Measure";
    }
}

// Scintillator bandwidths
function calcBandwidths(sheetMids) {
    if (!sheetMids || sheetMids.length === 0) return [];
    let bandwidths = [];
    for (var i = 0; i < sheetMids.length - 1; i++) {
        bandwidths.push(sheetMids[i + 1] - sheetMids[i]);
    }
    bandwidths.push(bandwidths[bandwidths.length - 1] || 3);
    return bandwidths;
}

// Collect DAQ parameters from inputs
function getDAQParams() {
    let filename = document.getElementById("fileName").value || ("Run" + pad(runCounter, 3));
    if (document.getElementById("checkbox_bck").checked) filename += "_background";
    return {
        filename:     filename,
        boards:       document.getElementById("boardsInput").value,
        FSR:          document.getElementById("FSRInput").value,
        tINT:         document.getElementById("tINTInput").value,
        measurements: document.getElementById("measInput").value,
        refresh:      25   // hardcoded at 25 Hz
    };
}

// Start/stop button handler
async function toggleButtonState() {
    if (isRunning) {
        // Stop
        isRunning = false;
        setButtonState();
        fetch("executeDAQ.py/stop") // trigger Python stop");
        document.getElementById("content").innerHTML = "Measurement stopped.";
    } else {
        // Validate required fields
        const params = getDAQParams();
        if (!params.filename || !params.measurements || !params.tINT) {
            document.getElementById("content").innerHTML =
                "<span style='color:red;'>Please fill in all fields before starting.</span>";
            return;
        }
        // Start
        isRunning = true;
        setButtonState();
        // Auto-increment run counter for next run
        runCounter++;
        const body = "command=START" +
            "&filename="     + encodeURIComponent(params.filename) +
            "&boards="       + encodeURIComponent(params.boards) +
            "&FSR="          + encodeURIComponent(params.FSR) +
            "&tINT="         + encodeURIComponent(params.tINT) +
            "&measurements=" + encodeURIComponent(params.measurements) +
            "&refresh="      + encodeURIComponent(params.refresh);
        fetch("executeDAQ.py/start");
        // Reset progress bar for new run
        document.getElementById("progressBar").style.width = "0%";
        document.getElementById("progressLabel").innerText = "0 / " + params.measurements;

        document.getElementById("content").innerHTML =
            "Measurement running: " + params.filename +
            " | " + params.boards + " boards" +
            " | FSR " + params.FSR + " pC" +
            " | tINT " + params.tINT + " μs" +
            " | " + params.measurements + " measurements";
        runLiveLoop();
    }
}

// Initialise on page load
function initLive() {
    setButtonState();
    updateTINT();
    // Wire up input event listeners
    document.getElementById("boardsInput").addEventListener("change", updateTINT);
    document.getElementById("tINTInput").addEventListener("input", validateTINT);
    document.getElementById("measInput").addEventListener("input", updateRunTime);
    document.getElementById("measTimeInput").addEventListener("input", updateMeasurements);
}

// Update the progress bar from logfile_runningStatus.txt
// Returns true if acquisition has finished ("Stopping")
async function updateProgress() {
    try {
        const response = await fetch("../logfile_runningStatus.txt?" + new Date().getTime());
        if (!response.ok) return false;
        const text = await response.text();

        // File uses \r (not \n) between entries — split on \r and take the last entry
        const entries = text.split('\r').map(s => s.trim()).filter(s => s !== '');
        if (entries.length === 0) return false;
        const lastEntry = entries[entries.length - 1];
        const parts  = lastEntry.split(/\s+/);
        const count  = parseInt(parts[0]);
        const status = parts[1] || "";
        const total  = parseInt(document.getElementById("measInput").value) || 0;

        if (!isNaN(count) && total > 0) {
            const pct = Math.min(100, (count / total) * 100).toFixed(0);
            document.getElementById("progressBar").style.width = pct + "%";
            document.getElementById("progressLabel").innerText = pct + "%";
        }

        return status === "Stopping";
    } catch (e) {
        return false;
    }
}

// Core polling loop
async function runLiveLoop() {
    while (isRunning) {
        const start = performance.now();

        // Check acquisition status and update progress bar
        const done = await updateProgress();
        if (done) {
            isRunning = false;
            setButtonState();
            document.getElementById("progressBar").style.width = "100%";
            document.getElementById("content").innerHTML = "Measurement complete.";
            break;
        }

        try {
            const response = await fetch("../bars_live.json?" + new Date().getTime());
            if (response.ok) {
                const text = await response.text();
                if (text.trim() !== "") {
                    const rawData = JSON.parse(text);
                    const pythonSlice = rawData.data;
                    if (pythonSlice) {
                        const dataSlice = {
                            left: pythonSlice.left || {
                                pdy: pythonSlice.y || [],
                                pdsigmay: pythonSlice.y_err || [],
                                kelleter: [],
                                bortfeld: []
                            },
                            right: pythonSlice.right || {
                                pdy: pythonSlice.y_right || pythonSlice.y || [],
                                pdsigmay: pythonSlice.err_right || pythonSlice.y_err || [],
                                kelleter: pythonSlice.lineData || [],
                                bortfeld: pythonSlice.lineData2 || []
                            },
                            pdx:        pythonSlice.pdx || pythonSlice.x || [],
                            fitx:       pythonSlice.fitx || pythonSlice.lineX || pythonSlice.x || [],
                            bandwidths: pythonSlice.bandwidths || calcBandwidths(pythonSlice.pdx || pythonSlice.x),
                            xSpotX:     pythonSlice.xSpotX || [],
                            xSpotY:     pythonSlice.xSpotY || []
                        };
                        if (!graphInitialized) {
                            await makeAndPopulateGraph(dataSlice);
                            graphInitialized = true;
                        } else {
                            await plotGraph(dataSlice);
                        }
                    }
                }
            }
        } catch (e) {
            console.error("Error fetching live data:", e);
            document.getElementById("content").innerHTML =
                "<span style='color:red;'>Error fetching live data.</span><br>" +
                "Ensure FTDI_GUI is running and <b>bars_live.json</b> exists.";
        }
        const elapsed = performance.now() - start;
        const loopTime = 1000 / frameRate;
        await new Promise(resolve => setTimeout(resolve, Math.max(10, loopTime - elapsed)));
    }
}
