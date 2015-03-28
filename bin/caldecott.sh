#!/bin/bash
APP_NAME=$1

APP_GUID=`cf app $1 --guid`
APP_DOMAIN=`cf curl /v2/apps/$APP_GUID/stats | jq -r '.["0"].stats.uris[0]'`

CREDENTIALS=`cf curl /v2/apps/$APP_GUID/env | jq '.system_env_json | .VCAP_SERVICES | .["postgresql-9.1"][0] |.credentials'`

REMOTE_HOST=`echo $CREDENTIALS | jq -r .hostname`
REMOTE_PORT=`echo $CREDENTIALS | jq -r .port`
DB_USER=`echo $CREDENTIALS | jq -r .username`
DB_PASS=`echo $CREDENTIALS | jq -r .password`
DB_NAME=`echo $CREDENTIALS | jq -r .name`

./bin/chisel client -v $APP_DOMAIN 15524:$REMOTE_HOST:$REMOTE_PORT &
CHISEL_PID=`echo $!`
sleep 3
export PGPASSWORD=$DB_PASS
psql localhost -h 127.0.0.1 -p 15524 -d $DB_NAME -U $DB_USER

if [ "${CHISEL_PID}" != "" ];then
  kill -9 $CHISEL_PID
fi
