#!/bin/bash

SCRIPTS_DIR=`dirname $0`

. $SCRIPTS_DIR/setup-environment.sh

echo
echo "### Delete extra resources."
echo

if [ -d $WORKSHOP_DIR/resources/ ]; then
    oc delete -f $WORKSHOP_DIR/resources/ --recursive
fi
