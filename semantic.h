#ifndef SEMANTIC_H
#define SEMANTIC_H
#include <stdbool.h>
#include "tableSymboles.h"



// on a besoin de cette structure car nous devons a un 
//certain moment stocker le type et la valeur en meme temps
typedef struct expression expression;
struct expression{
    int type;
    char stringValue[255];
    int integerValue;
    double floatValue;
    bool booleanValue;
    
};
typedef struct ArrayType {
    int elementType;    // Type of array elements
    size_t length;      // Current length of array
    size_t capacity;    // Allocated capacity
    SymbolValue* data;  // Dynamic array of values
} ArrayType;

typedef struct DictEntry {
    SymbolValue key;
    SymbolValue value;
    struct DictEntry* next;
} DictEntry;

typedef struct DictType {
    int keyType;        // Type of dictionary keys
    int valueType;      // Type of dictionary values
    size_t size;        // Number of entries
    DictEntry** buckets;// Hash table buckets
} DictType;

typedef struct variable variable;
struct variable{
    struct SymbolEntry* entry;
};

// this function is used for debugging mostly
void valeurToString(expression expression, char * valeur);
void handleTypeError(const char* expectedType, const char* gotType);
bool validateAndSetValue(SymbolValue* value, expression expr, int declaredType);
void initDefaultValue(SymbolValue* value, int type);
ArrayType* createArray(int elementType);
ArrayType* createArrayFromExprList(expression exprList);
void arrayPush(ArrayType* arr, SymbolValue value);
void freeArray(ArrayType* arr);
DictType* createDict(int keyType, int valueType);
DictType* createDictFromItems(expression items);
size_t hashValue(SymbolValue key, int keyType);
void dictSet(DictType* dict, SymbolValue key, SymbolValue value);
SymbolValue* dictGet(DictType* dict, SymbolValue key);
void freeDict(DictType* dict);
#endif // SEMANTIC_H
