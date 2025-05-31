;zad5 - przetwarzanie tablicy za pomocą filtru FIR i wyświetlanie liczb

dane SEGMENT
    WE          dw 64 dup(?)    ; Tablica wejściowa
    WY          dw 64 dup(?)    ; Tablica wynikowa
    DLUGOSC     equ 64          ; Długość tablic
    
    COEFF1      dw 125          ; Współczynnik filtra
    COEFF2      dw 62           ; Współczynnik filtra
    COEFF3      dw 27           ; Współczynnik filtra
    DIVISOR_CONST equ 256       ; Dzielnik filtra
    
    ; random_seed dw 12345        ; Usunięto - Ziarno generatora liczb pseudolosowych

    Buf_1       db 6 dup('$')   ; Bufor dla konwersji liczby na string (5 cyfr + znak końca '$')
    NL          db 13, 10, '$'  ; Sekwencja nowej linii
    MsgWE       db 'Tablica we:', 13, 10, '$'
    MsgWY       db 'Tablica wy:', 13, 10, '$'
    Separator   db ' ', '$'     ; Separator między liczbami
dane ENDS

rozkazy SEGMENT 'CODE' use16 ;segment kodu
	ASSUME cs:rozkazy, ds:dane

startuj:
	mov ax, SEG dane
	mov ds, ax	
	mov es, ax	; przypisanie segmentu danych również do rejestru es (dla operacji na stringach)

    ; 1. Wypełnij tablicę WE liczbami z pliku dane.txt (przez stdin)
    call WypelnijWE

    ; 2. Wywołaj podprogram filtrujący
    mov ax, offset WE
    push ax             ; Parametr 1: adres tablicy WE
    mov ax, offset WY
    push ax             ; Parametr 2: adres tablicy WY
    mov ax, DLUGOSC
    push ax             ; Parametr 3: długość tablic
    call FiltrFIR
    add sp, 6           ; Usuń parametry ze stosu (3 słowa * 2 bajty)

    ; 3. Wyświetl tablicę WE
    mov dx, offset MsgWE
    mov ah, 09h
    int 21h
    mov ax, offset WE
    push ax             ; Parametr 1: adres tablicy
    mov ax, DLUGOSC
    push ax             ; Parametr 2: długość
    call WyswietlTablice
    add sp, 4           ; Usuń parametry ze stosu (2 słowa * 2 bajty)

    call NowaLinia

    ; 4. Wyświetl tablicę WY
    mov dx, offset MsgWY
    mov ah, 09h
    int 21h
    mov ax, offset WY
    push ax             ; Parametr 1: adres tablicy
    mov ax, DLUGOSC
    push ax             ; Parametr 2: długość
    call WyswietlTablice
    add sp, 4           ; Usuń parametry ze stosu (2 słowa * 2 bajty)

	call koniec

;***********************************************************
; Podprogram do wypełniania tablicy WE liczbami pseudolosowymi
;***********************************************************
WypelnijWE PROC near
    push ax ; Zapisz używane rejestry na stosie
    push cx
    push si
    
    mov cx, DLUGOSC
    mov si, offset WE
petla_wypelniania:
    call WczytajLiczbe10_stdin ; Wczytaj liczbę z stdin, wynik w AX
    mov [si], ax
    add si, 2 ; Następne słowo (WORD)
    loop petla_wypelniania
    
    pop si  ; Odtwórz rejestry ze stosu
    pop cx
    pop ax
    ret
WypelnijWE ENDP

;***********************************************************
; Procedura WczytajLiczbe10_stdin
; Wczytuje liczbę dziesiętną ze standardowego wejścia (np. przekierowanego pliku).
; Wynik zwracany jest w rejestrze AX.
; Pomija wiodące białe znaki. Kończy na pierwszym znaku niebędącym cyfrą.
; Używa INT 21h, AH=08h (wczytaj znak bez echa).
; Używa DI jako akumulatora.
;***********************************************************
WczytajLiczbe10_stdin PROC near
    push bx
    push cx
    push dx
    push si
    push di         ; Zapisz DI na stosie

    xor di, di      ; DI będzie akumulatorem dla liczby (wynik inicjowany na 0)
    xor si, si      ; Stan: si=0 (pomijanie białych znaków), si=1 (wczytywanie cyfr)

