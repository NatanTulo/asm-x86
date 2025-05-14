;   PROGRAM  "pierwszy.asm"

dane SEGMENT 	; segment danych
Tablica1 db '0123456789',19 dup(' '), 13, 10, '$'  ; tablica znakowa o długości 32 znaków
dane ENDS

rozkazy SEGMENT 'CODE' use16 	; segment zawierający rozkazy programu
		ASSUME cs:rozkazy, ds:dane
wystartuj:
		mov ax, SEG dane
		mov ds, ax
		
		; Rysunek trójkąta - 8 linii
		mov cx, 8          ; licznik wierszy (0-7)
		xor si, si         ; indeks wiersza
		
petla_wierszy:
		; Przygotuj pustą linię
		mov di, OFFSET Tablica1 + 10  ; adres bufora (początek bufora w Tablica1)
		mov cx, 19
		petla_czyszczenia:
			mov byte ptr [di], ' '
			inc di
		loop petla_czyszczenia
		; CR+LF+$ są już zainicjalizowane na końcu Tablica1
		
		cmp si, 7          ; sprawdź czy to ostatni wiersz
		je ostatni_wiersz
		
		; Zwykły wiersz (0-6) - dwie cyfry z odstępami
		
		; Pozycja pierwszej cyfry: 7-si
		mov di, OFFSET Tablica1 + 10  ; adres bufora
		mov cx, 7
		sub cx, si
		add di, cx         ; adres miejsca pierwszej cyfry
		
		; Umieść pierwszą cyfrę
		mov bx, OFFSET Tablica1  ; adres bazowy tablicy
		mov al, [bx+si]          ; pobierz cyfrę
		mov [di], al
		
		; Umieść drugą cyfrę (dla wszystkich wierszy oprócz 0)
		cmp si, 0
		je koniec_wiersza
		
		; Pozycja drugiej cyfry: (7-si) + 2*si
		mov di, OFFSET Tablica1 + 10  ; adres bufora
		mov cx, 7
		sub cx, si         ; cx = 7-si
		add cx, si
		add cx, si
		add di, cx         ; adres miejsca drugiej cyfry
		
		; Umieść drugą cyfrę
		mov bx, OFFSET Tablica1  ; adres bazowy tablicy
		mov al, [bx+si]          ; pobierz cyfrę
		mov [di], al
		
		jmp koniec_wiersza
		
ostatni_wiersz:
		; Ostatni wiersz - 15 znaków '7'
		mov di, OFFSET Tablica1 + 10  ; adres bufora
		
		; Umieść 15 znaków '7'
		mov cx, 15
		mov bx, OFFSET Tablica1  ; adres bazowy tablicy
		petla_siodemek:
			mov al, [bx+7]          ; pobierz znak '7'
			mov [di], al            ; umieść w linii
			inc di
		loop petla_siodemek
		
koniec_wiersza:
		; Wyświetl gotową linię
		mov dx, OFFSET Tablica1 + 10  ; adres bufora
		mov ah, 9
		int 21h
		
		; Przygotuj następny wiersz
		inc si
		mov cx, 8
		sub cx, si         ; zostało (8-si) wierszy
		cmp cx, 0
		jne petla_wierszy
		
		; Zakończenie programu
		mov al, 0
		mov ah, 4CH
		int 21H

rozkazy ENDS

END wystartuj 			; wykonanie programu zacznie się od rozkazu
				; opatrzonego etykietą wystartuj