#!/bin/sh /etc/rc.common
START=99
STOP=01
USE_PROCD=1

VDSM_PROG="/usr/bin/qemu-system-x86_64"
VDSM_NAME="vdsm"
VDSM_DIR="/mnt/vdsm"
VDSM_PID="/var/run/$VDSM_NAME.pid"
VDSM_LOG="$VDSM_DIR/stdio.log"
VDSM_CONFIG="$VDSM_DIR/$VDSM_NAME.cfg"
VDSM_CPU="host"
VDSM_DISPLAY="none"

### host.bin configs
VDSM_H_API_CMD=6
VDSM_H_APIT_TIMEOUT=50
VDSM_H_API_HOST="127.0.0.1:2211"
VDSM_H_PROG="$VDSM_DIR/host.bin"
VDSM_H_PID="/var/run/$VDSM_NAME_host.pid"
VDSM_H_CPU=2
VDSM_H_CPU_ARCH="kvm64,,"
VDSM_H_MAC="00:00:00:00:00:00"
VDSM_H_MODEL="openwrt"
VDSM_H_HOSTSN="0000000000000"
VDSM_H_GUESTSN="0000000000000"

start_service() {
  ## host.bin
  procd_open_instance
  procd_set_param command $VDSM_H_PROG
  procd_append_param command \
    -addr=0.0.0.0:12346
    -cpu=$VDSM_H_CPU \
    -cpu_arch="$VDSM_H_CPU_ARCH" \
    -mac=$VDSM_H_MAC \
    -model=$VDSM_H_MODEL \
    -hostsn=$VDSM_H_HOSTSN \
    -guestsn=$VDSM_H_GUESTSN
  procd_set_param pidfile $VDSM_H_PID
  procd_close_instance

  ## vdsm qemu
  procd_open_instance
  procd_set_param command $VDSM_PROG
  procd_append_param command \
    -name $VDSM_NAME,process=$VDSM_NAME \
    -cpu $VDSM_CPU -enable-kvm \
    -display $VDSM_DISPLAY \
    -nodefaults \
    -chardev stdio,id=charlog,logfile=$VDSM_LOG,signal=off \
    -serial chardev:charlog \
    -readconfig $VDSM_CONFIG
  procd_set_param pidfile $VDSM_PID
  procd_set_param term_timeout 80
  procd_close_instance
}

stop_service() {
  url="http://$VDSM_H_API_HOST/read?command=$VDSM_H_API_CMD&timeout=$VDSM_H_APIT_TIMEOUT"
  response=$(curl -sk -m "$(( VDSM_H_APIT_TIMEOUT+2 ))" -S "$url" 2>&1)
  pid=$(cat $VDSM_PID)
  pid_host=$(cat $VDSM_H_PID)

  if [[ "$response" =~ "\"success\"" ]]; then
    MSG="Virtual DSM is now ready to shutdown..."
    echo $MSG
    logger -p notice -t QEMU $MSG
    while [ -e /proc/$pid ]; do sleep 3s; done
  else
    MSG="Virtual DSM Forcefully shutdown"
    echo $MSG
    logger -p notice -t QEMU $MSG
    kill -15 "$pid"
  fi

  # kill host.bin if is running
  if [ -e /proc/$pid_host ]; then
    kill -9 $pid_host
  fi
}

service_stopped() {
  MSG="Virtual DSM process finished"
  echo $MSG
  logger -p notice -t QEMU $MSG
}

reload_service() {
  stop
  start
}
