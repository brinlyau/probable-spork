#!/system/bin/sh
# Copyright (c) 2009-2015, The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of The Linux Foundation nor
#       the names of its contributors may be used to endorse or promote
#       products derived from this software without specific prior written
#       permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NON-INFRINGEMENT ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
chown -h system:system /sys/devices/soc/qpnp-smbcharger-*/battery_max_current
target=`getprop ro.board.platform`
if [ -f /sys/devices/soc0/soc_id ]; then
    platformid=`cat /sys/devices/soc0/soc_id`
else
    platformid=`cat /sys/devices/system/soc/soc0/id`
fi


start_msm_irqbalance_8939()
{
	if [ -f /system/bin/msm_irqbalance ]; then
		case "$platformid" in
		    "239" | "293" | "294" | "295" | "304")
			start msm_irqbalance;;
		esac
	fi
}

start_copying_prebuilt_qcril_db()
{
    if [ -f /system/vendor/qcril.db -a ! -f /data/misc/radio/qcril.db ]; then
        cp /system/vendor/qcril.db /data/misc/radio/qcril.db
        chown -h radio.radio /data/misc/radio/qcril.db
    fi
}

baseband=`getprop ro.baseband`
echo 1 > /proc/sys/net/ipv6/conf/default/accept_ra_defrtr

case "$baseband" in
        "svlte2a")
        start bridgemgrd
        ;;
esac

case "$target" in
    "msm8937")
        start_msm_irqbalance_8939
        if [ -f /sys/devices/soc0/soc_id ]; then
            soc_id=`cat /sys/devices/soc0/soc_id`
        else
            soc_id=`cat /sys/devices/system/soc/soc0/id`
        fi

        if [ -f /sys/devices/soc0/hw_platform ]; then
             hw_platform=`cat /sys/devices/soc0/hw_platform`
        else
             hw_platform=`cat /sys/devices/system/soc/soc0/hw_platform`
        fi
        case "$soc_id" in
             "294" | "295" | "303" | "307" | "308" | "309" | "313")
                  case "$hw_platform" in
                       "Surf")
                                    setprop qemu.hw.mainkeys 0
                                    ;;
                       "MTP")
                                    setprop qemu.hw.mainkeys 0
                                    ;;
                       "RCM")
                                    setprop qemu.hw.mainkeys 0
                                    ;;
                  esac
                  ;;
       esac
        ;;
    "msm8953")
	start_msm_irqbalance_8939
        if [ -f /sys/devices/soc0/soc_id ]; then
            soc_id=`cat /sys/devices/soc0/soc_id`
        else
            soc_id=`cat /sys/devices/system/soc/soc0/id`
        fi

        if [ -f /sys/devices/soc0/hw_platform ]; then
             hw_platform=`cat /sys/devices/soc0/hw_platform`
        else
             hw_platform=`cat /sys/devices/system/soc/soc0/hw_platform`
        fi
        case "$soc_id" in
             "293" | "304" )
                  case "$hw_platform" in
                       "Surf")
                                    setprop qemu.hw.mainkeys 0
                                    ;;
                       "MTP")
                                    setprop qemu.hw.mainkeys 0
                                    ;;
                       "RCM")
                                    setprop qemu.hw.mainkeys 0
                                    ;;
                  esac
                  ;;
       esac
        ;;
esac

bootmode=`getprop ro.bootmode`
emmc_boot=`getprop ro.boot.emmc`
case "$emmc_boot"
    in "true")
        if [ "$bootmode" != "charger" ]; then # start rmt_storage and rfs_access
            start rmt_storage
            start rfs_access
        fi
    ;;
esac

#
# Copy qcril.db if needed for RIL
#
start_copying_prebuilt_qcril_db
echo 1 > /data/misc/radio/db_check_done

#
# Make modem config folder and copy firmware config to that folder for RIL
#
if [ -f /data/misc/radio/ver_info.txt ]; then
    prev_version_info=`cat /data/misc/radio/ver_info.txt`
else
    prev_version_info=""
fi

cur_version_info=`cat /firmware/verinfo/ver_info.txt`
if [ "$prev_version_info" != "$cur_version_info" ]; then
    rm -rf /data/misc/radio/modem_config
    mkdir /data/misc/radio/modem_config
    chmod 770 /data/misc/radio/modem_config
    cp -r /firmware/image/modem_pr/mcfg/configs/* /data/misc/radio/modem_config
    chown -hR radio.radio /data/misc/radio/modem_config
    cp /firmware/verinfo/ver_info.txt /data/misc/radio/ver_info.txt
    chown radio.radio /data/misc/radio/ver_info.txt
fi
echo 1 > /data/misc/radio/copy_complete
