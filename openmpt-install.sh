#!/bin/bash

# cs127's OpenMPT install/update script for Linux
# version 0.4.0

# https://cs127.github.io



SCRIPTVER=0.4.0
DEPS_COMMON=()
DEPS_INSTALL=("wine" "curl" "jq" "unzip")
DEPS_UNINSTALL=()

URL_SCRIPTRESOURCES="https://github.com/cs127/openmpt-install-script/raw/master/resources/"
URL_MPTAPI="https://update.openmpt.org/api/v3/update/"
URL_MPTICON="https://openmpt.org/img/logo256.png"

RESOURCES=("openmpt.desktop" "openmpt" "mptwine" "wine_config.reg")

MPTDIR=/opt/openmpt
TMPDIR=$(mktemp -d)
BINDIR=/usr/bin
APPDIR=/usr/share/applications
ICODIR=/usr/share/icons

SCRIPT=$0
SCRIPTDIR="$(cd "$(dirname "$0")" && pwd)"

usernames=()
userhomes=()

existingversion=false
automode=false
uninstall=false
oldconfigusernames=()
oldconfiguserhomes=()

downgrade=false

proxy=""
channel=""
defaultchannel="release"
version=""
url_download32=""
url_download64=""

start_time=""
end_time=""
time=""



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



p_rw() { for ARG in "$@"; do echo -ne "$ARG"; done; }

p_ln() { p_rw "$@" "\n"; }

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

initialize() {
    IFS="\\" read -r -a usernames <<< "$(getent passwd | awk -F: '{if ($3 >= 1000) printf "%s\\", $1}')"
    IFS="\\" read -r -a userhomes <<< "$(getent passwd | awk -F: '{if ($3 >= 1000) printf "%s\\", $6}')"
    cd "$SCRIPTDIR";
}

startmessage() {
    p_ln $F_BOLD $C_CYAN
    p_ln "cs127's OpenMPT install/update script for Linux"
    p_ln "version $SCRIPTVER"
    p_ln $C_MAGENTA "https://cs127.github.io" $C_CYAN
    p_ln "_______________________________________________"
    p_ln $F_UNBOLD $C_RESET
}

endmessage() {
    ! [ -z "$start_time" ] && ! [ -z "$end_time" ] &&
    time=$(echo "$start_time $end_time" | awk '{printf "%.3f\n", ($2-$1)/1000}')
    p_rw $F_BOLD $C_CYAN
    p_ln "_______________________________________________"
    p_ln
    [ "$uninstall" != true ] &&
    p_ln $C_GREEN "Successfully installed OpenMPT $version." $C_CYAN ||
    p_ln $C_GREEN "Successfully uninstalled OpenMPT $version." $C_CYAN
    ! [ -z "$time" ] && p_ln "Total time spent: " $C_MAGENTA "$time" $C_CYAN " seconds."
    if [ "$existingversion" != true ] && [ "$uninstall" != true ]; then
        p_ln
        p_ln $C_CYAN "OpenMPT directory:        " $C_MAGENTA "${MPTDIR}"
        p_ln $C_CYAN "32-bit exe:               " $C_MAGENTA "${MPTDIR}/bin/x86/OpenMPT.exe"
        p_ln $C_CYAN "64-bit exe:               " $C_MAGENTA "${MPTDIR}/bin/amd64/OpenMPT.exe"
        p_ln $C_CYAN "Wine directory:           " $C_MAGENTA "~/.wine-openmpt"
        p_ln $C_CYAN "OpenMPT config directory: " $C_MAGENTA "~/.wine-openmpt/drive_c/users/$USER/AppData/Roaming"
        p_ln $C_CYAN "Desktop entry:            " $C_MAGENTA "${APPDIR}/openmpt.desktop"
        p_ln $C_CYAN "Desktop icon:             " $C_MAGENTA "${ICODIR}/hicolor/256x256/apps/openmpt.png"
        p_ln $C_CYAN "Launch script:            " $C_MAGENTA "${BINDIR}/openmpt"
        p_ln $C_CYAN "Wine launch script:       " $C_MAGENTA "${BINDIR}/mptwine"
        p_ln $F_UNBOLD $C_MAGENTA
        p_ln "You can now launch OpenMPT from your application menu,"
        p_ln "or by typing " $C_GREEN  "openmpt" $C_MAGENTA " in the command line."
        p_ln "Associating file types with the application are also possible."
        p_ln
        p_ln "To update OpenMPT to a newer version, simply run this script again."
        p_ln
        p_ln "To run a Wine program with OpenMPT's Wine directory, use " $C_GREEN "mptwine" $C_MAGENTA
        p_ln "Example: " $C_GREEN "mptwine cmd.exe" $C_MAGENTA
        p_ln
        p_ln "To configure basic Wine settings,  run " $C_GREEN "mptwine winecfg" $C_MAGENTA
        p_ln "To configure the registry in Wine, run " $C_GREEN "mptwine regedit" $C_MAGENTA
        p_ln "To manually configure Wine options, edit " $C_CYAN "~/.wine-openmpt/user.reg" $C_MAGENTA
        p_ln
        p_ln "You can choose whether to run the 32-bit or 64-bit OpenMPT executable"
        p_ln "by passing " $C_GREEN "MPTARCH=32" $C_MAGENTA " or " $C_GREEN "MPTARCH=64" $C_MAGENTA " as an environment variable."
        p_ln "Example: " $C_GREEN "MPTARCH=32 openmpt" $C_MAGENTA
        p_rw $F_UNBOLD $F_RESET
    fi
}

