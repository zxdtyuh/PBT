/**
 * live_loader.js — v12.1
 *
 * Polls bars_live.json at 25Hz and passes data directly to plotGraph().
 * Python backend now writes the exact QuARC structure plotGraph() expects,
 * so no morphing is needed — just fetch, add bandwidths, and plot.
 *
 * Button wired in live.html to toggleLive() — no conflict with quarcD3GUI.js.
 */

let liveRunning = false;
let graphInitialized = false;
let lastDataSlice = null; // stores last received frame for checkbox redraws when stopped

// Safe stub so quarcD3GUI.js requestUpdate() never crashes on dataJSON.right
let dataJSON = new Proxy({}, { get: () => null });

// Called by the Measure/Stop button in live.html
// function toggleLive() {
//     if (liveRunning) {
//         liveRunning = false;
//         fetch('php_backend/executeDAQ.php?command=STOP')
//             .catch(e => console.warn('Stop signal failed:', e));
//         document.getElementById('content').innerHTML = 'Measurement stopped.';
//         const btn = document.getElementById('DAQbutton');
//         btn.classList.remove('red');
//         btn.classList.add('green');
//         btn.innerText = 'Measure';
//     } else {
//         liveRunning = true;
//         fetch('php_backend/executeDAQ.php?command=MEASURE_CONTINUOUS')
//             .catch(e => console.warn('Start signal failed:', e));
//         document.getElementById('content').innerHTML = 'Measurement running...';
//         const btn = document.getElementById('DAQbutton');
//         btn.classList.remove('green');
//         btn.classList.add('red');
//         btn.innerText = 'Stop';
//         runLiveLoop();
//     }
// }

// New for Python -Sam 27/5/2026
function toggleLive() {
    if (liveRunning) {
        liveRunning = false;
        fetch('php_backend/executeDAQ.php?command=STOP')
            .catch(e => console.warn('Stop signal failed:', e));
        document.getElementById('content').innerHTML = 'Measurement stopped.';
        const btn = document.getElementById('DAQbutton');
        btn.classList.remove('red');
        btn.classList.add('green');
        btn.innerText = 'Measure';
    } else {
        liveRunning = true;
        fetch('/loop_extractor') // trigger Python loop extractor
            .catch(e => console.warn('Start signal failed:', e));
        document.getElementById('content').innerHTML = 'Measurement running...';
        const btn = document.getElementById('DAQbutton');
        btn.classList.remove('green');
        btn.classList.add('red');
        btn.innerText = 'Stop';
        runLiveLoop();
    }
}

// Bandwidth calculator
function calcBandwidths(sheetMids) {
    if (!sheetMids || sheetMids.length === 0) return [];
    const bw = [];
    for (let i = 0; i < sheetMids.length - 1; i++) {
        bw.push(sheetMids[i + 1] - sheetMids[i]);
    }
    bw.push(bw[bw.length - 1] || 3);
    return bw;
}

// Core polling loop
async function runLiveLoop() {
    while (liveRunning) {
        const start = performance.now();
        try {
            const response = await fetch('bars_live.json?' + Date.now(), { cache: 'no-store' });
            if (response.ok) {
                const text = await response.text();
                if (text.trim() !== '') {
                    const dataSlice = JSON.parse(text);

                    // Add bandwidths if Python didn't include them
                    if (!dataSlice.bandwidths) {
                        dataSlice.bandwidths = calcBandwidths(dataSlice.pdx);
                    }

                    lastDataSlice = dataSlice; // always keep last frame
                    if (!graphInitialized) {
                        await makeAndPopulateGraph(dataSlice);
                        graphInitialized = true;
                    } else {
                        await plotGraph(dataSlice);
                    }

                }
            }
        } catch (e) {
            console.error('Live poll error:', e);
        }

        const elapsed = performance.now() - start;
        const wait = Math.max(10, (1000 / frameRate) - elapsed);
        await new Promise(r => setTimeout(r, wait));
    }
}
