#!/bin/sh
platform=$(xcrun --sdk macosx --show-sdk-path)
swiftc -sdk $platform swift_decisions.swift

