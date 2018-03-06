#!/bin/bash
set -e
if [ ! -d "dela" ]; then
  echo "Run the script from the karamel-chef dir"
  exit 1
fi
KCHEF_DIR=${PWD}
. ${KCHEF_DIR}/dela/running/dela_env.sh

echo "#!/bin/bash" > ${KCHEF_DIR}/dela/running/dela_ports.sh
PORT=$((21000 + ${CLUSTER_SUFFIX}))
echo "SSH_P=${PORT}" >> ${KCHEF_DIR}/dela/running/dela_ports.sh
PORT=$((22000 + ${CLUSTER_SUFFIX}))
echo "MYSQL_P=${PORT}" >> ${KCHEF_DIR}/dela/running/dela_ports.sh
PORT=$((23000 + ${CLUSTER_SUFFIX}))
echo "KARAMEL_P=${PORT}" >> ${KCHEF_DIR}/dela/running/dela_ports.sh
PORT=$((24000 + ${CLUSTER_SUFFIX}))
echo "WEB_P=${PORT}" >> ${KCHEF_DIR}/dela/running/dela_ports.sh
PORT=$((25000 + ${CLUSTER_SUFFIX}))
echo "DEBUG_P=${PORT}" >> ${KCHEF_DIR}/dela/running/dela_ports.sh
PORT=$((26000 + ${CLUSTER_SUFFIX}))
echo "GFISH_P=${PORT}" >> ${KCHEF_DIR}/dela/running/dela_ports.sh
for i in {1..9}
do 
  PORT=$((26000 + ${i} * 1000 + ${CLUSTER_SUFFIX}))
  echo "PORT${i}=${PORT}" >> ${KCHEF_DIR}/dela/running/dela_ports.sh
done
PORT=$((41000 + ${CLUSTER_SUFFIX}))
echo "DELA1_P=${PORT}" >> ${KCHEF_DIR}/dela/running/dela_ports.sh
PORT=$((42000 + ${CLUSTER_SUFFIX}))
echo "DELA2_P=${PORT}" >> ${KCHEF_DIR}/dela/running/dela_ports.sh
PORT=$((43000 + ${CLUSTER_SUFFIX}))
echo "DELA3_P=${PORT}" >> ${KCHEF_DIR}/dela/running/dela_ports.sh
PORT=$((44000 + ${CLUSTER_SUFFIX}))
echo "DELA4_P=${PORT}" >> ${KCHEF_DIR}/dela/running/dela_ports.sh
PORT=$((24000 + ${HOPSSITE_SUFFIX}))
echo "HS_WEB1_P=${PORT}" >> ${KCHEF_DIR}/dela/running/dela_ports.sh
PORT=$((52000 + ${HOPSSITE_SUFFIX}))
echo "HS_WEB2_P=${PORT}" >> ${KCHEF_DIR}/dela/running/dela_ports.sh
chmod +x ${KCHEF_DIR}/dela/running/dela_ports.sh