#!/usr/bin/env bash

SERVICE_LOG_DIR=${SERVICE_LOG_DIR:-${SERVICE_HOME}"/logs"}
SERVICE_LOG_FILE=${SERVICE_LOG_FILE:-${SERVICE_HOME}"/nohup.out"}

export ZOO_LOG_DIR=${SERVICE_LOG_DIR}

function log {
        echo `date` $ME - $@
}

function serviceDefault {
    log "[ Applying default ${SERVICE_NAME} configuration... ]"
    ${SERVICE_HOME}/bin/zoo.cfg.sh
}

function serviceConf {
    log "[ Applying dinamic ${SERVICE_NAME} configuration... ]"
    while [ ! -f ${SERVICE_CONF} ]; do
        log "  Waiting for ${SERVICE_NAME} configuration..."
        sleep 3 
    done
}

function serviceLog {
    log "[ Redirecting ${SERVICE_NAME} log to stdout... ]"
    if [ ! -L ${SERVICE_LOG_FILE} ]; then
        rm ${SERVICE_LOG_FILE}
        ln -sf /proc/1/fd/1 ${SERVICE_LOG_FILE}
    fi
}

function serviceCheck {
    log "[ Checking ${SERVICE_NAME} configuration... ]"

    if [ -d "/opt/tools" ]; then
        serviceConf
    else
        serviceDefault
    fi
}

function serviceStart {
    log "[ Starting ${SERVICE_NAME}... ]"
    serviceCheck
    serviceLog
    ${SERVICE_HOME}/bin/zkServer.sh start
}

function serviceStop {
    log "[ Stoping ${SERVICE_NAME}... ]"
    ${SERVICE_HOME}/bin/zkServer.sh stop
    kill -9 /opt/zk/data/zookeeper_server.pid
    rm /opt/zk/data/zookeeper_server.pid
}

function serviceRestart {
    log "[ Restarting ${SERVICE_NAME}... ]"
    serviceStop
    serviceStart
    /opt/monit/bin/monit reload
}

case "$1" in
        "start")
            serviceStart
        ;;
        "stop")
            serviceStop
        ;;
        "restart")
            serviceRestart
        ;;
        *) 
            echo "Usage: $0 restart|start|stop"
            exit 1
        ;;

esac

exit 0
