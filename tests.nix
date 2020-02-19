{ pkgs ? import ./nix/nixpkgs.nix { config = {}; }
, lib ? pkgs.lib
, stdenv ? pkgs.stdenv
}:

let
  crate2nix = pkgs.callPackage ./default.nix {};
  nixTest = pkgs.callPackage ./nix/nix-test-runner.nix {};
  nodes = {
    dev = { pkgs, ... }: {
      environment.systemPackages = [ crate2nix ];
    };
  };
  tools = pkgs.callPackage ./tools.nix {};
  toolsAllowDeprecated = pkgs.callPackage ./tools.nix { strictDeprecation = false; };
  buildTest =
    { name
    , src
    , cargoToml ? "Cargo.toml"
    , features ? [ "default" ]
    , expectedOutput
    , expectedTestOutputs ? []
    , pregeneratedBuild ? null
    , additionalCargoNixArgs ? []
    , customBuild ? null
    , derivationAttrPath ? [ "rootCrate" ]
    , # Substitute nix-prefetch-url during generation.
      nixPrefetchUrl ? ''
        echo ./tests.nix: NO URL FETCH ALLOWED: "'$*'" >&2
        exit 1
      ''
    , # Substitute nix-prefetch-git during generation.
      nixPrefetchGit ? ''
        echo ./tests.nix: NO GIT FETCH ALLOWED: "'$*'" >&2
        exit 1
      ''
    }:
      let
        generatedCargoNix =
          if builtins.isNull pregeneratedBuild
          then
            let
              autoGeneratedCargoNix = tools.generatedCargoNix {
                name = "buildTest_test_${name}";
                inherit src cargoToml additionalCargoNixArgs;
              };
            in
              autoGeneratedCargoNix.overrideAttrs (
                oldAttrs: {
                  buildInputs = oldAttrs.buildInputs ++ [
                    (pkgs.writeShellScriptBin "nix-prefetch-url" nixPrefetchUrl)
                    (pkgs.writeShellScriptBin "nix-prefetch-git" nixPrefetchGit)
                  ];
                }
              )
          else
            ./. + "/${pregeneratedBuild}";
        derivation =
          if builtins.isNull customBuild
          then
            (lib.attrByPath derivationAttrPath null (pkgs.callPackage generatedCargoNix {})).build.override {
              inherit features;
            }
          else
            pkgs.callPackage (./. + "/${customBuild}") {
              inherit generatedCargoNix;
            };
      in
        assert lib.length expectedTestOutputs > 0 -> derivation ? test;
        pkgs.stdenv.mkDerivation {
          name = "buildTest_${name}";
          phases = [ "buildPhase" ];
          buildInputs = [ derivation ];
          buildPhase = ''
            mkdir -p $out
            ${derivation.crateName} >$out/run.log
            echo grepping
            grep '${expectedOutput}' $out/run.log || {
              echo '${expectedOutput}' not found in:
              cat $out/run.log
              exit 23
            }

            ${lib.optionalString (lib.length expectedTestOutputs > 0) ''
            cp ${derivation.test} $out/tests.log
          ''}
            ${lib.concatMapStringsSep "\n" (
            output: ''
              grep '${output}' $out/tests.log || {
                echo '${output}' not found in:
                cat $out/tests.log
                exit 23
              }
            ''
          ) expectedTestOutputs}
          '';
        };

  buildTestConfigs = [

    #
    # BASIC
    #
    # Artificial tests that tend to test only a few features.
    #

    {
      name = "bin";
      src = ./sample_projects/bin;
      expectedOutput = "Hello, world!";
    }

    {
      name = "lib_and_bin";
      src = ./sample_projects/lib_and_bin;
      expectedOutput = "Hello, lib_and_bin!";
    }

    {
      name = "bin_with_lib_dep";
      src = ./sample_projects;
      cargoToml = "bin_with_lib_dep/Cargo.toml";
      expectedOutput = "Hello, bin_with_lib_dep!";
    }

    {
      name = "bin_with_default_features";
      src = ./sample_projects;
      cargoToml = "bin_with_default_features/Cargo.toml";
      expectedOutput = "Hello, bin_with_default_features!";
    }

    {
      name = "bin_with_NON_default_features";
      src = ./sample_projects;
      cargoToml = "bin_with_default_features/Cargo.toml";
      features = [ "default" "do_not_activate" ];
      expectedOutput = "Hello, bin_with_default_features, do_not_activate!";
    }

    {
      name = "bin_with_NON_default_ROOT_features";
      src = ./sample_projects;
      cargoToml = "bin_with_default_features/Cargo.toml";
      expectedOutput = "Hello, bin_with_default_features, do_not_activate!";
      customBuild = "sample_projects/bin_with_default_features/override-root-features.nix";
    }

    {
      name = "bin_with_lib_git_dep";
      src = ./sample_projects/bin_with_lib_git_dep;
      expectedOutput = "Hello world from bin_with_lib_git_dep!";
    }

    {
      name = "bin_with_git_branch_dep";
      src = ./sample_projects/bin_with_git_branch_dep;
      expectedOutput = "Hello world from bin_with_git_branch_dep!";
      pregeneratedBuild = "sample_projects/bin_with_git_branch_dep/Cargo.nix";
    }

    {
      name = "bin_with_rerenamed_lib_dep";
      src = ./sample_projects;
      cargoToml = "bin_with_rerenamed_lib_dep/Cargo.toml";
      expectedOutput = "Hello, bin_with_rerenamed_lib_dep!";
    }

    {
      name = "cfg_test";
      src = ./sample_projects/cfg-test;
      cargoToml = "Cargo.toml";
      expectedOutput = "Hello, cfg-test!";
    }

    {
      name = "cfg_test-with-tests";
      src = ./sample_projects/cfg-test;
      cargoToml = "Cargo.toml";
      expectedOutput = "Hello, cfg-test!";
      expectedTestOutputs = [
        "test echo_foo_test ... ok"
        "test lib_test ... ok"
        "test in_source_dir ... ok"
        "test exec_cowsay ... ok"
      ];
      customBuild = "sample_projects/cfg-test/test.nix";
    }

    {
      name = "test_flag_passing";
      src = ./sample_projects/test_flag_passing;
      cargoToml = "Cargo.toml";
      expectedTestOutputs = [
        "test this_must_run ... ok"
        "1 filtered out"
      ];
      expectedOutput = "Banana is a veggie and tomato is a fruit";
      customBuild = "sample_projects/test_flag_passing/test.nix";
    }

    {
      name = "renamed_build_deps";
      src = ./sample_projects/renamed_build_deps;
      expectedOutput = "Hello, renamed_build_deps!";
    }

    {
      name = "sample_workspace";
      src = ./sample_workspace;
      expectedOutput = "Hello, with_tera!";
      derivationAttrPath = [ "workspaceMembers" "with_tera" ];
    }

    {
      name = "bin_with_git_submodule_dep";
      src = ./sample_projects/bin_with_git_submodule_dep;
      pregeneratedBuild = "sample_projects/bin_with_git_submodule_dep/Cargo.nix";
      customBuild = "sample_projects/bin_with_git_submodule_dep/default.nix";
      expectedOutput = "Hello world from with_git_submodule_dep!";
    }

    {
      name = "bin_with_git_submodule_dep_customBuildRustCrate";
      src = ./sample_projects/bin_with_git_submodule_dep;
      pregeneratedBuild = "sample_projects/bin_with_git_submodule_dep/Cargo.nix";
      customBuild = "sample_projects/bin_with_git_submodule_dep/default-with-customBuildRustCrate.nix";
      expectedOutput = "Hello world from with_git_submodule_dep!";
    }

    {
      name = "cdylib";
      src = ./sample_projects/cdylib;
      customBuild = "sample_projects/cdylib/test.nix";
      expectedOutput = "cdylib test";
    }

    {
      name = "numtest_new_cargo_lock";
      src = ./sample_projects/numtest_new_cargo_lock;
      expectedOutput = "Hello from numtest, world!";
    }

    #
    # Prefetch tests
    #

    {
      name = "simple_dep_prefetch_test";
      src = ./sample_projects/simple_dep;
      additionalCargoNixArgs = [ "--no-cargo-lock-checksums" ];
      expectedOutput = "Hello, simple_dep!";
      nixPrefetchUrl = ''
        case "$@" in
          "https://crates.io/api/v1/crates/nix-base32/0.1.1/download --name nix-base32-0.1.1")
            echo "04jnq6arig0amz0scadavbzn9bg9k4zphmrm1562n6ygfj1dnj45"
            ;;
          *)
            echo -e "\e[31mUnrecognized fetch:\e[0m $(basename $0) $@" >&2
            exit 1
            ;;
        esac
      '';
    }

    {
      name = "git_prefetch_test";
      src = ./sample_projects/bin_with_lib_git_dep;
      expectedOutput = "Hello world from bin_with_lib_git_dep!";
      additionalCargoNixArgs = [
        "--dont-read-crate-hashes"
      ];
      nixPrefetchGit = ''
        case "$@" in
          "--url https://github.com/kolloch/nix-base32 --fetch-submodules --rev 42f5544e51187f0c7535d453fcffb4b524c99eb2")
            echo '
            {
              "url": "https://github.com/kolloch/nix-base32",
              "rev": "42f5544e51187f0c7535d453fcffb4b524c99eb2",
              "date": "2019-11-29T22:22:24+01:00",
              "sha256": "011f945b48xkilkqbvbsxazspz5z23ka0s90ms4jiqjbhiwll1nw",
              "fetchSubmodules": true
            }            
            '
            ;;
          *)
            echo -e "\e[31mUnrecognized fetch:\e[0m $(basename $0) $@" >&2
            exit 1
            ;;
        esac
      '';
    }

    #
    # Compatibility tests with "real" crates
    #

    {
      name = "futures_compat_test";
      src = ./sample_projects/futures_compat;
      cargoToml = "Cargo.toml";
      expectedOutput = "Hello, futures_compat!";
    }

    {
      name = "numtest";
      src = ./sample_projects/numtest;
      expectedOutput = "Hello from numtest, world!";
    }

    {
      name = "dependency_issue_65_all_features";
      src = ./sample_projects/dependency_issue_65;
      # This will not work with only default features.
      # Therefore, it tests that the default is really --all-features.
      customBuild = "sample_projects/dependency_issue_65/default.nix";
      expectedOutput = "Hello, dependency_issue_65!";
    }

    {
      name = "dependency_issue_65_sqlite_feature";
      additionalCargoNixArgs = [ "--features" "sqlite" ];
      src = ./sample_projects/dependency_issue_65;
      customBuild = "sample_projects/dependency_issue_65/default.nix";
      expectedOutput = "Hello, dependency_issue_65";
    }

    {
      name = "with_problematic_crates";
      src = ./sample_projects/with_problematic_crates;
      expectedOutput = "Hello, with_problematic_crates!";
    }

  ];

  buildTestDerivationAttrSet =
    let
      buildTestDerivations =
        builtins.map
          (c: { name = c.name; value = buildTest c; })
          buildTestConfigs;
    in
      builtins.listToAttrs buildTestDerivations;

