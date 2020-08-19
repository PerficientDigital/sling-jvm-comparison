# Sling JVM Performance Comparison

Runs a performance test of a number of popular Java Virtual Machine implementations on running Apache Sling.

## Dependencies

This requires:

- [Node JS](https://nodejs.org/en/download/)
- [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
- [Vagrant](https://www.vagrantup.com/downloads.html)

## Preparation

There are a couple manual steps you need to do to run this test:

1. Download Oracle JDK 11.0.8 for Linux x64 into the `mount/` folder
2. Create a content and code package you want to install called *uber.zip* and move it to the `mount/` folder
3. Create a list of URLs for siege to call for your app

## Running

To run, cd into `local/` and run the command:

    vagrant destroy -f && vagrant up && vagrant ssh -c 'sudo /bin/bash /opt/libs/test.sh' && vagrant halt

This will automatically setup the VM, run the tests and stop the machine. Note that this process will take hours as it installs all of the required JVMs and then for every JVM:

 - Sets up an Apache Sling CMS instance
 - Installs an uber.zip of content
 - Runs siege against the url list for 15 minutes
 - Sleeps for 15 minutes
 - Runs siege against the url list for 15 minutes
 - Sleeps for 15 minutes
 - Tears down the instance and waits 5 minutes

## Analysis

There's a quick node script to analyse the project, cd into  `analyse/` and run the command:

    npm install && node .

This will parse the data from the tests and generate a data.csv. In addition, all of the raw data, including plot PNGs will be located in the `mount/tests/[jvm-name]` folders.