_docker_remote_sync_to() {
  local local_path=$1
  local remote_path="$HOME/.cache/docker-remote-sync${local_path}"
  ssh surface "mkdir -p '$remote_path'" 2>/dev/null
  rsync -az -q --delete --exclude=.git "${local_path}/" "surface:${remote_path}/"
  print -r -- "$remote_path"
}

_docker_remote_sync_from() {
  local local_path=$1
  local remote_path="$HOME/.cache/docker-remote-sync${local_path}"
  rsync -az -q "surface:${remote_path}/" "${local_path}/"
}

_docker_remote_watch_start() {
  (
    fswatch -o "$@" 2>/dev/null | while read -r _; do
      for p in "$@"; do
        _docker_remote_sync_to "$p" >/dev/null
      done
    done
  ) &
  print -r -- $!
}

_docker_remote_watch_stop() {
  kill "$1" 2>/dev/null
  wait "$1" 2>/dev/null
}

_docker_remote_compose() {
  local local_dir=$PWD
  local remote_dir
  remote_dir=$(_docker_remote_sync_to "$local_dir")

  local -a compose_files
  local i=1
  while (( i <= $# )); do
    case "${@[i]}" in
      -f|--file)
        (( i++ ))
        compose_files+=(-f "${@[i]}")
        ;;
    esac
    (( i++ ))
  done

  local -a port_args
  local ports
  ports=$(ssh surface "cd '$remote_dir' && docker compose ${compose_files[@]} config --format json" 2>/dev/null \
    | jq -r '[.services[].ports[]?.published] | unique | .[]' 2>/dev/null)
  local p
  for p in ${(f)ports}; do
    port_args+=(-L "${p}:localhost:${p}")
  done

  local watcher
  watcher=$(_docker_remote_watch_start "$local_dir")

  ssh -t "${port_args[@]}" surface "cd '$remote_dir' && docker compose $*"
  local status=$?

  _docker_remote_watch_stop "$watcher"
  _docker_remote_sync_from "$local_dir"

  return $status
}

_docker_remote_run() {
  local -a args=("$@")
  local -a local_paths
  local -a port_args
  local i=1

  while (( i <= $#args )); do
    case "${args[i]}" in
      -v|--volume)
        (( i++ ))
        local spec="${args[i]}"
        local src="${spec%%:*}"
        if [[ "$src" == /* || "$src" == .* || "$src" == "~"* ]]; then
          local abs_src="${src:A}"
          local remote_path
          remote_path=$(_docker_remote_sync_to "$abs_src")
          args[i]="${remote_path}${spec#$src}"
          local_paths+=("$abs_src")
        fi
        ;;
      --mount)
        (( i++ ))
        if [[ "${args[i]}" == *type=bind* ]]; then
          local src
          src=$(echo "${args[i]}" | sed -n 's/.*source=\([^,]*\).*/\1/p')
          if [[ -n "$src" ]]; then
            local abs_src="${src:A}"
            local remote_path
            remote_path=$(_docker_remote_sync_to "$abs_src")
            args[i]="${args[i]/source=$src/source=$remote_path}"
            local_paths+=("$abs_src")
          fi
        fi
        ;;
      -p|--publish)
        (( i++ ))
        local port="${args[i]%%:*}"
        port_args+=(-L "${port}:localhost:${port}")
        ;;
    esac
    (( i++ ))
  done

  local watcher
  if (( ${#local_paths} > 0 )); then
    watcher=$(_docker_remote_watch_start "${local_paths[@]}")
  fi

  ssh -t "${port_args[@]}" surface "docker run ${args[*]}"
  local status=$?

  if [[ -n "$watcher" ]]; then
    _docker_remote_watch_stop "$watcher"
  fi
  for p in "${local_paths[@]}"; do
    _docker_remote_sync_from "$p"
  done

  return $status
}

docker() {
  if [[ "$(command docker context show 2>/dev/null)" == "default" ]]; then
    command docker "$@"
    return $?
  fi

  case "$1" in
    compose)
      _docker_remote_compose "${@:2}"
      ;;
    run|create)
      _docker_remote_run "${@:2}"
      ;;
    *)
      command docker "$@"
      ;;
  esac
}
