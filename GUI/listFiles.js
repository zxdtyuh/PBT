//const rootDir = document.currentScript.src.substring(0, document.currentScript.src.lastIndexOf('/') + 1);// For PHP scripts (HEP filesystem path)
var dataUrl = '/GUIData/'; // For HTTP requests (HEP URL path)
var dataJSON;
// console.log(rootDir);
// console.log(dataJSON);
var headerHeight;
var plotWidth;
var fileLoaded = false;

// Updated to use fetch instead of XMLHttp

function getFileData(fileExt = "json") {
  let display = document.getElementById("content");
  fetch('replay.py/list', {method: "POST"})
  .then(response => response.json())
  .then(fileList => {
    console.log(fileList);
    display.innerHTML = "Data files loaded: select a file";
    populateMenus(fileList);
    getPlotAreaWidth();
  })
  .catch(e => {
    console.warn('File list fetch failed:', e);
        display.innerHTML = "Waiting for data to load...";
  });
}

// Find and set height of header banner
function getHeaderHeight() {
  const headerArea = document.querySelector("#maintitle");
  headerHeight = headerArea.offsetHeight;
  headerHeight += parseInt(window.getComputedStyle(headerArea).getPropertyValue('margin-top'));
  headerHeight += parseInt(window.getComputedStyle(headerArea).getPropertyValue('margin-bottom'));
  // console.log("Header height inc. margins: " + headerHeight);
}

// Find and set width of plot area
function getPlotAreaWidth() {
  const plotArea = document.querySelector("#plotArea");
  plotWidth = plotArea.getBoundingClientRect().width;
  //   plotWidth += parseInt(window.getComputedStyle(plotArea).getPropertyValue('margin-left'));
  //   plotWidth += parseInt(window.getComputedStyle(plotArea).getPropertyValue('margin-right'));
  // console.log("Plot area width inc. padding: " + plotWidth);
}

function populateMenus(fileList) {
  //   console.log(fileList);
  let directorySel = document.getElementById("dirs");
  let fileSel = document.getElementById("files");
  for (let x in fileList) {
    directorySel.options[directorySel.options.length] = new Option(x, x);
  }
  directorySel.onchange = function () {
    //empty Files dropdowns
    fileSel.length = 1;
    //display correct values
    let z = fileList[this.value];
    fileSel.options[0] = new Option("Select directory to view files", "Files");
    for (let i = 0; i < z.length; i++) {
      fileSel.options[fileSel.options.length] = new Option(z[i], z[i]);
    }
    fileSel.options[0].selected = true;
    //     fileSel.options[1].selected = true;
    //     fileSel.remove(0);
  }
  fileSel.onchange = function () {
    checkHeader();
  }
}

function getFileExtension(filename) {
  return filename.split('.').pop();
}

function checkHeader() {
  let display = document.getElementById("content");
  fileMenu = document.querySelector('#files');
  file = fileMenu.options[fileMenu.selectedIndex].value;
  fileExt = getFileExtension(file);

  if (file === "Files") {
    display.innerHTML = "Data files loaded: select a file";
    fileLoaded = false;
  } else if (fileExt === "txt") {
    readTXTHeader();
  } else if (fileExt === "json") {
    display.innerHTML = "File is a JSON";
    loadDataJSON();
  } else {
    display.innerHTML = "File " + file + " has unknown extension " + fileExt;
  };

}

