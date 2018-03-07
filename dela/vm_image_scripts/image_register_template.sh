set -e

DOMAIN={DOMAIN}
REGISTER_PORT={REGISTER_PORT}
DOMAIN_PREFIX={DOMAIN_PREFIX}://

INSTALL_DIR=/srv/hops
HOPSSITE_DIR=${INSTALL_DIR}/hopssite
REGISTERED=${HOPSSITE_DIR}/registered
DOMAINS_DIR=${INSTALL_DIR}/domains

#random 32 character alphanumeric string (upper and lowercase)
ID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
#3base + random 7 character alphanumeric string (upper and lowercase)
PASS="1Ab$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 7 | head -n 1)"
EMAIL="demo_${ID}@hops.io"

CONTENT_TYPE="Content-Type: application/json"
TARGET="${DOMAIN_PREFIX}${DOMAIN}:${REGISTER_PORT}/hopsworks-cluster/api/cluster/register"

mkdir -p ${HOPSSITE_DIR}
if [ -f ${REGISTERED} ]; then
  echo "already registered"
else
  CONTENT_DATA=${HOPSSITE_DIR}/register_data.json
  cp ${HOPSSITE_DIR}/register_data_template.json ${CONTENT_DATA}
  sed -i -e "s/REGISTER_EMAIL/${EMAIL}/g" ${CONTENT_DATA}
  sed -i -e "s/REGISTER_ORGANIZATION/demohops/g" ${CONTENT_DATA}
  sed -i -e "s/REGISTER_ORG_UNIT/${ID}/g" ${CONTENT_DATA}
  sed -i -e "s/REGISTER_PASSWORD/${PASS}/g" ${CONTENT_DATA}
  CURL_RES=$(curl -s -o /dev/null -w "%{http_code}" -d "@register_data.json" -H "${CONTENT_TYPE}" -X POST $TARGET)
  if [ ${CURL_RES} != 200 ] ; then
    echo "Register fail"
    exit 1
  fi
  echo "Register success"

  CA_INI=${HOPSSITE_DIR}/ca.ini
  echo "[hops-site]" > ${CA_INI}
  echo "url = ${DOMAIN_PREFIX}${DOMAIN}:${REGISTER_PORT}" >> ${CA_INI}
  echo "path-login = /hopsworks-api/api/auth/login" >> ${CA_INI}
  echo "path-sign-cert = /hopsworks-ca/ca/agentservice/hopsworks" >> ${CA_INI} 
  echo "username = ${EMAIL}" >> ${CA_INI}
  echo "password = ${PASS}" >> ${CA_INI}
  echo "retry-interval = 30" >> ${CA_INI}
  echo "max-retries = 5" >> ${CA_INI}
  echo "logging-level = INFO" >> ${CA_INI}
  echo "cert_c = se"  >> ${CA_INI}
  echo "cert_cn = demohops_${ID}" >> ${CA_INI}
  echo "cert_s = stockholm" >> ${CA_INI}
  echo "cert_l = kista" >> ${CA_INI}
  echo "cert_o = demohops" >> ${CA_INI}
  echo "cert_ou = ${ID}" >> ${CA_INI}
  echo "cert_email = ${EMAIL}" >> ${CA_INI}
  sudo mv ${CA_INI} ${DOMAINS_DIR}/domain1/config
  sudo chown glassfish:root ${DOMAINS_DIR}/domain1/config
  sudo su -c ${DOMAINS_DIR}/domain1/bin/csr-ca.py glassfish
  touch ${REGISTERED}
fi