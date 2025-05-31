;zad5 - przetwarzanie tablicy za pomoc filtru FIR i wywietlanie liczb

dane SEGMENT
    WE          dw 64 dup(?)    ; Tablica wejciowa
    WY          dw 64 dup(?)    ; Tablica wynikowa
    DLUGOSC     equ 64          ; Dugo tablic
    
    COEFF1      dw 125          ; Wspczynnik filtra
    COEFF2      dw 62           ; Wspczynnik filtra
    COEFF3      dw 27           ; Wspczynnik filtra
    DIVISOR_CONST equ 256       ; Dzielnik filtra
    
    random_seed dw 12345        ; Ziarno generatora liczb pseudolosowych

    Buf_1       db 6 dup('$')   ; Bufor dla konwersji liczby na string (5 cyfr + '$')
    NL          db 13, 10, '$'
    MsgWE       db 'Tablica we:', 13, 10, '$'
    MsgWY       db 'Tablica wy:', 13, 10, '$'
    Separator   db ' ', '$'     ; Separator midzy liczbami
dane ENDS

rozkazy SEGMENT 'CODE' use16 ;segment rozkazu
	ASSUME cs:rozkazy, ds:dane

startuj:
	mov ax, SEG dane
	mov ds, ax	
	mov es, ax	; przypisanie segmentu danych do rejestru es 

    ; 1. Wypenij tablic WE liczbami pseudolosowymi <= 7Fh
    call WypelnijWE

    ; 2. Wywoaj podprogram filtrujcy
    mov ax, offset WE
    push ax             ; Parametr 1: offset tablicy WE
    mov ax, offset WY
    push ax             ; Parametr 2: offset tablicy WY
    mov ax, DLUGOSC
    push ax             ; Parametr 3: dugo tablic
    call FiltrFIR
    add sp, 6           ; Usu parametry ze stosu (3 parametry * 2 bajty)

    ; 3. Wywietl tablic WE
    mov dx, offset MsgWE
    mov ah, 09h
    int 21h
    mov ax, offset WE
    push ax             ; Parametr 1: offset tablicy
    mov ax, DLUGOSC
    push ax             ; Parametr 2: dugo
    call WyswietlTablice
    add sp, 4           ; Usu parametry ze stosu

    call NowaLinia

    ; 4. Wywietl tablic WY
    mov dx, offset MsgWY
    mov ah, 09h
    int 21h
    mov ax, offset WY
    push ax             ; Parametr 1: offset tablicy
    mov ax, DLUGOSC
    push ax             ; Parametr 2: dugo
    call WyswietlTablice
    add sp, 4           ; Usu parametry ze stosu

	call koniec

;***********************************************************
; Podprogram do wypeniania tablicy WE liczbami pseudolosowymi
;***********************************************************
WypelnijWE PROC near
    push ax ; Zapisz uywane rejestry
    push cx
    push si
    
    mov cx, DLUGOSC
    mov si, offset WE
petla_wypelniania:
    call GenerujLosowa ; Wynik w AX (0-7Fh)
    mov [si], ax
    add si, 2 ; Nastpny WORD
    loop petla_wypelniania
    
    pop si  ; Odtwrz rejestry
    pop cx
    pop ax
    ret
WypelnijWE ENDP

;***********************************************************
; Prosty generator liczb pseudolosowych (LCG)
; Wynik (0-7Fh) w AX
;***********************************************************
GenerujLosowa PROC near
    push dx
    push cx
    push bx
    ; seed = (a * seed + c) mod m
    ; a = 25173, c = 13849, m = 65536 (WORD overflow)
    mov ax, 25173
    mul random_seed ; DX:AX = ax * random_seed
    add ax, 13849   ; Dodaj c
    mov random_seed, ax ; Zapisz nowe ziarno

    ; Redukcja do zakresu 0-7Fh
    and ax, 007Fh ; ax = ax AND 0000 0000 0111 1111b
    pop bx
    pop cx
    pop dx
    ret
GenerujLosowa ENDP

;***********************************************************
; Podprogram filtrujcy FIR
; Parametry na stosie: 
; [bp+8] - offset WE
; [bp+6] - offset WY
; [bp+4] - dugo
;***********************************************************
FiltrFIR PROC near
    push bp
    mov bp, sp
    push ax ; Zapisz uywane rejestry
    push bx
    push cx
    push dx
    push si
    push di

    mov si, [bp+8] ; Adres WE
    mov di, [bp+6] ; Adres WY
    mov cx, [bp+4] ; Dugo

    ; Kopiowanie pierwszych elementw (do 3), jeli dugo na to pozwala
    cmp cx, 1
    jl koniec_filtrowania_za_krotka
    mov ax, [si]    ; we[0]
    mov [di], ax    ; wy[0] = we[0]

    cmp cx, 2
    jl koniec_filtrowania_za_krotka
    mov ax, [si+2]  ; we[1]
    mov [di+2], ax  ; wy[1] = we[1]

    cmp cx, 3
    jl koniec_filtrowania_za_krotka
    mov ax, [si+4]  ; we[2]
    mov [di+4], ax  ; wy[2] = we[2]

    ; Sprawdzenie, czy s elementy do filtrowania (i >= 3)
    cmp cx, 3 
    jle koniec_filtrowania_za_krotka ; Jeli dugo <=3, to ju wszystko zrobione

    ; Ptla dla i = 3 do dugo-1
    add si, 6 ; Ustaw si na we[3]
    add di, 6 ; Ustaw di na wy[3]
    sub cx, 3 ; Liczba pozostaych elementw do przetworzenia

