# IMAGE 2: run challenge
# @AUTHOR: change base image as necessary (e.g. python, node)
FROM python:3.10-bullseye

# setup xinetd
RUN apt-get -qq update && \
    apt-get -qq install -y --no-install-recommends xinetd
RUN useradd --system chal
COPY base-container/* /

# setup chal dir
WORKDIR /chal
COPY flag ./

# copy binary from builder image
COPY src/chal.py ./
# @AUTHOR: add any runtime requirements if needed
RUN apt-get -qq install -y --no-install-recommends openssl
RUN python3 -m pip install pycryptodome

# ensure chal dir is read only
RUN chown -R root:root ./* && \
    chmod -R o-w ./*


EXPOSE 31337

RUN chmod +x /run_chal.sh
CMD ["/usr/sbin/xinetd", "-syslog", "local0", "-dontfork", "-f", "/xinetd.conf"]
