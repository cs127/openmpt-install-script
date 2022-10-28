#!/usr/bin/bash

# cs127's OpenMPT install/update script for Linux
# version 0.0.0

# https://cs127.github.io



SCRIPTVER=0.0.0
DEPS=("wine" "wget" "jq" "unzip")

URL_SCRIPTRESOURCES="https://github.com/cs127/openmpt-install-script/raw/master/resources/"
URL_MPTAPI="https://update.openmpt.org/api/v3/update/"
URL_MPTICON="https://openmpt.org/img/logo256.png"

RESOURCES=("openmpt" "openmpt.desktop" "mptwine")
MPTDIR=~/.openmpt
TMPDIR=$(mktemp -d)
BINDIR=~/.local/bin
APPDIR=~/.local/share/applications
ICODIR=~/.local/share/icons

export WINEPREFIX=$MPTDIR/wine
export WINEDEBUG=-all

SCRIPT=$0
SCRIPTDIR="$(cd "$(dirname "$0")" && pwd)"

existingversion=false

channel=""
version=""
url_download32=""
url_download64=""

start_time=""
end_time=""



p_trw() {
    echo -n "$@"
}

p_tln() {
    echo "$@"
}

p_fmt() {
    for a in "$@"; do
        case $a in
            resetall)  echo -ne '\e[0m';;
            f_bold)    echo -ne '\e[1m';;
            f_unbold)  echo -ne '\e[22m';;
            c_black)   echo -ne '\e[30m';;
            c_red)     echo -ne '\e[31m';;
            c_green)   echo -ne '\e[32m';;
            c_yellow)  echo -ne '\e[33m';;
            c_blue)    echo -ne '\e[34m';;
            c_magenta) echo -ne '\e[35m';;
            c_cyan)    echo -ne '\e[36m';;
            c_white)   echo -ne '\e[37m';;
            c_reset)   echo -ne '\e[39m';;
        esac
    done
}

startmessage() {
    cd "$SCRIPTDIR"
    p_tln
    p_fmt f_bold c_cyan
    p_tln "cs127's OpenMPT install/update script for Linux"
    p_tln "version $SCRIPTVER"
    p_fmt c_magenta
    p_tln "https://cs127.github.io"
    p_fmt c_cyan
    p_tln "_______________________________________________"
    p_fmt f_unbold c_reset
    p_tln
}

endmessage() {
    local time="";
    if ! [ -z ${start_time+x} ] && ! [ -z ${end_time+x} ] ; then
        local tr="$(($end_time-$start_time))"
        time="$(sed 's/...$/.&/' <<< $tr)"
        [ $tr -lt 1000 ] && time="0$(sed 's/...$/.&/' <<< $tr)"
        [ $tr -lt 100  ] && time="0.0$(sed 's/...$/.&/' <<< $tr)"
        [ $tr -lt 10   ] && time="0.00$(sed 's/...$/.&/' <<< $tr)"
    fi
    p_fmt f_bold c_cyan
    p_tln "_______________________________________________"
    p_tln
    p_fmt c_green
    p_tln "Successfully installed OpenMPT $version."
    p_fmt f_bold c_cyan
    if ! [ -z ${time+x} ]; then
        p_trw "Total time spent: "
        p_fmt c_magenta
        p_trw "$time"
        p_fmt c_cyan
        p_tln " seconds."
    fi
    if [ "$existingversion" != true ]; then
        p_tln
        p_fmt c_cyan; p_trw "OpenMPT directory:  "; p_fmt c_magenta; p_tln "${MPTDIR/~/"~"}/resources"
        p_fmt c_cyan; p_trw "32-bit exe:         "; p_fmt c_magenta; p_tln "${MPTDIR/~/"~"}/resources/bin/x86/OpenMPT.exe"
        p_fmt c_cyan; p_trw "64-bit exe:         "; p_fmt c_magenta; p_tln "${MPTDIR/~/"~"}/resources/bin/amd64/OpenMPT.exe"
        p_fmt c_cyan; p_trw "Wine directory:     "; p_fmt c_magenta; p_tln "${WINEPREFIX/~/"~"}"
        p_fmt c_cyan; p_trw "Desktop entry:      "; p_fmt c_magenta; p_tln "${APPDIR/~/"~"}/openmpt.desktop"
        p_fmt c_cyan; p_trw "Launch script:      "; p_fmt c_magenta; p_tln "${BINDIR/~/"~"}/openmpt"
        p_fmt c_cyan; p_trw "Wine launch script: "; p_fmt c_magenta; p_tln "${BINDIR/~/"~"}/mptwine"
        p_fmt f_unbold c_magenta
        p_tln
        p_tln "You can now launch OpenMPT from your application menu."
        p_tln "Associating file types with it are also possible."
        p_tln
        p_trw "If you have "; p_fmt c_cyan; p_trw "${BINDIR/~/"~"}"; p_fmt c_magenta; p_tln " in your PATH environment variable,"
        p_trw "you can run "; p_fmt c_green; p_trw "openmpt"; p_fmt c_magenta; p_trw " from the command line, "
        p_trw "and use "; p_fmt c_green; p_trw "mptwine"; p_fmt c_magenta; p_tln " as described below."
        p_tln
        p_trw "To configure basic Wine settings,  run ";   p_fmt c_green; p_tln "mptwine winecfg"; p_fmt c_magenta
        p_trw "To configure the registry in Wine, run ";   p_fmt c_green; p_tln "mptwine regedit"; p_fmt c_magenta
        p_trw "To manually configure Wine options, edit "; p_fmt c_cyan;  p_tln "${WINEPREFIX/~/"~"}/user.reg"; p_fmt c_magenta
        p_tln
        p_tln "You can choose whether to run the 32-bit or 64-bit OpenMPT executable"
        p_trw "by passing "
        p_fmt c_green; p_trw "MPTARCH=32"; p_fmt c_magenta
        p_trw " or "
        p_fmt c_green; p_trw "MPTARCH=64"; p_fmt c_magenta
        p_tln " as an environment variable."
        p_trw "Example: "; p_fmt c_green; p_tln "MPTARCH=32 openmpt"; p_fmt c_magenta
        p_fmt f_unbold c_reset
    fi
}

