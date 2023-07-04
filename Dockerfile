FROM docker.io/centos:centos7.9.2009@sha256:be65f488b7764ad3638f236b7b515b3678369a5124c47b8d32916d6487418ea4

USER root

RUN yum -y update \
    && yum -y install wget \
    && yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
    && yum -y install clamav clamav-data clamav-scanner-systemd clamav-devel clamav-server-systemd \
    && yum -y install nmap

RUN groupadd yolt && useradd -g yolt yolt

# initial update of av databases
RUN wget -O /var/lib/clamav/main.cvd --user=freshclam --password=freshclam https://nexus.yolt.io/repository/clamav/main.cvd && \
    wget -O /var/lib/clamav/daily.cvd --user=freshclam --password=freshclam https://nexus.yolt.io/repository/clamav/daily.cvd && \
    wget -O /var/lib/clamav/bytecode.cvd --user=freshclam --password=freshclam https://nexus.yolt.io/repository/clamav/bytecode.cvd && \
    chown yolt:yolt /var/lib/clamav/*.cvd

# backup with day of week number in case we have to fall back
RUN  DOW=$(date +%u) && \
     curl -v --user 'freshclam:freshclam' --upload-file /var/lib/clamav/main.cvd https://nexus.yolt.io/repository/clamav/main.cvd.$DOW && \
     curl -v --user 'freshclam:freshclam' --upload-file /var/lib/clamav/daily.cvd https://nexus.yolt.io/repository/clamav/daily.cvd.$DOW && \
     curl -v --user 'freshclam:freshclam' --upload-file /var/lib/clamav/bytecode.cvd https://nexus.yolt.io/repository/clamav/bytecode.cvd.$DOW

# permission juggling
RUN mkdir /var/run/clamav && \
    chown yolt:yolt /var/run/clamav && \
    chmod 750 /var/run/clamav

# av configuration update
RUN sed -i '/^Example/d' /etc/clamd.d/scan.conf && \
    sed -i 's/^Foreground .*$/Foreground true/g' /etc/clamd.d/scan.conf && \
    echo "TCPSocket 3310" >> /etc/clamd.d/scan.conf && \
    echo "MaxScanSize 50M" >> /etc/clamd.d/scan.conf && \
    echo "MaxFileSize 50M" >> /etc/clamd.d/scan.conf && \
    echo "StreamMaxLength 50M" >> /etc/clamd.d/scan.conf && \
    cp /etc/freshclam.conf /etc/freshclam.conf.bak && \
    sed -i 's/^Foreground .*$/Foreground true/g' /etc/freshclam.conf

# volume provision
VOLUME ["/var/lib/clamav"]

# Set environment variables.
ENV HOME /root

# Open up the server
EXPOSE 3310

# Run freshclam to ensure that we have the latest signatures.
# Note that YUM might not have the latest version of clamav,
# We suppress the freshclam warning of it by overriding the exitcode to 0.
RUN freshclam --on-outdated-execute=EXIT_0

# reupload updated files to keep the current version up to date
RUN curl -v --user 'freshclam:freshclam' --upload-file /var/lib/clamav/main.cvd https://nexus.yolt.io/repository/clamav/main.cvd && \
    curl -v --user 'freshclam:freshclam' --upload-file /var/lib/clamav/daily.cvd https://nexus.yolt.io/repository/clamav/daily.cvd && \
    curl -v --user 'freshclam:freshclam' --upload-file /var/lib/clamav/bytecode.cvd https://nexus.yolt.io/repository/clamav/bytecode.cvd

USER yolt

# k8s liveness & readiness
ADD liveness.sh /
ADD readiness.sh /

# self-test that can be run after build
ADD self-test.sh /

# Test files
ADD ./test/eicar.txt /home/yolt
ADD ./test/eicar.zip /home/yolt

# clamav daemon bootstrapping
ADD bootstrap.sh /
CMD ["/bootstrap.sh"]
