FROM ubuntu

# setup installation directory and disable prompts during installation
WORKDIR /tmp
ARG DEBIAN_FRONTEND=noninteractive

# Install necessary libraries & cleanup for subsequent commands
RUN apt-get update && apt-get install -y podman wget git dumb-init python3.6 python3-distutils python3-pip python3-apt \
 && apt-get clean autoclean \
 && apt-get autoremove --yes \
 && rm -rf /var/lib/{apt,dpkg,cache,log}/

# Install vegeta for HTTP benchmarking
RUN wget https://github.com/tsenart/vegeta/releases/download/v12.8.3/vegeta-12.8.3-linux-amd64.tar.gz \
 && tar -xzf vegeta-12.8.3-linux-amd64.tar.gz \
 && mv vegeta /usr/local/bin/vegeta \
 && rm -rf vegeta-12.8.3-linux-amd64.tar.gz

# Install clairctl to get clair manifests
RUN wget https://github.com/quay/clair/releases/download/v4.6.0/clairctl-linux-amd64 \
 && chmod 777 clairctl-linux-amd64 \
 && mv clairctl-linux-amd64 /usr/local/bin/clairctl \
 && rm -rf clairctl-linux-amd64

# Install and setup snafu for storing vegeta results into ES
RUN mkdir -p /opt/snafu/ \
 && wget -O /tmp/benchmark-wrapper.tar.gz https://github.com/cloud-bulldozer/benchmark-wrapper/archive/refs/tags/v1.0.0.tar.gz \
 && tar -xzf /tmp/benchmark-wrapper.tar.gz -C /opt/snafu/ --strip-components=1 \
 && pip3 install --upgrade pip \
 && pip3 install -e /opt/snafu/ \
 && rm -rf /tmp/benchmark-wrapper.tar.gz

# Copy binary and start the command
COPY clair-load-test /bin/clair-load-test
LABEL io.k8s.display-name="clair-load-test"
ENTRYPOINT ["/usr/bin/dumb-init", "--", "sh", "-c", "ulimit -n 65536 && ulimit -p 65536 && clair-load-test -D report"]