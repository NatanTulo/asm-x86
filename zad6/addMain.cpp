#include <iostream>
#include <string> 
#include <limits> 
#include <cstring> 
#include <chrono> 
#include <iomanip> 
#include <cctype>
#include <vector>
#include <cstdio> 

using namespace std;
using namespace std::chrono;

extern "C" void count_char_frequencies_asm(const char* str, int* frequencies); // Zlicza częstotliwość liter w str (tylko litery a-z, case-insensitive)
extern "C" void bubble_sort(char* array, int length);  // sortuje tablicę znaków bąbelkowo

// Szablon funkcji do pobierania i walidowania danych numerycznych
template <typename T>
T getValidatedInput(const string& prompt) {
    T value;
    while (true) {
        cout << prompt;
        cin >> value;
        if (cin.good()) {
            cin.ignore(numeric_limits<streamsize>::max(), '\n'); // Usuń resztę linii
            return value;
        }
        cout << "Niepoprawna wartosc. Sprobuj ponownie." << endl;
        cin.clear();
        cin.ignore(numeric_limits<streamsize>::max(), '\n');
    }
}

// Funkcja do pobierania i walidowania pojedynczego znaku
char getValidatedChar(const string& prompt) {
    char value;
    string line;
    while (true) {
        cout << prompt;
        getline(cin, line); // Wczytuj całą linię
        if (line.length() == 1) { // Sprawdź, czy wprowadzono dokładnie jeden znak
            value = line[0];
            return value;
        }
        cout << "Niepoprawna wartosc. Wprowadz pojedynczy znak. Sprobuj ponownie." << endl;
    }
}

// Funkcja C++ do sortowania bąbelkowego
void bubble_sort_cpp(char* array, int length) {
    for (int i = 0; i < length - 1; i++) {
        for (int j = 0; j < length - i - 1; j++) {
            // Porównanie tylko według wartości liter, ignorując wielkość
            if (tolower(array[j]) > tolower(array[j + 1])) {
                // Zamień elementy
                char temp = array[j];
                array[j] = array[j + 1];
                array[j + 1] = temp;
            }
        }
    }
}

// Funkcja do pomiaru czasu wykonania sortowania
template<typename SortFunc>
double measureSortTime(SortFunc sortFunction, char* data, int length, const string& sortName) {
    // Stwórz kopię danych do sortowania
    char* dataCopy = new char[length + 1];
    strcpy(dataCopy, data);

    // Pomiar czasu
    auto start = high_resolution_clock::now();
    sortFunction(dataCopy, length);
    auto end = high_resolution_clock::now();

    // Oblicz czas w mikrosekundach
    auto duration = duration_cast<microseconds>(end - start);
    double timeInMicroseconds = duration.count();

    cout << sortName << " - wynik sortowania: \"" << dataCopy << "\"" << endl;
    cout << sortName << " - czas wykonania: " << fixed << setprecision(2)
        << timeInMicroseconds << " mikrosekund (" << timeInMicroseconds / 1000.0 << " ms)" << endl;

    delete[] dataCopy;
    return timeInMicroseconds;
}

// Funkcja pomocnicza do filtrowania tylko liter z stringa
string filterLettersOnly(const string& input) {
    string result;
    for (char c : input) {
        if ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')) {
            result += c;
        }
    }
    return result;
}

// Funkcja do konwersji systemu dziesiętnego na inny system (2-16) z użyciem ASM
void convertDecimalToBase(unsigned int decimal, int targetBase, char* result) {
    if (targetBase < 2 || targetBase > 16) {
        strcpy(result, "ERROR");
        return;
    }

    if (decimal == 0) {
        strcpy(result, "0");
        return;
    }

    char digits[] = "0123456789ABCDEF";
    char tempBuffer[33]; // Maksymalnie 32 znaki dla liczby binarnej + '\0'
    int index = 0;

    __asm {
        push eax
        push ebx
        push ecx
        push edx
        push esi
        push edi

        mov eax, [decimal]      // Liczba do konwersji
        mov ebx, [targetBase]   // Podstawa systemu docelowego
        lea edi, [tempBuffer]   // Wskaźnik na bufor tymczasowy
        mov ecx, 0              // Licznik cyfr

        ConvertLoop:
        test eax, eax           // Sprawdź czy liczba = 0
            jz ConvertDone

            xor edx, edx            // Wyczyść edx przed dzieleniem
            div ebx                 // eax = eax / ebx, edx = reszta

            push eax                // Zachowaj wynik dzielenia

            // Znajdź odpowiedni znak dla reszty
            lea esi, [digits]       // Wskaźnik na tablicę znaków
            add esi, edx            // Przejdź do odpowiedniego znaku
            mov dl, byte ptr[esi]  // Wczytaj znak
            mov byte ptr[edi + ecx], dl  // Zapisz znak w buforze

            pop eax                 // Przywróć wynik dzielenia
            inc ecx                 // Zwiększ licznik cyfr
            jmp ConvertLoop

            ConvertDone :
        mov[index], ecx        // Zapisz liczbę cyfr

            pop edi
            pop esi
            pop edx
            pop ecx
            pop ebx
            pop eax
    }

    // Odwróć kolejność cyfr (są zapisane od tyłu)
    for (int i = 0; i < index; i++) {
        result[i] = tempBuffer[index - 1 - i];
    }
    result[index] = '\0';
}



