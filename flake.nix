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
    {
      homeConfigurations."wisteria@m5-macbook-air" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages."aarch64-darwin";
        modules = [ ./hosts/m5-macbook-air.nix ];
      };

      homeConfigurations."wisteria@surface" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages."x86_64-linux";
        modules = [ ./hosts/surface.nix ];
      };

      # 将来Windows機(NixOS-WSL)を使うようになったら、
      # homeConfigurations."wisteria@<host>" を追加する
    };
}
