{ pkgs, ... }:

let
  # 固定済み nixpkgs にまだないため、公式リリースからビルドする。
  shuck = pkgs.rustPlatform.buildRustPackage rec {
    pname = "shuck";
    version = "0.2.3";

    src = pkgs.fetchurl {
      url = "https://github.com/ewhauser/shuck/releases/download/v${version}/source.tar.gz";
      hash = "sha256-WlO0nis/m/4Q7XMC/ZykiiSqgedPo9Vmn5RJjXS0JfA=";
    };
    cargoHash = "sha256-XoXnOE9jyhm6kJ0693CJ8PE4/1Sn+fyv0nLs2GG+J6M=";
    cargoBuildFlags = [ "--package" "shuck-cli" ];
    cargoTestFlags = [ "--package" "shuck-cli" ];

    meta = {
      description = "Shell linter and language server with zsh support";
      homepage = "https://github.com/ewhauser/shuck";
      license = pkgs.lib.licenses.mit;
      mainProgram = "shuck";
    };
  };
in

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
    shuck
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
