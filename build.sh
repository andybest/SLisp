#!/bin/sh

swift build
mkdir -p .build/debug/data
cp ./Lib/* .build/debug/data/
