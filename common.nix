{ pkgs, config, lib, ... }:

let
  # ログイン中のアカウント名に追従する。クラウドVMなど、ユーザ名が wisteria とは
  # 限らないマシンでも同じ role をそのまま使い回せるようにするため。
  # bootstrap.sh / nix-sync は home-manager switch に --impure を付けて呼ぶ。
  # 純粋評価では getEnv が "" を返すので、その場合は既定値にフォールバックする。
  firstNonEmpty = lib.findFirst (s: s != "") "";

  username =
    let v = firstNonEmpty (map builtins.getEnv [ "NIXCONFIG_USER" "USER" "LOGNAME" ]);
    in if v != "" then v else "wisteria";

  homeDirectory =
    let v = builtins.getEnv "HOME";
    in
    if v != "" then v
    else if pkgs.stdenv.hostPlatform.isDarwin then "/Users/${username}"
    else "/home/${username}";
in
{
  home.username = username;
  home.homeDirectory = homeDirectory;

  home.packages = with pkgs; [
    # コアのエディタなので mise ではなく nix 側で入れる。
    # bootstrap 直後（mise install 前）から使え、アーキテクチャも自動で合う。
    neovim
    ripgrep
    fzf
    eza
    bat
    sheldon
    zoxide
    fd
    tree-sitter
    lazygit
    unzip
    fastfetch
    chafa
    cowsay
    tree
    qrencode
    pngquant
    fswatch
    gh
    poppler
    mpv
    yt-dlp
    rsync
    git
    tmux
  ] ++ lib.optionals stdenv.hostPlatform.isLinux [
    # macOS には最初から入っているが、Linux(特に最小構成のサーバ・コンテナ)には
    # 無いことが多い。apt に頼らず nix 側で用意する。
    zsh
  ];

  programs.home-manager.enable = true;

  home.file = {
    ".zshenv".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/nix-config/zsh/.zshenv";
    ".local/bin/docker".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/nix-config/bin/docker";
    ".local/bin/nix-sync".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/nix-config/bin/nix-sync";
  };

  xdg.configFile = {
    "git/ignore".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/nix-config/git/ignore";
    "sheldon/plugins.toml".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/nix-config/sheldon/plugins.toml";
    "zsh/.zshrc".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/nix-config/zsh/.zshrc";
    "zsh/.p10k.zsh".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/nix-config/zsh/.p10k.zsh";
    "nvim".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/nix-config/nvim";
    "mise/conf.d/00-common.toml".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/nix-config/mise/common.toml";
  };
}
