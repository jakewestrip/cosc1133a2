#!/bin/bash
#backgroundMonitorFunction(string processName, int monitorType) where monitorType = 0 for CPU and 1 for memory

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

while true
do
    if [ "$monitorType" -eq 0 ]
    then
        on=$(ps -aux | grep -v grep | grep chromium | awk '{n += $3}; END{print n/100}')
    fi
    if [ "$monitorType" -eq 1 ]
    then
        on=$(ps -aux | grep -v grep | grep chromium | awk '{n += $4}; END{print n/100}')
    fi

    off=$(echo 1-$on | bc) 

    echo 1 >/sys/class/leds/"$attachedLed"/brightness

    sleep "$on"

    echo 0 >/sys/class/leds/"$attachedLed"/brightness

    sleep "$off"
done