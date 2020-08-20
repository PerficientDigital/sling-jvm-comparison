#!/bin/bash
JVMS="adoptopenjdk-11-hotspot-amd64\nadoptopenjdk-11-openj9-amd64\ngraalvm\njava-11-amazon-corretto\njdk-11.0.8\nzulu11"

function log {
    BLU='\033[1;34m'
    NC='\033[0m' # No Color
    echo -e "\n${BLU}$1${NC}\n"
}

cd /opt/slingcms

ITR=0
while [ $ITR -le 9 ]; do
    log "Starting iteration ${ITR}"
    RAND_JVMS=$(echo -e $JVMS | sort -R)

    while IFS= read -r JVM; do
        log "Initializing test for ${JVM}"
        BASE="/opt/mount/tests/${ITR}/${JVM}"
        rm -rf $BASE
        mkdir -p $BASE
        update-alternatives --set java "/usr/lib/jvm/${JVM}/bin/java"
        java -version 2> "${BASE}/jvm.txt"

        TEST_START=$(date +%s%3N)
        SLING_START=0

        log "Starting Sling CMS"
        java -jar /opt/slingcms/org.apache.sling.cms.jar  &
        SLING_PID=$!

        log "Recording process information for ${SLING_PID}"
        psrecord $SLING_PID --interval 1 --log "${BASE}/activity.txt" &
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
PACKAGE_INSTALL_END,${PACKAGE_INSTALL_END}" > "${BASE}/stats.txt"

        sleep 120
        
        log "Besieging the instance for 10 minutes"
        siege --time=10M --file=/opt/mount/urls.txt > "${BASE}/siege1.txt" 2>&1
        log "Waiting for 5 minutes"
        sleep 300
        log "Besieging the instance for 10 minutes"
        siege --time=10M --file=/opt/mount/urls.txt > "${BASE}/siege2.txt" 2>&1 
        log "Waiting for 5 minutess"
        sleep 300

        log "Besieging complete!"

        log "Cleaning up!"
        kill $PSRECORD_PID
        kill -9 $SLING_PID
        sleep 120; 
        rm -rf /opt/slingcms/sling

        log "Performance test complete for ${JVM}"

    done <<< $RAND_JVMS
    ITR=$(( $ITR + 1 ))
done

