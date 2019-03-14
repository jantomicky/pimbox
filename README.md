# Pimbox

**Work in progress!** Some features are not implemented out of the box yet (Mailhog, Redis…), do not use the box if you're not willing to set these up by yourself in the meantime.

Pimbox is a [Vagrant](https://www.vagrantup.com) box made specifically for running [Pimcore 5](https://pimcore.com). With corresponding PHP version installed (PHP 5.6 for Pimcore 2, PHP 7.0 for Pimcore 4) it can run older versions as well. It is supposed to serve as a replacement for LAMP/WAMP localhost packages, however per-project installation should work too.

Thanks to everybody behind [Laravel Homestead](https://github.com/laravel/homestead)! Pimbox uses a few Homestead snippets that helped me understand how Vagrant and Ruby work, and how to make this box easier to use.

## Features

### Packages

- Apache & MySQL, versions, modules, settings for [Pimcore 5](https://pimcore.com/docs/5.x/Development_Documentation/Installation_and_Upgrade/System_Requirements.html)
- PHP 7.2 (FPM, FastCGI)
- Composer
- Java Runtime Environment 8

### Bash
- A few handy aliases and helper functions, see the `bash_aliases` file.

## Requirements
- Vagrant alongside a supported VM provider, for example [VirtualBox](https://www.virtualbox.org/).
- (Recommended) Vagrant [vagrant-bindfs](https://github.com/gael-ian/vagrant-bindfs) plugin:
```
vagrant plugin install vagrant-bindfs
```
- (Recommended, Windows) Vagrant [WinNFSd](https://github.com/winnfsd/winnfsd) plugin:
```
vagrant plugin install vagrant-winnfsd
```

## Setup

- Clone the Pimbox repository:
```
git clone git@github.com:jantomicky/pimbox.git /path/to/pimbox
```
- Where `/path/to/pimbox` is the directory the box configuration and "interface" will live in. To issue Vagrant commands like `vagrant up`, you either `cd` into this directory or you set up a helper function in your `~/.bashrc` or `~/.bash_aliases` files (see below).
- Run the initialization script:
```
/bin/bash init.sh
```
- Change your preferences in the `Pimbox.yaml` file, refer to the defaults. Duplicate list items (_folders_, _copy_, _run…_) if needed.
- (Optional, Linux) Set up a helper function:
```
vm() {
    vm="/path/to/$1"
    if [ ! -d $vm ]; then
        echo "Can't find the VM!"
    else
        ( cd $vm && vagrant "${@:2}" )
    fi
}
```
- Where `$1` is the first argument of your `vm` function, in our case it's `pimbox`. The function runs `cd` into the Pimbox folder for you and then executes the `vagrant` command with the rest of your passed arguments. Example:
```
vm pimbox reload --provision
```
- Run (without helper function set up):
```
cd /path/to/pimbox
vagrant up
```
- Or (with helper function set up):
```
vm pimbox up
```
- When the initial provisioning finishes, you should be able to SSH into the VM:
```
vagrant ssh
```
- Or, again, with the helper function set up:
```
vm pimbox ssh
```


## Tips

### General

- Use NFS for sharing folders, really helps with performance.

### Windows

- Exclude your defined shared folders from the Windows Defender scans to prevent I/O errors.
- When running `npm install` it may be necessary to add `--no-bin-links` parameter as Windows won't handle symlinks properly.

### Linux
- You might need to install the `net-tools` package on Arch-based distributions for the NFS to work.

## Work in progress
- Mailhog
- Elasticsearch
- Redis