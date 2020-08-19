#!/bin/bash

function log {
    BLU='\033[1;34m'
    NC='\033[0m' # No Color
    echo -e "\n${BLU}$1${NC}\n"
}

ulimit -n 10000

log "Adding repositories"

log "Adding Amazon Coretto repository"
wget -qO - https://apt.corretto.aws/corretto.key | apt-key add - 
add-apt-repository 'deb https://apt.corretto.aws stable main'

log "Adding OpenJDK repository"
wget -qO - https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public | sudo apt-key add -
sudo add-apt-repository --yes https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/

log "Adding Azul Zulu repository"
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0xB1998361219BD9C9
wget --quiet https://cdn.azul.com/zulu/bin/zulu-repo_1.0.0-2_all.deb -O zulu-repo_1.0.0-2_all.deb
dpkg -i zulu-repo_1.0.0-2_all.deb

log "Updating repositories"
apt-get update

log "Starting installation"

log "Installing Amazon Coretto"
apt-get install -y java-11-amazon-corretto-jdk

log "Installing OpenJDK 11 Hotspot"
apt-get install adoptopenjdk-11-hotspot -y

log "Installing OpenJDK 11 OpenJ9"
apt-get install adoptopenjdk-11-openj9 -y

log "Installing Azul Zulu 11"
apt-get install zulu11-jdk -y

log "Installing GraalVM"
wget --quiet https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-20.1.0/graalvm-ce-java11-linux-amd64-20.1.0.tar.gz -O graal.tar.gz
tar -xzf graal.tar.gz
mv graalvm-ce-java11-20.1.0/ /usr/lib/jvm/
ln -s /usr/lib/jvm/graalvm-ce-java11-20.1.0/ /usr/lib/jvm/graalvm
update-alternatives --install /usr/bin/java java /usr/lib/jvm/graalvm/bin/java 4

log "Installing OracleJDK 11"
dpkg -i /opt/mount/jdk-11.0.8_linux-x64_bin.deb
update-alternatives --install /usr/bin/java java /usr/lib/jvm/jdk-11.0.8/bin/java 5

log "All JVMs Installed!"
update-alternatives --list java

log "Setting up Sling CMS"
mkdir -p /opt/slingcms
wget --quiet https://github.com/apache/sling-org-apache-sling-app-cms/releases/download/org.apache.sling.cms-0.16.2/org.apache.sling.cms.builder-0.16.2.jar -O /opt/slingcms/org.apache.sling.cms.jar

log "Installing Sling Packager"
apt-get install npm -y
npm install @peregrinecms/slingpackager -g

log "Installing siege"
apt-get install siege -y

log "Install PSRecord"
apt-get install python-pip -y
pip install psrecord
