;   PROGRAM  "trzeci.asm"

dane SEGMENT 	;segment danych
tekst 	db 13,10
	db 'Podaj liczbe w systemie 9 (max 4 cyfry): ', 13,10
	db '$'
wynik_txt db 13,10
        db 'Liczba w systemie 6: '
        db '$'
Buf_1 db 4 dup (0)    ; bufor na liczbę w systemie dziewiątkowym
LBin dw 0             ; zmienna na liczbę binarną
Buf_2 db 128 dup (0)  ; bufor na liczbę w systemie szóstkowym
koniec_txt db ?
dane ENDS

rozkazy SEGMENT 'CODE' use16 	;segment zawierający rozkazy programu
		ASSUME cs:rozkazy, ds:dane
wystartuj:
		mov ax, SEG dane
		mov ds, ax
		
		; wyświetlenie komunikatu
		mov dx, OFFSET tekst
		mov ah, 9
		int 21h
		
		; wczytanie liczby dziewiątkowej (max 4 znaki)
		mov cx, 4       ; licznik znaków
		mov bx, OFFSET Buf_1
wczytaj_znak:
		mov ah, 1       ; funkcja wczytania znaku z echem
		int 21h
		
		cmp al, 13      ; czy Enter?
		je koniec_wczytywania
		
		cmp al, '0'     ; czy cyfra mniejsza od '0'?
		jb wczytaj_znak
		cmp al, '8'     ; czy cyfra większa od '8'? (system 9)
		ja wczytaj_znak
		
		sub al, '0'     ; konwersja ASCII na wartość cyfry
		mov [bx], al    ; zapisz cyfrę do bufora
		inc bx          ; przejdź do następnej pozycji
		loop wczytaj_znak
		
koniec_wczytywania:
		mov byte ptr [bx], 0         ; zakończenie łańcucha
		mov si, OFFSET Buf_1
		mov cx, bx
		sub cx, si                   ; CX = liczba wczytanych cyfr
		mov bx, OFFSET Buf_1
		mov ax, 0                   ; wynik początkowy
		
		; konwersja z systemu 9 na binarny (Horner)
horner_loop:
		mov dx, 9       ; mnożnik dla systemu 9
		mul dx          ; AX = AX * 9
		mov dl, [bx]    ; pobierz cyfrę
		mov dh, 0
		add ax, dx      ; dodaj cyfrę do wyniku
		inc bx          ; przejdź do następnej cyfry
		loop horner_loop
		mov LBin, ax    ; zapisz wynik konwersji
		
		; konwersja na system szóstkowy (dzielenie)
		mov bx, OFFSET Buf_2
		mov cx, 0       ; licznik cyfr
		
		; sprawdź czy liczba jest zerem
		cmp ax, 0
		jne dzielenie_loop
		
		; jeśli zero, zapisz jedną cyfrę 0
		mov byte ptr [bx], 0
		inc cx
		jmp koniec_dzielenia
		
dzielenie_loop:
		cmp ax, 0       ; czy liczba już jest zerem?
		je koniec_dzielenia
		
		mov dx, 0       ; zeruj DX dla operacji dzielenia
		mov si, 6       ; dzielnik (system 6)
		div si          ; DX:AX / SI = AX z resztą w DX
		
		mov [bx], dl    ; zapisz resztę (cyfrę systemu 6)
		inc bx          ; przejdź do następnej pozycji
		inc cx          ; zwiększ licznik cyfr
		jmp dzielenie_loop
		
koniec_dzielenia:
		; wyświetl komunikat o wyniku
		mov dx, OFFSET wynik_txt
		mov ah, 9
		int 21h
		
		; wyświetl liczbę w systemie 6 (od końca bufora)
		mov bx, OFFSET Buf_2
		add bx, cx      ; przejdź na koniec zapisanych cyfr
		dec bx          ; ostatnia cyfra
		
		; sprawdź czy są wiodące zera
pomijanie_zer:
		cmp byte ptr [bx], 0    ; czy cyfra to zero?
		jne wyswietl_cyfry      ; jeśli nie, wyświetl cyfry
		dec bx                  ; pomiń zero wiodące
		dec cx                  ; zmniejsz licznik
		cmp cx, 1               ; czy została ostatnia cyfra?
		jg pomijanie_zer        ; jeśli tak, kontynuuj pomijanie
		
wyswietl_cyfry:
		mov dl, [bx]    ; pobierz cyfrę
		add dl, '0'     ; konwersja na ASCII
		mov ah, 2       ; funkcja wyświetlenia znaku
		int 21h
		
		dec bx          ; przejdź do poprzedniej (mniej znaczącej) cyfry
		loop wyswietl_cyfry
		
		mov al, 0 	    ; kod powrotu programu
		mov ah, 4CH 	; zakończenie programu
		int 21H

rozkazy ENDS

END wystartuj 			;wykonanie programu zacznie się od rozkazu
				;opatrzonego etykietą wystartuj