#!/usr/bin/bash

# cs127's OpenMPT install/update script for Linux
# version 0.1.0

# https://cs127.github.io



SCRIPTVER=0.1.0
DEPS=("wine" "curl" "jq" "unzip")

URL_SCRIPTRESOURCES="https://github.com/cs127/openmpt-install-script/raw/master/resources/"
URL_MPTAPI="https://update.openmpt.org/api/v3/update/"
URL_MPTICON="https://openmpt.org/img/logo256.png"

RESOURCES=("openmpt.desktop" "openmpt" "mptwine")
MPTDIR=$HOME/.openmpt
TMPDIR=$(mktemp -d)
BINDIR=$HOME/.local/bin
APPDIR=$HOME/.local/share/applications
ICODIR=$HOME/.local/share/icons

export WINEPREFIX=$MPTDIR/wine
export WINEDEBUG=-all

WINEAPPDATA=$WINEPREFIX/drive_c/users/$USER/AppData/Roaming

SCRIPT=$0
SCRIPTDIR="$(cd "$(dirname "$0")" && pwd)"

existingversion=false
uninstall=false
oldconfigdrive=""

channel=""
version=""
url_download32=""
url_download64=""

start_time=""
end_time=""



__RESETALL='\e[0m'
F_BOLD='\e[1m'
F_UNBOLD='\e[22m'
C_BLACK='\e[30m'
C_RED='\e[31m'
C_GREEN='\e[32m'
C_YELLOW='\e[33m'
C_BLUE='\e[34m'
C_MAGENTA='\e[35m'
C_CYAN='\e[36m'
C_WHITE='\e[37m'
C_RESET='\e[39m'



p_rw() {
    for ARG in "$@"; do echo -ne "$ARG"; done
}

p_ln() {
    p_rw "$@" "\n"
}

startmessage() {
    cd "$SCRIPTDIR"
    p_ln $F_BOLD $C_CYAN
    p_ln "cs127's OpenMPT install/update script for Linux"
    p_ln "version $SCRIPTVER"
    p_ln $C_MAGENTA "https://cs127.github.io" $C_CYAN
    p_ln "_______________________________________________"
    p_ln $F_UNBOLD $C_RESET
}

