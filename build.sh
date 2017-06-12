#!/bin/sh

swift build
mkdir -p .build/debug/Lib
cp ./Lib/* .build/debug/Lib/
