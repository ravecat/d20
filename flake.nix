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
          pkgs.docker-compose
          pkgs.direnv
          pkgs.git
          pkgs.just
          # Phoenix uses PostgreSQL locally by default.
          pkgs.postgresql
          pkgs.watchexec
        ] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [ pkgs.procps ];
      in {
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