petla_filtru:
    ; Adresy: we[i-1] -> [si-2], we[i-2] -> [si-4], we[i-3] -> [si-6]
    
    xor bx, bx ; bx bdzie sum wy[i]

    ; term1 = (125 * we[i-1]) / 256
    mov ax, COEFF1
    mul word ptr [si-2] ; we[i-1]. Wynik w DX:AX.
    ; Poniewa max we[i-1] to 7Fh (127) i COEFF1 to 125,
    ; 125 * 127 = 15875. To mieci si w AX, wic DX bdzie 0.
    ; Dla pewnoci moemy wyzerowa DX, chocia mul word ptr to zrobi.
    ; xor dx, dx ; Nie jest to konieczne, bo mul word ptr [si-2] ustawi DX:AX
    push cx             ; Zachowaj licznik ptli CX
    mov cx, DIVISOR_CONST ; Zaaduj dzielnik do CX
    div cx              ; AX = (DX:AX) / CX. Reszta w DX.
    pop cx              ; Przywr licznik ptli CX
    add bx, ax          ; Dodaj (term1/DIVISOR_CONST) do sumy

    ; term2 = (62 * we[i-2]) / 256
    mov ax, COEFF2
    mul word ptr [si-4] ; we[i-2]. Wynik w DX:AX. (DX bdzie 0)
    push cx
    mov cx, DIVISOR_CONST
    div cx
    pop cx
    add bx, ax

    ; term3 = (27 * we[i-3]) / 256
    mov ax, COEFF3
    mul word ptr [si-6] ; we[i-3]. Wynik w DX:AX. (DX bdzie 0)
    push cx
    mov cx, DIVISOR_CONST
    div cx
    pop cx
    add bx, ax

    mov [di], bx   ; wy[i] = wynik

    add si, 2 ; Nastpny element we
    add di, 2 ; Nastpny element wy
    loop petla_filtru

koniec_filtrowania_za_krotka:
    pop di  ; Odtwrz rejestry
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret
FiltrFIR ENDP

;***********************************************************
; Podprogram do wywietlania tablicy liczb dziesitnych
; Parametry na stosie: 
; [bp+6] - offset tablicy
; [bp+4] - dugo
;***********************************************************
WyswietlTablice PROC near
    push bp
    mov bp, sp
    push ax ; Zapisz uywane rejestry
    push bx
    push cx
    push dx
    push si

    mov cx, [bp+4] ; Dugo
    mov si, [bp+6] ; Adres tablicy
    mov bx, 0      ; Licznik elementw w linii (dla formatowania)

petla_wyswietlania:
    push cx        ; Zachowaj licznik ptli gwnej
    
    mov ax, [si]   ; Liczba do wywietlenia
    call WyswLiczbe10_mod ; Wywietla liczb z AX

    ; Wywietl separator
    push dx
    mov dx, offset Separator
    mov ah, 09h
    int 21h
    pop dx

    inc bx
    cmp bx, 16 ; Wywietl 16 liczb w linii
    jne nie_nowa_linia_wysw
    call NowaLinia
    mov bx, 0
nie_nowa_linia_wysw:

    add si, 2
    pop cx
    loop petla_wyswietlania

    ; Jeli ostatnia linia nie bya pena i nie bya pusta, dodaj NowaLinia
    cmp bx, 0
    je koniec_wyswietlania_tab
    call NowaLinia

koniec_wyswietlania_tab:
    pop si  ; Odtwrz rejestry
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret
WyswietlTablice ENDP

;***********************************************************
; Podprogram WczyLiczbe10 (pozostawiony, ale nieuywany w gwnym przepywie)
;***********************************************************
WczyLiczbe10 PROC near
	push bp
	mov bp, sp
	push cx	;zapisanie na stosie wszystkich rejestrw uywanych przez podprogram
	push bx	;
	push dx	;
	push si	;

	mov si, [bp]+6 ;wczytanie do rej. si offset'u zmiennej wyjciowej - pierwszy param. procedury
	
	mov ax, 0       	  ;wpisanie wartoci poczatkowej 0
	mov word PTR [si], ax ;do zmiennej wyjciowej

	mov cx, [bp]+4 ;liczba wczytywanych cyfr dziesitnych - drugi param. procedury
