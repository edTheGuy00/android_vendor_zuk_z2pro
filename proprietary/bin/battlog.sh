#!/system/bin/sh
######################################################################
# 0          1    2      3           4         5           6           7       8            9
# battlog.sh date uptime output_file dumper_en dumper_flag prop_length log_cnt record_count pause_time
######################################################################

MOD="8996"
VER=6
tz_num=38
no_len=0
total_module=10
local utime
local ktime

if [ -n "$1" ] && [ -n "$2" ] && [ -n "$3" ] && [ -n "$4" ] && [ -n "$5" ] && [ -n "$6" ] && [ -n "$7" ] && [ -n "$8" ] && [ -n "$9" ]; then
	bc_date="$1"
	bc_uptime="$2"
	out_file="$3"
	out_dumper="$3.qc"
	tmp_file="$3.tmp"
	dumper_en="$4"
	dumper_flag="$5"
	raw_prop_len="$6"
	log_cnt="$7"
	rec_cnt="$8"
	pause_time="$9"
else
	exit
fi

get_temp_prop() {
	local p1=
	local i=0
	while [ $i -lt $tz_num ]
	do
		p1+=" "/sys/devices/virtual/thermal/thermal_zone$i/type
		i=$(($i+1))
	done
	prop=`cat $p1  | tr '\n' ','`
	prop=`echo ${prop%,*}`
}

get_temp_value() {
	local p1=
	local i=0
	while [ $i -lt $tz_num ]
	do
		p1+=" "/sys/devices/virtual/thermal/thermal_zone$i/temp
		i=$(($i+1))
	done
	value=`cat $p1  | tr '\n' ','`
	value=`echo ${value%,*}`
}

