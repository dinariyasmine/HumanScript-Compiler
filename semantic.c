#include "semantic.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>


void valeurToString(expression expression, char * valeur){
    switch (expression.type){
        case TYPE_INTEGER:
            sprintf(valeur, "%d", expression.integerValue);
            break;
        case TYPE_FLOAT:
            sprintf(valeur, "%.4f", expression.floatValue);
            break;
        case TYPE_STRING:
            sprintf(valeur, "%s", expression.stringValue);
            break;
        case TYPE_BOOLEAN:
            sprintf(valeur, "%s", expression.booleanValue ? "true" : "false");
            break;
        case TYPE_CONST:
            sprintf(valeur, "const");
            break;
        
        default:
            sprintf(valeur, "Unknown type");
            break;
    }
}
void getTypeString(int type, char* typeStr) {
    switch(type) {
        case TYPE_INTEGER: strncpy(typeStr, "int", MAX_TYPE_LENGTH - 1); break;
        case TYPE_FLOAT: strncpy(typeStr, "float", MAX_TYPE_LENGTH - 1); break;
        case TYPE_STRING: strncpy(typeStr, "string", MAX_TYPE_LENGTH - 1); break;
        case TYPE_BOOLEAN: strncpy(typeStr, "bool", MAX_TYPE_LENGTH - 1); break;
        case TYPE_ARRAY: strncpy(typeStr, "array", MAX_TYPE_LENGTH - 1); break;
        case TYPE_DICT: strncpy(typeStr, "dict", MAX_TYPE_LENGTH - 1); break;
        default: strncpy(typeStr, "unknown", MAX_TYPE_LENGTH - 1);
    }
    typeStr[MAX_TYPE_LENGTH - 1] = '\0';
}

bool validateAndSetValue(SymbolValue* value, expression expr, int declaredType) {
    if (expr.type != declaredType) {
        char expectedType[20], gotType[20];
        getTypeString(declaredType, expectedType);
        getTypeString(expr.type, gotType);
        handleTypeError(expectedType, gotType);
        return false;
    }

    switch(declaredType) {
        case TYPE_INTEGER:
            value->intValue = expr.integerValue;
            break;
        case TYPE_FLOAT:
            value->floatValue = expr.floatValue;
            break;
        case TYPE_STRING:
            strncpy(value->stringValue, expr.stringValue, MAX_NAME_LENGTH - 1);
            value->stringValue[MAX_NAME_LENGTH - 1] = '\0';
            break;
        case TYPE_BOOLEAN:
            value->intValue = expr.booleanValue ? 1 : 0;
            break;
        default:
            return false;
    }
    return true;
}

void initDefaultValue(SymbolValue* value, int type) {
    switch(type) {
        case TYPE_INTEGER:
            value->intValue = 0;
            break;
        case TYPE_FLOAT:
            value->floatValue = 0.0;
            break;
        case TYPE_STRING:
            value->stringValue[0] = '\0';
            break;
        case TYPE_BOOLEAN:
            value->intValue = 0;  // false
            break;
        case TYPE_ARRAY:
        case TYPE_DICT:
            // Initialize to empty container
            value->intValue = 0;  // Use as a pointer/reference to actual container
            break;
    }
}

void handleTypeError(const char* expectedType, const char* gotType) {
    char errorMsg[256];
    snprintf(errorMsg, sizeof(errorMsg), "Type mismatch: Expected %s, got %s", 
             expectedType, gotType);
    yyerror(errorMsg);
}

// Add to semantic.c

/* Array Operations */
ArrayType* createArray(int elementType) {
    ArrayType* arr = malloc(sizeof(ArrayType));
    if (!arr) {
        printf("Failed to allocate array\n");
        return NULL;
    }
    
    arr->elementType = elementType;
    arr->length = 0;
    arr->capacity = 10;  // Initial capacity
    arr->data = malloc(arr->capacity * sizeof(SymbolValue));
    
    if (!arr->data) {
        printf("Failed to allocate array data\n");
        free(arr);
        return NULL;
    }
    
    return arr;
}

ArrayType* createArrayFromExprList(expression exprList) {
    // This function would be called from your parser when creating an array literal
    // The expression list would be passed in from your grammar rules
    ArrayType* arr = createArray(exprList.type);  // Use first element's type
    if (!arr) return NULL;
    
    // You'll need to implement logic to iterate through your expression list
    // and add each element to the array
    // This will depend on how you're storing the expression list in your parser
    
    return arr;
}

