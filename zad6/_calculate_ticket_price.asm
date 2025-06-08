title Ticket Calculator Subroutine (_calculate_ticket_price.asm)

; This subroutine links to Visual C++.
; Calculates total ticket price.
; Args: [ebp+8] = adultCount, [ebp+12] = childCount, [ebp+16] = discountPercentage

.386P
.model flat
public _calculate_ticket_price

ADULT_TICKET_PRICE equ 25  ; Cena biletu dla dorosłego
CHILD_TICKET_PRICE equ 15  ; Cena biletu dla dziecka
HUNDRED            equ 100 ; Stała do dzielenia przez 100 dla procentów

.code
_calculate_ticket_price proc near   ; int calculate_ticket_price(int adultCount, int childCount, int discountPercentage)
    push   ebp
    mov    ebp, esp
    push   ebx          ; Zachowaj ebx
    push   ecx          ; Zachowaj ecx
    push   edx          ; Zachowaj edx
    push   esi          ; Zachowaj esi
    push   edi          ; Zachowaj edi

    ; Oblicz koszt biletów dla dorosłych
    mov    eax, [ebp+8]      ; adultCount (pierwszy argument)
    mov    ebx, ADULT_TICKET_PRICE
    mul    ebx               ; eax = adultCount * ADULT_TICKET_PRICE
    mov    esi, eax          ; esi = adultsCost

    ; Oblicz koszt biletów dla dzieci
    mov    eax, [ebp+12]     ; childCount (drugi argument)
    mov    ebx, CHILD_TICKET_PRICE
    mul    ebx               ; eax = childCount * CHILD_TICKET_PRICE
    mov    edi, eax          ; edi = childrenCost

    ; Suma kosztów przed zniżką
    add    esi, edi          ; esi = totalCostBeforeDiscount (esi = adultsCost + childrenCost)

    ; Oblicz kwotę zniżki
    mov    eax, esi          ; eax = totalCostBeforeDiscount
    mov    ebx, [ebp+16]     ; discountPercentage (trzeci argument)
    mul    ebx               ; edx:eax = totalCostBeforeDiscount * discountPercentage
    mov    ecx, HUNDRED
    div    ecx               ; eax = (totalCostBeforeDiscount * discountPercentage) / 100 (kwota zniżki)
                           ; edx = reszta (nieużywana)

    ; Ostateczna cena
    sub    esi, eax          ; esi = totalCostBeforeDiscount - discountAmount
    mov    eax, esi          ; Zwróć ostateczną cenę w eax

    pop    edi
    pop    esi
    pop    edx
    pop    ecx
    pop    ebx
    pop    ebp
    ret                   
_calculate_ticket_price endp
end

