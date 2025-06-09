#!/bin/bash

[[ $DEBUGLVL -gt 1 ]] && set -ex

# Stop the sshd service that may was started before, otherwise it won't work with others than the default algorithms
rc-service oqs-sshd stop

# default options
OPTIONS=${OPTIONS:="-q -o BatchMode=yes -o StrictHostKeyChecking=no"}

SIG=${SIG_ALG:="ecdsa-nistp384-mldsa65"}
KEM=${KEM_ALG:="mlkem768nistp256-sha256"}

# Generate new identity keys, overwrite old keys
SSH_DIR="/home/${OQS_USER}/.ssh"
SIG_ID_FILE="${SSH_DIR}/id_${SIG//-/_}"
echo "y" | su ${OQS_USER} -c "${OQS_INSTALL_DIR}/bin/ssh-keygen -t ssh-${SIG} -f ${SIG_ID_FILE} -N \"\" -q"
echo ""
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
    TEST_TIME=60
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
    OPTIONS="${OPTIONS} -o KexAlgorithms=${KEM}"
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
    echo ""
    echo "[ OK ] Connected to ${TEST_HOST} using ${KEM} and ${SIG}!"
    exit 0
else
    echo ""
    echo "[FAIL] Could not connect to ${TEST_HOST} using ${KEM} and ${SIG}!"
    exit 1
fi
