export

# Project specific variables
PROJECT=lol-server

# --- the rest of the file should not need to be configured ---

# GO env
GOPATH=$(shell pwd)
GO=go
GOCMD=GOPATH=$(GOPATH) $(GO)

# Build versioning
COMMIT = $(shell git log -1 --format="%h" 2>/dev/null || echo "0")
VERSION=$(shell git describe --tags --always)
BUILD_DATE = $(shell date -u +%Y-%m-%dT%H:%M:%SZ)
FLAGS = -ldflags "\
  -X $(PROJECT)/constants.COMMIT=$(COMMIT) \
  -X $(PROJECT)/constants.VERSION=$(VERSION) \
  -X $(PROJECT)/constants.BUILD_DATE=$(BUILD_DATE) \
  "

GOBUILD = $(GOCMD) build $(FLAGS)

# Protocol buffers stuff
PROTOROOT = ./protobuf
PROTOPATHPRJ = $(PROTOROOT)/$(PROJECT)
PROTOPATHVENDOR = $(PROTOROOT)/vendor
PROTOOUT = ./src
PROTOSWAGGER = $(PROTOROOT)/swagger
PROTODEPS = ./.proto_generated

PROTOPATHFLAGS = --proto_path=$(PROTOPATHPRJ) --proto_path=$(PROTOPATHVENDOR)
#--dependency_out=$(PROTODEPS).tmp

.PHONY: all
all:	build

.PHONY: build
build: proto format test
	$(GOBUILD) -o bin/$(PROJECT) $(PROJECT)

.PHONY: proto
proto:
	@if ! which protoc > /dev/null; then \
		echo "error: protoc not installed" >&2; \
		exit 1; \
	fi
	./makeproto.sh

.PHONY: format
format:
	@for gofile in $$(find ./src/$(PROJECT) -name "*.go"); do \
		echo "formatting" $$gofile; \
		gofmt -w $$gofile; \
	done

.PHONY: run
run: build
	$(GOPATH)/bin/$(PROJECT)

.PHONY: test
test:
	$(GOCMD) test ./src/$(PROJECT)/... -cover

.PHONY: coverage
coverage:
	rm -fr coverage
	mkdir -p coverage
	$(GOCMD) list $(PROJECT)/... > coverage/packages
	@i=a ; \
	while read -r P; do \
		i=a$$i ; \
		$(GOCMD) test ./src/$$P -cover -covermode=count -coverprofile=coverage/$$i.out; \
	done <coverage/packages

	echo "mode: count" > coverage/coverage
	cat coverage/*.out | grep -v "mode: count" >> coverage/coverage
	$(GOCMD) tool cover -html=coverage/coverage

.PHONY: cleanvendor
cleanvendor:
	@for pattern in *_test.go .travis.yml LICENSE Makefile CONTRIBUTORS .gitattributes AUTHORS PATENTS README; do \
		echo 'Deleting' $$pattern ; \
		find src/vendor -name $$pattern -delete; \
	done
	@for pattern in */testdata/*; do \
		echo 'Deleting' $$pattern ; \
		find src/vendor -path $$pattern -delete; \
	done
