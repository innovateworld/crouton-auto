#!/bin/bash

###############################################################
## GLOBALS
###############################################################
SELF_NAME=`basename $0`
SELF_PATH=`dirname $0`/${SELF_NAME}
CROUTON_PATH=`dirname $0`/crouton
PYCHARM_PATH=/usr/local/bin/pycharm

INODE_NUM=`ls -id / | awk '{print $1}'`
ROBO_MONGO_PATH=/usr/local/bin/robomongo
BOOTSTRAP_PATH=`dirname $0`/xenial.tar.bz2
DOWNLOADS_PATH=/home/chronos/user/Downloads
CHROOT_PATH=/mnt/stateful_partition/crouton/chroots/xenial
TARGETS=cli-extra,xorg,xiwi,extension,keyboard,audio,chrome,gnome


###############################################################
## Helpers
###############################################################
title() {
    printf "\033[1;42m"
    printf '%*s\n'  "${COLUMNS:-$(tput cols)}" '' | tr ' ' ' '
    printf '%-*s\n' "${COLUMNS:-$(tput cols)}" "  # $1" | tr ' ' ' '
    printf '%*s'  "${COLUMNS:-$(tput cols)}" '' | tr ' ' ' '
    printf "\033[0m"
    printf "\n\n"
    sleep .5
}

breakLine() {
    printf "\n"
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    printf "\n\n"
}

askUser() {
    while true; do
        read -p " - $1 (y/n): " yn
        case ${yn} in
            [Yy]* ) echo 1; return 1;;
            [Nn]* ) echo 0; return 0;;
        esac
    done
}


###############################################################
## Installation
###############################################################
fetchCrouton() {

    # Move to the downloads folder, we'll work in here
    cd ${DOWNLOADS_PATH}

    if [ ! -f ${CROUTON_PATH} ]; then
        title "Fetching crouton..."
        curl "https://goo.gl/fd3zc" -L -o crouton
        breakLine
    fi
}

updateChroot() {

    # Move to the downloads folder, we'll work in here
    cd ${DOWNLOADS_PATH}

    # If no crouton file exists get it
    fetchCrouton

    title "Updating your chroot installation"
    sudo sh ${CROUTON_PATH} -n xenial -u
    breakLine
}

install() {

    # Move to the downloads folder, we'll work in here
    cd ${DOWNLOADS_PATH}

    # If no crouton file exists get it
    fetchCrouton

    # If no chroot is setup
    if [ ! -d ${CHROOT_PATH} ]; then
        # Prepare a bootstrap
        if [ ! -f ${BOOTSTRAP_PATH} ]; then
            title "Preparing an Ubuntu bootstrap"
            sudo sh ${CROUTON_PATH} -d -f ${BOOTSTRAP_PATH} -r xenial -t ${TARGETS}
            breakLine
        fi

        # Setup Ubuntu
        title "Ubuntu 16.04 with Gnome on ChromeOS"
        if [ "$(askUser "Install Ubuntu 16.04 LTS (xenial)")" -eq 1 ]; then
            sudo sh ${CROUTON_PATH} -f ${BOOTSTRAP_PATH} -t ${TARGETS}
        fi
        breakLine
    fi

    # Launch Ubuntu & configure
    title "Mounting the Ubuntu 16.04 chroot"

    # Get chroot username
    CHROOT_USERNAME=`ls ${CHROOT_PATH}/home/ | awk '{print $1}'`
    sudo enter-chroot -n xenial -l sh /home/${CHROOT_USERNAME}/Downloads/${SELF_NAME}
    breakLine
}

###############################################################
## Configuration
###############################################################
cPreRequisites() {
    title "Installing package pre-requisites"
    sudo apt install -y locales software-properties-common python-software-properties
    breakLine
}

cRepositories() {
    title "Setting up required Ubuntu 16.04 repositories"
    sudo add-apt-repository -y ppa:tista/adapta
    sudo add-apt-repository -y ppa:papirus/papirus
    sudo add-apt-repository -y ppa:gnome3-team/gnome3-staging
    sudo add-apt-repository -y ppa:gnome3-team/gnome3
    sudo add-apt-repository -y ppa:webupd8team/atom

    sudo apt install -y curl apt-transport-https ca-certificates
    
    sudo add-apt-repository -y ppa:shutter/ppa
    sudo add-apt-repository -y ppa:peterlevi/ppa

    curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
    sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
    sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
              
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
    sudo echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
    
    sudo apt update -y
    breakLine
}

cUi() {
    title "Preparing the Gnome interface / applications"
    sudo apt dist-upgrade -y
    sudo apt install -y papirus-icon-theme whoopsie language-pack-en-base mlocate htop preload inxi
    sudo apt install -y gnome-tweak-tool gnome-terminal gnome-control-center gnome-online-accounts gnome-software gnome-software-common
    sudo apt install -y gnome-shell chrome-gnome-shell
    sudo apt install -y gnome-shell-extensions gnome-shell-pomodoro
}

