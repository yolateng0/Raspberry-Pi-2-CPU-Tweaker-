#!/bin/bash
clear
function control_c (){
echo -en "\n[i]Caught ctrl-c \n"
exit 0
}
trap control_c SIGINT
# Smart_RaspiCPUtweak - for Raspberry Pi 2
# View Raspberry Pi 2 B CPU Info - Clock speed - Temperatures - Voltage - Overclock you RPi - Change Governor & more
# Run script with sudo raspberrypicputweak.sh
# Warning: by using this software (script), you understand that I can't be held
# responsible for anything that may happen. If you OC you RPi, I recommend using heatsinks!!!

#### COLOR SETTINGS ####
BLACK=$(tput setaf 0 && tput bold)
RED=$(tput setaf 1 && tput bold)
GREEN=$(tput setaf 2 && tput bold)
YELLOW=$(tput setaf 3 && tput bold)
BLUE=$(tput setaf 4 && tput bold)
MAGENTA=$(tput setaf 5 && tput bold)
CYAN=$(tput setaf 6 && tput bold)
WHITE=$(tput setaf 7 && tput bold)
BLACKbg=$(tput setab 0 && tput bold)
REDbg=$(tput setab 1 && tput bold)
GREENbg=$(tput setab 2 && tput bold)
YELLOWbg=$(tput setab 3 && tput bold)
BLUEbg=$(tput setab 4 && tput dim)
MAGENTAbg=$(tput setab 5 && tput bold)
CYANbg=$(tput setab 6 && tput bold)
WHITEbg=$(tput setab 7 && tput bold)
STAND=$(tput sgr0)

version="12/30/2015"
unixtime=$(date --date="$version" +"%s")
time=$(date +"%T")

### Resize current window
function resizewindow(){
echo $WHITE" Resizing window to$GREEN 24x90"$STAND
resize -s 24 90 1> /dev/null
sleep 2;
}

#### ROOT User Check
function checkroot(){
	if [[ $(id -u) = 0 ]]; then
		echo -e $WHITE" Checking for ROOT:$GREEN PASSED" $STAND
		else
		echo -e $WHITE" Checking for ROOT:$RED FAILED
 This Script Needs To Run As$RED ROOT (sudo)" $STAND
		echo ""
		echo -e $WHITE" RaspiCPUtweak will now Exit"
		echo
		sleep 1
		exit
	fi
}


function sversion(){
echo $WHITE" Script version:$GREEN $version"$STAND
}

#### pause function
function pause(){
	local message="$@"
	[ -z $message ] && message=$STAND"Press [Enter] key to continue..."
	read -p "$message" readEnterKey
}

#### Dependencies check

function checkdependencies(){
####################################################################################
#                Path to installations			                           #
####################################################################################
findxterm="/lib/terminfo/x/xterm"    # installation path to xterm (for resize cmd) #
findvcgencmd="/opt/vc/bin/vcgencmd" # installation path to vcgencmd                #
####################################################################################

# -------------------------------------------
# Check for installed dependencies
# -------------------------------------------

#### check if xterm installation exists
if [ -e $findxterm ];
then

echo $BLUE" [ok][xterm]:$WHITE installation found..."

else

   echo $RED" [!][warning]:this script requires xterm installed to work"
   echo $GREEN" [i]Downloading from network..." $STAND
   sleep 3;
      apt-get install -y xterm
fi
sleep 1;
####

#### check if vcgencmd installation exists
if [ -e $findvcgencmd ]; 
then

echo $BLUE" [ok][vcgencmd]:$WHITE installation found..."

else

   echo $RED" [!][warning]:this script requires vcgencmd installed to work"
   echo $GREEN" [i]Downloading from network..." $STAND
   sleep 3;
      sudo apt-get update && sudo apt-get upgrade && sudo apt-get dist-upgrade
fi
sleep 1;
####

echo $WHITE" All ok.."
}
resizewindow && checkroot && sversion && checkdependencies && sleep 2
###


### Check Frequency, Temp, Voltage, Governor
function freqtempvolt() {
clear
function mhz_convert() {
    let value=$1/1000
    echo "$value"
}

function overvoltdecimals() {
    let overvolts=${1#*.}-20
    echo "$overvolts"
}

temp=$(vcgencmd measure_temp)
temp=${temp:5:4}

volts=$(vcgencmd measure_volts)
volts=${volts:5:4}

if [ $volts != "1.20" ]; then
    overvolts=$(overvoltdecimals $volts)
fi

minFreq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq)
minFreq=$(mhz_convert $minFreq)
maxFreq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq)
maxFreq=$(mhz_convert $maxFreq)
freq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq)
freq=$(mhz_convert $freq)
governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
transitionlatency=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_transition_latency)


	if [ $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor) == ondemand ]; then
			samplingrate=$(cat /sys/devices/system/cpu/cpufreq/ondemand/sampling_rate)
			samplingratemin=$(cat /sys/devices/system/cpu/cpufreq/ondemand/sampling_rate_min)
			upthreshold=$(cat /sys/devices/system/cpu/cpufreq/ondemand/up_threshold)
		echo ""
		echo "+------------------------------------+"
		echo "Temperature:        $temp C"
			if [ $volts == "1.20" ]; then
				echo "Voltage:            $volts V"
			else
				echo -n "Voltage:            $volts V"
				[ $overvolts ] && echo " (+0.$overvolts overvolt)" || echo -e "\n"
			fi
		echo "Min speed:          $minFreq MHz"
		echo "Max speed:          $maxFreq MHz"
		echo "Current speed:      $freq MHz"
		echo "Governor:           $governor"
		echo "Sampling rate:      $samplingrate"
		echo "Sampling rate MIN:  $samplingratemin"
		echo "Up threshold:       $upthreshold"
		echo "Transition latency: $transitionlatency"
		echo "+------------------------------------+"
	else
		echo ""
		echo "+------------------------------------+"
		echo "Temperature:        $temp C"
			if [ $volts == "1.20" ]; then
				echo "Voltage:            $volts V"
			else
				echo -n "Voltage:            $volts V"
				[ $overvolts ] && echo " (+0.$overvolts overvolt)" || echo -e "\n"
			fi
		echo "Min speed:          $minFreq MHz"
		echo "Max speed:          $maxFreq MHz"
		echo "Current speed:      $freq MHz"
		echo "Governor:           $governor"
		echo "Transition latency: $transitionlatency"
		echo "+------------------------------------+"
	fi

	pause
}

