# Loaded before config.nu. The live env.nu has the same initialization;
# Nushell's generated compatibility comments are omitted here.
$env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense' # optional
mkdir $"($nu.cache-dir)"
^carapace _carapace nushell | save --force ($nu.cache-dir | path join 'carapace.nu')
