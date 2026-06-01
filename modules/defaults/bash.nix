{
  programs.bash = {
    promptInit = ''
      y="$(tput setaf 11)"
      m="$(tput setaf 13)"
      c="$(tput setaf 14)"
      b="$(tput bold)"
      i="$(tput sitm)"
      r="$(tput sgr0)"

      PS1="(\[$b$y\]\u\[$r\]@\h \[$i$c\]\W\[$r\]) \[$b$m\]\@\[$r\] $ "

      function y() {
        local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
        yazi "$@" --cwd-file="$tmp"
        if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
          builtin cd -- "$cwd"
        fi
        rm -f -- "$tmp"
      }
    '';
  };
}
