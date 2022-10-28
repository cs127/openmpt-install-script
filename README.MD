# cs127's OpenMPT install script for Linux

This is a Bash script for simple installation of [OpenMPT](https://openmpt.org) on Linux (with [Wine](https://winehq.org)).

It also creates a desktop entry that can be accessed through your application menu, which you can open module files with, or even associate module files with it.

## Usage

### Download the script

* Install Git using your package manager. I will use pacman as an example.
```bash
sudo pacman -S git
```
* Clone the repository
```bash
git clone https://github.com/cs127/openmpt-install-script.git
cd openmpt-install-script
```

In case you can't clone the repository, you can just download the script
([openmpt-install.sh](https://raw.githubusercontent.com/cs127/openmpt-install-script/master/openmpt-install.sh))
by itself.

It will automatically download the rest of the files in the repository after you run it.

### Run the script

* Make the script executable.
```bash
chmod +x install-openmpt.sh
```
* To install OpenMPT, run the script followed by the name of the update channel. I will use `development` as an example.
```bash
./install-openmpt.sh development
```
* To uninstall OpenMPT, run the script followed by the word `uninstall`.
```bash
./install-openmpt.sh uninstall
```
The download channel can be one of the following:
* `release`: current stable release.
* `next`: preview of the next minor update.
* `development`: preview of the next major update.

For command-line arguments of OpenMPT, read the comments in the beginning of the
[launch script](https://github.com/cs127/openmpt-install-script/blob/master/resources/openmpt).

For more instructions, read the text that is printed after installation.
