; number_conversion.asm
; Funkcja konwertuj¹ca liczbê dziesiêtn¹ na dowolny system liczbowy (2-16)
; Kompatybilna z Visual C++ (32-bit)

.386P
.model flat
public _convert_to_base
.code

; Funkcja konwersji liczby na dowolny system liczbowy
; Argumenty: 
;   [ebp+8]  = liczba do konwersji (unsigned int)
;   [ebp+12] = podstawa systemu (2-16)
;   [ebp+16] = wskaŸnik do bufora wynikowego (char*)
; Zwraca: d³ugoœæ wyniku (int)
_convert_to_base proc near
    push ebp
    mov ebp, esp
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi

    mov eax, [ebp+8]        ; liczba do konwersji
    mov ebx, [ebp+12]       ; podstawa systemu
    mov edi, [ebp+16]       ; wskaŸnik do bufora wynikowego
    
    ; SprawdŸ poprawnoœæ podstawy (2-16)
    cmp ebx, 2
    jb invalid_base
    cmp ebx, 16
    ja invalid_base
    
    ; SprawdŸ czy liczba to 0
    cmp eax, 0
    jne convert_loop_start
    
    ; Jeœli liczba to 0, zwróæ "0"
    mov byte ptr [edi], '0'
    mov byte ptr [edi+1], 0     ; null terminator
    mov eax, 1                  ; d³ugoœæ = 1
    jmp conversion_end
    
convert_loop_start:
    mov ecx, 0                  ; licznik cyfr na stosie
    
convert_loop:
    cmp eax, 0                  ; sprawdŸ czy liczba = 0
    je reverse_digits
    
    mov edx, 0                  ; wyzeruj starsz¹ czêœæ dzielnej
    div ebx                     ; dziel przez podstawê: eax = iloraz, edx = reszta
    
    ; Konwertuj resztê na znak
    cmp edx, 9
    jle digit_0_9
    
    ; Cyfry A-F (10-15)
    add edx, 'A' - 10
    jmp push_digit
    
digit_0_9:
    ; Cyfry 0-9
    add edx, '0'
    
push_digit:
    push edx                    ; zapisz cyfrê na stosie
    inc ecx                     ; zwiêksz licznik cyfr
    jmp convert_loop
    
reverse_digits:
    ; Pobierz cyfry ze stosu w odwrotnej kolejnoœci
    mov esi, 0                  ; indeks w buforze wynikowym
    
pop_loop:
    cmp ecx, 0
    je add_null_terminator
    
    pop edx                     ; pobierz cyfrê ze stosu
    mov [edi+esi], dl          ; zapisz do bufora
    inc esi                     ; nastêpna pozycja
    dec ecx                     ; zmniejsz licznik
    jmp pop_loop
    
add_null_terminator:
    mov byte ptr [edi+esi], 0   ; dodaj null terminator
    mov eax, esi                ; zwróæ d³ugoœæ wyniku
    jmp conversion_end
    
invalid_base:
    ; Dla niepoprawnej podstawy zwróæ pusty string
    mov byte ptr [edi], 0
    mov eax, 0
    
conversion_end:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop ebp
    ret

_convert_to_base endp

end