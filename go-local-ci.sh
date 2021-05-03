#!/bin/bash

#cd $1
OUTDIR="sonarout"
echo $(pwd)
echo "creating temp dir $OUTDIR"
mkdir -p $OUTDIR
echo "running tests..."
go test -coverprofile=$OUTDIR/coverage.out -race $(go list ./...)
echo "running golint..."
golint ./...
echo "running golangci-lint..."
golangci-lint run --verbose --timeout=20m0s --out-format checkstyle \
$(if [ ! -f .golangci.yml ]; 
    then echo "--enable goimports,golint,dupl,exportloopref,goconst,bodyclose,dogsled,funlen,misspell,unparam"; 
fi) ./... | tee "$OUTDIR/gcilint.out"

# For sonarqube display
# docker run \
#     --rm \
#     -e SONAR_HOST_URL="$SONARQUBE_URL" \
#     -e SONAR_LOGIN="$SONARQUBE_LOGIN" \
#     -v "$(pwd):/usr/src" \
#     sonarsource/sonar-scanner-cli \
#     -Dsonar.projectKey="$(echo $(basename $(pwd)):$(git rev-parse --abbrev-ref HEAD) | sed -e 's/[^A-Za-z0-9._:-]/-/g')" \
#     -Dsonar.go.golangci-lint.reportPaths="$OUTDIR/gcilint.out" \
#     -Dsonar.go.coverage.reportPaths="$OUTDIR/coverage.out" \
#     -Dsonar.exclusions="spex/gen/**/*"
echo "removing temp dir $OUTDIR"
rm -rf $OUTDIR