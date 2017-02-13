#!/system/bin/sh

# Add by wangwq14 for stop aplog services.

APLOG_DIR=/data/local/newlog/aplog

# If log service running, should stop them.
for svc in dmesglog batterylog tcplog mainlog mainlog_big radiolog radiolog_big; do
    eval ${svc}=$(getprop init.svc.${svc})
    if eval [ "\$$svc" = "running" ]; then
        stop $svc
    fi
done

# wait for log services stop done.
wait

# remove history log.
rm -rf $APLOG_DIR/tombstones/*
rm -rf $APLOG_DIR/bluetooth/*
rm -rf $APLOG_DIR/anr/*
rm -rf $APLOG_DIR/gps/*
rm -rf $APLOG_DIR/recovery/*
rm -rf $APLOG_DIR/wlan/*
rm -rf $APLOG_DIR/tcps/*
rm -rf $APLOG_DIR/logcats/*

rm -f $APLOG_DIR/!(aplogsetting.enable)

# clean logcat system buffer
logcat -c
logcat -b radio -c

#clean anr, recovery, tombstones history files
rm -f /cache/recovery/*
rm -f /data/anr/*
rm -f /data/tombstones/*
rm -rf /data/tombstones/dsps/*
rm -rf /data/tombstones/lpass/*
rm -rf /data/tombstones/modem/*
rm -rf /data/tombstones/wcnss/*

wait
