#!/bin/bash

. config.sh


echo "Setting your default project to: $PROJECT"
echo "Setting your default region to: $REGION"
echo "Setting your default zone to: $ZONE"

gcloud config set project $PROJECT
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE

echo ""
echo ""
echo "If you are installing the enterprise version, add the license file 'env.sh' to this directory and make it executable"
echo ""
echo "Done."
echo ""
