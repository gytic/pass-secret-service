{
  description = "Description for the project";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-rust = {
      url = "git+https://git.solarpunk.social/solarpunk-kollektiv-dd/nix-rust";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        # To import an internal flake module: ./other.nix
        # To import an external flake module:
        #   1. Add foo to inputs
        #   2. Add foo as a parameter to the outputs function
        #   3. Add here: foo.flakeModule

      ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      perSystem =
        {
          config,
          self',
          inputs',
          pkgs,
          system,
          ...
        }:
        {

          devShells.default = inputs.nix-rust.lib.shell.mkRustShell {
            base = "nativeBase";
            system = pkgs.system;
          };

          packages.default = inputs.nix-rust.lib.build.buildRustPackage {
            inherit pkgs;
            src = inputs.self;

            cargoLock = "${inputs.self}/Cargo.lock";
            pname = "pass-secret-service";
            version = (builtins.fromTOML (builtins.readFile "${inputs.self}/Cargo.toml")).package.version;
          };

          packages.service = pkgs.runCommand "pass-secret-service" { } ''
            mkdir -p "$out/share/dbus-1/services/" "$out/lib/systemd/user/"
            sed -e "s|/usr/bin/pass-secret-service|${self'.packages.default}|g" "${./systemd/org.freedesktop.secrets.service}" > "$out/share/dbus-1/services/org.freedesktop.secrets.service"
            sed -e "s|/usr/bin/pass-secret-service|${self'.packages.default}|g" "${./systemd/pass-secret-service.service}" > "$out/lib/systemd/user/pass-secret-service.service"
          '';

        };
    };
}
