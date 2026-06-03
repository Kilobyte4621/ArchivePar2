# Version Details: v0.0
# Initial script to add current dir (full of .sh scripts) to your .bashrc file
add2bash() {
  local bashrc="$HOME/.bashrc"
  local reply
  local text

  if [[ -n "$1" ]]; then
    text="$1"

    cat <<EOF
The following text will be appended to:

  $bashrc

$text

EOF

    read -rp "Proceed? [y/N] " reply

    case "$reply" in
      [yY]|[yY][eE][sS])
        printf '%s\n' "$text" >> "$bashrc"
        echo "Appended to $bashrc"
        ;;
      *)
        echo "Cancelled."
        ;;
    esac

    return
  fi

  local cwd="$PWD"

  text=$(cat <<EOF
for f in "$cwd/"*.sh; do
  source "\$f"
done
EOF
)

  cat <<EOF
No text provided.

The following text will be appended to:

  $bashrc

$text

EOF

  read -rp "Proceed? [y/N] " reply

  case "$reply" in
    [yY]|[yY][eE][sS])
      {
        echo
        printf '%s\n' "$text"
      } >> "$bashrc"
      echo "Lines added to $bashrc"
      ;;
    *)
      echo "Cancelled."
      ;;
  esac
}
