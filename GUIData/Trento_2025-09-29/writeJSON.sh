#!/bin/bash

python3 /unix/www/html/pbt/PDdisplay/jolly/scripts/parseQuARCFittedData.py -v -o 20250929_Run024_fitted_25Hz.json -r 20250929_Run024_a_fitted_25Hz.txt -l 20250929_Run024_b_fitted_25Hz.txt

python3 /unix/www/html/pbt/PDdisplay/jolly/scripts/parseQuARCFittedData.py -v -o 20250929_Run025_fitted_25Hz.json -r 20250929_Run025_a_fitted_25Hz.txt -l 20250929_Run025_b_fitted_25Hz.txt

python3 /unix/www/html/pbt/PDdisplay/jolly/scripts/parseQuARCFittedData.py -v -o 20250929_Run027_fitted_25Hz.json -r 20250929_Run027_a_fitted_25Hz.txt -l 20250929_Run027_b_fitted_25Hz.txt

python3 /unix/www/html/pbt/PDdisplay/jolly/scripts/parseQuARCFittedData.py -v -o 20250929_Run028_fitted_25Hz.json -r 20250929_Run028_a_fitted_25Hz.txt -l 20250929_Run028_b_fitted_25Hz.txt

python3 /unix/www/html/pbt/PDdisplay/jolly/scripts/parseQuARCFittedData.py -v -o 20250929_Run029_fitted_25Hz.json -r 20250929_Run029_a_fitted_25Hz.txt -l 20250929_Run029_b_fitted_25Hz.txt

python3 /unix/www/html/pbt/PDdisplay/jolly/scripts/parseQuARCFittedData.py -v -o 20250929_Run030_fitted_25Hz.json -r 20250929_Run030_a_fitted_25Hz.txt -l 20250929_Run030_b_fitted_25Hz.txt

python3 /unix/www/html/pbt/PDdisplay/jolly/scripts/parseQuARCFittedData.py -v -o 20250929_Run032_fitted_25Hz.json -r 20250929_Run032_a_fitted_25Hz.txt -l 20250929_Run032_b_fitted_25Hz.txt

python3 /unix/www/html/pbt/PDdisplay/jolly/scripts/parseQuARCFittedData.py -v -o 20250929_Run033_fitted_25Hz.json -r 20250929_Run033_a_fitted_25Hz.txt -l 20250929_Run033_b_fitted_25Hz.txt

python3 /unix/www/html/pbt/PDdisplay/jolly/scripts/parseQuARCFittedData.py -v -o 20250929_Run034_fitted_25Hz.json -r 20250929_Run034_a_fitted_25Hz.txt -l 20250929_Run034_b_fitted_25Hz.txt

python3 /unix/www/html/pbt/PDdisplay/jolly/scripts/parseQuARCFittedData.py -v -o 20250929_Run035_fitted_25Hz.json -r 20250929_Run035_a_fitted_25Hz.txt -l 20250929_Run035_b_fitted_25Hz.txt

python3 /unix/www/html/pbt/PDdisplay/jolly/scripts/parseQuARCFittedData.py -v -o 20250929_Run036_fitted_25Hz.json -r 20250929_Run036_a_fitted_25Hz.txt -l 20250929_Run036_b_fitted_25Hz.txt

python3 /unix/www/html/pbt/PDdisplay/jolly/scripts/parseQuARCFittedData.py -v -o 20250929_Run037_fitted_25Hz.json -r 20250929_Run037_a_fitted_25Hz.txt -l 20250929_Run037_b_fitted_25Hz.txt

python3 /unix/www/html/pbt/PDdisplay/jolly/scripts/parseQuARCFittedData.py -v -o 20250929_Run038_fitted_25Hz.json -r 20250929_Run038_a_fitted_25Hz.txt -l 20250929_Run038_b_fitted_25Hz.txt

chgrp pbt *.json
chmod a+x,g+w *.json

exit 0
