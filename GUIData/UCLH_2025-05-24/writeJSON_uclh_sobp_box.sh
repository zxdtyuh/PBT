#!/bin/bash

python3 /unix/www/html/pbt/PDdisplay/bateman/scripts/parseQuARCFittedData.py -v -o 20250524_Run070_fitted_50Hz.json -r 20250524_Run070_a_fitted_50Hz.txt -l 20250524_Run070_b_fitted_50Hz.txt

python3 /unix/www/html/pbt/PDdisplay/bateman/scripts/parseQuARCFittedData.py -v -o 20250524_Run071_fitted_50Hz.json -r 20250524_Run071_a_fitted_50Hz.txt -l 20250524_Run071_b_fitted_50Hz.txt

python3 /unix/www/html/pbt/PDdisplay/bateman/scripts/parseQuARCFittedData.py -v -o 20250524_Run070_fitted_100Hz.json -r 20250524_Run070_a_fitted_100Hz.txt -l 20250524_Run070_b_fitted_100Hz.txt

python3 /unix/www/html/pbt/PDdisplay/bateman/scripts/parseQuARCFittedData.py -v -o 20250524_Run071_fitted_100Hz.json -r 20250524_Run071_a_fitted_100Hz.txt -l 20250524_Run071_b_fitted_100Hz.txt

python3 /unix/www/html/pbt/PDdisplay/bateman/scripts/parseQuARCFittedData.py -v -o 20250524_Run070_fitted_200Hz.json -r 20250524_Run070_a_fitted_200Hz.txt -l 20250524_Run070_b_fitted_200Hz.txt

python3 /unix/www/html/pbt/PDdisplay/bateman/scripts/parseQuARCFittedData.py -v -o 20250524_Run071_fitted_200Hz.json -r 20250524_Run071_a_fitted_200Hz.txt -l 20250524_Run071_b_fitted_200Hz.txt

python3 /unix/www/html/pbt/PDdisplay/bateman/scripts/parseQuARCFittedData.py -v -o 20250524_Run070_fitted_500Hz.json -r 20250524_Run070_a_fitted_500Hz.txt -l 20250524_Run070_b_fitted_500Hz.txt

python3 /unix/www/html/pbt/PDdisplay/bateman/scripts/parseQuARCFittedData.py -v -o 20250524_Run071_fitted_500Hz.json -r 20250524_Run071_a_fitted_500Hz.txt -l 20250524_Run071_b_fitted_500Hz.txt


chgrp pbt *.json
chmod a+x,g+w *.json

exit 0