pobierz_znak_loop:
    mov ah, 08h     ; Wczytaj znak bez echa
    int 21h         ; Znak w AL (AH może pozostać 08h)

    cmp al, 1Ah     ; Ctrl+Z (EOF) - koniec pliku
    je koniec_wczytywania_liczby_do_ax

    cmp si, 0       ; Czy jesteśmy w trybie pomijania białych znaków?
    jne probuj_jako_cyfre_do_di ; Jeśli si=1, to próbuj interpretować jako cyfrę

    ; Tryb pomijania białych znaków (si=0)
    cmp al, ' '     ; Spacja
    je pobierz_znak_loop
    cmp al, 09h     ; Tabulator
    je pobierz_znak_loop
    cmp al, 0Dh     ; CR (powrót karetki)
    je pobierz_znak_loop ; Traktuj jako biały znak
    cmp al, 0Ah     ; LF (nowa linia)
    je pobierz_znak_loop ; Traktuj jako biały znak

    ; Jeśli nie jest białym znakiem, to jest to potencjalna pierwsza cyfra
    mov si, 1       ; Przełącz na tryb wczytywania cyfr
    ; Przejdź do próby interpretacji tego znaku jako cyfry (poniżej)

probuj_jako_cyfre_do_di:
    cmp al, '0'
    jl koniec_wczytywania_liczby_do_ax ; Mniejszy niż '0' - to separator, zakończ
    cmp al, '9'
    jg koniec_wczytywania_liczby_do_ax ; Większy niż '9' - to separator, zakończ

    ; To jest cyfra
    sub al, '0'     ; Konwertuj ASCII ('0'-'9') na wartość (0-9)
    mov bl, al
    mov bh, 0       ; BX = wartość cyfry

    ; di = di * 10 + bx (Algorytm Hornera używając DI jako akumulatora)
    push ax         ; Zachowaj AX (bo MUL go używa)
    push dx         ; Zachowaj DX (bo MUL go używa)
    
    mov ax, di      ; Przenieś dotychczasową liczbę z DI do AX w celu mnożenia
    mov cx, 10      ; Mnożnik
    mul cx          ; DX:AX = AX * CX (czyli DI * 10). Zakładamy, że wynik mieści się w AX.
    mov di, ax      ; Przenieś wynik mnożenia (z AX) z powrotem do DI
    
    add di, bx      ; Dodaj nową cyfrę (z BX) do DI
    ; Można by tu dodać sprawdzanie przepełnienia DI, jeśli liczby mogą być duże
    
    pop dx          ; Przywróć DX
    pop ax          ; Przywróć AX

    jmp pobierz_znak_loop ; Wczytaj następny znak

koniec_wczytywania_liczby_do_ax:
    ; Znak w AL nie jest cyfrą lub jest EOF.
    ; Akumulator DI zawiera zbudowaną liczbę (lub 0, jeśli nie wczytano cyfr).
    mov ax, di      ; Przenieś ostateczny wynik z DI do AX

    pop di          ; Odtwórz oryginalną wartość DI
    pop si
    pop dx
    pop cx
    pop bx
    ret
WczytajLiczbe10_stdin ENDP

