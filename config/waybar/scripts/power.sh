#!/bin/bash

# -p layer-shell : Ensures it sits above windows
# -b 2 : Sets transparency
# -t 45 : TOP MARGIN (Push down 45px to clear the bar)
# -r 20 : RIGHT MARGIN (Push left 20px to align with button)
# -l 0 -b 0 : Reset other margins
wlogout --protocol layer-shell -b 5 -t 45 -r 15 -l 0 -b 0
