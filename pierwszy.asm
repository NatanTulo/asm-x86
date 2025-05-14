;   PROGRAM  "pierwszy.asm"

dane SEGMENT 	; segment danych
tekst 	db 13,10
	db 'Nazywam sie ...', 13, 10
	db 'moj pierwszy program asemblerowy'
	db 13,10
koniec_txt db ?
dane ENDS

rozkazy SEGMENT 'CODE' use16 	; segment zawierający rozkazy programu
		ASSUME cs:rozkazy, ds:dane
wystartuj:
		mov ax, SEG dane
		mov ds, ax
		mov cx, koniec_txt-tekst
		mov bx, OFFSET tekst 	; wpisanie do rejestru BX obszaru
					; zawierającego wyświetlany tekst
ptl:
		mov dl, [bx] 	; wpisanie do rejestru DL kodu ASCII
				; kolejnego wyświetlanego znaku
		mov ah, 2
		int 21H 	; wyświetlenie znaku za pomocą funkcji nr 2 DOS
		inc bx 		; inkrementacja adresu kolejnego znaku
loop ptl 			; sterowanie pętlą

		mov al, 0 	; kod powrotu programu (przekazywany przez
				; rejestr AL) stanowi syntetyczny opis programu
				; przekazywany do systemu operacyjnego
				; (zazwyczaj kod 0 oznacza, że program został
				; wykonany poprawnie)

		mov ah, 4CH 	; zakończenie programu – przekazanie sterowania
				; do systemu, za pomocą funkcji 4CH DOS
		int 21H
rozkazy ENDS

nasz_stos SEGMENT stack 	; segment stosu
dw 128 dup (?)
nasz_stos ENDS

END wystartuj 			; wykonanie programu zacznie się od rozkazu
				; opatrzonego etykietą wystartuj