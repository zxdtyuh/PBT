/**
 * quarcD3GUI.js - v.4
 * Main D3 plotting logic for Replay/Live.
 * Updated for UCL/Trento production.
 */

// Initial variable - SJ

let isRunning = false;
let curFrame = 1;
let frameRate = 25.0;
let dataSlice;
let svgChart;
let measurements = 0;
const maxWET = 300;
const maxInt = 10;

let checkInterval; // Declare checkInterval outside of the function to make it accessible globally

// Config flags - DS
const FLAGS = {
    plotBars: true,
    plotKelL: false,
    plotKelR: true,
    plotBortL: false,
    plotBortR: true,
    plotDiff: false,
    autoScale: true, // V8: Default ON
    highlightPeak: false,
    peakAsNegativeColor: false,
    debug: false  // set to false for production
};

let forceUpdate = false; // Flag to force re-draw on UI interaction

// Helper to trigger update from UI
function requestUpdate() {
    forceUpdate = true;

    // V11.5 Hot-reloading: If we are paused, instantly redraw the screen to reflect the toggle
    if (!isRunning && typeof dataJSON !== 'undefined' && dataJSON.right) {
        dataSlice = loadDataSlice(dataJSON, curFrame);
        plotGraph(dataSlice);
    }
}

// Helper to wire a checkbox to a flag
function wire(id, flagName) {
    const el = document.getElementById(id);
    if (!el) return; // skip if element is hidden/removed (V7.1 hidden buttons)

    // 1. Sync HTML to initial Flag state
    el.checked = FLAGS[flagName];

    // 2. Listen for clicks
    el.addEventListener("change", (e) => {
        console.log(`[UI] Toggling ${flagName} to ${e.target.checked}`);
        FLAGS[flagName] = e.target.checked;
        requestUpdate(); // Force a re-draw immediately
    });
}

// --- UI Controls Setup ---
function setupControls() {

    // Event Listeners (UI -> FLAGS)
    wire("autoScale", "autoScale");
    wire("toggleKelL", "plotKelL");
    wire("toggleKelR", "plotKelR");
    wire("toggleBortL", "plotBortL");
    wire("toggleBortR", "plotBortR");
    wire("toggleDiff", "plotDiff");
    wire("toggleDebug", "debug");

    // For Manual Mode: trigger an update when user types/changes values
    const triggerUpdate = () => requestUpdate();

    const xIn = document.getElementById("xMaxInput");
    const yIn = document.getElementById("yMaxInput");
    const yMinIn = document.getElementById("yMinInput"); // V11.5: Added yMin hook

    if (xIn) {
        xIn.addEventListener("input", triggerUpdate);
        xIn.addEventListener("change", triggerUpdate);
    }
    if (yIn) {
        yIn.addEventListener("input", triggerUpdate);
        yIn.addEventListener("change", triggerUpdate);
    }
    if (yMinIn) {
        yMinIn.addEventListener("input", triggerUpdate);
        yMinIn.addEventListener("change", triggerUpdate);
    }

    // --- V11.5 Slider Scrubbing Logic ---
    const slider = document.getElementById("frameSlider");
    if (slider) {
        slider.addEventListener("input", (e) => {
            // Pause animation when user drags slider
            if (isRunning) {
                isRunning = false; // Stop the runUpdateGraph loop
                setButtonState();  // Visually change "Stop" back to "Run"
            }

            // Instantly draw the frame they scrubbed to
            curFrame = parseInt(e.target.value);
            document.getElementById("frameReadout").innerText = curFrame;

            // Only plot if data exists
            if (typeof dataJSON !== 'undefined') {
                dataSlice = loadDataSlice(dataJSON, curFrame);
                plotGraph(dataSlice);
            }
        });
    }
}

// Set up controls immediately on load
setupControls();

