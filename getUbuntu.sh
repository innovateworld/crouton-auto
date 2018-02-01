#!/bin/bash

###############################################################
## GLOBALS
###############################################################
SELF_NAME=`basename $0`
SELF_PATH=`dirname $0`/${SELF_NAME}
CROUTON_PATH=`dirname $0`/crouton
PYCHARM_PATH=/usr/local/bin/pycharm
PHPSTORM_PATH=/usr/local/bin/phpstorm
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

    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6
    sudo echo "deb [arch=amd64,arm64] http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.4.list

    curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
    sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
    sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
              
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
    sudo echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
    
    curl -fsSL "https://download.docker.com/linux/ubuntu/gpg" | sudo apt-key add -
    sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

    sudo apt update -y
    breakLine
}

cUi() {
    title "Preparing the Gnome interface / applications"
    sudo apt dist-upgrade -y
    sudo apt install -y papirus-icon-theme whoopsie language-pack-en-base nano mlocate htop preload inxi filezilla vlc bleachbit vim fish kiki atom xarchiver p7zip p7zip-rar
    sudo apt install -y gnome-tweak-tool gnome-terminal gnome-control-center gnome-online-accounts gnome-software gnome-software-common
    sudo apt install -y gnome-shell chrome-gnome-shell
    sudo apt install -y gnome-shell-extensions gnome-shell-pomodoro

    cd /tmp
    wget "http://launchpadlibrarian.net/228111194/gnome-disk-utility_3.18.3.1-1ubuntu1_amd64.deb" -O gnome-disk.deb
    sudo dpkg -i gnome-disk.deb
    sudo rm gnome-disk.deb

    cd /tmp
    wget "https://builds.insomnia.rest/downloads/ubuntu/latest" -O insomnia.deb
    sudo dpkg -i insomnia.deb
    sudo rm insomnia.deb

    cd /tmp
    wget "https://github.com/oguzhaninan/Stacer/releases/download/v1.0.8/Stacer_1.0.8_amd64.deb" -O stacer.deb
    sudo dpkg -i stacer.deb
    sudo rm stacer.deb

    if [ -f /usr/share/applications/kiki.desktop ]; then
        sudo sed -i "s/Icon=.*/Icon=regexxer/g" /usr/share/applications/kiki.desktop
    fi

    breakLine

    title "Installing ClamAV"
    sudo apt install -y clamav clamav-daemon clamav-freshclam clamtk
    breakLine
}

cNodeJs() {
    title "NodeJS"
    if [ "$(askUser "Install NodeJS v8.0 environment")" -eq 1 ]; then
        curl -sL "https://deb.nodesource.com/setup_8.x" | sudo -E bash -
        sudo apt install -y build-essential nodejs

        breakLine
        title "Yarn"
        if [ "$(askUser "Install Yarn package manager")" -eq 1 ]; then
            sudo apt install -y yarn
        fi

        breakLine
        title "AngularJS Framework"
        if [ "$(askUser "Install the Angular CLI, Service Worker & PWA tools framework")" -eq 1 ]; then
            sudo npm install -y @angular/cli @angular/service-worker ng-pwa-tools -g
        fi
    fi
    breakLine
}

cGit() {
    title "Git"
    if [ "$(askUser "Install Git version control system")" -eq 1 ]; then
        sudo apt install -y git
    fi
    breakLine
}

cDocker() {
    title "Docker"
    if [ "$(askUser "Install Docker visualization environment")" -eq 1 ]; then
        sudo apt install -y docker-ce
    fi
    breakLine
}

cMySqlWorkbench() {
    title "MySQL Workbench"
    if [ "$(askUser "Install MySQL Workbench database manager")" -eq 1 ]; then
        sudo apt install -y mysql-workbench
    fi
    breakLine
}