endmessage_uninstall() {
    local time="";
    if ! [ -z ${start_time+x} ] && ! [ -z ${end_time+x} ] ; then
        local tr="$(($end_time-$start_time))"
        time="$(sed 's/...$/.&/' <<< $tr)"
        [ $tr -lt 1000 ] && time="0$(sed 's/...$/.&/' <<< $tr)"
        [ $tr -lt 100  ] && time="0.0$(sed 's/...$/.&/' <<< $tr)"
        [ $tr -lt 10   ] && time="0.00$(sed 's/...$/.&/' <<< $tr)"
    fi
    p_fmt f_bold c_cyan
    p_tln "_______________________________________________"
    p_tln
    p_fmt c_green
    [ -z ${version+x} ] && p_tln "Successfully uninstalled OpenMPT." || p_tln "Successfully uninstalled OpenMPT $version."
    p_fmt f_bold c_cyan
    if ! [ -z ${time+x} ]; then
        p_trw "Total time spent: "
        p_fmt c_magenta
        p_trw "$time"
        p_fmt c_cyan
        p_tln " seconds."
    fi
}

quit() {
    p_fmt f_unbold c_reset
    p_tln
    rm -rf "$TMPDIR"
    exit $1
}

cancel() {
    p_fmt f_unbold c_red
    [ "$1" != "uninstall" ] && p_tln "Installation canceled." || p_tln "Uninstallation canceled."
    p_fmt c_reset
    quit 8
}

error_generic() {
    p_fmt f_bold c_red
    p_tln "An error occured."
    p_fmt f_unbold c_reset
}

error_internet_connection() {
    p_fmt f_bold c_red
    p_tln "Internet connection error."
    p_fmt f_unbold c_reset
}

error_server_response() {
    p_fmt f_bold c_red
    p_tln "Server issued an error. The file probably does not exist."
    p_fmt f_unbold c_reset
}

get_update_file() {
    p_fmt f_bold c_white
    p_trw "Getting latest OpenMPT version number ($1 channel)..."
    wget -q -O "$TMPDIR/version.json" "$URL_MPTAPI$1"
    local status=$?
    [ $status -eq 0 ] && p_fmt c_green && p_tln "DONE" && p_fmt f_unbold c_reset && return
    p_fmt c_red && p_tln "FAILED" && p_fmt f_unbold c_reset
    rm "$TMPDIR/version.json"
    case $status in
        8) error_server_response && quit 5;;
        *) error_internet_connection && quit 4;;
    esac
}

