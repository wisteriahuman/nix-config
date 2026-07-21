{ pkgs, config, ... }:

{
  imports = [ ../common.nix ];

  home.username = "wisteria";
  home.homeDirectory = "/home/wisteria";

  home.stateVersion = "25.05";

  home.packages = [ pkgs.mise pkgs.gcc ];

  services.ssh-agent.enable = true;

  xdg.configFile."mise/conf.d/10-linux-minimal.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/nix-config/mise/linux-minimal.toml";
}
