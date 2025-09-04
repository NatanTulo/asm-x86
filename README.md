# asm-x86 (poglądowo)

Zbiór krótkich programów i procedur w asemblerze x86 pokazujących podstawowe techniki:

- 16‑bit DOS (real mode, `use16`, przerwania INT 21h) – proste I/O znakowe, pętle, operacje na buforach
- 32‑bit (flat model) procedury współpracujące z kodem C/C++ (MSVC) – sortowanie, zliczanie częstotliwości znaków, konwersja liczby do różnych podstaw
- Przykład prostego filtru FIR i narzędzia w Pythonie do weryfikacji wyniku ASM

Nie odtwarzamy dokładnego klucza „zadanie ↔ plik” – poniżej krótki opis funkcjonalny każdego elementu.

## Środowisko

Opcje uruchomienia / kompilacji:

1. Programy 16‑bit DOS (`pierwszy.asm`, `drugi.asm`, `trzeci.asm`, `czwarty.asm`, `piaty.asm`):
   - Składnia MASM/TASM (segmenty `dane`, `rozkazy`, `stack`).
   - Uruchamianie w DOSBox / emulacji, ewentualnie przy użyciu narzędzi takich jak `ml` + `link` (kompilacja do .EXE 16‑bit wymaga odpowiedniego toolchaina) lub emulator (np. dosbox). Batch `asembluj.bat` i `debaguj.bat` (jeśli dostarczone) mogą zawierać lokalne polecenia – tutaj pozostawione bez zmian.
2. Procedury 32‑bit w folderze `zad6/`:
   - Pliki mają dyrektywy `.386P`, `.model flat` i deklaracje `public _nazwa` zgodne z wywołaniami z MSVC (konwencja stdcall/cdecl przez ramkę EBP). Projekt Visual Studio: `Project.sln`, `Project.vcxproj`.
   - Do linkowania używana jest biblioteka `Irvine32.lib` (popularny zestaw pomocniczy dla nauki ASM). Wymaga Visual Studio (toolset 32‑bit) albo MASM dostarczonego z VS.

## Pliki 16‑bit DOS – skrócony opis

| Plik | Opis | Główne zagadnienia |
|------|------|--------------------|
| `pierwszy.asm` | Wypisanie kilku linii tekstu znak po znaku | Pętla ze sterowaniem `loop`, INT 21h funkcja 2 (wyświetlanie znaku) |
| `drugi.asm` | Dynamiczne budowanie i wypisywanie 8‑liniowego „trójkąta” z cyfr | Operacje na buforze, czyszczenie pamięci, adresowanie, warunek ostatniego wiersza |
| `trzeci.asm` | Konwersja liczby z systemu 9 (wejście max 4 cyfry) na system 6 | Wczytywanie znaków (INT 21h / AH=1), walidacja, Horner (podstawa 9), dzielenie przez 6 z resztą, wyświetlanie w odwrotnej kolejności |
| `czwarty.asm` | Modyfikacja tablicy: litery q‑z konwertowane na cyfry 0‑9 i wypisanie | Definicja i użycie podprogramów (`PROC`), iteracja po tablicy, warunkowa zamiana, modularność (wyswietl_znak, wyswietl_ciag) |
| `piaty.asm` | Filtr FIR: wejście 64 liczb (stdin / przekierowanie), filtracja 3‑tap (125,62,27)/256, wypisanie WE i WY | Własne procedury z parametrami na stosie, arytmetyka całkowita, dzielenie, konwersja liczby na ASCII, formatowanie kolumn |
| `piaty_verify_fir.py` | Skrypt Pythona sprawdzający poprawność implementacji filtru FIR (parsuje output) | Parsowanie tekstu, rekonstrukcja obliczeń, porównanie wyników |

Plik `dane.txt` może służyć jako źródło wejścia (przekierowanie: `piaty.exe < dane.txt > out.txt`). `OUT.TXT` prawdopodobnie przykładowy rezultat.

## Procedury 32‑bit w `zad6/`

