#
# crate2nix/default.nix (excerpt start)
#{#
{ pkgs
, lib
, stdenv
, buildRustCrate
, buildRustCrateForPkgs ? if buildRustCrate != null
  then lib.warn "`buildRustCrate` is deprecated, use `buildRustCrateForPkgs` instead" (_: buildRustCrate)
  else pkgs: pkgs.buildRustCrate
, defaultCrateOverrides
, strictDeprecation ? true
, crates ? { }
, rootFeatures ? [ ]
, targetFeatures ? [ ]
, release ? true
}:
rec {
  # #}

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
    , buildRustCrateForPkgsFunc ? null
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
          buildRustCrateForPkgsFuncOverriden =
            if buildRustCrateForPkgsFunc != null
            then buildRustCrateForPkgsFunc
            else
              (
                if crateOverrides == pkgs.defaultCrateOverrides
                then buildRustCrateForPkgs
                else
                  pkgs: (buildRustCrateForPkgs pkgs).override {
                    defaultCrateOverrides = crateOverrides;
                  }
              );
          builtRustCrates = builtRustCratesWithFeatures {
            inherit packageId features;
            buildRustCrateForPkgsFunc = buildRustCrateForPkgsFuncOverriden;
            runTests = false;
          };
          builtTestRustCrates = builtRustCratesWithFeatures {
            inherit packageId features;
            buildRustCrateForPkgsFunc = buildRustCrateForPkgsFuncOverriden;
            runTests = true;
          };
          drv = builtRustCrates.crates.${packageId};
          testDrv = builtTestRustCrates.crates.${packageId};
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

  /* Returns an attr set with packageId mapped to the result of buildRustCrateForPkgsFunc
     for the corresponding crate.
  */
  builtRustCratesWithFeatures =
    { packageId
    , features
    , crateConfigs ? crates
    , buildRustCrateForPkgsFunc
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
        # Memoize built packages so that reappearing packages are only built once.
        builtByPackageIdByPkgs = mkBuiltByPackageIdByPkgs pkgs;
        mkBuiltByPackageIdByPkgs = pkgs:
          let
            self = {
              crates = lib.mapAttrs (packageId: value: buildByPackageIdForPkgsImpl self pkgs packageId) crateConfigs;
              build = mkBuiltByPackageIdByPkgs pkgs.buildPackages;
            };
          in
          self;
        buildByPackageIdForPkgsImpl = self: pkgs: packageId:
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
                inherit features target;
                buildByPackageId = depPackageId:
                  # proc_macro crates must be compiled for the build architecture
                  if crateConfigs.${depPackageId}.procMacro or false
                  then self.build.crates.${depPackageId}
                  else self.crates.${depPackageId};
                dependencies =
                  (crateConfig.dependencies or [ ])
                  ++ devDependencies;
              };
            buildDependencies =
              dependencyDerivations {
                inherit features target;
                buildByPackageId = depPackageId:
                  self.build.crates.${depPackageId};
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
                    package = crateConfigs."${dep.packageId}";
                  in
                  { inherit (dep) rename; version = package.version; };
              in
              lib.mapAttrs (name: choices: builtins.map versionAndRename choices) grouped;
          in
          buildRustCrateForPkgsFunc pkgs
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
                extraRustcOpts = lib.lists.optional (targetFeatures != [ ]) "-C target-feature=${lib.concatMapStringsSep "," (x: "+${x}") targetFeatures}";
                inherit features dependencies buildDependencies crateRenames release;
              }
            );
      in
      builtByPackageIdByPkgs;

  /* Returns the actual derivations for the given dependencies. */
  dependencyDerivations =
    { buildByPackageId
    , features
    , dependencies
    , target
    }:
      assert (builtins.isList features);
      assert (builtins.isList dependencies);
      assert (builtins.isAttrs target);
      let
        enabledDependencies = filterEnabledDependencies {
          inherit dependencies features target;
        };
        depDerivation = dependency: buildByPackageId dependency.packageId;
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
          buildRustCrateForPkgsFunc = _: lib.id;
          inherit packageId;
        };
        sanitizedBuildTree = sanitizeForJson buildTree;
        dependencyTree = sanitizeForJson
          (
            buildRustCrateWithFeatures {
              buildRustCrateForPkgsFunc = _: crate: {
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
        enabledFeatures = enableFeatures (crateConfig.dependencies or [ ]) expandedFeatures;
        depWithResolvedFeatures = dependency:
          let
            packageId = dependency.packageId;
            features = dependencyFeatures enabledFeatures dependency;
          in
          { inherit packageId features; };
        resolveDependencies = cache: path: dependencies:
          assert (builtins.isAttrs cache);
          assert (builtins.isList dependencies);
          let
            enabledDependencies = filterEnabledDependencies {
              inherit dependencies target;
              features = enabledFeatures;
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
            combinedFeatures = sortedUnique (cacheFeatures ++ enabledFeatures);
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

  /* This function adds optional dependencies as features if they are enabled
     indirectly by dependency features. This function mimics Cargo's behavior
     described in a note at:
     https://doc.rust-lang.org/nightly/cargo/reference/features.html#dependency-features
  */
  enableFeatures = dependencies: features:
    assert (builtins.isList features);
    assert (builtins.isList dependencies);
    let
      additionalFeatures = lib.concatMap
        (
          dependency:
            assert (builtins.isAttrs dependency);
            let
              enabled = builtins.any (doesFeatureEnableDependency dependency) features;
            in
            if (dependency.optional or false) && enabled then [ dependency.name ] else [ ]
        )
        dependencies;
    in
    sortedUnique (features ++ additionalFeatures);

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
  #{#
}
# -#}
