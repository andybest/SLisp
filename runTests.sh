#!/bin/sh

./install.sh
pushd stdlibTests > /dev/null
slisp test-suite.sl
popd > /dev/null
