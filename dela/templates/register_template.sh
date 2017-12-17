#!/bin/bash
set -e
cd dela/running
CONTENT_TYPE="Content-Type: application/json"
TARGET=http://{HOPSSITE_DOMAIN}:{HS_WEB1_P}/hopsworks-cluster/api/cluster/register
curl -d "@register_data.json" -H $CONTENT_TYPE -X POST $TARGET