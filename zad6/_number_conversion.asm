; number_conversion.asm
; Funkcja konwertuj�ca liczb� dziesi�tn� na dowolny system liczbowy (2-16)
; Kompatybilna z Visual C++ (32-bit)

.386P
.model flat
public _convert_to_base
.code

; Funkcja konwersji liczby na dowolny system liczbowy
; Argumenty: 
;   [ebp+8]  = liczba do konwersji (unsigned int)
;   [ebp+12] = podstawa systemu (2-16)
;   [ebp+16] = wska�nik do bufora wynikowego (char*)
; Zwraca: d�ugo�� wyniku (int)
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
    mov edi, [ebp+16]       ; wska�nik do bufora wynikowego
    
    ; Sprawd� poprawno�� podstawy (2-16)
    cmp ebx, 2
    jb invalid_base
    cmp ebx, 16
    ja invalid_base
    
    ; Sprawd� czy liczba to 0
    cmp eax, 0
    jne convert_loop_start
    
    ; Je�li liczba to 0, zwr�� "0"
    mov byte ptr [edi], '0'
    mov byte ptr [edi+1], 0     ; null terminator
    mov eax, 1                  ; d�ugo�� = 1
    jmp conversion_end
    
convert_loop_start:
    mov ecx, 0                  ; licznik cyfr na stosie
    
convert_loop:
    cmp eax, 0                  ; sprawd� czy liczba = 0
    je reverse_digits
    
    mov edx, 0                  ; wyzeruj starsz� cz�� dzielnej
    div ebx                     ; dziel przez podstaw�: eax = iloraz, edx = reszta
    
    ; Konwertuj reszt� na znak
    cmp edx, 9
    jle digit_0_9
    
    ; Cyfry A-F (10-15)
    add edx, 'A' - 10
    jmp push_digit
    
digit_0_9:
    ; Cyfry 0-9
    add edx, '0'
    
push_digit:
    push edx                    ; zapisz cyfr� na stosie
    inc ecx                     ; zwi�ksz licznik cyfr
    jmp convert_loop
    
reverse_digits:
    ; Pobierz cyfry ze stosu w odwrotnej kolejno�ci
    mov esi, 0                  ; indeks w buforze wynikowym
    
pop_loop:
    cmp ecx, 0
    je add_null_terminator
    
    pop edx                     ; pobierz cyfr� ze stosu
    mov [edi+esi], dl          ; zapisz do bufora
    inc esi                     ; nast�pna pozycja
    dec ecx                     ; zmniejsz licznik
    jmp pop_loop
    
add_null_terminator:
    mov byte ptr [edi+esi], 0   ; dodaj null terminator
    mov eax, esi                ; zwr�� d�ugo�� wyniku
    jmp conversion_end
    
invalid_base:
    ; Dla niepoprawnej podstawy zwr�� pusty string
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