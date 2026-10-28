{ pkgs, config, inputs, ... }:

{
  imports = [ ../common.nix ../dev-tools.nix inputs.ken.homeManagerModules.default ];

  programs.ken = {
    enable = pkgs.stdenv.hostPlatform.system == "aarch64-darwin";
    profile = "9avsrp8n.Default (release)";
  };

  # home.username / home.homeDirectory は common.nix が実行中のアカウントから決める

  home.stateVersion = "25.05";

  # Spotlight と既定のブラウザ指定はリンクの .app を拾わないので、実物をコピーして置く
  targets.darwin.linkApps.enable = false;
  targets.darwin.copyApps.enable = true;

  home.packages = (with pkgs; [ wget xcodegen duckdb imagemagick coreutils-prefixed ]) ++ [
    inputs.mermaid-lsp.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

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
