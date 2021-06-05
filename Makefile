SRC = ./src
SRC_FILES = $(shell find $(SRC) -type f -name "*.js")
ENTRY_FILE = $(SRC)/index.js
DEPS = ./node_modules
LOCAL_BIN = $(DEPS)/.bin
OUT_FILE = docker-ast

.PHONY: clean cleanall

build: $(OUT_FILE)

$(OUT_FILE): $(DEPS) $(SRC_FILES)
	$(LOCAL_BIN)/nexe $(ENTRY_FILE) --build -o $(OUT_FILE)

deps: $(DEPS)

$(DEPS):
	npm ci

clean:
	-rm ./$(OUT_FILE)

cleanall: clean
	-rm -rf $(DEPS)
