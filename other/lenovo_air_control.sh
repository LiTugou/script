#!/bin/bash
# https://github.com/shaansubbaiah/powercontrol
# Built using information from the Arch Wiki
# https://wiki.archlinux.org/index.php/Lenovo_IdeaPad_5_14are05#Tips_and_tricks

toggle_batteryconserve() {
    # echo 1 >/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode
    if [ "$1" == "0" ]; then
        echo '\_SB.PCI0.LPC0.EC0.VPC0.SBMC 0x05' |sudo tee /proc/acpi/call > /dev/null
    elif [ "$1" == "1" ]; then
        echo '\_SB.PCI0.LPC0.EC0.VPC0.SBMC 0x03' |sudo tee /proc/acpi/call > /dev/null
    else
        echo 'please input 0/1'
        exit 1
    fi
}

toggle_rapidcharge() {
    if [ "$1" = "0" ]; then
        echo '\_SB.PCI0.LPC0.EC0.VPC0.SBMC 0x08' |sudo tee /proc/acpi/call > /dev/null
    elif [ "$1" = "1" ]; then
        echo '\_SB.PCI0.LPC0.EC0.VPC0.SBMC 0x07' |sudo tee /proc/acpi/call > /dev/null
    else
        echo 'please input 0/1'
        exit 1
    fi
}

toggle_fan() {
    tmp=$(cat "/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/fan_mode")
    case "$tmp" in
    133)
        echo 1 |sudo tee cat /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/fan_mode > /dev/null
        ;;
    35)
        echo 2 |sudo tee cat /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/fan_mode > /dev/null    
        ;;
    esac
}

switch_mode() {
    case "$1" in
    1)
        echo '\_SB.PCI0.LPC0.EC0.VPC0.DYTC 0x0013B001' |sudo tee /proc/acpi/call > /dev/null
        ;;
    2)
        echo '\_SB.PCI0.LPC0.EC0.VPC0.DYTC 0x000FB001' |sudo tee /proc/acpi/call > /dev/null
        ;;
    3)
        echo '\_SB.PCI0.LPC0.EC0.VPC0.DYTC 0x0012B001' |sudo tee /proc/acpi/call > /dev/null
        ;;
    *)
        echo "Mode [$1] is invalid!" >&2
        echo "
        Options :
            1 - Battery Saving, 2 - Intelligent Cooling, 3 - Extreme Performance
        "
        exit 1
        ;;
    esac
}

switch_govern() {
    # /sys/devices/system/cpu/cpu[0-9]*
    case "$1" in
    "schedutil")
        echo 'schedutil' |sudo tee /sys/devices/system/cpu/cpu{0..11}/cpufreq/scaling_governor > /dev/null
        ;;
    "performance")
        echo 'performance' |sudo tee /sys/devices/system/cpu/cpu{0..11}/cpufreq/scaling_governor > /dev/null
        ;;
    "powersave")
        echo 'powersave' |sudo tee /sys/devices/system/cpu/cpu{0..11}/cpufreq/scaling_governor > /dev/null
        ;;
    *)
        echo "Govern [ $1 ] is invalid!" >&2
        echo "
        Options :
            schedutil, powersave, performance, ondemand
        "
        exit 1
        ;;
    esac
}

use_preset() {
    case "$1" in
    1)
        switch_mode "1"
        switch_govern "powersave"
        ;;
    2)
        switch_mode "2"
        switch_govern "schedutil"
        ;;
    3)
        switch_mode "3"
        switch_govern "schedutil"
        ;;
    *)
        echo "Preset [ $1 ] is invalid!" >&2
        echo "
        Options :
            1 - Powersave, 2 - banance, 3 - Performance
        "
        exit 1
        ;;
    esac
}

