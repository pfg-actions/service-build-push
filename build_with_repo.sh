#!/bin/bash

set -eu

export SERVICE=$1
export GIT_REPO=$2
export API_VERSION=$3
export GIT_TAG=$3
echo "Service: $SERVICE"
export COMMIT_HASH=$(git rev-parse HEAD)
export COMMIT_HASH_SHORT=$(git rev-parse --short HEAD)
export BUILT_AT=$(LC_ALL=C date -u '+%d %B %Y %r (UTC)')
export ROOT="github.com/${GIT_REPO}"
export IMPORT_VERSION="${ROOT}/internal/${SERVICE}/version"
export LDFLAGS="-w -s -X '${IMPORT_VERSION}.Version=${GIT_TAG}' \
-X '${IMPORT_VERSION}.APIVersion=${API_VERSION}' \
-X '${IMPORT_VERSION}.CommitHash=${COMMIT_HASH}' \
-X '${IMPORT_VERSION}.BuiltAt=${BUILT_AT}'"; \

echo "${LDFLAGS}"

echo "Build"
for d in `ls cmd` ; do
    if [ $d == $SERVICE ]; then
        GOOS=linux GOARCH=amd64 GO111MODULE=on CGO_ENABLED=0 go build -ldflags="${LDFLAGS}" -o ./bin/$SERVICE ./cmd/$d/main.go &&  echo -n "${COMMIT_HASH_SHORT} (${GIT_TAG})" > ./bin/$SERVICE.commit
    else
        GOOS=linux GOARCH=amd64  GO111MODULE=on CGO_ENABLED=0 go build -ldflags="${LDFLAGS}" -o ./bin/$SERVICE-$d ./cmd/$d/main.go && echo -n "${COMMIT_HASH_SHORT} (${GIT_TAG})"> ./bin/$SERVICE-$d.commit
    fi
    if [ $? -ne 0 ]; then
        echo 'An error has occurred! Aborting build...'
        exit 1
    fi
done

echo "Build $SERVICE service completed!"