void arrayPush(ArrayType* arr, SymbolValue value) {
    if (!arr) return;
    
    // Check if we need to grow the array
    if (arr->length >= arr->capacity) {
        size_t newCapacity = arr->capacity * 2;
        SymbolValue* newData = realloc(arr->data, newCapacity * sizeof(SymbolValue));
        if (!newData) {
            printf("Failed to resize array\n");
            return;
        }
        arr->data = newData;
        arr->capacity = newCapacity;
    }
    
    // Add the new value
    arr->data[arr->length] = value;
    arr->length++;
}

void freeArray(ArrayType* arr) {
    if (!arr) return;
    free(arr->data);
    free(arr);
}

/* Dictionary Operations */
DictType* createDict(int keyType, int valueType) {
    DictType* dict = malloc(sizeof(DictType));
    if (!dict) {
        printf("Failed to allocate dictionary\n");
        return NULL;
    }
    
    dict->keyType = keyType;
    dict->valueType = valueType;
    dict->size = 0;
    dict->buckets = calloc(HASH_TABLE_SIZE, sizeof(DictEntry*));
    
    if (!dict->buckets) {
        printf("Failed to allocate dictionary buckets\n");
        free(dict);
        return NULL;
    }
    
    return dict;
}

DictType* createDictFromItems(expression items) {
    // This function would be called from your parser when creating a dictionary literal
    // The items expression would contain key-value pairs from your grammar rules
    // You'll need to implement the logic to process these based on your grammar structure
    
    // For now, we'll just create an empty dictionary
    return createDict(TYPE_STRING, TYPE_STRING); // Default types, adjust as needed
}

size_t hashValue(SymbolValue key, int keyType) {
    size_t hash = 0;
    switch (keyType) {
        case TYPE_STRING:
            // Simple string hash
            for (const char* p = key.stringValue; *p; p++) {
                hash = hash * 31 + *p;
            }
            break;
            
        case TYPE_INTEGER:
            hash = (size_t)key.intValue;
            break;
            
        case TYPE_FLOAT:
            // Convert float to bits for hashing
            hash = (size_t)key.floatValue;
            break;
            
        default:
            printf("Unsupported key type for hashing\n");
            return 0;
    }
    return hash % HASH_TABLE_SIZE;
}

void dictSet(DictType* dict, SymbolValue key, SymbolValue value) {
    if (!dict) return;
    
    size_t hash = hashValue(key, dict->keyType);
    
    // Look for existing key
    DictEntry* current = dict->buckets[hash];
    while (current) {
        bool keysMatch = false;
        
        // Compare keys based on type
        switch (dict->keyType) {
            case TYPE_STRING:
                keysMatch = (strcmp(current->key.stringValue, key.stringValue) == 0);
                break;
            case TYPE_INTEGER:
                keysMatch = (current->key.intValue == key.intValue);
                break;
            case TYPE_FLOAT:
                keysMatch = (current->key.floatValue == key.floatValue);
                break;
        }
        
        if (keysMatch) {
            // Update existing value
            current->value = value;
            return;
        }
        current = current->next;
    }
    
    // Create new entry
    DictEntry* newEntry = malloc(sizeof(DictEntry));
    if (!newEntry) {
        printf("Failed to allocate dictionary entry\n");
        return;
    }
    
    newEntry->key = key;
    newEntry->value = value;
    newEntry->next = dict->buckets[hash];
    dict->buckets[hash] = newEntry;
    dict->size++;
}

SymbolValue* dictGet(DictType* dict, SymbolValue key) {
    if (!dict) return NULL;
    
    size_t hash = hashValue(key, dict->keyType);
    DictEntry* current = dict->buckets[hash];
    
    while (current) {
        bool keysMatch = false;
        
        switch (dict->keyType) {
            case TYPE_STRING:
                keysMatch = (strcmp(current->key.stringValue, key.stringValue) == 0);
                break;
            case TYPE_INTEGER:
                keysMatch = (current->key.intValue == key.intValue);
                break;
            case TYPE_FLOAT:
                keysMatch = (current->key.floatValue == key.floatValue);
                break;
        }
        
        if (keysMatch) {
            return &current->value;
        }
        current = current->next;
    }
    
    return NULL;
}

void freeDict(DictType* dict) {
    if (!dict) return;
    
    // Free all entries in all buckets
    for (size_t i = 0; i < HASH_TABLE_SIZE; i++) {
        DictEntry* current = dict->buckets[i];
        while (current) {
            DictEntry* next = current->next;
            free(current);
            current = next;
        }
    }
    
    free(dict->buckets);
    free(dict);
}
