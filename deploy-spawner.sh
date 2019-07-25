#!/bin/bash

SCRIPTS_DIR=`dirname $0`

. $SCRIPTS_DIR/setup-environment.sh

TEMPLATE_REPO=https://raw.githubusercontent.com/$SPAWNER_REPO
TEMPLATE_FILE=$SPAWNER_MODE-$SPAWNER_VARIANT.json
TEMPLATE_PATH=$TEMPLATE_REPO/$SPAWNER_VERSION/templates/$TEMPLATE_FILE

echo "### Creating spawner application."

oc process -f $TEMPLATE_PATH \
    --param APPLICATION_NAME="$SPAWNER_APPLICATION" \
    --param PROJECT_NAME="$SPAWNER_NAMESPACE" \
    --param RESOURCE_BUDGET="$RESOURCE_BUDGET" \
    --param HOMEROOM_LINK="$HOMEROOM_LINK" \
    --param GATEWAY_ENVVARS="$GATEWAY_ENVVARS" \
    --param TERMINAL_ENVVARS="$TERMINAL_ENVVARS" \
    --param WORKSHOP_ENVVARS="$WORKSHOP_ENVVARS" \
    --param CONSOLE_VERSION="$CONSOLE_VERSION" \
    --param IDLE_TIMEOUT="$IDLE_TIMEOUT" \
    --param MAX_SESSION_AGE="$MAX_SESSION_AGE" \
    --param JUPYTERHUB_CONFIG="$JUPYTERHUB_CONFIG" \
    --param LETS_ENCRYPT="$LETS_ENCRYPT" | oc apply -f -

if [ "$?" != "0" ]; then
    fail "Failed to create deployment for spawner."
    exit 1
fi

echo "### Waiting for the spawner to deploy."

oc rollout status dc/"$SPAWNER_APPLICATION"

if [ "$?" != "0" ]; then
    fail "Deployment of spawner failed to complete."
    exit 1
fi

echo "### Install global definitions."

if [ -d $WORKSHOP_DIR/resources/ ]; then
    oc apply -f $WORKSHOP_DIR/resources/ --recursive

    if [ "$?" != "0" ]; then
        fail "Failed to create global definitions."
        exit 1
    fi
fi

echo "### Update spawner configuration for workshop."

if [ -f $WORKSHOP_DIR/templates/clusterroles-session-rules.yaml ]; then
    oc process -f $WORKSHOP_DIR/templates/clusterroles-session-rules.yaml \
        --param SPAWNER_APPLICATION="$SPAWNER_APPLICATION" \
        --param SPAWNER_NAMESPACE="$SPAWNER_NAMESPACE" | oc apply -f -

    if [ "$?" != "0" ]; then
        fail "Failed to update session rules for workshop."
        exit 1
    fi
fi

if [ -f $WORKSHOP_DIR/templates/clusterroles-spawner-rules.yaml ]; then
    oc process -f $WORKSHOP_DIR/templates/clusterroles-spawner-rules.yaml \
        --param SPAWNER_APPLICATION="$SPAWNER_APPLICATION" \
        --param SPAWNER_NAMESPACE="$SPAWNER_NAMESPACE" | oc apply -f -

    if [ "$?" != "0" ]; then
        fail "Failed to update spawner rules for workshop."
        exit 1
    fi
fi

if [ -f $WORKSHOP_DIR/templates/configmap-extra-resources.yaml ]; then
    oc process -f $WORKSHOP_DIR/templates/configmap-extra-resources.yaml \
        --param SPAWNER_APPLICATION="$SPAWNER_APPLICATION" \
        --param SPAWNER_NAMESPACE="$SPAWNER_NAMESPACE" | oc apply -f -

    if [ "$?" != "0" ]; then
        fail "Failed to update extra resources for workshop."
        exit 1
    fi
fi

echo "### Restart the spawner with new configuration."

oc rollout latest dc/"$SPAWNER_APPLICATION"

if [ "$?" != "0" ]; then
    fail "Failed to restart the spawner."
    exit 1
fi

oc rollout status dc/"$SPAWNER_APPLICATION"

if [ "$?" != "0" ]; then
    fail "Deployment of spawner failed to complete."
    exit 1
fi

echo "### Updating spawner to use image for workshop."

oc tag "$WORKSHOP_IMAGE" "${SPAWNER_APPLICATION}-app:latest"

if [ "$?" != "0" ]; then
    fail "Failed to update spawner to use workshop image."
    exit 1
fi

echo "### Route details for the spawner are as follows."

oc get route "${SPAWNER_APPLICATION}"
