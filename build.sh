CONFIGURATION=${1:-debug}
set -ex
swift package --swift-sdk swift-6.2.1-RELEASE_wasm --enable-experimental-prebuilts js --use-cdn -c $CONFIGURATION
swift postbuild.swift
