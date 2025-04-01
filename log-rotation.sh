#!/bin/bash

LOG_FILE="build-log-$(date +%Y%m%d-%H%M%S).log"

cp /var/lib/jenkins/jobs/api-service/builds/${BUILD_NUMBER}/log ./${LOG_FILE}

aws s3 cp ${LOG_FILE} s3://jenkins-log-bucket-2025/

rm ${LOG_FILE}