int main()
{
    // Analiza częstotliwości znaków w łańcuchu
    cout << "--- Analiza czestotliwosci znakow w lancuchu ---" << endl;
    cout << "Podaj lancuch znakow: ";
    string userInputString;
    getline(cin, userInputString);

    string lettersOnlyForFrequency = filterLettersOnly(userInputString);

    if (lettersOnlyForFrequency.empty()) {
        cout << "Nie wprowadzono zadnych liter do analizy!" << endl << endl;
    }
    else {
        cout << "Wprowadzony lancuch: \"" << userInputString << "\"" << endl;
        cout << "Lancuch po filtracji (tylko litery): \"" << lettersOnlyForFrequency << "\"" << endl;

        int charFrequencies[26] = { 0 }; // Tablica na liczniki dla a-z
        count_char_frequencies_asm(lettersOnlyForFrequency.c_str(), charFrequencies);

        cout << "Czestotliwosc wystepowania liter (a-z, bez rozrozniania wielkosci):" << endl;
        bool foundAny = false;
        for (int i = 0; i < 26; ++i) {
            if (charFrequencies[i] > 0) {
                cout << static_cast<char>('a' + i) << " - " << charFrequencies[i] << endl;
                foundAny = true;
            }
        }
        if (!foundAny) {
            cout << "Nie znaleziono liter w podanym ciagu." << endl;
        }
        cout << endl;
    }

    //*****************************************************

    // Sortowanie alfabetyczne - porównanie ASM vs C++
    cout << "--- Porownanie sortowania ASM vs C++ ---" << endl;
    cout << "Podaj tekst do posortowania: ";
    string textToSort;
    getline(cin, textToSort);

    // Filtruj tylko litery z wprowadzonego tekstu
    string lettersOnly = filterLettersOnly(textToSort);

    if (lettersOnly.empty()) {
        cout << "Nie wprowadzono zadnych liter do sortowania!" << endl << endl;
    }
    else {
        cout << "Tekst oryginalny: \"" << textToSort << "\"" << endl;
        cout << "Wyfiltrowane litery: \"" << lettersOnly << "\"" << endl;
        cout << "Dlugosc ciagu do sortowania: " << lettersOnly.length() << " znakow" << endl << endl;

        // Przygotuj bufor do sortowania
        char* sortData = new char[lettersOnly.length() + 1];
        strcpy(sortData, lettersOnly.c_str());

        cout << "=== POROWNANIE WYDAJNOSCI SORTOWANIA ===" << endl;

        // Test sortowania ASM
        double asmTime = measureSortTime(bubble_sort, sortData, static_cast<int>(lettersOnly.length()), "ASM Bubble Sort");
        cout << endl;

        // Test sortowania C++
        double cppTime = measureSortTime(bubble_sort_cpp, sortData, static_cast<int>(lettersOnly.length()), "C++ Bubble Sort");
        cout << endl;

        // Analiza wyników
        cout << "=== ANALIZA WYNIKOW ===" << endl;
        if (asmTime < cppTime) {
            double speedup = cppTime / asmTime;
            cout << "ASM jest szybsze o " << fixed << setprecision(2) << speedup << "x" << endl;
        }
        else if (cppTime < asmTime) {
            double speedup = asmTime / cppTime;
            cout << "C++ jest szybsze o " << fixed << setprecision(2) << speedup << "x" << endl;
        }
        else {
            cout << "Oba algorytmy maja podobna wydajnosc" << endl;
        }

        cout << "Roznica czasowa: " << fixed << setprecision(2)
            << abs(asmTime - cppTime) << " mikrosekund" << endl << endl;

        // Zwolnij pamięć
        delete[] sortData;
    }

    //*****************************************************

    // Kalkulator biletowy z danymi od użytkownika
    int adults;
    int children;
    int discount;
    int ticketPrice; // Zmienna na wynik obliczeń ASM

    const int ADULT_TICKET_PRICE = 25;
    const int CHILD_TICKET_PRICE = 15;
    const int HUNDRED = 100;

    cout << "--- Kalkulator biletowy ---" << endl;
    adults = getValidatedInput<int>("Podaj liczbe doroslych: ");
    children = getValidatedInput<int>("Podaj liczbe dzieci: ");
    discount = getValidatedInput<int>("Podaj procent znizki (np. 10 dla 10%): ");

    // Ceny biletów zdefiniowane jako stałe C++ powyżej
    __asm {
        push   eax
        push   ebx
        push   ecx
        push   edx
        push   esi
        push   edi

        // Oblicz koszt biletów dla dorosłych
        mov    eax, [adults]; adultCount
        mov    ebx, [ADULT_TICKET_PRICE]
        mul    ebx; eax = adultCount * ADULT_TICKET_PRICE
        mov    esi, eax; esi = adultsCost

        // Oblicz koszt biletów dla dzieci
        mov    eax, [children]; childCount
        mov    ebx, [CHILD_TICKET_PRICE]
        mul    ebx; eax = childCount * CHILD_TICKET_PRICE
        mov    edi, eax; edi = childrenCost

        // Suma kosztów przed zniżką
        add    esi, edi; esi = totalCostBeforeDiscount(esi = adultsCost + childrenCost)

        // Oblicz kwotę zniżki
        mov    eax, esi; eax = totalCostBeforeDiscount
        mov    ebx, [discount]; discountPercentage
        mul    ebx; edx:eax = totalCostBeforeDiscount * discountPercentage
        mov    ecx, [HUNDRED]
        div    ecx; eax = (totalCostBeforeDiscount * discountPercentage) / HUNDRED(kwota zniżki)
        ; edx = reszta(nieużywana)

        // Ostateczna cena
        sub    esi, eax; esi = totalCostBeforeDiscount - discountAmount
        mov[ticketPrice], esi; Zapisz ostateczną cenę do zmiennej C++

        pop    edi
        pop    esi
        pop    edx
        pop    ecx
        pop    ebx
        pop    eax
    }

    cout << "\n--- Podsumowanie biletow ---" << endl;
    cout << "Cena biletu dla doroslego: " << ADULT_TICKET_PRICE << " PLN" << endl;
    cout << "Cena biletu dla dziecka: " << CHILD_TICKET_PRICE << " PLN" << endl;
    cout << "Liczba doroslych: " << adults << endl;
    cout << "Liczba dzieci: " << children << endl;
    cout << "Zastosowana znizka: " << discount << "%" << endl;
    cout << "------------------------------------" << endl;
    cout << "Calkowity koszt biletow: " << ticketPrice << " PLN" << endl << endl;

    //*****************************************************

    // NOWY KALKULATOR SYSTEMÓW LICZBOWYCH
    cout << "--- Kalkulator konwersji z systemu dziesietnego ---" << endl;

    unsigned int decimalNum;
    int targetBase;
    char result[33];
    char continueChoice;

    do {
        decimalNum = getValidatedInput<unsigned int>("Podaj liczbe dziesietna do konwersji: ");

        do {
            targetBase = getValidatedInput<int>("Podaj docelowy system liczbowy (2-16): ");
            if (targetBase < 2 || targetBase > 16) {
                cout << "System musi byc w zakresie 2-16!" << endl;
            }
        } while (targetBase < 2 || targetBase > 16);

        convertDecimalToBase(decimalNum, targetBase, result);

        cout << "\n=== WYNIK KONWERSJI (ASM) ===" << endl;
        cout << decimalNum << " (dziesietny) = " << result << " (system " << targetBase << ")" << endl;

        // Dodatkowe informacje dla popularnych systemów
        switch (targetBase) {
        case 2:
            cout << "System binarny - uzywany w informatyce" << endl;
            break;
        case 8:
            cout << "System oktalny - rzadziej uzywany" << endl;
            break;
        case 16:
            cout << "System szesnastkowy - popularny w programowaniu" << endl;
            break;
        }

        continueChoice = getValidatedChar("\nChcesz wykonac kolejna konwersje? (t/n): ");
        cout << endl;

    } while (continueChoice == 't' || continueChoice == 'T');

    //*****************************************************

    // Rysowanie wzoru
    int patternCellSize;
    char lightSymbol, darkSymbol;

    cout << "\n--- Rysowanie wzoru ---" << endl;
    patternCellSize = getValidatedInput<int>("Podaj rozmiar boku wzoru (liczba komorek na bok): ");
    lightSymbol = getValidatedChar("Podaj znak jasny (np. '@'): ");
    darkSymbol = getValidatedChar("Podaj znak ciemny (np. '.'): ");

    const int HORIZONTAL_CHAR_MULTIPLIER = 2;
    cout << "\n--- Twoj wzor ---" << endl;

    __asm {
        // Zapisz rejestry, które będą modyfikowane
        push ebx
        push esi
        push edi

        // Inicjalizacja liczników pętli
        // esi będzie licznikiem i (wiersze)
        // edi będzie licznikiem j (kolumny)
        // ecx, eax, edx będą używane do obliczeń i jako liczniki/argumenty

        mov esi, 0          // i = 0
        OuterLoop_i:
        cmp esi, [patternCellSize]   // if (i >= patternCellSize) goto EndOuterLoop_i
            jge EndOuterLoop_i

            mov edi, 0          // j = 0
            InnerLoop_j :
            cmp edi, [patternCellSize]   // if (j >= patternCellSize) goto EndInnerLoop_j
            jge EndInnerLoop_j

            // Oblicz dist_i = min(i, patternCellSize - 1 - i)
            mov eax, [patternCellSize]
            dec eax
            sub eax, esi        // eax = patternCellSize - 1 - i
            mov ebx, esi        // ebx = i
            cmp ebx, eax        // Compare i with (patternCellSize - 1 - i)
            jle dist_i_is_i     // if i <= (patternCellSize - 1 - i), then dist_i = i
            mov ecx, eax        // else dist_i = (patternCellSize - 1 - i)
            jmp dist_i_done
            dist_i_is_i :
        mov ecx, ebx        // dist_i = i
            dist_i_done :
        // ecx przechowuje dist_i

        // Oblicz dist_j = min(j, patternCellSize - 1 - j)
        mov eax, [patternCellSize]
            dec eax
            sub eax, edi        // eax = patternCellSize - 1 - j
            mov ebx, edi        // ebx = j
            cmp ebx, eax        // Compare j with (patternCellSize - 1 - j)
            jle dist_j_is_j     // if j <= (patternCellSize - 1 - j), then dist_j = j
            mov edx, eax        // else dist_j = (patternCellSize - 1 - j)
            jmp dist_j_done
            dist_j_is_j :
        mov edx, ebx        // dist_j = j
            dist_j_done :
        // edx przechowuje dist_j

        // Oblicz distanceFromEdge = min(dist_i, dist_j)
        // dist_i jest w ecx, dist_j jest w edx
        mov eax, ecx        // eax = dist_i
            cmp eax, edx        // if (dist_i <= dist_j)
            jle dist_Edge_is_dist_i
            mov eax, edx        // distanceFromEdge = dist_j (w eax)
            jmp dist_Edge_done
            dist_Edge_is_dist_i :
        // distanceFromEdge = dist_i (w eax)
    dist_Edge_done:
        // eax przechowuje distanceFromEdge

        // Wybierz charToPrint na podstawie parzystości distanceFromEdge
        // (distanceFromEdge % 2 == 0) -> test najmłodszego bitu eax
        test eax, 1
            jnz IsOdd           // Jeśli nie zero (nieparzyste), skocz do IsOdd
            // Parzyste: charToPrint = lightSymbol
            mov bl, byte ptr[lightSymbol]
            jmp PrintCharLoopSetup
            IsOdd :
        // Nieparzyste: charToPrint = darkSymbol
        mov bl, byte ptr[darkSymbol]

            PrintCharLoopSetup :
            // Wydrukuj charToPrint (w bl) HORIZONTAL_CHAR_MULTIPLIER razy
            mov ecx, 0          // licznik k = 0
            Loop_k :
            cmp ecx, HORIZONTAL_CHAR_MULTIPLIER
            jge EndLoop_k

            // Zapisz ecx (licznik k), ponieważ putchar może go zmienić
            push ecx

            movzx eax, bl       // Rozszerz charToPrint (bl) do eax jako argument dla putchar
            push eax            // Przekaż argument na stos
            call putchar
            add esp, 4          // Zdejmij argument ze stosu (konwencja __cdecl)

            pop ecx             // Przywróć licznik k
            inc ecx             // k++
            jmp Loop_k
            EndLoop_k :

        inc edi             // j++
            jmp InnerLoop_j
            EndInnerLoop_j :

        // Wydrukuj nową linię po każdym wierszu komórek
        mov eax, 0Ah        // '\n' (ASCII 10)
            push eax
            call putchar
            add esp, 4

            inc esi             // i++
            jmp OuterLoop_i
            EndOuterLoop_i :

        // Przywróć rejestry callee-saved
        pop edi
            pop esi
            pop ebx
    }
    cout << endl; // Dodatkowa nowa linia po całym wzorze

    //*****************************************************

    // Kod generujący ciąg Fibonacciego
    cout << "--- Generator ciagu Fibonacciego ---" << endl;

    int fibLength;
    fibLength = getValidatedInput<int>("Podaj dlugosc ciagu Fibonacciego: ");

    if (fibLength <= 0) {
        cout << "Dlugosc musi byc wieksza od 0!" << endl;
    }
    else {
        long long* fibonacciNumbers = new long long[fibLength]; // Alokacja pamięci

        __asm {
            push esi
            push edi
            push ebx

            mov edi, [fibonacciNumbers] // Wskaźnik na początek tablicy fibonacciNumbers
            mov ecx, [fibLength]        // Długość ciągu w ecx

            // Jeśli fibLength == 0, nic nie rób (obsłużone przez C++ if)
            // Jeśli fibLength >= 1, ustaw F[0] = 0
            cmp ecx, 1
            jl SkipAllFib           // Mniejsze niż 1 (czyli 0), pomiń wszystko

            // Ustaw fibonacciNumbers[0] = 0
            mov dword ptr[edi], 0      // F[0] dolna część
            mov dword ptr[edi + 4], 0    // F[0] górna część

            // Jeśli fibLength >= 2, ustaw F[1] = 1
            cmp ecx, 2
            jl DoneFibGen           // Mniejsze niż 2 (czyli fibLength == 1), zakończ po F[0]

            // Ustaw fibonacciNumbers[1] = 1
            mov dword ptr[edi + 8], 1    // F[1] dolna część
            mov dword ptr[edi + 12], 0   // F[1] górna część

            // Jeśli fibLength <= 2, generowanie zakończone (F[0] i F[1] są ustawione)
            cmp ecx, 2
            jle DoneFibGen          // Mniejsze lub równe 2, zakończ

            // Główna pętla
            lea esi, [edi + 16]
            sub ecx, 2

            FibLoop_asm:
            // Oblicz F[i] = F[i-1] + F[i-2]
            mov eax, dword ptr[esi - 16] // F[i-2] dolna część
                mov edx, dword ptr[esi - 12] // F[i-2] górna część

                add eax, dword ptr[esi - 8]  // Dodaj F[i-1] dolna część
                adc edx, dword ptr[esi - 4]  // Dodaj F[i-1] górna część (z przeniesieniem)

                mov dword ptr[esi], eax    // Zapisz F[i] dolna część
                mov dword ptr[esi + 4], edx  // Zapisz F[i] górna część

                add esi, 8
                dec ecx
                jnz FibLoop_asm

                DoneFibGen :
        SkipAllFib:

            pop ebx
                pop edi
                pop esi
        }

        // Wyświetl wyniki
        cout << "\nCiag Fibonacciego (" << fibLength << " elementow wygenerowanych przez ASM):" << endl;
        for (int i = 0; i < fibLength; i++) {
            cout << "F(" << i << ") = " << fibonacciNumbers[i] << endl;
        }

        cout << "\nTablica zawiera " << fibLength << " liczb Fibonacciego." << endl << endl;

        delete[] fibonacciNumbers;
    }
    // Koniec generatora Fibonacciego

    return 0;
}