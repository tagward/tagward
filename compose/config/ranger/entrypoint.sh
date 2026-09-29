#!/bin/bash
# Replaces the upstream image's ranger.sh: same setup-once-then-start sequence, without
# the Kerberos wait and without create-ranger-services.py, which would create dev_hdfs,
# dev_hive and friends pointing at hosts that do not exist here. Spec 07 bootstraps the
# trino and tag services through the controller instead.
set -u
RANGER_HOME="${RANGER_HOME:-/opt/ranger}"

if [ ! -e "${RANGER_HOME}/.setupDone" ]; then
  cd "${RANGER_HOME}/admin" || exit 1
  if ./setup.sh; then
    touch "${RANGER_HOME}/.setupDone"
  else
    echo "Ranger admin setup.sh failed" >&2
    exit 1
  fi
fi

cd "${RANGER_HOME}/admin" && ./ews/ranger-admin-services.sh start

for _ in $(seq 1 60); do
  pid=$(ps -ef | grep -v grep | grep -i "org.apache.ranger.server.tomcat.EmbeddedServer" | awk "{print \$2}" | head -1)
  [ -n "${pid}" ] && break
  sleep 1
done
if [ -z "${pid:-}" ]; then
  echo "Ranger admin process not found after start" >&2
  exit 1
fi
exec tail --pid="${pid}" -f /dev/null
