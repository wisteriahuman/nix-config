{ pkgs, config, ... }:

{
  imports = [ ../common.nix ];

  home.username = "wisteria";
  home.homeDirectory = "/Users/wisteria";

  home.stateVersion = "25.05";

  home.packages = with pkgs; [ wget xcodegen ];

  home.file = {
    ".local/bin/tailscale".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/nix-config/bin/tailscale";
  };

  xdg.configFile = {
    "wezterm/wezterm.lua".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/nix-config/wezterm/wezterm.lua";
    "wezterm/keybinds.lua".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/nix-config/wezterm/keybinds.lua";
    "mise/conf.d/10-mac.toml".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/nix-config/mise/mac.toml";
    "zsh/.zprofile".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/nix-config/zsh/.zprofile";
  };
}