error_deps() {
    p_rw $F_BOLD $C_RED
    p_ln "The following dependencies are not installed:"
    for DEP in "$@"; do p_ln $C_RED "* " $C_WHITE "$DEP"; done
    p_ln $C_RED "Please install them using your package manager, and run this script again."
    p_rw $F_UNBOLD $C_RESET
}

error_oldsetup_installed() {
    local NAME="$1"
    p_rw $F_BOLD $C_RED
    p_ln "OpenMPT has already been installed for ${NAME} using the official installer."
    p_ln "Please uninstall OpenMPT on their account, and run this script again."
    p_ln "The current OpenMPT settings will be kept intact,"
    p_ln "and you can choose whether to migrate them to the new install."
    p_ln
    p_rw $F_UNBOLD $C_YELLOW
    p_ln "After uninstalling, make sure that:"
    p_ln
    p_ln "* There are no OpenMPT-related files in " $C_CYAN "~/.local/share/applications/wine" $C_YELLOW ", "
    p_ln "  " $C_CYAN "~/.config/menus/applications-merged" $C_YELLOW ", and " $C_CYAN "~/.local/share/desktop-directories" $C_YELLOW "."
    p_ln
    p_ln "* There are no OpenMPT file associations in " $C_CYAN "~/.local/share/mime/packages" $C_YELLOW ","
    p_ln "  such as " $C_CYAN "x-wine-extension-s3m.xml" $C_YELLOW "."
    p_rw "  If there are, delete them and run " $C_GREEN "update-mime-database ~/.local/share/mime" $C_YELLOW
    p_ln $F_UNBOLD $C_RESET
}

error_v01_installed() {
    local NAME="$1"
    p_rw $F_BOLD $C_RED
    p_ln "An old local OpenMPT setup has been detected in ${NAME}'s account,"
    p_ln "that was most likely installed using version 0.1 or 0.0 of this script."
    p_ln
    p_rw $F_UNBOLD $C_YELLOW
    p_ln "In order to install OpenMPT with the current version of the script,"
    p_ln "uninstall OpenMPT on their account first, by running"
    p_ln $C_GREEN "$SCRIPT uninstall" $C_YELLOW
    p_ln "on their account, with version 0.1 or 0.0 of this script."
    p_ln $F_UNBOLD $C_RESET
}