get_latest_version() {
    get_update_file $1
    version=$(jq -r '.[].version' "$TMPDIR/version.json")
    url_download32=$(jq -r '.[].downloads."portable-x86".download_url' "$TMPDIR/version.json")
    url_download64=$(jq -r '.[].downloads."portable-amd64".download_url' "$TMPDIR/version.json")
    rm "$TMPDIR/version.json"
}

download_32() {
    p_fmt f_bold c_white
    p_trw "Downloading OpenMPT $version (32-bit)..."
    wget -q -O "$TMPDIR/mpt32.zip" "$url_download32"
    local status=$?
    [ $status -eq 0 ] && p_fmt c_green && p_tln "DONE" && p_fmt f_unbold c_reset && return
    p_fmt c_red && p_tln "FAILED" && p_fmt f_unbold c_reset
    rm "$TMPDIR/mpt32.zip"
    case $status in
        8) error_server_response && quit 5;;
        *) error_internet_connection && quit 4;;
    esac
}

download_64() {
    p_fmt f_bold c_white
    p_trw "Downloading OpenMPT $version (64-bit)..."
    wget -q -O "$TMPDIR/mpt64.zip" "$url_download64"
    local status=$?
    [ $status -eq 0 ] && p_fmt c_green && p_tln "DONE" && p_fmt f_unbold c_reset && return
    p_fmt c_red && p_tln "FAILED" && p_fmt f_unbold c_reset
    rm "$TMPDIR/mpt64.zip"
    case $status in
        8) error_server_response && quit 5;;
        *) error_internet_connection && quit 4;;
    esac
}

download() {
    download_32 && download_64
}

extract_32() {
    mkdir "$TMPDIR/mpt32"
    p_fmt f_bold c_white
    p_trw "Extracting OpenMPT $version (32-bit)..."
    unzip -q "$TMPDIR/mpt32.zip" -d "$TMPDIR/mpt32"
    local status=$?
    [ $status -eq 0 ] && p_fmt c_green && p_tln "DONE" && p_fmt f_unbold c_reset && return
    p_fmt c_red && p_tln "FAILED" && p_fmt f_unbold c_reset
    rm -rf "$TMPDIR/mpt32"
    case $status in
        *) error_generic && quit 127;;
    esac
}

extract_64() {
    mkdir "$TMPDIR/mpt64"
    p_fmt f_bold c_white
    p_trw "Extracting OpenMPT $version (64-bit)..."
    unzip -q "$TMPDIR/mpt64.zip" -d "$TMPDIR/mpt64"
    local status=$?
    [ $status -eq 0 ] && p_fmt c_green && p_tln "DONE" && p_fmt f_unbold c_reset && return
    p_fmt c_red && p_tln "FAILED" && p_fmt f_unbold c_reset
    rm -rf "$TMPDIR/mpt64"
    case $status in
        *) error_generic && quit 127;;
    esac
}

check_diff() {
    local file32="$1"
    local file64="${file32/"mpt32"/"mpt64"}"
    if diff "$file32" "$file64" &>/dev/null; then
        local dir="$(cd "$(dirname "$file32")" && pwd)"
        mkdir -p "${dir/"mpt32"/"mptcommon"}"
        mv "$file32" "${file32/"mpt32"/"mptcommon"}"
        rm "$file64" &>/dev/null
    else
        mv "$file32" "${file32/"mpt32"/"mptcommon/bin/x86"}"
        mv "$file64" "${file64/"mpt64"/"mptcommon/bin/amd64"}"
    fi
}

merge_common_recurse() {
    for d in *; do
        [ -d "$d" ] && (cd -- "$d" && merge_common_recurse) || check_diff "$(pwd)/$d"
    done
}

handle_pluginbridge() {
    mv $TMPDIR/mptcommon/PluginBridge*x86.exe   $TMPDIR/mptcommon/bin/x86
    mv $TMPDIR/mptcommon/PluginBridge*amd64.exe $TMPDIR/mptcommon/bin/amd64
    rm $TMPDIR/mptcommon/PluginBridge*.exe
}

merge_common() {
    mkdir -p "$TMPDIR/mptcommon/bin/x86"
    mkdir -p "$TMPDIR/mptcommon/bin/amd64"
    p_fmt f_bold c_white
    p_trw "Merging common files..."
    cd "$TMPDIR/mpt32"
    merge_common_recurse && cd "$SCRIPTDIR" && handle_pluginbridge &&
    p_fmt c_green && p_tln "DONE" && p_fmt f_unbold c_reset && return
    error_generic && quit 127
}

