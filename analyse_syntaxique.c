#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include "tableSymboles.h" 
#include <ctype.h>
#define MAX_SYMBOLS 100
#define MAX_TERMINALS 100
#define MAX_RULES 100
#define MAX_SET_SIZE 100
#define MAX_STACK_SIZE 100
#define MAX_INPUT_SIZE 1000

typedef struct {
    char* elements[MAX_SET_SIZE];
    int size;
} SymbolSet;


typedef struct {
    char* nonTerminal;
    char* terminal;
    char* production;
} TableEntry;

typedef struct {
    TableEntry* entries;
    int numEntries;
    char** terminals;
    int numTerminals;
    char** nonTerminals;
    int numNonTerminals;
    SymbolSet* debut;   
    SymbolSet* suivant;   
} ParseTable;
// New structure for the parser stack
typedef struct {
    char* items[MAX_STACK_SIZE];
    int top;
} ParserStack;

// Stack operations
void initStack(ParserStack* stack) {
    stack->top = -1;
}

void push(ParserStack* stack, const char* item) {
    if (stack->top < MAX_STACK_SIZE - 1) {
        stack->items[++stack->top] = strdup(item);
    }
}

char* pop(ParserStack* stack) {
    if (stack->top >= 0) {
        return stack->items[stack->top--];
    }
    return NULL;
}

char* peek(ParserStack* stack) {
    if (stack->top >= 0) {
        return stack->items[stack->top];
    }
    return NULL;
}
// Initialize a symbol set
void initSet(SymbolSet* set) {
    set->size = 0;
}
// Add an element to a set
void addToSet(SymbolSet* set, const char* element) {
    for (int i = 0; i < set->size; i++) {
        if (strcmp(set->elements[i], element) == 0) return;
    }
    set->elements[set->size] = strdup(element);
    set->size++;
}
// Initialize the parse table
ParseTable* initializeParseTable() {
    ParseTable* table = (ParseTable*)malloc(sizeof(ParseTable));
    table->entries = (TableEntry*)malloc(MAX_RULES * sizeof(TableEntry));
    table->terminals = (char**)malloc(MAX_TERMINALS * sizeof(char*));
    table->nonTerminals = (char**)malloc(MAX_SYMBOLS * sizeof(char*));
    table->debut = (SymbolSet*)malloc(MAX_SYMBOLS * sizeof(SymbolSet));
    table->suivant = (SymbolSet*)malloc(MAX_SYMBOLS * sizeof(SymbolSet));
    
    for (int i = 0; i < MAX_SYMBOLS; i++) {
        initSet(&table->debut[i]);
        initSet(&table->suivant[i]);
    }
    
    table->numEntries = 0;
    table->numTerminals = 0;
    table->numNonTerminals = 0;
    return table;
}

void initializeDebutAndSuivantSets(ParseTable* table) {
    int idxZ = 0;  // Index  Z
    int idxS = 1;  // Index S
    int idxA = 2;  // Index A
    int idxB = 3;  // Index B

    // DEBUT(A)
    addToSet(&table->debut[idxA], "INT");
    addToSet(&table->debut[idxA], "STR");
    addToSet(&table->debut[idxA], "CONST");
    addToSet(&table->debut[idxA], "FLOAT");
    addToSet(&table->debut[idxA], "BOOL");
    addToSet(&table->debut[idxA], "ARRAY");
    addToSet(&table->debut[idxA], "DICT");

    // DEBUT(B)
    addToSet(&table->debut[idxB], "ID");

    // DEBUT(S) = DEBUT(A)
    for (int i = 0; i < table->debut[idxA].size; i++) {
        addToSet(&table->debut[idxS], table->debut[idxA].elements[i]);
    }

    // DEBUT(Z) = DEBUT(S)
    for (int i = 0; i < table->debut[idxS].size; i++) {
        addToSet(&table->debut[idxZ], table->debut[idxS].elements[i]);
    }

    // SUIVANT sets
    addToSet(&table->suivant[idxZ], "#");    // SUIVANT(Z) = {#}
    addToSet(&table->suivant[idxS], "#");    // SUIVANT(S) = {#}
    addToSet(&table->suivant[idxA], "ID");   // SUIVANT(A) = {ID}
    addToSet(&table->suivant[idxB], "#");    // SUIVANT(B) = {#}
}
// Add an entry to the parse table
void addTableEntry(ParseTable* table, const char* nonTerminal, const char* terminal, const char* production) {
    TableEntry entry;
    entry.nonTerminal = strdup(nonTerminal);
    entry.terminal = strdup(terminal);
    entry.production = strdup(production);
    table->entries[table->numEntries++] = entry;
}
// Build the parse table
void buildParseTable(ParseTable* table) {
    const char* nonTerminals[] = {"Z", "S", "A", "B"};
    for (int i = 0; i < 4; i++) {
        table->nonTerminals[i] = strdup(nonTerminals[i]);
    }
    table->numNonTerminals = 4;

    const char* terminals[] = {"INT", "STR", "CONST", "FLOAT", "BOOL", "ARRAY", "DICT", "ID", "#"};
    for (int i = 0; i < 9; i++) {
        table->terminals[i] = strdup(terminals[i]);
    }
    table->numTerminals = 9;

    initializeDebutAndSuivantSets(table);

    // Z -> S #
    for (int i = 0; i < table->debut[0].size; i++) {
        addTableEntry(table, "Z", table->debut[0].elements[i], "S #");
    }
    
    // S -> A B
    for (int i = 0; i < table->debut[2].size; i++) {
        addTableEntry(table, "S", table->debut[2].elements[i], "A B");
    }

    // A's productions
    addTableEntry(table, "A", "INT", "INT");
    addTableEntry(table, "A", "STR", "STR");
    addTableEntry(table, "A", "CONST", "CONST");
    addTableEntry(table, "A", "FLOAT", "FLOAT");
    addTableEntry(table, "A", "BOOL", "BOOL");
    addTableEntry(table, "A", "ARRAY", "ARRAY");
    addTableEntry(table, "A", "DICT", "DICT");

    // B -> ID
    addTableEntry(table, "B", "ID", "ID");
}
// Print a set
void printSet(const char* setName, SymbolSet* set) {
    printf("%s: { ", setName);
    for (int i = 0; i < set->size; i++) {
        printf("%s", set->elements[i]);
        if (i < set->size - 1) printf(", ");
    }
    printf(" }\n");
}
// Print DEBUT sets
void printDebutSets(ParseTable* table) {
    printf("\nEnsembles DEBUT:\n");
    for (int i = 0; i < table->numNonTerminals; i++) {
        printSet(table->nonTerminals[i], &table->debut[i]);
    }
}
// Print SUIVANT sets
void printSuivantSets(ParseTable* table) {
    printf("\nEnsembles SUIVANT:\n");
    for (int i = 0; i < table->numNonTerminals; i++) {
        printSet(table->nonTerminals[i], &table->suivant[i]);
    }
}

