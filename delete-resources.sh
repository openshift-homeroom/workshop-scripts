#!/bin/bash

SCRIPTS_DIR=`dirname $0`

. $SCRIPTS_DIR/setup-environment.sh

echo "### Delete spawner resources."

if [ -d $WORKSHOP_DIR/resources/ ]; then
    oc delete -f $WORKSHOP_DIR/resources/ --recursive
fi

if [ -f $WORKSHOP_DIR/templates/spawner-resources.yaml ]; then
    oc process \
        -f $WORKSHOP_DIR/templates/spawner-resources.yaml \
        --param SPAWNER_APPLICATION="$SPAWNER_APPLICATION" \
        --param SPAWNER_NAMESPACE="$PROJECT_NAME" | \
        oc delete -f -
fi
