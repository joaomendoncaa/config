{
  description = "Systems config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    packages.${system} = {
      desktop = pkgs.buildEnv {
        name = "desktop";
        paths = with pkgs; [
          neovim
          gh
          starship
          yazi
          tmux
          lazygit
          atuin
          zoxide
          git
          rustup
          gcc
          fzf
        ];
      };
      default = self.packages.${system}.desktop;
    };
  };
}
