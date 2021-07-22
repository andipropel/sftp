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

ENV AWS_DEFAULT_REGION='ap-southeast-2' \
    AWS_ACCESS_KEY_ID='' \
    AWS_SECRET_ACCESS_KEY=''
    
RUN mkdir -p /root/.aws
RUN echo "[default]" > /root/.aws/config
RUN echo "region = $AWS_DEFAULT_REGION" >> /root/.aws/config
RUN echo "[default]" > /root/.aws/credentials
RUN echo "aws_access_key_id = $AWS_ACCESS_KEY_ID" >> /root/.aws/credentials
RUN echo "aws_secret_access_key = $AWS_SECRET_ACCESS_KEY" >> /root/.aws/credentials

COPY files/sshd_config /etc/ssh/sshd_config
COPY files/create-sftp-user /usr/local/bin/
COPY files/entrypoint /

# Copy hello-cron file to the cron.d directory
COPY s3cron /etc/cron.d/s3cron
 
# Give execution rights on the cron job
RUN chmod 0644 /etc/cron.d/s3cron

# Apply cron job
RUN crontab /etc/cron.d/s3cron
 
# Create the log file to be able to run tail
RUN touch /var/log/cron.log

#USER root
#COPY passwd-s3fs /root/.passwd-s3fs
#RUN chmod 600 $HOME/.passwd-s3fs
#RUN mkdir /s3bucket
#RUN mkdir /s3bucket/foo && chmod 755 /s3bucket/foo
#RUN echo "testsftpandi /home fuse.s3fs _netdev,rw,nosuid,nodev,allow_other,nonempty 0 0" >> /etc/fstab
#RUN s3fs sftptestandi /s3bucket -o passwd_file=$HOME/.passwd-s3fs
EXPOSE 22
ENTRYPOINT ["/entrypoint"]