#!/bin/bash

#cd $1
OUTDIR=".lint"

echo $(pwd)
echo "creating temp dir $OUTDIR"
mkdir -p $OUTDIR

echo "running go mod tidy..."
go mod tidy

echo "running goimports..."
goimports -local "git.garena.com" -w $(find . -name \*.go -not -name \*.pb.go)

echo "running golangci-lint..."
golangci-lint run --timeout=3m0s --build-tags=integration \
$(if [ ! -f .golangci.yml ]; then 
    echo "--enable goimports,govet,dupl,exportloopref,goconst,bodyclose,dogsled,misspell,unparam";
fi) \
./... | tee "$OUTDIR/gcilint.out"
RC=( "${PIPESTATUS[@]}" )
[ "${RC[0]}" -eq "0" ] || exit 1

echo "running tests..."
go test -race -tags=integration \
-coverprofile=$OUTDIR/coverage.out \
./...
