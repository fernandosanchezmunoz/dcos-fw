#!/bin/bash

#env.sh

NAME_0="dcos"
SUBNET_0 ="192.168.0.0/19"

NAME_1="dcos-1"
SUBNET_1="192.168.32.0/19"

POLICY_NAME="dcos-isolation"
#"allow-selves-plus-80-dcos-1-to-dcos"

$SIMPLE="simple_allowed_selves"

$COMPLEX="complex_allowed_port_80_dcos-1_to_dcos"
$PORT=80
