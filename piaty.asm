;Zadanie 5 - Filtr FIR (Finite Impulse Response)
;Procesor 16-bitowy

dane SEGMENT
    we dw 64 dup (?) ; tablica wejsciowa 64 liczb typu WORD
    wy dw 64 dup (?) ; tablica wynikow 64 liczb typu WORD
    rozmiar dw 64    ; rozmiar tablic
    
    ; Komunikaty do wyswietlania
    msg_we db 'Tablica wejsciowa WE (hex):', 13, 10, '$'
    msg_wy db 13, 10, 'Tablica wynikow WY (hex):', 13, 10, '$'
    spacja db ' $'
    NL db 13, 10, '$'
    
    ; Zmienne pomocnicze do generowania liczb losowych
    seed dw 1234h    ; ziarno generatora
    
dane ENDS

rozkazy SEGMENT 'CODE' use16
    ASSUME cs:rozkazy, ds:dane

startuj:
    mov ax, SEG dane
    mov ds, ax
    mov es, ax
    
    ; Wypelnienie tablicy we liczbami losowymi <= 7Fh
    call WypelnijTablice
    
    ; Wyswietlenie tablicy wejsciowej
    mov dx, offset msg_we
    mov ah, 9
    int 21h
    
    mov ax, offset we
    push ax                ; offset tablicy we
    mov ax, rozmiar
    push ax                ; rozmiar tablicy
    call WyswietlTablice
    pop ax                 ; czyszczenie stosu
    pop ax
    
    ; Wywolanie podprogramu filtrujacego
    mov ax, offset we      ; offset tablicy wejsciowej
    push ax
    mov ax, offset wy      ; offset tablicy wynikow
    push ax
    mov ax, rozmiar        ; rozmiar tablic
    push ax
    call FiltrFIR
    pop ax                 ; czyszczenie stosu
    pop ax
    pop ax
    
    ; Wyswietlenie tablicy wynikow
    mov dx, offset msg_wy
    mov ah, 9
    int 21h
    
    mov ax, offset wy
    push ax                ; offset tablicy wy
    mov ax, rozmiar
    push ax                ; rozmiar tablicy
    call WyswietlTablice
    pop ax                 ; czyszczenie stosu
    pop ax
    
    call Koniec

;*****************************************************
; Podprogram wypelniajacy tablice liczbami losowymi <= 7Fh
;*****************************************************
WypelnijTablice PROC near
    push cx
    push bx
    push dx
    push si
    
    mov cx, 64             ; liczba elementow
    mov si, 0              ; indeks w tablicy
    
wypelnij_petla:
    ; Prosty generator liczb pseudolosowych
    mov ax, seed
    mov dx, 25173          ; mnoznik
    mul dx
    add ax, 13849          ; przyrost
    mov seed, ax           ; nowe ziarno
    
    ; Ograniczenie do zakresu <= 7Fh (127)
    and ax, 7Fh            ; maska dla 7 bitow
    
    mov word ptr we[si], ax
    add si, 2              ; przejscie do nastepnego elementu (WORD = 2 bajty)
    loop wypelnij_petla
    
    pop si
    pop dx
    pop bx
    pop cx
    ret
WypelnijTablice ENDP

;*****************************************************
; Podprogram filtrujacy FIR
; Parametry na stosie (po wykonaniu PUSH BP; MOV BP, SP):
; [bp+8] - offset tablicy we (pierwszy parametr odłożony na stos)
; [bp+6] - offset tablicy wy (drugi parametr odłożony na stos)
; [bp+4] - rozmiar tablic (trzeci, ostatni parametr odłożony na stos)
;*****************************************************
FiltrFIR PROC near
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    mov si, [bp+8]         ; odczyt offsetu tablicy we
    mov di, [bp+6]         ; odczyt offsetu tablicy wy
    mov cx, [bp+4]         ; odczyt rozmiaru tablic
    
    ; Kopiowanie pierwszych trzech elementow bez zmian
    ; wy0 = x0, wy1 = x1, wy2 = x2
    mov ax, word ptr [si]     ; we[0]
    mov word ptr [di], ax     ; wy[0] = we[0]
    
    mov ax, word ptr [si+2]   ; we[1]
    mov word ptr [di+2], ax   ; wy[1] = we[1]
    
    mov ax, word ptr [si+4]   ; we[2]
    mov word ptr [di+4], ax   ; wy[2] = we[2]
    
    ; Filtrowanie dla i = 3, ..., 63
    ; wyi = (125*xi-1)/256 + (62*xi-2)/256 + (27*xi-3)/256
    mov bx, 3              ; licznik elementow od 3 do 63
    
