#!/bin/bash

SCRIPTS_DIR=`dirname $0`

echo "### Parsing command line arguments."

for i in "$@"
do
    case $i in
        --event=*|--settings=*)
            SETTINGS_NAME="${i#*=}"
            shift
            ;;
        *)
            ;;
    esac
done

. $SCRIPTS_DIR/setup-environment.sh

echo "### Delete project resources."

APPLICATION_LABELS="app=$DASHBOARD_APPLICATION"

PROJECT_RESOURCES="all,serviceaccount,rolebinding,configmap"

oc delete "$PROJECT_RESOURCES" --selector "$APPLICATION_LABELS"
