set -e
if [ ! -d "dela" ]; then
  echo "Run the script from the karamel-chef dir"
  exit 1
fi
TEMPLATE="1.${1}.yml"
KCHEF_DIR=${PWD}
rm cluster-defns/${TEMPLATE}
cp dela/templates/${TEMPLATE} cluster-defns/1.demodela.yml

#random 32 character alphanumeric string (upper and lowercase)
ID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
#3base + random 7 character alphanumeric string (upper and lowercase)
PASS="1Ab$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 7 | head -n 1)"
EMAIL="demo_${ID}@hops.io"
FILE=cluster-defns/1.demodela.yml
sed -i -e "s/REGISTER_EMAIL/${EMAIL}/g" $FILE
sed -i -e "s/REGISTER_ORGANIZATION/demohops/g" $FILE
sed -i -e "s/REGISTER_ORG_UNIT/${ID}/g" $FILE
sed -i -e "s/REGISTER_PASSWORD/${PASS}/g" $FILE