error() {
    local status=$1
    case $status in
        1)  p_ln $F_BOLD $C_RED "Invalid argument '$2'.";;
        2)  error_deps "${@:2}";;
        3)  p_ln $F_BOLD $C_RED "Proxy connection error.";;
        4)  p_ln $F_BOLD $C_RED "Connection error.";;
        5)  p_ln $F_BOLD $C_RED "Server issued an error. The file probably does not exist.";;
        6)  p_ln $F_BOLD $C_RED "Unable to write file.";;
        7)  p_ln $F_BOLD $C_RED "Corrupted file.";;
        8)  p_ln $F_BOLD $C_RED "Unable to allocate enough memory.";;
        9)  p_ln $F_BOLD $C_RED "Not enough disk space.";;
        16) error_oldsetup_installed "${@:2}";;
        17) error_v01_installed "${@:2}";;
        20) p_ln $F_BOLD $C_RED "Invalid download channel '$2'.";;
        24) p_ln $F_BOLD $C_RED "Proxy address not specified.";;
        25) p_ln $F_BOLD $C_RED "Invalid proxy address '$2'.";;
        32) p_ln $F_BOLD $C_RED "The script should be run with root privileges.";;
        *)  p_ln $F_BOLD $C_RED "An error occured."; status=127;;
    esac
    quit $status
}

checkstatus_curl() {
    local status=$1
    [ $status -eq 0 ] && p_ln $F_BOLD $C_GREEN "DONE" $F_UNBOLD $C_RESET && return
    p_ln $F_BOLD $C_RED "FAILED" $F_UNBOLD $C_RESET
    [ -f "$2" ] && rm "$2"
    case $status in
        97)                error 3;;
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
    if [ -z "$proxy" ]; then
        curl --fail -s "$1" -o "$2"
    elif ! [ -z "$proxy" ]; then
        curl --fail -x "$proxy" -s "$1" -o "$2"
    fi
    checkstatus_curl $? "$2"
}

unzip_file() {
    unzip -q "$1" -d "$2"
    checkstatus_unzip $? "$1"
}

get_latest_version() {
    p_rw $F_BOLD $C_WHITE "Getting latest OpenMPT version number ($1 channel)..."
    download_file "$URL_MPTAPI$1" "$TMPDIR/version.json"
    version=$(cat "$TMPDIR/version.json" | jq -r '.[].version')
    url_download32=$(cat "$TMPDIR/version.json" | jq -r '.[].downloads."portable-x86".download_url')
    url_download64=$(cat "$TMPDIR/version.json" | jq -r '.[].downloads."portable-amd64".download_url')
    rm "$TMPDIR/version.json"
}

download() {
    p_rw $F_BOLD $C_WHITE "Downloading OpenMPT $version (32-bit)..."
    download_file "$url_download32" "$TMPDIR/mpt32.zip"
    p_rw $F_BOLD $C_WHITE "Downloading OpenMPT $version (64-bit)..."
    download_file "$url_download64" "$TMPDIR/mpt64.zip"
}

extract() {
    mkdir "$TMPDIR/mpt32"
    mkdir "$TMPDIR/mpt64"
    p_rw $F_BOLD $C_WHITE "Extracting OpenMPT $version (32-bit)..."
    unzip_file "$TMPDIR/mpt32.zip" "$TMPDIR/mpt32"
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
    extract
    rm "$TMPDIR/mpt32.zip" && rm "$TMPDIR/mpt64.zip"
    merge_common
    rm "$TMPDIR/mptcommon/OpenMPT.portable"
}

install_openmpt_files() {
    mkdir -p "$MPTDIR"
    p_rw $F_BOLD $C_WHITE "Installing OpenMPT files..."
    cp -RT "$TMPDIR/mptcommon" "$MPTDIR"
    checkstatus_fileop $?
    echo "$version" > "$MPTDIR/.mptver"
    echo "$channel" > "$MPTDIR/.mptchn"
    cp "$SCRIPTDIR/resources/wine_config.reg" "$MPTDIR"
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
    chmod +x "$BINDIR/openmpt"
    chmod +x "$BINDIR/mptwine"
}

configure_wine() {
    p_rw $F_BOLD $C_WHITE "Configuring Wine..."
    wine regedit "$SCRIPTDIR/resources/wine_config.reg" &>/dev/null
    p_ln $F_BOLD $C_GREEN "DONE" $F_UNBOLD $C_RESET
}

