#!/bin/bash

# Check if root
if [ "x${EUID}" != "x0" ]; then
    echo "Must be root! Aborting..."
    exit 1
fi

################################################################################
# Get all active IDENTITY KEY files from ssh_config and generate a file for each
################################################################################
echo "Generating identity key files as configured in ${OQS_INSTALL_DIR}/ssh_config:"

HOME_DIR="/home/${OQS_USER}"
readarray ID_FILES <<< $(sed -n "s:^identityfile[ =]\+::Ip" ${OQS_INSTALL_DIR}/ssh_config | sed -n "s:\~:${HOME_DIR}:gp")
readarray ID_ALGS <<< $(sed -n "s:^identityfile.\+/id_::Ip" ${OQS_INSTALL_DIR}/ssh_config)

# Find longest name
MAX_ALG_LEN=0
for ALG in ${ID_ALGS[@]}; do
    if [ ${#ALG} -gt $MAX_ALG_LEN ]; then
        MAX_ALG_LEN=${#ALG}
    fi
done
MAX_FILE_LEN=0
for FILE in ${ID_FILES[@]}; do
    if [ ${#FILE} -gt $MAX_FILE_LEN ]; then
        MAX_FILE_LEN=${#FILE}
    fi
done

# Generate a new identity key for each found host key algorithm
for IDX in ${!ID_ALGS[@]}; do
    ALG=${ID_ALGS[$IDX]}
    ID_FILE=${ID_FILES[$IDX]:0:(-1)} # Cut off some weird trailing newline
    printf "\t%-$((MAX_ALG_LEN + 1))s" ${ALG^^}
    if [ -e $ID_FILE ]; then
        printf "exists @ %-$((MAX_LEN + 10))s --> SKIPPED\n" "$ID_FILE(.pub)"
    else
        CMD="su ${OQS_USER} -c \"${OQS_INSTALL_DIR}/bin/ssh-keygen -t $ALG -f $ID_FILE -N '' -q\""
        # echo $CMD
        eval $CMD 2> /dev/null
        if [ $? -ne 0 ]; then
            echo "FAILED"
        else
            echo "generated @ $ID_FILE(.pub)"
        fi
    fi
done

################################################################################
# Get all active HOST KEY files from ssh_config and generate a file for each ###
################################################################################
echo -e "\nGenerating host key files as configured in $OQS_INSTALL_DIR/sshd_config:"

# Get algorithms from sshd_config
readarray HOST_KEY_FILES <<< $(sed -n "s:^hostkey[ =]\+::Ip" ${OQS_INSTALL_DIR}/sshd_config)
readarray HOST_KEY_ALGS <<< $(sed -n "s:^hostkey.*/ssh_host_::Ip" ${OQS_INSTALL_DIR}/sshd_config | sed -n "s:_key$::gp")

# Find longest name
MAX_ALG_LEN=0
for ALG in ${HOST_KEY_ALGS[@]}; do
    if [ ${#ALG} -gt $MAX_ALG_LEN ]; then
        MAX_ALG_LEN=${#ALG}
    fi
done
MAX_FILE_LEN=0
for FILE in ${HOST_KEY_FILES[@]}; do
    if [ ${#FILE} -gt $MAX_FILE_LEN ]; then
        MAX_FILE_LEN=${#FILE}
    fi
done

# Generate a new host key for each found host key algorithm
for IDX in "${!HOST_KEY_ALGS[@]}"; do
    ALG=${HOST_KEY_ALGS[$IDX]}
    HOST_FILE=${HOST_KEY_FILES[$IDX]:0:(-1)} # Cut off some weird trailing newline
    printf "\t%-$((MAX_ALG_LEN + 1))s" ${ALG^^}
    if [ -e $HOST_FILE ]; then
        printf "exists @ %-$((MAX_FILE_LEN + 6))s --> SKIPPED\n" "$HOST_FILE(.pub)"
    else
        CMD="${OQS_INSTALL_DIR}/bin/ssh-keygen  -t $ALG -f $HOST_FILE -N '' -q -h"
        #echo "Generating key via: $CMD"
        eval $CMD 2> /dev/null
        if [ $? -ne 0 ]; then
            echo "FAILED"
        else
            echo "generated @ $HOST_FILE(.pub)"
            RESTART_SSHD=yes
        fi
    fi
done

if [ "x$RESTART_SSHD" != "x" ]; then
    echo ""
    rc-service oqs-sshd restart
else
# make sure service is running
    echo ""
    rc-service oqs-sshd start
fi
