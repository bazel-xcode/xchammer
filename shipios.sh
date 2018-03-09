#!/bin/bash

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <path/to/ios/repo>"
  exit 1
fi

ln -sf $1 ios-building

