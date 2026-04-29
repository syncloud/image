#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd "$DIR"

go mod tidy
CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o platform-diff .
