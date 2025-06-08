title Bubble Sort Subroutine (bubble_sort.asm)
; This subroutine links to Visual C++.
; Sorts an array of characters using bubble sort algorithm.
; Arguments: 
;   [ebp+8] = pointer to character array
;   [ebp+12] = length of the array
; Returns: nothing (sorts in-place)

.386P
.model flat
public _bubble_sort

.code

; Funkcja sortowania b¹belkowego
; Argumenty: [ebp+8] = wskaŸnik do tablicy, [ebp+12] = d³ugoœæ tablicy
_bubble_sort proc near
    push ebp
    mov ebp, esp
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    
    mov esi, [ebp+8]    ; wskaŸnik do tablicy
    mov ecx, [ebp+12]   ; d³ugoœæ tablicy
    
    cmp ecx, 2          ; jeœli d³ugoœæ < 2, nie ma co sortowaæ
    jb sort_end
    
    mov edi, ecx        ; edi = liczba przebiegów zewnêtrznych
    dec edi             ; n-1 przebiegów
    
outer_loop:
    cmp edi, 0
    jle sort_end
    
    mov ebx, 0          ; indeks dla pêtli wewnêtrznej
    mov edx, ecx        ; liczba porównañ w tym przebiegu
    sub edx, edi        ; edx = ecx - edi
    dec edx             ; pomniejsz o 1
    
inner_loop:
    cmp ebx, edx
    jge next_outer
    
    ; Porównaj elementy [esi+ebx] i [esi+ebx+1]
    mov al, [esi+ebx]
    mov ah, [esi+ebx+1]
    
    ; Konwertuj kopie na wielkie litery do porównania
    push eax            ; zachowaj oryginalne wartoœci
    call to_upper_al
    call to_upper_ah
    
    cmp al, ah
    pop eax             ; przywróæ oryginalne wartoœci
    jle no_swap         ; jeœli al <= ah, nie zamieniaj
    
    ; Zamieñ oryginalne elementy
    mov [esi+ebx], ah
    mov [esi+ebx+1], al
    
no_swap:
    inc ebx
    jmp inner_loop
    
next_outer:
    dec edi
    jmp outer_loop
    
sort_end:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop ebp
    ret

; Pomocnicza funkcja do konwersji znaku w AL na wielk¹ literê
to_upper_al:
    cmp al, 'a'
    jb al_done
    cmp al, 'z'
    ja al_done
    sub al, 32          ; konwertuj a-z na A-Z
al_done:
    ret

; Pomocnicza funkcja do konwersji znaku w AH na wielk¹ literê  
to_upper_ah:
    cmp ah, 'a'
    jb ah_done
    cmp ah, 'z'
    ja ah_done
    sub ah, 32          ; konwertuj a-z na A-Z
ah_done:
    ret

_bubble_sort endp

end