endmessage() {
    local time=""
    if ! [ -z "$start_time" ] && ! [ -z "$end_time" ] ; then
        local tr="$(($end_time-$start_time))"
        local tu="$(sed 's/...$/.&/' <<< $tr)"; time="$tu"
        [ $tr -lt 1000 ] && time="0$tu"
        [ $tr -lt 100  ] && time="0.0$tu"
        [ $tr -lt 10   ] && time="0.00$tu"
    fi
    p_rw $F_BOLD $C_CYAN
    p_ln "_______________________________________________"
    p_ln
    [ "$uninstall" != true ] &&
    p_ln $C_GREEN "Successfully installed OpenMPT $version." $C_CYAN ||
    p_ln $C_GREEN "Successfully uninstalled OpenMPT $version." $C_CYAN
    ! [ -z "$time" ] && p_ln "Total time spent: " $C_MAGENTA "$time" $C_CYAN " seconds."
    if [ "$existingversion" != true ] && [ "$uninstall" != true ]; then
        p_ln
        p_ln $C_CYAN "OpenMPT directory:        " $C_MAGENTA "${MPTDIR/~/"~"}/resources"
        p_ln $C_CYAN "32-bit exe:               " $C_MAGENTA "${MPTDIR/~/"~"}/resources/bin/x86/OpenMPT.exe"
        p_ln $C_CYAN "64-bit exe:               " $C_MAGENTA "${MPTDIR/~/"~"}/resources/bin/amd64/OpenMPT.exe"
        p_ln $C_CYAN "Wine directory:           " $C_MAGENTA "${WINEPREFIX/~/"~"}"
        p_ln $C_CYAN "OpenMPT config directory: " $C_MAGENTA "${WINEAPPDATA/~/"~"}/OpenMPT"
        p_ln $C_CYAN "Desktop entry:            " $C_MAGENTA "${APPDIR/~/"~"}/openmpt.desktop"
        p_ln $C_CYAN "Desktop icon:             " $C_MAGENTA "${ICODIR/~/"~"}/hicolor/256x256/apps/openmpt.png"
        p_ln $C_CYAN "Launch script:            " $C_MAGENTA "${BINDIR/~/"~"}/openmpt"
        p_ln $C_CYAN "Wine launch script:       " $C_MAGENTA "${BINDIR/~/"~"}/mptwine"
        p_ln $F_UNBOLD $C_MAGENTA
        p_ln "You can now launch OpenMPT from your application menu."
        p_ln "Associating file types with it are also possible."
        p_ln
        p_ln "If you have " $C_CYAN "${BINDIR/~/"~"}" $C_MAGENTA " in your PATH environment variable,"
        p_ln "you can run " $C_GREEN "openmpt" $C_MAGENTA " from the command line, and use " $C_GREEN "mptwine" $C_MAGENTA " as described below."
        p_ln
        p_ln "To configure basic Wine settings,  run " $C_GREEN "mptwine winecfg" $C_MAGENTA
        p_ln "To configure the registry in Wine, run " $C_GREEN "mptwine regedit" $C_MAGENTA
        p_ln "To manually configure Wine options, edit " $C_CYAN "${WINEPREFIX/~/"~"}/user.reg" $C_MAGENTA
        p_ln
        p_ln "You can choose whether to run the 32-bit or 64-bit OpenMPT executable"
        p_ln "by passing " $C_GREEN "MPTARCH=32" $C_MAGENTA " or " $C_GREEN "MPTARCH=64" $C_MAGENTA " as an environment variable."
        p_ln "Example: " $C_GREEN "MPTARCH=32 openmpt" $C_MAGENTA
        p_rw $F_UNBOLD $F_RESET
    fi
}

quit() {
    p_ln $F_UNBOLD $C_RESET
    rm -rf "$TMPDIR"
    exit $1
}

cancel() {
    p_rw $F_UNBOLD $C_RED
    [ "$uninstall" != true ] && p_ln "Installation canceled." || p_ln "Uninstallation canceled."
    p_rw $C_RESET
    quit 64
}

error_deps() {
    p_rw $F_BOLD $C_RED
    p_ln "The following dependencies are not installed:"
    for DEP in "$@"; do p_ln $C_RED "* " $C_WHITE "$DEP"; done
    p_ln $C_RED "Please install them using your package manager, and run this script again."
    p_rw $F_UNBOLD $C_RESET
}

error_oldsetup_installed() {
    p_rw $F_BOLD $C_RED
    p_ln "OpenMPT has already been installed using the official installer."
    p_ln "Please uninstall OpenMPT, and run this script again."
    p_ln "Your current OpenMPT settings will be kept intact,"
    p_ln "and you can choose whether to migrate them to the new install."
    p_ln
    p_rw $F_UNBOLD $C_YELLOW
    p_ln "After uninstalling, make sure that:"
    p_ln
    p_ln "* There are no desktop entries in " $C_CYAN "~/.local/share/applications/wine/OpenMPT" $C_YELLOW
    p_ln "  and " $C_CYAN "~/.config/menus/applications-merged" $C_YELLOW "."
    p_ln
    p_ln "* There are no OpenMPT file associations in " $C_CYAN "~/.local/share/mime/packages" $C_YELLOW ","
    p_ln "  such as " $C_CYAN "x-wine-extension-s3m.xml" $C_YELLOW "."
    p_rw "  If there are any, delete them and run " $C_GREEN "update-mime-database ~/.local/share/mime" $C_YELLOW
    p_rw $F_UNBOLD $C_RESET
}

