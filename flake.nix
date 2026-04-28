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
      in {
        devShells.default = pkgs.mkShell {
          packages = [
            beam.erlang
            beam.elixir_1_19
            pkgs.git
            pkgs.glibcLocales
            pkgs.jq
            # Keep the JS toolchain in the shell for the Nx workspace tooling.
            pkgs.nodejs_22
            pkgs.pnpm
            # Phoenix uses PostgreSQL locally by default.
            pkgs.postgresql
          ];

          shellHook = ''
            # Elixir expects a locale archive on Nix-based shells.
            export LOCALE_ARCHIVE=${pkgs.glibcLocales}/lib/locale/locale-archive

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
