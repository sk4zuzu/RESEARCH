FROM alpine:3.15

RUN apk --no-cache add \
    fd \
    curl \
    ripgrep \
    tar \
    xz

ARG QEMU_VERSION=6.0.1

RUN curl -fsSL "https://download.qemu.org/qemu-$QEMU_VERSION.tar.xz" \
    | tar -xJf- -C /opt/

WORKDIR /opt/qemu-$QEMU_VERSION/

RUN apk --no-cache add \
    bash \
    binutils \
    g++ \
    gcc \
    glib-dev \
    glib-static \
    make \
    musl-dev \
    ninja \
    perl \
    pkgconfig \
    python3 \
    zlib-dev \
    zlib-static

RUN ./configure \
    --disable-capstone \
    --disable-guest-agent \
    --disable-system \
    --disable-user \
    --enable-tools \
    --static

RUN make -j4 \
 && strip --strip-unneeded \
    build/qemu-img

CMD exec /bin/sh