error() {
    local status=$1
    case $status in
        1) p_ln $F_BOLD $C_RED "Invalid argument." $F_UNBOLD $C_RESET;;
        2) error_deps "${@:2}";;
        3) error_oldsetup_installed;;
        4) p_ln $F_BOLD $C_RED "Connection error." $F_UNBOLD $C_RESET;;
        5) p_ln $F_BOLD $C_RED "Server issued an error. The file probably does not exist." $F_UNBOLD $C_RESET;;
        6) p_ln $F_BOLD $C_RED "Unable to write file.";;
        7) p_ln $F_BOLD $C_RED "Corrupted file.";;
        8) p_ln $F_BOLD $C_RED "Unable to allocate enough memory.";;
        9) p_ln $F_BOLD $C_RED "Not enough disk space.";;
        *) p_ln $F_BOLD $C_RED "An error occured." $F_UNBOLD $C_RESET; status=127;;
    esac
    quit $status
}

checkstatus_curl() {
    local status=$1
    [ $status -eq 0 ] && p_ln $F_BOLD $C_GREEN "DONE" $F_UNBOLD $C_RESET && return
    p_ln $F_BOLD $C_RED "FAILED" $F_UNBOLD $C_RESET
    rm "$2"
    case $status in
        5|6|7|28|35|55|56) error 4;;
        22)                error 5;;
        23)                error 6;;
        18)                error 7;;
        27)                error 8;;
        *)                 error 127;;
    esac
}

checkstatus_unzip() {
    local status=$1
    [ $status -eq 0 ] && p_ln $F_BOLD $C_GREEN "DONE" $F_UNBOLD $C_RESET && return
    p_ln $F_BOLD $C_RED "FAILED" $F_UNBOLD $C_RESET
    rm "$2"
    case $status in
        1|2|3|12|51) error 7;;
        4|5|6|7)     error 8;;
        9)           error 9;;
        *)           error 127;;
    esac
}
checkstatus_fileop() {
    local status=$1
    [ $status -eq 0 ] && p_ln $F_BOLD $C_GREEN "DONE" $F_UNBOLD $C_RESET && return
    p_ln $F_BOLD $C_RED "FAILED" $F_UNBOLD $C_RESET
    error 6
}

download_file() {
    curl --fail -s "$1" -o "$2"
    checkstatus_curl $? "$2"
}

unzip_file() {
    unzip -q "$1" -d "$2"
    checkstatus_unzip $? "$1"
}

get_update_file() {
    p_rw $F_BOLD $C_WHITE "Getting latest OpenMPT version number ($1 channel)..."
    download_file "$URL_MPTAPI$1" "$TMPDIR/version.json"
}

get_latest_version() {
    get_update_file $1
    version=$(cat "$TMPDIR/version.json" | jq -r '.[].version')
    url_download32=$(cat "$TMPDIR/version.json" | jq -r '.[].downloads."portable-x86".download_url')
    url_download64=$(cat "$TMPDIR/version.json" | jq -r '.[].downloads."portable-amd64".download_url')
    rm "$TMPDIR/version.json"
}

download_32() {
    p_rw $F_BOLD $C_WHITE "Downloading OpenMPT $version (32-bit)..."
    download_file "$url_download32" "$TMPDIR/mpt32.zip"
}

download_64() {
    p_rw $F_BOLD $C_WHITE "Downloading OpenMPT $version (64-bit)..."
    download_file "$url_download64" "$TMPDIR/mpt64.zip"
}

download() {
    download_32 && download_64
}

extract_32() {
    mkdir "$TMPDIR/mpt32"
    p_rw $F_BOLD $C_WHITE "Extracting OpenMPT $version (32-bit)..."
    unzip_file "$TMPDIR/mpt32.zip" "$TMPDIR/mpt32"
}

