#!/bin/bash

# LedConfigurator.sh

# A bash script which allows a user to perform various functions with system
#  LEDs, including manually turning them on and off, associating them with
#  system events and associating them with the resource usage of a process
#  via a background worker process.

# Global variables:

# backgroundWorkerPath: keeps the path to the BackgroundWorker script
backgroundWorkerPath="./BackgroundWorker.sh"
# ledToManipulate: stores the currently selected LED
ledToManipulate=""
# eventToAssociate: stores the currently selected system event to associate
eventToAssociate=""
# procName: stores the currently selected process name to associate
procName=""

# mainMenu function
# Uses globals: ledToManipulate (write)
# Displays the LED selection menu and saves the selected LED
#  as global variable ledToManipulate, then calling the function
#  to display the LED manipulation menu.
mainMenu()
{
    clear

    # Reads available LEDS from /sys/class/leds/ and populates an array with these
    #  to build the menu.
    local availableLeds=()
    mapfile -t availableLeds < <(ls /sys/class/leds/)
    local menuItems=("${availableLeds[@]}")
    local menuItems+=("Quit")
    local menuItemNum=${#menuItems[@]}

    # Build menu, pipe all menu output through more
    (
    cat <<EOM
Welcome to LedConfigurator!
============================
Please select an LED to configure: 
EOM
    
    for ((i=1; i<=menuItemNum; i++))
    do
        echo $i\) "${menuItems[(($i-1))]}"
    done
    echo "Please enter a number (1-$menuItemNum) for the led to configure or quit:"
    ) | more

    local input
    read -r input

    # Check that input is a numeric character, restart function if invalid input
    if ! [[ $input =~ ^-?[0-9]+$ ]]
    then
        mainMenu
    fi

    # Exit script if the last option (Quit) was selected
    if [ "$input" -eq "$menuItemNum" ]
    then
        exit $?
    fi

    ledToManipulate=${menuItems[$input-1]}

    manipulateLED
}

# manipulateLED function
# Uses globals: ledToManipulate (read)
# Displays the menu for choosing which action to take with the
#  selected LED and calls the corresponding function (or returns
#  to main menu)
manipulateLED()
{
    clear

    # Build menu, pipe all menu output through more
    (
    cat <<EOM
$ledToManipulate
============================
What would you like to do with this LED? 
1) Turn on
2) Turn off
3) Associate with a system event
4) Associate with the performance of a process
5) Stop association with a process’ performance
6) Quit to main menu
Please enter a number (1-6) for your choice:
EOM
    ) | more

    local input
    read -r input

    # Check that input is a numeric character, restart function if invalid input
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

# turnOnLED function
# Uses globals: ledToManipulate (read)
# Turns on the selected LED by writing a 1 to the corresponding brightness file,
#  then returns to the LED manipulation menu.
turnOnLED()
{
    echo 1 >/sys/class/leds/"$ledToManipulate"/brightness
    manipulateLED
}

# turnOffLED function
# Uses globals: ledToManipulate (read)
# Turns off the selected LED by writing a 0 to the corresponding brightness file,
#  then returns to the LED manipulation menu.
turnOffLED()
{
    echo 0 >/sys/class/leds/"$ledToManipulate"/brightness
    manipulateLED
}

