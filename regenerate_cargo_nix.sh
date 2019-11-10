#!/usr/bin/env bash

echo "================ Regenerating ./Cargo.nix =================="

(cd crate2nix; cargo run -- "generate" "-n" "../nixpkgs.nix" \
  "-f" "./Cargo.toml" "-o" "./Cargo.nix")  ||\
     { echo "Bootstrap regeneration of ./Cargo.nix failed." >&2 ; exit 1; }

nix-shell --run 'crate2nix "generate" "-n" "./nixpkgs.nix" \
  "-f" "./crate2nix/Cargo.toml" "-o" "./crate2nix/Cargo.nix"'  ||\
     { echo "Regeneration of ./Cargo.nix failed." >&2 ; exit 1; }

nix eval --json -f ./tests.nix buildTestConfigs |\
 jq -r .[].pregeneratedBuild |\
 while read cargo_nix; do
   if [ "$cargo_nix" = "null" ]; then
     continue
   fi

   dir=$(dirname "$cargo_nix")

   echo "=============== Regenerating ${cargo_nix} ================"

   nix-shell --run "crate2nix generate -f \"$dir/Cargo.toml\" -o \"$cargo_nix\"" ||\
     { echo "Regeneration of ${cargo_nix} failed." >&2 ; exit 1; }
 done
