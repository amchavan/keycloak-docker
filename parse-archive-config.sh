# Parse archiveConfig.properties and extract Oracle
# connection information needed by the Dockerfile
#
# amchavan, 26-Oct-2020

PROPS_FILE=${ACSDATA}/config/archiveConfig.properties

CONNECTION_PROP=archive.keycloak.connection
URL_PROP=$(grep ${CONNECTION_PROP} ${PROPS_FILE} | tr -d '[:space:]')
URL_ARRY=(${URL_PROP//=/ })
URL=${URL_ARRY[1]}

HOSTNAME=$(echo ${URL} | cut -d@ -f2 | cut -d: -f1)
PORT_NUM=$(echo ${URL} | cut -d@ -f2 | cut -d: -f2 | cut -d/ -f1)
DATABASE=$(echo ${URL} | cut -d/ -f2)

if [ -z "${URL}" ] ; then
    echo "ERROR: ${CONNECTION_PROP} property: not found"
    exit 1
fi

if [[ -z "${HOSTNAME}" || -z "${PORT_NUM}" || -z "${DATABASE}" ]] ; then
    echo "ERROR: ${CONNECTION_PROP} property: invalid value '${URL}'"
    exit 1
fi

USERNAME_PROP=$(grep archive.keycloak.user ${PROPS_FILE} | tr -d '[:space:]')
USERNAME_ARRY=(${USERNAME_PROP//=/ })
USERNAME=${USERNAME_ARRY[1]}
if [ -z "${USERNAME}" ] ; then
    echo "ERROR: archive.keycloak.user property: not found"
    exit 1
fi

PASSWORD_PROP=$(grep archive.keycloak.passwd ${PROPS_FILE} | tr -d '[:space:]')
PASSWORD_ARRY=(${PASSWORD_PROP//=/ })
PASSWORD=${PASSWORD_ARRY[1]}
if [ -z "${PASSWORD}" ] ; then
    echo "ERROR: archive.keycloak.passwd property: not found"
    exit 1
fi

# echo export URL=${URL} 
# echo export HOSTNAME=${HOSTNAME}
# echo export PORT_NUM=${PORT_NUM}
# echo export DATABASE=${DATABASE}
# echo export USERNAME=${USERNAME}
# echo export PASSWORD=$(echo ${PASSWORD} | sed 's/\$/\$\$/g' )

echo "HOSTNAME := ${HOSTNAME}"
echo "PORT_NUM := ${PORT_NUM}"
echo "DATABASE := ${DATABASE}"
echo "USERNAME := ${USERNAME}"
echo "PASSWORD := $(echo ${PASSWORD} | sed 's/\$/\$\$/g' )"
