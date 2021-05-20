#!/bin/bash

#cd $1
OUTDIR="lint"

# Set ENABLE_SONARQUBE to 1 to run sonar-scanner and upload results to sonarqube
ENABLE_SONARQUBE=0

echo $(pwd)
echo "creating temp dir $OUTDIR"
mkdir -p $OUTDIR

echo "running go mod tidy..."
go mod tidy

echo "running goimports..."
goimports -local "git.garena.com" -w $(find . -name \*.go -not -name \*.pb.go)

# We still run golint here despite being included in golangci-lint 
# because golangci-lint suppresses some golint issues
echo "running golint..."
golint ./...

echo "running golangci-lint..."
golangci-lint run --verbose --timeout=3m0s \
$(if [ "$ENABLE_SONARQUBE" -eq "1" ]; then
   echo "--out-format checkstyle";
fi) \
$(if [ ! -f .golangci.yml ]; then 
    echo "--enable goimports,govet,golint,dupl,exportloopref,goconst,bodyclose,dogsled,funlen,misspell,unparam";
fi) \
./... | tee "$OUTDIR/gcilint.out"

echo "running tests..."
go test -race -tags=integration \
-coverprofile=$OUTDIR/coverage.out \
./...

if [ "$ENABLE_SONARQUBE" -eq "1" ]; then
    echo "SONAR_HOST_URL: $SONAR_HOST_URL"
    echo "SONAR_LOGIN_KEY: $SONAR_LOGIN"

    docker run \
    --rm \
    -e SONAR_HOST_URL="$SONAR_HOST_URL" \
    -e SONAR_LOGIN="$SONAR_LOGIN" \
    -v "$(pwd):/usr/src" \
    sonarsource/sonar-scanner-cli \
    -Dsonar.projectKey="$(echo $(basename $(pwd)):$(git rev-parse --abbrev-ref HEAD) | sed -e 's/[^A-Za-z0-9._:-]/-/g')" \
    -Dsonar.go.golangci-lint.reportPaths="$OUTDIR/gcilint.out" \
    -Dsonar.go.coverage.reportPaths="$OUTDIR/coverage.out" \
    -Dsonar.exclusions="spex/gen/**/*"
fi

echo "removing temp dir $OUTDIR"
rm -rf $OUTDIR
