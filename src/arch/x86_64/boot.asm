EXTERN error
EXTERN check_cpuid
EXTERN check_long_mode
EXTERN long_mode_start

GLOBAL start

SECTION .text
BITS 32
start:
  mov esp, stack_top
  mov edi, ebx                  ; Move multiboot info pointer to edi
  call check_multiboot
  call check_cpuid
  call check_long_mode

  call disable_paging
  call set_up_page_tables
  call enable_paging
  call set_up_SSE

  lgdt [gdt64.pointer]

  ; Update selectors
  mov ax, gdt64.data
  mov ss, ax                    ; Stack selector
  mov ds, ax                    ; Data selector
  mov es, ax                    ; Extra selector

  ; Magic debug instruction
  ; gets bochs to pause here, otherwise does nothing
  XCHG BX, BX

  jmp gdt64.code:long_mode_start

check_multiboot:
  cmp eax, 0x36d76289
  jne .no_multiboot
  ret

.no_multiboot:
  mov al, "0"
  jmp error

disable_paging:
  mov eax, cr0
  and eax, 01111111111111111111111111111111b
  mov cr0, eax
  ret

set_up_page_tables:
  ; map the first P4 entry to P3 table
  mov eax, p3_table
  or eax, 0b11                  ; Present + writable
  mov [p4_table], eax

  ; Map first P3 entry to P2 table
  mov eax, p2_table
  or eax, 0b11                  ; Present + writable
  mov [p3_table], eax

  mov ecx, 0                    ; Counter variable

.map_p2_table:
  ; Map ecx-th P2 entry to a huge page that starts at 2MiB*ecx
  mov eax, 0x200000             ; 2MiB
  mul ecx
  or eax, 0b10000011            ; Present, writable, huge
  mov [p2_table + ecx * 8], eax ; Map ecx-th entry

  inc ecx
  cmp ecx, 512
  jne .map_p2_table

  ret

enable_paging:
  ; Load P4 to CR3 register (CPU uses this to access the P4 table)
  mov eax, p4_table
  mov cr3, eax

  ; Enable PAE-flag in CR4
  mov eax, cr4
  or eax, 1 << 5
  mov cr4, eax

  ; Set the long-mode bit in the EFER MSR
  mov ecx, 0xC0000080
  rdmsr
  or eax, 1 << 8
  wrmsr

  ; Enable paging in the CR0 register
  mov eax, cr0
  or eax, 1 << 31
  mov cr0, eax

  ret

set_up_SSE:
  ; check for SSE
  mov eax, 0x1
  cpuid
  test edx, 1<<25
  jz .no_SSE

  ; enable SSE
  mov eax, cr0
  and ax, 0xFFFB
  or ax, 0x2
  mov cr0, eax
  mov eax, cr4
  or ax, 3 << 9
  mov cr4, eax

  ret
.no_SSE:
  mov al, "a"
  jmp error

SECTION .bss
align 4096
p4_table:
  resb 4096
p3_table:
  resb 4096
p2_table:
  resb 4096
stack_bottom:
  resb 4096
stack_top:

SECTION .rodata
gdt64:
  dq 0                                     ; zero entry
.code: equ $ - gdt64
  dw 0
  dw 0
  db 0
  db 10011010b
  db 00100000b
  db 0
.data: equ $ - gdt64
  dw 0
  dw 0
  db 0
  db 10010010b
  db 00000000b
  db 0
.pointer:
  dw $ - gdt64 - 1
  dq gdt64
