FROM debian:buster
MAINTAINER Adrian Dvergsdal [atmoz.net]
# Steps done in one RUN layer:
# - Install packages
# - OpenSSH needs /var/run/sshd to run
# - Remove generic host keys, entrypoint generates unique keys
RUN apt-get update && \
    apt-get -y install openssh-server curl s3fs awscli module-assistant cron vim && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /var/run/sshd && \
    rm -f /etc/ssh/ssh_host_*key*

COPY files/sshd_config /etc/ssh/sshd_config
COPY files/create-sftp-user /usr/local/bin/
COPY files/entrypoint /
USER root
COPY passwd-s3fs /root/.passwd-s3fs
RUN chmod 600 $HOME/.passwd-s3fs
RUN mkdir /s3bucket
RUN mkdir /s3bucket/foo && chmod 755 /s3bucket/foo
RUN echo "testsftpandi /home fuse.s3fs _netdev,rw,nosuid,nodev,allow_other,nonempty 0 0" >> /etc/fstab
#RUN s3fs sftptestandi /s3bucket -o passwd_file=$HOME/.passwd-s3fs
EXPOSE 22
ENTRYPOINT ["/entrypoint"]