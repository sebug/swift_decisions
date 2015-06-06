#!/bin/sh
platform=$(xcrun --sdk macosx --show-sdk-path)
# First, build hpple
pushd hpple/Pod/Classes
clang -I /usr/include/libxml2 -c *.m
ar rcs libhpple.a *.o
popd
swiftc -sdk $platform -I HppleModule  -L hpple/Pod/Classes -lhpple -lxml2 swift_decisions.swift

