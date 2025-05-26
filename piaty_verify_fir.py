import re
import sys

def parse_hex_table(lines, start_marker):
    """Parsuje tablicę hex z outputu programu ASM"""
    table = []
    found_start = False
    
    for line in lines:
        if start_marker in line:
            found_start = True
            continue
        
        if found_start:
            # Sprawdź czy to linia z danymi hex (zawiera cyfry/litery hex)
            if re.search(r'[0-9A-Fa-f]{4}', line):
                # Znajdź wszystkie 4-cyfrowe liczby hex w linii
                hex_numbers = re.findall(r'[0-9A-Fa-f]{4}', line)
                for hex_num in hex_numbers:
                    table.append(int(hex_num, 16))
            elif line.strip() == '' or 'Tablica' in line:
                # Koniec tej tablicy
                break
    
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
        result = (125 * input_data[i-1] + 62 * input_data[i-2] + 27 * input_data[i-3]) // 256
        output[i] = result
    
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
            print(f"  Element {i}: ASM={asm_val:04X}h ({asm_val}), Python={py_val:04X}h ({py_val})")
        if len(differences) > 10:
            print(f"  ... i {len(differences) - 10} więcej różnic")
        return False
    else:
        print("✓ Wszystkie wyniki są identyczne!")
        return True

def print_table_comparison(name, asm_data, python_data=None):
    """Wyświetla tablicę w formacie hex z opcjonalnym porównaniem"""
    print(f"\n{name}:")
    for i in range(0, len(asm_data), 8):
        line_asm = " ".join(f"{asm_data[j]:04X}" for j in range(i, min(i+8, len(asm_data))))
        print(f"  {line_asm}")
        
        if python_data:
            line_py = " ".join(f"{python_data[j]:04X}" for j in range(i, min(i+8, len(python_data))))
            if line_asm != line_py:
                print(f"  {line_py} <- Python (różnica!)")

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
    
    input_table = parse_hex_table(lines, "Tablica wejsciowa WE")
    output_table = parse_hex_table(lines, "Tablica wynikow WY")
    
    if not input_table:
        print("Błąd: Nie można znaleźć tablicy wejściowej w pliku")
        return
    
    if not output_table:
        print("Błąd: Nie można znaleźć tablicy wyników w pliku")
        return
    
    print(f"Wczytano tablicę wejściową: {len(input_table)} elementów")
    print(f"Wczytano tablicę wyników: {len(output_table)} elementów")
    
    # Oblicz wyniki w Pythonie
    print("\nObliczanie wyników w Pythonie...")
    python_results = fir_filter_python(input_table)
    
    if python_results is None:
        return
    
    # Porównaj wyniki
    print("\nPorównywanie wyników...")
    is_correct = compare_results(output_table, python_results)
    
    # Wyświetl szczegółowe porównanie
    print_table_comparison("Tablica wejściowa WE (hex)", input_table)
    print_table_comparison("Tablica wyników - porównanie ASM vs Python", 
                          output_table, python_results)
    
    if is_correct:
        print("\n🎉 Program ASM działa poprawnie!")
    else:
        print("\n❌ Znaleziono błędy w programie ASM")
        
        # Dodatkowa analiza dla pierwszych kilku elementów
        print("\nAnaliza szczegółowa pierwszych elementów:")
        for i in range(min(10, len(input_table))):
            if i < 3:
                print(f"wy[{i}] = we[{i}] = {input_table[i]:04X}h")
            else:
                manual_calc = (125 * input_table[i-1] + 62 * input_table[i-2] + 27 * input_table[i-3]) // 256
                print(f"wy[{i}] = (125*{input_table[i-1]:04X} + 62*{input_table[i-2]:04X} + 27*{input_table[i-3]:04X})/256")
                print(f"     = ({125 * input_table[i-1]} + {62 * input_table[i-2]} + {27 * input_table[i-3]})/256")
                print(f"     = {125 * input_table[i-1] + 62 * input_table[i-2] + 27 * input_table[i-3]}/256 = {manual_calc}")
                print(f"     ASM: {output_table[i]:04X}h ({output_table[i]}), Expected: {manual_calc:04X}h ({manual_calc})")

if __name__ == "__main__":
    main()
