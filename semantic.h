// semantic.h
#ifndef SEMANTIC_H
#define SEMANTIC_H
#include <stdbool.h>
#include "tableSymboles.h"

typedef struct expression {
    int type;
    char value[MAX_NAME_LENGTH];  
    struct expression* next;
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
void handleTypeError(const char* expectedType, const char* gotType);
bool validateAndSetValue(char* value, expression expr, int declaredType);
void initDefaultValue(char* value, int type);
void getTypeString(int type, char* typeStr);
ArrayType* createArray(int elementType);
ArrayType* createArrayFromExprList(ExpressionList* list, int elementType);
void getTypeString(int type, char *typeStr);
void createValueString(int type, const char *inputValue, char *valueStr);
ExpressionList* createExpressionNode(expression expr);
int compareExpressions(expression exp1, expression exp2);
char* getExpressionValue(expression exp);
int validateArithmeticOperation(expression exp1, expression exp2);
ExpressionList* addExpressionToList(ExpressionList* list, expression expr);
bool isNumericType(const char *type);
bool isBooleanType(const char *type);
bool isComparable(const char *type1, const char *type2);

#endif // SEMANTIC_H