void printtableAnalyseSyntaxique(ParseTable* table) {
    printf("\nTable d'analyse LL(1):\n\n");
    // En-tête
    printf("%-12s", "");
    for (int i = 0; i < table->numTerminals; i++) {
        printf("%-12s", table->terminals[i]);
    }
    printf("\n");
    // Ligne de séparation
    for (int i = 0; i < (table->numTerminals + 1) * 12; i++) {
        printf("-");
    }
    printf("\n");
    // Corps de la table
    for (int i = 0; i < table->numNonTerminals; i++) {
        printf("%-12s", table->nonTerminals[i]);
        
        for (int j = 0; j < table->numTerminals; j++) {
            bool found = false;
            for (int k = 0; k < table->numEntries; k++) {
                if (strcmp(table->entries[k].nonTerminal, table->nonTerminals[i]) == 0 &&
                    strcmp(table->entries[k].terminal, table->terminals[j]) == 0) {
                    printf("%-12s", table->entries[k].production);
                    found = true;
                    break;
                }
            }
            if (!found) {
                printf("%-12s", "erreur");
            }
        }
        printf("\n");
    }
}
// Free allocated memory
void freeParseTable(ParseTable* table) {
    for (int i = 0; i < table->numEntries; i++) {
        free(table->entries[i].nonTerminal);
        free(table->entries[i].terminal);
        free(table->entries[i].production);
    }
    for (int i = 0; i < table->numTerminals; i++) {
        free(table->terminals[i]);
    }
    for (int i = 0; i < table->numNonTerminals; i++) {
        free(table->nonTerminals[i]);
        for (int j = 0; j < table->debut[i].size; j++) {
            free(table->debut[i].elements[j]);
        }
        for (int j = 0; j < table->suivant[i].size; j++) {
            free(table->suivant[i].elements[j]);
        }
    }
    free(table->entries);
    free(table->terminals);
    free(table->nonTerminals);
    free(table->debut);
    free(table->suivant);
    free(table);
}
const char* getProduction(ParseTable* table, const char* nonTerminal, const char* terminal) {
    // Parcours des entrées de la table
    for (int i = 0; i < table->numEntries; i++) {
        // Si une entrée correspond à la combinaison non-terminal/terminal
        if (strcmp(table->entries[i].nonTerminal, nonTerminal) == 0 &&
            strcmp(table->entries[i].terminal, terminal) == 0) {
            // Retourne la production associée
            return table->entries[i].production;
        }
    }
    // Si aucune entrée ne correspond, retourne "erreur"
    return "erreur";
}

typedef struct {
    char** tokens;
    int count;
} TokenArray;

// Add this new function to validate identifiers
bool isValidIdentifier(const char* str) {
    if (!str || strlen(str) == 0) return false;
    
    // First character must be a letter or underscore
    if (!isalpha(str[0]) && str[0] != '_') return false;
    
    // Rest can be letters, numbers, or underscores
    for (int i = 1; str[i] != '\0'; i++) {
        if (!isalnum(str[i]) && str[i] != '_') return false;
    }
    
    // Check if it's not a reserved word
    const char* reservedWords[] = {"INT", "STR", "CONST", "FLOAT", "BOOL", "ARRAY", "DICT", "ID"};
    int numReserved = sizeof(reservedWords) / sizeof(reservedWords[0]);
    
    for (int i = 0; i < numReserved; i++) {
        if (strcasecmp(str, reservedWords[i]) == 0) return false;
    }
    
    return true;
}

