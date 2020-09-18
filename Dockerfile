FROM ubuntu
COPY install-hrl.sh /root/install-hrl.sh
RUN /root/install-hrl.sh