cMongoDb() {
    title "MongoDB"
    if [ "$(askUser "Install MongoDB server")" -eq 1 ]; then
        sudo apt install -y mongodb-org

        breakLine
        title "RoboMongo (Robo3T)"
        if [ "$(askUser "Install RoboMongo database manager")" -eq 1 ]; then
            sudo apt install -y xcb
            cd /tmp
            wget "https://download.robomongo.org/1.1.1/linux/robo3t-1.1.1-linux-x86_64-c93c6b0.tar.gz" -O robomongo.tar.gz

            if [ -d ${ROBO_MONGO_PATH} ]; then
                sudo rm -rf ${ROBO_MONGO_PATH}
            fi

            sudo mkdir ${ROBO_MONGO_PATH}
            sudo tar xf robomongo.tar.gz
            sudo rm robomongo.tar.gz
            sudo mv robo3t-*/* ${ROBO_MONGO_PATH}
            sudo rm -rf robo3t-*/
            sudo rm ${ROBO_MONGO_PATH}/lib/libstdc++*
            sudo chmod +x ${ROBO_MONGO_PATH}/bin/robo3t

            local ROBO_MONGO_LAUNCHER_PATH=/usr/share/applications/robomongo.desktop

            if [ ! -f ${ROBO_MONGO_LAUNCHER_PATH} ]; then
                sudo touch ${ROBO_MONGO_LAUNCHER_PATH}
            fi

            sudo truncate --size 0 ${ROBO_MONGO_LAUNCHER_PATH}
            sudo echo "[Desktop Entry]" >> ${ROBO_MONGO_LAUNCHER_PATH}
            sudo echo "Name=Robomongo" >> ${ROBO_MONGO_LAUNCHER_PATH}
            sudo echo "Comment=MongoDB Database Administration" >> ${ROBO_MONGO_LAUNCHER_PATH}
            sudo echo "Exec=/usr/local/bin/robomongo/bin/robo3t" >> ${ROBO_MONGO_LAUNCHER_PATH}
            sudo echo "Terminal=false" >> ${ROBO_MONGO_LAUNCHER_PATH}
            sudo echo "Type=Application" >> ${ROBO_MONGO_LAUNCHER_PATH}
            sudo echo "Icon=robomongo" >> ${ROBO_MONGO_LAUNCHER_PATH}
            sudo echo "StartupWMClass=robo3t" >> ${ROBO_MONGO_LAUNCHER_PATH}
        fi
  fi
  breakLine
}

cVsCodeIde() {
    title "Microsoft Visual Studio Code IDE"
    if [ "$(askUser "Install Microsoft Visual Studio Code IDE")" -eq 1 ]; then
        sudo apt install -y code
    fi
    breakLine
}

cPyCharmIde() {
    title "PyCharm Community Edition IDE"
    if [ "$(askUser "Install PyCharm Community Edition IDE")" -eq 1 ]; then
        cd /tmp
        wget "https://download.jetbrains.com/python/pycharm-community-2017.2.3.tar.gz" -O pycharm.tar.gz
        sudo tar xf pycharm.tar.gz

        if [ -d ${PYCHARM_PATH} ]; then
            sudo rm -rf ${PYCHARM_PATH}
        fi

        sudo mkdir ${PYCHARM_PATH}
        sudo mv pycharm-*/* ${PYCHARM_PATH}
        sudo rm -rf pycharm-*/
        sudo rm pycharm.tar.gz

        local PYCHARM_LAUNCHER_PATH=/usr/share/applications/pycharm.desktop

        if [ ! -f ${PYCHARM_LAUNCHER_PATH} ]; then
            sudo touch ${PYCHARM_LAUNCHER_PATH}
        fi

        sudo truncate --size 0 ${PYCHARM_LAUNCHER_PATH}
        sudo echo "[Desktop Entry]" >> ${PYCHARM_LAUNCHER_PATH}
        sudo echo "Version=1.0" >> ${PYCHARM_LAUNCHER_PATH}
        sudo echo "Type=Application" >> ${PYCHARM_LAUNCHER_PATH}
        sudo echo "Name=PyCharm" >> ${PYCHARM_LAUNCHER_PATH}
        sudo echo "Icon=pycharm" >> ${PYCHARM_LAUNCHER_PATH}
        sudo echo "Exec=/usr/local/bin/pycharm/bin/pycharm.sh" >> ${PYCHARM_LAUNCHER_PATH}
        sudo echo "StartupWMClass=jetbrains-pycharm-ce" >> ${PYCHARM_LAUNCHER_PATH}
        sudo echo "Comment=The Drive to Develop" >> ${PYCHARM_LAUNCHER_PATH}
        sudo echo "Categories=Development;IDE;" >> ${PYCHARM_LAUNCHER_PATH}
        sudo echo "Terminal=false" >> ${PYCHARM_LAUNCHER_PATH}
    fi
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
        sudo echo "Exec=/usr/bin/franz --disable-gpu %U" >> ${FRANZ_LAUNCHER_PATH}
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
    cPhp
    cNodeJs
    cGit
    cDocker
    cMySqlWorkbench
    cMongoDb
    cVsCodeIde
    cPyCharmIde
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
