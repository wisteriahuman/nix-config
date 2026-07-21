{ pkgs, config, ... }:

{
  imports = [ ../common.nix ];

  home.username = "wisteria";
  home.homeDirectory = "/home/wisteria";

  home.stateVersion = "25.05";

  home.packages = [ pkgs.mise pkgs.gcc ];

  xdg.configFile."mise/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/nix-config/mise/surface.toml";
}
