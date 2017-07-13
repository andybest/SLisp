#!/bin/sh

INSTALL_ROOT=/usr/local/opt/slisp

swift build -c release -Xswiftc -static-stdlib
pushd .build/release > /dev/null
mkdir -p $INSTALL_ROOT
mkdir -p $INSTALL_ROOT/bin
cp SLisp $INSTALL_ROOT/bin
popd > /dev/null

cp -R stdlib $INSTALL_ROOT
