# LICENSE UPL 1.0
#
# Copyright (c) 2018, 2020 Oracle and/or its affiliates.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Oracle Database 19c
# 
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# (1) db_home.zip
#     Download Oracle Database 19c Enterprise Edition or Standard Edition 2 for Linux x64
#     from http://www.oracle.com/technetwork/database/enterprise-edition/downloads/index.html
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run: 
#      $ docker build -t oracle/database:19.3.0-${EDITION} . 
#
# Pull base image
# ---------------
FROM oraclelinux:7-slim as base

# Labels
# ------
LABEL "provider"="Oracle"                                               \
      "issues"="https://github.com/oracle/docker-images/issues"         \
      "volume.data"="/opt/oracle/oradata"                               \
      "volume.setup.location1"="/opt/oracle/scripts/setup"              \
      "volume.setup.location2"="/docker-entrypoint-initdb.d/setup"      \
      "volume.startup.location1"="/opt/oracle/scripts/startup"          \
      "volume.startup.location2"="/docker-entrypoint-initdb.d/startup"  \
      "port.listener"="1521"                                            \
      "port.oemexpress"="5500"

# Argument to control removal of components not needed after db software installation
ARG SLIMMING=true
ARG ORACLE_PWD="Oracle19"

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV ORACLE_BASE=/opt/oracle \
    ORACLE_HOME=/opt/oracle/product/19c/dbhome_1 \
    INSTALL_DIR=/opt/install \
    FILES_DIR="files" \
    INSTALL_RSP="db_inst.rsp" \
    CONFIG_RSP="dbca.rsp.tmpl" \
    PWD_FILE="setPassword.sh" \
    RUN_FILE="runOracle.sh" \
    START_FILE="startDB.sh" \
    CREATE_DB_FILE="createDB.sh" \
    SETUP_LINUX_FILE="setupLinuxEnv.sh" \
    CHECK_SPACE_FILE="checkSpace.sh" \
    CHECK_DB_FILE="checkDBStatus.sh" \
    USER_SCRIPTS_FILE="runUserScripts.sh" \
    INSTALL_DB_BINARIES_FILE="installDBBinaries.sh" \
    RELINK_BINARY_FILE="relinkOracleBinary.sh" \
    SLIMMING=$SLIMMING

ENV APEX_HOME=$ORACLE_BASE/product/apex \
    ORDS_HOME=$ORACLE_BASE/product/ords \
    JAVA_HOME=$ORACLE_BASE/product/java/latest \
    SQLCL_HOME=$ORACLE_BASE/product/sqlcl 

# Use second ENV so that variable get substituted
ENV PATH=$ORACLE_HOME/bin:$ORACLE_HOME/OPatch/:/usr/sbin:$JAVA_HOME/bin:$SQLCL_HOME/bin:$PATH \
    LD_LIBRARY_PATH=$ORACLE_HOME/lib:/usr/lib \
    CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib

# Copy files needed during both installation and runtime
# -------------
COPY $FILES_DIR/$SETUP_LINUX_FILE $FILES_DIR/$CHECK_SPACE_FILE $INSTALL_DIR/
COPY $FILES_DIR/$RUN_FILE $FILES_DIR/$START_FILE $FILES_DIR/$CREATE_DB_FILE $FILES_DIR/$CONFIG_RSP \
     $FILES_DIR/$PWD_FILE $FILES_DIR/$CHECK_DB_FILE $FILES_DIR/$USER_SCRIPTS_FILE $FILES_DIR/$RELINK_BINARY_FILE $ORACLE_BASE/

RUN chmod ug+x $INSTALL_DIR/*.sh && \
    sync && \
    $INSTALL_DIR/$CHECK_SPACE_FILE && \
    $INSTALL_DIR/$SETUP_LINUX_FILE && \
    rm -rf $INSTALL_DIR



#############################################
# -------------------------------------------
# Start new stage for installing the database
# -------------------------------------------
#############################################

FROM base AS builder

ARG DB_EDITION

ENV SW_DIR="software" \
    INSTALL_DB="LINUX.X64_193000_db_home.zip" \
    INSTALL_JAVA="jdk-8u271-linux-x64.tar.gz" \
    INSTALL_ORDS="ords-20.2.1.227.0350.zip" \
    INSTALL_APEX="apex_20.2.zip" \
    INSTALL_SQLCL="sqlcl-20.2.0.174.1557.zip"

# Copy DB install file
COPY --chown=oracle:dba $SW_DIR/$INSTALL_DB $SW_DIR/$INSTALL_JAVA $SW_DIR/$INSTALL_APEX $SW_DIR/$INSTALL_ORDS \
     $SW_DIR/$INSTALL_SQLCL $FILES_DIR/$INSTALL_RSP $FILES_DIR/$INSTALL_DB_BINARIES_FILE $INSTALL_DIR/

# Install DB software binaries
USER oracle
RUN chmod ug+x $INSTALL_DIR/*.sh && \
    sync && \
    $INSTALL_DIR/$INSTALL_DB_BINARIES_FILE $DB_EDITION



#############################################
# -------------------------------------------
# Start new layer for database runtime
# -------------------------------------------
#############################################

FROM base

ENV FILES_DIR= \
    SW_DIR=

USER oracle
COPY --chown=oracle:dba --from=builder $ORACLE_BASE $ORACLE_BASE

USER root
RUN $ORACLE_BASE/oraInventory/orainstRoot.sh && \
    $ORACLE_HOME/root.sh 
    #echo '#!/usr/bin/env bash'$'\n'$(env | egrep "^(PATH=|ORACLE_SID=|ORACLE_PDB=)") > /etc/profile.d/env_path.sh

USER oracle
WORKDIR /home/oracle
COPY scripts/setup/ $ORACLE_BASE/scripts/setup/
COPY scripts/startup/ $ORACLE_BASE/scripts/startup/

HEALTHCHECK --interval=1m --start-period=5m \
   CMD "$ORACLE_BASE/$CHECK_DB_FILE" >/dev/null || exit 1

# Define default command to start Oracle Database. 
CMD exec $ORACLE_BASE/$RUN_FILE
