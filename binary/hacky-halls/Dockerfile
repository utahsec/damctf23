FROM ubuntu:jammy

# setup xinetd
RUN apt-get -qq update && \
    apt-get -qq install -y --no-install-recommends openssl
RUN useradd --system chal

# setup chal dir
WORKDIR /chal
# Copy flag
COPY flag ./
# Copy 16-byte anticheat AES key
COPY anticheat.key ./
# Copy server binary
COPY server ./

# copy binary from builder image
# @AUTHOR: make sure all build outputs are copied to the runner
#          if there is no build output, replace this with the appropriate COPYs
#          to pull files from the host

# ensure chal dir is read only
RUN chown -R root:root ./* && \
    chmod -R o-w ./*

RUN chmod +x server
EXPOSE 31337

CMD ["./server", "-p", "31337", "-t", "30"]
