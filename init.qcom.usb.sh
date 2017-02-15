#!/system/bin/sh
# Copyright (c) 2012-2016, The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
#       copyright notice, this list of conditions and the following
#       disclaimer in the documentation and/or other materials provided
#       with the distribution.
#     * Neither the name of The Linux Foundation nor the names of its
#       contributors may be used to endorse or promote products derived
#      from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT
# ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
# IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#
chown -h root.system /sys/devices/platform/msm_hsusb/gadget/wakeup
chmod -h 220 /sys/devices/platform/msm_hsusb/gadget/wakeup

# Set platform variables
if [ -f /sys/devices/soc0/hw_platform ]; then
    soc_hwplatform=`cat /sys/devices/soc0/hw_platform` 2> /dev/null
else
    soc_hwplatform=`cat /sys/devices/system/soc/soc0/hw_platform` 2> /dev/null
fi

# Get hardware revision
if [ -f /sys/devices/soc0/revision ]; then
    soc_revision=`cat /sys/devices/soc0/revision` 2> /dev/null
else
    soc_revision=`cat /sys/devices/system/soc/soc0/revision` 2> /dev/null
fi

# check configfs is mounted or not
if [ -d /config/usb_gadget ]; then
	setprop sys.usb.configfs 1
fi

#
# Allow USB enumeration with default PID/VID
#
baseband=`getprop ro.baseband`
echo 1  > /sys/class/android_usb/f_mass_storage/lun/nofua
usb_config=`getprop persist.sys.usb.config`
case "$usb_config" in
    "" | "adb") #USB persist config not set, select default configuration
      case "$esoc_link" in
          "PCIe")
              setprop persist.sys.usb.config diag,diag_mdm,serial_cdev,rmnet_qti_ether,mass_storage,adb
          ;;
          *)
	  case "$soc_hwplatform" in
	      "Dragon")
	          setprop persist.sys.usb.config diag,adb
	      ;;
              *)
	      case "$target" in
	          "msm8909" | "msm8937")
		      setprop persist.sys.usb.config diag,serial_smd,rmnet_qti_bam,adb
		  ;;
	          "msm8952" | "msm8953" | "msm8940")
		      setprop persist.sys.usb.config diag,serial_smd,rmnet_ipa,adb
		  ;;
	          *)
		      setprop persist.sys.usb.config diag,adb
		  ;;
              esac
	      ;;
	  esac
	  ;;
      esac
      ;;
  * ) ;; #USB persist config exists, do nothing
esac

#
# Do target specific things
#
case "$target" in
    "msm8994" | "msm8992" | "msm8996" | "msm8953" | "msm8940")
        echo BAM2BAM_IPA > /sys/class/android_usb/android0/f_rndis_qc/rndis_transports
        echo 131072 > /sys/module/g_android/parameters/mtp_tx_req_len
        echo 131072 > /sys/module/g_android/parameters/mtp_rx_req_len
    ;;
esac

#
# Initialize RNDIS Diag option. If unset, set it to 'none'.
#
diag_extra=`getprop persist.sys.usb.config.extra`
if [ "$diag_extra" == "" ]; then
	setprop persist.sys.usb.config.extra none
fi

# soc_ids for 8937
if [ -f /sys/devices/soc0/soc_id ]; then
	soc_id=`cat /sys/devices/soc0/soc_id`
else
	soc_id=`cat /sys/devices/system/soc/soc0/id`
fi

# enable rps cpus on msm8937 target
setprop sys.usb.rps_mask 0
case "$soc_id" in
	"294" | "295")
		setprop sys.usb.rps_mask 40
	;;
esac
