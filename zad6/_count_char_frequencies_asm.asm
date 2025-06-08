title Character Frequency Counter Subroutine (_count_char_frequencies_asm.asm)

; This subroutine links to Visual C++.
; Counts the frequency of each letter (a-z, case-insensitive) in a given string.
; Assumes the input string contains only letters.
; Arguments:
;   [ebp+8]  = pointer to the null-terminated string (containing only letters)
;   [ebp+12] = pointer to an array of 26 integers (frequencies for 'a' through 'z'),
;              assumed to be initialized to zero by the caller.
; Returns: nothing (modifies the frequencies array in-place)

.386P
.model flat
public _count_char_frequencies_asm

.code
_count_char_frequencies_asm proc near
    push   ebp
    mov    ebp, esp
    push   eax          ; Zachowaj rejestry
    push   ebx
    push   ecx
    push   edx
    push   esi
    push   edi

    mov    esi, [ebp+8]  ; esi = wskaźnik do łańcucha znaków (str)
    mov    edi, [ebp+12] ; edi = wskaźnik do tablicy liczników (frequencies)
                          ; Tablica frequencies jest już wyzerowana przez C++

char_loop:
    mov    al, [esi]     ; Pobierz znak z łańcucha
    cmp    al, 0         ; Sprawdź, czy to terminator null (koniec łańcucha)
    je     end_loop      ; Jeśli tak, zakończ pętlę

    ; Konwertuj znak na małą literę, jeśli jest wielką literą
    ; Zakładamy, że string zawiera tylko litery (A-Z, a-z) zgodnie z filtrowaniem w C++
    cmp    al, 'A'
    jl     is_lowercase_or_not_letter ; Jeśli mniejszy od 'A', to już mała litera lub nie litera
    cmp    al, 'Z'
    jg     is_lowercase_or_not_letter ; Jeśli większy od 'Z', to już mała litera lub nie litera
    add    al, 32        ; Konwertuj wielką literę na małą (np. 'A' + 32 = 'a')

is_lowercase_or_not_letter:
    ; W tym miejscu AL powinien zawierać małą literę, jeśli oryginalny znak był literą.
    ; Sprawdź, czy znak jest w zakresie 'a'-'z'
    cmp    al, 'a'
    jl     next_char     ; Jeśli mniejszy od 'a', zignoruj (nie powinno się zdarzyć, jeśli C++ filtruje poprawnie)
    cmp    al, 'z'
    jg     next_char     ; Jeśli większy od 'z', zignoruj (nie powinno się zdarzyć)

    ; Oblicz indeks dla tablicy frequencies: index = al - 'a'
    movzx  ebx, al       ; Rozszerz al do ebx (ebx = wartość ASCII znaku)
    sub    bl, 'a'       ; ebx = indeks (0 dla 'a', 1 dla 'b', ..., 25 dla 'z')
                         ; Używamy bl, ponieważ indeksy są małe (0-25)

    ; Inkrementuj licznik dla danego znaku: frequencies[index]++
    ; Adres elementu = edi (bazowy adres tablicy) + ebx (indeks) * 4 (rozmiar int w bajtach)
    inc    dword ptr [edi + ebx*4]

next_char:
    inc    esi           ; Przejdź do następnego znaku w łańcuchu
    jmp    char_loop     ; Kontynuuj pętlę

end_loop:
    pop    edi           ; Przywróć rejestry
    pop    esi
    pop    edx
    pop    ecx
    pop    ebx
    pop    eax
    pop    ebp
    ret                   
_count_char_frequencies_asm endp
end
