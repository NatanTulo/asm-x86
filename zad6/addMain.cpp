// Addem Main Program      (AddMain.cpp) 

#include <iostream>
#include <string> // Dodano dla std::string i std::getline
#include <limits> // Dodano dla std::numeric_limits
#include <cstring> // Dodano dla strcpy

using namespace std;

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
        getline(cin, line); // Wczytaj całą linię
        if (line.length() == 1) { // Sprawdź, czy wprowadzono dokładnie jeden znak
            value = line[0];
            return value;
        }
        cout << "Niepoprawna wartosc. Wprowadz pojedynczy znak. Sprobuj ponownie." << endl;
    }
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

    // Sortowanie alfabetyczne (fun3 - bubble sort)
    cout << "--- Sortowanie alfabetyczne liter (ASM) ---" << endl;
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

        // Przygotuj bufor do sortowania (kopia dla zachowania oryginału)
        char* sortBuffer = new char[lettersOnly.length() + 1];
        strcpy(sortBuffer, lettersOnly.c_str());

        // Wywołaj funkcję sortowania z ASM
        bubble_sort(sortBuffer, static_cast<int>(lettersOnly.length()));

        cout << "Litery posortowane alfabetycznie (ASM bubble sort): \"" << sortBuffer << "\"" << endl << endl;

        // Zwolnij pamięć
        delete[] sortBuffer;
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

    return 0;
}