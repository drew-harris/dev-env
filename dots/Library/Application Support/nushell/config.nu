# The default config record. This is where much of your global configuration is setup.
$env.config = {
    show_banner: false # true or false to enable or disable the welcome banner at startup
    ls: {clickable_links: false}
    table: {

        # basic, compact, compact_double, light, thin, with_love, rounded, reinforced, heavy, none, other
        mode: light
        index_mode: always # "always" show indexes, "never" show indexes, "auto" = show indexes when a table has "index" column
        show_empty: true # show 'empty list' and 'empty record' placeholders for command output
        padding: {left: 1, right: 1} # a left right padding of each column in a table
        trim: {methodology: wrapping, wrapping_try_keep_words: true, truncating_suffix: "..."}
        header_on_separator: false # show header text on separator/border line
    }
    error_style: "fancy" # "fancy" or "plain" for screen reader-friendly error messages
    history: {
        max_size: 100_000 # Session has to be reloaded for this to take effect
        sync_on_enter: true # Enable to share history between multiple sessions, else you have to close the session to write history to file
        file_format: "plaintext" # "sqlite" or "plaintext"
        isolation: false # only available with sqlite file_format. true enables history isolation, false disables it. true will allow the history to be isolated to the current session using up/down arrows. false will allow the history to be shared across all sessions.
    }
    completions: {
        case_sensitive: false # set to true to enable case-sensitive completions
        quick: true # set this to false to prevent auto-selecting completions when only one remains
        partial: true # set this to false to prevent partial filling of the prompt
        algorithm: "fuzzy" # prefix or fuzzy
        sort: "smart" # "smart" (alphabetical for prefix matching, fuzzy score for fuzzy matching) or "alphabetical",
        external: {enable: true, max_results: 100}
        use_ls_colors: true # set this to true to enable file/path/directory completions using LS_COLORS
    }
    cursor_shape: {emacs: line, vi_insert: block, vi_normal: underscore}
    footer_mode: 25 # always, never, number_of_rows, auto
    float_precision: 2 # the precision for displaying floats in tables
    buffer_editor: zed
    use_ansi_coloring: true
    bracketed_paste: true # enable bracketed paste, currently useless on windows
    edit_mode: emacs # emacs, vi
    shell_integration: {
        # osc2 abbreviates the path if in the home_dir, sets the tab/window title, shows the running command in the tab/window title
        osc2: true
        # osc7 is a way to communicate the path to the terminal, this is helpful for spawning new tabs in the same directory
        osc7: true
        # osc8 is also implemented as the deprecated setting ls.show_clickable_links, it shows clickable links in ls output if your terminal supports it. show_clickable_links is deprecated in favor of osc8
        osc8: true
        # osc9_9 is from ConEmu and is starting to get wider support. It's similar to osc7 in that it communicates the path to the terminal
        osc9_9: false
        # osc133 is several escapes invented by Final Term which include the supported ones below.
        # 133;A - Mark prompt start
        # 133;B - Mark prompt end
        # 133;C - Mark pre-execution
        # 133;D;exit - Mark execution finished with exit code
        # This is used to enable terminals to know where the prompt is, the command is, where the command finishes, and where the output of the command is
        osc133: true
        # osc633 is closely related to osc133 but only exists in visual studio code (vscode) and supports their shell integration features
        # 633;A - Mark prompt start
        # 633;B - Mark prompt end
        # 633;C - Mark pre-execution
        # 633;D;exit - Mark execution finished with exit code
        # 633;E - Explicitly set the command line with an optional nonce
        # 633;P;Cwd=<path> - Mark the current working directory and communicate it to the terminal
        # and also helps with the run recent menu in vscode
        osc633: true
        # reset_application_mode is escape \x1b[?1l and was added to help ssh work better
        reset_application_mode: true
    }
    highlight_resolved_externals: true # true enables highlighting of external commands in the repl resolved by which.
    plugins: {} # Per-plugin configuration. See https://www.nushell.sh/contributor-book/plugins.html#configuration.
    plugin_gc: {

        # Configuration for plugin garbage collection
        default: {
            enabled: true # true to enable stopping of inactive plugins
            stop_after: 10sec # how long to wait after a plugin is inactive to stop it
        }
        plugins: {}
    }
    # Per-directory `project` overlay: when the current folder has a `mod.nu`,
    # load it as the `project` overlay (and reload it when the file changes).
    # These hooks are LOAD-ONLY on purpose. An overlay applied from inside a
    # hook is invisible to Nushell's parser, so `overlay hide project` errors
    # with `active_overlay_not_found` (an uncatchable parse error) — there is no
    # way to auto-unload it. It therefore persists across subfolders. To drop a
    # stale overlay, use the `unproject` command below.
    hooks: {
        pre_prompt: [
            {
                condition: {|| ("mod.nu" | path exists) }
                code: "
                        overlay use --reload mod.nu as project
                    "
            }
        ]
        pre_execution: [
            {
                condition: {|| ("mod.nu" | path exists) }
                code: "
                        overlay use --reload mod.nu as project
                    "
            }
        ]
        display_output: "if (term size).columns >= 100 { table -e } else { table -e -w 999 }"
        command_not_found: { null }
    }
}

use ~/.cache/starship/init.nu

source ~/.zoxide.nu

mkdir ($nu.data-dir | path join "vendor/autoload")
^mise activate nu | save -f ($nu.data-dir | path join "vendor/autoload/mise.nu")
source ($nu.cache-dir | path join "carapace.nu")

