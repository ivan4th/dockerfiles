#!/bin/sh

cat >/tmp/jenkins.ini <<EOF
[jenkins]
url=${JENKINS_URL}
user=${JENKINS_USER}
password=${JENKINS_API_TOKEN}
EOF

/usr/bin/jenkins-jobs --conf /tmp/jenkins.ini "$@"
