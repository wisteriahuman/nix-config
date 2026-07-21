{ pkgs, config, ... }:

{
  home.packages = with pkgs; [
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
    rsync
  ];

  programs.home-manager.enable = true;

  home.file = {
    ".zshenv".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/nix-config/zsh/.zshenv";
    ".local/bin/docker".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/nix-config/bin/docker";
  };

  xdg.configFile = {
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
