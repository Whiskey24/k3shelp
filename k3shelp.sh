#!/bin/bash

# Define kubectl command
KUBECTL=(k3s kubectl)

RED='\033[0;31m'
CYAN='\033[0;36m'
LGRN='\033[0;32m'
NCLR='\033[0m' # No Color


# Check if we're running as root
if [ "$EUID" -ne 0 ]
    then echo "This script needs to run as root"
    exit
fi

# Define parameters to use to find podnamespaces and names
KUBEPODLIST=("${KUBECTL[@]}")
KUBEPODLIST+=(get pods --all-namespaces)

# Run the command and store results in an array
readarray -t PODLIST < <("${KUBEPODLIST[@]}")

#IFS=$'\n' PODLIST=($(sort <<<"${PODLIST[*]}"))
#unset IFS
readarray -t PODLIST < <(for a in "${PODLIST[@]}"; do echo "$a"; done | sort)


# get length of the array
LENGTH=${#PODLIST[@]}

# function to show list with options to user
showpods(){
    for (( j=0; j<$LENGTH; j++ ));
    do
        if [ $j -eq 0 ]
             then printf "  \t%s\n" "${PODLIST[$j]}"
             else printf "%d\t%s\n" $j "${PODLIST[$j]}"
        fi
    done
}

# function to ask for selection, validate input
choosepod(){
    until [ $_GOODINPUT ]; do
        printf "${CYAN}Please select a pod:${NCLR} "
        read INPUT

        if [[ -n ${INPUT//[0-9]/} ]]; then
            printf "${RED}Choose between 1 and %d, no letters allowed!${NCLR}\n" "$(($j-1))"
        elif (( $INPUT == 0 )); then
            printf "${RED}Choose between 1 and %d, 0 is not an option!${NCLR}\n" "$(($j-1))"
        elif (( $INPUT >= $LENGTH )); then
            printf "${RED}Choose between 1 and %d, %d is not an option!${NCLR}\n" "$(($j-1))" $INPUT
        else
            _GOODINPUT=1
        fi
    done
    unset _GOODINPUT
    
    PODNAME=$(printf "%s\n" "${PODLIST[$INPUT]}" | awk '{print $2}')
    NAMESPACE=$(printf "%s\n" "${PODLIST[$INPUT]}" | awk '{print $1}')
}

# function to ask for log tail or command shell
chooseoption(){
    until [ $_GOODINPUT ]; do
        printf "1 Log tail\n"
        printf "2 Command shell\n"
        printf "0 Choose different pod${NCLR}\n"
        printf "${CYAN}Start log tail or open a command shell: ${NCLR}"
        read INPUT

        if [[ "$INPUT" != [0-2] ]]; then
            printf "${RED}Choose 1 or 2, no other options allowed!${NCLR}\n"
        
        else
            _GOODINPUT=1
        fi
    done
    unset _GOODINPUT
}

logtail(){
    # Define parameters to use to tail a log
    KUBETAIL=("${KUBECTL[@]}" "logs" "${PODNAME}" "-n ${NAMESPACE}" "-f")
    STRCMD="${KUBETAIL[@]}"
    eval $STRCMD   
}

openshell(){
    # Define parameters to use to tail a log
    KUBESHELL=("${KUBECTL[@]}" "exec -it" "${PODNAME}" "-n ${NAMESPACE}" "-- /bin/bash")
    STRCMD="${KUBESHELL[@]}"
    clear
    eval $STRCMD
}

until [ $_CHOICEMADE ]; do
    showpods
    choosepod
    printf "${CYAN}Selected ${LGRN}%s${CYAN} in namespace ${LGRN}%s${NCLR}\n" "$PODNAME" "$NAMESPACE"
    chooseoption
    if [[ "$INPUT" != [0] ]]; then
        _CHOICEMADE=1
    fi
done
unset $_CHOICEMADE

if [[ "$INPUT" == 1 ]]; then
    logtail
elif [[ "$INPUT" == 2 ]]; then
    openshell
else
    printf "Nothing to do"
fi
