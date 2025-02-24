{pkgs ? import <nixpkgs> { }}:

pkgs.rustPlatform.buildRustPackage rec {
  pname = "hybrid";
  version = "1.0.0";
  src = pkgs.lib.cleanSource ./.;
  cargoLock.lockFile = "${src}/Cargo.lock";
}