czn: 
	mov ah, 07H ;wczytanie z klawiatury do rej. AL znaku w kodzie ASCII
	int 21H 	;bez wywietlania !!!
	cmp al, 13
	je jest_enter ;skok gdy nacisnieto klawisz Enter
	sub al, 30H ;zamaiana kodu ASCII na wartosc cyfry
	mov bl, al ;przechowanie kolejnej cyfry w rej. BL
	mov bh, 0  ;zerowanie rejestru BH
		   ;algorytm Hornera - wyznaczenie za pomoc cyfr liczby wejsciowej 
		   ;(dziesi�tnej) jej wartoci binarnej	
	mov ax, 10 ;mnoznik = 10 bo wczytujemy cyfry w kodzie dziesi�tnym
	mul word PTR [si] 	;mnozenie dotychczas uzyskanego wyniku przez 10, 
				        ;iloczyn zostaje wpisany do rejestrw DX:AX
	add ax, bx 	        ;dodanie do wyniku mnoenia aktualnie wczytanej cyfry
	mov word PTR [si], ax	;przesanie wyniku obliczenia do zmiennej wyjciowej
	loop czn;
	jmp dalej		;jeli wczytano wszystkie okrelone przez drugi param. podprogramu
					;omijamy oczyszczenie bufora klawiatury ze znaku enter.

jest_enter:
	mov ah, 06H 	;Oczyszczenie bufora klawiatury ze znaku enter.  
	mov dl, 255		;Zabieg ten jest niezbdny przy przetwarzaniu wsadowym, gdy  
	int 21H 		;przekierowujemy do programu strumie danych w postaci pliku tekstowego  
					;z liczbami oddzielonymi enterem (komenda:  piaty.exe < dane.txt). 
					;- zabieg oczyszcenia bufora uzyskamy wstawiajc
					;do rej. DL warto 255 i wywoujc funkcj 06H przerwania 21H. 
dalej:	
	pop si 	; przywrcenie wartoci poczatkowych wszystkich rejestrw 
	pop dx	; uywanych przez podprogram
	pop bx	; UWAGA! w odwrotnej kolejnoci ni byo w to komendach push!
	pop cx	;

	pop bp
	ret
WczyLiczbe10 ENDP

;**************************
; Zmodyfikowany WyswLiczbe10, ktry bierze liczb z AX
; i uywa lokalnego bufora Buf_1
;**************************
WyswLiczbe10_mod PROC near
    ; Liczba do wywietlenia jest w AX
    push ax ; Zapisz uywane rejestry
    push bx
    push cx
    push dx ; Zapisz oryginalny DX (dx_outer)
    push di ; Zapisz oryginalny DI (di_outer)

    mov cx, 0       ; Licznik cyfr
    mov di, offset Buf_1 + 5 ; Wskanik na koniec bufora (Buf_1 db 6 dup('$'))
                            ; Buf_1[5] = '$', Buf_1[4] = ostatnia cyfra, itd.
    mov byte ptr [di], '$' ; Terminator stringu
    dec di

    cmp ax, 0
    jne konwersja_liczby_wysw
    ; Specjalny przypadek dla liczby 0
    mov byte ptr [di], '0'
    dec di ; przesun DI aby wskazywalo na '0'
    inc cx
    jmp koniec_konwersji_wysw

konwersja_liczby_wysw:
    mov bx, 10      ; Dzielnik
petla_dziel_wysw:
    mov dx, 0       ; Wyzeruj DX przed dzieleniem DX:AX przez BX
    div bx          ; AX = AX / 10, reszta w DX
    add dl, '0'     ; Konwertuj reszt na cyfr ASCII
    mov [di], dl    ; Zapisz cyfr w buforze
    dec di
    inc cx          ; Zwiksz licznik cyfr
    cmp ax, 0       ; Czy iloraz jest zerem?
    jne petla_dziel_wysw

koniec_konwersji_wysw:
    inc di ; Ustaw DI na poczatek liczby w buforze

    ; Wywietl liczb z bufora
    push dx ; Zachowaj DX (dx_inner - aktualna warto DX przed uzyciem go jako wskaźnika)
    mov dx, di
    mov ah, 09h
    int 21h
    ; Poprawiona sekwencja zdejmowania rejestrów ze stosu:
    pop dx  ; Odtwrz dx_inner do rejestru DX
    pop di  ; Odtwrz di_outer
    pop dx  ; Odtwrz dx_outer
    pop cx
    pop bx
    pop ax
    ret
WyswLiczbe10_mod ENDP

;**************************

NowaLinia PROC near
	push dx
	mov dx, offset NL
	mov ah, 9 
	int 21H
	pop dx
	ret
NowaLinia ENDP

;**************************

koniec PROC near
	mov al, 0
	mov ah, 4CH
	int 21H
koniec ENDP

;**************************

rozkazy ENDS


stosik SEGMENT stack
	dw 128 dup(?)
stosik ENDS
END startuj
