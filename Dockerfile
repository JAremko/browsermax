FROM alpine:edge

MAINTAINER JAremko <w3techplaygound@gmail.com>

ENV XPRA_REV="15453"

COPY /sbin/cleanup /usr/local/sbin/cleanup

# Update
RUN echo "http://nl.alpinelinux.org/alpine/edge/testing" \
    >> /etc/apk/repositories \
    && echo "http://nl.alpinelinux.org/alpine/edge/community" \
    >> /etc/apk/repositories \
    && apk --no-cache upgrade \
    && cleanup

# Generic stuff
RUN apk --no-cache add \
    bash \
    coreutils \
    git \
    wget \
    && cleanup

RUN wget -O /usr/local/ship-it-right-now.jpg \
    http://c1.staticflickr.com/4/3007/3582044425_940fbd8171.jpg

# su-exec
RUN apk --no-cache add build-base \
    && git clone https://github.com/ncopa/su-exec.git /tmp/su-exec \
    && cd /tmp/su-exec \
    && make \
    && chmod 770 su-exec \
    && mv su-exec /usr/sbin/ \
# Cleanup
    && apk del build-base \
    && cleanup

# Default fonts
ENV NNG_URL="https://github.com/google/fonts/raw/master/ofl/\
nanumgothic/NanumGothic-Regular.ttf" \
    SCP_URL="https://github.com/adobe-fonts/source-code-pro/\
archive/2.030R-ro/1.050R-it.tar.gz"
RUN apk --no-cache add \
    fontconfig \
    wget \
    && mkdir -p /usr/share/fonts \
    && wget -qO- "${SCP_URL}" | tar xz -C /usr/share/fonts \
    && wget -q "${NNG_URL}" -P /usr/share/fonts \
    && fc-cache -fv \
# Cleanup
    && apk del wget \
    && cleanup

# Emacs
RUN apk --no-cache add emacs-x11 \
    && cleanup

# User
ENV UNAME="spacemacser" \
    GNAME="xpra"        \
    UHOME="/home/emacs" \
    UID="1000"          \
    GID="1000"          \
    SHELL="/bin/bash"

RUN echo "${UNAME}:x:${UID}:${GID}:${UNAME},,,:${UHOME}:${SHELL}" \
    >> /etc/passwd \
    && echo "${UNAME}::17032:0:99999:7:::" \
    >> /etc/shadow \
    && echo "${GNAME}:x:${GID}:${UNAME}" \
    >> /etc/group \
    && mkdir -p "${UHOME}"

# Spacemacs
COPY .spacemacs ${UHOME}/.spacemacs
RUN apk --no-cache add git \
    && git clone https://github.com/syl20bnr/spacemacs.git -b develop \
    "${UHOME}/.emacs.d" \
    && chown "${UID}":"${GID}" -R "${UHOME}" \
    && su-exec ${UNAME} emacs -nw -batch -u ${UNAME} -q -kill \
# 2X
    && su-exec ${UNAME} emacs -nw -batch -u ${UNAME} -q -kill \
    && cleanup

# Xpra deps
RUN apk --no-cache add \
    cython \
    dbus-x11 \
    desktop-file-utils \
    ffmpeg \
    gst-plugins-base1 \
    gst-plugins-good1 \
    gstreamer1 \
    libvpx \
    libxcomposite \
    libxdamage \
    libxext \
    libxfixes \
    libxkbfile \
    libxrandr \
    libxtst \
    musl-utils \
    py-asn1 \
    py-cffi \
    py-cryptography \
    py-enum34 \
    py-gobject3 \
    py-gtk \
    py-gtkglext \
    py-idna \
    py-ipaddress \
    py-lz4 \
    py-numpy \
    py-pillow \
    py-rencode \
    py-six \
    shared-mime-info \
    xf86-video-dummy \
    xorg-server \
    xset \
# Meta build-deps
    && apk --no-cache add --virtual build-deps \
    build-base \
    ffmpeg-dev \
    flac-dev \
    git \
    git-svn \
    libc-dev \
    libvpx-dev \
    libxcomposite-dev \
    libxdamage-dev \
    libxext-dev \
    libxfixes-dev \
    libxkbfile-dev \
    libxrandr-dev \
    libxtst-dev \
    linux-headers \
    opus-dev \
    perl-git \
    py-gtk-dev \
    py-gtkglext-dev \
    py-numpy-dev \
    py2-pip \
    python-dev \
    which \
    xvidcore-dev \
# PIP
    && pip install \
    pycrypto \
    netifaces \
    websockify \
    xxhash \
# Xpra
    && cd /tmp/ \
    && git svn clone  -s -r${XPRA_REV} https://www.xpra.org/svn/Xpra/ \
    && cd /tmp/Xpra/src \
    && echo -e 'Section "Module"\n  Load "fb"\n  EndSection' \
    >> etc/xpra/xorg.conf \
    && python2 setup.py install \
        --verbose \
        --with-Xdummy \
        --with-Xdummy_wrapper \
        --with-bencode \
        --with-clipboard \
        --with-csc_swscale \
        --with-cython_bencode \
        --with-enc_ffmpeg \
        --with-gtk2 \
        --with-gtk_x11 \
        --with-pillow \
        --with-server \
        --with-vpx \
        --with-vsock \
        --with-x11 \
        --without-client \
        --without-clipboard \
        --without-csc_libyuv \
        --without-dbus \
        --without-dec_avcodec2 \
        --without-enc_x264 \
        --without-enc_x265 \
        --without-gtk3 \
        --without-mdns \
        --without-opengl \
        --without-printing \
        --without-proxy \
        --without-sound \
        --without-shadow \
        --without-webcam \
    && mkdir -p /var/run/xpra/ \
    && cd ../.. \
    && rm -fr xpra-$XPRA_VERSION \
# Cleanup
    && apk del build-deps \
    && cleanup

COPY xorg.conf /etc/xpra/xorg.conf
RUN chmod 604 /etc/xpra/xorg.conf \
    && chown root:root /etc/xpra/xorg.conf

COPY /sbin/run /usr/local/sbin/run
COPY /sbin/healthcheck /usr/local/sbin/healthcheck

ENV DISPLAY=":14"                   \
    XORG_DPI="96"                   \
    XPRA_COMPRESS="0"               \
    XPRA_DPI="0"                    \
    XPRA_ENCODING="rgb"             \
    XPRA_HTML_DPI="96"              \
    XPRA_KEYBOARD_SYNC="yes"        \
    XPRA_IDLE_TIMEOUT="60"          \
    XPRA_SERVER_IDLE_TIMEOUT="3600" \
    XPRA_TCP_PORT="10000"

ENV APPROXIMATE_MAX_CONNECTION_LENGTH_S="120"

EXPOSE ${XPRA_TCP_PORT}

ENV TMPDIR="${UHOME}/.emacs.d/.cache"
ENV XAUTHORITY="${TMPDIR}/Xauthority"
ENV NO_AT_BRIDGE=1

# Mount point for tmpfs
RUN rm -rf /tmp \
    && ln -s "${TMPDIR}" /tmp \
    && ln -s "${TMPDIR}" ${UHOME}/.xpra \
    && mkdir -p "${TMPDIR}/workspace"

HEALTHCHECK --interval=30s \
            --timeout=30s \
            --retries=4 \
            CMD /usr/local/sbin/healthcheck

CMD run
