#!/usr/bin/env bash

# Executes cargo from the pinned nixpkgs
#
# Example: ./cargo.sh test

mydir=$(dirname "$0")

nix run "(import $mydir/../nixpkgs.nix { config = {}; }).cargo" -c cargo $*