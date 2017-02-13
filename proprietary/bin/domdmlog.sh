#!/system/bin/sh

mdmlog_stat="stopped"
# start modem offline log

enable_mdm_log=0

function start_mdmlog() 
{
    if [ -e /sdcard/log_cfg/cs.cfg ]; then
        setprop "persist.sys.lenovo.log.qxdmcfg" "/sdcard/log_cfg/cs.cfg"
    else
        setprop "persist.sys.lenovo.log.qxdmcfg" "/system/etc/cs.cfg"
    fi
    setprop "persist.sys.lenovo.log.path" "/sdcard/log"

    for i in $(seq 0 9)
    do 
        setprop "ctl.start" startmdmlog 
        mdmlog_stat=$(getprop "init.svc.startmdmlog")
        if [ "$mdmlog_stat" == "running" ]; then
            break
        else
            sleep 1
        fi
   done
}

build_type=$(getprop "ro.build.type")
if [ "$build_type" == "user" ]; then
    exit
fi

#check if /sdcard/log and cs.cfg are ready
for i in $(seq 0 1000)
do
    if [ -e /sdcard/log ]; then
#        echo "sdcard-log ready i:$i" >> /sdcard/log/debug.log
        break
    else
	if [ "i" == "0" ]; then
            sleep 15
        else
            sleep 1
        fi
    fi

    if [ "$i" == "1000" ]; then
#        echo "sdcard-log and cs.cfg not ready" >> /sdcard/log/debug.log
        exit
    fi
done

#echo "checking enable_mdm_log switch from nv" >> /sdcard/log/debug.log
for i in $(seq 0 9)
do
    if [ -e /proc/lnvqlogd ]; then
        enable_mdm_log=$(cat /proc/lnvqlogd)
#        echo "read after i:$i enable_mdm_log:$enable_mdm_log" >> /sdcard/log/debug.log
	break
    else
        sleep 1
    fi
done

#echo "checking enable_mdm_log switch mdmlog.enable" >> /sdcard/log/debug.log
if [ "$enable_mdm_log" == "0" ]; then
    for i in $(seq 0 9)
    do
        if [ -e /data/local/newlog/mdmlog.enable ]; then
            enable_mdm_log=1
            break
        else
            sleep 1
        fi
    done
fi

#echo "starting modem offline log enable_mdm_log:$enable_mdm_log" >> /sdcard/log/debug.log
if [ "$enable_mdm_log" == "1" ]; then
#    echo "starting modem offline log" >> /sdcard/log/debug.log
    start_mdmlog
fi
