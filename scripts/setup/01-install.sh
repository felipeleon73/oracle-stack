#!/bin/bash
export SCRIPT_DIR=$SCRIPTS_ROOT
export PREFIX=@

# Install APEX
echo "##### Installing APEX #####"
if [ $UID = "0" ]; then
  runuser oracle -m -s /bin/bash -c ". $SCRIPT_DIR/package/installApex.sh"
else
  . $SCRIPT_DIR/package/installApex.sh
fi

# Install ORDS
echo "##### Installing ORDS #####"
if [ $UID = "0" ]; then
  runuser oracle -m -s /bin/bash -c ". $SCRIPT_DIR/package/installOrds.sh"
else
  . $SCRIPT_DIR/package/installOrds.sh
fi

# Post-installation Tasks for APEX and ORDS
if [ $UID = "0" ]; then
  runuser oracle -m -s /bin/bash -c ". $SCRIPT_DIR/package/postInstallApexOrds.sh"
else
  . $SCRIPT_DIR/package/postInstallApexOrds.sh
fi

# Setup Oracle Wallet for APEX
if [ $UID = "0" ]; then
  runuser oracle -m -s /bin/bash -c ". $SCRIPT_DIR/package/setupBaseWallet.sh"
else
  . $SCRIPT_DIR/package/setupBaseWallet.sh
fi