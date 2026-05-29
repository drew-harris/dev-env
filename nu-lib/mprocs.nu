export def --wrapped proc [...args] {
    ^mprocs --server 127.0.0.1:4050 ...$args
}

export def 'proc send-cmd' [msg] {
    ^mprocs --server 127.0.0.1:4050 --ctl ($msg | to json)
}

export def "proc shutdown" [] {
    proc send-cmd {c: quit}
}

export def "proc add-proc" [name: string, ...cmd: string] {
    proc send-cmd {
        c: add-proc
        name: $name
        cmd: $"nu -il -c \"overlay use mod.nu; ($cmd | str join ' ')\""
    }
}

export def "proc reload" [] {
    proc send-cmd {c: restart-all}
}
