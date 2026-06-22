{
  description = "d20 dev environment";

  inputs = {
    # Stable-enough rolling channel for day-to-day development.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Keep the flake output portable across Linux/macOS targets we may develop on.
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        # Match the BEAM major we want to run locally before adding Phoenix deps.
        beam = pkgs.beam.packages.erlang_28;
        elixir = beam.elixir_1_20;
        gardenVersion = "0.13.64";
        gardenPlatform = {
          aarch64-darwin = "macos-arm64";
          aarch64-linux = "linux-arm64";
          x86_64-darwin = "macos-amd64";
          x86_64-linux = "linux-amd64";
        }.${system};
        gardenHash = {
          aarch64-darwin = "sha256-XgcQZzkvYI9jlqfK+51UmRT0VewgBG+YnKRdRynQmko=";
          aarch64-linux = "sha256-iT8qn2EKbsgZ57TpslvoqB3taurLYYLXveYVpcnHn4M=";
          x86_64-darwin = "sha256-QId83CukodZ0kBUTDTTjolf0wxF4zbMu4XLB4awmOzM=";
          x86_64-linux = "sha256-8rmqdlUE+R0jWPJq0cJMdSzCQNe4HnUvJaNhUzyRd4o=";
        }.${system};
        garden = pkgs.stdenvNoCC.mkDerivation {
          pname = "garden";
          version = gardenVersion;

          src = pkgs.fetchurl {
            url = "https://download.garden.io/core/${gardenVersion}/garden-${gardenVersion}-${gardenPlatform}.tar.gz";
            hash = gardenHash;
          };

          sourceRoot = gardenPlatform;
          nativeBuildInputs = pkgs.lib.optionals pkgs.stdenv.isLinux [
            pkgs.autoPatchelfHook
          ];
          buildInputs = pkgs.lib.optionals pkgs.stdenv.isLinux [
            pkgs.stdenv.cc.cc.lib
          ];

          installPhase = ''
            runHook preInstall

            install -Dm755 garden "$out/bin/garden"

            runHook postInstall
          '';
        };

        commonShellHook = ''
          # C.UTF-8 is available without pulling glibcLocales into the shell.
          export LANG=C.UTF-8
          export LANGUAGE=C
          export LC_ALL=C.UTF-8
          export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
          export NIX_SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        '';

        hostPackages = [
          beam.erlang
          elixir
          pkgs.docker-client
          garden
          pkgs.git
          pkgs.just
          pkgs.k3d
          pkgs.kubectl
          (pkgs.python3.withPackages (pythonPackages: [
            pythonPackages.pyyaml
          ]))
          pkgs.telepresence2
          # Phoenix uses PostgreSQL locally by default.
          pkgs.postgresql
        ];
      in {
        packages.garden = garden;

        devShells.default = pkgs.mkShell {
          packages = hostPackages;

          shellHook = commonShellHook + ''
            if [ "''${CI:-}" != "true" ]; then
              export PGDATA="$PWD/.pg_data"
              export PGHOST="$PGDATA"

              if [ ! -d "$PGDATA" ]; then
                initdb --pgdata "$PGDATA" --username postgres --auth-local=trust --auth-host=trust >/dev/null
                echo "unix_socket_directories = '$PGDATA'" >> "$PGDATA/postgresql.conf"
                pg_ctl start -D "$PGDATA" -l "$PGDATA/log" -s
              else
                pg_ctl status -D "$PGDATA" -s >/dev/null 2>&1 || pg_ctl start -D "$PGDATA" -l "$PGDATA/log" -s
              fi
            fi
          '';
        };
      });
}