extract_64() {
    mkdir "$TMPDIR/mpt64"
    p_rw $F_BOLD $C_WHITE "Extracting OpenMPT $version (64-bit)..."
    unzip_file "$TMPDIR/mpt64.zip" "$TMPDIR/mpt64"
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
    for FILE in *; do
        [ -d "$FILE" ] && (cd -- "$FILE" && merge_common_recurse) || check_diff "$(pwd)/$FILE"
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
    p_rw $F_BOLD $C_WHITE "Merging common files..."
    cd "$TMPDIR/mpt32"
    merge_common_recurse && cd "$SCRIPTDIR" && handle_pluginbridge &&
    p_ln $F_BOLD $C_GREEN "DONE" $F_UNBOLD $C_RESET && return
    p_ln $F_BOLD $C_RED "FAILED" $F_UNBOLD $C_RESET
    error 127
}

prepare() {
    extract_32 && extract_64
    rm "$TMPDIR/mpt32.zip" && rm "$TMPDIR/mpt64.zip"
    merge_common
    rm "$TMPDIR/mptcommon/OpenMPT.portable"
}

install_openmpt_files() {
    mkdir -p "$MPTDIR/resources"
    p_rw $F_BOLD $C_WHITE "Installing OpenMPT files..."
    cp -RT "$TMPDIR/mptcommon" "$MPTDIR/resources"
    checkstatus_fileop $?
    echo "$version" > "$MPTDIR/.mptver"
    echo "$channel" > "$MPTDIR/.mptchn"
}

install_desktop_entry() {
    mkdir -p "$APPDIR"
    p_rw $F_BOLD $C_WHITE "Installing desktop entry..."
    cp "$SCRIPTDIR/resources/openmpt.desktop" "$APPDIR"
    checkstatus_fileop $?
}

install_icon() {
    mkdir -p "$ICODIR/hicolor/256x256/apps"
    p_rw $F_BOLD $C_WHITE "Downloading icon for desktop entry..."
    download_file "$URL_MPTICON" "$ICODIR/hicolor/256x256/apps/openmpt.png"
}

install_launch_script() {
    mkdir -p "$BINDIR"
    p_rw $F_BOLD $C_WHITE "Installing launch script..."
    cp "$SCRIPTDIR/resources/openmpt" "$BINDIR" && cp "$SCRIPTDIR/resources/mptwine" "$BINDIR"
    checkstatus_fileop $?
    chmod +x "$BINDIR/openmpt" && chmod +x "$BINDIR/mptwine"
}

configure_wine() {
    p_rw $F_BOLD $C_WHITE "Configuring Wine..."
    wine chcp &>/dev/null
    p_ln $F_BOLD $C_GREEN "DONE" $F_UNBOLD $C_RESET
}

migrate_old_config() {
    mkdir -p "$WINEAPPDATA/OpenMPT"
    p_rw $F_BOLD $C_WHITE "Migrating old settings..."
    mv "$HOME/.wine/drive_$oldconfigdrive/users/$USER/AppData/Roaming/OpenMPT" "$WINEAPPDATA"
    checkstatus_fileop $?
}

uninstall_openmpt_files() {
    p_rw $F_BOLD $C_WHITE "Uninstalling OpenMPT files..."
    rm -rf "$MPTDIR/resources" "$MPTDIR/.mptver" "$MPTDIR/.mptchn"
    checkstatus_fileop $?
}

uninstall_desktop_entry() {
    p_rw $F_BOLD $C_WHITE "Uninstalling desktop entry..."
    rm "$APPDIR/openmpt.desktop"
    checkstatus_fileop $?
}

uninstall_icon() {
    p_rw $F_BOLD $C_WHITE "Uninstalling desktop icon..."
    rm "$ICODIR/hicolor/256x256/apps/openmpt.png"
    checkstatus_fileop $?
}

uninstall_launch_script() {
    p_rw $F_BOLD $C_WHITE "Uninstalling launch script..."
    rm "$BINDIR/openmpt" && rm "$BINDIR/mptwine"
    checkstatus_fileop $?
}

uninstall_wine_files() {
    mkdir -p "$WINEAPPDATA/OpenMPT"
    p_rw $F_BOLD $C_WHITE "Uninstalling Wine files..."
    mv "$WINEAPPDATA/OpenMPT" "$TMPDIR" &&
    rm -rf "$MPTDIR/wine"               &&
    mkdir -p "$WINEAPPDATA"             &&
    mv "$TMPDIR/OpenMPT" "$WINEAPPDATA"
    checkstatus_fileop $?
}

