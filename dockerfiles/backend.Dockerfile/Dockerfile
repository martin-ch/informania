FROM python:latest

# Download and install Zig from the official website (latest version)
RUN curl -fsSL https://ziglang.org/builds/zig-linux-x86_64-0.15.0-dev.471+369177f0b.tar.xz -o /tmp/zig.tar.xz && \
    tar -xf /tmp/zig.tar.xz -C /opt && \
    mv "/opt/zig-linux-x86_64-0.15.0-dev.471+369177f0b" /opt/zig && \
    rm /tmp/zig.tar.xz

# Clone and build LMDB
RUN git clone https://github.com/LMDB/lmdb.git /opt/lmdb && \
    make -C /opt/lmdb/libraries/liblmdb