get_value_len() {
	local arr
	OLD_IFS="$IFS"
	IFS=$','
	arr=($value)
	echo ${#arr[@]}
	IFS=$OLD_IFS
}

get_freq_value() {
	local p1=
	local i=0
	echo 0 >$tmp_file
	while [ $i -lt 4 ]
	do
		if [ -f "/sys/devices/system/cpu/cpu$i/cpufreq/scaling_cur_freq" ]; then
			p1+=" "/sys/devices/system/cpu/cpu$i/cpufreq/scaling_cur_freq
		else
			p1+=" "$tmp_file
		fi
		i=$(($i+1))
	done
	p1+=" ""/sys/devices/soc/b00000.qcom,kgsl-3d0/kgsl/kgsl-3d0/gpuclk"
	value=`cat $p1  | tr '\n' ','`
	value=`echo ${value%,*}`
	rm $tmp_file
}

get_usbin_value() {
	value=`cat /sys/class/hwmon/hwmon2/device/chg_temp /sys/class/hwmon/hwmon2/device/usb_dm /sys/class/hwmon/hwmon2/device/usb_dp /sys/class/hwmon/hwmon2/device/usbin | tr '\n' ',' | tr ' ' ',' |  tr ':' ',' | cut -d "," -f  2,6,10,14`","
	value=`echo ${value%,*}`
}

get_vph_pwr_value() {
	value=`cat /sys/devices/soc/qpnp-vadc-*/vph_pwr | tr '\n' ',' | tr ' ' ',' |  tr ':' ',' | cut -d "," -f  2,6,10,14`","
	value=`echo ${value%,*}`
}

get_ps_prop() {
	local a b arr i
	a=`cat $1`
	b=""
	OLD_IFS="$IFS"
	IFS=$'\n'
	arr=($a)
	for i in ${arr[@]}
	do
		c=${i%=*}
		b=$b"${c:13},"
	done
	IFS=$OLD_IFS
	prop=`echo $(echo $b | tr '[A-Z]' '[a-z]')`
	prop=`echo ${prop%,*}`
	IFS=$OLD_IFS
}

get_ps_value() {
	local a arr i
	a=`cat $1`
	value=""
	OLD_IFS="$IFS"
	IFS=$'\n'
	arr=($a)
	for i in ${arr[@]}
	do
		value=$value${i#*=}","
	done;
	IFS=$OLD_IFS
	value=`echo ${value%,*}`
}

get_new_prop() {
	local prop_arr raw_prop_arr i j is_same
	OLD_IFS="$IFS"
	IFS=","
	prop_arr=($prop)
	raw_prop_arr=($raw_prop)
	IFS="$OLD_IFS"

	raw_prop="$raw_prop"",module_x_$1"
	is_same=0
	for i in ${prop_arr[@]}
	do
		for j in ${raw_prop_arr[@]}
		do
			if [[ "$i" == "$j" ]]; then
				raw_prop="$raw_prop"",$1""_x_$i"
				is_same=1
				break
			fi
		done
		if [ $is_same -ne 1 ]; then
			raw_prop="$raw_prop"",$i"
		fi
		is_same=0
	done
	return ${#prop_arr[@]}
}

get_virtual_value() {
	local v=
	local i=1
	while true
	do
		if [ $i -lt $1 ]; then
			v=",""$v"
			i=$(($i+1))
		else
			break
		fi
	done
	echo "$v"
}

dump_peripheral () {
	local base=$1
	local size=$2
	local dump_path=$3
	echo $base > $dump_path/address
	echo $size > $dump_path/count
	value=`cat $dump_path/data`
}

dump_smbchg_fg_regs () {
	echo $1 >$2
	value=`cat $2`
}

build_dumper_log() {
	if [ ! -s $out_dumper ] || [ ! -e $out_dumper ]; then
		qc_buf="Starting dumps! flag = $log_cnt""\n"
		qc_buf="$qc_buf""Dump path = $dump_path, pause time = $pause_time""\n"

		qc_buf="$qc_buf""Time is $bc_date""\n"
		qc_buf="$qc_buf""SRAM and SPMI Dump""\n"
		dump_smbchg_fg_regs 0 "/proc/fg_regs"
		qc_buf="$qc_buf""$value""\n"
		echo "$qc_buf" >$out_dumper
	fi

	qc_buf="Time is $bc_date""\n"
	if [ $dumper_flag -eq 1 ]; then
		qc_buf="$qc_buf""Charger Dump Started at $bc_uptime""\n"
		dump_smbchg_fg_regs 0 "/proc/smbchg_regs"
		qc_buf="$qc_buf""$value""\n"
		dump_smbchg_fg_regs 1 "/proc/smbchg_regs"
		qc_buf="$qc_buf""$value""\n"
		qc_buf="$qc_buf""Charger Dump done at $bc_uptime""\n"
		qc_buf="$qc_buf""FG Dump Started at $bc_uptime""\n"
		dump_smbchg_fg_regs 2 "/proc/smbchg_regs"
		qc_buf="$qc_buf""$value""\n"
		qc_buf="$qc_buf""FG Dump done at $bc_uptime""\n"
		qc_buf="$qc_buf""PS Capture Started at $bc_uptime""\n"
		qc_buf="$qc_buf"`cat /sys/class/power_supply/bms/uevent`"\n"
		qc_buf="$qc_buf"`cat /sys/class/power_supply/battery/uevent`"\n"
		qc_buf="$qc_buf""PS Capture done at $bc_uptime""\n"

		qc_buf="$qc_buf""SRAM Dump Started at $bc_uptime""\n"
		dump_smbchg_fg_regs 1 "/proc/fg_regs"
		qc_buf="$qc_buf""$value""\n"
		qc_buf="$qc_buf""SRAM Dump done at $bc_uptime""\n"
	else
		qc_buf="$qc_buf""SRAM Dump Started at $bc_uptime""\n"
		dump_smbchg_fg_regs 1 "/proc/fg_regs"
		qc_buf="$qc_buf""$value""\n"
		qc_buf="$qc_buf""SRAM Dump done at $bc_uptime""\n"
	fi
	echo "$qc_buf" >>$out_dumper
}

build_battery_log() {
	if [ ! -s $out_file ] || [ ! -e $out_file ]; then
		raw_prop="log_cnt,rec_cnt,module,version,date,uptime"

		get_ps_prop "/sys/class/power_supply/battery/uevent"
		get_new_prop "ps_battery"
		ps_battery_len=$?
		raw_prop_len="$ps_battery_len"

		get_ps_prop "/sys/class/power_supply/bms/uevent"
		get_new_prop "ps_bms"
		ps_bms_len=$?
		raw_prop_len="$raw_prop_len"",$ps_bms_len"

		get_ps_prop "/sys/class/power_supply/lenuk_battery/uevent"
		get_new_prop "ps_lenuk_battery"
		ps_lenuk_battery_len=$?
		raw_prop_len="$raw_prop_len"",$ps_lenuk_battery_len"

		get_ps_prop "/sys/class/power_supply/usb-parallel/uevent"
		get_new_prop "ps_usb-parallel"
		ps_usb_parallel_len=$?
		raw_prop_len="$raw_prop_len"",$ps_usb_parallel_len"

		get_ps_prop "/sys/class/power_supply/usb/uevent"
		get_new_prop "ps_usb"
		ps_usb_len=$?
		raw_prop_len="$raw_prop_len"",$ps_usb_len"

		prop="0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0a,0x0b,0x0c,0x0d,0x0e,0x0f,0x10,0x11,0x12,0x13,0x14,0x15,0x16,0x30,0x31,0x32,0x33,0x34,0x36,0x37,0x38,0x39,0x3a,0x3b,0x3c,0x3d,0x3e,0x3f"
		get_new_prop "smb1351"
		smb1351_len=$?
		raw_prop_len="$raw_prop_len"",$smb1351_len"

		get_temp_prop
		get_new_prop "temp"
		temp_len=$?
		raw_prop_len="$raw_prop_len"",$temp_len"

		prop="cpu0,cpu1,cpu2,cpu3,gpu"
		get_new_prop "freq"
		freq_len=$?
		raw_prop_len="$raw_prop_len"",$freq_len"

		prop="chg_temp,usb_dm,usb_dp,usbin"
		get_new_prop "usbin"
		usbin_len=$?
		raw_prop_len="$raw_prop_len"",$usbin_len"

		prop="vph_pwr"
		get_new_prop "vph_pwr"
		vph_pwr_len=$?
		raw_prop_len="$raw_prop_len"",$vph_pwr_len"

		echo "$raw_prop" >$out_file
		raw_prop_len="$total_module,$raw_prop_len"
	else
		if [[ "$raw_prop_len" == "0" ]]; then
			no_len=1
		else
			OLD_IFS="$IFS"
			IFS=$','
			arr=($raw_prop_len)
			IFS=$OLD_IFS

			for i in ${arr[@]}
			do
				if [[ ${arr[i]} == *[!0-9]* ]]; then
					no_len=1
					break
				fi
			done

			if [ $no_len -eq 0 ]; then
				((j = ${arr[@]} - 1))
				if [ $j -ne ${arr[0]} ] || [ $j -ne $total_module ]; then
					no_len=1
				fi
			fi
		fi

		if [ $no_len -eq 0 ]; then
			ps_battery_len=${arr[1]}
			ps_bms_len=${arr[2]}
			ps_lenuk_battery_len=${arr[3]}
			ps_usb_parallel_len=${arr[4]}
			ps_usb_len=${arr[5]}
			smb1351_len=${arr[6]}
			temp_len=${arr[7]}
			freq_len=${arr[8]}
			usbin_len=${arr[9]}
			vph_pwr_len=${arr[10]}
		fi
	fi

	raw_value="$log_cnt,$rec_cnt,$MOD,$VER,$bc_date,$bc_uptime"

	if [ $no_len -eq 1 ]; then
		echo $raw_value >>$out_file
		return
	fi

	get_ps_value "/sys/class/power_supply/battery/uevent"
	if [[ `get_value_len` -eq $ps_battery_len ]]; then
		raw_value="$raw_value"",ps_battery,$value"
	else
		raw_value="$raw_value"",ps_battery,`get_virtual_value $ps_battery_len`"
	fi

	get_ps_value "/sys/class/power_supply/bms/uevent"
	if [[ `get_value_len` -eq $ps_bms_len ]]; then
		raw_value="$raw_value"",ps_bms,$value"
	else
		raw_value="$raw_value"",ps_bms,`get_virtual_value $ps_bms_len`"
	fi

	get_ps_value "/sys/class/power_supply/lenuk_battery/uevent"
	if [[ `get_value_len` -eq $ps_lenuk_battery_len ]]; then
		raw_value="$raw_value"",ps_lenuk_battery,$value"
	else
		raw_value="$raw_value"",ps_lenuk_battery,`get_virtual_value $ps_lenuk_battery_len`"
	fi

	get_ps_value "/sys/class/power_supply/usb-parallel/uevent"
	if [[ `get_value_len` -eq $ps_usb_parallel_len ]]; then
		raw_value="$raw_value"",ps_usb-parallel,$value"
	else
		raw_value="$raw_value"",ps_usb-parallel,`get_virtual_value $ps_usb_parallel_len`"
	fi

	get_ps_value "/sys/class/power_supply/usb/uevent"
	if [[ `get_value_len` -eq $ps_usb_len ]]; then
		raw_value="$raw_value"",ps_usb,$value"
		if [[ "$value" == "usb,1"* ]]; then
			value=`cat /proc/smb1351_regs`
			value=","`echo ${value%,*}`
			value=${value//,/,0x}
			value=`echo ${value:1}`
			if [[ `get_value_len` -eq $smb1351_len ]]; then
				raw_value="$raw_value"",smb1351,$value"
			else
				raw_value="$raw_value"",smb1351,`get_virtual_value $smb1351_len`"
			fi
		else
			raw_value="$raw_value"",smb1351,`get_virtual_value $smb1351_len`"
		fi
	else
		raw_value="$raw_value"",ps_usb,`get_virtual_value $ps_usb_len`"
		raw_value="$raw_value"",smb1351,`get_virtual_value $smb1351_len`"
	fi

	get_temp_value
	if [[ `get_value_len` -eq $temp_len ]]; then
		raw_value="$raw_value"",temp,$value"
	else
		raw_value="$raw_value"",temp,`get_virtual_value $temp_len`"
	fi

	get_freq_value
	if [[ `get_value_len` -eq $freq_len ]]; then
		raw_value="$raw_value"",freq,$value"
	else
		raw_value="$raw_value"",freq,`get_virtual_value $freq_len`"
	fi

	get_usbin_value
	if [[ `get_value_len` -eq $usbin_len ]]; then
		raw_value="$raw_value"",usbin,$value"
	else
		raw_value="$raw_value"",usbin,`get_virtual_value $usbin_len`"
	fi

	get_vph_pwr_value
	if [[ `get_value_len` -eq $vph_pwr_len ]]; then
		raw_value="$raw_value"",vph_pwr,$value"
	else
		raw_value="$raw_value"",vph_pwr,`get_virtual_value $vph_pwr_len`"
	fi

	echo $raw_value >>$out_file
}

build_battery_log
if [[ $dumper_en -eq 1 ]]; then
	build_dumper_log
fi
echo "prop_len=[""$raw_prop_len""]=prop_len"
