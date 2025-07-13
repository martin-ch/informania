FROM python:latest

# Install Jupyter
RUN pip install --no-cache-dir notebook

# Install LMDB, prerequisites for zig and prerequisites for nats 
RUN apt-get update && \
    apt-get install -y  liblmdb-dev \
                        curl git zip && \
    rm -rf /var/lib/apt/lists/*

# Download and install Zig from the official website (latest version)
RUN curl -fsSL https://ziglang.org/builds/zig-x86_64-linux-0.15.0-dev.936+fc2c1883b.tar.xz -o /tmp/zig.tar.xz && \
    tar -xf /tmp/zig.tar.xz -C /opt && \
    mv "/opt/zig-x86_64-linux-0.15.0-dev.936+fc2c1883b" /opt/zig && \
    rm /tmp/zig.tar.xz && \
    ln -s /opt/zig/zig /usr/local/bin/zig

# Expose the necessary port
EXPOSE 8888
