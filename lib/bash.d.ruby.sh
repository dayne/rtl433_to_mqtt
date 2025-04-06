#!/bin/bash

# Get the version Ruby uses for gem directory paths
RUBY_ABI_VERSION=$(ruby -e 'require "rbconfig"; puts RbConfig::CONFIG["ruby_version"]' 2>/dev/null)

if [ -z "$RUBY_ABI_VERSION" ]; then
  echo "❌ Ruby not found or RbConfig broken. Unable to setup bundler in path"
  exit 1
fi

# Construct the correct path
LOCAL_GEM_BIN="$HOME/.local/share/gem/ruby/$RUBY_ABI_VERSION/bin"
echo "🔧 Exporting PATH with Ruby gem bin: $LOCAL_GEM_BIN"
export PATH="$LOCAL_GEM_BIN:$PATH"
