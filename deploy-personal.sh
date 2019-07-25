#!/bin/bash

SCRIPTS_DIR=`dirname $0`

. $SCRIPTS_DIR/setup-environment.sh

TEMPLATE_REPO=https://raw.githubusercontent.com/$DASHBOARD_REPO
TEMPLATE_FILE=$DASHBOARD_VARIANT.json
TEMPLATE_PATH=$TEMPLATE_REPO/$DASHBOARD_VERSION/templates/$TEMPLATE_FILE

echo "### Install global definitions."

if [ -d $WORKSHOP_DIR/resources/ ]; then
    oc apply -f $WORKSHOP_DIR/resources/ --recursive

    if [ "$?" != "0" ]; then
        fail "Failed to create global definitions."
        exit 1
    fi
fi

echo "### Creating workshop deployment."

oc process -f $TEMPLATE_PATH \
    --param APPLICATION_NAME="$DASHBOARD_APPLICATION" \
    --param TERMINAL_IMAGE="$DASHBOARD_IMAGE" \
    --param GATEWAY_ENVVARS="$GATEWAY_ENVVARS" \
    --param TERMINAL_ENVVARS="$TERMINAL_ENVVARS" \
    --param WORKSHOP_ENVVARS="$WORKSHOP_ENVVARS" \
    --param CONSOLE_VERSION="$CONSOLE_VERSION"

if [ "$?" != "0" ]; then
    fail "Failed to create deployment for dashboard."
    exit 1
fi

echo "### Waiting for the dashboard to deploy."

oc rollout status dc/"$DASHBOARD_APPLICATION"

if [ "$?" != "0" ]; then
    fail "Deployment of dashboard failed to complete."
    exit 1
fi

echo "### Waiting for the dashboard to deploy."

oc rollout status dc/"$DASHBOARD_APPLICATION"

if [ "$?" != "0" ]; then
    fail "Deployment of dashboard failed to complete."
    exit 1
fi

echo "### Route details for the dashboard are as follows."

oc get route "${DASHBOARD_APPLICATION}"