prepare() {
    extract_32 && extract_64
    rm "$TMPDIR/mpt32.zip" && rm "$TMPDIR/mpt64.zip"
    merge_common
}

install_openmpt_files() {
    mkdir -p "$MPTDIR/resources"
    p_fmt f_bold c_white
    p_trw "Installing OpenMPT files..."
    if cp -RT "$TMPDIR/mptcommon" "$MPTDIR/resources" ; then
        p_fmt c_green && p_tln "DONE" && p_fmt f_unbold c_reset
    else p_fmt c_red && p_tln "FAILED" && p_fmt f_unbold c_reset && stop 127; fi
    echo "$version" > "$MPTDIR/.mptver"
    echo "$channel" > "$MPTDIR/.mptchn"
}

install_icon() {
    mkdir -p "$ICODIR/hicolor/256x256/apps"
    wget -q -O "$ICODIR/hicolor/256x256/apps/openmpt.png" "$URL_MPTICON"
}

install_desktop_entry() {
    mkdir -p "$APPDIR"
    p_fmt f_bold c_white
    p_trw "Installing desktop entry..."
    if cp "$SCRIPTDIR/resources/openmpt.desktop" "$APPDIR" && install_icon ; then
        p_fmt c_green && p_tln "DONE" && p_fmt f_unbold c_reset
    else p_fmt c_red && p_tln "FAILED" && p_fmt f_unbold c_reset && stop 127; fi
}

install_launch_script() {
    mkdir -p "$BINDIR"
    p_fmt f_bold c_white
    p_trw "Installing launch script..."
    if cp "$SCRIPTDIR/resources/openmpt" "$BINDIR" && cp "$SCRIPTDIR/resources/mptwine" "$BINDIR" &&
       chmod +x "$BINDIR/openmpt" && chmod +x "$BINDIR/mptwine" ; then
       p_fmt c_green && p_tln "DONE" && p_fmt f_unbold c_reset
    else p_fmt c_red && p_tln "FAILED" && p_fmt f_unbold c_reset && stop 127; fi
}

configure_wine() {
    p_fmt f_bold c_white
    p_trw "Configuring Wine..."
    wine chcp &>/dev/null
    p_fmt c_green && p_tln "DONE" && p_fmt f_unbold c_reset
}

uninstall_openmpt_files() {
    p_fmt f_bold c_white
    p_trw "Uninstalling OpenMPT files..."
    if rm -rf "$MPTDIR" ; then p_fmt c_green && p_tln "DONE" && p_fmt f_unbold c_reset
    else p_fmt c_red && p_tln "FAILED" && p_fmt f_unbold c_reset && stop 127; fi
}

uninstall_icon() {
    rm "$ICODIR/hicolor/256x256/apps/openmpt.png"
}

uninstall_desktop_entry() {
    p_fmt f_bold c_white
    p_trw "Uninstalling desktop entry..."
    if rm "$APPDIR/openmpt.desktop" && uninstall_icon ; then p_fmt c_green && p_tln "DONE" && p_fmt f_unbold c_reset
    else p_fmt c_red && p_tln "FAILED" && p_fmt f_unbold c_reset && stop 127; fi
}

uninstall_launch_script() {
    p_fmt f_bold c_white
    p_trw "Uninstalling launch script..."
    if rm "$BINDIR/openmpt" && rm "$BINDIR/mptwine" ; then p_fmt c_green && p_tln "DONE" && p_fmt f_unbold c_reset
    else p_fmt c_red && p_tln "FAILED" && p_fmt f_unbold c_reset && stop 127; fi
}

show_usage() {
    p_fmt f_bold c_cyan;    p_tln "Usage:"
    p_fmt f_bold c_magenta; p_trw "To install:   "; p_fmt f_unbold c_green; p_trw "$SCRIPT "; p_fmt c_cyan; p_tln "[channel]"; p_fmt c_reset
    p_fmt f_bold c_magenta; p_trw "To uninstall: "; p_fmt f_unbold c_green; p_trw "$SCRIPT ";               p_tln "uninstall"; p_fmt c_reset
    p_tln
    p_fmt f_bold c_cyan;    p_trw "Example:      "; p_fmt f_unbold c_green; p_trw "$SCRIPT ";               p_tln "development"; p_fmt c_reset
    p_tln
    p_tln "The download channel can be one of the following:"
    p_fmt c_green;  p_tln "'release':     current stable release."
    p_fmt c_yellow; p_tln "'next':        preview of the next minor update."
    p_fmt c_red;    p_tln "'development': preview of the next major update."
    p_fmt c_reset;
}

