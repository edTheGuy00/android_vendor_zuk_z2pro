#!/system/bin/sh

APLOG_DIR=/data/local/newlog/aplog

TMLOG_DIR=/persist/testmode
TMLOG_ALL_DIR=/persist/testmode.*
GPSLOG_DIR=/data/gps/log
ANR_DIR=/data/anr
RECOVERY_DIR=/cache/recovery
CRASH_DIR=/data/tombstones
BT_ENABLE=$APLOG_DIR/bluetooth.enable
BT_DIR=/data/misc/bluedroid
BT_ETC_DIR=/system/etc/bluetooth
WLAN_DIR=/data/misc/wifi
DDR_ID=/sys/devices/system/soc/soc0/ddr_id

cd $APLOG_DIR && rm -fr gps anr recovery wlan
cat /proc/interrupts > $APLOG_DIR/interrupts.txt
cat /proc/meminfo > $APLOG_DIR/meminfo.txt
cat /d/ion/heaps/system > $APLOG_DIR/ion_system.txt
getprop > $APLOG_DIR/prop.txt
[ -e /system/build.prop ] && cp /system/build.prop $APLOG_DIR/
[ -e /system/etc/version.conf ] && cp /system/etc/version.conf $APLOG_DIR/
[ -d $GPSLOG_DIR ] && cp -a $GPSLOG_DIR $APLOG_DIR/gps
[ -d $ANR_DIR ] &&  cp -a $ANR_DIR $APLOG_DIR/anr
[ -d $RECOVERY_DIR ] && cp -a $RECOVERY_DIR $APLOG_DIR/recovery
[ -d $CRASH_DIR ] && cp -a $CRASH_DIR $APLOG_DIR/tombstones
[ -e $BT_ENABLE ] && [ -d $BT_ETC_DIR ] && cp -a $BT_ETC_DIR/* $APLOG_DIR/bluetooth
[ -e $BT_ENABLE ] && [ -d $BT_DIR ] && cp -a $BT_DIR/* $APLOG_DIR/bluedroid
[ -d $WLAN_DIR ] && cp -a $WLAN_DIR $APLOG_DIR/wlan
[ -e $TMLOG_DIR ] && cp -a $TMLOG_DIR $APLOG_DIR
[ -e $TMLOG_DIR ] && cp -a $TMLOG_ALL_DIR $APLOG_DIR
[ -e $DDR_ID ] && cat $DDR_ID > $APLOG_DIR/ddr_id

# add for settings info.
[ -e /data/system/users/0/settings_global.xml ] && cp /data/system/users/0/settings_global.xml $APLOG_DIR/
[ -e /data/system/users/0/settings_secure.xml ] && cp /data/system/users/0/settings_secure.xml $APLOG_DIR/
[ -e /data/system/users/0/settings_system.xml ] && cp /data/system/users/0/settings_system.xml $APLOG_DIR/

## record dumpsys
dumpsys activity -a > $APLOG_DIR/dumpsys_activity

for dumpsyslog in alarm appops package location battery batterystats power audio window notification meminfo display media.audio_policy cpuinfo sensorservice deviceidle; do
    dumpsys $dumpsyslog > $APLOG_DIR/dumpsys_$dumpsyslog
done

FILENAME=$(date +%Y_%m_%d_%H_%M_%S)

mkdir -p /sdcard/log
tar zcf /sdcard/log/${FILENAME}.tgz -C ${APLOG_DIR}/../ aplog

for svc in dmesglog batterylog tcplog mainlog mainlog_big radiolog radiolog_big; do
    eval ${svc}=$(getprop init.svc.${svc})
    if eval [ "\$$svc" = "running" ]; then
        stop $svc
    fi
done

# wait for stop services done.
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

# remove files except '*.enable'
rm -f $APLOG_DIR/!(*.enable)

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

for svc in dmesglog batterylog tcplog mainlog mainlog_big radiolog radiolog_big; do
    if eval [ "\$$svc" = "running" ]; then
        start $svc
    fi
done

# wait for start services done
wait
