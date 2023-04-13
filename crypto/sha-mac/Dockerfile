FROM python:3.11-slim

# setup xinetd
RUN apt-get -qq update && \
    apt-get -qq install -y --no-install-recommends xinetd
RUN useradd --system chal
COPY base-container/* /

# setup chal dir
WORKDIR /chal
COPY flag server.py requirements.txt ./

# install python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# ensure chal dir is read only
RUN chown -R root:root ./* && \
    chmod -R o-w ./*

EXPOSE 31337

RUN chmod +x /run_chal.sh
CMD ["/usr/sbin/xinetd", "-syslog", "local0", "-dontfork", "-f", "/xinetd.conf"]
