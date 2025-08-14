#!/bin/bash

SOURCE_DIR=${PWD}/source
BUILD_DIR=${PWD}/build
OUTPUT_DIR=${PWD}/output

MAKE_JOBS=$(nproc)

COLOR_STATUS=$'\033[1m\033[32m'
COLOR_RESET=$'\033[0m'

show_status() {
  echo "$COLOR_STATUS=> $1$COLOR_RESET"
}
check_run() {
  echo "Running: $*"
  "$@"
  local STATUS=$?
  if (( $STATUS != 0 )); then
    echo "ERROR: Command failed with exit code $STATUS: $*"
    echo "Current working directory: $(pwd)"
    echo "Available disk space: $(df -h . | tail -1 | awk '{print $4}')"
    echo "Available memory: $(free -h | grep "Mem:" | awk '{print $7}')"
    exit $STATUS
  fi
}

check_system_resources() {
  show_status "Checking system resources"
  
  # Check available disk space (need at least 2GB)
  local disk_available=$(df /tmp | tail -1 | awk '{print $4}')
  if [ "$disk_available" -lt 2097152 ]; then # Less than 2GB in KB
    echo "WARNING: Low disk space detected: $(df -h /tmp | tail -1 | awk '{print $4}') available"
  fi
  
  # Check available memory (need at least 2GB)
  local mem_available=$(free | grep "Mem:" | awk '{print $7}')
  if [ "$mem_available" -lt 2097152 ]; then # Less than 2GB in KB
    echo "WARNING: Low memory detected: $(free -h | grep "Mem:" | awk '{print $7}') available"
    echo "Reducing parallel jobs from $MAKE_JOBS to 1"
    export MAKE_JOBS=1
  fi
  
  # Check CPU cores
  local cpu_cores=$(nproc)
  echo "System info: $cpu_cores CPU cores, $(free -h | grep "Mem:" | awk '{print $2}') total memory, $(df -h /tmp | tail -1 | awk '{print $2}') disk space"
}

shopt -s nullglob

load_quirks() {
  if [ ! -z "$1" ]; then
    show_status "Loading quirks file: $1"
    source "$1"
  fi
}

call_quirk() {
  local QUIRK_NAME="quirk_$1"
  QUIRK_NAME=`declare -f -F "$QUIRK_NAME"`
  if (( $? == 0 )); then
    show_status "Executing $QUIRK_NAME"
    $QUIRK_NAME
  fi
}

create_build_directories() {
  mkdir -p $SOURCE_DIR
  mkdir -p $BUILD_DIR
  mkdir -p $OUTPUT_DIR
}

# Enhanced git operations with retry logic
check_run_with_retry() {
  local max_attempts=3
  local attempt=1
  local delay=5
  
  while [ $attempt -le $max_attempts ]; do
    echo "Running (attempt $attempt/$max_attempts): $*"
    if "$@"; then
      return 0
    fi
    
    local STATUS=$?
    if [ $attempt -eq $max_attempts ]; then
      echo "ERROR: Command failed after $max_attempts attempts with exit code $STATUS: $*"
      echo "Current working directory: $(pwd)"
      echo "Available disk space: $(df -h . | tail -1 | awk '{print $4}')"
      echo "Available memory: $(free -h | grep "Mem:" | awk '{print $7}')"
      exit $STATUS
    fi
    
    echo "Command failed, retrying in $delay seconds..."
    sleep $delay
    ((attempt++))
    ((delay *= 2))  # Exponential backoff
  done
}

download_repo() {
  if [ -d $SOURCE_DIR/$1 ]; then
    show_status "Updating $2"
    pushd $SOURCE_DIR/$1
    check_run_with_retry git fetch origin $3
    check_run git reset --hard FETCH_HEAD
    check_run git submodule update --init --recursive
    popd
  else
    show_status "Downloading $2"
    mkdir -p $SOURCE_DIR/$1
    pushd $SOURCE_DIR/$1
    check_run git init
    check_run_with_retry git remote add origin $2
    check_run_with_retry git fetch origin $3
    check_run git reset --hard FETCH_HEAD
    check_run git submodule update --init --recursive
    popd
  fi
  
  # Validate downloaded commit hash
  pushd $SOURCE_DIR/$1
  local actual_commit=$(git rev-parse HEAD)
  if [ "$actual_commit" != "$3" ]; then
    echo "WARNING: Downloaded commit $actual_commit doesn't match expected $3"
  else
    show_status "Successfully downloaded $1 at commit $3"
  fi
  popd
}

reset_cmake_options() {
  CMAKE_OPTIONS=()
}

add_cmake_options() {
  CMAKE_OPTIONS=("${CMAKE_OPTIONS[@]}" "$@")
}

build_component() {
  show_status "Building $1"
  mkdir -p $BUILD_DIR/$1
  pushd $BUILD_DIR/$1
  echo "cmake" $CMAKE_OPTIONS "$SOURCE_DIR/$1"
  check_run cmake "${CMAKE_OPTIONS[@]}" "$SOURCE_DIR/$1"
  
  # Use appropriate build tool based on generator
  if [ -f "build.ninja" ]; then
    check_run ninja -j${MAKE_JOBS}
  else
    check_run make -j${MAKE_JOBS}
  fi
  popd
}
install_component_cpack() {
  pushd $OUTPUT_DIR
  for cf in $BUILD_DIR/$1/**/CPackConfig.cmake; do
    echo "CPack config: $cf"
    check_run cpack --config $cf
  done
  popd
}

cleanup_build() {
  rm -rf $OUTPUT_DIR/_CPack_Packages
}
