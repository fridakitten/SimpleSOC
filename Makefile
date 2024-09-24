# Makefile

all:
	swiftc -sdk $(shell xcrun --show-sdk-path) Compiler.swift -o Compiler
	swiftc -sdk $(shell xcrun --show-sdk-path) SeanSOC.swift -o SOC 
