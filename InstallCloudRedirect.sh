#!/usr/bin/env bash
set -eu
    
    cloudredirect="https://raw.githubusercontent.com/Selectively11/CloudRedirect/refs/heads/gh-pages/cloudredirect.flatpakrepo"
    flathub="https://dl.flathub.org/repo/flathub.flatpakrepo"

    install_CR(){
        echo "Installing Cloud Redirect App"
        flatpak remote-add --user --if-not-exists cloudredirect $cloudredirect
        flatpak remote-add --user --if-not-exists flathub $flathub
        flatpak --user update --appstream --noninteractive
        flatpak install --user flathub org.kde.Platform//6.10 --assumeyes --noninteractive
        flatpak install --user --reinstall org.cloudredirect.CloudRedirect --assumeyes --noninteractive
        update-desktop-database
        echo "App Installed Open It To Configure Your Storage Provider"
    }
    install_CR
