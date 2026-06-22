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
          # The Mix bun installer downloads a generic Linux binary that does not
          # run in the nixos/nix Docker image without patching.
          export MIX_BUN_PATH="${pkgs.bun}/bin/bun"
        '';

        hostPackages = [
          beam.erlang
          elixir
          pkgs.docker-client
          pkgs.git
          pkgs.just
          pkgs.k3d
          pkgs.kubectl
          # Phoenix uses PostgreSQL locally by default.
          pkgs.postgresql
          pkgs.tilt
        ];

        containerPackages = [
          pkgs.bash
          beam.erlang
          elixir
          pkgs.bun
          pkgs.cacert
          pkgs.coreutils
          pkgs.findutils
          pkgs.gawk
          pkgs.gcc
          pkgs.gitMinimal
          pkgs.gnugrep
          pkgs.gnused
          pkgs.gnutar
          pkgs.gzip
          pkgs.gnumake
          pkgs.inotify-tools
        ];

        runtimePackages = [
          pkgs.bash
          pkgs.cacert
          pkgs.coreutils
          pkgs.findutils
          pkgs.gawk
          pkgs.gcc.cc.lib
          pkgs.gnugrep
          pkgs.gnused
          pkgs.ncurses
          pkgs.openssl.out
          pkgs.patchelf
          pkgs.systemdLibs
          pkgs.zlib
        ];

        toolchainRoot = pkgs.buildEnv {
          name = "toolchain-root";
          paths = containerPackages;
          pathsToLink = [ "/bin" "/etc" ];
        };

        runtimeRoot = pkgs.buildEnv {
          name = "runtime-root";
          paths = runtimePackages;
          pathsToLink = [ "/bin" "/etc" "/lib" ];
        };

      in {
        packages.runtime = runtimeRoot;

        packages.toolchainImage = pkgs.dockerTools.streamLayeredImage {
          name = "d20/toolchain";
          tag = "latest";
          maxLayers = 100;

          contents = [ toolchainRoot ];

          extraCommands = ''
            mkdir -p app etc/pki/tls/certs root tmp usr/bin
            ln -s /etc/ssl/certs/ca-bundle.crt etc/pki/tls/certs/ca-bundle.crt
            ln -s /bin/env usr/bin/env
          '';

          config = {
            Env = [
              "CI=true"
              "HOME=/root"
              "LANG=C.UTF-8"
              "LANGUAGE=C"
              "LC_ALL=C.UTF-8"
              "MIX_BUN_PATH=/bin/bun"
              "NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
              "PATH=/bin"
              "SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
            ];
            WorkingDir = "/app";
          };
        };

        packages.runtimeImage = pkgs.dockerTools.streamLayeredImage {
          name = "d20/runtime";
          tag = "latest";
          maxLayers = 100;

          contents = [ runtimeRoot ];

          extraCommands = ''
            mkdir -p app bin etc/pki/tls/certs tmp usr/bin
            ln -sf bash bin/sh
            ln -sf /etc/ssl/certs/ca-bundle.crt etc/pki/tls/certs/ca-bundle.crt
            ln -sf /bin/env usr/bin/env
            chmod 1777 tmp
          '';

          config = {
            Env = [
              "HOME=/tmp"
              "LANG=C.UTF-8"
              "LANGUAGE=C"
              "LC_ALL=C.UTF-8"
              "MIX_ENV=prod"
              "NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
              "PATH=/bin"
              "SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
            ];
            WorkingDir = "/app";
          };
        };

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

        devShells.container = pkgs.mkShell {
          packages = containerPackages;

          shellHook = commonShellHook;
        };
      });
}
