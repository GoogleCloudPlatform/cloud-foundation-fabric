TFDOC_GO_FILES := $(shell find src -name '*.go' -o -name 'go.mod')

tfdoc: $(TFDOC_GO_FILES)
	cd src && go build -o ../tfdoc ./cmd/tfdoc
