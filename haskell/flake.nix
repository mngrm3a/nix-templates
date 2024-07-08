{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs =
    { self, nixpkgs, ... }:
    let
      packageName = "my-package";
      supportedSystems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);
      pkgsFor = forAllSystems (
        system:
        import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
        }
      );
      withEnv =
        system: f:
        let
          pkgs = pkgsFor.${system};
        in
        f rec {
          inherit pkgs;
          haskellPackages = pkgs.haskellPackages;
          haskellTools = with haskellPackages; [
            haskell-language-server
            ghcid
            hpack
            cabal-install
            stack
          ];
        };
    in
    {
      overlays.default = final: prev: {
        ${packageName} = final.haskellPackages.callCabal2nix packageName ./. { };
      };

      packages = forAllSystems (system: {
        default = pkgsFor.${system}.${packageName};
      });

      devShells = forAllSystems (system: {
        boot = withEnv system (
          { pkgs, haskellTools, ... }: pkgs.mkShellNoCC { nativeBuildInputs = haskellTools; }
        );
        default = withEnv system (
          { haskellPackages, haskellTools, ... }:
          haskellPackages.shellFor {
            packages = p: [ self.packages.${system}.default ];
            withHoogle = true;
            nativeBuildInputs = haskellTools;
          }
        );
      });
    };
}

