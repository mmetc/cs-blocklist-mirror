# Go parameters
GOCMD=go
GOBUILD=$(GOCMD) build
GOCLEAN=$(GOCMD) clean
GOTEST=$(GOCMD) test
GOGET=$(GOCMD) get

GOOS ?= linux
GOARCH ?= amd64

# Current versioning information from env
BUILD_VERSION?="$(shell git describe --tags)"
BUILD_GOVERSION="$(shell go version | cut -d " " -f3 | sed -r 's/[go]+//g')"
BUILD_TIMESTAMP=$(shell date +%F"_"%T)
BUILD_TAG="$(shell git rev-parse HEAD)"

LD_OPTS_VARS=\
-X 'github.com/crowdsecurity/cs-blocklist-mirror/version.Version=$(BUILD_VERSION)' \
-X 'github.com/crowdsecurity/cs-blocklist-mirror/version.BuildDate=$(BUILD_TIMESTAMP)' \
-X 'github.com/crowdsecurity/cs-blocklist-mirror/version.Tag=$(BUILD_TAG)' \
-X 'github.com/crowdsecurity/cs-blocklist-mirror/version.GoVersion=$(BUILD_GOVERSION)'

ifdef BUILD_STATIC
	export LD_OPTS=-ldflags "-a -v -s -w -extldflags '-static' $(LD_OPTS_VARS)" -tags netgo
else
	export LD_OPTS=-ldflags "-a -v -s -w $(LD_OPTS_VARS)"
endif

PREFIX?="/"
BINARY_NAME=crowdsec-blocklist-mirror

RELDIR = "crowdsec-blocklist-mirror-${BUILD_VERSION}"

all: clean build

goversion:
	CURRENT_GOVERSION="$(shell go version | cut -d " " -f3 | sed -r 's/[go]+//g')"
	REQUIRE_GOVERSION="1.17"
	RESPECT_VERSION="$(shell echo "$(CURRENT_GOVERSION),$(REQUIRE_GOVERSION)" | tr ',' '\n' | sort -V)"

build: goversion clean
	$(GOBUILD) $(LD_OPTS) -o $(BINARY_NAME)

clean:
	@rm -f $(BINARY_NAME)
	@rm -rf ${RELDIR}
	@rm -f crowdsec-blocklist-mirror-*.tgz || ""

.PHONY: release
release: build
	@if [ -z ${BUILD_VERSION} ] ; then BUILD_VERSION="local" ; fi
	@if [ -d $(RELDIR) ]; then echo "$(RELDIR) already exists, clean" ;  exit 1 ; fi
	@echo Building Release to dir $(RELDIR)
	@mkdir $(RELDIR)/
	@cp $(BINARY_NAME) $(RELDIR)/
	@cp -R ./config $(RELDIR)/
	@cp ./scripts/install.sh $(RELDIR)/
	@cp ./scripts/uninstall.sh $(RELDIR)/
	@cp ./scripts/upgrade.sh $(RELDIR)/
	@chmod +x $(RELDIR)/install.sh
	@chmod +x $(RELDIR)/uninstall.sh
	@chmod +x $(RELDIR)/upgrade.sh
	@tar cvzf crowdsec-blocklist-mirror-$(GOOS)-$(GOARCH).tgz $(RELDIR)
