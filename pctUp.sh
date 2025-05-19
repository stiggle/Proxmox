#!/bin/bash
# Loop through all the configured LXC Containers
# Detect if they are running
# Run the configured linux versions updates 

function pctDebian {
# apt based systems 

    inID=$1

    /usr/sbin/pct exec $inID -- apt update
    /usr/sbin/pct exec $inID -- apt -y dist-upgrade
    /usr/sbin/pct exec $inID -- apt -y autoremove
}

function pctFedora {
# yum based systems

    inID=$1

    /usr/sbin/pct exec $inID -- yum -y update
    /usr/sbin/pct exec $inID -- yum -y autoremove 
}

function pctSuse {
# zypper/yast based systems

    inID=$1

    /usr/sbin/pct exec $inID -- zypper -n dist-upgrade
}

function pctArch {
# Pacman based systems

    inID=$1

    /usr/sbin/pct exec $inID -- pacman -Syu
}

function pctUnknown {
# Unknown system - unable to update

    inID=$1

    echo "LXC Container $inID is an unknown type and needs to be updated manually."
}

function pctUpdate {
# Check the /etc/os-release file for the LXC OS Type

    inID=$1

# First check the ID_LIKE field
    inLIKE=`/usr/sbin/pct exec $inID -- grep ID_LIKE /etc/os-release | cut -c9- | sed -e 's/\"//g' | sed -e 's/rhel //g'`

# If there is no content for ID_LIKE, check the ID field
    if [ "$inLIKE" = "" ]; then
        inLIKE=`/usr/sbin/pct exec 101 -- grep ID= /etc/os-release | grep -v _ID= | cut -c4- | sed -e '/\"//g'` 
    fi

# Run the OS specific update
    case $inLIKE in
       "debian" | "ubuntu" )
           pctDebian $inID ;;
       "rhel" | "fedora" | "centos" | "ol" )
           pctFedora $inID ;;
       "suse" )
           pctSuse $inID ;;
       "arch" )
           pctArch $inID ;;
      *) 
           pctUnknown $inID ;;
    esac
}

function pctCheck {
# Check to see if the LXC is running 

    inID=$1

    inStatus=`/usr/sbin/pct list | grep  $inID | cut -c12-18` 
    if [ "$inStatus" = "running" ]; then
       pctUpdate $inID
    fi
}

dirList=`/usr/bin/ls -1 /etc/pve/lxc/ | /usr/bin/sed -e 's/\.conf$//'`

for lxc in $dirList
do
   pctCheck $lxc
done

exit;
