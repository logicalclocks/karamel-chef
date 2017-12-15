#!/bin/bash
set -e
JSON='{"email":"{CLUSTER_EMAIL}", "chosenPassword":"{CLUSTER_PASSWORD}", "repeatedPassword":"{CLUSTER_PASSWORD}", "organizationName":"{CLUSTER_ORG}", "organizationalUnitName":"CLUSTER_UNIT", "tos": true}'
CONTENT_TYPE="Content-Type: application/json"
TARGET=http://{HOPSSITE_DOMAIN}:{HS_WEB1_P}/hopsworks-cluster/register
curl -d $JSON -H $CONTENT_TYPE -X POST $TARGET