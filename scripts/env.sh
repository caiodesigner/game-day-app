#!/usr/bin/env bash
# Use: source scripts/env.sh (a partir de qualquer diretório).
PUZZLE_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
export FLUTTER_ROOT="$PUZZLE_ROOT/.tools/flutter"
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"
export JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-21-openjdk-amd64}"
export PUB_CACHE="$PUZZLE_ROOT/.tools/pub-cache"
export GRADLE_USER_HOME="$PUZZLE_ROOT/.tools/gradle"
export PATH="$FLUTTER_ROOT/bin:$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
