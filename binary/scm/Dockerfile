# @AUTHOR: if your chal doesn't build seperately from being run (i.e. Python),
#          delete all of this builder code (until next FROM)
FROM archlinux:base-devel as builder

# @AUTHOR: add any build requirements
RUN pacman -Syu --noconfirm && pacman -Sy --noconfirm libseccomp

# build challenge binary
# @AUTHOR: make sure all source files are copied in
#          if everything is in src/, no change needed
WORKDIR /build
COPY Makefile ./
COPY src ./src

RUN make container


# IMAGE 2: run challenge
# @AUTHOR: change base image as necessary (e.g. python, node)
FROM archlinux:base-devel

# setup xinetd
RUN pacman -Syu --noconfirm && pacman -Sy --noconfirm libseccomp xinetd
RUN useradd --system chal
COPY base-container/* /

# setup chal dir
WORKDIR /chal
COPY flag ./

# copy binary from builder image
# @AUTHOR: make sure all build outputs are copied to the runner
#          if there is no build output, replace this with the appropriate COPYs
#          to pull files from the host
COPY --from=builder /build/scm ./
# @AUTHOR: add any runtime requirements if needed

# ensure chal dir is read only
RUN chown -R root:root ./* && \
    chmod -R o-w ./*


EXPOSE 31337

RUN chmod +x /run_chal.sh
CMD ["/usr/sbin/xinetd", "-syslog", "local0", "-dontfork", "-f", "/xinetd.conf"]
