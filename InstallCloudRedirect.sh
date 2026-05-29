#!/usr/bin/env bash
set -eu
    
    #Paths
    SCRIPT_DIR="$(dirname "$(realpath "$0")")"
    CloudRedirectApp="https://github.com/Selectively11/h3adcr-b/releases/download/linux-test/cloudredirect.flatpak"

    install_CR(){
    cd $SCRIPT_DIR/
    wget -O cloudredirect.flatpak "$CloudRedirectApp" &> /dev/null
    echo "Installing Cloud Redirect App"
    flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    flatpak install --user flathub org.kde.Platform//6.10 --assumeyes --noninteractive
    flatpak install --user cloudredirect.flatpak --assumeyes --noninteractive
    echo "App Installed Open It To Configure Your Storage Provider"
    }
    install_CR