get_batteryconserve() {
    echo '\_SB.PCI0.LPC0.EC0.BTSG' |sudo tee /proc/acpi/call > /dev/null
    btsg=$(sudo cat /proc/acpi/call | cut -d '' -f1)

    if [ "$btsg" = 0x0 ]; then
        batteryconserve="Off"
    elif [ "$btsg" = 0x1 ]; then
        batteryconserve="On"
    fi
}

get_rapidcharge() {
    echo '\_SB.PCI0.LPC0.EC0.FCGM' |sudo tee /proc/acpi/call > /dev/null
    fcgm=$(sudo cat /proc/acpi/call | cut -d '' -f1)

    if [ "$fcgm" = 0x0 ]; then
        rapidcharge="Off"
    elif [ "$fcgm" = 0x1 ]; then
        rapidcharge="On"
    fi
}

get_mode() {
    echo '\_SB.PCI0.LPC0.EC0.STMD' |sudo tee /proc/acpi/call > /dev/null
    stmd=$(sudo cat /proc/acpi/call | cut -d '' -f1)

    echo '\_SB.PCI0.LPC0.EC0.QTMD' |sudo tee /proc/acpi/call > /dev/null
    qtmd=$(sudo cat /proc/acpi/call | cut -d '' -f1)

    # echo 'qtmd:' "$qtmd" 'stmd:' "$stmd"

    if [ "$qtmd" = 0x0 ] && [ "$stmd" = 0x0 ]; then
        mode="Extreme Performance"
    elif [ "$qtmd" = 0x1 ] && [ "$stmd" = 0x0 ]; then
        mode="Battery Saving"
    elif [ "$qtmd" = 0x0 ] && [ "$stmd" = 0x1 ]; then
        mode="Intelligent Cooling"
    fi
}

get_governor() {
    cpugovernor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
}

display_info() {
    get_rapidcharge
    get_batteryconserve
    get_mode
    get_governor

    echo "
    Performance Mode     : $mode
    Cpu governor         : $cpugovernor
    Battery Conservation : $batteryconserve
    Rapid Charge         : $rapidcharge
    "
}

usage() {
    echo "
  Usage:
    powercontrol [OPTIONS]
  Options:
    -i, --info              Display current power mode and battery status
    -r, --rapid-charge      Toggle Rapid Charge 0/1
    -c, --battery-conserve  Toggle Battery Conservation 0/1 (Doesn't charge >60%)
    -m, --mode [value]      Switch power mode, values:
                              1 - Battery Saving, 2 - Intelligent Cooling, 3 - Extreme Performance
    -g, --govern [value]    Switch cpu governor, values:
                              schedutil, performance, powersave, ondemand, conservative
    -p, --preset [value]    Use mode and govern configure in advance, values:
                              1 - Powersave, 2 - banance, 3 - Performance
    -h, --help              View this help page
"
}

# ------------------
#
# PowerControl start
#
# ------------------

# Load acpi_call module ( apt install acpi )
# if ! modprobe acpi_call; then
#     echo "Error: acpi_call module could not be loaded!" >&2
#     exit 1
# fi

# Display usage if no args are supplied
if [ -z "$1" ]; then
    usage
    exit 1
fi

display=0
# Handle arguments
while [[ -n "$1" ]]; do
    case "$1" in
    -i | --info)
        display_info
        display=1
        shift
        ;;
    -r | --rapid-charge)
        toggle_rapidcharge "$2"
        shift 2
        ;;
    -c | --battery-conserve)
        toggle_batteryconserve "$2"
        shift 2
        ;;
    -f | --fan)
        toggle_fan
        shift
        ;;
    -m | --mode)
        switch_mode "$2"
        shift 2
        ;;
    -g | --govern)
        switch_govern "$2"
        shift 2
        ;;
    -p | --preset)
        use_preset "$2"
        shift 2
        ;;
    -h | --help)
        usage
        exit 0
        ;;
    *)
        echo "$1 is an invalid command!"
        usage
        exit 1
        ;;
    esac
done

if [[ "$display" == "0" ]];then
    display_info
fi

exit 0