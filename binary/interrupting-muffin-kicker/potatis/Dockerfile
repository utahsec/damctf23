FROM rustlang/rust:nightly as builder

RUN apt-get update && apt-get install -y libsixel-dev build-essential tree
COPY . /potatis

WORKDIR /potatis/nes-cloud
RUN cargo build --release

EXPOSE 4444/tcp
EXPOSE 5555/tcp
CMD ["cargo", "run", "--release", "--bin", "nes-cloud-app", "--", "--max-concurrent", "500", "--log-to-file", "--instance-bin", "target/release/nes-cloud-instance"]
