; number_conversion.asm
; Funkcja konwertująca liczbę dziesiętną na dowolny system liczbowy (2-16)
; Kompatybilna z Visual C++ (32-bit)

.386P
.model flat
public _convert_to_base
.code

; Funkcja konwersji liczby na dowolny system liczbowy
; Argumenty: 
;   [ebp+8]  = liczba do konwersji (unsigned int)
;   [ebp+12] = podstawa systemu (2-16)
;   [ebp+16] = wskaźnik do bufora wynikowego (char*)
; Zwraca: długość wyniku (int)
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
    mov edi, [ebp+16]       ; wskaźnik do bufora wynikowego
    
    ; Sprawdź poprawność podstawy (2-16)
    cmp ebx, 2
    jb invalid_base
    cmp ebx, 16
    ja invalid_base
    
    ; Sprawdź czy liczba to 0
    cmp eax, 0
    jne convert_loop_start
    
    ; Jeśli liczba to 0, zwróć "0"
    mov byte ptr [edi], '0'
    mov byte ptr [edi+1], 0     ; null terminator
    mov eax, 1                  ; długość = 1
    jmp conversion_end
    
convert_loop_start:
    mov ecx, 0                  ; licznik cyfr na stosie
    
convert_loop:
    cmp eax, 0                  ; sprawdź czy liczba = 0
    je reverse_digits
    
    mov edx, 0                  ; wyzeruj starszą część dzielnej
    div ebx                     ; dziel przez podstawę: eax = iloraz, edx = reszta
    
    ; Konwertuj resztę na znak
    cmp edx, 9
    jle digit_0_9
    
    ; Cyfry A-F (10-15)
    add edx, 'A' - 10
    jmp push_digit
    
digit_0_9:
    ; Cyfry 0-9
    add edx, '0'
    
push_digit:
    push edx                    ; zapisz cyfrę na stosie
    inc ecx                     ; zwiększ licznik cyfr
    jmp convert_loop
    
reverse_digits:
    ; Pobierz cyfry ze stosu w odwrotnej kolejności
    mov esi, 0                  ; indeks w buforze wynikowym
    
pop_loop:
    cmp ecx, 0
    je add_null_terminator
    
    pop edx                     ; pobierz cyfrę ze stosu
    mov [edi+esi], dl          ; zapisz do bufora
    inc esi                     ; następna pozycja
    dec ecx                     ; zmniejsz licznik
    jmp pop_loop
    
add_null_terminator:
    mov byte ptr [edi+esi], 0   ; dodaj null terminator
    mov eax, esi                ; zwróć długość wyniku
    jmp conversion_end
    
invalid_base:
    ; Dla niepoprawnej podstawy zwróć pusty string
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