show_usage() {
    p_ln $F_BOLD $C_CYAN    "Usage:"
    p_ln $F_BOLD $C_MAGENTA "To install:   " $F_UNBOLD $C_GREEN "$SCRIPT " $C_CYAN "[channel]" $C_RESET
    p_ln $F_BOLD $C_MAGENTA "To uninstall: " $F_UNBOLD $C_GREEN "$SCRIPT "         "uninstall" $C_RESET
    p_ln
    p_ln $F_BOLD $C_CYAN    "Example:      " $F_UNBOLD $C_GREEN "$SCRIPT "         "development" $C_RESET
    p_ln
    p_ln "The download channel can be one of the following:"
    p_ln $C_GREEN  "'release':     current stable release."
    p_ln $C_YELLOW "'next':        preview of the next minor update."
    p_ln $C_RED    "'development': preview of the next major update."
    p_rw $C_RESET
}

check_deps() {
    local missingdeps=()
    local depexec=""
    for DEP in "$@"; do
        case $DEP in
            imagemagick) depexec="convert";;
            *)           depexec="$DEP";;
        esac
        ! command -v "$depexec" &>/dev/null && missingdeps+=("$DEP")
    done
    [ ${#missingdeps} -gt 0 ] && error 2 "${missingdeps[@]}"
}

check_uninstall() {
    local message="You are about to uninstall OpenMPT. Continue?"
    [ -f "$MPTDIR/.mptver" ] && version="$(< "$MPTDIR/.mptver")" && message="You are about to uninstall OpenMPT $version. Continue?"
    p_rw $F_BOLD $C_YELLOW
    if ! [ -d "$MPTDIR/resources" ] && ! [ -f "$APPDIR/openmpt.desktop" ] && ! [ -f "$BINDIR/openmpt" ]; then
        p_ln "OpenMPT is not installed."
        quit
    fi
    p_rw "$message" $F_UNBOLD $C_RESET " (Y/n) "
    read response
    case $response in
        [Yy]|'') ;;
        [Nn])    cancel;;
        *)       p_rw $C_RED "Invalid response. " && cancel;;
    esac
    p_ln
}

check_arg() {
    [ "$1" = "" ] && show_usage && quit
    [ "$1" = "uninstall" ] && uninstall=true && return
    [ "$1" != "release" ] && [ "$1" != "next" ] && [ "$1" != "development" ] && show_usage && error 1
    channel="$1"
}

check_oldsetup_installed() {
    [ -d $HOME/.local/share/applications/wine/Programs/OpenMPT ] ||
    ls $HOME/.config/menus/applications-merged/wine-Programs-OpenMPT-* 1> /dev/null 2>&1 &&
    error 3
    for DRIVE in {a..z}; do
        [ -f $HOME/.wine/drive_$DRIVE/Program\ Files/OpenMPT/bin/x86/OpenMPT.exe   ] ||
        [ -f $HOME/.wine/drive_$DRIVE/Program\ Files/OpenMPT/bin/amd64/OpenMPT.exe ] ||
        [ -f $HOME/.wine/drive_$DRIVE/Program\ Files/OpenMPT/OpenMPT.exe           ] ||
        [ -f $HOME/.wine/drive_$DRIVE/Program\ Files\ \(x86\)/OpenMPT/OpenMPT.exe  ] &&
        error 3
    done
}

prompt_oldsetup_config() {
    p_rw $F_UNBOLD $C_YELLOW
    p_ln "OpenMPT settings detected in default Wine directory (" $C_CYAN "~/.wine" $C_YELLOW ")."
    p_rw "Do you want to migrate your those settings to this install?" $F_UNBOLD $C_RESET " (Y/n) "
    read response
    case $response in
        [Yy]|'') oldconfigdrive="$1";;
        [Nn])    ;;
        *)       p_rw $C_RED "Invalid response. " && cancel;;
    esac
    p_ln
}

