// semantic.h
#ifndef SEMANTIC_H
#define SEMANTIC_H
#include <stdbool.h>
#include "tableSymboles.h"

typedef struct expression {
    int type;
    char value[MAX_NAME_LENGTH];  
    void* data;
} expression;

typedef struct ExpressionNode {
    expression expr;
    struct ExpressionNode* next;
} ExpressionList;

typedef struct variable {
    struct SymbolEntry* entry;
} variable;

// Function declarations
void getTypeString(int type, char* typeStr);
ArrayType* createArray();
ArrayType* createArrayFromExprList(ExpressionList* list);
void getTypeString(int type, char *typeStr);
void createValueString(int type, const char *inputValue, char *valueStr);
ExpressionList* createExpressionNode(expression expr);
ExpressionList* addExpressionToList(ExpressionList* list, expression expr);

#endif // SEMANTIC_H