# Show Unicode value in the status line.
define-command -override declare-cursor-character-unicode-expansion -docstring 'declare %opt{cursor_character_unicode} expansion' %{
  declare-option str cursor_character_unicode
  remove-hooks global update-cursor-character-unicode-expansion
  hook -group update-cursor-character-unicode-expansion global NormalIdle '' %{
    set-option window cursor_character_unicode %sh{printf '%04x' "$kak_cursor_char_value"}
  }
}

define-command -override remove-scratch-message -docstring 'remove scratch message' %{
  remove-hooks global remove-scratch-message
  hook -group remove-scratch-message global BufCreate '\*scratch\*' %{
    execute-keys '%d'
    hook -always -once buffer NormalIdle '' %{
      rename-buffer /dev/null
      evaluate-commands -no-hooks -- edit -scratch '*scratch*'
      delete-buffer /dev/null
    }
  }
}

define-command -override open-kakrc -docstring 'open kakrc' %{
  edit "%val{config}/kakrc"
}

define-command -override source-kakrc -docstring 'source kakrc' %{
  source "%val{config}/kakrc"
}

define-command -override source-runtime -menu -params 1 -shell-script-candidates 'cd "$kak_runtime" && find -L . -type f -name "*.kak" | sort -u' -docstring 'source from %val{runtime}' %{
  source "%val{runtime}/%arg{1}"
}

define-command -override source-config -menu -params 1 -shell-script-candidates 'cd "$kak_config" && find -L . -type f -name "*.kak" | sort -u' -docstring 'source from %val{config}' %{
  source "%val{config}/%arg{1}"
}

define-command -override append-text -params .. -docstring 'append-text [values]' %{
  execute-keys 'aX<esc>;'
  replace-text %arg{@}
}

define-command -override insert-text -params .. -docstring 'insert-text [values]' %{
  execute-keys 'iX<esc>h'
  replace-text %arg{@}
}

define-command -override replace-text -params .. -docstring 'replace-text [values]' %{
  evaluate-commands -save-regs '"' %{
    set-register dquote %arg{@}
    execute-keys 'R'
  }
}

define-command -override indent-selections -docstring 'indent selections' %{
  # Replace leading tabs with the appropriate indent.
  try %[ execute-keys -draft "<a-s>s\A\t+<ret>s.<ret>%opt{indentwidth}@" ]
  # Align everything with the current line.
  try %[ execute-keys -draft -itersel '<a-s>Z)<space><a-x>s^\h+<ret>yz)<a-space>_P' ]
}

define-command -override make-directory-on-save -docstring 'make directory on save' %{
  remove-hooks global make-directory-on-save
  hook -group make-directory-on-save global BufWritePre '.*' %{
    nop %sh(mkdir -p "$(dirname "$kak_buffile")")
  }
}

# Documentation: https://xfree86.org/current/ctlseqs.html#:~:text=clipboard
define-command -override synchronize-terminal-clipboard -docstring 'synchronize terminal clipboard' %{
  remove-hooks global synchronize-terminal-clipboard
  hook -group synchronize-terminal-clipboard global RegisterModified '"' %{
    nop %sh{
      encoded_selection_data=$(printf '%s' "$kak_main_reg_dquote" | base64)
      printf '\033]52;c;%s\a' "$encoded_selection_data" > /dev/tty
    }
  }
}