### Change GOVERNOR settings
function changegovernor(){
clear && echo ""
affected_cpus=$(cat /sys/devices/system/cpu/cpu0/cpufreq/affected_cpus)
available_governors=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors)
current_governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)

echo "Current CPU governor is:$GREEN $current_governor"$STAND
echo "Affected cpus:$GREEN $affected_cpus"$STAND
echo "Available CPU governors:$RED $available_governors"$STAND
echo "If you'd like to abort, write abort then press enter :)"
read -p "Enter desired governor: " ch_governor
echo ""


if [ $ch_governor == abort ]; then
echo "Going back to main menu." && sleep 2
else
sudo sh -c "echo $ch_governor > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"
echo "Governor changed to:$RED $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)"$STAND
echo ""

	if [ $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor) == ondemand ]; then
		echo "Ondemand governor set. You can change sampling_rate and up_threshold for better performance."
		echo "Current sampling_rate=$GREEN $(cat /sys/devices/system/cpu/cpufreq/ondemand/sampling_rate)"$STAND
		#read -p "Enter new sampling_rate value: " sampling_rate
		#sudo sh -c "echo $sampling_rate > /sys/devices/system/cpu/cpufreq/ondemand/sampling_rate"
		#echo "sampling_rate changed to:$RED $(cat /sys/devices/system/cpu/cpufreq/ondemand/sampling_rate)"$STAND

		echo "According to Kernel Documentation, sampling_rate should get adjusted considering the transition latency."
		echo "The default model looks like this: cpuinfo_transition_latency * 1000 / 1000 = sampling_rate"

		echo "The next operation will do this for you. For example, we can choose 750"
		read -p "Enter value: " sampling_rate_value
		sudo sh -c "echo $(($(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_transition_latency) * $sampling_rate_value / 1000)) > /sys/devices/system/cpu/cpufreq/ondemand/sampling_rate"
		echo "sampling_rate changed to:$RED $(cat /sys/devices/system/cpu/cpufreq/ondemand/sampling_rate)"$STAND

		echo "Current up_threshold=$GREEN $(cat /sys/devices/system/cpu/cpufreq/ondemand/up_threshold)"$STAND
		echo ""
		read -p "Enter new up_threshold value: " up_threshold
		sudo sh -c "echo $up_threshold > /sys/devices/system/cpu/cpufreq/ondemand/up_threshold"
		echo "up_threshold changed to:$RED $(cat /sys/devices/system/cpu/cpufreq/ondemand/up_threshold)"$STAND
		echo "" && pause
	else
		echo "" && pause
	fi
fi
}

### Overclocking settings
function rpioverclock() {
clear
read -p "Write$GREEN overclock$STAND to continue or$RED abort$STAND to cancel: " oc_accept
	if [ $oc_accept == overclock ]; then
		echo "Creating backup for config.txt in /boot"
		echo "You will have an option to post-edit/review your config.txt and add personal settings before restarting."
	sleep 1
		sudo cp /boot/config.txt /boot/config.txt.raspicputweak-backup
		sudo echo "hdmi_force_hotplug=1
arm_freq=1000
core_freq=450
sdram_freq=450
over_voltage=6" > /boot/config.txt

		echo "Mods written."
		echo "Please review mods..." && sleep 1
		sudo nano /boot/config.txt
		echo "All ok."
		echo "" && pause
	else
		echo "" && echo "Going back to main menu." && sleep 1
		#rpioverclock
	fi
}

#### Exit RaspiCPUtweak
function exitcputweak () {
  echo -e $WHITE"Bye bye! @-@"$STAND
  exit 0
}

#### Infinite Loop To Show Menu Until Exit
while :
do
clear
echo $YELLOW"+------------------------------+"
echo "|Raspberry Pi 2 CPU Tweaker    | 
|Script version: $version    |
echo "+------------------------------+"$STAND
echo $WHITE"+------------------------------+"
echo $WHITE"| 1. Show CPU details          |"
echo $WHITE"| 2. Change CPU Govenor        |"
echo $WHITE"| 3.$RED Overclock$WHITE                 |"
echo $WHITE"| 4. Smart_RPiCPUtweak Updates |"
echo $WHITE"| 5. EXIT                      |"
echo $WHITE"+------------------------------+"
echo $STAND""
echo -en $MAGENTA"Choose An Option: "$STAND
read menuoption
case $menuoption in
1) freqtempvolt ;;
2) changegovernor ;;
3) rpioverclock ;;
4) raspitweakchangelog ;;
5) exitcputweak ;;
*) echo $RED" \"$menuoption\" Is not a valid option!"; echo $STAND""; sleep 1; clear ;;
esac
done


#End


