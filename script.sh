#!/bin/bash

mainMenu()
{
    clear
    availableleds=(`ls /sys/class/leds/`)
    menuitems=("${availableleds[@]}")
    menuitems+=("Quit")
    num=${#menuitems[@]}
    quitindex=$num

    cat <<EOM
Welcome to Led_Konfigurator!
============================
Please select an LED to configure: 
EOM
    
    for ((i=1; i<=$num; i++))
    do
        echo $i: ${menuitems[(($i-1))]}
    done
    echo "Please enter a number (1-$num) for the led to configure or quit:"

    read input
    if [ $input -eq $num ]
    then
        exit $?
    fi

    ledtomanipulate=${menuitems[$input-1]}

    manipulateLED
}

manipulateLED()
{
    clear
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

    read input
    if [ $input -eq 1 ]
    then
        turnOnLED
    fi
    if [ $input -eq 2 ]
    then
        turnOffLED
    fi
    if [ $input -eq 6 ]
    then
        mainMenu
    fi
}

turnOnLED()
{
    echo 1 >/sys/class/leds/$ledtomanipulate/brightness
    manipulateLED
}

turnOffLED()
{
    echo 0 >/sys/class/leds/$ledtomanipulate/brightness
    manipulateLED
}

mainMenu

exit $?