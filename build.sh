#!/bin/bash

set -eu

export SERVICE=$1
echo "Service: $SERVICE"
export GIT_TAG=$(git name-rev --tags --name-only $(git rev-parse HEAD))
export API_VERSION=$(git name-rev --tags --name-only $(git rev-parse HEAD))
export COMMIT_HASH=$(git rev-parse HEAD)
export COMMIT_HASH_SHORT=$(git rev-parse --short HEAD)
export BUILT_AT=$(LC_ALL=C date -u '+%d %B %Y %r (UTC)')
export ROOT="github.com/${GITHUB_REPOSITORY}"
export IMPORT_VERSION="${ROOT}/internal/${SERVICE}/version"
export LDFLAGS="-w -s -X '${IMPORT_VERSION}.Version=${GIT_TAG}' \
-X '${IMPORT_VERSION}.APIVersion=${API_VERSION}' \
-X '${IMPORT_VERSION}.CommitHash=${COMMIT_HASH}' \
-X '${IMPORT_VERSION}.BuiltAt=${BUILT_AT}'"; \

echo "${LDFLAGS}"

for arch in amd64 arm64; do
    echo "[$arch] Go build"
    for d in `ls cmd` ; do
        if [ $d == $SERVICE ]; then
            GOOS=linux GOARCH=$arch GO111MODULE=on CGO_ENABLED=0 go build -ldflags="${LDFLAGS}" -o ./bin/$arch/$SERVICE ./cmd/$d/main.go &&  echo -n "${COMMIT_HASH_SHORT} (${GIT_TAG})" > ./bin/$SERVICE.commit
        else
            GOOS=linux GOARCH=$arch  GO111MODULE=on CGO_ENABLED=0 go build -ldflags="${LDFLAGS}" -o ./bin/$arch/$SERVICE-$d ./cmd/$d/main.go && echo -n "${COMMIT_HASH_SHORT} (${GIT_TAG})"> ./bin/$SERVICE-$d.commit
        fi
        if [ $? -ne 0 ]; then
            echo "[$arch] An error has occurred! Aborting go build..."
            exit 1
        fi
    done

    echo "Build service: $SERVICE platform: $arch completed!"
done