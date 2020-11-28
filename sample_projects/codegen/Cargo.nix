
# This file was @generated by crate2nix 0.9.0-alpha.1 with the command:
#   "generate" "-f" "sample_projects/codegen/Cargo.toml" "-o" "sample_projects/codegen/Cargo.nix"
# See https://github.com/kolloch/crate2nix for more info.

{ nixpkgs ? <nixpkgs>
, pkgs ? import nixpkgs { config = {}; }
, lib ? pkgs.lib
, stdenv ? pkgs.stdenv
, buildRustCrate ? pkgs.buildRustCrate
  # This is used as the `crateOverrides` argument for `buildRustCrate`.
, defaultCrateOverrides ? pkgs.defaultCrateOverrides
  # The features to enable for the root_crate or the workspace_members.
, rootFeatures ? [ "default" ]
  # If true, throw errors instead of issueing deprecation warnings.
, strictDeprecation ? false
  # Used for conditional compilation based on CPU feature detection.
, targetFeatures ? []
  # Whether to perform release builds: longer compile times, faster binaries.
, release ? true
  # Additional crate2nix configuration if it exists.
, crateConfig
  ? if builtins.pathExists ./crate-config.nix
    then pkgs.callPackage ./crate-config.nix {}
    else {}
}:

rec {
  #
  # "public" attributes that we attempt to keep stable with new versions of crate2nix.
  #

  rootCrate = rec {
    packageId = "codegen";

    # Use this attribute to refer to the derivation building your root crate package.
    # You can override the features with rootCrate.build.override { features = [ "default" "feature1" ... ]; }.
    build = internal.buildRustCrateWithFeatures {
      inherit packageId;
    };

    # Debug support which might change between releases.
    # File a bug if you depend on any for non-debug work!
    debug = internal.debugCrate { inherit packageId; };
  };
  # Refer your crate build derivation by name here.
  # You can override the features with
  # workspaceMembers."${crateName}".build.override { features = [ "default" "feature1" ... ]; }.
  workspaceMembers = {
    "codegen" = rec {
      packageId = "codegen";
      build = internal.buildRustCrateWithFeatures {
        packageId = "codegen";
      };

      # Debug support which might change between releases.
      # File a bug if you depend on any for non-debug work!
      debug = internal.debugCrate { inherit packageId; };
    };
  };

  # A derivation that joins the outputs of all workspace members together.
  allWorkspaceMembers = pkgs.symlinkJoin {
      name = "all-workspace-members";
      paths =
        let members = builtins.attrValues workspaceMembers;
        in builtins.map (m: m.build) members;
  };

  #
  # "internal" ("private") attributes that may change in every new version of crate2nix.
  #

  internal = rec {
    # Build and dependency information for crates.
    # Many of the fields are passed one-to-one to buildRustCrate.
    #
    # Noteworthy:
    # * `dependencies`/`buildDependencies`: similar to the corresponding fields for buildRustCrate.
    #   but with additional information which is used during dependency/feature resolution.
    # * `resolvedDependencies`: the selected default features reported by cargo - only included for debugging.
    # * `devDependencies` as of now not used by `buildRustCrate` but used to
    #   inject test dependencies into the build

    crates = {
      "ansi_term" = rec {
        crateName = "ansi_term";
        version = "0.11.0";
        edition = "2015";
        sha256 = "16wpvrghvd0353584i1idnsgm0r3vchg8fyrm0x8ayv1rgvbljgf";
        authors = [
          "ogham@bsago.me"
          "Ryan Scheel (Havvy) <ryan.havvy@gmail.com>"
          "Josh Triplett <josh@joshtriplett.org>"
        ];
        dependencies = [
          {
            name = "winapi";
            packageId = "winapi";
            target = { target, features }: (target."os" == "windows");
            features = [ "errhandlingapi" "consoleapi" "processenv" ];
          }
        ];
        
      };
      "atty" = rec {
        crateName = "atty";
        version = "0.2.13";
        edition = "2015";
        sha256 = "140sswp1bwqwc4zk80bxkbnfb3g936hgrb77g9g0k1zcld3wc0qq";
        authors = [
          "softprops <d.tangren@gmail.com>"
        ];
        dependencies = [
          {
            name = "libc";
            packageId = "libc";
            usesDefaultFeatures = false;
            target = { target, features }: target."unix";
          }
          {
            name = "winapi";
            packageId = "winapi";
            target = { target, features }: target."windows";
            features = [ "consoleapi" "processenv" "minwinbase" "minwindef" "winbase" ];
          }
        ];
        
      };
      "bitflags 0.7.0" = rec {
        crateName = "bitflags";
        version = "0.7.0";
        edition = "2015";
        sha256 = "0v8hh6wdkpk9my8z8442g4hqrqf05h0qj53dsay6mv18lqvqklda";
        authors = [
          "The Rust Project Developers"
        ];
        
      };
      "bitflags 1.2.1" = rec {
        crateName = "bitflags";
        version = "1.2.1";
        edition = "2015";
        sha256 = "14qnd5nq8p2almk79m4m8ydqhd413yaxsyjp5xd19g3mikzf47fg";
        authors = [
          "The Rust Project Developers"
        ];
        features = {
        };
        resolvedDefaultFeatures = [ "default" ];
      };
      "clap" = rec {
        crateName = "clap";
        version = "2.33.0";
        edition = "2015";
        sha256 = "1nf6ld3bims1n5vfzhkvcb55pdzh04bbhzf8nil5vvw05nxzarsh";
        authors = [
          "Kevin K. <kbknapp@gmail.com>"
        ];
        dependencies = [
          {
            name = "ansi_term";
            packageId = "ansi_term";
            optional = true;
            target = { target, features }: (!target."windows");
          }
          {
            name = "atty";
            packageId = "atty";
            optional = true;
          }
          {
            name = "bitflags";
            packageId = "bitflags 1.2.1";
          }
          {
            name = "strsim";
            packageId = "strsim";
            optional = true;
          }
          {
            name = "textwrap";
            packageId = "textwrap";
          }
          {
            name = "unicode-width";
            packageId = "unicode-width";
          }
          {
            name = "vec_map";
            packageId = "vec_map";
            optional = true;
          }
        ];
        features = {
          "color" = [ "ansi_term" "atty" ];
          "default" = [ "suggestions" "color" "vec_map" ];
          "doc" = [ "yaml" ];
          "lints" = [ "clippy" ];
          "suggestions" = [ "strsim" ];
          "wrap_help" = [ "term_size" "textwrap/term_size" ];
          "yaml" = [ "yaml-rust" ];
        };
        resolvedDefaultFeatures = [ "ansi_term" "atty" "color" "default" "strsim" "suggestions" "vec_map" ];
      };
      "codegen" = rec {
        crateName = "codegen";
        version = "0.1.0";
        edition = "2018";
        crateBin = [
          { name = "codegen"; path = "src/main.rs"; }
        ];
        src = lib.cleanSourceWith { filter = sourceFilter;  src = ./.; };
        authors = [
          "Peter Kolloch <info@eigenvalue.net>"
        ];
        dependencies = [
          {
            name = "dbus";
            packageId = "dbus";
          }
        ];
        buildDependencies = [
          {
            name = "dbus-codegen";
            packageId = "dbus-codegen";
          }
        ];
        
      };
      "dbus" = rec {
        crateName = "dbus";
        version = "0.7.1";
        edition = "2018";
        workspace_member = null;
        src = pkgs.fetchgit {
          url = "https://github.com/diwic/dbus-rs/";
          rev = "b079366e27da1b9c2869f065fbb6004138e439c2";
          sha256 = "0lbp76vvi0cw57lxhfqmz22qd5l61w3rh8g58hhmwi8wcr9qmiiw";
        };
        authors = [
          "David Henningsson <diwic@ubuntu.com>"
        ];
        dependencies = [
          {
            name = "libc";
            packageId = "libc";
          }
          {
            name = "libdbus-sys";
            packageId = "libdbus-sys";
          }
        ];
        features = {
        };
      };
      "dbus-codegen" = rec {
        crateName = "dbus-codegen";
        version = "0.4.1";
        edition = "2018";
        crateBin = [];
        workspace_member = null;
        src = pkgs.fetchgit {
          url = "https://github.com/diwic/dbus-rs/";
          rev = "b079366e27da1b9c2869f065fbb6004138e439c2";
          sha256 = "0lbp76vvi0cw57lxhfqmz22qd5l61w3rh8g58hhmwi8wcr9qmiiw";
        };
        authors = [
          "David Henningsson <diwic@ubuntu.com>"
        ];
        dependencies = [
          {
            name = "clap";
            packageId = "clap";
          }
          {
            name = "dbus";
            packageId = "dbus";
          }
          {
            name = "xml-rs";
            packageId = "xml-rs";
          }
        ];
        
      };
      "libc" = rec {
        crateName = "libc";
        version = "0.2.66";
        edition = "2015";
        sha256 = "0n0mwry21fxfwc063k33mvxk8xj7ia5ar8m42c9ymbam2ksb25fm";
        authors = [
          "The Rust Project Developers"
        ];
        features = {
          "default" = [ "std" ];
          "rustc-dep-of-std" = [ "align" "rustc-std-workspace-core" ];
          "use_std" = [ "std" ];
        };
        resolvedDefaultFeatures = [ "default" "std" ];
      };
      "libdbus-sys" = rec {
        crateName = "libdbus-sys";
        version = "0.2.1";
        edition = "2015";
        workspace_member = null;
        src = pkgs.fetchgit {
          url = "https://github.com/diwic/dbus-rs/";
          rev = "b079366e27da1b9c2869f065fbb6004138e439c2";
          sha256 = "0lbp76vvi0cw57lxhfqmz22qd5l61w3rh8g58hhmwi8wcr9qmiiw";
        };
        authors = [
          "David Henningsson <diwic@ubuntu.com>"
        ];
        buildDependencies = [
          {
            name = "pkg-config";
            packageId = "pkg-config";
          }
        ];
        
      };
      "pkg-config" = rec {
        crateName = "pkg-config";
        version = "0.3.17";
        edition = "2015";
        sha256 = "0xynnaxdv0gzadlw4h79j855k0q7rj4zb9xb1vk00nc6ss559nh5";
        authors = [
          "Alex Crichton <alex@alexcrichton.com>"
        ];
        
      };
      "strsim" = rec {
        crateName = "strsim";
        version = "0.8.0";
        edition = "2015";
        sha256 = "0sjsm7hrvjdifz661pjxq5w4hf190hx53fra8dfvamacvff139cf";
        authors = [
          "Danny Guo <dannyguo91@gmail.com>"
        ];
        
      };
      "textwrap" = rec {
        crateName = "textwrap";
        version = "0.11.0";
        edition = "2015";
        sha256 = "0q5hky03ik3y50s9sz25r438bc4nwhqc6dqwynv4wylc807n29nk";
        authors = [
          "Martin Geisler <martin@geisler.net>"
        ];
        dependencies = [
          {
            name = "unicode-width";
            packageId = "unicode-width";
          }
        ];
        
      };
      "unicode-width" = rec {
        crateName = "unicode-width";
        version = "0.1.6";
        edition = "2015";
        sha256 = "082f9hv1r3gcd1xl33whjhrm18p0w9i77zhhhkiccb5r47adn1vh";
        authors = [
          "kwantam <kwantam@gmail.com>"
        ];
        features = {
          "rustc-dep-of-std" = [ "std" "core" "compiler_builtins" ];
        };
        resolvedDefaultFeatures = [ "default" ];
      };
      "vec_map" = rec {
        crateName = "vec_map";
        version = "0.8.1";
        edition = "2015";
        sha256 = "06n8hw4hlbcz328a3gbpvmy0ma46vg1lc0r5wf55900szf3qdiq5";
        authors = [
          "Alex Crichton <alex@alexcrichton.com>"
          "Jorge Aparicio <japaricious@gmail.com>"
          "Alexis Beingessner <a.beingessner@gmail.com>"
          "Brian Anderson <>"
          "tbu- <>"
          "Manish Goregaokar <>"
          "Aaron Turon <aturon@mozilla.com>"
          "Adolfo Ochagavía <>"
          "Niko Matsakis <>"
          "Steven Fackler <>"
          "Chase Southwood <csouth3@illinois.edu>"
          "Eduard Burtescu <>"
          "Florian Wilkens <>"
          "Félix Raimundo <>"
          "Tibor Benke <>"
          "Markus Siemens <markus@m-siemens.de>"
          "Josh Branchaud <jbranchaud@gmail.com>"
          "Huon Wilson <dbau.pp@gmail.com>"
          "Corey Farwell <coref@rwell.org>"
          "Aaron Liblong <>"
          "Nick Cameron <nrc@ncameron.org>"
          "Patrick Walton <pcwalton@mimiga.net>"
          "Felix S Klock II <>"
          "Andrew Paseltiner <apaseltiner@gmail.com>"
          "Sean McArthur <sean.monstar@gmail.com>"
          "Vadim Petrochenkov <>"
        ];
        features = {
          "eders" = [ "serde" ];
        };
      };
      "winapi" = rec {
        crateName = "winapi";
        version = "0.3.8";
        edition = "2015";
        sha256 = "1ii9j9lzrhwri0902652awifzx9fpayimbp6hfhhc296xcg0k4w0";
        authors = [
          "Peter Atashian <retep998@gmail.com>"
        ];
        dependencies = [
          {
            name = "winapi-i686-pc-windows-gnu";
            packageId = "winapi-i686-pc-windows-gnu";
            target = { target, features }: (stdenv.hostPlatform.config == "i686-pc-windows-gnu");
          }
          {
            name = "winapi-x86_64-pc-windows-gnu";
            packageId = "winapi-x86_64-pc-windows-gnu";
            target = { target, features }: (stdenv.hostPlatform.config == "x86_64-pc-windows-gnu");
          }
        ];
        features = {
          "debug" = [ "impl-debug" ];
        };
        resolvedDefaultFeatures = [ "consoleapi" "errhandlingapi" "minwinbase" "minwindef" "processenv" "winbase" ];
      };
      "winapi-i686-pc-windows-gnu" = rec {
        crateName = "winapi-i686-pc-windows-gnu";
        version = "0.4.0";
        edition = "2015";
        sha256 = "1dmpa6mvcvzz16zg6d5vrfy4bxgg541wxrcip7cnshi06v38ffxc";
        authors = [
          "Peter Atashian <retep998@gmail.com>"
        ];
        
      };
      "winapi-x86_64-pc-windows-gnu" = rec {
        crateName = "winapi-x86_64-pc-windows-gnu";
        version = "0.4.0";
        edition = "2015";
        sha256 = "0gqq64czqb64kskjryj8isp62m2sgvx25yyj3kpc2myh85w24bki";
        authors = [
          "Peter Atashian <retep998@gmail.com>"
        ];
        
      };
      "xml-rs" = rec {
        crateName = "xml-rs";
        version = "0.3.6";
        edition = "2015";
        crateBin = [];
        sha256 = "0qmm2nss16b0f46fp30s2ka8k50a5i03jlp36672qf38magc7iky";
        libName = "xml";
        authors = [
          "Vladimir Matveev <vladimir.matweev@gmail.com>"
        ];
        dependencies = [
          {
            name = "bitflags";
            packageId = "bitflags 0.7.0";
          }
        ];
        
      };
    };

    #
# crate2nix/default.nix (excerpt start)
#

  /* Target (platform) data for conditional dependencies.
     This corresponds roughly to what buildRustCrate is setting.
  */
  defaultTarget = {
    unix = true;
    windows = false;
    fuchsia = true;
    test = false;

    # This doesn't appear to be officially documented anywhere yet.
    # See https://github.com/rust-lang-nursery/rust-forge/issues/101.
    os =
      if stdenv.hostPlatform.isDarwin
      then "macos"
      else stdenv.hostPlatform.parsed.kernel.name;
    arch = stdenv.hostPlatform.parsed.cpu.name;
    family = "unix";
    env = "gnu";
    endian =
      if stdenv.hostPlatform.parsed.cpu.significantByte.name == "littleEndian"
      then "little" else "big";
    pointer_width = toString stdenv.hostPlatform.parsed.cpu.bits;
    vendor = stdenv.hostPlatform.parsed.vendor.name;
    debug_assertions = false;
  };

  /* Filters common temp files and build files. */
  # TODO(pkolloch): Substitute with gitignore filter
  sourceFilter = name: type:
    let
      baseName = builtins.baseNameOf (builtins.toString name);
    in
      ! (
        # Filter out git
        baseName == ".gitignore"
        || (type == "directory" && baseName == ".git")

        # Filter out build results
        || (
          type == "directory" && (
            baseName == "target"
            || baseName == "_site"
            || baseName == ".sass-cache"
            || baseName == ".jekyll-metadata"
            || baseName == "build-artifacts"
          )
        )

        # Filter out nix-build result symlinks
        || (
          type == "symlink" && lib.hasPrefix "result" baseName
        )

        # Filter out IDE config
        || (
          type == "directory" && (
            baseName == ".idea" || baseName == ".vscode"
          )
        ) || lib.hasSuffix ".iml" baseName

        # Filter out nix build files
        || baseName == "Cargo.nix"

        # Filter out editor backup / swap files.
        || lib.hasSuffix "~" baseName
        || builtins.match "^\\.sw[a-z]$$" baseName != null
        || builtins.match "^\\..*\\.sw[a-z]$$" baseName != null
        || lib.hasSuffix ".tmp" baseName
        || lib.hasSuffix ".bak" baseName
        || baseName == "tests.nix"
      );

  /* Returns a crate which depends on successful test execution
     of crate given as the second argument.

     testCrateFlags: list of flags to pass to the test exectuable
     testInputs: list of packages that should be available during test execution
  */
  crateWithTest = { crate, testCrate, testCrateFlags, testInputs }:
    assert builtins.typeOf testCrateFlags == "list";
    assert builtins.typeOf testInputs == "list";
    let
      # override the `crate` so that it will build and execute tests instead of
      # building the actual lib and bin targets We just have to pass `--test`
      # to rustc and it will do the right thing.  We execute the tests and copy
      # their log and the test executables to $out for later inspection.
      test =
        let
          drv = testCrate.override
            (
              _: {
                buildTests = true;
              }
            );
        in
        pkgs.runCommand "run-tests-${testCrate.name}"
          {
            inherit testCrateFlags;
            buildInputs = testInputs;
          } ''
          set -ex

          export RUST_BACKTRACE=1

          # recreate a file hierarchy as when running tests with cargo

          # the source for test data
          ${pkgs.xorg.lndir}/bin/lndir ${crate.src}

          # build outputs
          testRoot=target/debug
          mkdir -p $testRoot

          # executables of the crate
          # we copy to prevent std::env::current_exe() to resolve to a store location
          for i in ${crate}/bin/*; do
            cp "$i" "$testRoot"
          done
          chmod +w -R .

          # test harness executables are suffixed with a hash, like cargo does
          # this allows to prevent name collision with the main
          # executables of the crate
          hash=$(basename $out)
          for file in ${drv}/tests/*; do
            f=$testRoot/$(basename $file)-$hash
            cp $file $f
            $f $testCrateFlags 2>&1 | tee -a $out
          done
        '';
    in
    pkgs.runCommand "${crate.name}-linked"
      {
        inherit (crate) outputs crateName;
        passthru = (crate.passthru or { }) // {
          inherit test;
        };
      } ''
      echo tested by ${test}
      ${lib.concatMapStringsSep "\n" (output: "ln -s ${crate.${output}} ${"$"}${output}") crate.outputs}
    '';

  /* A restricted overridable version of builtRustCratesWithFeatures. */
  buildRustCrateWithFeatures =
    { packageId
    , features ? rootFeatures
    , crateOverrides ? defaultCrateOverrides
    , buildRustCrateFunc ? null
    , runTests ? false
    , testCrateFlags ? [ ]
    , testInputs ? [ ]
    }:
    lib.makeOverridable
      (
        { features
        , crateOverrides
        , runTests
        , testCrateFlags
        , testInputs
        }:
        let
          buildRustCrateFuncOverriden =
            if buildRustCrateFunc != null
            then buildRustCrateFunc
            else
              (
                if crateOverrides == pkgs.defaultCrateOverrides
                then buildRustCrate
                else
                  buildRustCrate.override {
                    defaultCrateOverrides = crateOverrides;
                  }
              );
          builtRustCrates = builtRustCratesWithFeatures {
            inherit packageId features;
            buildRustCrateFunc = buildRustCrateFuncOverriden;
            runTests = false;
          };
          builtTestRustCrates = builtRustCratesWithFeatures {
            inherit packageId features;
            buildRustCrateFunc = buildRustCrateFuncOverriden;
            runTests = true;
          };
          drv = builtRustCrates.${packageId};
          testDrv = builtTestRustCrates.${packageId};
          derivation =
            if runTests then
              crateWithTest
                {
                  crate = drv;
                  testCrate = testDrv;
                  inherit testCrateFlags testInputs;
                }
            else drv;
        in
        derivation
      )
      { inherit features crateOverrides runTests testCrateFlags testInputs; };

  /* Returns an attr set with packageId mapped to the result of buildRustCrateFunc
     for the corresponding crate.
  */
  builtRustCratesWithFeatures =
    { packageId
    , features
    , crateConfigs ? crates
    , buildRustCrateFunc
    , runTests
    , target ? defaultTarget
    } @ args:
      assert (builtins.isAttrs crateConfigs);
      assert (builtins.isString packageId);
      assert (builtins.isList features);
      assert (builtins.isAttrs target);
      assert (builtins.isBool runTests);
      let
        rootPackageId = packageId;
        mergedFeatures = mergePackageFeatures
          (
            args // {
              inherit rootPackageId;
              target = target // { test = runTests; };
            }
          );
        buildByPackageId = packageId: buildByPackageIdImpl packageId;

        # Memoize built packages so that reappearing packages are only built once.
        builtByPackageId =
          lib.mapAttrs (packageId: value: buildByPackageId packageId) crateConfigs;
        buildByPackageIdImpl = packageId:
          let
            features = mergedFeatures."${packageId}" or [ ];
            crateConfig' = crateConfigs."${packageId}";
            crateConfig =
              builtins.removeAttrs crateConfig' [ "resolvedDefaultFeatures" "devDependencies" ];
            devDependencies =
              lib.optionals
                (runTests && packageId == rootPackageId)
                (crateConfig'.devDependencies or [ ]);
            dependencies =
              dependencyDerivations {
                inherit builtByPackageId features target;
                dependencies =
                  (crateConfig.dependencies or [ ])
                  ++ devDependencies;
              };
            buildDependencies =
              dependencyDerivations {
                inherit builtByPackageId features target;
                dependencies = crateConfig.buildDependencies or [ ];
              };
            filterEnabledDependenciesForThis = dependencies: filterEnabledDependencies {
              inherit dependencies features target;
            };
            dependenciesWithRenames =
              lib.filter (d: d ? "rename")
                (
                  filterEnabledDependenciesForThis
                    (
                      (crateConfig.buildDependencies or [ ])
                      ++ (crateConfig.dependencies or [ ])
                      ++ devDependencies
                    )
                );
            # Crate renames have the form:
            #
            # {
            #    crate_name = [
            #       { version = "1.2.3"; rename = "crate_name01"; }
            #    ];
            #    # ...
            # }
            crateRenames =
              let
                grouped =
                  lib.groupBy
                    (dependency: dependency.name)
                    dependenciesWithRenames;
                versionAndRename = dep:
                  let
                    package = builtByPackageId."${dep.packageId}";
                  in
                  { inherit (dep) rename; version = package.version; };
              in
              lib.mapAttrs (name: choices: builtins.map versionAndRename choices) grouped;
          in
          buildRustCrateFunc
            (
              crateConfig // {
                src = crateConfig.src or (
                  pkgs.fetchurl rec {
                    name = "${crateConfig.crateName}-${crateConfig.version}.tar.gz";
                    # https://www.pietroalbini.org/blog/downloading-crates-io/
                    # Not rate-limited, CDN URL.
                    url = "https://static.crates.io/crates/${crateConfig.crateName}/${crateConfig.crateName}-${crateConfig.version}.crate";
                    sha256 =
                      assert (lib.assertMsg (crateConfig ? sha256) "Missing sha256 for ${name}");
                      crateConfig.sha256;
                  }
                );
                extraRustcOpts = lib.lists.optional (targetFeatures != [ ]) "-C target-feature=${stdenv.lib.concatMapStringsSep "," (x: "+${x}") targetFeatures}";
                inherit features dependencies buildDependencies crateRenames release;
              }
            );
      in
      builtByPackageId;

  /* Returns the actual derivations for the given dependencies. */
  dependencyDerivations =
    { builtByPackageId
    , features
    , dependencies
    , target
    }:
      assert (builtins.isAttrs builtByPackageId);
      assert (builtins.isList features);
      assert (builtins.isList dependencies);
      assert (builtins.isAttrs target);
      let
        enabledDependencies = filterEnabledDependencies {
          inherit dependencies features target;
        };
        depDerivation = dependency: builtByPackageId.${dependency.packageId};
      in
      map depDerivation enabledDependencies;

  /* Returns a sanitized version of val with all values substituted that cannot
     be serialized as JSON.
  */
  sanitizeForJson = val:
    if builtins.isAttrs val
    then lib.mapAttrs (n: v: sanitizeForJson v) val
    else if builtins.isList val
    then builtins.map sanitizeForJson val
    else if builtins.isFunction val
    then "function"
    else val;

  /* Returns various tools to debug a crate. */
  debugCrate = { packageId, target ? defaultTarget }:
    assert (builtins.isString packageId);
    let
      debug = rec {
        # The built tree as passed to buildRustCrate.
        buildTree = buildRustCrateWithFeatures {
          buildRustCrateFunc = lib.id;
          inherit packageId;
        };
        sanitizedBuildTree = sanitizeForJson buildTree;
        dependencyTree = sanitizeForJson
          (
            buildRustCrateWithFeatures {
              buildRustCrateFunc = crate: {
                "01_crateName" = crate.crateName or false;
                "02_features" = crate.features or [ ];
                "03_dependencies" = crate.dependencies or [ ];
              };
              inherit packageId;
            }
          );
        mergedPackageFeatures = mergePackageFeatures {
          features = rootFeatures;
          inherit packageId target;
        };
        diffedDefaultPackageFeatures = diffDefaultPackageFeatures {
          inherit packageId target;
        };
      };
    in
    { internal = debug; };

  /* Returns differences between cargo default features and crate2nix default
     features.

     This is useful for verifying the feature resolution in crate2nix.
  */
  diffDefaultPackageFeatures =
    { crateConfigs ? crates
    , packageId
    , target
    }:
      assert (builtins.isAttrs crateConfigs);
      let
        prefixValues = prefix: lib.mapAttrs (n: v: { "${prefix}" = v; });
        mergedFeatures =
          prefixValues
            "crate2nix"
            (mergePackageFeatures { inherit crateConfigs packageId target; features = [ "default" ]; });
        configs = prefixValues "cargo" crateConfigs;
        combined = lib.foldAttrs (a: b: a // b) { } [ mergedFeatures configs ];
        onlyInCargo =
          builtins.attrNames
            (lib.filterAttrs (n: v: !(v ? "crate2nix") && (v ? "cargo")) combined);
        onlyInCrate2Nix =
          builtins.attrNames
            (lib.filterAttrs (n: v: (v ? "crate2nix") && !(v ? "cargo")) combined);
        differentFeatures = lib.filterAttrs
          (
            n: v:
              (v ? "crate2nix")
              && (v ? "cargo")
              && (v.crate2nix.features or [ ]) != (v."cargo".resolved_default_features or [ ])
          )
          combined;
      in
      builtins.toJSON {
        inherit onlyInCargo onlyInCrate2Nix differentFeatures;
      };

  /* Returns an attrset mapping packageId to the list of enabled features.

     If multiple paths to a dependency enable different features, the
     corresponding feature sets are merged. Features in rust are additive.
  */
  mergePackageFeatures =
    { crateConfigs ? crates
    , packageId
    , rootPackageId ? packageId
    , features ? rootFeatures
    , dependencyPath ? [ crates.${packageId}.crateName ]
    , featuresByPackageId ? { }
    , target
      # Adds devDependencies to the crate with rootPackageId.
    , runTests ? false
    , ...
    } @ args:
      assert (builtins.isAttrs crateConfigs);
      assert (builtins.isString packageId);
      assert (builtins.isString rootPackageId);
      assert (builtins.isList features);
      assert (builtins.isList dependencyPath);
      assert (builtins.isAttrs featuresByPackageId);
      assert (builtins.isAttrs target);
      assert (builtins.isBool runTests);
      let
        crateConfig = crateConfigs."${packageId}" or (builtins.throw "Package not found: ${packageId}");
        expandedFeatures = expandFeatures (crateConfig.features or { }) features;
        depWithResolvedFeatures = dependency:
          let
            packageId = dependency.packageId;
            features = dependencyFeatures expandedFeatures dependency;
          in
          { inherit packageId features; };
        resolveDependencies = cache: path: dependencies:
          assert (builtins.isAttrs cache);
          assert (builtins.isList dependencies);
          let
            enabledDependencies = filterEnabledDependencies {
              inherit dependencies target;
              features = expandedFeatures;
            };
            directDependencies = map depWithResolvedFeatures enabledDependencies;
            foldOverCache = op: lib.foldl op cache directDependencies;
          in
          foldOverCache
            (
              cache: { packageId, features }:
                let
                  cacheFeatures = cache.${packageId} or [ ];
                  combinedFeatures = sortedUnique (cacheFeatures ++ features);
                in
                if cache ? ${packageId} && cache.${packageId} == combinedFeatures
                then cache
                else
                  mergePackageFeatures {
                    features = combinedFeatures;
                    featuresByPackageId = cache;
                    inherit crateConfigs packageId target runTests rootPackageId;
                  }
            );
        cacheWithSelf =
          let
            cacheFeatures = featuresByPackageId.${packageId} or [ ];
            combinedFeatures = sortedUnique (cacheFeatures ++ expandedFeatures);
          in
          featuresByPackageId // {
            "${packageId}" = combinedFeatures;
          };
        cacheWithDependencies =
          resolveDependencies cacheWithSelf "dep"
            (
              crateConfig.dependencies or [ ]
              ++ lib.optionals
                (runTests && packageId == rootPackageId)
                (crateConfig.devDependencies or [ ])
            );
        cacheWithAll =
          resolveDependencies
            cacheWithDependencies "build"
            (crateConfig.buildDependencies or [ ]);
      in
      cacheWithAll;

  /* Returns the enabled dependencies given the enabled features. */
  filterEnabledDependencies = { dependencies, features, target }:
    assert (builtins.isList dependencies);
    assert (builtins.isList features);
    assert (builtins.isAttrs target);

    lib.filter
      (
        dep:
        let
          targetFunc = dep.target or (features: true);
        in
        targetFunc { inherit features target; }
        && (
          !(dep.optional or false)
          || builtins.any (doesFeatureEnableDependency dep) features
        )
      )
      dependencies;

  /* Returns whether the given feature should enable the given dependency. */
  doesFeatureEnableDependency = { name, rename ? null, ... }: feature:
    let
      prefix = "${name}/";
      len = builtins.stringLength prefix;
      startsWithPrefix = builtins.substring 0 len feature == prefix;
    in
    (rename == null && feature == name)
    || (rename != null && rename == feature)
    || startsWithPrefix;

  /* Returns the expanded features for the given inputFeatures by applying the
     rules in featureMap.

     featureMap is an attribute set which maps feature names to lists of further
     feature names to enable in case this feature is selected.
  */
  expandFeatures = featureMap: inputFeatures:
    assert (builtins.isAttrs featureMap);
    assert (builtins.isList inputFeatures);
    let
      expandFeature = feature:
        assert (builtins.isString feature);
        [ feature ] ++ (expandFeatures featureMap (featureMap."${feature}" or [ ]));
      outFeatures = lib.concatMap expandFeature inputFeatures;
    in
    sortedUnique outFeatures;

  /*
     Returns the actual features for the given dependency.

     features: The features of the crate that refers this dependency.
  */
  dependencyFeatures = features: dependency:
    assert (builtins.isList features);
    assert (builtins.isAttrs dependency);
    let
      defaultOrNil =
        if dependency.usesDefaultFeatures or true
        then [ "default" ]
        else [ ];
      explicitFeatures = dependency.features or [ ];
      additionalDependencyFeatures =
        let
          dependencyPrefix = (dependency.rename or dependency.name) + "/";
          dependencyFeatures =
            builtins.filter (f: lib.hasPrefix dependencyPrefix f) features;
        in
        builtins.map (lib.removePrefix dependencyPrefix) dependencyFeatures;
    in
    defaultOrNil ++ explicitFeatures ++ additionalDependencyFeatures;

  /* Sorts and removes duplicates from a list of strings. */
  sortedUnique = features:
    assert (builtins.isList features);
    assert (builtins.all builtins.isString features);
    let
      outFeaturesSet = lib.foldl (set: feature: set // { "${feature}" = 1; }) { } features;
      outFeaturesUnique = builtins.attrNames outFeaturesSet;
    in
    builtins.sort (a: b: a < b) outFeaturesUnique;

  deprecationWarning = message: value:
    if strictDeprecation
    then builtins.throw "strictDeprecation enabled, aborting: ${message}"
    else builtins.trace message value;

  #
  # crate2nix/default.nix (excerpt end)
  #

  };
}
