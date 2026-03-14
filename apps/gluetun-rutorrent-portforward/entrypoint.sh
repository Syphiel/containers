#!/bin/bash

while true; do
    if [ -f /tmp/gluetun/forwarded_port ]; then
        FORWARDED_PORT=$(cat /tmp/gluetun/forwarded_port)
        if [ -n "$FORWARDED_PORT" ]; then
            echo "Port forwarded: $FORWARDED_PORT"
            echo "RT_INC_PORT=\'$FORWARDED_PORT\'" >/data/config.env
            break
        else
            echo "Forwarded port file is empty, waiting..."
        fi
    else
        echo "No port forwarded yet, waiting..."
    fi
    sleep 5
done
