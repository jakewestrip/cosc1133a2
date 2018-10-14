#!/bin/bash

# BackgroundWorker.sh

# A bash script which is made to be run in the background after being spawned
#  by LedConfigurator.sh. Monitors either the CPU or Memory usage of a given
#  process and turns a given LED on and off accordingly.
# Should be called with parameters: -p {processName} -t {monitorType} -l {attachedLed}

# Global variables:

# processName: stores the process to monitor
processName="./BackgroundWorker.sh"
# monitorType: stores which resource to monitor usage of (CPU or Memory)
monitorType=""
# attachedLed: stores the LED with which to associate resource usage
attachedLed=""

# The 3 above variables are passed through to this script by the caller as
#  parameters and consumed in this script using getopts.

while getopts ":p:t:l:" opt
do
    case $opt in
        p)
            processName=$OPTARG
            ;;
        t)
            monitorType=$OPTARG
            ;;
        l)
            attachedLed=$OPTARG
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done

# Check that the necessary parameters have been passed through and
# parsed and set correctly.

if [ -z ${processName+x} ];
then
    echo "Process name must be set with -p"
    exit 1
fi

if [ -z ${monitorType+x} ];
then
    echo "Monitoring type must be set with -t"
    exit 1
fi

if [ -z ${attachedLed+x} ];
then
    echo "Attached LED must be set with -l"
    exit 1
fi

# Loop forever (until this process is killed), monitoring the selected process and
#  setting on and off intervals for the attached LED accordingly. The awk program used
#  will take all of the results from the grep'd ps, select either the CPU or Memory
#  column and sum all of the lines, dividing the result by 100 before returning to the
#  on variable. This gives us the time in seconds to keep the LED on for in this
#  1 second cycle. We then use bc to perform the floating point calculations necessary
#  to find the time in seconds to keep the LED off in the cycle. Then perform the cycle
#  by turning the LED on, waiting for the on time, then turning the LED off and waiting
#  for the off time.
while true
do
    if [ "$monitorType" -eq 0 ]
    then
        on=$(ps -axco pcpu,command | grep -v grep | grep -i "$processName" | awk '{n += $1}; END{print n/100}')
    fi
    if [ "$monitorType" -eq 1 ]
    then
        on=$(ps -axco pmem,command | grep -v grep | grep -i "$processName" | awk '{n += $1}; END{print n/100}')
    fi

    if [ -z "$on" ]
    then
        on="0"
    fi

    off=$(echo 1-"$on" | bc) 

    if [ "$on" != "0" ]
    then
        echo 1 >/sys/class/leds/"$attachedLed"/brightness
        sleep "$on"
    fi

    echo 0 >/sys/class/leds/"$attachedLed"/brightness

    sleep "$off"
done