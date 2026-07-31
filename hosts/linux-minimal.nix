{ pkgs, config, ... }:

{
  imports = [ ../common.nix ];

  # home.username / home.homeDirectory は common.nix が実行中のアカウントから決める

  home.stateVersion = "25.05";

  home.packages = [ pkgs.mise pkgs.gcc ];

  services.ssh-agent.enable = true;

  xdg.configFile."mise/conf.d/10-linux-minimal.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/nix-config/mise/linux-minimal.toml";
}
