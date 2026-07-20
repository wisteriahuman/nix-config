{ pkgs, config, ... }:

{
  home.packages = with pkgs; [
    ripgrep
    fzf
    eza
    bat
    sheldon
  ];

  # home-manager自体をこの環境のパッケージとして管理する
  programs.home-manager.enable = true;

  # $HOME直下必須のファイル(XDG非対応)はhome.fileで扱う
  home.file = {
    ".zshenv".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/nix-config/zsh/.zshenv";
  };

  # 実体はこのリポジトリ配下に置いたまま、~/.config/... からout-of-store symlinkで参照する。
  # store配下へのコピーと違い、直接編集がそのまま反映される(nvimのlazy-lock.json書き込みにも必要)。
  xdg.configFile = {
    "sheldon/plugins.toml".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/nix-config/sheldon/plugins.toml";
    "zsh/.zshrc".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/nix-config/zsh/.zshrc";
    "zsh/.zprofile".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/nix-config/zsh/.zprofile";
    "zsh/.p10k.zsh".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/nix-config/zsh/.p10k.zsh";
    "nvim".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/nix-config/nvim";
  };
}
