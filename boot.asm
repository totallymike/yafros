EXTERN error
EXTERN check_cpuid
EXTERN check_long_mode
GLOBAL start

SECTION .text
BITS 32
start:
  mov esp, stack_top
  call check_multiboot
  call check_cpuid
  call check_long_mode

  call disable_paging
  XCHG BX, BX
  call set_up_page_tables
  call enable_paging
  hlt

  mov word [0xb8000], 0x0248    ; H
  mov word [0xb8002], 0x0265    ; e
  mov word [0xb8004], 0x026c    ; l
  mov word [0xb8006], 0x026c    ; l
  mov word [0xb8008], 0x026f    ; o
  mov word [0xb800a], 0x022c    ; ,
  mov word [0xb800c], 0x0220    ;
  mov word [0xb800e], 0x0277    ; w
  mov word [0xb8010], 0x026f    ; o
  mov word [0xb8012], 0x0272    ; r
  mov word [0xb8014], 0x026c    ; l
  mov word [0xb8016], 0x0264    ; d
  mov word [0xb8018], 0x0221    ; !
  hlt

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
  ; Map first P4 entry to P3 table
  mov eax, p3_table
  or eax, 0b11                  ; Present + writeable
  mov [p4_table], eax

  ; Map first P3 entry to P2 table
  mov eax, p2_table
  or eax, 0b11                  ; present + writable
  mov [p3_table], eax

  mov ecx, 0
.map_p2_table:
  ; map ecx-th P2 entry to a huge page that starts at
  ; 2MiB*ecx
  mov eax, 0x200000             ; 2MiB
  mul ecx                       ; Start address of ecx-th page
  or eax, 0x10000011            ; present, writable, and HUGE
  mov [p2_table + ecx * 8], eax ; Map ecx-th entry

  inc ecx                       ; Increase counter
  cmp ecx, 512                  ; If counter == 512, finished
  jne .map_p2_table

  ret

enable_paging:
  ; Load P4 to cr3 register (cpu uses this to access the P4 table)
  mov eax, p4_table
  mov cr3, eax

  ; Enable PAE flag in CR4 (Physical address extension)
  mov eax, cr4
  or eax, 1 << 5
  mov cr4, eax

  ; Set the long-mode bit in the EFER MSR (model specific register)
  mov ecx, 0xC0000080
  rdmsr
  or eax, 1 << 8
  wrmsr

  ; Enable paging in the CR0 register
  mov eax, cr0
  or eax, 1 << 31
  XCHG BX, BX
  mov cr0, eax

  ret

SECTION .bss
ALIGN 4096
p4_table:
  resb 4096
p3_table:
  resb 4096
p2_table:
  resb 4096
stack_bottom:
  resb 64
stack_top:
