# based on https://github.com/jsallis/docker-jenkins-job-builder
FROM alpine:3.8
MAINTAINER Ivan Shvedunov <ivan4th@gmail.com>

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh && \
    apk add --no-cache python && \
    apk add --no-cache py-pip && \
    pip install jenkins-job-builder==2.9.1

WORKDIR /opt/jenkins-job
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