migrate_old_config() {
    for i in "${!oldconfigusernames[@]}"; do
        local NAME="${oldconfigusernames[$i]}"
        local HOME="${oldconfiguserhomes[$i]}"
        local OLDDATA="${HOME}/.wine/drive_c/users/${NAME}/AppData/Roaming/OpenMPT"
        local NEWDATA="${OLDDATA/".wine"/".wine-openmpt"}"
        mkdir -p "$NEWDATA"
        p_rw $F_BOLD $C_WHITE "Migrating old settings for ${NAME}..."
        mv "$OLDDATA" "$NEWDATA"
        checkstatus_fileop $?
    done
}

uninstall_openmpt_files() {
    p_rw $F_BOLD $C_WHITE "Uninstalling OpenMPT files..."
    rm -rf "$MPTDIR"
    checkstatus_fileop $?
}

uninstall_desktop_entry() {
    p_rw $F_BOLD $C_WHITE "Uninstalling desktop entry..."
    rm -f "$APPDIR/openmpt.desktop"
    checkstatus_fileop $?
}

uninstall_icon() {
    p_rw $F_BOLD $C_WHITE "Uninstalling desktop icon..."
    rm -f "$ICODIR/hicolor/256x256/apps/openmpt.png"
    checkstatus_fileop $?
}

uninstall_launch_script() {
    p_rw $F_BOLD $C_WHITE "Uninstalling launch script..."
    rm -f "$BINDIR/openmpt" "$BINDIR/mptwine"
    checkstatus_fileop $?
}

show_usage() {
    p_ln $F_BOLD $C_CYAN    "Usage:"
    p_ln $F_UNBOLD $C_GREEN "$SCRIPT " $C_CYAN "[options] [channel]" $C_RESET
    p_ln
    p_ln $F_BOLD $C_CYAN    "Examples:"
    p_ln $F_UNBOLD $C_GREEN "$SCRIPT"                                           $C_RESET
    p_ln $F_UNBOLD $C_GREEN "$SCRIPT -a -p socks5://127.0.0.1:1234 development" $C_RESET
    p_ln $F_UNBOLD $C_GREEN "$SCRIPT -u"                                        $C_RESET
    p_ln
    p_ln $F_BOLD $C_CYAN    "Options:"
    p_ln $F_UNBOLD $C_GREEN "-h" $C_RESET " | " $C_GREEN "--help     " $C_RESET "    Help (show this screen)."
    p_ln $F_UNBOLD $C_GREEN "-u" $C_RESET " | " $C_GREEN "--uninstall" $C_RESET "    Uninstall OpenMPT instead of installing or updating."
    p_ln $F_UNBOLD $C_GREEN "-a" $C_RESET " | " $C_GREEN "--auto     " $C_RESET "    Auto mode (confirm everything without asking)."
    p_ln $F_UNBOLD $C_GREEN "-p" $C_RESET " | " $C_GREEN "--proxy    " $C_RESET "    Download using a proxy. Followed by a valid proxy address."
    p_ln $F_UNBOLD $C_GREEN "--" $C_RESET "   " $C_GREEN "           " $C_RESET "    End of options."
    p_ln
    p_ln $F_BOLD $C_CYAN    "Download channel:" $F_UNBOLD
    p_ln $C_GREEN  "'release':     current stable release."           $C_RESET
    p_ln $C_YELLOW "'next':        preview of the next minor update." $C_RESET
    p_ln $C_RED    "'development': preview of the next major update." $C_RESET
    p_ln "If a download channel is not specified, the script will automatically choose"
    p_ln "'release', or the currently installed one if OpenMPT is already installed."
    p_ln "The download channel is ignored by the uninstall option."
}

check_root() {
    [ "$EUID" -ne 0 ] && error 32
}

