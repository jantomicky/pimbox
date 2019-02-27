# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'

# Set up settings.
defaultSettings = {
  "ip" => "10.0.0.10",
  "name" => "default",
  "memory" => 2048,
  "cpus" => 1
}

currentDirectory = File.expand_path(File.dirname(__FILE__))
settingsFile = "#{currentDirectory}/settings.yaml"

if File.exist? settingsFile then
  customSettings = YAML::load(File.read(settingsFile))
  settings = defaultSettings.merge(customSettings)
else
  abort "Could not find settings.yaml file in #{currentDirectory}"
end

# Documentation: https://docs.vagrantup.com
Vagrant.configure("2") do |config|

  # Boxes: https://vagrantcloud.com/search
  config.vm.box = "ubuntu/xenial64"

  # Set the box name.
  config.vm.define settings['name']

  # Create a private network for host-only access to the machine.
  config.vm.network "private_network", ip: settings['ip']

  # Provider-specific settings.
  config.vm.provider "virtualbox" do |vb|
    vb.name = settings['name']
    vb.memory = settings['memory']
    vb.cpus = settings['cpus']
  end

  # Set up shared folders.
  if settings.include? 'folders'
    settings['folders'].each do |folder|
      if File.exist? File.expand_path(folder['map'])
        options = {}

        if folder['type'] == 'nfs'
          options = folder['mount_options'] ? folder['mount_options'] : { mount_options: ['nolock', 'vers=3', 'udp', 'actimeo=1'] }
        end

        options.keys.each{|k| options[k.to_sym] = options.delete(k) }
        config.vm.synced_folder folder['map'], folder['to'], type: folder['type'] ||= nil, **options

        if folder['type'] == 'nfs' && Vagrant.has_plugin?('vagrant-bindfs')
          config.bindfs.bind_folder folder['to'], folder['to'], perms: "u=rwX,g=rwX,o=rX"
        end
      else
        print "Failed to map #{folder['map']}, check your configuration"
      end
    end
  end

   # Copy user files.
  if settings.include? 'copy'
    settings['copy'].each do |file|
      config.vm.provision "file", source: file['from'], destination: file['to']
    end
  end

  # Forwarding SSH credentials.
  config.ssh.forward_agent = true

  # Run provisioning shell scripts.
  settings['run'].each do |script|
    config.vm.provision "shell", path: script
  end
end
