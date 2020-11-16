#!/bin/bash
CONTAINER_NAME=${1-oracle-stack}
VOLUME=${2-oracle-data}

docker run -d --name $CONTAINER_NAME \
-p 1521:1521 \
-p 5500:5500 \
-p 2222:22 \
-p 8080:8080 \
-e TIME_ZONE="Europe/Rome" \
-e ORACLE_EDITION=EE \
-e ORACLE_PWD=Oracle2020 \
-e ORACLE_SID=ORCLCDB \
-e ORACLE_PDB=ORCLPDB1 \
-e APEX_ADMIN_EMAIL=myemail@domain.com \
-e APEX_ADMIN_PWD=Apex2020!! \
-v $VOLUME:/opt/oracle/oradata \
--tmpfs /dev/shm:rw,exec,size=8G \
oracle-stack:19.3.0-ee

docker logs -f $CONTAINER_NAME