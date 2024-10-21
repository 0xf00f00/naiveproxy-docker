FROM --platform=${TARGETPLATFORM} debian:stable-slim as downloader

WORKDIR /root

ARG TARGETPLATFORM
ARG VERSION

RUN set -eux; \
    apt-get update; \ 
    apt-get install -y wget binutils xz-utils; \
	case "${TARGETPLATFORM}" in \
        'linux/386') \
            ARCH="linux-x86"; \
            ;; \
        'linux/amd64') \
            ARCH="linux-x64"; \
            ;; \
        'linux/arm/v7') \
            ARCH="linux-arm"; \
            ;; \
        'linux/arm64'|'linux/arm64/v8') \
            ARCH="linux-arm64"; \
            ;; \
		*) echo >&2 "error: unsupported architecture '$arch' (likely packaging update needed)"; exit 1 ;; \
	esac; \
    \
    export NAIVE_FILE="naiveproxy-${VERSION}-${ARCH}"; \
    \
    echo "Downloading compressed release file..."; \
    wget -O /root/naive.tar.xz https://github.com/0xf00f00/naiveproxy/releases/download/${VERSION}/${NAIVE_FILE}.tar.xz > /dev/null 2>&1; \
    if [ ! -f /root/naive.tar.xz ]; then \
        echo "Error: Failed to download compressed release file!"; exit 1; \
    fi; \
    echo "Download compressed release file completed."; \
    \
    mkdir -p /root/naive; \
    \
    echo "Extracting release file"; \
    tar -xf /root/naive.tar.xz -C /root; \
    mv /root/${NAIVE_FILE}/naive /root/naive/naive; \
    mv /root/${NAIVE_FILE}/config.json /root/naive/config.json; \
    chmod +x /root/naive/naive; \
    strip -s /root/naive/naive; \
    echo "Extracting release file: completed.";


FROM --platform=${TARGETPLATFORM} debian:stable-slim

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates 

VOLUME /etc/naiveproxy

COPY --from=downloader /root/naive/naive /usr/bin/naive
COPY --from=downloader /root/naive/config.json /etc/naiveproxy/config.json

CMD [ "/usr/bin/naive", "/etc/naiveproxy/config.json" ]
