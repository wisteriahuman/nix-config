# nix-config

Nix (home-manager) で管理する個人の環境設定。

## 前提条件

- SSH鍵を用意し、GitHubに公開鍵を登録しておくこと（`ssh-keygen` → GitHubの Settings > SSH keys）

## 新しいマシンでのセットアップ

```sh
curl -fsSL https://raw.githubusercontent.com/wisteriahuman/nix-config/main/bootstrap.sh | sh
```

OS(macOS/Linux)から役割(role)を自動判定して確認プロンプトを出す。明示的に指定したい場合:

```sh
sh bootstrap.sh mac-full
# または
NIXCONFIG_ROLE=linux-minimal curl -fsSL https://raw.githubusercontent.com/wisteriahuman/nix-config/main/bootstrap.sh | sh
```

Nixのインストール直後は新しいシェルセッションを開いてから再実行が必要。

## 日常の同期

設定を変更してpushした後、他のマシンに反映する:

```sh
nix-sync
```

## 役割(role)の一覧

- `mac-full` — メインの開発機（Mac）。wezterm、mise(フル)、`bin/docker`など一式
- `linux-minimal` — SSH接続で使うLinuxサーバ。Neovim中心の最小構成。`bin/docker`のリモート実行先。新しいLinux機(WSL含む)はこれを使い回す想定

新しい役割を追加する場合は、`hosts/`に倣って新規ファイルを作り、`flake.nix`の`homeConfigurations`に1エントリ追加する。

## `bin/docker`

`docker context`がリモート(`surface`など)を指している時、`docker compose`/`docker run`をカレントディレクトリ(または`-v`で指定したパス)ごとリモートに同期し、ビルド・実行だけリモートで行う透過ラッパー。プロジェクト側の設定変更は不要。

## secretsについて

このリポジトリは public。`~/.config/zsh/hidden/`配下や`~/.ssh/`など、秘密情報を含むファイルは意図的に含まれていない。