filtr_petla:
    cmp bx, 64             ; sprawdz czy nie przekroczylismy 64 elementow
    jge koniec_filtra
    
    ; Oblicz indeks w bajtach (bx * 2)
    push bx
    shl bx, 1              ; bx = bx * 2 (indeks w bajtach)
    
    ; Obliczenie 125 * xi-1
    mov ax, word ptr [si+bx-2]  ; xi-1
    mov cx, 125
    mul cx                      ; AX = 125 * xi-1 (zakładamy brak przepełnienia)
    mov dx, ax                  ; zachowaj pierwszy składnik
    
    ; Obliczenie 62 * xi-2
    mov ax, word ptr [si+bx-4]  ; xi-2
    mov cx, 62
    mul cx                      ; AX = 62 * xi-2
    add dx, ax                  ; dodaj do sumy
    
    ; Obliczenie 27 * xi-3
    mov ax, word ptr [si+bx-6]  ; xi-3
    mov cx, 27
    mul cx                      ; AX = 27 * xi-3
    add dx, ax                  ; dodaj do sumy
    
    ; Dzielenie sumy przez 256 (przesuniecie o 8 bitow w prawo)
    mov ax, dx
    mov cl, 8
    shr ax, cl                  ; ax = ax / 256
    
    ; Zapisanie wyniku
    mov word ptr [di+bx], ax
    
    pop bx                      ; przywroc licznik elementow
    inc bx                      ; nastepny element
    jmp filtr_petla
    
koniec_filtra:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret
FiltrFIR ENDP

;*****************************************************
; Podprogram wyswietlajacy tablice w systemie szesnastkowym
; Parametry na stosie: [bp+6] - offset tablicy
;                      [bp+4] - rozmiar tablicy
;*****************************************************
WyswietlTablice PROC near
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    push si
    
    mov si, [bp+6]         ; offset tablicy
    mov cx, [bp+4]         ; rozmiar tablicy
    mov bx, 0              ; indeks
    
wyswietl_petla:
    mov ax, word ptr [si+bx]
    call WyswietlHex
    
    ; Wyswietlenie spacji
    mov dx, offset spacja
    mov ah, 9
    int 21h
    
    add bx, 2              ; nastepny element
    
    ; Co 8 elementow nowa linia
    push ax
    mov ax, bx
    shr ax, 1              ; dzielenie przez 2 (bo WORD = 2 bajty)
    mov dx, 0
    mov di, 8
    div di
    cmp dx, 0
    jne nie_nowa_linia
    
    mov dx, offset NL
    mov ah, 9
    int 21h
    
nie_nowa_linia:
    pop ax
    loop wyswietl_petla
    
    mov dx, offset NL
    mov ah, 9
    int 21h
    
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret
WyswietlTablice ENDP

;*****************************************************
; Podprogram wyswietlajacy liczbe w systemie szesnastkowym
; Wejscie: ax - liczba do wyswietlenia
;*****************************************************
WyswietlHex PROC near
    push ax
    push bx
    push cx
    push dx
    
    mov cx, 4              ; 4 cyfry hex dla WORD
    
hex_petla:
    push cx                ; Zachowaj licznik pętli zewnętrznej
    mov cl, 4              ; Liczba bitów do rotacji
    rol ax, cl             ; Przesunięcie o 4 bity w lewo
    pop cx                 ; Przywróć licznik pętli zewnętrznej
    mov dx, ax
    and dx, 0Fh            ; maska dla 4 bitow
    
    cmp dx, 9
    jle cyfra
    add dx, 7              ; dla A-F
cyfra:
    add dx, 30h            ; kod ASCII
    
    push ax
    mov ah, 2
    int 21h
    pop ax
    
    loop hex_petla
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
WyswietlHex ENDP

;*****************************************************
; Podprogram konczacy program
;*****************************************************
Koniec PROC near
    mov al, 0
    mov ah, 4Ch
    int 21h
Koniec ENDP

rozkazy ENDS

stosik SEGMENT stack
    dw 128 dup(?)
stosik ENDS

END startuj