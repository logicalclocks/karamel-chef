set -e
if [ ! -d "dela" ]; then
  echo "Run the script from the karamel-chef dir"
  exit 1
fi
KCHEF_DIR=${PWD}
rm cluster-defns/1.demodela.yml
cp dela/templates/1.demodela.yml cluster-defns/

#random 32 character alphanumeric string (upper and lowercase)
ID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
#3base + random 7 character alphanumeric string (upper and lowercase)
PASS="1Ab"+$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 7 | head -n 1)
EMAIL="demo"+${ID}+"@hops.io"
sed -i -e "s/REGISTER_EMAIL/${EMAIL}/g" $FILE
sed -i -e "s/REGISTER_ORGANIZATION/demohops/g" $FILE
sed -i -e "s/REGISTER_ORGANIZATION_UNIT/${ID}/g" $FILE
sed -i -e "s/REGISTER_PASSWORD/${PASS}/g" $FILE