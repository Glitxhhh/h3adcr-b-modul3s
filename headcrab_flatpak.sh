#!/usr/bin/env bash


    STEAM_CLIENT="$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/client.sh"
    INJECT_SLS="LD_AUDIT=$HOME/.var/app/com.valvesoftware.Steam/.local/share/SLSsteam/library-inject.so:$HOME/.var/app/com.valvesoftware.Steam/.local/share/SLSsteam/SLSsteam.so"
    INJECT_CR="LD_PRELOAD=$HOME/.var/app/com.valvesoftware.Steam/.local/share/CloudRedirect/cloud_redirect.so"

       GameLauncher(){
        export $INJECT_SLS &> /dev/null
        export $INJECT_CR &> /dev/null
        source $STEAM_CLIENT "$@"
        }



    steam(){
        GameLauncher "$@"
        }

   steam "$@"
