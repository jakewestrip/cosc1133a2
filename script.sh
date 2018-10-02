#!/bin/bash

#backgroundMonitorFunction(string processName, int monitorType) where monitorType = 0 for CPU and 1 for memory
backgroundMonitorFunction()
{
    processName=$1
    monitorType=$2
    while true
    do
        if [ "$monitorType" -eq 0 ]
        then
            echo "I'm monitoring the CPU of $processName"
        fi
        if [ "$monitorType" -eq 1 ]
        then
            echo "I'm monitoring the Memory of $processName"
        fi
        sleep 10
    done
}

mainMenu()
{
    clear
    mapfile -t availableLeds < <(ls /sys/class/leds/)
    menuitems=("${availableLeds[@]}")
    menuitems+=("Quit")
    num=${#menuitems[@]}

    (
    cat <<EOM
Welcome to Led_Konfigurator!
============================
Please select an LED to configure: 
EOM
    
    for ((i=1; i<=num; i++))
    do
        echo $i\) "${menuitems[(($i-1))]}"
    done
    echo "Please enter a number (1-$num) for the led to configure or quit:"
    ) | more

    read -r input
    if [ "$input" -eq "$num" ]
    then
        exit $?
    fi

    ledtomanipulate=${menuitems[$input-1]}

    manipulateLED
}

manipulateLED()
{
    clear
    (
    cat <<EOM
$ledtomanipulate
============================
What would you like to do with this led? 
1) turn on
2) turn off
3) associate with a system event
4) associate with the performance of a process
5) stop association with a process’ performance
6) quit to main menu
Please enter a number (1-6) for your choice:
EOM
    ) | more

    #Unsure about brackets after numbers, doesn't fit style of mainMenu()
    #SANITIZE INPUT, LETTERS SHOULDN'T KILL THE SCRIPT
    #also handle input better overall

    read -r input
    if [ "$input" -eq 1 ]
    then
        turnOnLED
    fi
    if [ "$input" -eq 2 ]
    then
        turnOffLED
    fi
    if [ "$input" -eq 3 ]
    then
        associateWithSystemEvent
    fi
    if [ "$input" -eq 4 ]
    then
        associateWithProcess
    fi
    if [ "$input" -eq 6 ]
    then
        mainMenu
    fi
}

turnOnLED()
{
    echo 1 >/sys/class/leds/"$ledtomanipulate"/brightness
    manipulateLED
}

turnOffLED()
{
    echo 0 >/sys/class/leds/"$ledtomanipulate"/brightness
    manipulateLED
}

associateWithSystemEvent()
{
    clear

    IFS=" "
    read -r -a availableEvents <<< "$(cat /sys/class/leds/"$ledtomanipulate"/trigger)"
    eventMenuitems=("${availableEvents[@]}")
    eventMenuitems+=("Quit to previous menu")
    eventNum=${#eventMenuitems[@]}

    (
    cat <<EOM
Associate Led with a system Event
=================================
Available events are: 
---------------------
EOM
    for ((i=1; i<=eventNum; i++))
    do
        echo $i: "${eventMenuitems[(($i-1))]}"
    done
    echo "Please select an option (1-$eventNum):"
    ) | more

    read -r input
    if [ "$input" -eq "$eventNum" ]
    then
        manipulateLED
    fi

    eventToAssociate=${eventMenuitems[$input-1]}
    associateWithSystemEventAction
}

associateWithSystemEventAction()
{
    echo "$eventToAssociate" >/sys/class/leds/"$ledtomanipulate"/trigger
    manipulateLED
}

associateWithProcess()
{
    clear
    cat <<EOM
Associate LED with the performance of a process
------------------------------------------------
Please enter the name of the program to monitor(partial names are ok):
EOM

    read -r procName
    procNum=$(pgrep -c "$procName")
    echo "$procNum"

    if [ "$procNum" -eq 0 ]
    then
        echo "BAD BAD NOT GOOD"
    fi
    if [ "$procNum" -gt 1 ]
    then
        chooseProcess
    fi

    pickAssociation
}

chooseProcess()
{
    clear

    cat <<EOM
Name Conflict
-------------
I have detected a name conflict. Do you want to monitor: 
EOM

    read -r
}

pickAssociation()
{
    clear

    echo "Do you wish to 1) monitor memory or 2) monitor cpu? [enter memory or cpu]:"
    read -r monitorType

    if [ "$monitorType" == "memory" ]
    then
        (backgroundMonitorFunction "$procName" "1") &
    fi
    if [ "$monitorType" == "cpu" ]
    then
        (backgroundMonitorFunction "$procName" "0") &
    fi

    manipulateLED
}

mainMenu

exit $?