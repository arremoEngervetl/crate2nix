
# Generated by crate2nix 0.7.0-beta.1 with the command:
#   "generate" "-f" "sample_projects/bin_with_git_branch_dep/Cargo.toml" "-o" "sample_projects/bin_with_git_branch_dep/Cargo.nix"
# See https://github.com/kolloch/crate2nix for more info.

{ pkgs? import <nixpkgs> { config = {}; },
  lib? pkgs.lib,
  callPackage? pkgs.callPackage,
  stdenv? pkgs.stdenv,
  buildRustCrate? pkgs.buildRustCrate,
  fetchurl? pkgs.fetchurl,
  fetchCrate? pkgs.fetchCrate,
  defaultCrateOverrides? pkgs.defaultCrateOverrides,
  # The features to enable for the root_crate or the workspace_members.
  rootFeatures? ["default"]}:

rec {
  #
  # "public" attributes that we attempt to keep stable with new versions of crate2nix.
  #

  rootCrate = rec {
    packageId = "bin_with_lib_git_dep 0.1.0 (path+file:///home/peter/projects/crate2nix/sample_projects/bin_with_git_branch_dep)";

    # Use this attribute to refer to the derivation building your root crate package.
    # You can override the features with rootCrate.build.override { features = [ "default" "feature1" ... ]; }.
    build = buildRustCrateWithFeatures {
      features = rootFeatures;
      inherit packageId;
    };

    # Debug support which might change between releases.
    # File a bug if you depend on any for non-debug work!
    debug = debugCrate { inherit packageId; };
  };
  root_crate =
    builtins.trace "root_crate is deprecated since crate2nix 0.4. Please use rootCrate instead." rootCrate.build;
  # Refer your crate build derivation by name here.
  # You can override the features with
  # workspaceMembers."${crateName}".build.override { features = [ "default" "feature1" ... ]; }.
  workspaceMembers = {
    "bin_with_lib_git_dep" = rec {
      packageId = "bin_with_lib_git_dep 0.1.0 (path+file:///home/peter/projects/crate2nix/sample_projects/bin_with_git_branch_dep)";
      build = buildRustCrateWithFeatures {
        packageId = "bin_with_lib_git_dep 0.1.0 (path+file:///home/peter/projects/crate2nix/sample_projects/bin_with_git_branch_dep)";
        features = rootFeatures;
      };

      # Debug support which might change between releases.
      # File a bug if you depend on any for non-debug work!
      debug = debugCrate { inherit packageId; };
    };
  };
  workspace_members =
    builtins.trace
      "workspace_members is deprecated in crate2nix 0.4. Please use workspaceMembers instead."
      lib.mapAttrs (n: v: v.build) workspaceMembers;

  #
  # "private" attributes that may change in every new version of crate2nix.
  #

  # Build and dependency information for crates.
  # Many of the fields are passed one-to-one to buildRustCrate.
  #
  # Noteworthy:
  # * `crateBin = [{name = ","; path = ",";}];`: a hack to disable building the binary.
  # * `dependencies`/`buildDependencies`: similar to the corresponding fields for buildRustCrate.
  #   but with additional information which is used during dependency/feature resolution.
  # * `resolvedDependencies`: the selected default features reported by cargo - only included for debugging.
  # * `devDependencies` as of now not used by `buildRustCrate` but used to
  #   inject test dependencies into the build

  crates = {
    "bin_with_lib_git_dep 0.1.0 (path+file:///home/peter/projects/crate2nix/sample_projects/bin_with_git_branch_dep)"
      = rec {
        crateName = "bin_with_lib_git_dep";
        version = "0.1.0";
        edition = "2018";
        crateBin = [
          { name = "bin_with_lib_git_dep"; path = "src/main.rs"; }
        ];
        src = (builtins.filterSource sourceFilter ./.);
        authors = [
          "Peter Kolloch <info@eigenvalue.net>"
        ];
        dependencies = [
          {
            name = "nix-base32";
            packageId = "nix-base32 0.1.2-alpha.0 (git+https://github.com/kolloch/nix-base32?branch=branch-for-test#42f5544e51187f0c7535d453fcffb4b524c99eb2)";
          }
        ];
        features = {
        };
      };
    "nix-base32 0.1.2-alpha.0 (git+https://github.com/kolloch/nix-base32?branch=branch-for-test#42f5544e51187f0c7535d453fcffb4b524c99eb2)"
      = rec {
        crateName = "nix-base32";
        version = "0.1.2-alpha.0";
        edition = "2018";
        src = pkgs.fetchgit {
          url = "https://github.com/kolloch/nix-base32";
          rev = "42f5544e51187f0c7535d453fcffb4b524c99eb2";
          sha256 = "011f945b48xkilkqbvbsxazspz5z23ka0s90ms4jiqjbhiwll1nw";
        };
        authors = [
          "Peter Kolloch <info@eigenvalue.net>"
        ];
        features = {
        };
      };
  };

  #
  # crate2nix/default.nix (excerpt start)
  # 

  # Target (platform) data for conditional dependencies.
  # This corresponds roughly to what buildRustCrate is setting.
  defaultTarget = {
      unix = true;
      windows = false;
      fuchsia = true;
      test = false;

      # This doesn't appear to be officially documented anywhere yet.
      # See https://github.com/rust-lang-nursery/rust-forge/issues/101.
      os = if stdenv.hostPlatform.isDarwin
        then "macos"
        else stdenv.hostPlatform.parsed.kernel.name;
      arch = stdenv.hostPlatform.parsed.cpu.name;
      family = "unix";
      env = "gnu";
      endian = if stdenv.hostPlatform.parsed.cpu.significantByte.name == "littleEndian" then "little" else "big";
      pointer_width = toString stdenv.hostPlatform.parsed.cpu.bits;
      vendor = stdenv.hostPlatform.parsed.vendor.name;
      debug_assertions = false;
  };

  /* Filters common temp files and build files */
  # TODO(pkolloch): Substitute with gitignore filter
  sourceFilter = name: type:
    let baseName = builtins.baseNameOf (builtins.toString name);
    in ! (
      # Filter out git
      baseName == ".gitignore" ||
      (type == "directory" && baseName == ".git" ) ||

      # Filter out build results
      (type == "directory" && (
        baseName == "target" ||
        baseName == "_site" ||
        baseName == ".sass-cache" ||
        baseName == ".jekyll-metadata" ||
        baseName == "build-artifacts"
        )) ||

      # Filter out nix-build result symlinks
      (type == "symlink" && lib.hasPrefix "result" baseName) ||

      # Filter out IDE config
      (type == "directory" && (
        baseName == ".idea" ||
        baseName == ".vscode"
        )) ||
      lib.hasSuffix ".iml" baseName ||

      # Filter out nix build files
      # lib.hasSuffix ".nix" baseName ||
      baseName == "Cargo.nix" ||

      # Filter out editor backup / swap files.
      lib.hasSuffix "~" baseName ||
      builtins.match "^\\.sw[a-z]$$" baseName != null ||
      builtins.match "^\\..*\\.sw[a-z]$$" baseName != null ||
      lib.hasSuffix ".tmp" baseName ||
      lib.hasSuffix ".bak" baseName ||
      baseName == "tests.nix"
    );

  /* Returns a crate which depends on successful test execution of crate given as the second argument */
  crateWithTest = crate: testCrate: testCrateFlags:
    let
      # override the `crate` so that it will build and execute tests instead of
      # building the actual lib and bin targets We just have to pass `--test`
      # to rustc and it will do the right thing.  We execute the tests and copy
      # their log and the test executables to $out for later inspection.
      test = let
        drv = testCrate.override (_: {
          buildTests = true;
        });
      in pkgs.runCommand "run-tests-${testCrate.name}" {
        inherit testCrateFlags;
      } ''
        set -e
        for file in ${drv}/tests/*; do
          echo "Executing test $file" | tee -a $out
          $file -- "$testCrateFlags" 2>&1 | tee -a $out
        done
      '';
    in crate.overrideAttrs (old: {
      checkPhase = ''
        test -e ${test}
      '';
      passthru = (old.passthru or {}) // {
        inherit test;
      };
    });

  /* A restricted overridable version of  buildRustCrateWithFeaturesImpl. */
  buildRustCrateWithFeatures =
    { packageId
    , features ? rootFeatures
    , crateOverrides ? defaultCrateOverrides
    , buildRustCrateFunc ? buildRustCrate
    , runTests ? false
    , testCrateFlags ? []
    }:
    lib.makeOverridable
      ({features, crateOverrides, runTests, testCrateFlags}:
        let
          builtRustCrates = builtRustCratesWithFeatures {
            inherit packageId features crateOverrides buildRustCrateFunc;
            runTests = false;
          };
          builtTestRustCrates = builtRustCratesWithFeatures {
            inherit packageId features crateOverrides buildRustCrateFunc;
            runTests = true;
          };
          drv = builtRustCrates.${packageId};
          testDrv = builtTestRustCrates.${packageId};
        in if runTests then crateWithTest drv testDrv testCrateFlags else drv)
      { inherit features crateOverrides runTests testCrateFlags; };

  /* Returns a buildRustCrate derivation for the given packageId and features. */
  builtRustCratesWithFeatures =
    { packageId
    , features
    , crateConfigs ? crates
    , crateOverrides
    , buildRustCrateFunc
    , runTests
    , target ? defaultTarget
    } @ args:
    assert (builtins.isAttrs crateConfigs);
    assert (builtins.isString packageId);
    assert (builtins.isList features);
    assert (builtins.isAttrs target);
    assert (builtins.isBool runTests);

    let rootPackageId = packageId;
        mergedFeatures = mergePackageFeatures (args // {
          inherit rootPackageId;
          target = target // { test = runTests; };
        });

        buildByPackageId = packageId: buildByPackageIdImpl packageId;

        # Memoize built packages so that reappearing packages are only built once.
        builtByPackageId =
          lib.mapAttrs (packageId: value: buildByPackageId packageId) crateConfigs;

        buildByPackageIdImpl = packageId:
          let
              features = mergedFeatures."${packageId}" or [];
              crateConfig' = crateConfigs."${packageId}";
              crateConfig = builtins.removeAttrs crateConfig' ["resolvedDefaultFeatures" "devDependencies"];
              devDependencies = lib.optionals (runTests && packageId == rootPackageId) (crateConfig'.devDependencies or []);
              dependencies =
                dependencyDerivations {
                  inherit builtByPackageId features target;
                  dependencies =
                   (crateConfig.dependencies or [])
                    ++ devDependencies;
                };
              buildDependencies =
                dependencyDerivations {
                  inherit builtByPackageId features target;
                  dependencies = crateConfig.buildDependencies or [];
                };

              dependenciesWithRenames =
                lib.filter (d: d ? "rename") (
                  (crateConfig.buildDependencies or [])
                  ++ (crateConfig.dependencies or [])
                  ++ devDependencies);

              crateRenames =
                builtins.listToAttrs (map (d: { name = d.name; value = d.rename; }) dependenciesWithRenames);
          in buildRustCrateFunc (crateConfig // {
            src = crateConfig.src or (pkgs.fetchurl {
              name = "${crateConfig.crateName}-${crateConfig.version}.tar.gz";
              url = "https://crates.io/api/v1/crates/${crateConfig.crateName}/${crateConfig.version}/download";
              sha256 = crateConfig.sha256;
            });
            inherit features dependencies buildDependencies crateRenames;
          });
    in builtByPackageId;

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

    let enabledDependencies = filterEnabledDependencies { inherit dependencies features target; };
        depDerivation = dependency: builtByPackageId.${dependency.packageId};
    in map depDerivation enabledDependencies;

  sanitizeForJson = val:
          if builtins.isAttrs val
          then lib.mapAttrs (n: v: sanitizeForJson v) val
          else if builtins.isList val
          then builtins.map sanitizeForJson val
          else if builtins.isFunction val
          then "function"
          else val;

  debugCrate = {packageId, target}:
    assert (builtins.isString packageId);

    rec {
        # The built tree as passed to buildRustCrate.
        buildTree = buildRustCrateWithFeatures {
            buildRustCrateFunc = lib.id;
            inherit packageId;
        };
        sanitizedBuildTree = sanitizeForJson buildTree;
        dependencyTree = sanitizeForJson (buildRustCrateWithFeatures {
            buildRustCrateFunc = crate: {
                "01_crateName" = crate.crateName or false;
                "02_features" = crate.features or [];
                "03_dependencies" = crate.dependencies or [];
            };
            inherit packageId;
        });
        mergedPackageFeatures = mergePackageFeatures { inherit packageId target; features = rootFeatures; };
        diffedDefaultPackageFeatures = diffDefaultPackageFeatures { inherit packageId;  features = rootFeatures; };
    };

  /* Returns differences between cargo default features and crate2nix default features.
   *
   * This is useful for verifying the feature resolution in crate2nix.
   */
  diffDefaultPackageFeatures =
    { crateConfigs ? crates
    , packageId
    , target
    }:
    assert (builtins.isAttrs crateConfigs);

    let prefixValues = prefix: lib.mapAttrs (n: v: { "${prefix}" = v; });
        mergedFeatures =
          prefixValues
            "crate2nix"
            (mergePackageFeatures {inherit crateConfigs packageId target; features = ["default"]; });
        configs = prefixValues "cargo" crateConfigs;
        combined = lib.foldAttrs (a: b: a // b) {} [ mergedFeatures configs ];
        onlyInCargo = builtins.attrNames (lib.filterAttrs (n: v: !(v ? "crate2nix" ) && (v ? "cargo")) combined);
        onlyInCrate2Nix = builtins.attrNames (lib.filterAttrs (n: v: (v ? "crate2nix" ) && !(v ? "cargo")) combined);
        differentFeatures = lib.filterAttrs
          (n: v:
          (v ? "crate2nix" )
          && (v ? "cargo")
          && (v.crate2nix.features or []) != (v."cargo".resolved_default_features or []))
          combined;
    in builtins.toJSON { inherit onlyInCargo onlyInCrate2Nix differentFeatures; };

  /* Returns the feature configuration by package id for the given input crate.

     Returns a { packageId, features } attribute set for every package needed for building the
     package for the given packageId with the given features.

     Returns multiple, potentially conflicting attribute sets for dependencies that are reachable
     by multiple paths in the dependency tree.
  */

  mergePackageFeatures = {
    crateConfigs ? crates,
    packageId,
    rootPackageId,
    features ? rootFeatures,
    dependencyPath? [crates.${packageId}.crateName],
    featuresByPackageId? {},
    target,
    runTests,
    ...} @ args:
    assert (builtins.isAttrs crateConfigs);
    assert (builtins.isString packageId);
    assert (builtins.isList features);
    assert (builtins.isAttrs featuresByPackageId);

    let
        crateConfig = crateConfigs."${packageId}" or (builtins.throw "Package not found: ${packageId}");
        expandedFeatures = expandFeatures (crateConfig.features or {}) features;

        depWithResolvedFeatures = dependency:
          let packageId = dependency.packageId;
              features = dependencyFeatures expandedFeatures dependency;
          in { inherit packageId features; };

        resolveDependencies = cache: path: dependencies:
          assert (builtins.isAttrs cache);
          assert (builtins.isList dependencies);

          let enabledDependencies = filterEnabledDependencies {
                inherit dependencies target;
                features = expandedFeatures;
              };
              directDependencies = map depWithResolvedFeatures enabledDependencies;
              foldOverCache = op: lib.foldl op cache directDependencies;
          in foldOverCache
            (cache: {packageId, features}:
             let cacheFeatures = cache.${packageId} or [];
                 combinedFeatures = sortedUnique (cacheFeatures ++ features);
             in
             if cache ? ${packageId} && cache.${packageId} == combinedFeatures
             then cache
             else mergePackageFeatures {
                  # This is purely for debugging.
                  dependencyPath = dependencyPath ++ [path crateConfigs.${packageId}.crateName];
                  features = combinedFeatures;
                  featuresByPackageId = cache;
                  inherit crateConfigs packageId target runTests rootPackageId;
                 });

        cacheWithSelf =
            let cacheFeatures = featuresByPackageId.${packageId} or [];
                combinedFeatures = sortedUnique (cacheFeatures ++ expandedFeatures);
            in featuresByPackageId // {
                ${packageId} = combinedFeatures;
            };

        cacheWithDependencies =
            resolveDependencies cacheWithSelf "dep" (
              crateConfig.dependencies or []
              ++ lib.optionals (runTests && packageId == rootPackageId) (crateConfig.devDependencies or [])
        );
        cacheWithAll =
            resolveDependencies cacheWithDependencies "build" (crateConfig.buildDependencies or []);

    in cacheWithAll;

  /* Returns the enabled dependencies given the enabled features. */
  filterEnabledDependencies = {dependencies, features, target}:
    assert (builtins.isList dependencies);
    assert (builtins.isList features);
    assert (builtins.isAttrs target);

    lib.filter
      (dep:
        let targetFunc = dep.target or (features: true);
        in targetFunc { inherit features target; }
           && (!(dep.optional or false) || builtins.any (doesFeatureEnableDependency dep) features))
      dependencies;

  /* Returns whether the given feature should enable the given dependency. */
  doesFeatureEnableDependency = { name, rename ? null, ...}: feature:
    let prefix = "${name}/";
        len = builtins.stringLength prefix;
        startsWithPrefix = builtins.substring 0 len feature == prefix;
    in feature == name || (rename != null && rename == feature) || startsWithPrefix;

  /* Returns the expanded features for the given inputFeatures by applying the rules in featureMap.

     featureMap is an attribute set which maps feature names to lists of further feature names to enable in case this
     feature is selected.
  */
  expandFeatures = featureMap: inputFeatures:
    assert (builtins.isAttrs featureMap);
    assert (builtins.isList inputFeatures);

    let expandFeature = feature:
          assert (builtins.isString feature);
          [feature] ++ (expandFeatures featureMap (featureMap."${feature}" or []));
        outFeatures = builtins.concatMap expandFeature inputFeatures;
    in sortedUnique outFeatures;

  /*
   * Returns the actual dependencies for the given dependency.
   *
   * features: The features of the crate that refers this dependency.
   */
  dependencyFeatures = features: dependency:
    assert (builtins.isList features);
    assert (builtins.isAttrs dependency);

    let defaultOrNil = if dependency.usesDefaultFeatures or true
                       then ["default"]
                       else [];
        explicitFeatures = dependency.features or [];
        additionalDependencyFeatures =
          let dependencyPrefix = dependency.name+"/";
              dependencyFeatures =
                builtins.filter (f: lib.hasPrefix dependencyPrefix f) features;
          in builtins.map (lib.removePrefix dependencyPrefix) dependencyFeatures;
    in
      defaultOrNil ++ explicitFeatures ++ additionalDependencyFeatures;

  /* Sorts and removes duplicates from a list of strings. */
  sortedUnique = features:
    assert (builtins.isList features);
    assert (builtins.all builtins.isString features);

    let outFeaturesSet = lib.foldl (set: feature: set // {"${feature}" = 1;} ) {} features;
        outFeaturesUnique = builtins.attrNames outFeaturesSet;
    in builtins.sort (a: b: a < b) outFeaturesUnique;

  #
  # crate2nix/default.nix (excerpt end)
  # 

}
