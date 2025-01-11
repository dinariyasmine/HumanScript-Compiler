/*************************************** Fichier d'En-Tete pour la Table des Symboles *************************/
#ifndef TABLE_SYMBOLES_H
#define TABLE_SYMBOLES_H
#include <stddef.h> 
#include <stdlib.h> 
#include <string.h> 
#include <stdio.h> 
#include <stdbool.h>  // Include for bool type



#define TYPE_BOOLEAN 0
#define TYPE_INTEGER 1
#define TYPE_FLOAT 2
#define TYPE_STRING 3
#define TYPE_ARRAY 4
#define TYPE_DICT 6
#define TYPE_FUNCTION 7
#define TYPE_CONST 8

#define ROWS 128
#define COLS 32
#define MAX_NAME_LENGTH 64  // Maximum length for the name field
#define MAX_TYPE_LENGTH 32  // Maximum length for the type field

// Definitions de constantes
#define HASH_TABLE_SIZE 101 // Taille de la table de hachage (un nombre premier pour une meilleure distribution des hachages)

typedef struct {
    int length;     // Number of elements in the array
    void* elements; // Pointer to the array data (could be any type)
} ArrayType1;
// Union pour stocker la valeur du symbole
typedef union {
    int intValue;
    float floatValue;
    ArrayType1* arrayValue;
    char stringValue[MAX_NAME_LENGTH]; // Fixed-size array for string values
} SymbolValue;


// Structure representant une entree de symbole dans la table des symboles
typedef struct SymbolEntry {
    int id;                    // Identifiant unique pour le symbole
    char name[MAX_NAME_LENGTH]; // Nom lisible du symbole (fixed-size array)
    char type[MAX_TYPE_LENGTH]; // Type de donnees du symbole (fixed-size array)
    SymbolValue value;         // Valeur du symbole (union)
    bool isConst;              // Indique si le symbole est une constante
    bool isInitialized;        // Indique si le symbole est initialisé
    int scopeLevel;            // Niveau de portee du symbole
    struct SymbolEntry *next;  // Pointeur vers l'entree suivante pour la gestion des collisions (chainage dans les buckets)
} SymbolEntry;

// Structure representant la table des symboles
typedef struct SymbolTable {
    SymbolEntry *buckets[HASH_TABLE_SIZE]; // Tableau des buckets pour une recherche rapide
    int nextId;                            // Compteur pour generer des identifiants uniques pour les symboles
} SymbolTable;

SymbolTable *createSymbolTable();
void insertSymbol(SymbolTable *table, const char *name, const char *type, SymbolValue value, int scopeLevel, bool isConst, bool isInitialized);
SymbolEntry *lookupSymbolByName(SymbolTable *table, const char *name, int scopeLevel);
SymbolEntry *lookupSymbolById(SymbolTable *table, int id, int scopeLevel);
void deleteSymbolById(SymbolTable *table, int id);
void deleteSymbolByName(SymbolTable *table, const char *name);
void freeSymbolTable(SymbolTable *table);
void clearSymbolTable(SymbolTable *table);
int symbolExistsByName(SymbolTable *table, const char *name, int scopeLevel);
int symbolExistsById(SymbolTable *table, int id, int scopeLevel);
void listAllSymbols(SymbolTable *table);
void updateSymbolValue(SymbolTable *table, int id, SymbolValue newValue, int scopeLevel);
void freeSymbolEntry(SymbolEntry *entry);
void resizeSymbolTable(SymbolTable *table, int newSize);
#endif // TABLE_SYMBOLES_H