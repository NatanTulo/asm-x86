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

; Funkcja sortowania b�belkowego
; Argumenty: [ebp+8] = wska�nik do tablicy, [ebp+12] = d�ugo�� tablicy
_bubble_sort proc near
    push ebp
    mov ebp, esp
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    
    mov esi, [ebp+8]    ; wska�nik do tablicy
    mov ecx, [ebp+12]   ; d�ugo�� tablicy
    
    cmp ecx, 2          ; je�li d�ugo�� < 2, nie ma co sortowa�
    jb sort_end
    
    mov edi, ecx        ; edi = liczba przebieg�w zewn�trznych
    dec edi             ; n-1 przebieg�w
    
outer_loop:
    cmp edi, 0
    jle sort_end
    
    mov ebx, 0          ; indeks dla p�tli wewn�trznej
    mov edx, ecx        ; liczba por�wna� w tym przebiegu
    sub edx, edi        ; edx = ecx - edi
    dec edx             ; pomniejsz o 1
    
inner_loop:
    cmp ebx, edx
    jge next_outer
    
    ; Por�wnaj elementy [esi+ebx] i [esi+ebx+1]
    mov al, [esi+ebx]
    mov ah, [esi+ebx+1]
    
    ; Konwertuj kopie na wielkie litery do por�wnania
    push eax            ; zachowaj oryginalne warto�ci
    call to_upper_al
    call to_upper_ah
    
    cmp al, ah
    pop eax             ; przywr�� oryginalne warto�ci
    jle no_swap         ; je�li al <= ah, nie zamieniaj
    
    ; Zamie� oryginalne elementy
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

; Pomocnicza funkcja do konwersji znaku w AL na wielk� liter�
to_upper_al:
    cmp al, 'a'
    jb al_done
    cmp al, 'z'
    ja al_done
    sub al, 32          ; konwertuj a-z na A-Z
al_done:
    ret

; Pomocnicza funkcja do konwersji znaku w AH na wielk� liter�  
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