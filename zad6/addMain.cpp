// Addem Main Program      (AddMain.cpp) 

#include <iostream>
#include <string> // Dodano dla std::string i std::getline
#include <limits> // Dodano dla std::numeric_limits
#include <cstring> // Dodano dla strcpy
#include <chrono> // Dodano dla pomiaru czasu
#include <iomanip> // Dodano dla formatowania wyjścia
#include <cctype>
#include <vector>

using namespace std;
using namespace std::chrono;

extern "C" int fun(int adultCount, int childCount, int discountPercentage); // Oblicza całkowity koszt biletów
extern "C" int fun2(const char* strx);				// zwraca długość łańcucha znaków strx (zmieniono na const char*)
extern "C" void bubble_sort(char* array, int length);  // sortuje tablicę znaków bąbelkowo
extern "C" void set_input_string(const char* input);   // ustawia string do sortowania w ASM
extern "C" char* read_and_sort_string();               // pobiera i sortuje string (zwraca wskaźnik)

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

// Funkcja C++ do rysowania wzoru
void drawPattern(int cellSize, char lightChar, char darkChar) {
    const int HORIZONTAL_CHAR_MULTIPLIER = 2; // Współczynnik kompensujący proporcje znaku (2:1 wysokość:szerokość)
    cout << "\n--- Twoj wzor ---" << endl;
    for (int i = 0; i < cellSize; ++i) { // Pętla po wierszach "komórek" wzoru
        for (int j = 0; j < cellSize; ++j) { // Pętla po kolumnach "komórek" wzoru
            char charToPrint;
            if ((i + j) % 2 == 0) { // Logika szachownicy dla komórek
                charToPrint = lightChar;
            }
            else {
                charToPrint = darkChar;
            }
            // Wydrukuj zwielokrotniony znak w poziomie dla bieżącej komórki
            for (int k = 0; k < HORIZONTAL_CHAR_MULTIPLIER; ++k) {
                cout << charToPrint;
            }
        }
        cout << endl; // Nowa linia po każdym wierszu komórek
    }
    cout << endl;
}


// Prosty generator ciągu Fibonacciego - funkcja C++
void generateFibonacci() {
    cout << "--- Generator ciAgu Fibonacciego (C++ vector) ---" << endl;

    int length = getValidatedInput<int>("Podaj d;ugosc ciagu Fibonacciego: ");

    if (length <= 0) {
        cout << "Dlugosc musi byc wieksza od 0!" << endl;
        return;
    }

    vector<long long> fibonacci;

    // Generuj ciąg Fibonacciego
    for (int i = 0; i < length; i++) {
        if (i == 0) {
            fibonacci.push_back(0);
        }
        else if (i == 1) {
            fibonacci.push_back(1);
        }
        else {
            long long next = fibonacci[i - 1] + fibonacci[i - 2];
            fibonacci.push_back(next);
        }
    }

    // Wyświetl wyniki
    cout << "\nCiag Fibonacciego (" << length << " elementOw):" << endl;
    for (int i = 0; i < fibonacci.size(); i++) {
        cout << "F(" << i << ") = " << fibonacci[i] << endl;
    }

    cout << "\nVector zawiera " << fibonacci.size() << " liczb Fibonacciego." << endl << endl;
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

int main()
{
    //******* FUNKCJE ASM *********
    // Kalkulator biletowy z danymi od użytkownika
    int adults;
    int children;
    int discount;

    cout << "--- Kalkulator biletowy ---" << endl;
    adults = getValidatedInput<int>("Podaj liczbe doroslych: ");
    children = getValidatedInput<int>("Podaj liczbe dzieci: ");
    discount = getValidatedInput<int>("Podaj procent znizki (np. 10 dla 10%): ");

    // Ceny biletów są zdefiniowane w fun.asm: Dorosły=25, Dziecko=15
    int ticketPrice = fun(adults, children, discount);

    cout << "\n--- Podsumowanie biletow ---" << endl;
    cout << "Cena biletu dla doroslego: 25 PLN (zdefiniowana w ASM)" << endl;
    cout << "Cena biletu dla dziecka: 15 PLN (zdefiniowana w ASM)" << endl;
    cout << "Liczba doroslych: " << adults << endl;
    cout << "Liczba dzieci: " << children << endl;
    cout << "Zastosowana znizka: " << discount << "%" << endl;
    cout << "------------------------------------" << endl;
    cout << "Calkowity koszt biletow: " << ticketPrice << " PLN" << endl << endl;

    //*****************************************************

    // Obliczanie długości łańcucha z danymi od użytkownika
    cout << "--- Kalkulator dlugosci lancucha ---" << endl;
    cout << "Podaj lancuch znakow: ";
    string userInputString;
    getline(cin, userInputString);

    cout << "Wprowadzony lancuch: \"" << userInputString << "\"" << endl;
    int string_length = fun2(userInputString.c_str());
    cout << "Dlugosc lancucha (obliczona przez fun2 z ASM): " << string_length << endl << endl;

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

    //******* FUNKCJE C++ *********
    // Rysowanie wzoru
    int patternCellSize;
    char lightSymbol, darkSymbol;

    cout << "--- Rysowanie wzoru (C++) ---" << endl;
    patternCellSize = getValidatedInput<int>("Podaj rozmiar boku wzoru (liczba komorek na bok): ");
    lightSymbol = getValidatedChar("Podaj znak jasny (np. '@'): ");
    darkSymbol = getValidatedChar("Podaj znak ciemny (np. '.'): ");

    drawPattern(patternCellSize, lightSymbol, darkSymbol);

    generateFibonacci();

    return 0;
}