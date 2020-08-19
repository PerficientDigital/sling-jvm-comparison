#!/bin/bash
JVMS=(
    "adoptopenjdk-11-hotspot-amd64"
    "adoptopenjdk-11-openj9-amd64"
    "graalvm"
    "java-11-amazon-corretto"
    "jdk-11.0.8"
    "zulu11"
)

function log {
    BLU='\033[1;34m'
    NC='\033[0m' # No Color
    echo -e "\n${BLU}$1${NC}\n"
}

cd /opt/slingcms
for JVM in ${JVMS[@]}; do

    log "Initializing test for ${JVM}"
    BASE="/opt/mount/tests/${JVM}"
    rm -rf $BASE
    mkdir -p $BASE
    update-alternatives --set java "/usr/lib/jvm/${JVM}/bin/java"
    java -version 2> "/opt/mount/tests/${JVM}/jvm.txt"

    TEST_START=$(date +%s%3N)
    SLING_START=0

    log "Starting Sling CMS"
    java -jar /opt/slingcms/org.apache.sling.cms.jar  &
    SLING_PID=$!

    log "Recording process information for ${SLING_PID}"
    psrecord $SLING_PID --interval 1 --log "/opt/mount/tests/${JVM}/activity.txt" &
    PSRECORD_PID=$!

    while true; do
        STATUS=$(curl -o /dev/null --silent --head --write-out '%{http_code}' http://localhost:8080/content/apache/sling-apache-org/index.html)
        if [ "$STATUS" = "200" ]; then
            log "Sling CMS started"
            SLING_START=$(date +%s%3N)
            break
        fi
        sleep 0.1; 
    done


    sleep 120; 
    PACKAGE_INSTALL_START=$(date +%s%3N)
    log "Installing Uber package"
    slingpackager upload -i /opt/mount/uber.zip
    PACKAGE_INSTALL_END=$(date +%s%3N)

   echo "TEST_START,${TEST_START}
SLING_START,${SLING_START}
PACKAGE_INSTALL_START,${PACKAGE_INSTALL_START}
PACKAGE_INSTALL_END,${PACKAGE_INSTALL_END}" > "/opt/mount/tests/${JVM}/stats.txt"

    sleep 300
    
    log "Besieging the instance"
    siege --time=15M --file=/opt/mount/urls.txt > "/opt/mount/tests/${JVM}/siege1.txt" 2>&1
    log "Waiting for 15 minutes"
    sleep 900
    log "Besieging the instance"
    siege --time=15M --file=/opt/mount/urls.txt > "/opt/mount/tests/${JVM}/siege2.txt" 2>&1 
    log "Waiting for 15 minutes"
    sleep 900

    log "Besieging complete!"

    log "Cleaning up!"
    kill $PSRECORD_PID
    kill -9 $SLING_PID
    sleep 30; 
    rm -rf /opt/slingcms/sling

    log "Performance test complete for ${JVM}"

    sleep 300
done