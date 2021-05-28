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

# We still run golint here despite it being included in golangci-lint 
# because golangci-lint suppresses some golint issues
echo "running golint..."
golint ./...

echo "running golangci-lint..."
golangci-lint run --verbose --timeout=3m0s --build-tags=integration \
$(if [ ! -f .golangci.yml ]; then 
    echo "--enable goimports,govet,golint,dupl,exportloopref,goconst,bodyclose,dogsled,funlen,misspell,unparam,lll";
fi) \
./... | tee "$OUTDIR/gcilint.out"

echo "running tests..."
go test -race -tags=integration \
-coverprofile=$OUTDIR/coverage.out \
./...