error_deps() {
    p_fmt f_bold c_red
    p_tln "The following dependencies are not installed:"
    for dep in "$@"; do p_fmt c_red; p_trw "* "; p_fmt c_white; p_tln "$dep"; done
    p_fmt c_red
    p_tln "Please install them using your package manager, and run this script again."
    p_fmt f_unbold c_reset
}

check_deps() {
    local missingdeps=()
    local depexec=""
    for dep in "$@"; do
        case $dep in
            imagemagick) depexec="convert";;
            *)           depexec="$dep";;
        esac
        ! command -v "$depexec" &>/dev/null && missingdeps+=("$dep")
    done
    [ ${#missingdeps} -gt 0 ] && error_deps "${missingdeps[@]}" && quit 2
}

check_uninstall() {
    local message="You are about to uninstall OpenMPT. Continue?"
    [ -f "$MPTDIR/.mptver" ] && version="$(< "$MPTDIR/.mptver")" && message="You are about to uninstall OpenMPT $version. Continue?"
    p_fmt f_bold c_yellow
    if ! [ -d "$MPTDIR" ] && ! [ -f "$APPDIR/openmpt.desktop" ] && ! [ -f "$BINDIR/openmpt" ]; then
        p_tln "OpenMPT is not installed."
        quit
    fi
    p_trw "$message"; p_fmt f_unbold c_reset; p_trw " (Y/n) "
    read response
    case $response in
        [Yy]|'') ;;
        [Nn])    cancel uninstall;;
        *)       p_fmt c_red && p_trw "Invalid response. " && cancel uninstall;;
    esac
    p_tln
}

uninstall_mode() {
    check_uninstall
    get_start_time
    uninstall_openmpt_files
    uninstall_desktop_entry
    uninstall_launch_script
    get_end_time
    endmessage_uninstall
    quit
}

check_arg() {
    [ "$1" = "" ] && show_usage && quit
    [ "$1" = "uninstall" ] && uninstall_mode && quit
    [ "$1" != "release" ] && [ "$1" != "next" ] && [ "$1" != "development" ] && show_usage && quit 1
    channel="$1"
}

error_oldsetup() {
    p_fmt f_bold c_red
    p_tln "OpenMPT has already been installed using the official installer."
    p_tln "Migrating official installs is not implemented yet."
    p_tln
    p_tln "Please uninstall OpenMPT, and run this script again."
    p_tln
    p_tln
    p_fmt f_unbold c_yellow
    p_tln "After uninstalling, make sure that:"
    p_tln
    p_trw "* There are no desktop entries in "
    p_fmt c_cyan; p_tln "~/.local/share/applications/wine/OpenMPT"; p_fmt c_yellow
    p_trw "  and "
    p_fmt c_cyan; p_trw "~/.config/menus/applications-merged"; p_fmt c_yellow
    p_tln "."
    p_tln
    p_trw "* There are no OpenMPT file associations in "; p_fmt c_yellow
    p_fmt c_cyan; p_trw "~/.local/share/mime/packages"; p_fmt c_yellow
    p_tln ","
    p_trw "  such as "
    p_fmt c_cyan; p_trw "x-wine-extension-s3m.xml"; p_fmt c_yellow
    p_tln "."
    p_trw "  If there are any, delete them and run "
    p_fmt c_cyan; p_tln "update-mime-database ~/.local/share/mime"; p_fmt c_yellow
    p_fmt f_unbold c_reset
}

