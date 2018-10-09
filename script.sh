#!/bin/bash

mainMenu()
{
    clear
    local availableLeds=()
    mapfile -t availableLeds < <(ls /sys/class/leds/)
    local menuitems=("${availableLeds[@]}")
    local menuitems+=("Quit")
    local num=${#menuitems[@]}

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

    local input
    read -r input

    if ! [[ $input =~ ^-?[0-9]+$ ]]
    then
        mainMenu
    fi

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

    #SANITIZE INPUT, LETTERS SHOULDN'T KILL THE SCRIPT
    #also handle input better overall

    local input
    read -r input

    if ! [[ $input =~ ^-?[0-9]+$ ]]
    then
        manipulateLED
        return
    fi

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
    if [ "$input" -eq 5 ]
    then
        killBackgroundProcess
        manipulateLED
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
    local availableEvents
    read -r -a availableEvents <<< "$(cat /sys/class/leds/"$ledtomanipulate"/trigger)"
    local eventMenuitems=("${availableEvents[@]}")
    local eventMenuitems+=("Quit to previous menu")
    local eventNum=${#eventMenuitems[@]}

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

    local input
    read -r input

    if ! [[ $input =~ ^-?[0-9]+$ ]]
    then
        associateWithSystemEvent
        return
    fi

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
    local procNum
    procNum=$(ps -axco command | grep -v grep | grep "$procName" | sort -u | wc -l)

    if [ "$procNum" -eq 0 ]
    then
        clear
        echo "No process was found with with the name $procName. Press any key to return to LED Manipulation menu."
        read -r
        manipulateLED
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

    local procs=()
    mapfile -t procs < <(ps -axco command | grep -v grep | grep ch | sort -u)
    local procMenuitems=("${procs[@]}")
    local procMenuitems+=("Quit to previous menu")
    local procNum=${#procMenuitems[@]}

    (
    cat <<EOM
Name Conflict
-------------
I have detected a name conflict. Do you want to monitor: 
EOM

    for ((i=1; i<=procNum; i++))
    do
        echo $i: "${procMenuitems[(($i-1))]}"
    done
    echo "Please select an option (1-$procNum):"
    ) | more

    local input
    read -r input

    if ! [[ $input =~ ^-?[0-9]+$ ]]
    then
        chooseProcess
        return
    fi

    if [ "$input" -eq "$procNum" ]
    then
        manipulateLED
    fi

    procName=${procMenuitems[$input-1]}
}

pickAssociation()
{
    clear

    echo "Do you wish to 1) monitor memory or 2) monitor cpu? [enter memory or cpu]:"
    local monitorType
    read -r monitorType

    echo $monitorType
    if [ "$monitorType" != "memory" -a "$monitorType" != "cpu" ]
    then
        pickAssociation
        return
    fi

    killBackgroundProcess

    if [ "$monitorType" == "memory" ]
    then
        ./backgroundWorker.sh -p "$procName" -t "1" -l "$ledtomanipulate" &
    fi
    if [ "$monitorType" == "cpu" ]
    then
        ./backgroundWorker.sh -p "$procName" -t "0" -l "$ledtomanipulate" &
    fi

    manipulateLED
}

killBackgroundProcess()
{
    local pid
    pid=$(ps -ax | grep -v grep | grep backgroundWorker | awk '{print $1}')
    if [ "$pid" != "" ]
    then
        kill "$pid"
    fi
}

mainMenu

exit $?