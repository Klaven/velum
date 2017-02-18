#!/bin/bash

set -e

if [ -z "$1" ] || [ -z "$2" ]; then
  cat <<EOF
usage:
  ./buildresult.sh REPOSITORY ARCH
EOF
  exit 1
fi

repository=$1
arch=$2
result="succeeded"

log()   { echo ">>> $1" ; }

sed -i "s|<username>|$OSC_USERNAME|g" /root/.oscrc
sed -i "s|<password>|$OSC_PASSWORD|g" /root/.oscrc

log "fetching build results"
until osc results Virtualization:containers:Velum velum | grep -Eq "^$repository.*$arch.*(succeeded|failed|excluded|unresolvable)$";
do
    result=$(osc results Virtualization:containers:Velum velum | grep "$repository.*$arch")
    log "Waiting for $repository $arch build to finish"
    sleep 5
done

echo $result | grep "succeeded" && exit 0

log "build failed with: $result"
exit 1
