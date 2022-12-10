# cs127's OpenMPT install script for Linux

This is a Bash script for simple installation of [OpenMPT](https://openmpt.org) on Linux (with [Wine](https://winehq.org)).

It also creates a desktop entry that can be accessed through your application menu, which you can open module files with, or even associate module files with it.

## Usage

### Install requirements
* Download `wine`, `jq`, `unzip`, and `curl` using your pckage manager. I will use pacman as an example.
```bash
sudo pacman -S wine jq unzip curl
```
If `sudo` is not installed, log in as root and install it. You will need `sudo` to run the script.

### Download the script

* Install Git using your package manager. I will use pacman as an example.
```bash
sudo pacman -S git
```
* Clone the repository to a directory where you want the script to be stored. I will choose `~/.mptinst` as an example.
```bash
git clone https://github.com/cs127/openmpt-install-script.git ~/.mptinst
```

When a newer version of the script is released, you can update by going to the script directory (`~/.mptinst` in my case) and pulling the repository:
```bash
cd ~/.mptinst
git pull
```

In case you can't clone the repository, you can just download the script
([openmpt-install.sh](https://raw.githubusercontent.com/cs127/openmpt-install-script/master/openmpt-install.sh))
by itself. It will automatically download the rest of the files in the repository after you run it.

### Run the script

* Go to the script's directory (e.g. `~/.mptinst`)
```bash
cd ~/.mptinst
```
* Make the script executable.
```bash
chmod +x openmpt-install.sh
```
* To install OpenMPT, run the script using sudo. You can optionally specify command-line options, and the download channel.
  In this example, I have enabled "auto mode (`-a` or `--auto`)". This causes the script to confirm everything without asking.
  I have also set the download channel to `development`.
```bash
sudo ./openmpt-install.sh -a development
```
* To uninstall OpenMPT, run the script using sudo, with the `-u` or `--uninstall` command-line option.
  In this example, I have also used auto mode as well.
```bash
sudo ./openmpt-install.sh -u -a
```

The command-line options are:
* `-h` or `--help`:      Show the help screen.
* `-u` or `--uninstall`: Uninstall OpenMPT instead of installing or updating.
* `-a` or `--auto`:      Auto mode (confirm everything without asking).
* `-p` or `--proxy`:     Download using a proxy. Followed by a valid proxy address.
* `--`:                  End of options.

Using multiple options in a single argument (e.g. `-au`) is not supported (yet).

The download channel can be one of the following:
* `release`:     current stable release.
* `next`:        preview of the next minor update.
* `development`: preview of the next major update.

If a download channel is not specified, the script will automatically choose 'release',
or the currently installed one if OpenMPT is already installed.

The download channel is ignored by the uninstall option.

### Other

To update OpenMPT, simply run the script again.
The download channel does not need to be specified.
The script will automatically use the same one that was used for the version that is already installed.

For command-line arguments of OpenMPT, read the comments in the beginning of the
[launch script](https://github.com/cs127/openmpt-install-script/blob/master/resources/openmpt).

For more instructions, read the text that is printed after installation.
