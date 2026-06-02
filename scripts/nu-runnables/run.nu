#!/usr/bin/env nu
# Invoked by the Zed nu-run task. Loads <file>, then runs <command>.
# If <command> takes parameters, prompts for them (as nushell source code)
# before running. Module files (any line starting with `export`) are loaded
# via `use` with the module's stem as prefix; everything else uses `source`.
#
# Usage: run.nu <file> <command>

def main [file: path, command: string] {
    let target = ($file | path expand)
    if not ($target | path exists) {
        error make { msg: $"File not found: ($target)" }
    }

    # `decl_def` quoted-name forms like `export def 'swarm list-services'` arrive
    # here with their surrounding quotes intact (the tree-sitter capture spans the
    # whole `val_string` node). Strip them so the name matches how nu stores it
    # in `scope commands` and how it must be invoked at the call site.
    let bare = (
        $command
        | str replace -r "^['\"](.*)['\"]$" '$1'
    )

    let is_module = (
        open --raw $target
        | lines
        | any {|l| ($l | str trim) | str starts-with "export " }
    )
    let loader = if $is_module {
        $"use ($target | to nuon)"
    } else {
        $"source ($target | to nuon)"
    }
    let resolved = if $is_module {
        let prefix = $"($target | path parse | get stem) "
        if ($bare | str starts-with $prefix) { $bare } else { $"($prefix)($bare)" }
    } else {
        $bare
    }

    let probe = $"($loader); scope commands | where name == ($resolved | to nuon) | first | get signatures.any | where parameter_type not-in [input output] | is-not-empty | into string"
    let has_args = ((^nu -n -c $probe | str trim) == "true")

    let args = if $has_args {
        input $"args for ($resolved) \(nushell source\): "
    } else {
        ""
    }

    let call = if (($args | str trim) | is-empty) {
        $resolved
    } else {
        $"($resolved) ($args)"
    }
    ^nu -n -c $"($loader); ($call)"
}
