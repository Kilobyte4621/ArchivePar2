# Version Details: v0.1
# Initial script to backup a full directory, file by file. (Atualizado para repassar flags)
folderbkp() {
  local parent="$1"
  local item

  [[ -n "$parent" ]] || {
    echo "Error: no folder provided"
    return 1
  }

  parent="$(realpath -e "$parent")" || return 1
  [[ -d "$parent" ]] || return 1

  # Captura todos os argumentos a partir do segundo ($2, $3, etc.)
  # e os armazena com segurança preservando espaços e aspas.
  shift
  local extra_args=("$@")

  local old_nullglob old_dotglob
  shopt -q nullglob && old_nullglob=1 || old_nullglob=0
  shopt -q dotglob  && old_dotglob=1  || old_dotglob=0

  cleanup() {
    (( old_nullglob )) || shopt -u nullglob
    (( old_dotglob  )) || shopt -u dotglob
  }

  trap cleanup RETURN

  shopt -s nullglob dotglob

  for item in "$parent"/*; do
    # Passa o item atual E expande o array de flags extras
    backup "$item" "${extra_args[@]}" || return 1
  done
}
