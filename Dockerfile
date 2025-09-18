FROM ghcr.io/ton-blockchain/ton:latest

ENV DEBIAN_FRONTEND=noninteractive
ARG MYTONCTRL_VERSION=master
ARG TELEMETRY=false
ARG DUMP=false
ARG MODE=validator
ARG IGNORE_MINIMAL_REQS=true
ARG GLOBAL_CONFIG_URL=https://ton.org/global.config.json

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y lsb-release software-properties-common gnupg gperf make cmake libblas-dev wget gcc openssl libgsl-dev zlib1g-dev libsecp256k1-dev libmicrohttpd-dev libsodium-dev liblz4-dev python3-dev python3-pip sudo git fio iproute2 plzip pv curl libjemalloc-dev ninja-build rocksdb-tools autoconf automake libtool iputils-ping \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/ton-work/db/static /var/ton-work/db/import /var/ton-work/db/keyring /usr/bin/ton /usr/bin/ton/lite-client /usr/bin/ton/validator-engine /usr/bin/ton/validator-engine-console /usr/bin/ton/utils /usr/src/ton/crypto/fift/lib/ /usr/src/ton/crypto/smartcont /usr/bin/ton/crypto \
    && cd /usr/src/ton && git init && git remote add origin https://github.com/ton-blockchain/ton.git \
    && wget https://apt.llvm.org/llvm.sh  \
    && chmod +x llvm.sh  \
    && ./llvm.sh 16 clang  \
    && ln /usr/bin/clang-16 /usr/bin/clang  \
    && ln /usr/bin/clang++-16 /usr/bin/clang++ \
    && cp /usr/local/bin/lite-client /usr/bin/ton/lite-client/ \
    && cp /usr/local/bin/validator-engine /usr/bin/ton/validator-engine \
    && cp /usr/local/bin/validator-engine-console /usr/bin/ton/validator-engine-console/ \
    && cp /usr/local/bin/generate-random-id /usr/bin/ton/utils/ \
    && cp /usr/local/bin/fift /usr/bin/ton/crypto/ \
    && cp /usr/local/bin/func /usr/bin/ton/crypto/ \
    && cp /usr/lib/fift/* /usr/src/ton/crypto/fift/lib/ \
    && cp -r /usr/share/ton/smartcont/* /usr/src/ton/crypto/smartcont/ \
    && wget -nv https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl3.py -O /usr/bin/systemctl \
    && chmod +x /usr/bin/systemctl \
    && wget https://raw.githubusercontent.com/ton-blockchain/mytonctrl/${MYTONCTRL_VERSION}/scripts/install.sh -O /tmp/install.sh \
    && wget -nv ${GLOBAL_CONFIG_URL} -O /usr/bin/ton/global.config.json \
    && if [ "$TELEMETRY" = false ]; then export TELEMETRY="-t"; else export TELEMETRY=""; fi && if [ "$IGNORE_MINIMAL_REQS" = true ]; then export IGNORE_MINIMAL_REQS="-i"; else export IGNORE_MINIMAL_REQS=""; fi \
    && /bin/bash /tmp/install.sh ${TELEMETRY} ${IGNORE_MINIMAL_REQS} -b ${MYTONCTRL_VERSION} -m ${MODE} \
    && ln -sf /proc/$$/fd/1 /usr/local/bin/mytoncore/mytoncore.log \
    && ln -sf /proc/$$/fd/1 /var/log/syslog \
    && sed -i 's/--logname \/var\/ton-work\/log//g' /etc/systemd/system/validator.service \
    && sed -i 's/\[Service\]/\[Service\]\nStandardOutput=null\nStandardError=syslog/' /etc/systemd/system/validator.service \
    && sed -i 's/\[Service\]/\[Service\]\nStandardOutput=null\nStandardError=syslog/' /etc/systemd/system/mytoncore.service \
    && rm -rf /var/lib/apt/lists/* && rm -rf /root/.cache/pip

COPY --chmod=755 ./scripts/entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]