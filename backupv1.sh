# Version Details: v0.1
# Agora interpreta flags e as passa para archivepar2 ou restorepar2
backup() {
  local src=""
  local base out dir
  local full_restore_level=0
  local -a create_flags=()
  local startdir="$PWD"
  local backupdir

  # ------------------------------------------------------------
  # GERENCIAMENTO DINÂMICO E AUTOMÁTICO DE ARGUMENTOS
  # ------------------------------------------------------------
  while [[ $# -gt 0 ]]; do
    local current_arg="${1^^}"

    case "$current_arg" in
      --FULL)
        # Se passar apenas --full, assume nível 1 (BLAKE3 + Zstd inteligente)
        full_restore_level=1
        ;;
      --FULL=1)
        full_restore_level=1
        ;;
      --FULL=2)
        # Nível 2 força o teste estrutural do TAR no final (Força Bruta)
        full_restore_level=2
        ;;
      --*)
        # Qualquer outra flag vai direto para o array de criação
        create_flags+=("$1")
        ;;
      *)
        # Se bater com o padrão de tamanho (ex: 2G, 500M)
        if [[ "$current_arg" =~ ^[1-9]+[0-9]*[KMGTP]$ ]]; then
          create_flags+=("$1")
        # Se não for flag nem tamanho, assume que é o diretório de origem
        elif [[ -z "$src" ]]; then
          src="$1"
        else
          echo "ERROR: Invalid or duplicate argument: $1"
          return 1
        fi
        ;;
    esac
    shift
  done

  # ------------------------------------------------------------
  # VALIDAÇÃO DO DIRETÓRIO DE ORIGEM
  # ------------------------------------------------------------
  if [[ -z "$src" ]]; then
    echo "Error: no input folder provided"
    return 1
  fi

  src="$(realpath -e "$src")" || {
    echo "Error: path not found"
    return 1
  }

  base="$(basename "$src")"

  out=$(printf "%s" "$base" \
    | tr '[:upper:]' '[:lower:]' \
    | tr ' ' '_' \
    | sed 's/[^a-z0-9_-]//g')

  dir="${out}-bak"

  # ------------------------------------------------------------
  # EXECUÇÃO DO PIPELINE
  # ------------------------------------------------------------
  # 1. Cria o arquivo passando automaticamente as flags de criação
  archivepar2 "$src" "${create_flags[@]}" || return 1
  backupdir="$(realpath -m "$startdir/$dir")"

  # 2. Executa o restorepar2 passando o nível correto selecionado
    if (( full_restore_level > 0 )); then
        restorepar2 "$backupdir" --full="$full_restore_level" || return 1
    else
        restorepar2 "$backupdir" || return 1
    fi
}
