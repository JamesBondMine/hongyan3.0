#!/bin/bash

# Check if a proto file name is provided as an argument
if [ $# -eq 0 ]; then
    echo "Usage: $0 <proto_file_name>"
    echo "Example: $0 group_pb.proto"
    exit 1
fi

# Get the proto file name from command line argument
PROTO_FILE_NAME="$1"
PROTO_DIR="$(pwd)"  # Current directory
PROTO_FILE="$PROTO_DIR/$PROTO_FILE_NAME"
OUTPUT_DIR="$PROTO_DIR"

# Check if protoc is available
if ! command -v protoc &> /dev/null; then
    echo "Error: protoc is not installed or not in PATH"
    exit 1
fi

# Check if the proto file exists
if [ ! -f "$PROTO_FILE" ]; then
    echo "Error: Proto file does not exist: $PROTO_FILE"
    exit 1
fi

# Generate Objective-C files from the specified proto file
echo "Generating iOS Objective-C files from $PROTO_FILE..."
protoc --objc_out="$OUTPUT_DIR" \
       --proto_path="$PROTO_DIR" \
       "$PROTO_FILE"

# Check if generation was successful
if [ $? -eq 0 ]; then
    # Extract base name without extension for the output files
    BASE_NAME=$(basename "$PROTO_FILE_NAME" .proto)
    echo "Successfully generated:"
    echo "- ${BASE_NAME}.pbobjc.h"
    echo "- ${BASE_NAME}.pbobjc.m"
    echo "Files saved in: $OUTPUT_DIR"
else
    echo "Error: Failed to generate Objective-C files"
    exit 1
fi
