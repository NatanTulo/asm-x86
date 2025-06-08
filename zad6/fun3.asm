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
    
    mov edi, 0          ; edi = licznik przebieg�w zewn�trznych (i)
    
outer_loop:
    mov eax, ecx        ; eax = n
    dec eax             ; eax = n-1
    cmp edi, eax        ; sprawd� czy i < n-1
    jge sort_end        ; je�li i >= n-1, koniec
    
    mov ebx, 0          ; ebx = licznik p�tli wewn�trznej (j)
    
inner_loop:
    mov eax, ecx        ; eax = n
    sub eax, edi        ; eax = n - i
    dec eax             ; eax = n - i - 1
    cmp ebx, eax        ; sprawd� czy j < n-i-1
    jge next_outer      ; je�li j >= n-i-1, nast�pny przebieg zewn�trzny
    
    ; Por�wnaj elementy [esi+ebx] i [esi+ebx+1]
    mov al, [esi+ebx]
    mov ah, [esi+ebx+1]
    
    ; Stw�rz kopie do por�wnania (konwersja na wielkie litery)
    push eax            ; zachowaj oryginalne warto�ci
    call to_upper_al
    call to_upper_ah
    
    cmp al, ah          ; por�wnaj skonwertowane znaki
    pop eax             ; przywr�� oryginalne warto�ci
    jle no_swap         ; je�li al <= ah, nie zamieniaj
    
    ; Zamie� oryginalne elementy miejscami
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