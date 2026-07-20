{
  description = "wisteria's home-manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      homeConfigurations."wisteria@m5-macbook-air" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./home.nix ];
      };

      # 将来 Linux機/WSL(NixOS-WSL)を使うようになったら、
      # homeConfigurations."wisteria@<host>" を x86_64-linux / aarch64-linux 向けに追加する
    };
}
