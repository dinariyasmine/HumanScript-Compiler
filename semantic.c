// semantic.c
#include "semantic.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#define YYERROR return



bool validateAndSetValue(char* value, expression expr, int declaredType) {
    if (expr.type != declaredType) {
        char expectedType[20], gotType[20];
        getTypeString(declaredType, expectedType);
        getTypeString(expr.type, gotType);
        handleTypeError(expectedType, gotType);
        return false;
    }
    
    strncpy(value, expr.value, MAX_NAME_LENGTH - 1);
    value[MAX_NAME_LENGTH - 1] = '\0';
    return true;
}

void initDefaultValue(char* value, int type) {
    switch(type) {
        case TYPE_INTEGER:
            strncpy(value, "0", MAX_NAME_LENGTH - 1);
            break;
        case TYPE_FLOAT:
            strncpy(value, "0.0", MAX_NAME_LENGTH - 1);
            break;
        case TYPE_STRING:
            strncpy(value, "", MAX_NAME_LENGTH - 1);
            break;
        case TYPE_BOOLEAN:
            strncpy(value, "false", MAX_NAME_LENGTH - 1);
            break;
        case TYPE_ARRAY:
            strncpy(value, "[]", MAX_NAME_LENGTH - 1);
            break;
        case TYPE_DICT:
            strncpy(value, "{}", MAX_NAME_LENGTH - 1);
            break;
        default:
            value[0] = '\0';
    }
    value[MAX_NAME_LENGTH - 1] = '\0';
}

void handleTypeError(const char* expectedType, const char* gotType) {
    char errorMsg[256];
    snprintf(errorMsg, sizeof(errorMsg), "Type mismatch: Expected %s, got %s", expectedType, gotType);
    yyerror(errorMsg);
}

ArrayType* createArray(int elementType) {
    ArrayType* arr = malloc(sizeof(ArrayType));
    if (!arr) return NULL;
    
    arr->elementType = elementType;
    arr->length = 0;
    arr->capacity = 10;  // Initial capacity
    arr->data = malloc(arr->capacity * sizeof(char*));
    
    if (!arr->data) {
        free(arr);
        return NULL;
    }
    
    return arr;
}

ArrayType* createArrayFromExprList(ExpressionList* list, int elementType) {
    if (!list) return NULL;
    
    // Count elements first
    size_t count = 0;
    ExpressionList* current = list;
    while (current) {
        count++;
        current = current->next;
    }
    
    // Create array with exact size needed
    ArrayType* arr = malloc(sizeof(ArrayType));
    if (!arr) return NULL;
    
    arr->elementType = elementType;
    arr->length = count;
    arr->capacity = count;
    arr->data = malloc(count * sizeof(char*));
    
    if (!arr->data) {
        free(arr);
        return NULL;
    }
    
    // Copy values
    current = list;
    for (size_t i = 0; i < count && current; i++) {
        arr->data[i] = strdup(current->expr.value);
        if (!arr->data[i]) {
            // Cleanup on failure
            for (size_t j = 0; j < i; j++) {
                free(arr->data[j]);
            }
            free(arr->data);
            free(arr);
            return NULL;
        }
        current = current->next;
    }
    
    return arr;
}

ExpressionList* createExpressionNode(expression expr) {
    ExpressionList* node = malloc(sizeof(ExpressionList));
    if (node) {
        node->expr = expr;
        node->next = NULL;
    }
    return node;
}

ExpressionList* addExpressionToList(ExpressionList* list, expression expr) {
    if (!list) {
        return createExpressionNode(expr);
    }
    ExpressionList* current = list;
    while (current->next != NULL) {
        current = current->next;
    }
    current->next = createExpressionNode(expr);
    return list;
}

int validateArithmeticOperation(expression exp1, expression exp2) {
    if (exp1.type != exp2.type) {
        char type1[20], type2[20];
        getTypeString(exp1.type, type1);
        getTypeString(exp2.type, type2);
        handleTypeError(type1, type2);
        return -1;
    }
    return exp1.type;
}

char* getExpressionValue(expression exp) {
    return exp.value;
}

int compareExpressions(expression exp1, expression exp2) {
    if (exp1.type != exp2.type) {
        yyerror("Cannot compare expressions of different types");
        return 0;
    }
    return strcmp(exp1.value, exp2.value);
}



bool isNumericType(const char* type) {
    return (strcmp(type, "int") == 0 || strcmp(type, "float") == 0);
}

bool isBooleanType(const char* type) {
    return strcmp(type, "boolean") == 0;
}

bool isComparable(const char* type1, const char* type2) {
    if (strcmp(type1, type2) != 0) return false;
    return isNumericType(type1) || strcmp(type1, "string") == 0;
}

void getTypeString(int type, char *typeStr) {
    switch(type) {
        case TYPE_INTEGER:
            strcpy(typeStr, "int");
            break;
        case TYPE_FLOAT:
            strcpy(typeStr, "float");
            break;
        case TYPE_BOOLEAN:
            strcpy(typeStr, "bool");
            break;
        case TYPE_STRING:
            strcpy(typeStr, "string");
            break;
        case TYPE_ARRAY:
            strcpy(typeStr, "array");
            break;
        default:
            yyerror("Unsupported type");
            YYERROR;
    }
}
void createValueString(int type, const char *inputValue, char *valueStr) {
    if (inputValue == NULL || strlen(inputValue) == 0) {
        // Handle case when there is no value by setting defaults
        
        switch(type) {
            case TYPE_INTEGER:
                snprintf(valueStr, MAX_VALUE_LENGTH, "%d", 0);
                break;
            case TYPE_FLOAT:
                snprintf(valueStr, MAX_VALUE_LENGTH, "%.2f", 0.0);
                break;
            case TYPE_BOOLEAN:
                strncpy(valueStr, "false", MAX_VALUE_LENGTH - 1);
                valueStr[MAX_VALUE_LENGTH - 1] = '\0';
                break;
            case TYPE_STRING:
                strncpy(valueStr, "", MAX_VALUE_LENGTH - 1);
                valueStr[MAX_VALUE_LENGTH - 1] = '\0';
                break;
            case TYPE_ARRAY:
                strncpy(valueStr, "[]", MAX_VALUE_LENGTH - 1);
                valueStr[MAX_VALUE_LENGTH - 1] = '\0';
                break;
            default:
                yyerror("Unsupported type");
                
                YYERROR;
        }
    } else {
        switch(type) {
            case TYPE_INTEGER:
                snprintf(valueStr, MAX_VALUE_LENGTH, "%d", atoi(inputValue));
                break;
            case TYPE_FLOAT:
                snprintf(valueStr, MAX_VALUE_LENGTH, "%.2f", atof(inputValue));
                break;
            case TYPE_BOOLEAN:
                strncpy(valueStr, inputValue, MAX_VALUE_LENGTH - 1);
                valueStr[MAX_VALUE_LENGTH - 1] = '\0';
                break;
            case TYPE_STRING:
                strncpy(valueStr, inputValue, MAX_VALUE_LENGTH - 1);
                valueStr[MAX_VALUE_LENGTH - 1] = '\0';
                break;
            case TYPE_ARRAY:
                strncpy(valueStr, inputValue, MAX_VALUE_LENGTH - 1);
                valueStr[MAX_VALUE_LENGTH - 1] = '\0';
                break;
            default:
                yyerror("Unsupported type");
                
                YYERROR;
        }
    }
}


