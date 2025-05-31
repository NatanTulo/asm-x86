import re
import sys

def parse_decimal_table(lines, start_marker):
    """Parsuje tablicę liczb dziesiętnych z outputu programu ASM"""
    table = []
    found_start = False
    
    for line in lines:
        if not found_start:
            if start_marker in line:
                found_start = True
                # Sprawdź, czy linia ze znacznikiem startowym również zawiera liczby
                # (na tej samej linii co np. "Tablica we:")
                # W tym konkretnym formacie, liczby zaczynają się od następnej linii,
                # ale dodajemy to dla ogólności.
                # Jeśli liczby są ZAWSZE w następnej linii, można by tu dać 'continue'.
                # Aktualnie, jeśli "Tablica we: 1 2 3" to 1 2 3 zostaną sparsowane.
                # Jeśli "Tablica we:" i liczby w następnej linii, to ta linia zostanie pominięta
                # przez 'continue' poniżej, jeśli nie ma cyfr.
                pass # Pozwól na przetworzenie tej linii, jeśli zawiera liczby
            else:
                continue # Szukaj dalej znacznika startowego
        
        # Jesteśmy w sekcji tabeli (found_start is True)
        if re.search(r'\d', line): # Jeśli linia zawiera jakąkolwiek cyfrę
            decimal_numbers = re.findall(r'\b\d+\b', line)
            for dec_num_str in decimal_numbers:
                try:
                    table.append(int(dec_num_str))
                except ValueError:
                    print(f"Ostrzeżenie: Nie można przekonwertować '{dec_num_str}' na liczbę w linii: {line.strip()}")
        elif found_start: 
            # Jeśli znaleźliśmy początek tabeli, a bieżąca linia nie zawiera cyfr,
            # oznacza to koniec danych dla tej tabeli.
            # (np. pusta linia lub nagłówek następnej tabeli)
            # Ale tylko jeśli już coś wczytaliśmy do tabeli, aby uniknąć przerwania
            # na linii z samym markerem, jeśli nie zawierała ona od razu liczb.
            if table: # Jeśli tabela ma już jakieś elementy
                break
            # Jeśli tabela jest pusta, a linia nie ma cyfr (np. linia z samym markerem),
            # kontynuuj, aby liczby mogły być w następnej linii.
            # Jeśli marker był np. "Tablica we:" i liczby są w następnej linii,
            # to ta linia (z markerem) nie doda nic do `table`, `table` będzie pusta,
            # i nie przerwiemy tutaj, pozwalając następnej iteracji pętli wczytać liczby.

    return table

def fir_filter_python(input_data):
    """Implementacja filtru FIR w Pythonie"""
    if len(input_data) < 64:
        print(f"Błąd: Tablica wejściowa ma {len(input_data)} elementów, oczekiwano 64")
        return None
    
    output = [0] * 64
    
    # Kopiowanie pierwszych trzech elementów bez zmian
    output[0] = input_data[0]
    output[1] = input_data[1] 
    output[2] = input_data[2]
    
    # Filtrowanie dla i = 3, ..., 63
    for i in range(3, 64):
        # wyi = (125*xi-1)/256 + (62*xi-2)/256 + (27*xi-3)/256
        # Ważne: używamy dzielenia całkowitego //, tak jak w ASM (mul -> dx:ax, div -> ax)
        term1 = (125 * input_data[i-1]) // 256
        term2 = (62 * input_data[i-2]) // 256
        term3 = (27 * input_data[i-3]) // 256
        output[i] = term1 + term2 + term3
    
    return output

def compare_results(asm_output, python_output):
    """Porównuje wyniki z ASM i Pythona"""
    if len(asm_output) != len(python_output):
        print(f"Błąd: Różne rozmiary tablic (ASM: {len(asm_output)}, Python: {len(python_output)})")
        return False
    
    differences = []
    for i in range(len(asm_output)):
        if asm_output[i] != python_output[i]:
            differences.append((i, asm_output[i], python_output[i]))
    
    if differences:
        print(f"Znaleziono {len(differences)} różnic:")
        for i, asm_val, py_val in differences[:10]:  # Pokaż max 10 różnic
            print(f"  Element {i}: ASM={asm_val}, Python={py_val}")
        if len(differences) > 10:
            print(f"  ... i {len(differences) - 10} więcej różnic")
        return False
    else:
        print("✓ Wszystkie wyniki są identyczne!")
        return True