cSoftware() {
    breakLine

    title "Installing Basic Software"
    sudo apt install -y filezilla vlc bleachbit nano vim fish xarchiver p7zip p7zip-rar variety shutter
    cd /tmp
    wget "https://github.com/oguzhaninan/Stacer/releases/download/v1.0.8/Stacer_1.0.8_amd64.deb" -O stacer.deb
    sudo dpkg -i stacer.deb
    sudo rm stacer.deb
    cd /tmp
    wget "http://launchpadlibrarian.net/228111194/gnome-disk-utility_3.18.3.1-1ubuntu1_amd64.deb" -O gnome-disk.deb
    sudo dpkg -i gnome-disk.deb
    sudo rm gnome-disk.deb
    breakLine
    
    title "Installing ClamAV"
    sudo apt install -y clamav clamav-daemon clamav-freshclam clamtk
    breakLine
    
    title "Installing GIT"
    sudo apt install -y git
    breakLine
    
    title "Installing NodeJS"
    curl -sL "https://deb.nodesource.com/setup_8.x" | sudo -E bash -
    sudo apt install -y build-essential nodejs
    breakLine
    
    title "Installing N"
    sudo npm install -g n
    breakLine
    
    title "Installing Yarn"
    sudo apt install -y yarn
    breakLine
    
    title "Installing Angular CLI"
    sudo yarn global add @angular/cli@latest
    sudo ng set --global packageManager=yarn
    breakLine
    
    title "Installing Cordova"
    sudo yarn global add cordova
    breakLine
    
    title "Installing Ionic"
    sudo yarn global add ionic@latest
    breakLine
    
    title "Installing Firebase Tools"
    sudo yarn global add firebase-tools
    breakLine
    
    title "Installing Visual Studio Code"
    sudo apt install -y code
    breakLine
    
    title "Installing Atom"
    sudo apt install -y atom
    breakLine
    
    title "Installing Insomnia"
    cd /tmp
    wget "https://builds.insomnia.rest/downloads/ubuntu/latest" -O insomnia.deb
    sudo dpkg -i insomnia.deb
    sudo rm insomnia.deb
    breakLine

}

cFranz() {
    title "Franz"
    if [ "$(askUser "Install Franz Chat")" -eq 1 ]; then
        sudo mkdir -p /opt/franz
        wget -qO- https://github.com/meetfranz/franz-app/releases/download/4.0.4/Franz-linux-x64-4.0.4.tgz | sudo tar xvz -C /opt/franz/
        sudo wget "https://cdn-images-1.medium.com/max/360/1*v86tTomtFZIdqzMNpvwIZw.png" -O /opt/franz/franz-icon.png
        local FRANZ_LAUNCHER_PATH=/usr/share/applications/franz.desktop
        
        if [ ! -f ${FRANZ_LAUNCHER_PATH} ]; then
            sudo touch ${FRANZ_LAUNCHER_PATH}
        fi

        sudo truncate --size 0 ${FRANZ_LAUNCHER_PATH}
        sudo echo "[Desktop Entry]" >> ${FRANZ_LAUNCHER_PATH}
        sudo echo "Name=Franz" >> ${FRANZ_LAUNCHER_PATH}
        sudo echo "Comment=Franz" >> ${FRANZ_LAUNCHER_PATH}
        sudo echo "GenericName=Franz Client for Linux" >> ${FRANZ_LAUNCHER_PATH}
        sudo echo "Icon=franz" >> ${FRANZ_LAUNCHER_PATH}
        sudo echo "Type=Application" >> ${FRANZ_LAUNCHER_PATH}
        sudo echo "StartupNotify=true" >> ${FRANZ_LAUNCHER_PATH}
        sudo echo "Categories=GNOME;GTK;Network;InstantMessaging;" >> ${FRANZ_LAUNCHER_PATH}
        sudo echo "MimeType=x-scheme-handler/franz;" >> ${FRANZ_LAUNCHER_PATH}
    fi
    breakLine
}

cLocalesPlusKeymap() {
    title "Configuring locales and keyboard mappings"
    sudo echo "LANG=en_US.UTF-8" >> /etc/default/locale
    sudo echo "LANGUAGE=en_US.UTF-8" >> /etc/default/locale
    sudo echo "LC_ALL=en_US.UTF-8" >> /etc/default/locale
    sudo sed -i "s/XKBMODEL=.*/XKBMODEL=\"chromebook\"/g" /etc/default/keyboard
    breakLine
}

cClean() {
    title "Cleaning up..."
    sudo apt remove -y xterm netsurf netsurf-common netsurf-fb netsurf-gtk
    sudo apt update -y
    sudo apt autoremove --purge -y
    sudo updatedb
    breakLine
}

configure() {

    # Set the home variable
    export HOME=/home/`ls /home/ | awk '{print $1}'`

    # OS setup
    local IS_OS_SETUP=`dpkg -l | grep preload | awk '{print $1}'`
    if [ "$IS_OS_SETUP" = "" ]; then
        cPreRequisites
        cRepositories
        cUi
    fi

    # Systems setup
    cSoftware   
    cFranz
    cLocalesPlusKeymap
    cClean
    exit
}


###############################################################
## Main application
###############################################################
clear
if [ ${INODE_NUM} -eq 2 ];
    then
        if [ $# -eq 0 ];
            then
            install
        else while getopts :u option
            do
                case "${option}" in
                u) updateChroot;;
                esac
            done
        fi
    else configure
fi
