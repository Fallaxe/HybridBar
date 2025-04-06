{
  description = "HybridBar - A status bar focused on wlroots Wayland compositors";

  inputs = {
    flake-compat.url = "github:edolstra/flake-compat/refs/pull/65/head";
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, rust-overlay, flake-compat, ... }: 
  let
    overlays = [
      (import rust-overlay)
      self.overlays.default
    ];

    pkgsFor = system: import nixpkgs { inherit system overlays; };

    targetSystems = [
      "x86_64-linux"
      "aarch64-linux"
    ];

    mkRustToolchain = pkgs: pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;

  in {
    overlays.default = final: prev: {
      inherit (self.packages.${final.system}) hyprbar;
    };

    packages = nixpkgs.lib.genAttrs targetSystems (system: 
      let
        pkgs = pkgsFor system;
        rust = mkRustToolchain pkgs;
        rustPlatform = pkgs.makeRustPlatform {
          cargo = rust;
          rustc = rust;
        };
        version = (builtins.fromTOML (builtins.readFile ./Cargo.toml)).package.version;
      in rec {
        hybrid = rustPlatform.buildRustPackage {
          version = "${version}";
          pname = "hybrid";
          src = ./.;
          cargoLock.lockFile = ./Cargo.lock;  
          cargoBuildFlags = [
              "--bin"
              "hybrid-bar"
            ];

          nativeBuildInputs = with pkgs; [
            pkg-config
            wrapGAppsHook
          ];

          buildInputs = with pkgs; [
              gtk3
              gtk-layer-shell 
              wlroots 
              librsvg
              libdbusmenu-gtk3
              wget
          ];
          
          doCheck = false;
        };
      }
    );

    defaultPackage.x86_64-linux = self.packages.x86_64-linux.hybrid;
    shellHook = ''
      export GDK_BACKEND=wayland
    '';
  };
}