// Modified tokenizeInput function to handle identifiers
TokenArray tokenizeInput(const char* input) {
    TokenArray result = {malloc(MAX_INPUT_SIZE * sizeof(char*)), 0};
    char* inputCopy = strdup(input);
    char* token = strtok(inputCopy, " \t\n");
    
    while (token != NULL) {
        // Check if this token should be treated as an identifier
        if (result.count > 0 && 
            strcmp(result.tokens[result.count-1], "ID") != 0 && 
            isValidIdentifier(token)) {
            // Save the original identifier
            char* identifier = strdup(token);
            // Add "ID" token
            result.tokens[result.count++] = strdup("ID");
            // Add the actual identifier
            result.tokens[result.count++] = identifier;
        } else {
            result.tokens[result.count++] = strdup(token);
        }
        token = strtok(NULL, " \t\n");
    }
    
    free(inputCopy);
    return result;
}

// Modified analyzeSyntax function
bool analyzeSyntax(ParseTable* table, const char* input, SymbolTable* symTable) {
    ParserStack stack;
    initStack(&stack);
    
    push(&stack, "#");
    push(&stack, "Z");
    
    TokenArray tokens = tokenizeInput(input);
    int currentToken = 0;
    
    tokens.tokens[tokens.count] = strdup("#");
    tokens.count++;
    
    char* currentIdentifier = NULL;
    char* currentType = NULL;
    
    while (stack.top >= 0) {
        char* X = peek(&stack);
        char* a = tokens.tokens[currentToken];
        
        printf("Stack top: %s, Current input: %s\n", X, a);
        
        if (strcmp(X, "#") == 0 && strcmp(a, "#") == 0) {
            printf("Analysis successful!\n");
            // Insert into symbol table if we have both type and identifier
            if (currentType != NULL && currentIdentifier != NULL) {
                insertSymbol(symTable, currentIdentifier, currentType, NULL, 1);
                printf("Inserted %s of type %s into symbol table\n", currentIdentifier, currentType);
            }
            return true;
        }
        
        bool isTerminal = false;
        for (int i = 0; i < table->numTerminals; i++) {
            if (strcmp(X, table->terminals[i]) == 0) {
                isTerminal = true;
                break;
            }
        }
        
        if (isTerminal) {
            if (strcmp(X, a) != 0) {
                printf("Error: Expected %s but got %s\n", X, a);
                return false;
            } else {
                // Store type and identifier information
                if (strcmp(X, "INT") == 0 || strcmp(X, "FLOAT") == 0 ||
                    strcmp(X, "STR") == 0 || strcmp(X, "BOOL") == 0 ||
                    strcmp(X, "ARRAY") == 0 || strcmp(X, "DICT") == 0 || strcmp(X, "CONST") == 0) {
                    currentType = strdup(X);
                }
                if (strcmp(X, "ID") == 0 && currentToken + 1 < tokens.count) {
                    currentIdentifier = strdup(tokens.tokens[currentToken + 1]);
                    currentToken++; // Skip the actual identifier
                }
                
                free(pop(&stack));
                currentToken++;
                continue;
            }
        }
        
        const char* production = getProduction(table, X, a);
        
        if (strcmp(production, "erreur") == 0) {
            printf("Error: No production found for %s with input %s\n", X, a);
            return false;
        }
        
        free(pop(&stack));
        
        char* prodCopy = strdup(production);
        char* symbol = strtok(prodCopy, " ");
        char* symbols[MAX_STACK_SIZE];
        int symbolCount = 0;
        
        while (symbol != NULL) {
            symbols[symbolCount++] = strdup(symbol);
            symbol = strtok(NULL, " ");
        }
        
        for (int i = symbolCount - 1; i >= 0; i--) {
            if (strcmp(symbols[i], "ε") != 0) {
                push(&stack, symbols[i]);
            }
            free(symbols[i]);
        }
        
        free(prodCopy);
    }
    
    // Clean up
    if (currentType) free(currentType);
    if (currentIdentifier) free(currentIdentifier);
    
    for (int i = 0; i < tokens.count; i++) {
        free(tokens.tokens[i]);
    }
    free(tokens.tokens);
    
    return false;
}
int main() {
    ParseTable* table = initializeParseTable();
    buildParseTable(table);
    
    // Initialize symbol table
    SymbolTable* symTable = createSymbolTable();
    
    // Example usage
    char input[1000];
    printf("Enter input string (e.g., 'INT myVar'): ");
    fgets(input, sizeof(input), stdin);
    input[strcspn(input, "\n")] = 0;  // Remove newline
    
    if (analyzeSyntax(table, input, symTable)) {
        printf("\nSymbol table after analysis:\n");
        listAllSymbols(symTable);
    }
    
  
    freeParseTable(table);
    
    
    return 0;
}