in
{
  help = pkgs.stdenv.mkDerivation {
    name = "help";
    phases = [ "buildPhase" ];
    buildPhase = ''
      mkdir -p $out
      ${crate2nix}/bin/crate2nix help >$out/crate2nix.log
      echo grepping
      grep USAGE $out/crate2nix.log
    '';
  };

  fail = pkgs.stdenv.mkDerivation {
    name = "fail";
    phases = [ "buildPhase" ];
    buildPhase = ''
      mkdir -p $out
      ${crate2nix}/bin/crate2nix 2>$out/crate2nix.log \
          && exit 23 || echo expect error
      echo grepping
      grep USAGE $out/crate2nix.log
    '';
  };

  bin_with_deprecated_alias =
    let
      bin_build = (
        toolsAllowDeprecated.generated {
          name = "bin_with_deprecated_alias";
          src = ./sample_projects/bin;
        }
      ).root_crate;
    in
      pkgs.stdenv.mkDerivation {
        name = "test_bin";
        phases = [ "buildPhase" ];
        buildInputs = [ bin_build ];
        buildPhase = ''
          mkdir -p $out
          hello_world_bin >$out/test.log
          echo grepping
          grep 'Hello, world!' $out/test.log
        '';
      };

  buildNixTestWithLatestCrate2nix = pkgs.callPackage ./nix/nix-test-runner.nix {
    inherit tools;
  };

  inherit buildTestConfigs;
} // buildTestDerivationAttrSet
