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
            # Keep the JS toolchain in the shell for the workspace-managed assets package.
            pkgs.nodejs_22
            pkgs.pnpm
          ];

          shellHook = ''
            # Elixir expects a locale archive on Nix-based shells.
            export LOCALE_ARCHIVE=${pkgs.glibcLocales}/lib/locale/locale-archive
          '';
        };
      });
}
