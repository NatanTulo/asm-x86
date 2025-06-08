title Bubble Sort Subroutine (_bubble_sort.asm)
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

; Funkcja sortowania bąbelkowego
; Argumenty: [ebp+8] = wskaźnik do tablicy, [ebp+12] = długość tablicy
_bubble_sort proc near
    push ebp
    mov ebp, esp
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    
    mov esi, [ebp+8]    ; wskaźnik do tablicy
    mov ecx, [ebp+12]   ; długość tablicy
    
    cmp ecx, 2          ; jeśli długość < 2, nie ma co sortować
    jb sort_end
    
    mov edi, 0          ; edi = licznik przebiegów zewnętrznych (i)
    
outer_loop:
    mov eax, ecx        ; eax = n
    dec eax             ; eax = n-1
    cmp edi, eax        ; sprawdź czy i < n-1
    jge sort_end        ; jeśli i >= n-1, koniec
    
    mov ebx, 0          ; ebx = licznik pętli wewnętrznej (j)
    
inner_loop:
    mov eax, ecx        ; eax = n
    sub eax, edi        ; eax = n - i
    dec eax             ; eax = n - i - 1
    cmp ebx, eax        ; sprawdź czy j < n-i-1
    jge next_outer      ; jeśli j >= n-i-1, następny przebieg zewnętrzny
    
    ; Porównaj elementy [esi+ebx] i [esi+ebx+1]
    mov al, [esi+ebx]
    mov ah, [esi+ebx+1]
    
    ; Stwórz kopie do porównania (konwersja na wielkie litery)
    push eax            ; zachowaj oryginalne wartości
    call to_upper_al
    call to_upper_ah
    
    cmp al, ah          ; porownaj skonwertowane znaki
    pop eax             ; przywróć oryginalne wartości
    jle no_swap         ; jeśli al <= ah, nie zamieniaj
    
    ; Zamień oryginalne elementy miejscami
    mov [esi+ebx], ah
    mov [esi+ebx+1], al
    
no_swap:
    inc ebx             ; j++
    jmp inner_loop
    
next_outer:
    inc edi             ; i++
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

; Pomocnicza funkcja do konwersji znaku w AL na wielką literę
to_upper_al:
    cmp al, 'a'
    jb al_done
    cmp al, 'z'
    ja al_done
    sub al, 32          ; konwertuj a-z na A-Z
al_done:
    ret

; Pomocnicza funkcja do konwersji znaku w AH na wielką literę
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