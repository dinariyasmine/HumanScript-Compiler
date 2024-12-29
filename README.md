### Compilation and Execution Steps (Commands)

1. **Generate the syntax analysis files** using Bison:
   ```bash
   bison -d syntaxique.y
   ```

2. **Generate the lexical analysis files** using Flex:
   ```bash
   flex lexical.l
   ```

3. **Compile the generated files** into an executable named `compiler`:
   ```bash
   gcc lex.yy.c syntaxique.tab.c -o compiler
   ```

4. **Run the compiler**:
   ```bash
   ./compiler
   ```

5. **Compile the syntax analysis program**:
   ```bash
   gcc analyse_syntaxique.c tableSymboles.c -o analyse_syntaxique
   ```

6. **Run the syntax analysis program**:
   ```bash
   ./analyse_syntaxique
   ```