;***********************************************************
; Podprogram filtrujący FIR
; Parametry na stosie: 
; [bp+8] - adres tablicy WE
; [bp+6] - adres tablicy WY
; [bp+4] - długość
;***********************************************************
FiltrFIR PROC near
    push bp
    mov bp, sp
    push ax ; Zapisz używane rejestry na stosie
    push bx
    push cx
    push dx
    push si
    push di

    mov si, [bp+8] ; Adres WE
    mov di, [bp+6] ; Adres WY
    mov cx, [bp+4] ; Długość

    ; Kopiowanie pierwszych 3 elementów (jeśli długość na to pozwala),
    ; ponieważ filtr potrzebuje 3 poprzednich wartości.
    cmp cx, 1
    jl koniec_filtrowania_za_krotka ; Jeśli długość < 1, zakończ
    mov ax, [si]    ; we[0]
    mov [di], ax    ; wy[0] = we[0]

    cmp cx, 2
    jl koniec_filtrowania_za_krotka ; Jeśli długość < 2, zakończ
    mov ax, [si+2]  ; we[1]
    mov [di+2], ax  ; wy[1] = we[1]

    cmp cx, 3
    jl koniec_filtrowania_za_krotka ; Jeśli długość < 3, zakończ
    mov ax, [si+4]  ; we[2]
    mov [di+4], ax  ; wy[2] = we[2]

    ; Sprawdzenie, czy są elementy do filtrowania (indeks i >= 3)
    cmp cx, 3 
    jle koniec_filtrowania_za_krotka ; Jeśli długość <=3, to wszystkie elementy zostały już skopiowane

    ; Pętla dla i = 3 do długość-1
    add si, 6 ; Ustaw si na we[3] (indeks 3, przesunięcie o 3*2 bajty)
    add di, 6 ; Ustaw di na wy[3] (indeks 3, przesunięcie o 3*2 bajty)
    sub cx, 3 ; Liczba pozostałych elementów do przetworzenia w pętli

petla_filtru:
    ; Adresy: we[i-1] -> [si-2], we[i-2] -> [si-4], we[i-3] -> [si-6]
    ; Bieżący element wejściowy to [si], ale filtr FIR używa poprzednich wartości.
    ; W tej implementacji filtr liczy wy[i] na podstawie we[i-1], we[i-2], we[i-3].
    ; Aby obliczyć wy[i], potrzebujemy we[i-1], we[i-2], we[i-3].
    ; Jeśli si wskazuje na we[i], to:
    ; we[i-1] jest pod [si-2]
    ; we[i-2] jest pod [si-4]
    ; we[i-3] jest pod [si-6]
    
    xor bx, bx ; bx będzie sumą dla wy[i]

    ; term1 = (COEFF1 * we[i-1]) / DIVISOR_CONST
    mov ax, COEFF1
    mul word ptr [si-2] ; we[i-1]. Wynik w DX:AX. DX będzie 0, bo 125*127 < 65536.
    push cx             ; Zachowaj licznik pętli CX
    mov cx, DIVISOR_CONST ; Załaduj dzielnik do CX
    div cx              ; AX = (DX:AX) / CX. Reszta (nieużywana) w DX.
    pop cx              ; Przywróć licznik pętli CX
    add bx, ax          ; Dodaj (term1/DIVISOR_CONST) do sumy

    ; term2 = (COEFF2 * we[i-2]) / DIVISOR_CONST
    mov ax, COEFF2
    mul word ptr [si-4] ; we[i-2]. Wynik w DX:AX. (DX będzie 0)
    push cx
    mov cx, DIVISOR_CONST
    div cx
    pop cx
    add bx, ax

    ; term3 = (COEFF3 * we[i-3]) / DIVISOR_CONST
    mov ax, COEFF3
    mul word ptr [si-6] ; we[i-3]. Wynik w DX:AX. (DX będzie 0)
    push cx
    mov cx, DIVISOR_CONST
    div cx
    pop cx
    add bx, ax

    mov [di], bx   ; wy[i] = wynik

    add si, 2 ; Następny element we (dla następnej iteracji i obliczenia wy[i+1])
    add di, 2 ; Następny element wy
    loop petla_filtru

koniec_filtrowania_za_krotka:
    pop di  ; Odtwórz rejestry ze stosu
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret
FiltrFIR ENDP

;***********************************************************
; Podprogram do wyświetlania tablicy liczb dziesiętnych
; Parametry na stosie: 
; [bp+6] - adres tablicy
; [bp+4] - długość
;***********************************************************
WyswietlTablice PROC near
    push bp
    mov bp, sp
    push ax ; Zapisz używane rejestry na stosie
    push bx
    push cx
    push dx
    push si

    mov cx, [bp+4] ; Długość
    mov si, [bp+6] ; Adres tablicy
    mov bx, 0      ; Licznik elementów w linii (dla formatowania)

