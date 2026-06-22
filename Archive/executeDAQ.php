<?php
header('Content-Type: text/plain');
$command      = $_GET['command'] ?? '';
$baseDir      = dirname(__DIR__);
$pythonScript = $baseDir . '/loop_extractor_JSON.py';
$statusFile   = $baseDir . '/logfile_runningStatus.txt';
$logFile      = __DIR__  . '/daq_output.log';
$phpLog       = __DIR__  . '/php_execution.log';
$timestamp    = date('Y-m-d H:i:s');
if ($command === 'MEASURE_CONTINUOUS') {
    file_put_contents($statusFile, 'Running');
    if (!file_exists($pythonScript)) {
        http_response_code(500);
        echo "Error: Python script not found\n";
        exit(1);
    }
    $cmd = "python3 -u \"$pythonScript\" > \"$logFile\" 2>&1 &";
    exec($cmd, $out, $rc);
    file_put_contents($phpLog, "[$timestamp] DAQ started rc=$rc\n", FILE_APPEND);
    echo "DAQ started\n";
} elseif ($command === 'STOP') {
    file_put_contents($statusFile, 'Stopping');
    file_put_contents($phpLog, "[$timestamp] Stop signal written\n", FILE_APPEND);
    echo "Stopped\n";
} else {
    http_response_code(400);
    echo "Unknown command\n";
}
?>
