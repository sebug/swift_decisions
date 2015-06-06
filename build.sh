#!/bin/sh
platform=$(xcrun --sdk macosx --show-sdk-path)
clang -c HTMLParsing/html_parsing.c
ar rcs libHTMLParsing.a html_parsing.o
mv libHTMLParsing.a HTMLParsing/libHTMLParsing.a
swiftc -sdk $platform -I HTMLParsing -L HTMLParsing -lHTMLParsing swift_decisions.swift

