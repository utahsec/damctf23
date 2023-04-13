FROM ubuntu:jammy

RUN apt-get -qq update && \
    apt-get -qq install -y --no-install-recommends tcl wget unzip openssl
RUN useradd --system chal

RUN wget https://wapp.tcl-lang.org/home/zip/wapp.zip --no-check-certificate && unzip wapp.zip -d /usr/lib && echo pkg_mkIndex /usr/lib/wapp | tclsh

# setup chal dir
COPY app /chal/app
COPY flag /chal
WORKDIR /chal/app

# ensure chal dir is read only
RUN chown -R root:root ./* && \
    chmod -R o-w ./*

EXPOSE 31337

RUN chmod +x ./app.tcl
CMD ["./app.tcl", "--server", "31337"]
