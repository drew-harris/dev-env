; Mark every `def` (and `export def`) declaration as runnable. Arguments
; are collected interactively by the runner script — see run.nu.
; @run positions the gutter button (still on the `def` line — the gutter is
; per-row). @_full on the outer decl_def extends `full_range`/`context_range`
; so the runnable is detected when the cursor is anywhere inside the function
; body. @name is exposed to tasks as $ZED_CUSTOM_name.
((decl_def
   [(cmd_identifier) (val_string)] @run @name) @_full
  (#set! tag nu-run))