check_oldsetup() {
    [ -d ~/.local/share/applications/wine/Programs/OpenMPT ] ||
    ls ~/.config/menus/applications-merged/wine-Programs-OpenMPT-* 1> /dev/null 2>&1 &&
    error_oldsetup && quit 3
    for DRIVE in {a..z}; do
        [ -f ~/.wine/drive_${DRIVE}/Program\ Files/OpenMPT/bin/x86/OpenMPT.exe   ] ||
        [ -f ~/.wine/drive_${DRIVE}/Program\ Files/OpenMPT/bin/amd64/OpenMPT.exe ] ||
        [ -f ~/.wine/drive_${DRIVE}/Program\ Files/OpenMPT/OpenMPT.exe           ] ||
        [ -f ~/.wine/drive_${DRIVE}/Program\ Files\ \(x86\)/OpenMPT/OpenMPT.exe  ] &&
        error_oldsetup && quit 3;
    done
}

get_resource() {
    p_fmt f_bold c_white
    p_trw "Downloading file..."
    wget -q -O "$SCRIPTDIR/resources/$1" "$URL_SCRIPTRESOURCES$1"
    local status=$?
    [ $status -eq 0 ] && p_fmt c_green && p_tln "DONE" && p_fmt f_unbold c_reset && return
    p_fmt c_red && p_tln "FAILED" && p_fmt f_unbold c_reset
    rm "$SCRIPTDIR/resources/$1"
    case $status in
        8) error_server_response && quit 5;;
        *) error_internet_connection && quit 4;;
    esac
}

prompt_resource() {
    p_fmt c_yellow
    p_trw "File '"; p_fmt c_cyan; p_trw "$1"; p_fmt c_yellow; p_tln "' not found."
    p_trw "Do you want to download it from the GitHub repo?"; p_fmt c_reset; p_trw " (Y/n) "
    read response
    case $response in
        [Yy]|'') get_resource "$1";;
        [Nn])    cancel;;
        *)       p_fmt c_red && p_trw "Invalid response. " && cancel;;
    esac
}

check_resource() {
    ! [ -f "$SCRIPTDIR/resources/$1" ] && prompt_resource "$1"
}

check_resources() {
    for resource in "$@"; do check_resource "$resource"; done
}

check_install() {
    local message="You are about to install OpenMPT $version. Continue?"
    p_fmt f_bold c_yellow
    p_tln
    p_tln "This script installs OpenMPT for the current user only."
    p_tln "If anyone else on this computer wants to have OpenMPT installed,"
    p_tln "they should run this script on their account as well."
    p_tln
    if ! [[ ":$PATH:" == *":$HOME/.local/bin:"* ]]; then
        p_fmt f_bold c_yellow; p_trw "You do not seem to have "
        p_fmt f_unbold c_cyan; p_trw "~/.local/bin"
        p_fmt f_bold c_yellow; p_tln " added to your PATH environment variable."
        p_tln "It is recommended to stop the script, add it, and run the script again."
        p_tln
    fi
    [ -f "$MPTDIR/.mptver" ] || [ -f "$MPTDIR/.mptchn" ] && existingversion=true && p_tln "Existing OpenMPT install found."
    if [ -f "$MPTDIR/.mptchn" ] && [ "$(< "$MPTDIR/.mptchn")" = "development" ] && [ "$channel" != "development" ]; then
        p_tln
        p_tln "WARNING:"
        p_tln "The currently installed version of OpenMPT is a development version,"
        p_tln "but the version you are about to install is a stable release."
        p_tln "Only continue the installation if the version you are about to install"
        p_tln "has a higher version number than the one currently installed."
        p_tln "Otherwise, please stop the script and run it again with the"
        p_tln "development channel instead."
        p_tln
    fi
    if [ -f "$MPTDIR/.mptver" ]; then
        if [ "$(< "$MPTDIR/.mptver")" = "$version" ]; then message="You already have OpenMPT $version installed. Install anyway?"
        else
            p_tln "The currently installed version is $(< "$MPTDIR/.mptver")."
        fi
    fi
    p_trw "$message"; p_fmt f_unbold c_reset; p_trw " (Y/n) "
    read response
    case $response in
        [Yy]|'') ;;
        [Nn])    cancel;;
        *)       p_fmt c_red && p_trw "Invalid response. " && cancel;;
    esac
    p_tln
}

get_start_time() {
    start_time="$(date +%s%3N)"
}

get_end_time() {
    end_time="$(date +%s%3N)"
}



# Script starts here

clear
startmessage
check_oldsetup
check_arg $1
check_deps ${DEPS[@]}
check_resources ${RESOURCES[@]}
get_latest_version $channel
check_install
get_start_time
download
prepare
install_openmpt_files
install_desktop_entry
install_launch_script
configure_wine
get_end_time
endmessage
quit
