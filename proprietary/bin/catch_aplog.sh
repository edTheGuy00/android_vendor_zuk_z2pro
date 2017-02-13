#!/system/bin/sh

# Add by wangwq14@zuk
# This shell catch system cached log info, system prop, dumpsys.
# The logs will be saved at '/sdcard/log' as a tar, size less than 10M.

umask 022

APLOG_DIR=/data/local/newlog/aplog

CURLOG_DIR=/local/newlog/curlog

TMLOG_DIR=/persist/testmode
GPSLOG_DIR=/data/gps/log
ANR_DIR=/data/anr
RECOVERY_DIR=/cache/recovery
CRASH_DIR=/data/tombstones
BT_DIR=/data/misc/bluedroid
BT_ETC_DIR=/system/etc/bluetooth
WLAN_DIR=/data/misc/wifi

mkdir -p $CURLOG_DIR

cat /proc/interrupts > $CURLOG_DIR/interrupts.txt
cat /proc/meminfo > $CURLOG_DIR/meminfo.txt
cat /d/ion/heaps/system > $CURLOG_DIR/ion_system.txt
getprop > $CURLOG_DIR/prop.txt

[ -e /system/build.prop ] && cp /system/build.prop $CURLOG_DIR/
[ -e /system/etc/version.conf ] && cp /system/etc/version.conf $CURLOG_DIR/
[ -d $GPSLOG_DIR ] && cp -a $GPSLOG_DIR/ $CURLOG_DIR/gps
[ -d $ANR_DIR ] &&  cp -a $ANR_DIR/ $CURLOG_DIR/anr
[ -d $RECOVERY_DIR ] && cp -a $RECOVERY_DIR/ $CURLOG_DIR/recovery
[ -d $CRASH_DIR ] && cp -a $CRASH_DIR/ $CURLOG_DIR/tombstones
[ -d $BT_DIR ] && cp -a $BT_DIR/ $CURLOG_DIR/bluedroid
[ -d $BT_ETC_DIR ] && cp -a $BT_ETC_DIR/ $CURLOG_DIR/bluetooth
[ -d $WLAN_DIR ] && cp -a $WLAN_DIR/ $CURLOG_DIR/wlan
[ -e $TMLOG_DIR ] && cp -a $TMLOG_DIR $CURLOG_DIR

# add for settings info.
[ -e /data/system/users/0/settings_global.xml ] && cp /data/system/users/0/settings_global.xml $CURLOG_DIR/
[ -e /data/system/users/0/settings_secure.xml ] && cp /data/system/users/0/settings_secure.xml $CURLOG_DIR/
[ -e /data/system/users/0/settings_system.xml ] && cp /data/system/users/0/settings_system.xml $CURLOG_DIR/

logcat -d -b main -b system -b crash -v threadtime -f $CURLOG_DIR/logcat
logcat -d -b radio -v threadtime -f $CURLOG_DIR/radio
logcat -d -b events -v threadtime -f $CURLOG_DIR/events

DMESG_LOGFILE=$CURLOG_DIR/dmesglog
TZ_LOGFILE=$CURLOG_DIR/tzlog
QSEE_LOGFILE=$CURLOG_DIR/qseelog
LASTKMSG_LOGFILE=$CURLOG_DIR/lastkmsg
LKMSG_LOGFILE=$CURLOG_DIR/lkmsg
XBLMSG_LOGFILE=$CURLOG_DIR/xblmsg


if [ -e /d/le_rkm ]; then
    date >> $LASTKMSG_LOGFILE
    echo "" >> $LASTKMSG_LOGFILE
    cat /d/le_rkm/last_kmsg >> $LASTKMSG_LOGFILE

    data >> $LKMSG_LOGFILE
    echo "" >> $LKMSG_LOGFILE
    cat /d/le_rkm/lk_mesg > $LKMSG_LOGFILE

    data >> $XBLMSG_LOGFILE
    echo "" >> $XBLMSG_LOGFILE
    cat /d/le_rkm/sbl1_mesg > $XBLMSG_LOGFILE
fi

date  >> $TZ_LOGFILE
echo "" >> $TZ_LOGFILE
cat /d/tzdbg/log >> $TZ_LOGFILE

date  >> $QSEE_LOGFILE
echo "" >> $QSEE_LOGFILE
cat /d/tzdbg/qsee_log >> $QSEE_LOGFILE

date  >> $DMESG_LOGFILE
echo "" >> $DMESG_LOGFILE
dmesg >> $DMESG_LOGFILE

cat $APLOG_DIR/dmesglog > $CURLOG_DIR/dmesglog.r

## record dumpsys
dumpsys activity -a > $CURLOG_DIR/dumpsys_activity

for dumpsyslog in alarm appops package location battery batterystats power audio window notification meminfo display media.audio_policy cpuinfo sensorservice deviceidle; do
    dumpsys $dumpsyslog > $CURLOG_DIR/dumpsys_$dumpsyslog
done

FILENAME=$(date +%Y_%m_%d_%H_%M_%S)

mkdir -p /sdcard/log
tar zcf /sdcard/log/${FILENAME}_curlog.tgz -C $CURLOG_DIR/../ curlog
rm -rf $CURLOG_DIR

#clean anr, recovery, tombstones history files
#rm -f /cache/recovery/*
rm -f /data/anr/*
rm -f /data/tombstones/*
rm -rf /data/tombstones/dsps/*
rm -rf /data/tombstones/lpass/*
rm -rf /data/tombstones/modem/*
rm -rf /data/tombstones/wcnss/*
