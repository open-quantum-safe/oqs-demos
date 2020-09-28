#!/bin/bash

[[ $DEBUGLVL -gt 1 ]] && set -ex

# default options
OPTIONS=${OPTIONS:="-q -o BatchMode=yes -o StrictHostKeyChecking=no"}

SIG=${SIG_ALG:="p256-dilithium2"}
KEM=${KEM_ALG:="ecdh-nistp384-kyber-1024"}

# Correct id file exists? Create it if not
SSH_DIR="/home/${OQS_USER}/.ssh"
SIG_ID_FILE="${SSH_DIR}/id_${SIG//-/_}"
su ${OQS_USER} -c "${OQS_INSTALL_DIR}/bin/ssh-keygen -t ssh-${SIG} -f ${SIG_ID_FILE} -N \"\" -q"
cat ${SIG_ID_FILE}.pub >> ${SSH_DIR}/authorized_keys
[[ $DEBUGLVL -gt 0 ]] && echo "Debug1: New identity key '${SIG_ID_FILE}(.pub)' created!"
OPTIONS="${OPTIONS} -i ${SIG_ID_FILE}"

eval "export CONNECT_TEST=true; serverstart.sh"

# Evaluate if called as root
if [ ${EUID} -eq 0 ]; then
    SSH_PREFIX="su ${OQS_USER} -c "
fi

# See if TEST_HOST was set, if not use default
if [ "x${TEST_HOST}" == "x" ]; then
    TEST_HOST="localhost"
fi

# See if TEST_TIME was set, if not use default
if [ "x${TEST_TIME}" == "x" ]; then
    TEST_TIME=3
fi
OPTIONS="${OPTIONS} -o ConnectTimeout=${TEST_TIME}"

# Optionally set port
# if left empty, the options defined in sshd_config will be used
if [ "x$SERVER_PORT" != "x" ]; then
    OPTIONS="${OPTIONS} -p ${SERVER_PORT}"
fi

# Optionally set KEM to one defined in https://github.com/open-quantum-safe/openssh#key-exchange
# if left empty, the options defined in sshd_config will be used
if [ "x$KEM" != "x" ]; then
    OPTIONS="${OPTIONS} -o KexAlgorithms=${KEM}-sha384@openquantumsafe.org"
fi

# Optionally set SIG to one defined in https://github.com/open-quantum-safe/openssh#digital-signature
# if left empty, the options defined in sshd_config will be used
if [ "x$SIG" != "x" ]; then
    OPTIONS="${OPTIONS} -o HostKeyAlgorithms=ssh-${SIG} -o PubkeyAcceptedKeyTypes=ssh-${SIG}"
fi

CMD="ssh ${OPTIONS} ${TEST_HOST} 'exit 0'"
[[ $DEBUGLVL -gt 0 ]] && echo "Debug1: $SSH_PREFIX\"$CMD\""
eval "$SSH_PREFIX\"$CMD\""

if [ $? -eq 0 ]; then
    echo "Successfully connected to ${TEST_HOST}!"
    exit 0
else
    echo "Failed connecting to ${TEST_HOST}!"
    exit 1
fi