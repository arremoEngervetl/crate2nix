#
# Some tools that might be useful in builds.
#
# Part of the "public" API of crate2nix in the sense that we will try to
# avoid breaking the API and/or mention breakages in the CHANGELOG.
#

{ pkgs? import ./nixpkgs.nix { config = {}; }, lib? pkgs.lib}:

let 
  cargo_nix = pkgs.callPackage ./crate2nix/Cargo.nix {};
  crate2nix = cargo_nix.rootCrate.build;

  # Returns a derivation with all the transitive dependencies in
  # sub directories suitable for cargo vendoring.
  vendoredCratesIoDependencies = { cargoLock? ./Cargo.lock }:
    let 
      locked = builtins.fromTOML (builtins.readFile cargoLock);
      # hashesFile = "${dirOf cargoLock}/crate-hashes.json";
      # hashes = 
      #   if builtins.pathExists hashesFile
      #   then builtins.fromJSON (builtins.readFile hashesFile)
      #   else {};

      # Unpack sources and add a .cargo-checksum.json file to make cargo happy.
      unpacked = sha256: source: 
        assert builtins.isString sha256;
        assert builtins.isAttrs source;

        pkgs.runCommand (lib.removeSuffix ".tar.gz" source.name) {}
        ''
          mkdir -p $out
          tar -xzf ${source} --strip-components=1 -C $out
          echo '{"package":"${sha256}","files":{}}' > $out/.cargo-checksum.json
        '';

      crateSource = package:
        assert builtins.isAttrs package;

        with package; 
        let sha256 = 
          package.checksum 
          or locked.metadata."checksum ${name} ${version} (${source})"
          or (builtins.throw "Checksum for ${name} ${version} (${source}) not found");
        in unpacked sha256 (pkgs.fetchurl {
          name = "crates-io-${name}-${version}.tar.gz";
          url = "https://crates.io/api/v1/crates/${name}/${version}/download";
          inherit sha256;
        });

      cratesIoPackages = 
        builtins.filter 
          (p: p ? source && p.source == "registry+https://github.com/rust-lang/crates.io-index") 
          locked.package;

      crateSources = 
        builtins.map 
          (package: 
            let source = crateSource package;
            in 
            {
              name = builtins.baseNameOf source; 
              path = source; 
            })
          cratesIoPackages;
    in 
      pkgs.linkFarm "deps" crateSources;

  vendorConfig = { cargoLock? ./Cargo.lock }:
    let
      cratesIoDeps = vendoredCratesIoDependencies { inherit cargoLock; };
    in
      pkgs.writeText
        "vendor-config"
        ''
        [source.crates-io]
        replace-with = "vendored-sources"

        [source.vendored-sources]
        directory = "${cratesIoDeps}"      
        '';

in rec {

  # Returns the whole expression (top-level function) generated by crate2nix.
  #
  # name: will be part of the derivation name
  # src: the source that is needed to build the crate, usually the crate/workspace root directory
  # cargoToml: Path to the Cargo.toml file relative to src, "Cargo.toml" by default.
  generate = {name, src, cargoToml? "Cargo.toml", additionalCargoNixArgs? []}: 
    let 
      cargoLock = (dirOf "${src}/${cargoToml}") + "/Cargo.lock";
      cargoConfig = vendorConfig { inherit cargoLock; };
    in
      pkgs.stdenv.mkDerivation ({
        name = "${name}-crate2nix";

        buildInputs = [ pkgs.cargo crate2nix ];

        buildCommand = ''
            mkdir -p "$out/cargo"

            export CARGO_HOME="$out/cargo"
            export HOME="$out"

            cp ${cargoConfig} $out/cargo/config

            crate2nix generate \
              ${lib.escapeShellArgs additionalCargoNixArgs}\
              -f ${src}/${cargoToml} \
              -o $out/default.nix
        '';
    });

  # Returns a derivation for a rust binary package.
  #
  # name: will be part of the derivation name
  # src: the source that is needed to build the crate, usually the crate/workspace root directory
  # cargoToml: Path to the Cargo.toml file relative to src, "Cargo.toml" by default.
  generated = {name, src, cargoToml? "Cargo.toml"} @ args:
    pkgs.callPackage (generate args) {};


}

