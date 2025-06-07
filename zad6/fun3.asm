title The fun Subroutine    (fun3.asm)

; This subroutine links to Visual C++ 6.0.

.386P
.model flat
public _fun3

.code
_fun3 proc near   ;**********************
    push ebp
    mov ebp, esp

    mov eax, [ebp+8]	; pierwszy argument funkcji
	add eax, 10

    pop ebp
    ret                   
_fun3 endp
end

