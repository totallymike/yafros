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
  call set_up_page_tables
  XCHG BX, BX

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
  mov edi, 0x1000               ; Set destination index to 0x1000
  mov cr3, edi
  xor eax, eax
  mov ecx, 4096
  rep stosd
  mov edi, cr3

  mov DWORD [edi], 0x2003
  add edi, 0x1000
  mov DWORD [edi], 0x3003
  add edi, 0x1000
  mov DWORD [edi], 0x4003
  add edi, 0x1000

  mov ebx, 0x00000003
  mov ecx, 512

.SetEntry:
  mov DWORD [edi], ebx
  add ebx, 0x1000
  add edi, 8
  loop .SetEntry

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
  mov cr0, eax

  ret

SECTION .bss
stack_bottom:
  resb 64
stack_top:
