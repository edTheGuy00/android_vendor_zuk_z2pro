#!/system/bin/sh

APLOG_DIR=/data/local/newlog/aplog

# Add by wangwq14@zuk.com
# Set log files max numnber
# If userdebug and eng version, set max log file larger to record more logs.
# If user version, you can set this prop by log APK with a hide activity.
if [ $(getprop ro.debuggable) = 1 ]; then
    if [ ! -e $APLOG_DIR/aplogsetting.enable ]; then
        setprop persist.sys.aplogfiles  1000
    fi
fi

# setup log service
if [ -e $APLOG_DIR/aplogsetting.enable ]; then
    for svc in dmesglog batterylog tcplog ; do
        if [ -e $APLOG_DIR/${svc}.enable ]; then
            setprop ctl.start $svc
        else
            setprop ctl.stop $svc
        fi
    done

    if [ $(getprop persist.sys.aplogfiles) -gt 0 ]; then
        if [ -e $APLOG_DIR/mainlog.enable ]; then
            setprop ctl.start mainlog_big
        else
            setprop ctl.stop mainlog_big
        fi

        if [ -e $APLOG_DIR/radiolog.enable ]; then
            setprop ctl.start radiolog_big
        else
            setprop ctl.stop radiolog_big
        fi
    else
        if [ -e $APLOG_DIR/mainlog.enable ]; then
            setprop ctl.start mainlog
        else
            setprop ctl.stop mainlog
        fi

        if [ -e $APLOG_DIR/radiolog.enable ]; then
            setprop ctl.start radiolog
        else
            setprop ctl.stop radiolog
        fi
    fi


    if [ -e $APLOG_DIR/dloadlog.enable ]; then
        setprop persist.sys.dloadmode.config 1
    else
        setprop persist.sys.dloadmode.config 0
    fi

    if [ -e $APLOG_DIR/bluetooth.enable ]; then
        setprop persist.bt.btsnoop true
    else
        setprop persist.bt.btsnoop false
    fi

elif [ $(getprop ro.debuggable) = 1 ]; then
    setprop ctl.start dmesglog
    setprop ctl.start batterylog
    setprop ctl.start tcplog
    setprop ctl.start mainlog_big
    setprop ctl.start radiolog_big
    setprop persist.sys.dloadmode.config 1
    setprop persist.bt.btsnoop true

# start log services once,
# for after factoryreset, qfile burn, or upgrade from Android M.
elif [ -z "$(getprop persist.sys.firstbootfinish)" ]; then
    setprop ctl.start dmesglog
    setprop ctl.start mainlog
    wait

    # start a service to auto save and stop the log services
    setprop ctl.start assalog
else
    setprop persist.sys.dloadmode.config 0
fi

rm -r /data/lost+found

