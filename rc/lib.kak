# Show Unicode value in the status line.
define-command -override declare-cursor-character-unicode-expansion -docstring 'declare %opt{cursor_character_unicode} expansion' %{
  declare-option str cursor_character_unicode
  remove-hooks global update-cursor-character-unicode-expansion
  hook -group update-cursor-character-unicode-expansion global NormalIdle '' %{
    set-option window cursor_character_unicode %sh{printf '%04x' "$kak_cursor_char_value"}
  }
}

define-command -override delete-scratch-message -docstring 'delete scratch message' %{
  remove-hooks global delete-scratch-message
  hook -group delete-scratch-message global BufCreate '\*scratch\*' %{
    execute-keys '%d'
  }
}

declare-option -docstring 'find command' str find_command 'fd --type file'

define-command -override find -menu -params 1 -shell-script-candidates %opt{find_command} -docstring 'open file' %{
  edit %arg{1}
}

alias global f find

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

# Registers: https://github.com/mawww/kakoune/blob/master/doc/pages/registers.asciidoc
# Source code: https://github.com/mawww/kakoune/blob/master/src/register_manager.cc
define-command -override evaluate-commands-pure -params .. -docstring 'evaluate-commands -pure [switches] <commands>' %{
  evaluate-commands -no-hooks -save-regs '"#%./0123456789:@ABCDEFGHIJKLMNOPQRSTUVWXYZ^_abcdefghijklmnopqrstuvwxyz|' %arg{@}
}

define-command -override append-text -params .. -docstring 'append-text [values]' %{
  evaluate-commands -save-regs '"' %{
    set-register dquote %arg{@}
    execute-keys '<a-p>'
  }
}

define-command -override insert-text -params .. -docstring 'insert-text [values]' %{
  evaluate-commands -save-regs '"' %{
    set-register dquote %arg{@}
    execute-keys '<a-P>'
  }
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

define-command -override sort-selections -docstring 'sort selections' %{
  connect run kcr pipe jq sort
}

define-command -override reverse-selections -docstring 'reverse selections' %{
  connect run kcr pipe jq reverse
}

declare-option -hidden str-list palette

define-command -override show-palette -docstring 'show palette' %{
  evaluate-commands -draft %{
    # Select the viewport
    execute-keys 'gtGb'
    # Select colors
    execute-keys '2s(#|rgb:)([0-9A-Fa-f]{6})<ret>'
    set-option window palette %reg{.}
  }
  info -anchor "%val{cursor_line}.%val{cursor_column}" -markup %sh{
    printf '{rgb:%s}██████{default}\n' $kak_opt_palette
  }
}

define-command -override make-directory-on-save -docstring 'make directory on save' %{
  remove-hooks global make-directory-on-save
  hook -group make-directory-on-save global BufWritePre '.*' %{
    nop %sh{
      # The full path of the file does not work with scratch buffers,
      # hence using `dirname`.
      # buffer_directory_path=${kak_buffile%/*}
      buffer_directory_path=$(dirname "$kak_buffile")
      if [ ! -d "$buffer_directory_path" ]; then
        mkdir -p "$buffer_directory_path"
      fi
    }
  }
}

# Documentation: https://xfree86.org/current/ctlseqs.html#:~:text=clipboard
define-command -override synchronize-clipboard -docstring 'synchronize clipboard' %{
  remove-hooks global synchronize-clipboard
  hook -group synchronize-clipboard global RegisterModified '"' %{
    nop %sh{
      encoded_selection_data=$(printf '%s' "$kak_main_reg_dquote" | base64)
      printf '\033]52;c;%s\a' "$encoded_selection_data" > /dev/tty
    }
  }
}
