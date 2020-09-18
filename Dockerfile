FROM ubuntu
COPY install-hrl.sh /root/install-hrl.sh
RUN chmod +x /root/install-hrl.sh; /root/install-hrl.sh
