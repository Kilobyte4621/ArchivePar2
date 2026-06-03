# Version Details: v0.1
# CORRIGIDO: Agora aceita argumentos.
sh2txt () {
  # 1. Store the first argument passed to the function ($1), defaulting to current dir (.) if empty
  local dir="${1:-.}"
  local f

  # 2. Check if there are actually any .sh files to avoid the "cannot stat" error
  # (Using shopt -s nullglob inside a subshell is cleanest, or we can just check file existence)

  for f in "$dir"/*.sh; do
    # Ensure it's a real file before copying (handles the case where no .sh files exist)
    [ -f "$f" ] || continue
    cp -- "$f" "${f%.sh}.txt"
  done

  # --- RECURSIVE OPTION ---
  # If you want it to go recursive using 'find', uncomment the line below and comment out the loop above:
  # find "$dir" -type f -name '*.sh' -exec sh -c 'for f; do cp -- "$f" "${f%.sh}.txt"; done' sh {} +
}