def print_table_comparison(name, asm_data, python_data=None):
    """Wyświetla tablicę w formacie dziesiętnym z opcjonalnym porównaniem"""
    print(f"\n{name}:")
    for i in range(0, len(asm_data), 8): # Wyświetlaj 8 liczb w linii
        line_asm_parts = []
        for j in range(i, min(i+8, len(asm_data))):
            line_asm_parts.append(f"{asm_data[j]:>5}") # Wyrównaj do 5 znaków
        line_asm = " ".join(line_asm_parts)
        print(f"  {line_asm}")
        
        if python_data:
            line_py_parts = []
            mismatch_in_line = False
            for j in range(i, min(i+8, len(python_data))):
                line_py_parts.append(f"{python_data[j]:>5}")
                if j < len(asm_data) and asm_data[j] != python_data[j]:
                    mismatch_in_line = True
            line_py = " ".join(line_py_parts)
            
            if mismatch_in_line: # line_asm != line_py: # Prostsze porównanie może być mylące przez formatowanie
                print(f"  {line_py} <- Python {'(różnica!)' if mismatch_in_line else ''}")


def main():
    if len(sys.argv) != 2:
        print("Użycie: python verify_fir.py <plik_wyjsciowy_asm.txt>")
        print("\nAby użyć:")
        print("1. Uruchom program ASM i przekieruj wyjście do pliku:")
        print("   piaty.exe > output.txt")
        print("2. Uruchom ten skrypt:")
        print("   python verify_fir.py output.txt")
        return
    
    filename = sys.argv[1]
    
    try:
        with open(filename, 'r', encoding='utf-8') as f:
            lines = f.readlines()
    except FileNotFoundError:
        print(f"Błąd: Nie można znaleźć pliku {filename}")
        return
    except UnicodeDecodeError:
        # Spróbuj inne kodowania
        try:
            with open(filename, 'r', encoding='cp852') as f:
                lines = f.readlines()
        except:
            with open(filename, 'r', encoding='latin-1') as f:
                lines = f.readlines()
    
    # Parsowanie tablic z outputu ASM
    print("Parsowanie danych z pliku ASM...")
    
    input_table = parse_decimal_table(lines, "Tablica we:")
    output_table = parse_decimal_table(lines, "Tablica wy:")
    
    if not input_table:
        print("Błąd: Nie można znaleźć tablicy wejściowej w pliku")
        return
    
    if not output_table:
        print("Błąd: Nie można znaleźć tablicy wyników w pliku")
        return
    
    print(f"Wczytano tablicę wejściową: {len(input_table)} elementów")
    print(f"Wczytano tablicę wyników: {len(output_table)} elementów")

    if len(input_table) != 64:
        print(f"Ostrzeżenie: Tablica wejściowa 'we' powinna mieć 64 elementy, ma {len(input_table)}")
    if len(output_table) != 64:
        print(f"Ostrzeżenie: Tablica wynikowa 'wy' powinna mieć 64 elementy, ma {len(output_table)}")

    # Oblicz wyniki w Pythonie
    print("\nObliczanie wyników w Pythonie...")
    python_results = fir_filter_python(input_table)
    
    if python_results is None:
        return
    
    # Porównaj wyniki
    print("\nPorównywanie wyników...")
    is_correct = compare_results(output_table, python_results)
    
    # Wyświetl szczegółowe porównanie
    print_table_comparison("Tablica wejściowa WE (dziesiętnie)", input_table)
    print_table_comparison("Tablica wyników - porównanie ASM vs Python (dziesiętnie)", 
                          output_table, python_results)
    
    if is_correct:
        print("\n🎉 Program ASM działa poprawnie!")
    else:
        print("\n❌ Znaleziono błędy w programie ASM")
        
        # Dodatkowa analiza dla pierwszych kilku elementów
        print("\nAnaliza szczegółowa pierwszych elementów (dziesiętnie):")
        for i in range(min(10, len(input_table))): # Pokaż do 10 elementów
            if i < 3:
                print(f"wy[{i}] = we[{i}] = {input_table[i]}")
            else:
                term1_val = (125 * input_table[i-1])
                term2_val = (62 * input_table[i-2])
                term3_val = (27 * input_table[i-3])
                
                term1_div = term1_val // 256
                term2_div = term2_val // 256
                term3_div = term3_val // 256
                
                manual_calc = term1_div + term2_div + term3_div

                print(f"wy[{i}]:")
                print(f"  we[i-1]={input_table[i-1]}, we[i-2]={input_table[i-2]}, we[i-3]={input_table[i-3]}")
                print(f"  Term1: (125 * {input_table[i-1]}) / 256 = {term1_val} / 256 = {term1_div}")
                print(f"  Term2: (62 * {input_table[i-2]}) / 256 = {term2_val} / 256 = {term2_div}")
                print(f"  Term3: (27 * {input_table[i-3]}) / 256 = {term3_val} / 256 = {term3_div}")
                print(f"  Suma = {term1_div} + {term2_div} + {term3_div} = {manual_calc}")
                print(f"  ASM: {output_table[i]}, Oczekiwane (Python): {manual_calc}")
                if i < len(output_table) and output_table[i] != manual_calc:
                    print(f"  RÓŻNICA!")
                print("-" * 20)

if __name__ == "__main__":
    main()