function loadDataJSON() {
  dirMenu = document.querySelector('#dirs');
  directory = dirMenu.options[dirMenu.selectedIndex].value;
  fileMenu = document.querySelector('#files');
  file = fileMenu.options[fileMenu.selectedIndex].value;
  let display = document.getElementById("content");

  let dataFile;
  if (directory === "Local Data Folder") {
    dataFile = dataUrl + file;
  } else {
    dataFile = dataUrl + directory + "/" + file;
  }
  //     console.log(dataFile);

  let xmlhttp = new XMLHttpRequest();
  xmlhttp.overrideMimeType("application/json");
  xmlhttp.open("GET", dataFile, true);
  xmlhttp.send();
  xmlhttp.onreadystatechange = function () {
    if (xmlhttp.readyState === 4 && xmlhttp.status == "200") {
      dataJSON = JSON.parse(xmlhttp.responseText);
      display.innerHTML = "Loaded data file " + dataFile + "<br />";
      fileLoaded = true;
      dataJSON.right.data["bandwidths"] = calcBandwidths(dataJSON.right.data["pdx"]);
      console.log(dataJSON);
      displayHeaderData();
      refreshDisplay();

      // --- V12 Scrubber Logic ---
      const slider = document.getElementById("frameSlider");
      const readout = document.getElementById("frameReadout");
      let maxFrames = dataJSON.right.data["measurements"] || dataJSON.left.data["measurements"];
      if (slider) {
        slider.max = maxFrames;
        slider.value = 1;
        slider.disabled = false;
        readout.innerText = "1 / " + maxFrames;

        slider.oninput = function () {
          // Update the global curFrame
          curFrame = parseInt(this.value);
          readout.innerText = curFrame + " / " + maxFrames;

          // If we are currently paused, force a redraw IMMEDIATELY
          if (!isRunning && dataJSON) {
            dataSlice = loadDataSlice(dataJSON, curFrame);
            plotGraph(dataSlice);
          }
        };
      }
    } else {
      display.innerHTML = "Attempting to load data file " + dataFile + "...";
    }
  }
}

// Scintillators have different widths. We need to calculate bandwidths individually to plot them accurately.
function calcBandwidths(sheetMids) {
  let bandwidths = [];
  for (var i = 0; i < sheetMids.length - 1; i++) {
    bandwidths.push(sheetMids[i + 1] - sheetMids[i]);
    //         if ( i >= sheetMids.length ) { 
    //             bandwidths[i] = bandwidths[i-1]
    //         } //For last PD in Clatt module. Need to review if this is necessary or if it is handled later
  }
  bandwidths.push(bandwidths[bandwidths.length - 1]);
  return bandwidths;
}

function displayHeaderData() {
  let display = document.getElementById("content");

  let headerText = "Detector: " + dataJSON.header["label"] + "<br />";
  headerText += "Facility: " + dataJSON.header["Facility"] + ", " + dataJSON.header.Room + "<br />";
  headerText += "Recorded: " + dataJSON.header["Date"] + ", " + dataJSON.header.Time + "<br />";
  headerText += "Energy: " + dataJSON.header["Energy"] + "&nbsp;MeV<br />";
  headerText += "Fit rate: " + dataJSON.header["Fit rate"].toString() + "&nbsp;Hz<br />";
  display.innerHTML = headerText;
}

function refreshDisplay() {
  let display = document.getElementById("content");
  display.innerHTML += "<br />Data loaded for plotting<br />";
}




// Moving away from txt files

// function readTXTHeader() {   
//   dirMenu = document.querySelector('#dirs');
//   directory = dirMenu.options[dirMenu.selectedIndex].value;
//   fileMenu = document.querySelector('#files');
//   file = fileMenu.options[fileMenu.selectedIndex].value;
//   let display = document.getElementById("content");
//   let xmlhttp = new XMLHttpRequest();
//   let execString = 'readHeader.php?rootDir=' + rootDir + '&dataDir=' + directory +
//     '&dataFile=' + file + '&debug=true';
//   display.innerHTML = execString;
//   xmlhttp.open("GET", execString);
//   xmlhttp.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
//   xmlhttp.send();
//   xmlhttp.onreadystatechange = function () {
//     if (this.readyState === 4 && this.status === 200) {
//       display.innerHTML = this.responseText;
//     } else {
//       display.innerHTML = "Checking file header...";
//     };
//   }
// }

