#!/system/bin/sh

# Add by wangwq14, start to record battery log.

umask 022

APLOG_DIR=/data/local/newlog/aplog

BATT_LOGSHELL="/system/bin/battlog.sh"
BATT_LOGFILE=${APLOG_DIR}"/battlog"
BATT_LOGFILE_QC=${APLOG_DIR}"/battlog.qc"
BATT_LOGFILE_GROUP_MAX_SIZE=20971520

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

mv_files $BATT_LOGFILE
mv_files $BATT_LOGFILE_QC

file_count=0
count=1
dumper_en=1
prop_len=0
pause_time=10

while [ 1 ]
do
	utime=($(cat /proc/uptime))
	ktime=${utime[0]}

	if [ $(((count - 1) % 5)) -eq 0 ]; then
		dumper_flag=1
	else
		dumper_flag=0
	fi

	#      0              1         2        3             4          5            6           7           8      9
	buf=`. $BATT_LOGSHELL "$(date)" ${ktime} $BATT_LOGFILE $dumper_en $dumper_flag "$prop_len" $file_count $count $pause_time`

	buf=`echo ${buf##*prop_len=\[}`
	prop_len=`echo ${buf%\]=prop_len*}`

    BATT_LOGFILE_size=`stat -c "%s" $BATT_LOGFILE`
    BATT_LOGFILE_QC_size=`stat -c "%s" $BATT_LOGFILE_QC`
    BATT_LOGFILE_GROUP_size=$(($BATT_LOGFILE_size+$BATT_LOGFILE_QC_size))

	let count=$count+1
	sleep $pause_time

    if [ $BATT_LOGFILE_GROUP_size -gt $BATT_LOGFILE_GROUP_MAX_SIZE ]; then
        mv_files $BATT_LOGFILE
        mv_files $BATT_LOGFILE_QC
	let file_count=$file_count+1
    fi
done

