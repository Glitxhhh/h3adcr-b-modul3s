#!/usr/bin/env bash


    STEAM_CLIENT="$HOME/.steam/steam/client.sh"
    INJECT_SLS="LD_AUDIT=$HOME/.local/share/SLSsteam/library-inject.so:$HOME/.local/share/SLSsteam/SLSsteam.so"
    INJECT_CR="LD_PRELOAD=$HOME/.local/share/CloudRedirect/cloud_redirect.so"
       GameLauncher(){
        export $INJECT_SLS &> /dev/null
        export $INJECT_CR &> /dev/null
        source $STEAM_CLIENT "$@" &> /dev/null
        }



    steam(){
        GameLauncher "$@"
        }

   steam "$@"
