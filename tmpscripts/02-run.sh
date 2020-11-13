#!/bin/bash

export SCRIPT_DIR=$SCRIPTS_ROOT

# Run ORDS
echo "##### Starting ORDS #####"
if [ $UID = "0" ]; then
  runuser oracle -m -s /bin/bash -c ". $SCRIPT_DIR/package/runOrds.sh"
else
  . $SCRIPT_DIR/package/runOrds.sh
fi