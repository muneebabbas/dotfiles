{
  description = "Modular zsh dotfiles with NixOS support";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      # NixOS module for user-specific zsh dotfiles
      # Pass self so module can reference dotfiles from Nix store
      nixosModules.default = import ./modules/zsh-dotfiles.nix { dotfilesSource = self; };

      # Optional: formatter for nix fmt
      formatter.${system} = pkgs.nixpkgs-fmt;
    };
}
