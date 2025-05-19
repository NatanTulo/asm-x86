;   PROGRAM  "czwarty.asm"

dane SEGMENT 	; segment danych
tablica db 'aqrstuvwxyzbcdefmnopijqrstuvwxyz$'  ; 32-znakowa tablica z małymi literami zakończona '$'
nowa_linia db 13, 10, '$'                        ; sekwencja nowej linii
komunikat db 'Oryginalna tablica: $'
komunikat2 db 'Przeksztalcona tablica: $'
dane ENDS

rozkazy SEGMENT 'CODE' use16 	; segment zawierający rozkazy programu
        ASSUME cs:rozkazy, ds:dane

; Podprogram wyświetlający jeden znak na ekranie
; Wejście: DL - znak do wyświetlenia
wyswietl_znak PROC
        mov ah, 2    ; funkcja 2h przerwania 21h - wyświetl znak
        int 21h
        ret
wyswietl_znak ENDP

; Podprogram wyświetlający ciąg znaków na ekranie
; Wejście: DX - offset tablicy znakowej
wyswietl_ciag PROC
        mov ah, 9    ; funkcja 9h przerwania 21h - wyświetl ciąg zakończony '$'
        int 21h
        ret
wyswietl_ciag ENDP

; Podprogram kończący program
zakoncz_program PROC
        mov al, 0    ; kod powrotu 0 (prawidłowe zakończenie)
        mov ah, 4Ch  ; funkcja 4Ch przerwania 21h - zakończ program
        int 21h
        ret          ; ten ret nigdy nie zostanie wykonany
zakoncz_program ENDP

; Podprogram wyświetlający tablicę z zamienionymi literami q-z na cyfry 0-9
wyswietl_przeksztalcona PROC
        push si      ; zachowaj rejestr SI
        mov si, OFFSET tablica  ; adres tablicy do SI
        
petla_przeksztalcenie:
        mov al, [si]        ; pobierz znak
        cmp al, '$'         ; sprawdź czy koniec tablicy
        je koniec_przeksztalcenia
        
        ; Sprawdź czy znak jest w zakresie q-z
        cmp al, 'q'
        jb bez_zmian
        cmp al, 'z'
        ja bez_zmian
        
        ; Zamień literę na cyfrę
        sub al, 'q'         ; q -> 0, r -> 1, ..., z -> 9
        add al, '0'         ; Konwersja na ASCII cyfry
        mov [si], al        ; Zapisz przekształcony znak
        
bez_zmian:
        mov dl, [si]        ; pobierz znak (przekształcony lub nie) do DL
        call wyswietl_znak  ; wyświetl znak używając podprogramu wyswietl_znak
        
        inc si              ; przejdź do następnego znaku
        jmp petla_przeksztalcenie
        
koniec_przeksztalcenia:
        pop si              ; przywróć rejestr SI
        ret
wyswietl_przeksztalcona ENDP

wystartuj:
        mov ax, SEG dane
        mov ds, ax
        
        ; Wyświetl komunikat "Oryginalna tablica: "
        mov dx, OFFSET komunikat
        call wyswietl_ciag
        
        ; Wyświetl oryginalną tablicę
        mov dx, OFFSET tablica
        call wyswietl_ciag
        
        ; Wyświetl nową linię
        mov dx, OFFSET nowa_linia
        call wyswietl_ciag
        
        ; Wyświetl komunikat "Przeksztalcona tablica: "
        mov dx, OFFSET komunikat2
        call wyswietl_ciag
        
        ; Przekształć tablicę i wyświetl ją jednocześnie
        call wyswietl_przeksztalcona
        
        ; Wyświetl nową linię
        mov dx, OFFSET nowa_linia
        call wyswietl_ciag
        
        ; Zakończ program
        call zakoncz_program
rozkazy ENDS

nasz_stos SEGMENT stack 	; segment stosu
dw 128 dup (?)
nasz_stos ENDS

END wystartuj 			; wykonanie programu zacznie się od rozkazu
				; opatrzonego etykietą wystartuj