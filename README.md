# Pimbox

**Work in progress!** Some features are not implemented out of the box yet (Mailhog), do not use the box if you're not willing to set these up by yourself.

Pimbox is a [Vagrant](https://www.vagrantup.com) box made specifically for running [Pimcore 5](https://pimcore.com) and above. With corresponding PHP version installed (PHP 5.6 for Pimcore 2, PHP 7.0 for Pimcore 4) it should be able to run older versions as well. It is supposed to serve as a replacement for LAMP/WAMP localhost packages, however per-project installation should work too.

Thanks to everybody behind [Laravel Homestead](https://github.com/laravel/homestead)! Pimbox uses a few Homestead snippets that helped me understand how Vagrant and Ruby work, and how to make this box easier to use.

## Features

### Packages

- Apache & MySQL, versions, modules, settings for >= [Pimcore 5](https://pimcore.com/docs/5.x/Development_Documentation/Installation_and_Upgrade/System_Requirements.html).
- PHP (FPM, FastCGI, 7.0 + 7.2 scripts available for provisioning).
- Composer & Deployer.
- Redis (server, CLI).
- Elasticsearch (very specific, customized 1.0.0 and 1.7.6 versions for my personal use, probably of no use to anyone else).
- Java Runtime Environment 8 (for Elasticsearch).

### Bash

- A few handy aliases, helper functions and settings, see the `bash_aliases` file.

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
- (Optional) Vagrant [vagrant-disksize](https://github.com/sprotheroe/vagrant-disksize) plugin, if you need to set your own disk size:
```
vagrant plugin install vagrant-disksize
```

## Setup

- Clone the Pimbox repository:
```
git clone git@github.com:jantomicky/pimbox.git /path/to/pimbox
```
- Where `/path/to/pimbox` is the directory the box configuration and "interface" will live in. To issue Vagrant commands like `vagrant up`, you either `cd` into this directory or you set up a helper function in your `~/.bashrc` or `~/.bash_aliases` files (see below).
- Run the initialization script:
```
./init.sh
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

## Credentials

### MySQL

- User: `pimbox`
- Password: `secret`

## Tips

### General

- Use NFS for sharing folders (enabled by default), really helps with performance.

### Windows

- Exclude your defined shared folders from the Windows Defender scans to prevent I/O errors.
- When running `npm install` it may be necessary to add `--no-bin-links` parameter as Windows won't handle symlinks properly.

### Linux
- You might need to install the `net-tools` package on Arch-based distributions ([see docs](https://wiki.archlinux.org/index.php/Vagrant#Troubleshooting)) for the NFS to work.
- Using NFS will require root permissions when booting the VM unless configured otherwise ([see docs](https://www.vagrantup.com/docs/synced-folders/nfs.html#root-privilege-requirement)).
- You might need to allow the `udp=y` line in the NFS configuration file ([see issue](https://github.com/hashicorp/vagrant/issues/9666)) in `/etc/nfs.conf`, then, if already created, either destroy and re-create the box, or prune the NFS exports:
```
vagrant global-status --prune
```

## TODO

- Mailhog
