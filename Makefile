# Source files
SRC = ./src
SRC_FILES = $(shell find $(SRC) -type f -name "*.js")
ENTRY_FILE = $(SRC)/index.js

# Dependencies
DEPS = ./node_modules
# Used trick from https://stackoverflow.com/a/34455370
PYTHON_PATH = $(firstword $(shell which python2 python python3))
LOCAL_BIN = $(DEPS)/.bin

# Output
OUT_FILE = docker-ast

.PHONY: clean cleanall

build: $(OUT_FILE)

# Taken partially from https://github.com/nexe/nexe/issues/887#issue-863480184
$(OUT_FILE): $(DEPS) $(SRC_FILES)
	$(LOCAL_BIN)/nexe $(ENTRY_FILE) --build --output $(OUT_FILE) --make="-j$(shell nproc 2> /dev/null || echo 1)" --python $(PYTHON_PATH)

deps: $(DEPS)

$(DEPS):
	npm ci

clean:
	-rm ./$(OUT_FILE)

cleanall: clean
	-$(LOCAL_BIN)/nexe $(ENTRY_FILE) --clean
	-rm -rf $(DEPS)