petla_wyswietlania:
    push cx        ; Zachowaj licznik pętli głównej
    
    mov ax, [si]   ; Liczba do wyświetlenia
    call WyswLiczbe10_mod ; Wyświetla liczbę z AX

    ; Wyświetl separator
    push dx
    mov dx, offset Separator
    mov ah, 09h
    int 21h
    pop dx

    inc bx
    cmp bx, 16 ; Wyświetl 16 liczb w jednej linii
    jne nie_nowa_linia_wysw
    call NowaLinia
    mov bx, 0 ; Resetuj licznik elementów w linii
nie_nowa_linia_wysw:

    add si, 2 ; Następne słowo (WORD)
    pop cx    ; Przywróć licznik pętli głównej
    loop petla_wyswietlania

    ; Jeśli ostatnia linia nie była pełna (bx != 0) i nie była pusta, dodaj NowaLinia
    cmp bx, 0
    je koniec_wyswietlania_tab
    call NowaLinia

koniec_wyswietlania_tab:
    pop si  ; Odtwórz rejestry ze stosu
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret
WyswietlTablice ENDP

;**************************
; Zmodyfikowany WyswLiczbe10, który bierze liczbę z AX
; i używa lokalnego bufora Buf_1 do konwersji na string.
;**************************
WyswLiczbe10_mod PROC near
    ; Liczba do wyświetlenia znajduje się w rejestrze AX
    push ax ; Zapisz używane rejestry na stosie
    push bx
    push cx
    push dx 
    push di 

    mov cx, 0       ; Licznik cyfr
    mov di, offset Buf_1 + 5 ; Wskaźnik na koniec bufora (Buf_1 ma 6 bajtów, ostatni to '$')
                            ; Buf_1[5] = '$', Buf_1[4] = ostatnia cyfra, itd.
    mov byte ptr [di], '$' ; Terminator stringu dla funkcji 09h INT 21h
    dec di                 ; Ustaw wskaźnik na pozycję ostatniej cyfry

    cmp ax, 0
    jne konwersja_liczby_wysw
    ; Specjalny przypadek dla liczby 0
    mov byte ptr [di], '0' ; Zapisz '0' w buforze
    dec di                 ; Przesuń DI, aby wskazywało na cyfrę '0' (dla poprawnego wyświetlenia)
    inc cx                 ; Jedna cyfra
    jmp koniec_konwersji_wysw

konwersja_liczby_wysw:
    mov bx, 10      ; Dzielnik (podstawa systemu dziesiętnego)
petla_dziel_wysw:
    xor dx, dx      ; Wyzeruj DX (górne słowo dywidendy) przed dzieleniem DX:AX przez BX
    div bx          ; AX = AX / 10, reszta w DX
    add dl, '0'     ; Konwertuj resztę (cyfrę 0-9) na kod ASCII ('0'-'9')
    mov [di], dl    ; Zapisz cyfrę ASCII w buforze (od końca)
    dec di          ; Przesuń wskaźnik bufora w lewo
    inc cx          ; Zwiększ licznik cyfr
    cmp ax, 0       ; Czy iloraz jest zerem?
    jne petla_dziel_wysw ; Jeśli nie, kontynuuj dzielenie

koniec_konwersji_wysw:
    inc di ; Ustaw DI na początek zapisanej liczby w buforze

    ; Wyświetl liczbę (string) z bufora
    push dx ; Zachowaj DX (zawiera resztę z ostatniego dzielenia, nieistotne tutaj)
    mov dx, di ; DX = adres stringu do wyświetlenia
    mov ah, 09h
    int 21h
    ; Odtwarzanie rejestrów ze stosu
    pop dx  ; Odtwórz poprzednią wartość DX
    pop di  
    pop dx  
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
	mov ah, 4CH ; Funkcja zakończenia programu
	int 21H
koniec ENDP

;**************************

rozkazy ENDS


stosik SEGMENT stack
	dw 128 dup(?) ; Definicja segmentu stosu
stosik ENDS
END startuj
