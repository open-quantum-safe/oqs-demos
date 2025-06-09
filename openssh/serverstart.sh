#!/bin/bash

[[ $DEBUGLVL -gt 1 ]] && set -ex

OPTIONS=${OPTIONS:=""}

SIG=${SIG_ALG:="ecdsa-nistp384-mldsa65"}
KEM=${KEM_ALG:="mlkem768nistp256-sha256"}

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
    HOST_KEY_FILE="${OQS_INSTALL_DIR}/ssh_host_${SIG//-/_}_key"
    OPTIONS="${OPTIONS} -h ${HOST_KEY_FILE}"
fi
# Generate host keys
# SSH_DIR="/home/${OQS_USER}/.ssh"
HOST_KEY_FILE="${SSH_DIR}/ssh_host_${SIG//-/_}_key"
echo "y" | ${OQS_INSTALL_DIR}/bin/ssh-keygen -t ssh-${SIG} -f ${OQS_INSTALL_DIR}/${HOST_KEY_FILE} -N "" -q
echo ""
# cat ${HOST_KEY_FILE}.pub >> ${SSH_DIR}/authorized_keys
[[ $DEBUGLVL -gt 0 ]] && echo "Debug1: New host key '${HOST_KEY_FILE}(.pub)' created!"
# OPTIONS="${OPTIONS} -i ${HOST_KEY_FILE}"


# Start the OQS SSH Daemon with the configuration as in ${OQS_INSTALL_DIR}/sshd_config
CMD="${OQS_INSTALL_DIR}/sbin/sshd ${OPTIONS}"
[[ $DEBUGLVL -gt 0 ]] && echo $CMD
eval $CMD

# Open a shell for local experimentation if not testing the connection
if [ "x${CONNECT_TEST}" == "x" ]; then
    sh
fi
