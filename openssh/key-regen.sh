#!/bin/bash
# set -ex

if [ "x${EUID}" != "x0" ]; then
    echo "Must be root! Aborting..."
    exit 1
fi

# Get all active identity files from ssh_config and generate a file for each
ID_DIR="/home/${OQS_USER}/.ssh"
readarray ID_ALGS <<< $(sed -n "s:^identityfile.*/id_::Ip" ${OQS_INSTALL_DIR}/ssh_config)
# Find longest name
MAX_LEN=0
for alg in ${ID_ALGS[@]}; do
    if [ ${#alg} -gt $MAX_LEN ]; then
        MAX_LEN=${#alg}
    fi
done
echo "Generating identity files as configured in ${OQS_INSTALL_DIR}/ssh_config:"
for alg in ${ID_ALGS[@]}; do
    printf "\t%-$((MAX_LEN + 1))s" ${alg^^}
    if [ $alg == "rsa" ] || [ $alg == "dsa" ] || [ $alg == "ecdsa*" ] || [ $alg == "ed25519*" ]; then
        alg_pre=''
    else
        alg_pre='ssh-'
    fi
    ID_FILE=${ID_DIR}/id_${alg}
    if [ -e $ID_FILE ]; then
        printf "exists @ %-$((MAX_LEN + ${#ID_DIR} + 10))s --> SKIPPED\n" "$ID_FILE(.pub)"
    else
        CMD="su ${OQS_USER} -c \"${OQS_INSTALL_DIR}/bin/ssh-keygen -t $alg_pre$(echo $alg | sed 's/_/-/g') -f $ID_FILE -N '' -q\""
        # echo $CMD
        eval $CMD
        if [ $? -ne 0 ]; then
            echo "FAILED"
        else
            echo "generated @ $ID_FILE(.pub)"
        fi
    fi
done
# echo " done!"

# Regenerate existing host keys
HOST_KEY_DIR=$(echo $OQS_INSTALL_DIR | sed 's:/*$::')
echo -e "\nGenerating host key files as configured in $OQS_INSTALL_DIR/sshd_config (all HostKeyAlgorithms):"

# Get algorithms from sshd_config
IFS=',' read -ra HOST_KEY_ALGS <<< $(sed -n "s/^hostkeyalgorithms[ \t=]*//Ip" ${OQS_INSTALL_DIR}/sshd_config)
MAX_LEN=0
for alg in ${HOST_KEY_ALGS[@]}; do
    if [ ${#alg} -gt $MAX_LEN ]; then
        MAX_LEN=${#alg}
    fi
done
# Generate new host key for each found host key algorithm
for alg in "${HOST_KEY_ALGS[@]}"; do
    printf "\t%-$((MAX_LEN + 1))s" ${alg^^}
    HOST_FILE="${HOST_KEY_DIR}/ssh_host_$(echo $alg | sed 's/^ssh-//;s/-/_/g')_key"
    if [ -e $HOST_FILE ]; then
        printf "exists @ %-$((MAX_LEN + ${#HOST_KEY_DIR} + 16))s --> SKIPPED\n" "$HOST_FILE(.pub)"
    else
        CMD="${OQS_INSTALL_DIR}/bin/ssh-keygen  -t $alg -f $HOST_FILE -N '' -q -h"
        # echo $CMD
        eval $CMD
        if [ $? -ne 0 ]; then
            echo "FAILED"
        else
            echo "generated @ $HOST_FILE(.pub)"
            RESTART_SSHD=yes
        fi
    fi
done
# echo " done!"

if [ "x$RESTART_SSHD" != "x" ]; then
    echo ""
    rc-service oqs-sshd restart
fi