check_oldsetup_config() {
    for DRIVE in {a..z}; do
        [ -d $HOME/.wine/drive_$DRIVE/users/$USER/AppData/Roaming/OpenMPT ] && prompt_oldsetup_config "$DRIVE" && return
    done
}

get_resource() {
    p_rw $F_BOLD $C_WHITE "Downloading file..."
    download_file "$URL_SCRIPTRESOURCES$1" "$SCRIPTDIR/resources/$1"
}

prompt_resource() {
    p_rw $C_YELLOW
    p_ln "File '" $C_CYAN "$1" $C_YELLOW "' not found."
    p_rw "Do you want to download it from the GitHub repo?" $F_UNBOLD $C_RESET " (Y/n) "
    read response
    case $response in
        [Yy]|'') get_resource "$1";;
        [Nn])    cancel;;
        *)       p_rw $C_RED "Invalid response. " && cancel;;
    esac
}

check_resource() {
    ! [ -f "$SCRIPTDIR/resources/$1" ] && prompt_resource "$1"
}

check_resources() {
    mkdir -p "$SCRIPTDIR/resources"
    for RESOURCE in "$@"; do check_resource "$RESOURCE"; done
}

check_install() {
    local message="You are about to install OpenMPT $version. Continue?"
    p_ln $F_BOLD $C_YELLOW
    p_ln "This script installs OpenMPT for the current user only."
    p_ln "If anyone else on this computer wants to have OpenMPT installed,"
    p_ln "they should run this script on their account as well."
    p_ln
    if ! [[ ":$PATH:" == *":$HOME/.local/bin:"* ]]; then
        p_ln $F_BOLD $C_YELLOW "You do not seem to have " $F_UNBOLD $C_CYAN "~/.local/bin" $F_BOLD $C_YELLOW " added to your PATH environment variable."
        p_ln "It is recommended to stop the script, add it, and run the script again."
        p_ln
    fi
    [ -f "$MPTDIR/.mptver" ] || [ -f "$MPTDIR/.mptchn" ] && existingversion=true && p_ln "Existing OpenMPT install found."
    if [ -f "$MPTDIR/.mptchn" ] && [ "$(< "$MPTDIR/.mptchn")" = "development" ] && [ "$channel" != "development" ]; then
        p_ln
        p_ln "WARNING:"
        p_ln "The currently installed version of OpenMPT is a development version,"
        p_ln "but the version you are about to install is a stable release."
        p_ln "Only continue the installation if the version you are about to install"
        p_ln "has a higher version number than the one currently installed."
        p_ln "Otherwise, please stop the script and run it again with the"
        p_ln "development channel instead."
        p_ln
    fi
    if [ -f "$MPTDIR/.mptver" ]; then
        if [ "$(< "$MPTDIR/.mptver")" = "$version" ]; then message="You already have OpenMPT $version installed. Install anyway?"
        else
            p_ln "The currently installed version is $(< "$MPTDIR/.mptver")."
        fi
    fi
    p_rw "$message" $F_UNBOLD $C_RESET " (Y/n) "
    read response
    case $response in
        [Yy]|'') ;;
        [Nn])    cancel;;
        *)       p_rw $C_RED "Invalid response. " && cancel;;
    esac
    p_ln
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
check_oldsetup_installed
check_arg $1
if [ "$uninstall" = true ]; then
    check_uninstall
    get_start_time
    uninstall_openmpt_files
    uninstall_desktop_entry
    uninstall_icon
    uninstall_launch_script
    uninstall_wine_files
    get_end_time
else
    check_deps ${DEPS[@]}
    check_resources ${RESOURCES[@]}
    check_oldsetup_config
    get_latest_version $channel
    check_install
    get_start_time
    download
    prepare
    install_openmpt_files
    install_desktop_entry
    install_icon
    install_launch_script
    configure_wine
    ! [ -z "$oldconfigdrive" ] && migrate_old_config
    get_end_time
fi
endmessage
quit
