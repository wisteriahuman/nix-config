{ pkgs, config, ... }:

{
  home.username = "wisteria";
  home.homeDirectory = "/Users/wisteria";

  # 最初にswitchしたhome-managerのリリースに合わせて固定する値。
  # 後から上げるのは任意だが、下げてはいけない。
  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    ripgrep
    fzf
    eza
    bat
    sheldon
  ];

  # home-manager自体をこの環境のパッケージとして管理する
  programs.home-manager.enable = true;

  # 実体はこのリポジトリ配下に置いたまま、~/.config/... からout-of-store symlinkで参照する。
  # store配下へのコピーと違い、直接編集がそのまま反映される。
  xdg.configFile = {
    "wezterm/wezterm.lua".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/nix-config/wezterm/wezterm.lua";
    "wezterm/keybinds.lua".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/nix-config/wezterm/keybinds.lua";
    "sheldon/plugins.toml".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/nix-config/sheldon/plugins.toml";
  };
}
