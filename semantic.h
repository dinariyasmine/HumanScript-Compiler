#ifndef SEMANTIC_H
#define SEMANTIC_H
#include <stdbool.h>
#include "tableSymboles.h"


struct ArrayType;
// on a besoin de cette structure car nous devons a un 
//certain moment stocker le type et la valeur en meme temps
typedef struct expression expression;
struct expression {
    int type;
    char stringValue[255];
    int integerValue;
    double floatValue;
    bool booleanValue;
    struct expression* next;
    void* data;
};
typedef struct ExpressionNode {
    expression expr;
    struct ExpressionNode* next;
} ExpressionList;
typedef struct variable variable;
struct variable {
    struct SymbolEntry* entry;
};
// this function is used for debugging mostly
void valeurToString(expression expression, char * valeur);
void handleTypeError(const char* expectedType, const char* gotType);
bool validateAndSetValue(SymbolValue* value, expression expr, int declaredType);
void initDefaultValue(SymbolValue* value, int type);
ArrayType* createArrayFromExprList(ExpressionList* exprList, int baseType); ;
ArrayType* createArray(int baseType) ;
void arrayPush(ArrayType* arr, SymbolValue value);
void freeArray(ArrayType* arr);
ExpressionList* addExpressionToList(ExpressionList* list, expression expr);
ExpressionList* createExpressionNode(expression expr);

#endif // SEMANTIC_H
