; Mark zero-argument `def` (and `export def`) declarations as runnable.
; @run positions the gutter button; @name is exposed to tasks as $ZED_CUSTOM_name.
((decl_def
   (cmd_identifier) @run @name
   (parameter_bracks) @_params)
  (#match? @_params "^\\[\\s*\\]$")
  (#set! tag nu-run))