# associateWithSystemEvent function
# Uses globals: ledToManipulate (read), eventToAssociate (write)
# Gets the list of available system event triggers from the file corresponding to the
#  selected LED, then creates a menu to select one of these events and save the event
#  to the eventToAssociate global variable. Then calls the associateWithSystemEventAction
#  function.
associateWithSystemEvent()
{
    clear

    # Read available LEDS and populate array
    IFS=" "
    local availableEvents
    read -r -a availableEvents <<< "$(cat /sys/class/leds/"$ledToManipulate"/trigger)"
    local eventMenuitems=("${availableEvents[@]}")
    local eventMenuitems+=("Quit to previous menu")
    local eventNum=${#eventMenuitems[@]}

    # Build menu, pipe all menu output through more
    (
    cat <<EOM
Associate Led with a system Event
=================================
Available events are: 
---------------------
EOM
    for ((i=1; i<=eventNum; i++))
    do
        # Converts from [event] notation to event* notation
        echo $i: "$(echo "${eventMenuitems[(($i-1))]}" | sed -E "s|\[(.*)\]|\1\*|g")"
    done
    echo "Please select an option (1-$eventNum):"
    ) | more

    local input
    read -r input

    # Check that input is a numeric character, restart function if invalid input
    if ! [[ $input =~ ^-?[0-9]+$ ]]
    then
        associateWithSystemEvent
        return
    fi

    # Drop back to LED manipulation menu if the last option (Quit to previous menu)
    #  was selected
    if [ "$input" -eq "$eventNum" ]
    then
        manipulateLED
        return
    fi

    # Save chosen event to global variable and continue to associateWithSystemEventAction
    eventToAssociate=${eventMenuitems[$input-1]}
    associateWithSystemEventAction
}

# associateWithSystemEventAction function
# Uses globals: ledToManipulate (read), eventToAssociate (read)
# Associates the selected LED with the selected system event by writing
#  the system event name to the LEDs trigger file.
associateWithSystemEventAction()
{
    echo "$eventToAssociate" >/sys/class/leds/"$ledToManipulate"/trigger
    manipulateLED
}

# associateWithProcess function
# Uses globals: procName (write)
# Allows the user to input the name of the process to associate the LED to.
#  Checks ps to see how many running process names match, if none then display
#  an error message and return, if 1 then continue, if multiple then call the
#  chooseProcess function to select 1 process. Then continues to call the
#  pickAssociation function.
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
    procNum=$(ps -axco command | grep -v grep | grep -i "$procName" | sort -u | wc -l)

    if [ "$procNum" -eq 1 ]
    then
        procName=$(ps -axco command | grep -v grep | grep -i "$procName" | sort -u)
    fi
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

# chooseProcess function
# Uses globals: procName (read, write)
# Upon name conflict in process input of associateWithProcess function,
#  this function is called to list all the matching processes and allow the
#  user to pick one to associate the LED with. Returns to associateWithProcess.
chooseProcess()
{
    clear

    local procs=()
    mapfile -t procs < <(ps -axco command | grep -v grep | grep -i "$procName" | sort -u)
    local procMenuitems=("${procs[@]}")
    local procMenuitems+=("Quit to previous menu")
    local procNum=${#procMenuitems[@]}

    # Build menu, pipe all menu output through more
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

    # Check that input is a numeric character, restart function if invalid input
    if ! [[ $input =~ ^-?[0-9]+$ ]]
    then
        chooseProcess
        return
    fi

    # Drop back to LED manipulation menu if the last option (Quit to previous menu)
    #  was selected
    if [ "$input" -eq "$procNum" ]
    then
        manipulateLED
    fi

    procName=${procMenuitems[$input-1]}
}

# pickAssociation function
# Uses globals: backgroundWorkerPath(read), ledToManipulate (read), procName (read)
# Allows the user to select which process property to associate the selected LED
#  with, between CPU monitoring and Memory usage monitoring. Kills any currently
#  running background worker, then spawns a new background worker process, passing
#  through the process name, monitoring type and selected LED as params to be
#  consumed with getopts. Then returns to the LED manipulation menu.
pickAssociation()
{
    clear

    echo "Do you wish to 1) monitor memory or 2) monitor cpu? [enter memory or cpu]:"
    local monitorType
    read -r monitorType

    # Check that input is valid, restart function if invalid input
    if [[ "$monitorType" != "memory" && "$monitorType" != "cpu" && "$monitorType" != "1" && "$monitorType" != "2" ]]
    then
        pickAssociation
        return
    fi

    killBackgroundProcess

    # Use nohup and output redirection to make sure that the process will continue even
    #  after the current terminal is closed.
    if [[ "$monitorType" == "memory" || "$monitorType" == "1" ]]
    then
        nohup "$backgroundWorkerPath" -p "$procName" -t "1" -l "$ledToManipulate" &>/dev/null &
    fi
    if [[ "$monitorType" == "cpu" || "$monitorType" == "2" ]]
    then
        nohup "$backgroundWorkerPath" -p "$procName" -t "0" -l "$ledToManipulate" &>/dev/null &
    fi

    manipulateLED
}

# killBackgroundProcess function
# Uses no globals
# Kills any running background worker processes by searching running processes
#  for BackgroundWorker and sending SIGKILL to them.
killBackgroundProcess()
{
    local pid
    pid=$(ps -ax | grep -v grep | grep BackgroundWorker | awk '{print $1}')
    if [ "$pid" != "" ]
    then
        disown "$pid"
        kill -s SIGKILL "$pid"
    fi
}

mainMenu

exit $?