alias oc = opencode
alias oca = opencode attach http://localhost:9923 --dir .

export def "from env" []: string -> record {
    lines
    | split column '#'
    | get column1
    | where {($in | str length) > 0}
    | parse "{key}={value}"
    | update value {str trim -c '"'}
    | transpose -r -d
}

$env.config.menus ++= [
    {
        name: vars_menu
        only_buffer_difference: true
        marker: "󰊕 "
        type: {layout: list, page_size: 10, columns: 4}
        style: {text: green, selected_text: green_reverse, description_text: yellow}
        source: {|buffer, position|
            let recent = (
                history
                | get command
                | reverse
                | first 50
                | each {|line| $line | str trim | str replace --all --regex '\s+' ' '}
            )
            scope commands
            | where type == "custom"
            | where name =~ $buffer
            | sort-by decl_id --reverse
            | sort-by {|row|
                let hits = (
                    $recent
                    | enumerate
                    | where {|e| $e.item == $row.name or ($e.item | str starts-with $"($row.name) ")}
                )
                if ($hits | is-empty) { 999999 } else { $hits | first | get index }
            }
            | each {|row| {value: $row.name, extra: [$row.description $row.search_terms]}}
        }
    }
]

$env.config.keybindings ++= [
    {
        name: vars_menu
        modifier: control
        keycode: char_d
        mode: [vi_insert vi_normal emacs]
        event: {
            until: [
                {send: menu, name: vars_menu}
                {send: menupagenext}
            ]
        }
    }
]

$env.config.keybindings ++= [
    {
        name: menu_next
        modifier: control
        keycode: char_n
        mode: [vi_insert vi_normal emacs]
        event: {
            until: [
                {send: menunext}
                {send: down}
            ]
        }
    }
    {
        name: menu_previous
        modifier: control
        keycode: char_p
        mode: [vi_insert vi_normal emacs]
        event: {
            until: [
                {send: menuprevious}
                {send: up}
            ]
        }
    }
]

# def pick-command [] {
#     let recent = (
#         history
#         | get command
#         | reverse
#         | first 50
#         | each {|line| $line | str trim | str replace --all --regex '\s+' ' '}
#     )

#     let cmds = (
#         scope commands
#         | where type == "custom"
#         | sort-by decl_id --reverse
#         | sort-by {|row|
#             let hits = (
#                 $recent
#                 | enumerate
#                 | where {|e| $e.item == $row.name or ($e.item | str starts-with $"($row.name) ")}
#             )
#             if ($hits | is-empty) { 999999 } else { $hits | first | get index }
#         }
#     )

#     if ($cmds | is-empty) { return "" }

#     let w = (
#         $cmds
#         | get name
#         | each {|n| $n | str length}
#         | math max
#     )

#     let dir = (mktemp --directory)
#     let lines = (
#         $cmds
#         | enumerate
#         | each {|e|
#             let src = try { view source $e.item.name } catch {|err| $"# source unavailable\n# ($err.msg)" }
#             $"# ($e.item.name) — ($e.item.description)\n\n($src)"
#             | nu-highlight
#             | save --force --raw ($dir | path join $"($e.index).nu")
#             let display = $"($e.item.name | fill --alignment left --width $w)  ($e.item.description)"
#             [$e.index $e.item.name $display] | str join (char tab)
#         }
#         | str join (char nl)
#     )

#     let preview = $"cat ($dir)/{1}.nu"

#     let fzf_args = [
#         "--delimiter"
#         (char tab)
#         "--with-nth" "3"
#         "--preview" $preview
#         "--preview-window" "right,60%,wrap,border-left"
#         "--height" "90%"
#         "--layout" "reverse"
#         "--prompt" "cmd ❯ "
#         "--ansi" # render the ANSI colors nu-highlight emitted
#         "--no-multi"
#     ]

#     let picked = $lines | fzf ...$fzf_args | complete
#     rm --recursive --force $dir

#     if $picked.exit_code != 0 { return "" }
#     $picked.stdout | str trim | split row (char tab) | get 1
# }

# $env.config.keybindings ++= [
#     {
#         name: cmd_menu_fzf
#         modifier: control
#         keycode: char_d
#         mode: [emacs vi_normal vi_insert]
#         event: {send: executehostcommand, cmd: "commandline edit --insert (pick-command)"}
#     }
# ]

def dockerj-completer [spans: list<string>] {

    # spans = [dockerj run --r ...]; make carapace think it's docker
    do $env.config.completions.external.completer ($spans | update 0 docker)
}

@complete dockerj-completer
def --wrapped dockerj [...args] {
    docker ...$args --format=json | from json --objects
}

def lsg [] {
    print ""
    ls | sort-by type name -i | grid name -c -i -w 60
}

alias l = lsg
alias lg = lazygit

# Drop the per-directory `project` overlay. Hook-loaded overlays can't be hidden
# (`overlay hide` is a parser keyword that never sees them), so the only reliable
# way to clear one is to re-exec the shell. This keeps your cwd and reloads only
# the current directory's overlay — so `cd` out of the project first, then run it.
def unproject [] { exec nu }

def make-template [name: string] {
    let dest = $nu.home-dir | path join interviews $name
    cp -r ($nu.home-dir | path join interviews template) $dest
}

alias icli = instant-cli
