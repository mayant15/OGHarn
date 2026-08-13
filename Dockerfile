FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG AFLPLUSPLUS_COMMIT=ad5304010ae3be9d5cdc1ba51b09e14169c5cb87
ARG MULTIPLIER_RELEASE=e137812

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        autoconf \
        autogen \
        automake \
        bear \
        build-essential \
        ca-certificates \
        clang \
        libclang-rt-dev \
        cmake \
        curl \
        git \
        libasound2-dev \
        libflac-dev \
        libjpeg-dev \
        liblzma-dev \
        libmp3lame-dev \
        libmpg123-dev \
        libogg-dev \
        libopus-dev \
        libtool \
        libvorbis-dev \
        lld \
        llvm-dev \
        pkg-config \
        python3.12-dev \
        python3.12-venv \
        xz-utils \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/multiplier \
    && curl -fsSL \
        "https://github.com/trailofbits/multiplier/releases/download/${MULTIPLIER_RELEASE}/multiplier-${MULTIPLIER_RELEASE}.tar.xz" \
        | tar -xJ -C /opt/multiplier

RUN git clone https://github.com/AFLplusplus/AFLplusplus.git /tmp/AFLplusplus \
    && git -C /tmp/AFLplusplus checkout --detach "${AFLPLUSPLUS_COMMIT}" \
    && make -C /tmp/AFLplusplus -j"$(nproc)" LLVM_CONFIG=llvm-config all \
    && make -C /tmp/AFLplusplus install \
    && rm -rf /tmp/AFLplusplus

RUN python3.12 -m venv /opt/ogharn-venv \
    && /opt/ogharn-venv/bin/pip install --no-cache-dir cfile==0.2.0 PyYAML

ENV PATH="/opt/ogharn-venv/bin:/opt/multiplier/bin:/usr/local/bin:/OGHarn/src:${PATH}" \
    PYTHONPATH="/opt/multiplier/lib/python3.12/site-packages" \
    LD_LIBRARY_PATH="/opt/multiplier/lib"

COPY src /OGHarn/src
COPY extras/mult-to-c-types.txt extras/type-to-val.txt /OGHarn/extras/

WORKDIR /OGHarn
CMD ["bash"]
