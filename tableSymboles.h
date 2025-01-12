#ifndef TABLE_SYMBOLES_H
#define TABLE_SYMBOLES_H
#include <stddef.h> 
#include <stdlib.h> 
#include <string.h> 
#include <stdio.h> 
#include <stdbool.h>  

#define TYPE_BOOLEAN 0
#define TYPE_INTEGER 1
#define TYPE_FLOAT 2
#define TYPE_STRING 3
#define TYPE_ARRAY 4
#define MAX_NAME_LENGTH 64  
#define MAX_TYPE_LENGTH 32
#define MAX_VALUE_LENGTH 100  
#define HASH_TABLE_SIZE 101 

typedef struct ArrayType ArrayType;

typedef struct ArrayType {
    int elementType;   
    size_t length;     
    size_t capacity;    
    char** data;
} ArrayType;


typedef struct SymbolEntry {
    int id;
    char name[MAX_NAME_LENGTH];
    char type[MAX_TYPE_LENGTH];
    char value[MAX_NAME_LENGTH];
    bool isConst;
    bool isInitialized;
    int scopeLevel;
    struct SymbolEntry *next;
} SymbolEntry;

// Structure representant la table des symboles
typedef struct SymbolTable {
    SymbolEntry *buckets[HASH_TABLE_SIZE];
    int nextId;
} SymbolTable;

SymbolTable *createSymbolTable();
void insertSymbol(SymbolTable *table, const char *name, const char *type, const char *value, int scopeLevel, bool isConst, bool isInitialized);
SymbolEntry *lookupSymbolByName(SymbolTable *table, const char *name, int scopeLevel);
SymbolEntry *lookupSymbolById(SymbolTable *table, int id, int scopeLevel);
void deleteSymbolById(SymbolTable *table, int id);
void deleteSymbolByName(SymbolTable *table, const char *name);
void freeSymbolTable(SymbolTable *table);
void clearSymbolTable(SymbolTable *table);
int symbolExistsByName(SymbolTable *table, const char *name, int scopeLevel);
int symbolExistsById(SymbolTable *table, int id, int scopeLevel);
void listAllSymbols(SymbolTable *table);
void updateSymbolValue(SymbolTable *table, int id,const char *newValue, int scopeLevel);
void freeSymbolEntry(SymbolEntry *entry);
void resizeSymbolTable(SymbolTable *table, int newSize);
#endif 