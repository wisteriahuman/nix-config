{ pkgs, config, ... }:

{
  imports = [ ../common.nix ];

  home.username = "wisteria";
  home.homeDirectory = "/Users/wisteria";

  # 最初にswitchしたhome-managerのリリースに合わせて固定する値。
  # 後から上げるのは任意だが、下げてはいけない。
  home.stateVersion = "25.05";

  xdg.configFile = {
    "wezterm/wezterm.lua".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/nix-config/wezterm/wezterm.lua";
    "wezterm/keybinds.lua".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/nix-config/wezterm/keybinds.lua";
    "mise/config.toml".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/nix-config/mise/config.toml";
  };
}