check_deps() {
    local missingdeps=()
    for DEP in "$@"; do ! command -v "$DEP" &>/dev/null && missingdeps+=("$DEP"); done
    [ ${#missingdeps} -gt 0 ] && error 2 "${missingdeps[@]}"
}

check_uninstall() {
    [ -f "$MPTDIR/.mptver" ] && version="$(< "$MPTDIR/.mptver")"
    p_rw $F_BOLD $C_YELLOW
    if ! [ -d "$MPTDIR" ] && ! [ -f "$APPDIR/openmpt.desktop" ] && ! [ -f "$BINDIR/openmpt" ] ; then
        p_ln "OpenMPT is not installed."
        quit
    fi
    if [ "$automode" = true ]; then
        [ -z "$version" ] &&
        p_ln "Uninstalling OpenMPT." ||
        p_ln "Uninstalling OpenMPT $version."
    else
        ! [ -z "$version" ] &&
        p_rw "You are about to uninstall OpenMPT. Continue?" ||
        p_rw "You are about to uninstall OpenMPT $version. Continue?"
        p_rw $F_UNBOLD $C_RESET " (Y/n) "
        read response
        case $response in
            [Yy]|'') ;;
            [Nn])    cancel;;
            *)       p_rw $C_RED "Invalid response. " && cancel;;
        esac
        p_ln
    fi
}

auto_channel() {
    p_rw $F_BOLD $C_YELLOW
    p_ln "No download channel specified."
    if [ -f "$MPTDIR/.mptchn" ]; then
        channel="$(< "$MPTDIR/.mptchn")"
        p_ln "Defaulting to the currently installed channel ('$channel')."
    else
        channel="$defaultchannel"
        p_ln "Defaulting to '$channel'."
    fi
    p_ln $F_UNBOLD $C_RESET
}

parse_arg_proxy() {
    [[ -z "$1" ]] && error 24;
    local regex='(socks4a?|socks5h?|https?):\/\/.*'
    [[ $1 =~ $regex ]] && proxy="$1" || error 25 "$1";
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_usage
                quit
            ;;
            -u|--uninstall)
                uninstall=true
                shift
            ;;
            -a|--auto)
                automode=true
                shift
            ;;
            -p|--proxy)
                parse_arg_proxy "$2"
                shift;shift
            ;;
            --)
                shift;
                ARGS=("$@")
                break
            ;;
            -*|--*)
                error 1 "$1"
            ;;
            *)
                ARGS+=("$1")
                break
            ;;
        esac
    done
    set -- "${ARGS[@]}"
    if [ "$uninstall" != true ]; then
        [ -z "$1" ] && auto_channel && return
        [ "$1" != "release"     ] &&
        [ "$1" != "next"        ] &&
        [ "$1" != "development" ] &&
        error 20 "$1" || channel="$1"
    fi
}

check_oldsetup_installed() {
    for i in "${!usernames[@]}"; do
        local NAME=${usernames[$i]}
        local HOME=${userhomes[$i]}
        [ -d $HOME/.local/share/applications/wine/Programs/OpenMPT ] ||
        ls $HOME.config/menus/applications-merged/wine-Programs-OpenMPT-* 1> /dev/null 2>&1 ||
        [ -f $HOME/.local/share/desktop-directories/wine-Programs-OpenMPT.directory ] ||
        [ -f $HOME/.wine/drive_c/Program\ Files/OpenMPT/bin/x86/OpenMPT.exe   ] ||
        [ -f $HOME/.wine/drive_c/Program\ Files/OpenMPT/bin/amd64/OpenMPT.exe ] ||
        [ -f $HOME/.wine/drive_c/Program\ Files/OpenMPT/OpenMPT.exe           ] ||
        [ -f $HOME/.wine/drive_c/Program\ Files\ \(x86\)/OpenMPT/OpenMPT.exe  ] &&
        error 16 "$NAME"
    done
}

prompt_oldsetup_config() {
    local NAME="$1"
    local HOME="$2"
    p_rw $F_UNBOLD $C_YELLOW
    p_ln "OpenMPT settings detected in ${NAME}'s default Wine directory (" $C_CYAN "${HOME}/.wine" $C_YELLOW ")."
    if [ "$automode" = true ]; then
        p_ln "They will be migrated to this install."
        oldconfigusernames+=("$NAME")
        oldconfiguserhomes+=("$HOME")
    else
        p_rw "Do you want to migrate them to this install?" $F_UNBOLD $C_RESET " (Y/n) "
        read response
        case $response in
            [Yy]|'') oldconfigusernames+=("$NAME");oldconfiguserhomes+=("$HOME");;
            [Nn])    ;;
            *)       p_rw $C_RED "Invalid response. " && cancel;;
        esac
        p_ln
    fi
}

