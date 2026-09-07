// Beam Spot Tracker — X/Y asymmetry calculation
// Horizontal: (R-L)/(R+L), Vertical: (B-T)/(B+T)
// Dot moves frame-to-frame based on detector balance.

const SPOT_M = { top: 30, right: 20, bottom: 50, left: 50 };

// Normalised asymmetry scales [-1.1, 1.1]
const spotX = d3.scaleLinear().domain([-1.1, 1.1]);
const spotY = d3.scaleLinear().domain([-1.1, 1.1]);

const spotSvg = d3.select("#spotChart");
const spotG   = spotSvg.append("g").attr("transform", `translate(${SPOT_M.left},${SPOT_M.top})`);

// Center crosshairs
const spotRefX = spotG.append("line").attr("class", "spot-ref").attr("y1", 0);
const spotRefY = spotG.append("line").attr("class", "spot-ref").attr("x1", 0);

// Axes
const spotXAxisG = spotG.append("g").attr("class", "axis");
const spotYAxisG = spotG.append("g").attr("class", "axis");

// Axis labels
spotG.append("text")
    .attr("class", "axis-label")
    .attr("text-anchor", "middle")
    .attr("id", "spotXLabel")
    .text("Beam X  (R−L)/(R+L)");

spotG.append("text")
    .attr("class", "axis-label")
    .attr("transform", "rotate(-90)")
    .attr("text-anchor", "middle")
    .attr("id", "spotYLabel")
    .text("Beam Y  (B−T)/(B+T)");

// Plot title
spotG.append("text")
    .attr("class", "axis-label")
    .attr("id", "spotTitle")
    .attr("text-anchor", "middle")
    .attr("font-size", "11px")
    .attr("fill", "slategray")
    .text("Beam Spot Position");

// Target Y label note (shown when Y data unavailable)
spotG.append("text")
    .attr("id", "spotYNote")
    .attr("text-anchor", "middle")
    .attr("font-size", "9px")
    .attr("fill", "#aaa")
    .text("Y awaiting top/bottom detectors");

// The beam dot
const spotDot = spotG.append("circle")
    .attr("r", 7)
    .attr("fill", "crimson")
    .attr("stroke", "black")
    .attr("stroke-width", 1.5)
    .attr("opacity", 0.85);

// Re-center and force squareness on window resize
function resizeSpotTracker() {
    const container = document.getElementById("spotArea");
    if (!container) return;

    const rect = container.getBoundingClientRect();
    const sw   = Math.floor(rect.width);
    const sh   = Math.floor(rect.height);
    if (sw < 60 || sh < 60) return;

    // Dimensions of the available inner area
    const iW_full = sw - SPOT_M.left - SPOT_M.right;
    const iH_full = sh - SPOT_M.top  - SPOT_M.bottom;

    // Force squareness: use the smaller dimension
    const squareSize = Math.min(iW_full, iH_full);
    
    // Calculate offsets to center the square plot inside the column
    const offsetX = (iW_full - squareSize) / 2;
    const offsetY = (iH_full - squareSize) / 2;

    spotSvg.attr("width", sw).attr("height", sh);
    
    // Shift the main group to center the square plot within the container
    spotG.attr("transform", `translate(${SPOT_M.left + offsetX},${SPOT_M.top + offsetY})`);

    spotX.range([0, squareSize]);
    spotY.range([squareSize, 0]);

    // Reference lines
    spotRefX.attr("x1", 0).attr("x2", squareSize).attr("y1", spotY(0)).attr("y2", spotY(0))
    spotRefY.attr("x1", spotX(0)).attr("x2", spotX(0)).attr("y1", 0).attr("y2", squareSize);

    // Axes
    spotXAxisG.attr("transform", `translate(0,${squareSize})`).call(d3.axisBottom(spotX).ticks(5));
    spotYAxisG.call(d3.axisLeft(spotY).ticks(5));

    // Labels
    d3.select("#spotXLabel").attr("x", squareSize / 2).attr("y", squareSize + SPOT_M.bottom - 10);
    d3.select("#spotYLabel").attr("x", -squareSize / 2).attr("y", -SPOT_M.left + 15);
    d3.select("#spotTitle").attr("x", squareSize / 2).attr("y", -SPOT_M.top / 2 + 5);
    
    // Remove Y-note as requested
    d3.select("#spotYNote").remove();
}

// ResizeObserver on spotArea
const spotResizeObserver = new ResizeObserver(() => resizeSpotTracker());
const spotContainer = document.getElementById("spotArea");
if (spotContainer) spotResizeObserver.observe(spotContainer);
setTimeout(resizeSpotTracker, 100); // initial sizing after layout settles

// --- CSS for reference lines ---
const spotStyle = document.createElement("style");
spotStyle.textContent = `
    .spot-ref {
        stroke: #ccc;
        stroke-width: 1px;
        stroke-dasharray: 4,3;
    }
`;
document.head.appendChild(spotStyle);

// Sum charge: handles Replay (array) or Live (object) formats
function sumCharge(detectorData) {
    if (!detectorData) return 0;
    if (Array.isArray(detectorData)) {
        return d3.sum(detectorData, d => Math.max(0, d.v || 0));
    }
    if (detectorData.pdy && Array.isArray(detectorData.pdy)) {
        return d3.sum(detectorData.pdy, v => Math.max(0, v || 0));
    }
    return 0;
}

// Update loop called from main plotGraph()
function updateSpotTracker(dataSlice) {
    if (!dataSlice || !dataSlice.left || !dataSlice.right) return;

    const Ltotal = sumCharge(dataSlice.left);
    const Rtotal = sumCharge(dataSlice.right);

    // X asymmetry; Y=0 for now (awaiting top/bottom)
    const beamX = (Rtotal + Ltotal) > 0 ? (Rtotal - Ltotal) / (Rtotal + Ltotal) : 0;
    const beamY = 0;

    spotDot.attr("cx", spotX(beamX)).attr("cy", spotY(beamY));
}
