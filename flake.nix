{
  description = "Modular zsh dotfiles with NixOS support";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      # Support both x86_64 and aarch64 Linux systems
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      # NixOS module for user-specific zsh dotfiles
      # Uses standard module signature - dotfilesSource is passed as an option
      nixosModules.default = ./modules/zsh-dotfiles.nix;

      # Formatter for nix fmt (available on all supported systems)
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt);
    };
}
