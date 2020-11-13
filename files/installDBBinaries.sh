#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
#
# Since: December, 2016
# Author: gerald.venzl@oracle.com
# Description: Sets up the unix environment for DB installation.
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

# Convert $1 into upper case via "^^" (bash version 4 onwards)
EDITION=${1^^}

# Check whether edition has been passed on
if [ "$EDITION" == "" ]; then
   echo "ERROR: No edition has been passed on!"
   echo "Please specify the correct edition!"
   exit 1;
fi;

# Check whether correct edition has been passed on
if [ "$EDITION" != "EE" -a "$EDITION" != "SE2" ]; then
   echo "ERROR: Wrong edition has been passed on!"
   echo "Edition $EDITION is no a valid edition!"
   exit 1;
fi;

# Check whether ORACLE_BASE is set
if [ "$ORACLE_BASE" == "" ]; then
   echo "ERROR: ORACLE_BASE has not been set!"
   echo "You have to have the ORACLE_BASE environment variable set to a valid value!"
   exit 1;
fi;

# Check whether ORACLE_HOME is set
if [ "$ORACLE_HOME" == "" ]; then
   echo "ERROR: ORACLE_HOME has not been set!"
   echo "You have to have the ORACLE_HOME environment variable set to a valid value!"
   exit 1;
fi;


# Replace place holders
# ---------------------
sed -i -e "s|###ORACLE_EDITION###|$EDITION|g" $INSTALL_DIR/$INSTALL_RSP && \
sed -i -e "s|###ORACLE_BASE###|$ORACLE_BASE|g" $INSTALL_DIR/$INSTALL_RSP && \
sed -i -e "s|###ORACLE_HOME###|$ORACLE_HOME|g" $INSTALL_DIR/$INSTALL_RSP

# Install Oracle binaries
cd $ORACLE_HOME       && \
mv $INSTALL_DIR/$INSTALL_DB $ORACLE_HOME/ && \
unzip $INSTALL_DB && \
rm $INSTALL_DB    && \
$ORACLE_HOME/runInstaller -silent -force -waitforcompletion -responsefile $INSTALL_DIR/$INSTALL_RSP -ignorePrereqFailure && \
cd $HOME

if $SLIMMING; then
    # Remove not needed components
    # APEX
    rm -rf $ORACLE_HOME/apex && \
    # ORDS
    rm -rf $ORACLE_HOME/ords && \
    # SQL Developer
    rm -rf $ORACLE_HOME/sqldeveloper && \
    # UCP connection pool
    rm -rf $ORACLE_HOME/ucp && \
    # All installer files
    rm -rf $ORACLE_HOME/lib/*.zip && \
    # OUI backup
    rm -rf $ORACLE_HOME/inventory/backup/* && \
    # Network tools help
    rm -rf $ORACLE_HOME/network/tools/help && \
    # Database upgrade assistant
    rm -rf $ORACLE_HOME/assistants/dbua && \
    # Database migration assistant
    rm -rf $ORACLE_HOME/dmu && \
    # Remove pilot workflow installer
    rm -rf $ORACLE_HOME/install/pilot && \
    # Support tools
    rm -rf $ORACLE_HOME/suptools && \
    # Temp location
    rm -rf /tmp/* && \
    # Database files directory
    rm -rf $INSTALL_DIR/database
fi


#install JAVA
echo "##### Extracting Java files ####"
JAVA_DIR_NAME=`tar -tzf $INSTALL_DIR/$INSTALL_JAVA | head -1 | cut -f1 -d"/"` && \
mkdir -p $ORACLE_BASE/product/java && \
tar zxf $INSTALL_DIR/$INSTALL_JAVA --directory $ORACLE_BASE/product/java && \
ln -s $ORACLE_BASE/product/java/$JAVA_DIR_NAME $JAVA_HOME && \
rm $INSTALL_DIR/$INSTALL_JAVA

#Install ORDS
echo "##### Extracting ords files ####"
mkdir -p $ORDS_HOME
unzip -q $INSTALL_DIR/$INSTALL_APEX -d $ORACLE_BASE/product
unzip -q $INSTALL_DIR/$INSTALL_ORDS -d $ORDS_HOME
chown -R oracle:oinstall $APEX_HOME $ORDS_HOME
rm $INSTALL_DIR/$INSTALL_APEX
rm $INSTALL_DIR/$INSTALL_ORDS

#Install sqlcl
echo "##### Extracting SQLCL files ####"
unzip -q $INSTALL_DIR/$INSTALL_SQLCL -d $ORACLE_BASE/product > /dev/null
chown -R oracle:oinstall $SQLCL_HOME
rm -f $INSTALL_DIR/$INSTALL_SQLCL
mv $SQLCL_HOME/bin/sql $SQLCL_HOME/bin/sqlcl 

