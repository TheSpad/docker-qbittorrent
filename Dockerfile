FROM ghcr.io/linuxserver/baseimage-alpine:3.15

# set version label
ARG BUILD_DATE
ARG VERSION
ARG QBITTORRENT_RELEASE="release-4.4.0*"
LABEL maintainer="thespad"

ENV HOME="/config" \
XDG_CONFIG_HOME="/config" \
XDG_DATA_HOME="/config"

RUN \
  echo "**** install packages ****" && \
  apk add --update --no-cache --virtual=build-dependencies \
    autoconf \
    automake \
    build-base \
    cmake \
    git \
    libtool \
    linux-headers \
    perl \
    pkgconf \
    python3-dev \
    re2c \
    icu-dev \
    libexecinfo-dev \
    openssl-dev \
    qt5-qtbase-dev \
    qt5-qttools-dev \
    qt5-qtsvg-dev \
    zlib-dev && \
  apk add -U --upgrade --no-cache  \
    bash \
    curl \
    geoip \
    icu \
    libexecinfo \
    openssl \
    python3 \
    qt5-qtbase \
    qt5-qttools \
    qt5-qtsvg \
    tar \
    zlib && \
  apk add -U --upgrade --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/main/ unrar && \    
  git clone --shallow-submodules --recurse-submodules https://github.com/ninja-build/ninja.git ~/ninja && cd ~/ninja && \
  git checkout "$(git tag -l --sort=-v:refname "v*" | head -n 1)" && \
  cmake -Wno-dev -B build \
    -D CMAKE_CXX_STANDARD=17 \
    -D CMAKE_INSTALL_PREFIX="/usr" && \
  cmake --build build && \
  cmake --install build && \
  curl -sNLk https://boostorg.jfrog.io/artifactory/main/release/1.76.0/source/boost_1_76_0.tar.gz -o "$HOME/boost_1_76_0.tar.gz" && \
  tar xf "$HOME/boost_1_76_0.tar.gz" -C "$HOME" && \
  echo "**** build libtorrent ****" && \  
  git clone --shallow-submodules --recurse-submodules https://github.com/arvidn/libtorrent.git ~/libtorrent && cd ~/libtorrent && \
  git checkout "$(git tag -l --sort=-v:refname "v2*" | head -n 1)" && \
  cmake -Wno-dev -G Ninja -B build \
    -D CMAKE_BUILD_TYPE="release" \
    -D CMAKE_CXX_STANDARD=17 \
    -D BOOST_INCLUDEDIR="$HOME/boost_1_76_0/" \
    -D CMAKE_INSTALL_LIBDIR="lib" \
    -D CMAKE_INSTALL_PREFIX="/usr" && \
  cmake --build build && \
  cmake --install build && \
  echo "**** build qbittorrent ****" && \    
  git clone --shallow-submodules --recurse-submodules https://github.com/qbittorrent/qBittorrent.git ~/qbittorrent && cd ~/qbittorrent && \
  git checkout "$(git tag -l --sort=-v:refname "${QBITTORRENT_RELEASE}" | head -n 1)" && \
  cmake -Wno-dev -G Ninja -B build \
    -D CMAKE_BUILD_TYPE="release" \
    -D CMAKE_CXX_STANDARD=17 \
    -D BOOST_INCLUDEDIR="$HOME/boost_1_76_0/" \
    -D CMAKE_CXX_STANDARD_LIBRARIES="/usr/lib/libexecinfo.so" \
    -D CMAKE_INSTALL_PREFIX="/usr" \
    -D GUI=OFF && \
  cmake --build build && \
  cmake --install build && \
  echo "**** clean up ****" && \    
  cd ~ && rm -rf qbittorrent libtorrent ninja boost_1_76_0 boost_1_76_0.tar.gz && \
  apk del --purge \
    build-dependencies && \
  rm -rf \
    /tmp/* \
    /root/.cache

COPY root/ /

EXPOSE 8080 6881 6881/udp

VOLUME /config