#!/bin/bash
set -e
cd dela/running
CONTENT_TYPE="Content-Type: application/json"
TARGET=http://{HOPSSITE_DOMAIN}:{HS_WEB1_P}/hopsworks-cluster/api/cluster/register
CURL_RES=$(curl -s -o /dev/null -w "%{http_code}" -d "@register_data.json" -H "$CONTENT_TYPE" -X POST $TARGET)
if [ ${CURL_RES} != 200 ] ; then
  echo "Register fail"
  exit 1
fi
echo "Register success"