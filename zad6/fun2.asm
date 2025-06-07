title String Length Calculator Subroutine (fun2.asm)

; This subroutine links to Visual C++.
; Calculates the length of a null-terminated string.
; Argument: [ebp+8] = pointer to the string
; Returns: length of the string in EAX

.386P
.model flat
public _fun2

MAX_STRING_SCAN_LENGTH equ 0FFFFh ; Maksymalna liczba znaków do przeskanowania (dla bezpieczeństwa)

.code
_fun2 proc near   ; Oblicza długość łańcucha znaków
    push ebp
    mov ebp, esp
    push ecx
    push edx
    push edi
    push esi

    mov esi, [ebp+8]	; pierwszy argument funkcji - wskaźnik do łańcucha
    mov ecx, MAX_STRING_SCAN_LENGTH ; maksymalna długość do sprawdzenia (zabezpieczenie przed brakiem terminatora null)
	mov edi, 0			; licznik długości łańcucha (wynik)
ptl_count_length:
	mov dl, [esi]		; pobierz znak
	cmp dl, 0h			; sprawdź, czy to terminator null
	je length_counted	; jeśli tak, zakończ liczenie
	inc esi				; przesuń wskaźnik na następny znak
	inc edi				; zwiększ licznik długości
	loop ptl_count_length	; kontynuuj pętlę (dekrementuje ecx i skacze, jeśli ecx != 0)

length_counted:
	mov eax, edi		; umieść wynik (długość) w eax

    pop esi
    pop edi
    pop edx
    pop ecx
    pop ebp
    ret                   
_fun2 endp
end

