# WILL OF THE CITY :: THE INDEX — Fish

if status is-interactive
    set -g fish_color_normal 85C5E8
    set -g fish_color_command FFFFFF
    set -g fish_color_keyword 5DADE2
    set -g fish_color_quote 85C5E8
    set -g fish_color_redirection 5DADE2
    set -g fish_color_end 3A7CA5
    set -g fish_color_error FF6B6B
    set -g fish_color_param 85C5E8
    set -g fish_color_comment 3A7CA5
    set -g fish_color_selection --background=3A7CA5
    set -g fish_color_search_match --background=3A7CA5
    set -g fish_color_operator 5DADE2
    set -g fish_color_escape 5DE285
    set -g fish_color_autosuggestion 3A7CA5
    set -g fish_color_cancel FF6B6B

    if command -q fastfetch
        fastfetch
    end
end

function fish_greeting
    set_color 5DADE2
    echo 'WILL OF THE CITY :: THE INDEX'
    set_color normal
end

function __index_git_segment
    command -q git; or return
    command git rev-parse --is-inside-work-tree >/dev/null 2>&1; or return

    set -l branch (command git symbolic-ref --quiet --short HEAD 2>/dev/null)
    if test -z "$branch"
        set branch (command git rev-parse --short HEAD 2>/dev/null)
    end
    test -n "$branch"; or return

    set -l dirty (command git status --porcelain --untracked-files=normal 2>/dev/null | string collect)
    if test -n "$dirty"
        set branch "$branch*"
    end
    printf '%s' "$branch"
end

function fish_prompt
    set -l last_status $status
    set -l branch (__index_git_segment)

    set_color 5DADE2
    printf '[ '
    set_color FFFFFF
    printf '%s' "$USER"
    set_color 3A7CA5
    printf '@'
    set_color 85C5E8
    printf '%s' (prompt_hostname)
    set_color 5DADE2
    printf ' ] :: '
    set_color 85C5E8
    printf '%s' (prompt_pwd)

    if test -n "$branch"
        set_color 5DADE2
        printf ' :: '
        set_color FFFFFF
        printf '%s' "$branch"
    end

    echo
    if test $last_status -eq 0
        set_color 5DADE2
        printf '> '
    else
        set_color FF6B6B
        printf '!> '
    end
    set_color normal
end
