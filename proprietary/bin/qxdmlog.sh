#!/system/bin/sh

umask 022

CFGFILE=$(getprop persist.sys.lenovo.log.qxdmcfg)
LOGFILE=$(getprop persist.sys.lenovo.log.path)
#echo "qxdmlog.sh $1"
if [ "$1" == "start" ]; then
    #echo "start mdlog"
	#kill the diag_mdlog process at first
	/system/bin/diag_mdlog -k -c
	# -s set the single log size in MB 
	/system/bin/diag_mdlog -s 512 -n 10 -f $CFGFILE -o $LOGFILE
else
    #echo "stop mdlog"
	#kill the diag_mdlog process at first
	/system/bin/diag_mdlog -k -c
fi
