#!/bin/bash

# Run as oracle user

ORAENV_ASK=NO
ORACLE_SID=${ORACLE_SID:-ORCLCDB}

. oraenv

ORDS_CONFIG_DIR=$ORACLE_BASE/oradata/ordsconfig/$ORACLE_PDB

mkdir -p $ORDS_CONFIG_DIR

cd $ORDS_HOME

PARAM_FILE=$ORDS_HOME/params/custom_params.properties

cat << EOF > $PARAM_FILE
db.hostname=localhost
db.password=${APEX_PUBLIC_USER_PWD:-$ORACLE_PWD}
db.port=1521
db.servicename=${ORACLE_PDB:-XEPDB1}
db.username=APEX_PUBLIC_USER
plsql.gateway.add=true
rest.services.apex.add=true
rest.services.ords.add=true
schema.tablespace.default=SYSAUX
schema.tablespace.temp=TEMP
user.apex.listener.password=${APEX_LISTENER_PWD:-$ORACLE_PWD}
user.apex.restpublic.password=${APEX_REST_PUBLIC_USER_PWD:-$ORACLE_PWD}
user.public.password=${ORDS_PUBLIC_USER_PWD:-$ORACLE_PWD}
user.tablespace.default=SYSAUX
user.tablespace.temp=TEMP
sys.user=sys
sys.password=${ORACLE_PWD}
EOF

echo "restEnabledSql.active=true" >> $PARAM_FILE
echo "feature.sdw=true" >> $PARAM_FILE
echo "database.api.enabled=true" >> $PARAM_FILE

java -jar ords.war configdir $ORDS_CONFIG_DIR
java -jar ords.war install simple --parameterFile $ORDS_HOME/params/custom_params.properties

java -jar ords.war set-property jdbc.InitialLimit 6
java -jar ords.war set-property jdbc.MinLimit 6
java -jar ords.war set-property jdbc.MaxLimit 40
java -jar ords.war set-property jdbc.MaxConnectionReuseCount 10000
java -jar ords.war set-property security.verifySSL false

echo "Creating SQL Developer Web Admin User."
sqlplus / as sysdba << EOF
  alter session set container = ${ORACLE_PDB};
  create user SDW_ADMIN identified by ${ORACLE_PWD} default tablespace USERS temporary tablespace TEMP;
  alter user SDW_ADMIN quota unlimited on USERS;
  grant connect, dba, pdb_dba to SDW_ADMIN;
EOF

echo "Creating SDW_ADMIN Schema"
echo "sqlplus SDW_ADMIN/${ORACLE_PWD}@${ORACLE_PDB}"

sqlplus SDW_ADMIN/${ORACLE_PWD}@${ORACLE_PDB} << EOF
  BEGIN
    ORDS.enable_schema(
        p_enabled             => TRUE,
        p_schema              => 'SDW_ADMIN',
        p_url_mapping_type    => 'BASE_PATH',
        p_url_mapping_pattern => 'sdw_admin',
        p_auto_rest_auth      => FALSE
    );
    COMMIT;
  END;
  /
EOF