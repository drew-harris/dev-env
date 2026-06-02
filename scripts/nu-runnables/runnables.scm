; Mark every `def` (and `export def`) declaration as runnable. Arguments
; are collected interactively by the runner script — see run.nu.
; @run positions the gutter button; @name is exposed to tasks as $ZED_CUSTOM_name.
((decl_def
   (cmd_identifier) @run @name)
  (#set! tag nu-run))
