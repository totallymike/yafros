  SECTION .text
  BITS 32
  EXTERN error
  GLOBAL check_cpuid
  GLOBAL check_long_mode

check_cpuid:
  ;; Try to flip ID bit 21 in FLAGS
  ;; if it works, we have CPUID

  ;; Copy flags to EAX via stack
  pushfd
  pop eax

  ;; Stash FLAGS to ecx to compare later
  mov ecx, eax

  xor eax, 1 << 21

  push eax
  popfd

  pushfd
  pop eax

  push ecx
  popfd

  cmp eax, ecx
  je .no_cpuid
  ret
.no_cpuid:
  mov al, "1"
  jmp error

check_long_mode:
  mov eax, 0x80000000
  cpuid
  cmp eax, 0x80000001
  jb .no_long_mode

  mov eax, 0x80000001
  cpuid
  test edx, 1 << 29
  jz .no_long_mode
  ret
.no_long_mode:
  mov al, "2"
  jmp error

;; long_mode:
;;   mov eax, cr0
;;   and eax, 01111111111111111111111111111111b
;;   mov cr0, eax
;;   mov edi, 0x1000
;;   mov cr3, edi
;;   xor eax, eax
;;   mov ecx, 4096
;;   rep stosd
;;   mov edi, cr3
;;   mov DWORD [edi], 0x2003
;;   add edi, 0x1000
;;   mov DWORD [edi], 0x3003
;;   add edi, 0x1000
;;   mov DWORD [edi], 0x4003
;;   add edi, 0x1000

;;   mov ebx, 0x00000003
;;   mov ecx, 512

;; .SetEntry:
;;   mov DWORD [edi], ebx
;;   add ebx, 0x1000
;;   add edi, 8
;;   loop .SetEntry

;;   mov eax, cr4
;;   or eax, 1 << 5
;;   mov crx, eax

;;   mov ecx, 0xC0000080
;;   rdmsr
;;   or eax, 1 << 8
;;   wrmsr

;;   mov eax, cr0
;;   or eax, 1 << 31
;;   mov cr0, eax
