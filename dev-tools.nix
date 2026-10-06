{ pkgs, ... }:

{
  # Neovim が使う LSP・リンタ・フォーマッタ。
  # gopls / goimports / ruby-lsp / rust-analyzer は言語処理系と版を合わせる必要があるので
  # ここには置かず、mise や rustup 側で入れる。
  home.packages = with pkgs; [
    # LSP
    lua-language-server
    vtsls
    vscode-langservers-extracted # html / css / json / eslint
    astro-language-server
    pyright
    bash-language-server
    yaml-language-server
    taplo
    marksman
    nixd
    dockerfile-language-server
    docker-compose-language-service

    # リンタ・フォーマッタ
    biome
    # clang-format / clang-tidy 用。同梱の clangd は macOS の SDK を見つけられないので
    # mac では使わず、nvim 側で /usr/bin/clangd に固定している
    clang-tools
    ruff
    stylua
    shellcheck
    shfmt
    hadolint
    actionlint
  ];
}
