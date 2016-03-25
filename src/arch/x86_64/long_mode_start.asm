global long_mode_start

section .text
bits 64
long_mode_start:
extern rust_main
  call rust_main

  ; Should never get here,
  ; but halt if we do
  hlt