check_oldsetup_config() {
    for i in "${!usernames[@]}"; do
        local NAME="${usernames[$i]}"
        local HOME="${userhomes[$i]}"
        [ -d $HOME/.wine/drive_c/users/$NAME/AppData/Roaming/OpenMPT ] &&
        prompt_oldsetup_config "$NAME" "$HOME"
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

check_v01_installed() {
    for i in "${!usernames[@]}"; do
        local NAME="${usernames[$i]}"
        local HOME="${userhomes[$i]}"
        [ -d "$HOME/.openmpt/resources"                                  ] ||
        [ -f "$HOME/.openmpt/.mptver"                                    ] ||
        [ -f "$HOME/.openmpt/.mptchn"                                    ] ||
        [ -f "$HOME/.local/bin/openmpt"                                  ] ||
        [ -f "$HOME/.local/bin/mptwine"                                  ] ||
        [ -f "$HOME/.local/share/icons/hicolor/256x256/apps/openmpt.png" ] &&
        error 17 "$NAME"
    done
}

check_install() {
    [ -f "$MPTDIR/.mptver" ] && existingversion=true
    p_ln $F_BOLD $C_YELLOW
    if [ "$automode" = true ]; then
        local message="Installing OpenMPT $version."
        if [ -f "$MPTDIR/.mptchn" ] && [ "$(< "$MPTDIR/.mptchn")" = "development" ] && [ "$channel" != "development" ]; then
            p_ln "The currently installed version of OpenMPT is a development version,"
            p_ln "but the version you are about to install is a stable release."
            p_ln "Aborting installation."
            p_ln
            cancel
        elif [ "$existingversion" = true ]; then
            p_ln "Existing OpenMPT install found."
            if [ "$(< "$MPTDIR/.mptver")" = "$version" ]; then
                message="OpenMPT $version is already installed. Reinstalling."
            else
                p_ln "The currently installed version is $(< "$MPTDIR/.mptver")."
            fi
        fi
        p_ln "$message"
        p_ln
    else
        local message="You are about to install OpenMPT $version. Continue?"
        if [ -f "$MPTDIR/.mptchn" ] && [ "$(< "$MPTDIR/.mptchn")" = "development" ] && [ "$channel" != "development" ]; then
            downgrade=true
            p_ln "WARNING:"
            p_ln "The currently installed version of OpenMPT is a development version,"
            p_ln "but the version you are about to install is a stable release."
            p_ln "Only continue the installation if the version you are about to install"
            p_ln "has a higher version (NOT revision) number than the one currently installed."
            p_ln "Otherwise, please stop the script and run it again with the"
            p_ln "development channel instead."
            p_ln
        fi
        if [ "$existingversion" = true ]; then
            p_ln "Existing OpenMPT install found."
            if [ "$(< "$MPTDIR/.mptver")" = "$version" ]; then
                message="You already have OpenMPT $version installed. Install anyway?"
            else
                p_ln "The currently installed version is $(< "$MPTDIR/.mptver")."
            fi
        fi
        p_rw "$message" $F_UNBOLD $C_RESET
        [ "$downgrade" != true ] && p_rw " (Y/n) " || p_rw " (y/N) "
        read response
        case $response in
            [Yy])  ;;
            [Nn])  cancel;;
            '')    [ "$downgrade" = true ] && cancel;;
            *)     p_rw $C_RED "Invalid response. " && cancel;;
        esac
        p_ln
    fi
}

get_start_time() { start_time="$(date +%s%3N)"; }

get_end_time() { end_time="$(date +%s%3N)"; }



# Script starts here

initialize
startmessage
parse_args "$@"
check_root
check_oldsetup_installed
if [ "$uninstall" = true ]; then
    check_deps ${DEPS_COMMON[@]} ${DEPS_UNINSTALL[@]}
    check_uninstall
    get_start_time
    uninstall_openmpt_files
    uninstall_desktop_entry
    uninstall_icon
    uninstall_launch_script
    get_end_time
else
    check_deps ${DEPS_COMMON[@]} ${DEPS_INSTALL[@]}
    check_resources ${RESOURCES[@]}
    check_v01_installed
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
    migrate_old_config
    get_end_time
fi
endmessage
quit
