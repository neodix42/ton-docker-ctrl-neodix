#!/bin/bash
set -e

# check machine configuration
echo -e "Checking system requirements"

cpus=$(nproc)
memory=$(cat /proc/meminfo | grep MemTotal | awk '{print $2}')
CPUS=$(expr $(nproc) - 1)
GLOBAL_CONFIG_URL=${GLOBAL_CONFIG_URL:-https://ton.org/testnet-global.config.json}

echo "This machine has ${cpus} CPUs and ${memory}KB of Memory"
if [ "$IGNORE_MINIMAL_REQS" != true ] && ([ "${cpus}" -lt 16 ] || [ "${memory}" -lt 64000000 ]); then
	echo "Insufficient resources. Requires a minimum of 16 processors and 64Gb RAM."
	exit 1
fi

echo "Setting global config..."
wget ${GLOBAL_CONFIG_URL} -O /usr/bin/ton/global.config.json

URL="https://dump.ton.org"
if [ ! -f /var/ton-work/db/dump_done ]; then
  if [ "$DUMP" == true ] ; then
    if [[ "$GLOBAL_CONFIG_URL" == *"testnet"* ]]; then
       DUMP_NAME="latest_testnet"
    else
       DUMP_NAME="latest"
    fi
    echo "Start DownloadDump $DUMP_NAME"
    DUMPSIZE=$(curl --silent ${URL}/dumps/${DUMP_NAME}.tar.size.archive.txt)
    DISKSPACE=$(df -B1 --output=avail /var/ton-work | tail -n1)
    NEEDSPACE=$(expr 3 '*' "$DUMPSIZE")
    if [ "$DISKSPACE" -gt "$NEEDSPACE" ]; then
      (curl --silent ${URL}/dumps/${DUMP_NAME}.tar.lz | pv --force | plzip -d -n${CPUS} | tar -xC /var/ton-work/db) 2>&1 | stdbuf -o0 tr '\r' '\n'
      mkdir -p /var/ton-work/db/static /var/ton-work/db/import
      chown -R validator:validator /var/ton-work/db
      touch /var/ton-work/db/dump_done
    echo "Done DownloadDump $DUMP_NAME"
    else
      echo "A minimum of $NEEDSPACE bytes of free disk space is required"
      exit 1
    fi
  fi
fi

echo "Setting processor cores"
sed -i -e "s/--threads\s[[:digit:]]\+/--threads ${CPUS}/g" /etc/systemd/system/validator.service

echo "Configuring TTL and verbosity settings"
# Set default values if not provided
ARCHIVE_TTL=${ARCHIVE_TTL:-86400}
STATE_TTL=${STATE_TTL:-86400}
VERBOSITY=${VERBOSITY:-1}

# Replace existing --verbosity value with environment variable
sed -i -e "s/--verbosity\s[[:digit:]]\+/--verbosity ${VERBOSITY}/g" /etc/systemd/system/validator.service

# Replace existing --archive-ttl value with environment variable
sed -i -e "s/--archive-ttl\s[[:digit:]]\+/--archive-ttl ${ARCHIVE_TTL}/g" /etc/systemd/system/validator.service

# Add --state-ttl parameter if not already present
if ! grep -q "\-\-state-ttl" /etc/systemd/system/validator.service; then
    sed -i -e "s/--archive-ttl ${ARCHIVE_TTL}/--archive-ttl ${ARCHIVE_TTL} --state-ttl ${STATE_TTL}/g" /etc/systemd/system/validator.service
else
    # Replace existing --state-ttl value if already present
    sed -i -e "s/--state-ttl\s[[:digit:]]\+/--state-ttl ${STATE_TTL}/g" /etc/systemd/system/validator.service
fi

echo "Starting validator"
systemctl start validator
echo "Starting mytoncore"
systemctl start mytoncore

echo "Service started!"
exec /usr/bin/systemctl
