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
      inherit (nixpkgs) lib;

      # role ごとに、その role を使えるシステム(CPUアーキテクチャ+OS)を列挙する。
      # 先頭がその role の既定システム。
      roles = {
        mac-full = {
          module = ./hosts/mac-full.nix;
          systems = [ "aarch64-darwin" "x86_64-darwin" ];
        };
        linux-minimal = {
          module = ./hosts/linux-minimal.nix;
          systems = [ "x86_64-linux" "aarch64-linux" ];
        };
      };

      mkHome = system: module:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          modules = [ module ];
        };

      # 1つの role から
      #   "wisteria@<role>-<system>"  … 対応システムぶん全部
      #   "wisteria@<role>"           … 既定システムへの別名
      # を生やす。bootstrap.sh / nix-sync は前者を使う。
      configsForRole = role: def:
        lib.listToAttrs
          (map
            (system: lib.nameValuePair "wisteria@${role}-${system}" (mkHome system def.module))
            def.systems)
        // {
          "wisteria@${role}" = mkHome (lib.head def.systems) def.module;
        };
    in
    {
      homeConfigurations =
        lib.foldl'
          (acc: role: acc // configsForRole role roles.${role})
          { }
          (lib.attrNames roles);
    };
}
