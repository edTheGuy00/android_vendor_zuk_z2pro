#!/system/bin/sh

umask 022
APLOG_DIR=/data/local/newlog/aplog

LOGFILE=${APLOG_DIR}"/dmesglog"
LOGFILE_MAX_SIZE=104857600

PMLOGSHELL_ENG="/system/bin/pmlog.sh"
PMLOGSHELL_USER="/data/local/newlog/pmlog.sh"
PMLOGFILE=${APLOG_DIR}"/pmlog"
PMLOGFILE_MAX_SIZE=3145728

SMD_LOGFILE=${APLOG_DIR}"/smd_log"
TZ_LOGFILE=${APLOG_DIR}"/tzlog"

QSEE_LOGFILE=${APLOG_DIR}"/qseelog"
QSEE_LOGFILE_MAX_SIZE=5242880

LASTKMSG_LOGFILE=${APLOG_DIR}"/lastkmsg"
RAMOOPS_LOGFILE=${APLOG_DIR}"/rkmsg"
LKMSG_LOGFILE=${APLOG_DIR}"/lkmsg"
XBLMSG_LOGFILE=${APLOG_DIR}"/xblmsg"

# mv files.x-1 to files.x
mv_files()
{
	if [ -z "$1" ]; then
	  echo "No file name!"
	  return
	fi

	if [ -z "$2" ]; then
      fileNum=$(getprop persist.sys.aplogfiles)
      if [ $fileNum -gt 0 ]; then
        LAST_FILE=$fileNum
      else
	    LAST_FILE=5
      fi
	else
	  LAST_FILE=$2
	fi

#	echo $1 $2 $LAST_FILE
	i=$LAST_FILE
	while [ $i -gt 0 ]; do
#	for ((i=$LAST_FILE; i>=0; i--)); do
	  prev=$(($i-1))
	  if [ -e "$1.$prev" ]; then
#	    echo mv $1.$prev $1.$i
	    mv $1.$prev $1.$i
	  fi
	  i=$(($i-1))
	done

	if [ -e $1 ]; then
#	  echo mv $1 $1.1
	  mv $1 $1.1
	fi
}

mv_files $LOGFILE
mv_files $PMLOGFILE
mv_files $SMD_LOGFILE
mv_files $TZ_LOGFILE
mv_files $QSEE_LOGFILE

date  >> $TZ_LOGFILE
echo "" >> $TZ_LOGFILE

date  >> $QSEE_LOGFILE
echo "" >> $QSEE_LOGFILE

if [ -e /d/le_rkm ]; then
    mv_files $LASTKMSG_LOGFILE
    cat /d/le_rkm/last_kmsg > $LASTKMSG_LOGFILE
    mv_files $LKMSG_LOGFILE
    cat /d/le_rkm/lk_mesg > $LKMSG_LOGFILE
    mv_files $XBLMSG_LOGFILE
    cat /d/le_rkm/sbl1_mesg > $XBLMSG_LOGFILE
fi

if [ -e /sys/fs/pstore/console-ramoops ]; then
    mv_files $RAMOOPS_LOGFILE
    cat /sys/fs/pstore/console-ramoops > $RAMOOPS_LOGFILE
fi

while [ 1 ]
do
	date  >> $LOGFILE
	echo "" >> $LOGFILE
	date >> $QSEE_LOGFILE
	date >> $TZ_LOGFILE
# /data/local/newlog/pmlog.sh can bypass /system/bin/pmlog.sh
# You can push pmlog.sh to /data/local/newlog after change it
	if [ -e $PMLOGSHELL_USER ]; then
# Use . to inherit the environment
		. $PMLOGSHELL_USER $LOGFILE $PMLOGFILE
	else
		if [ -e $PMLOGSHELL_ENG ]; then
# Use . to inherit the environment
		. $PMLOGSHELL_ENG $LOGFILE $PMLOGFILE
		fi
	fi
    PMLOGFILE_size=`stat -c "%s" $PMLOGFILE`
    if [ $PMLOGFILE_size -gt $PMLOGFILE_MAX_SIZE ]; then
        mv_files $PMLOGFILE
    fi

    cat /d/tzdbg/qsee_log >> $QSEE_LOGFILE
    QSEE_LOGFILE_size=`stat -c "%s" $QSEE_LOGFILE`
    if [ $QSEE_LOGFILE_size -gt $QSEE_LOGFILE_MAX_SIZE ]; then
        mv_files $QSEE_LOGFILE
    fi

    cat /d/tzdbg/log >> $TZ_LOGFILE

    dmesg -c >> $LOGFILE
    LOGFILE_size=`stat -c "%s" $LOGFILE`
    if [ $LOGFILE_size -gt $LOGFILE_MAX_SIZE ]; then
        mv_files $LOGFILE
    fi

	sleep 2
done