// Function to format the date as YYYYmmdd
function formatDate(date) {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0'); // Month is 0-based
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}${month}${day}`; // Format: YYYYmmdd
}

// Extract current date
const currentDate = new Date();
console.log("Current date: ", currentDate);
const formattedDate = formatDate(currentDate); // Format the date YYmmdd for folder + file

// Options for formatting the date
const options = { day: 'numeric', month: 'long', year: 'numeric' };
const formattedDate2 = currentDate.toLocaleDateString('en-UK', options);

// I/O and button control functions

let directorySel = document.getElementById("dirs");
let fileSel = document.getElementById("files");
if (fileSel) {     // Check if file selector exists for live version -Sam 27/5/2026
    fileSel.addEventListener("change", () => {
        fileMenu = document.querySelector('#files');
        file = fileMenu.options[fileMenu.selectedIndex].value;
        if (file === "Files") {
            fileLoaded = false;
        } else {
            fileLoaded = true;
        };
        curFrame = 1;
        // console.log("File selector menu changed; files loaded is " + fileLoaded);
        setButtonState();
});
}

// Check and set button colour and text
function setButtonState() {
    let daqButton = document.getElementById("DAQbutton");
    let buttonClasses = daqButton.classList;

    // Remove colour setting from class list
    if (buttonClasses.contains("grey")) {
        daqButton.classList.toggle("grey");
    }
    if (buttonClasses.contains("green")) {
        daqButton.classList.toggle("green");
    }
    if (buttonClasses.contains("red")) {
        daqButton.classList.toggle("red");
    }

    // Set button colour depending on state
    if (!fileLoaded) {
        daqButton.classList.toggle("grey");
        daqButton.innerText = "Wait";
    } else if (isRunning) {
        daqButton.classList.toggle("red");
        daqButton.innerText = "Stop";
    } else {
        daqButton.classList.toggle("green");
        daqButton.innerText = "Run";
    }
    // console.log(daqButton);
}

// Toggle button text
function toggleButtonState() {
    //     let txt = button.innerText;
    //     button.innerText = txt == 'Run' ? 'Stop' : 'Run';
    // console.log(button);
    if (fileLoaded) {
        if (isRunning) {
            isRunning = false;
            setButtonState();
        } else {
            isRunning = true;
            setButtonState();
            runUpdateGraph();
        }
    }
    //     console.log("Current measurement: " + curFrame + " out of " + measurements);
}

// Functions to control plotting

// Refresh display when new data is loaded
async function refreshDisplay() {
    let display = document.getElementById("content");
    display.innerHTML += "<br />Data loaded for plotting<br />";

    frameRate = dataJSON.header["Fit rate"];
    console.log("Display frame rate: " + frameRate + " Hz");

    measurements = dataJSON.right.data["measurements"];
    console.log("Number of measurements in data file: " + measurements);

    curFrame = 1;

    // V11.5 Configure Slider
    const slider = document.getElementById('frameSlider');
    if (slider) {
        slider.max = measurements;
        slider.value = curFrame;
        slider.disabled = false;
        document.getElementById("frameReadout").innerText = curFrame;
    }

    dataSlice = loadDataSlice(dataJSON, curFrame);
    //     console.log(dataSlice);

    //     svgChart = makeGraph(dataSlice);
    const start = performance.now();
    await makeAndPopulateGraph(dataSlice);
    const end = performance.now();
    console.log(`Time to update graph: ${end - start} ms`);
    //     testingMaths(dataSlice);

    setButtonState();
}

// Load data for current frame from JSON containing all QuARC data
function loadDataSlice(quarcDataAsJSON, curFrame) {
    const dataSlice = {
        left: quarcDataAsJSON.left.data[curFrame],
        right: quarcDataAsJSON.right.data[curFrame],
        pdx: quarcDataAsJSON.right.data["pdx"],
        fitx: quarcDataAsJSON.right.data["fitx"],
        bandwidths: quarcDataAsJSON.right.data["bandwidths"],
        measurements: quarcDataAsJSON.right.data["measurements"]
    };
    return dataSlice;
}

// Helper for "Sensible" Rounding
function roundToSensible(val) {
    // "If close to 100, nearest 10"
    // "If past 200, nearest 50"
    if (val <= 20) return Math.ceil(val / 2) * 2;   // <20: Round to 2 (e.g. 16->16, 17->18)
    if (val <= 200) return Math.ceil(val / 10) * 10; // 20-200: Round to 10 (e.g. 33->40)
    return Math.ceil(val / 50) * 50;                // >200: Round to 50
}

// Assortment of functions to test calculations
function testingMaths(dataSlice) {
    // Parse input data to find plot axes limits
    // First maximum WET to nearest 10mm for X-axis
    let revSortedPDX = [...new Set(dataSlice["pdx"])];
    revSortedPDX.sort((a, b) => b - a);
    // console.log(revSortedPDX);
    setWET = parseInt(((2 * revSortedPDX[0]) - revSortedPDX[1]) / 10, 10) * 10 + 10;
    console.log("Maximum WET for X-axis: " + setWET);

    // Calculate maximum intensity for Y-axis
    let allRightInts = dataSlice.right["pdy"].concat(dataSlice.right["kelleter"], dataSlice.right["bortfeld"]);
    let allLeftInts = dataSlice.left["pdy"].concat(dataSlice.left["kelleter"], dataSlice.left["bortfeld"]);
    let revSortedInts = [...new Set(allRightInts.concat(allLeftInts))];
    revSortedInts.sort((a, b) => b - a);
    // console.log(revSortedInts);
    maxY = Math.ceil(revSortedInts[0]);
    console.log("Maximum Intensity for Y-axis: " + maxY);
}

// --- Initial D3 Setup (V12: Responsive) ---
const X_PAD = 0; // px padding removed so axes meet squarely at 0 without gap
const SHRINK_FACTOR = 0.9; // 90% width to leave a small visual gap
const M = { top: 10, right: 50, bottom: 60, left: 50 };

// V12: Read actual container size instead of fixed constants
function getChartDimensions() {
    const container = document.getElementById("plotArea");
    const rect = container.getBoundingClientRect();
    return {
        W: Math.floor(rect.width),
        H: Math.floor(rect.height)
    };
}

let { W, H } = getChartDimensions();
let innerW = W - M.left - M.right;
let innerH = H - M.top - M.bottom;

// V12: Position overlay controls to align with chart axes (not hardcoded CSS pixels)
function positionOverlay() {
    const overlay = document.querySelector('.overlay-controls');
    if (!overlay) return;
    overlay.style.top  = M.top + 'px';
    overlay.style.left = (M.left + 10) + 'px'; // 10px gap from y-axis line
}
positionOverlay();

// V12: No viewBox — set explicit pixel dimensions for 1:1 mapping
const svg = d3.select("#chart")
    .attr("width", W)
    .attr("height", H);

// Define plotting groups needed by SVG
var plotG = svg.append("g").attr("transform", `translate(${M.left},${M.top})`);

// V12: Clip-path so bars/lines don't overflow — applied to data group only, NOT plotG
// (axes extend beyond innerW×innerH and must not be clipped)
svg.append("defs").append("clipPath").attr("id", "plot-clip")
    .append("rect").attr("width", innerW).attr("height", innerH);
const dataClipG = plotG.append("g").attr("clip-path", "url(#plot-clip)");

// Layer groups inside clipped area (SVG draw order matters):
const barsG = dataClipG.append("g").attr("class", "bars");
const errorG = dataClipG.append("g").attr("class", "error-bars");

// Right Detector Groups (Render ON TOP of Left)
const barsRightG = dataClipG.append("g").attr("class", "bars-right");
const errorRightG = dataClipG.append("g").attr("class", "error-bars-right");

const linesG = dataClipG.append("g").attr("class", "overlays");

// New Group for Peak Dots (Z-index: On top of everything)
const dotsG = dataClipG.append("g").attr("class", "dots");

// --- Overlay paths (created ONCE here; Step 4 only updates their 'd') ---
const kelPathL = linesG.append("path")
    .attr("id", "kelOverlayL")
    .attr("class", "overlay-line keller")
    .style("fill", "none")
    .attr("d", "");

const kelPathR = linesG.append("path")
    .attr("id", "kelOverlayR")
    .attr("class", "overlay-line keller right")
    .style("fill", "none")
    .attr("d", "");

const bortPathL = linesG.append("path")
    .attr("id", "bortOverlayL")
    .attr("class", "overlay-line bortfeldt")
    .style("fill", "none")
    .attr("d", "");

const bortPathR = linesG.append("path")
    .attr("id", "bortOverlayR")
    .attr("class", "overlay-line bortfeldt right")
    .style("fill", "none")
    .attr("d", "");

const diffPath = linesG.append("path")
    .attr("id", "diffOverlay")
    .attr("class", "overlay-line cumulative-diff")
    .style("fill", "none")
    .attr("stroke", "mediumspringgreen")
    .attr("stroke-width", 3)
    .attr("d", "");

var x = d3.scaleLinear() //linear x axis now same as y axis 
    .domain([0, maxWET])
    .range([X_PAD, innerW]);

var y = d3.scaleLinear()
    .domain([0, maxInt]) // pixel height of scale
    .range([innerH, 0])
    .nice();

var yDiffScale = d3.scaleLinear()
    .domain([-100, 100])
    .range([innerH, 0]);

// --- X axis: numeric axis (pdx positions) ---
const xAxisG = plotG.append("g")
    .attr("class", "axis")
    .attr("transform", `translate(0,${innerH})`)
    .call(d3.axisBottom(x));
// ^ D3 chooses sensible ticks for the pdx domain, to not plot every bar on scale

// axis label for clarity
plotG.append("text")
    .attr("class", "axis-label")
    .attr("id", "x-axis-label")
    .attr("text-anchor", "end")
    .text("Water-Equivalent Thickness (mm)");

// --- Y axis (save a handle so update() can refresh it when domain changes) ---
const yAxisG = plotG.append("g")
    .attr("class", "axis")
    .call(d3.axisLeft(y)); //via linear scale (defined up above)

// ---------------- Y axis label ----------------
plotG.append("text")
    .attr("class", "axis-label y-label")
    .attr("id", "y-axis-label")
    .attr("transform", "rotate(-90)")
    .attr("text-anchor", "middle")
    .text("Charge (pC)");            // required label

// Cumulative Difference Y axis rendering (RHS)
const yDiffAxisG = plotG.append("g")
    .attr("class", "axis diff-axis")
    .attr("transform", `translate(${innerW},0)`)
    .call(d3.axisRight(yDiffScale));

// RHS Y axis label
plotG.append("text")
    .attr("class", "axis-label y-label right-label")
    .attr("id", "y-diff-axis-label")
    .attr("transform", "rotate(-90)") // Symmetrical rotation to LHS
    .attr("text-anchor", "middle")
    .text("Difference (R-L)/(R+L)");

// Convert mm widths to pixels using our x-scale
// (Note: x scale maps mm -> pixels)
function getWidthsPx(widthsMM, currentXScale, currentXData, shrinkFact) {
    return widthsMM.map((w_mm, i) => {
        // We calculate how many pixels 'w_mm' takes up at this position
        const center_mm = currentXData[i];
        const half_mm = (w_mm * shrinkFact) / 2;
        // Pixel width = | x(center + half) - x(center - half) |
        return Math.abs(currentXScale(center_mm + half_mm) - currentXScale(center_mm - half_mm));
    });
}

// Make new plot axes for graph
function makeGraph(dataSlice) {

    // Extract data from data slice to set up plot
    let pdRight = dataSlice.right["pdy"];
    let pdRightErr = dataSlice.right["pdsigmay"];
    let kellRight = dataSlice.right["kelleter"];
    let bortRight = dataSlice.right["bortfeld"];
    let fitX = dataSlice["fitx"];
    let pdX = dataSlice["pdx"];
    let bandwidths = dataSlice["bandwidths"];

    let pdLeft = dataSlice.left["pdy"];
    let pdLeftErr = dataSlice.left["pdsigmay"];
    let kellLeft = dataSlice.left["kelleter"];
    let bortLeft = dataSlice.left["bortfeld"];

    // x axis scale x = linear (real pdx positions), y = linear (heights)
    x0 = pdX.map(Number); // ensure pdx is numeric for D3(sometimes Json yields strings)

    x = d3.scaleLinear() //linear x axis now same as y axis 
        .domain([d3.min(x0), d3.max(x0)])
        .range([X_PAD, innerW]);

    y = d3.scaleLinear()
        .domain([0, Math.max(5, d3.max(pdRight) + 1)]) // pixel height of scale
        .range([innerH, 0])
        .nice();

    // --- V9 Feature: Link Overlay to JS Margins --- overudes style.css 
    const overlay = document.querySelector(".overlay-controls");
    if (overlay) {
        // Use M.top to align with the top of the Y-axis
        overlay.style.top = `${M.top + 120}px`;
        // can also add offsets: `${M.top + 10}px`
    }

    let currentWidthsPx = getWidthsPx(bandwidths, x, x0, SHRINK_FACTOR);

    // Bars (data join) 
    // We use "currentWidthsPx[i]" for the width of the i-th bar
    barsG.selectAll("rect")
        .data(pdRight.map((v, i) => ({ x: x0[i], v, i })), d => `bar-${d.i}`)
        .join("rect")
        .attr("class", "bar positive")
        .attr("x", d => x(d.x) - currentWidthsPx[d.i] / 2) // center the bar
        .attr("y", d => y(Math.max(0, d.v)))
        .attr("width", d => currentWidthsPx[d.i])          // unique width per bar
        .attr("height", d => Math.abs(y(0) - y(d.v)));

    // --- Right Detector Bars Initial (Section 3) ---
    // If we have Right data initially, use it. Else empty.
    const yRightInit = (pdRight) ? pdRight : new Array(pdRight.length).fill(0);
    const xRightInit = (pdX) ? pdX : x0; // Fallback to left X if missing?

    barsRightG.selectAll("rect")
        .data(yRightInit.map((v, i) => ({ x: xRightInit[i], v, i })))
        .join("rect")
        .attr("class", "bar right") // Salmon + Transparent as of v10.1
        .attr("x", d => x(d.x) - currentWidthsPx[d.i] / 2)
        .attr("y", d => y(Math.max(0, d.v)))
        .attr("width", d => currentWidthsPx[d.i])
        .attr("height", d => Math.abs(y(0) - y(d.v)));

    // --- Error Bars Initial (Section 3) ---
    // Create the lines ONCE based on initial x-values
    // They will start at the correct position for the first frame
    const yErrInit = (pdLeftErr) ? pdLeftErr : new Array(pdLeft.length).fill(0);

    // We bind data to create exactly N lines (where N = number of bars)
    errorG.selectAll("path.error-line")
        .data(pdLeft.map((v, i) => ({ x: x0[i], v, err: yErrInit[i], i })))
        .join("path")
        .attr("class", "error-line") // Styled in CSS
        .attr("d", d => {
            if (!d.err) return "";
            let cx = x(d.x);
            let yTop = y(d.v + d.err);
            let yBot = y(d.v - d.err);
            let w = (currentWidthsPx[d.i] || 5) * 0.3;
            if (isNaN(w) || w <= 0) w = 2;
            return `M ${cx},${yBot} L ${cx},${yTop} M ${cx - w},${yTop} L ${cx + w},${yTop} M ${cx - w},${yBot} L ${cx + w},${yBot}`;
        });

    // --- Right Error Bars Initial (Section 3) ---
    const yErrRightInit = (pdRightErr) ? pdRightErr : new Array(pdRight.length).fill(0);

    errorRightG.selectAll("path.error-line.right")
        .data(yRightInit.map((v, i) => ({ x: xRightInit[i], v, err: yErrRightInit[i], i })))
        .join("path")
        .attr("class", "error-line right") // Reuse error style
        .attr("d", d => {
            if (!d.err) return "";
            let cx = x(d.x);
            let yTop = y(d.v + d.err);
            let yBot = y(d.v - d.err);
            let w = (currentWidthsPx[d.i] || 5) * 0.3;
            if (isNaN(w) || w <= 0) w = 2;
            return `M ${cx},${yBot} L ${cx},${yTop} M ${cx - w},${yTop} L ${cx + w},${yTop} M ${cx - w},${yBot} L ${cx + w},${yBot}`;
        });

    // console.log(svg);
    // console.log(svg.selectAll("g"));
    // return svg;

}

// Run live data display
async function runUpdateGraph() {

    // Initialise variables for timing
    let startPlotting = performance.now();
    let loopTime = 1000 / frameRate;
    let endPlotting = performance.now();
    let elapsedTime = endPlotting - startPlotting;
    let waitTime = loopTime - elapsedTime;
    // console.log(curFrame);
    // console.log(measurements);

    // Only loop while required and not exceeding number of measurements
    do {
        if (curFrame >= measurements) {
            toggleButtonState();
            curFrame = 1;
            break;
        } else {
            startPlotting = performance.now();
            loopTime = 1000 / frameRate;
            dataSlice = loadDataSlice(dataJSON, curFrame);

            // Keep slider visually in sync with playing animation
            const slider = document.getElementById('frameSlider');
            if (slider) {
                slider.value = curFrame;
                const readout = document.getElementById("frameReadout");
                if (readout) readout.innerText = curFrame;
            }

            await plotGraph(dataSlice);
            curFrame++;
            endPlotting = performance.now();
            elapsedTime = endPlotting - startPlotting;
            waitTime = Math.max(0, loopTime - elapsedTime);
            await new Promise(resolve => setTimeout(resolve, waitTime));
        }
    }
    while (isRunning === true)

}

// Combine plotting into single asynchronous function
async function makeAndPopulateGraph(dataSlice) {

    makeGraph(dataSlice);
    // Pass the svg to plotGraph function
    plotGraph(dataSlice);

}

// Function plotGraph will obtain all the values from the data file, plot them
// and define their characteristics
// Duplicated from SER function updateGraph
async function plotGraph(dataSlice) {

    // Extract data from data slice to set up plot
    let pdRight = dataSlice.right["pdy"];
    let pdRightErr = dataSlice.right["pdsigmay"];
    let kellRight = dataSlice.right["kelleter"];
    let bortRight = dataSlice.right["bortfeld"];
    let fitX = dataSlice["fitx"];
    let pdX = dataSlice["pdx"];
    let bandwidths = dataSlice["bandwidths"];

    let pdLeft = dataSlice.left["pdy"];
    let pdLeftErr = dataSlice.left["pdsigmay"];
    let kellLeft = dataSlice.left["kelleter"];
    let bortLeft = dataSlice.left["bortfeld"];

    const xNum = (pdX || []).map(Number);
    const lineXNum = (fitX || []).map(Number);

    // --- X Axis Logic ---
    // "Cut the Pipe" approach here.
    // If Auto Scale is ON, the system drives the bus: we calculate the max data range 
    // and force it into the input box (overwriting anything user type).
    // If OFF, we listen to the input box, giving you full manual control.
    const xInput = document.getElementById("xMaxInput");
    let xMax = 0;

    // 1a. Calculate what the system thinks the max should be
    const calcXMax = d3.max(xNum) || 300;

    // 1b. Decide who's in charge system or user for scaling
    if (FLAGS.autoScale) {
        xMax = roundToSensible(calcXMax); // Round it!
        if (xInput) {
            xInput.value = xMax; // Aggressive overwrite (Snap Back)
        }
    } else {
        // Manual: Read box
        if (xInput) {
            let val = parseFloat(xInput.value);
            // Safety fallback if the box is empty or invalid
            if (isNaN(val) || val <= 0) val = calcXMax;
            xMax = val;
        }
    }

    // Apply the domain to the scale (X always starts at 0 for physics)
    x.domain([0, xMax]);
    // Note: X-axis .nice() might still be useful or we can remove it too if strictness needed. 
    // For now leaving X alone unless requested.
    x.range([X_PAD, innerW]);
    xAxisG.call(d3.axisBottom(x));

    // 2. Recalculate Bar Widths (geometry might have changed)
    const newWidthsMM = calcBandwidths(xNum);
    currentWidthsPx = getWidthsPx(newWidthsMM, x, xNum, SHRINK_FACTOR);

    // --- Y Axis Logic ---
    // Same logic as X: Auto Scale acts as a hard link between data and display.
    const yInput = document.getElementById("yMaxInput");
    let yMax = 5;

    // 1. Find the highest peak among all active datasets (Bars Left, Bars Right, Kel, Bort)
    let calcYMax = 5;
    let calcYMin = 0;
    if (FLAGS.plotBars && pdLeft && pdLeft.length > 0) {
        calcYMax = Math.max(calcYMax, d3.max(pdLeft, d => +d));
        calcYMin = Math.min(calcYMin, d3.min(pdLeft, d => +d));
    }
    if (FLAGS.plotBars && pdRight && pdRight.length > 0) {
        calcYMax = Math.max(calcYMax, d3.max(pdRight, d => +d));
        calcYMin = Math.min(calcYMin, d3.min(pdRight, d => +d));
    }
    if (FLAGS.plotKelL && kellLeft && kellLeft.length > 0) {
        calcYMax = Math.max(calcYMax, d3.max(kellLeft, d => +d));
        calcYMin = Math.min(calcYMin, d3.min(kellLeft, d => +d));
    }
    if (FLAGS.plotKelR && kellRight && kellRight.length > 0) {
        calcYMax = Math.max(calcYMax, d3.max(kellRight, d => +d));
        calcYMin = Math.min(calcYMin, d3.min(kellRight, d => +d));
    }
    if (FLAGS.plotBortL && bortLeft && bortLeft.length > 0) {
        calcYMax = Math.max(calcYMax, d3.max(bortLeft, d => +d));
        calcYMin = Math.min(calcYMin, d3.min(bortLeft, d => +d));
    }
    if (FLAGS.plotBortR && bortRight && bortRight.length > 0) {
        calcYMax = Math.max(calcYMax, d3.max(bortRight, d => +d));
        calcYMin = Math.min(calcYMin, d3.min(bortRight, d => +d));
    }

    // Add a little breathing room (5%) so the peak doesn't touch the ceiling
    calcYMax = Math.ceil(calcYMax * 1.05);

    // Hard-pin Y-min to exactly -1 pC — axis never chases negative data.
    // Bars below -1 are clipped visually; you just see them hit the floor.
    calcYMin = -1;
    // calcYMin = Math.min(calcYMin, -1); // alternative: expands axis to show full extent of negative data

    let yMin = calcYMin;

    // 2. Route the decision
    let yMinInputBox = document.getElementById("yMinInput");

    if (FLAGS.autoScale) {
        yMax = calcYMax; // Just the calculated max (+5%), no extra rounding
        if (yInput) {
            yInput.value = yMax; // Aggressive overwrite (Snap Back) again
        }
        if (yMinInputBox) yMinInputBox.value = yMin;
    } else {
        // Manual Mode: READ from box
        if (yInput) {
            let val = parseFloat(yInput.value);
            if (isNaN(val) || val <= 0) val = calcYMax; // Fallback if typed junk
            yMax = val;
        }
        if (yMinInputBox) {
            let val = parseFloat(yMinInputBox.value);
            if (isNaN(val)) val = calcYMin;
            if (val >= yMax) {
                val = yMax - 1;
                yMinInputBox.value = val;
            }
            yMin = val;
        }
    }

    // Apply
    if (y.domain()[1] !== yMax || y.domain()[0] !== yMin) {
        // REMOVED .nice() to enforce the exact rounded limit requested
        y.domain([yMin, yMax]);
        yAxisG.call(d3.axisLeft(y));
    }

    // 4. Update Bars
    // We find the peak index to optionally highlight it
    const peakIdx = (pdLeft && pdLeft.length > 0) ? pdLeft.indexOf(Math.max(...pdLeft)) : -1;

    barsG.selectAll("rect")
        .data((pdLeft || []).map((v, i) => ({ x: xNum[i], v, i })), d => `bar-${d.i}`)
        .join(
            enter => enter.append("rect")
                .attr("class", d => {
                    // Logic: If highlighting is on and this is the peak, use special class
                    if (FLAGS.highlightPeak && d.i === peakIdx) {
                        return FLAGS.peakAsNegativeColor ? "bar negative" : "bar peak";
                    }
                    return "bar positive";
                })
                .attr("x", d => x(d.x) - currentWidthsPx[d.i] / 2)
                .attr("y", d => y(Math.max(0, d.v)))
                .attr("width", d => currentWidthsPx[d.i])
                .attr("height", d => Math.abs(y(0) - y(d.v))),

            updateSel => updateSel
                .attr("class", d => {
                    if (FLAGS.highlightPeak && d.i === peakIdx) {
                        return FLAGS.peakAsNegativeColor ? "bar negative" : "bar peak";
                    }
                    return "bar positive";
                })
                .attr("x", d => x(d.x) - currentWidthsPx[d.i] / 2)
                .attr("y", d => y(Math.max(0, d.v)))
                .attr("width", d => currentWidthsPx[d.i])
                .attr("height", d => Math.abs(y(0) - y(d.v))),

            exit => exit.remove()
        );

    // --- Right Bars Update (Section 4) ---
    // Only plot if data exists. 
    if (pdRight && pdRight.length > 0) {
        // Ensure X exists, fallback to Left X if not provided (should be provided)
        const xNum = (pdX && pdX.length === pdRight.length) ? pdX : xNum;

        barsRightG.selectAll("rect")
            .data(pdRight.map((v, i) => ({ x: xNum[i], v, i })))
            .join("rect")
            .attr("display", null) // Show
            .attr("x", d => x(d.x) - currentWidthsPx[d.i] / 2)
            .attr("width", d => currentWidthsPx[d.i])
            .attr("y", d => y(Math.max(0, d.v)))
            .attr("height", d => Math.abs(y(0) - y(d.v)));
    } else {
        // Hide if no data
        barsRightG.selectAll("rect").attr("display", "none");
    }

    // --- Error Bars ---
    // V10: Render simple vertical lines (y - err to y + err) centered on bar
    // --- Error Bars Update (Section 4) ---
    // V10: Mutate existing lines. 
    // We re-bind data to update positions, just like bars.
    errorG.selectAll("path.error-line")
        .data((pdLeft || []).map((v, i) => ({ x: xNum[i], v, err: (pdLeftErr ? pdLeftErr[i] : 0), i })))
        .join("path")
        .attr("class", "error-line")
        .attr("d", d => {
            if (!d.err) return "";
            let cx = x(d.x);
            let yTop = y(d.v + d.err);
            let yBot = y(d.v - d.err);
            let w = (currentWidthsPx[d.i] || 5) * 0.3;
            if (isNaN(w) || w <= 0) w = 2;
            return `M ${cx},${yBot} L ${cx},${yTop} M ${cx - w},${yTop} L ${cx + w},${yTop} M ${cx - w},${yBot} L ${cx + w},${yBot}`;
        });

    // --- Right Error Bars Update ---
    if (pdRight && pdRight.length > 0) {
        const eR = (pdRightErr) ? pdRightErr : new Array(pdRight.length).fill(0);

        errorRightG.selectAll("path.error-line.right")
            .data(pdRight.map((v, i) => ({ x: xNum[i], v, err: eR[i], i })))
            .join("path")
            .attr("class", "error-line right")
            .attr("display", null)
            .attr("d", d => {
                if (!d.err) return "";
                let cx = x(d.x);
                let yTop = y(d.v + d.err);
                let yBot = y(d.v - d.err);
                let w = (currentWidthsPx[d.i] || 5) * 0.3;
                if (isNaN(w) || w <= 0) w = 2;
                return `M ${cx},${yBot} L ${cx},${yTop} M ${cx - w},${yTop} L ${cx + w},${yTop} M ${cx - w},${yBot} L ${cx + w},${yBot}`;
            });
    } else {
        errorRightG.selectAll("path.error-line.right").attr("display", "none");
    }

    // --- Overlays (Kelleter / Bortfeldt) ---
    const lenX = lineXNum.length;

    // Build a line generator that uses the *same* x and y scales as bars
    const lineGen = d3.line()
        .x((d, i) => x(lineXNum[i]))
        .y(d => y(d))
        .curve(d3.curveLinear);

    // Kelleter Left
    if (FLAGS.plotKelL && kellLeft && kellLeft.length > 0 && lenX > 1) {
        const safeLen = Math.min(kellLeft.length, lenX);
        const safeData = kellLeft.slice(0, safeLen);
        const safeLineGen = d3.line().x((d, i) => x(lineXNum[i])).y(d => y(+d));
        kelPathL.attr("d", safeLineGen(safeData));
        kelPathL.attr("display", null);
    } else {
        kelPathL.attr("d", "");
        kelPathL.attr("display", "none");
    }

    // Kelleter Right
    // Check if we have data, even if lengths slightly mismatch
    if (FLAGS.plotKelR && kellRight && kellRight.length > 0 && lenX > 1) {
        // Use minimum length to prevent indexing errors
        const safeLen = Math.min(kellRight.length, lenX);
        // Create safe slice of data for plotting
        const safeData = kellRight.slice(0, safeLen);
        // We need a custom line generator for the sliced data that matches indices
        const safeLineGen = d3.line()
            .x((d, i) => x(lineXNum[i])) // Matches x at same index
            .y(d => y(+d)); // Coerce to number

        kelPathR.attr("d", safeLineGen(safeData));
        kelPathR.attr("display", null);

        // Warn if mismatch found (only once or debug)
        if (kellRight.length !== lenX && FLAGS.debug) console.warn("Mismatch Kel:", kellRight.length, "vs LineX:", lenX);
    } else {
        kelPathR.attr("d", "");
        kelPathR.attr("display", "none");
    }

    // Bortfeldt Left
    if (FLAGS.plotBortL && bortLeft && bortLeft.length > 0 && lenX > 1) {
        const safeLen = Math.min(bortLeft.length, lenX);
        const safeData = bortLeft.slice(0, safeLen);
        const safeLineGen = d3.line().x((d, i) => x(lineXNum[i])).y(d => y(+d));
        bortPathL.attr("d", safeLineGen(safeData));
        bortPathL.attr("display", null);
    } else {
        bortPathL.attr("d", "");
        bortPathL.attr("display", "none");
    }

    // Bortfeldt Right
    if (FLAGS.plotBortR && bortRight && bortRight.length > 0 && lenX > 1) {
        const safeLen = Math.min(bortRight.length, lenX);
        const safeData = bortRight.slice(0, safeLen);
        const safeLineGen = d3.line()
            .x((d, i) => x(lineXNum[i]))
            .y(d => y(+d)); // Coerce to number

        bortPathR.attr("d", safeLineGen(safeData));
        bortPathR.attr("display", null);
    } else {
        bortPathR.attr("d", "");
        bortPathR.attr("display", "none");
    }

    // --- Absolute Difference (RHS) ---
    let diffArr = [];
    let diffMaxAbs = 0;

    if (FLAGS.plotDiff && pdLeft && pdRight) {
        const minLen = Math.min(pdLeft.length, pdRight.length, xNum.length);
        for (let i = 0; i < minLen; i++) {
            let leftVal = +pdLeft[i];
            let rightVal = +pdRight[i];
            let sumVal = rightVal + leftVal;
            // Normalized Difference (R - L) / (R + L)
            let diffVal = sumVal !== 0 ? (rightVal - leftVal) / sumVal : 0;

            diffArr.push({ x: xNum[i], v: diffVal });
            if (Math.abs(diffVal) > diffMaxAbs) diffMaxAbs = Math.abs(diffVal);
        }
    }

    // Scale the Diff Axis Symmetrically to naturally center 0 at middle of the page
    if (FLAGS.plotDiff && diffArr.length > 0) {
        let limit = (diffMaxAbs * 1.1) || 0.1; // 10% breathing room

        // Force domain to be symmetrical around 0. 
        // Range stays [innerH, 0] so 0 is exactly at innerH/2
        yDiffScale.domain([-limit, limit]);

        // Update the axis UI
        plotG.select(".diff-axis").call(d3.axisRight(yDiffScale));
        plotG.selectAll(".diff-axis, .right-label").attr("display", null);

        // Draw the Line
        const diffLineGen = d3.line()
            .x(d => x(d.x))
            .y(d => yDiffScale(d.v))
            .curve(d3.curveLinear); // Connect the dots smoothly instead of stepping

        diffPath.attr("d", diffLineGen(diffArr));
        diffPath.attr("display", null);
    } else {
        diffPath.attr("d", "");
        diffPath.attr("display", "none");
        plotG.selectAll(".diff-axis, .right-label").attr("display", "none");
    }

    // --- Peak Highlighting (Dots for Lines) ---
    // We clear old dots first, then draw new ones if needed
    dotsG.selectAll(".peak-dot").remove();

    if (FLAGS.highlightPeak) {
        // Helper to draw a dot
        const drawDot = (arr, className) => {
            if (!arr || arr.length === 0) return;
            // Find max value and its index
            let maxVal = -Infinity;
            let maxIdx = -1;
            for (let i = 0; i < arr.length; i++) {
                const val = +arr[i];
                if (val > maxVal) { maxVal = val; maxIdx = i; }
            }

            if (maxIdx !== -1 && maxIdx < lineXNum.length) {
                dotsG.append("circle")
                    .attr("class", `peak-dot ${className}`)
                    .attr("cx", x(lineXNum[maxIdx]))
                    .attr("cy", y(maxVal))
                    .attr("r", 5);
            }
        };

        // Only draw if the line itself is enabled!
        if (FLAGS.plotKelR) drawDot(kellRight, "keller");
        if (FLAGS.plotBortR) drawDot(bortRight, "bortfeldt");
    }

    // Ensure visual stacking: lines on top of bars
    linesG.raise();

    // Re-assert overlay position — SVG drawing can trigger ResizeObserver
    // reflow which may attempt to shift the overlay before settling
    positionOverlay();

    // Sync X-Y tracker dot
    if (typeof updateSpotTracker === 'function') updateSpotTracker(dataSlice);

};

// V12 Responsive Handler
// Debounce to prevent lag during drag-resize
let resizeTimer = null;
const resizeObserver = new ResizeObserver(() => {
    clearTimeout(resizeTimer);
    resizeTimer = setTimeout(() => {
        const dims = getChartDimensions();
        W = dims.W;
        H = dims.H;
        innerW = W - M.left - M.right;
        innerH = H - M.top - M.bottom;

        // Update SVG size
        svg.attr("width", W).attr("height", H);

        // Update clip-path
        svg.select("#plot-clip rect")
            .attr("width", innerW).attr("height", innerH);

        // Update scale ranges
        x.range([X_PAD, innerW]);
        y.range([innerH, 0]);
        yDiffScale.range([innerH, 0]);

        // Update axis positions
        xAxisG.attr("transform", `translate(0,${innerH})`).call(d3.axisBottom(x));
        yAxisG.call(d3.axisLeft(y));
        yDiffAxisG.attr("transform", `translate(${innerW},0)`).call(d3.axisRight(yDiffScale));

        // Update labels position
        d3.select("#x-axis-label").attr("x", innerW).attr("y", innerH + (M.bottom - 26));
        d3.select("#y-axis-label").attr("x", -innerH / 2).attr("y", -M.left + 20);
        d3.select("#y-diff-axis-label").attr("x", -innerH / 2).attr("y", innerW + M.right - 20);

        // Keep overlay aligned with axes after resize
        positionOverlay();

        // Re-render current frame if data is loaded
        if (typeof dataJSON !== 'undefined' && dataJSON.right) {
            dataSlice = loadDataSlice(dataJSON, curFrame);
            plotGraph(dataSlice);
        }
    }, 150); // 150ms debounce
});

// Observe the plot container
const plotContainer = document.getElementById("plotArea");
if (plotContainer) resizeObserver.observe(plotContainer);