| Plik | Opis | Zagadnienia |
|------|------|-------------|
| `_bubble_sort.asm` | Sortowanie bąbelkowe znaków (in‑place), porównanie bez rozróżniania wielkości liter | Pętle zewn./wewn., konwersja do wielkich liter przed porównaniem, rejestry ogólnego przeznaczenia |
| `_count_char_frequencies_asm.asm` | Zliczanie częstości liter a‑z w łańcuchu (case‑insensitive) | Indeksowanie `frequencies[index]`, arytmetyka na rejestrach 32‑bit, mnożenie indeksu przez 4 (skalowany adres) |
| `_number_conversion.asm` | Konwersja liczby bez znaku do systemu o podstawie 2‑16 (zwraca długość) | Dzielenie przez podstawę, przechowywanie reszt na stosie, mapowanie 10‑15 na A‑F, odwracanie kolejności |
| `addMain.cpp` | (Nie czytany tutaj – prawdopodobnie kod w C++ wywołujący powyższe procedury) | Integracja ASM <-> C++ |
| `Irvine32.lib` | Biblioteka pomocnicza (nie dokumentowana tutaj) | Wywołania usług systemowych, I/O |
| `Project.sln` / `Project.vcxproj` | Konfiguracja projektu Visual Studio | Budowanie MASM + C++ |

## Uruchamianie – przykłady

### Programy 16‑bit (DOS)

Przykład (DOSBox / system z narzędziami):

1. Asemblacja (przykładowo MASM – zależnie od konfiguracji lokalnej):
   `ml /c /Fl piaty.asm`
2. Linkowanie do EXE 16‑bit (wymaga odpowiednich narzędzi – opis zależny od środowiska; w wielu kursach dostarczony jest gotowy skrypt `asembluj.bat`).
3. Uruchomienie z przekierowaniem:
   `piaty.exe < dane.txt > out.txt`
4. Weryfikacja filtru:
   `python piaty_verify_fir.py out.txt`

### Procedury 32‑bit (`zad6`)

1. Otwórz `Project.sln` w Visual Studio (konfiguracja Win32, Debug lub Release).
2. Zbuduj rozwiązanie – Visual Studio wywoła MASM dla plików `.asm` oraz skompiluje C++.
3. Uruchom program C++ wywołujący procedury (np. test sortowania, konwersji, zliczania częstotliwości).

## Wzorce i dobre praktyki widoczne w kodzie

- Separacja sekcji: dane/kod/stos (16‑bit) vs model flat (32‑bit) – pokazanie różnic między real mode a protected/flat.
- Parametry przez stos i ramkę `bp` / `ebp` – konwencja wołania zgodna z interfesem C.
- Rejestry zachowywane/parowane push/pop – dbałość o czystość konwencji.
- Konwersje liczb: Horner dla wejścia w systemie 9; dzielenie z resztą do generowania cyfr w innych podstawach.
- Filtr FIR – implementacja deterministycznego przetwarzania sygnału z integer arithmetic (skalowanie /256), a następnie niezależna weryfikacja high‑level (Python).

## Możliwe rozszerzenia (opcjonalne pomysły)

- Dodanie testów automatycznych (np. skrypt batch wywołujący `piaty.exe` z kilkoma wejściami + porównanie przez Pythona).
- Uogólnienie filtru FIR (parametryzacja liczby współczynników i wartości w tablicy `COEFF*`).
- Dodanie README w `zad6/` z przykładowymi wywołaniami z C++.
- Komentarze w plikach batch (jeśli istnieją lokalnie) opisujące dokładnie kroki toolchaina.

## Krótkie wskazówki debugowania (16‑bit)

- Nieprawidłowy output często wynika z błędnej inicjalizacji DS – zawsze `mov ax, SEG dane` / `mov ds, ax` na początku.
- Przy dzieleniu (instrukcja `div`) pamiętaj o wyzerowaniu górnej części dzielnej: 16‑bit `xor dx, dx`; 32‑bit `xor edx, edx`.
- Gdy pętla nie kończy się oczekiwanie – sprawdź czy licznik (`cx`) nie jest nadpisywany wewnątrz.

---

Poglądowy opis gotowy. W razie potrzeby można doprecyzować instrukcje buildu (np. dodać konkretne polecenia dla MASM/TASM lub Visual Studio) – daj znać jeśli mam je rozszerzyć.
