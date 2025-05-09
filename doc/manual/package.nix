{ json-schema-for-humans
, cargo
, fetchpatch2
, jq
, lib
, mdbook
, mdbook-mermaid
, nixdoc
, nixops4
, nixops4-resource-runner
, manual-deployment-option-docs-md
, stdenv
}:
let
  inherit (lib) fileset;
in
stdenv.mkDerivation (finalAttrs: {
  name = "nixops-manual";

  src = fileset.toSource {
    fileset = fileset.unions [
      ../../nix/lib/lib.nix
      ../../rust/nixops4-resource/examples
      ../../rust/nixops4-resource/resource-schema-v0.json
      (fileset.fileFilter ({ name, ... }: name == "Cargo.toml") ../../rust)
      ./book.toml
      ./cargo-deps.sh
      ./custom.css
      ./json-schema-for-humans-config.yaml
      ./make
      ./Makefile
      ./mermaid-init.js
      ./mermaid.min.js
      ./src
      ./theme
    ];
    root = ../..;
  };
  sourceRoot = "source/doc/manual";
  strictDeps = true;
  nativeBuildInputs = finalAttrs.passthru.externalBuildTools ++ [
    # cargo for the `cargo-deps.sh` script. Not listed in externalBuildTools because the shell already has it
    cargo
    nixops4
    nixops4-resource-runner
  ];
  preConfigure = ''
    patchShebangs --build ./cargo-deps.sh
  '';
  installPhase = ''
    runHook preInstall
    docDir="$out/share/doc/nixops4/manual"
    mkdir -p "$docDir"
    mv book/ "$docDir/html"
    runHook postInstall
  '';
  allowedReferences = [ ];
  env = {
    NIXOPS_DEPLOYMENT_OPTION_DOCS_MD = manual-deployment-option-docs-md;
  };

  passthru = {
    html = finalAttrs.finalPackage.out + "/share/doc/nixops4/manual/html";
    index = finalAttrs.passthru.html + "/index.html";
    /** To add to the project-wide dev shell */
    externalBuildTools = [
      mdbook
      mdbook-mermaid
      nixdoc
      json-schema-for-humans
      jq
    ];
  };
})
