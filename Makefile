# Compiler
CC = gcc
CFLAGS = -O2 -Wall

# Platform detection
ifeq ($(OS),Windows_NT)
    TARGET = build/edge_detection.dll
    LDFLAGS = -shared -lm
    MKDIR = if not exist build mkdir build
else
    TARGET = build/edge_detection.so
    LDFLAGS = -shared -fPIC -lm
    MKDIR = mkdir -p build
endif

# Source files
SRC = src/edge_detection.c

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(SRC) src/edge_detection.h
	$(MKDIR)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $(TARGET) $(SRC)

clean:
ifeq ($(OS),Windows_NT)
	if exist build rmdir /s /q build
else
	rm -rf build
endif
