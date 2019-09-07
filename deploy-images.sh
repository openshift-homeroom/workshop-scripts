#!/bin/bash

SCRIPTS_DIR=`dirname $0`

. $SCRIPTS_DIR/parse-arguments.sh

. $SCRIPTS_DIR/setup-environment.sh

echo "### Deploy daemon set to pre-pull images."

cat << EOF | oc apply -f -
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: $WORKSHOP_NAME-cache
spec:
  selector:
    matchLabels:
      app: $WORKSHOP_NAME-cache
  template:
    metadata:
      labels:
        app: $WORKSHOP_NAME-cache
    spec:
      initContainers:
      - name: prepull-spawner 
        image: $SPAWNER_IMAGE
        command: ["/bin/true"]
      - name: prepull-terminal 
        image: $TERMINAL_IMAGE
        command: ["/bin/true"]
      - name: prepull-workshop 
        image: $WORKSHOP_IMAGE
        command: ["/bin/true"]
      - name: prepull-console
        image: $CONSOLE_IMAGE
        command: ["/bin/true"]
      containers:
      - name: pause
        image: gcr.io/google_containers/pause
EOF
