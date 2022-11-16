# cs127's OpenMPT install script for Linux

This is a Bash script for simple installation of [OpenMPT](https://openmpt.org) on Linux (with [Wine](https://winehq.org)).

It also creates a desktop entry that can be accessed through your application menu, which you can open module files with, or even associate module files with it.

## Usage

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
* To install OpenMPT, run the script followed by the name of the update channel. I will use `development` as an example.
```bash
./openmpt-install.sh development
```
* To uninstall OpenMPT, run the script followed by the word `uninstall`.
```bash
./openmpt-install.sh uninstall
```
The download channel can be one of the following:
* `release`: current stable release.
* `next`: preview of the next minor update.
* `development`: preview of the next major update.

To update OpenMPT, simply run the script again.

For command-line arguments of OpenMPT, read the comments in the beginning of the
[launch script](https://github.com/cs127/openmpt-install-script/blob/master/resources/openmpt).

For more instructions, read the text that is printed after installation.
