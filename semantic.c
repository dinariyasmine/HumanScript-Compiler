#include "semantic.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#define INITIAL_CAPACITY 10  // or any other suitable value



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
    printf("Getting type string for type: %d\n", type);
    switch(type) {
        case TYPE_BOOLEAN:
            strncpy(typeStr, "bool", MAX_TYPE_LENGTH - 1);
            break;
        case TYPE_INTEGER:
            strncpy(typeStr, "int", MAX_TYPE_LENGTH - 1);
            break;
        case TYPE_FLOAT:
            strncpy(typeStr, "float", MAX_TYPE_LENGTH - 1);
            break;
        case TYPE_STRING:
            strncpy(typeStr, "string", MAX_TYPE_LENGTH - 1);
            break;
        case TYPE_ARRAY:
            strncpy(typeStr, "array", MAX_TYPE_LENGTH - 1);
            break;
        case TYPE_DICT:
            strncpy(typeStr, "dict", MAX_TYPE_LENGTH - 1);
            break;
        case TYPE_FUNCTION:
            strncpy(typeStr, "function", MAX_TYPE_LENGTH - 1);
            break;
        case TYPE_CONST:
            strncpy(typeStr, "const", MAX_TYPE_LENGTH - 1);
            break;
        default:
            snprintf(typeStr, MAX_TYPE_LENGTH - 1, "unknown(%d)", type);
    }
    typeStr[MAX_TYPE_LENGTH - 1] = '\0';
    printf("Type string result: %s\n", typeStr);
}bool validateAndSetValue(SymbolValue* value, expression expr, int declaredType) {
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
ArrayType* createArrayFromExprList(ExpressionList* exprList, int baseType) {
    printf("Creating array from expression list with base type: %d\n", baseType);
    
    if (!exprList) {
        printf("Expression list is empty.\n");
        return NULL;
    }
    
    ArrayType* arr = createArray(baseType);
    if (!arr) {
        printf("Error: Array creation failed.\n");
        return NULL;
    }
    
    ExpressionList* current = exprList;
    while (current != NULL) {
        expression expr = current->expr;
        printf("Processing element of type %d (expected %d)\n", expr.type, baseType);
        
        if (expr.type != baseType) {
            char expectedType[MAX_TYPE_LENGTH];
            char gotType[MAX_TYPE_LENGTH];
            getTypeString(baseType, expectedType);
            getTypeString(expr.type, gotType);
            printf("Type mismatch: expected %s, got %s\n", expectedType, gotType);
            freeArray(arr);
            return NULL;
        }
        
        SymbolValue value = {0};
        switch (baseType) {
            case TYPE_INTEGER:
                value.intValue = expr.integerValue;
                break;
            case TYPE_FLOAT:
                value.floatValue = expr.floatValue;
                break;
            case TYPE_BOOLEAN:
                value.intValue = expr.booleanValue ? 1 : 0;
                break;
            case TYPE_STRING:
                strncpy(value.stringValue, expr.stringValue, MAX_NAME_LENGTH - 1);
                value.stringValue[MAX_NAME_LENGTH - 1] = '\0';
                break;
            default:
                printf("Error: Unsupported base type: %d\n", baseType);
                freeArray(arr);
                return NULL;
        }
        
        arrayPush(arr, value);
        current = current->next;
    }
    
    return arr;
}
ArrayType* createArray(int baseType) {
    printf("Creating array with base type: %d\n", baseType);
    ArrayType* arr = malloc(sizeof(ArrayType));
    if (arr) {
        arr->elementType = baseType;
        arr->length = 0;
        arr->capacity = INITIAL_CAPACITY;
        arr->data = malloc(sizeof(SymbolValue) * arr->capacity);
        if (!arr->data) {
            free(arr);
            return NULL;
        }
        printf("Array created successfully with base type %d\n", arr->elementType);
    }
    return arr;
}
void arrayPush(ArrayType* arr, SymbolValue value) {
    // Push value to the array, resizing if necessary
    if (arr->length >= arr->capacity) {
        arr->capacity *= 2;
        arr->data = realloc(arr->data, sizeof(SymbolValue) * arr->capacity);
    }
    arr->data[arr->length++] = value;
}

void freeArray(ArrayType* arr) {
    // Free memory allocated for the array
    if (arr) {
        free(arr->data);
        free(arr);
    }
}
ExpressionList* createExpressionNode(expression expr) {
    ExpressionList* node = malloc(sizeof(ExpressionList));
    node->expr = expr;
    node->next = NULL;
    return node;
}

ExpressionList* addExpressionToList(ExpressionList* list, expression expr) {
    ExpressionList* current = list;
    while (current->next != NULL) {
        current = current->next;
    }
    current->next = createExpressionNode(expr);
    return list;
}

bool validateTypeCompatibility(int declaredType, int expressionType) {
    // Basic type equality check
    if (declaredType == expressionType) {
        return true;
    }

    // Special cases for numeric type compatibility
    if ((declaredType == TYPE_FLOAT && expressionType == TYPE_INTEGER) ||
        (declaredType == TYPE_INTEGER && expressionType == TYPE_FLOAT)) {
        return true;
    }

    // Array type compatibility
    if (declaredType == TYPE_ARRAY && expressionType == TYPE_ARRAY) {
        // Additional array element type checking could be added here
        return true;
    }

    return false;
}
int countParameters(SymbolEntry* paramList) {
    int count = 0;
    SymbolEntry* current = paramList;
    
    while (current != NULL) {
        count++;
        current = current->next;
    }
    
    return count;
}
