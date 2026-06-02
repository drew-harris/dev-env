; Mark zero-argument `def` (and `export def`) declarations as runnable.
; @run positions the gutter button (still on the `def` line — the gutter is
; per-row). @_full on the outer decl_def extends `full_range`/`context_range`
; so the runnable is detected when the cursor is anywhere inside the function
; body. @name is exposed to tasks as $ZED_CUSTOM_name.
((decl_def
   (cmd_identifier) @run @name
   (parameter_bracks) @_params) @_full
  (#match? @_params "^\\[\\s*\\]$")
  (#set! tag nu-run))
