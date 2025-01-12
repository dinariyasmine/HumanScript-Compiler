%define parse.error verbose

%{


#define simpleToArrayOffset 4
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <math.h>
#define YYDEBUG 1


extern int yylex();
extern int yylineno; 
extern char* yytext;
extern FILE* yyin;
int positionCurseur = 0;
char *file = "input.txt";

void yyerror(const char *s);  
%}

%code requires{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <math.h>
#include "semantic.h"
#include "tableSymboles.h"
#include "quadruplets.h"
#include "pile.h"


}


%union {
    char identifier[255];      
    int type;
    int integerValue;
    double floatValue;
    bool booleanValue;
    char stringValue[255];
    struct SymbolEntry* entry;
    expression expression;
    variable variable;
    ExpressionList* exprList;
}

%token <type> INT FLOAT BOOL STR 
%token CONST ARRAY DICT FUNCTION 
%token LET BE CALL WITH PARAMETERS
%token ELSEIF IF ELSE ENDIF
%token FOR EACH IN ENDFOR
%token WHILE ENDWHILE
%token REPEAT UNTIL ENDREPEAT
%token INPUT TO
%token PRINT
%token SWITCH CASE DEFAULT ENDSWITCH
%token RETURN

%token ADD SUB MUL DIV INT_DIV MOD
%token EQUAL NOT_EQUAL GREATER_THAN LESS_THAN GREATER_EQUAL LESS_EQUAL
%token COLON LPAREN RPAREN LBRACE RBRACE COMMA LBRACKET RBRACKET
%token LOGICAL_AND LOGICAL_OR LOGICAL_NOT

%token <booleanValue> TRUE FALSE
%token <integerValue> INT_LITERAL 
%token <floatValue> FLOAT_LITERAL 
%token <stringValue> STRING_LITERAL
%token <identifier> ID    

%token COMMENT

/* Type definitions for non-terminals */
%type <expression> Expression SimpleExpression
%type <exprList> ExpressionList
%type <expression> ArrayLiteral
%type <expression> DictLiteral
%type <expression> DictItems
%type <expression> DictItem
%type <type> Type
%type <entry> Declaration Parameter ParameterList NonEmptyParameterList
%type <variable> Assignment


%left LOGICAL_OR
%left LOGICAL_AND
%left EQUAL NOT_EQUAL
%left LESS_THAN GREATER_THAN LESS_EQUAL GREATER_EQUAL
%left ADD SUB
%left MUL DIV MOD INT_DIV
%right LOGICAL_NOT
%nonassoc UMINUS

%start Program
%{
extern FILE *yyin;
extern int yylineno;
extern int yyleng;
extern int yylex();

int currentColumn = 1;
SymbolTable *symbolTable;
pile * stack;
quad *q = NULL;  
int qc = 1;

int currentArrayType = -1;
void yysuccess(char *s);
void yyerror(const char *s);
void showLexicalError();
%}
%%

Program:
    StatementList
    ;


StatementList:
    /* empty */                    { }
    | StatementList Statement      { }
    ;


Statement:
    SimpleStatement
    | CompoundStatement
    | COMMENT
    ;


SimpleStatement:
    Declaration
    | PrintStatement
    | Assignment
    | FunctionCall
    | InputStatement
    | RETURN Expression
    ;


CompoundStatement:
    LoopStatement
    | Function
    | Condition
    | SwitchStatement
    ;


LoopStatement:
    ForLoop
    | WhileLoop
    | RepeatLoop
    ;



ForLoop:
    FOR EACH ID IN Expression COLON StatementList ENDFOR
    ;


WhileLoop:
    WHILE Expression COLON StatementList ENDWHILE
    ;


RepeatLoop:
    REPEAT COLON StatementList UNTIL Expression ENDREPEAT
    ;


Expression:
    SimpleExpression {
        $$ = $1;
    }
    | Expression ADD Expression {
    char resultValue[MAX_VALUE_LENGTH];
    char temp[MAX_NAME_LENGTH];
    snprintf(temp, sizeof(temp), "t%d", qc);

    // Check if operands are compatible for arithmetic operations
    if (!validateArithmeticOperation($1, $3)) {
        yyerror("Invalid operands for addition");
        YYERROR;
    }

    // Retrieve type strings for both operands
    char type1Str[MAX_TYPE_LENGTH];
    char type3Str[MAX_TYPE_LENGTH];
    getTypeString($1.type, type1Str);
    getTypeString($3.type, type3Str);

    // Check if the operands are strings for concatenation
    if (strcmp(type1Str, "string") == 0 && strcmp(type3Str, "string") == 0) {
        snprintf(resultValue, sizeof(resultValue), "%s%s", getExpressionValue($1), getExpressionValue($3));
        printf("Result value: %s\n", resultValue);
        // Insert the result as a temporary variable in the symbol table
        insertSymbol(symbolTable, temp, "string", resultValue, 0, false, true);

        // Generate quadruplet for string concatenation
        insererQuadreplet(&q, "CONCAT", getExpressionValue($1), getExpressionValue($3), temp, qc++);

        // Set result values
        $$.type = TYPE_STRING;
        strncpy($$.value, temp, MAX_NAME_LENGTH - 1);
        $$.value[MAX_NAME_LENGTH - 1] = '\0';
        $$.next = NULL;
        $$.data = NULL;
    } 
    // Handle numeric addition
    else {
        // Determine result type
        if (strcmp(type1Str, "float") == 0 || strcmp(type3Str, "float") == 0) {
            $$.type = TYPE_FLOAT;

            // Compute the result
            float val1 = atof(getExpressionValue($1));
            float val2 = atof(getExpressionValue($3));
            snprintf(resultValue, sizeof(resultValue), "%.2f", val1 + val2);
        } else {
            $$.type = TYPE_INTEGER;

            // Compute the result
            int val1 = atoi(getExpressionValue($1));
            int val2 = atoi(getExpressionValue($3));
            snprintf(resultValue, sizeof(resultValue), "%d", val1 + val2);
        }

        // Create value string for symbol table insertion
        char valueStr[MAX_VALUE_LENGTH];
        createValueString($$.type, resultValue, valueStr);

        // Insert the result as a temporary variable in the symbol table
        insertSymbol(symbolTable, temp, $$.type == TYPE_FLOAT ? "float" : "int", valueStr, 0, false, true);

        // Generate quadruplet for numeric addition
        insererQuadreplet(&q, "+", getExpressionValue($1), getExpressionValue($3), temp, qc++);

        // Set result values
        strncpy($$.value, temp, MAX_NAME_LENGTH - 1);
        $$.value[MAX_NAME_LENGTH - 1] = '\0';
        $$.next = NULL;
        $$.data = NULL;
    }
}



    | Expression SUB Expression {
        if (!isNumericType($1.type) || !isNumericType($3.type)) {
            yyerror("Invalid operands for subtraction");
            YYERROR;
        }
        
        char resultValue[MAX_VALUE_LENGTH];
        char temp[20];
        sprintf(temp, "t%d", qc);
        
        if (strcmp($1.type, "float") == 0 || strcmp($3.type, "float") == 0) {
            strcpy($$.type, "float");
            float val1 = atof($1.value);
            float val2 = atof($3.value);
            snprintf(resultValue, MAX_VALUE_LENGTH - 1, "%.2f", val1 - val2);
        } else {
            strcpy($$.type, "int");
            int val1 = atoi($1.value);
            int val2 = atoi($3.value);
            snprintf(resultValue, MAX_VALUE_LENGTH - 1, "%d", val1 - val2);
        }
        
        insertSymbol(symbolTable, temp, $$.type, resultValue, 0, false, true);
        insererQuadreplet(&q, "-", $1.value, $3.value, temp, qc++);
        strcpy($$.value, resultValue);
    }

    | Expression MUL Expression {
        if (!isNumericType($1.type) || !isNumericType($3.type)) {
            yyerror("Invalid operands for multiplication");
            YYERROR;
        }
        
        char resultValue[MAX_VALUE_LENGTH];
        char temp[20];
        sprintf(temp, "t%d", qc);
        
        if (strcmp($1.type, "float") == 0 || strcmp($3.type, "float") == 0) {
            strcpy($$.type, "float");
            float val1 = atof($1.value);
            float val2 = atof($3.value);
            snprintf(resultValue, MAX_VALUE_LENGTH - 1, "%.2f", val1 * val2);
        } else {
            strcpy($$.type, "int");
            int val1 = atoi($1.value);
            int val2 = atoi($3.value);
            snprintf(resultValue, MAX_VALUE_LENGTH - 1, "%d", val1 * val2);
        }
        
    
        insertSymbol(symbolTable, temp, $$.type, resultValue, 0, false, true);
        insererQuadreplet(&q, "*", $1.value, $3.value, temp, qc++);
        strcpy($$.value, resultValue);
    }

    | Expression DIV Expression {
        if (!isNumericType($1.type) || !isNumericType($3.type)) {
            yyerror("Invalid operands for division");
            YYERROR;
        }
        
        // Check for division by zero
        if ((strcmp($3.type, "int") == 0 && atoi($3.value) == 0) ||
            (strcmp($3.type, "float") == 0 && atof($3.value) == 0.0)) {
            yyerror("Division by zero");
            YYERROR;
        }
        
        char resultValue[MAX_VALUE_LENGTH];
        char temp[20];
        sprintf(temp, "t%d", qc);
        
        // Division always results in float
        strcpy($$.type, "float");
        float val1 = strcmp($1.type, "int") == 0 ? atoi($1.value) : atof($1.value);
        float val2 = strcmp($3.type, "int") == 0 ? atoi($3.value) : atof($3.value);
        snprintf(resultValue, MAX_VALUE_LENGTH - 1, "%.2f", val1 / val2);
        
        insertSymbol(symbolTable, temp, $$.type, resultValue, 0, false, true);
        insererQuadreplet(&q, "/", $1.value, $3.value, temp, qc++);
        strcpy($$.value, resultValue);
    }

    | Expression INT_DIV Expression {
        if (strcmp($1.type, "int") != 0 || strcmp($3.type, "int") != 0) {
            yyerror("Integer division requires integer operands");
            YYERROR;
        }
        
        if (atoi($3.value) == 0) {
            yyerror("Division by zero");
            YYERROR;
        }
        
        char resultValue[MAX_VALUE_LENGTH];
        char temp[20];
        sprintf(temp, "t%d", qc);
        
        strcpy($$.type, "int");
        int val1 = atoi($1.value);
        int val2 = atoi($3.value);
        snprintf(resultValue, MAX_VALUE_LENGTH - 1, "%d", val1 / val2);
        
        insertSymbol(symbolTable, temp, $$.type, resultValue, 0, false, true);
        insererQuadreplet(&q, "DIV", $1.value, $3.value, temp, qc++);
        strcpy($$.value, resultValue);
    }
    | Expression MOD Expression {
        if (strcmp($1.type, "int") != 0 || strcmp($3.type, "int") != 0) {
            yyerror("Modulo operation requires integer operands");
            YYERROR;
        }
        
        if (atoi($3.value) == 0) {
            yyerror("Modulo by zero");
            YYERROR;
        }
        
        char resultValue[MAX_VALUE_LENGTH];
        char temp[20];
        sprintf(temp, "t%d", qc);
        
        strcpy($$.type, "int");
        int val1 = atoi($1.value);
        int val2 = atoi($3.value);
        snprintf(resultValue, MAX_VALUE_LENGTH - 1, "%d", val1 % val2);
        
        insertSymbol(symbolTable, temp, $$.type, resultValue, 0, false, true);
        insererQuadreplet(&q, "MOD", $1.value, $3.value, temp, qc++);
        strcpy($$.value, resultValue);
    }

    | Expression EQUAL Expression {
        char resultValue[MAX_VALUE_LENGTH];
        char temp[20];
        sprintf(temp, "t%d", qc);
        
        // Handle comparison based on types
        strcpy($$.type, "boolean");
        bool isEqual = false;
        
        if (strcmp($1.type, $3.type) == 0) {
            if (strcmp($1.type, "string") == 0) {
                isEqual = (strcmp($1.value, $3.value) == 0);
            } else if (strcmp($1.type, "float") == 0) {
                isEqual = (fabs(atof($1.value) - atof($3.value)) < 0.000001);
            } else {
                isEqual = (strcmp($1.value, $3.value) == 0);
            }
        }
        
        snprintf(resultValue, MAX_VALUE_LENGTH - 1, "%s", isEqual ? "true" : "false");
        insertSymbol(symbolTable, temp, $$.type, resultValue, 0, false, true);
        insererQuadreplet(&q, "==", $1.value, $3.value, temp, qc++);
        strcpy($$.value, resultValue);
    }

    | Expression NOT_EQUAL Expression {
        char resultValue[MAX_VALUE_LENGTH];
        char temp[20];
        sprintf(temp, "t%d", qc);
        
        strcpy($$.type, "boolean");
        bool isNotEqual = true;
        
        if (strcmp($1.type, $3.type) == 0) {
            if (strcmp($1.type, "string") == 0) {
                isNotEqual = (strcmp($1.value, $3.value) != 0);
            } else if (strcmp($1.type, "float") == 0) {
                isNotEqual = (fabs(atof($1.value) - atof($3.value)) >= 0.000001);
            } else {
                isNotEqual = (strcmp($1.value, $3.value) != 0);
            }
        }
        
        snprintf(resultValue, MAX_VALUE_LENGTH - 1, "%s", isNotEqual ? "true" : "false");
        insertSymbol(symbolTable, temp, $$.type, resultValue, 0, false, true);
        insererQuadreplet(&q, "!=", $1.value, $3.value, temp, qc++);
        strcpy($$.value, resultValue);
    }

    | Expression GREATER_THAN Expression {
        if (!isComparable($1.type, $3.type)) {
            yyerror("Invalid types for comparison");
            YYERROR;
        }
        
        char resultValue[MAX_VALUE_LENGTH];
        char temp[20];
        sprintf(temp, "t%d", qc);
        
        strcpy($$.type, "boolean");
        bool isGreater = false;
        
        if (strcmp($1.type, "string") == 0) {
            isGreater = (strcmp($1.value, $3.value) > 0);
        } else if (isNumericType($1.type)) {
            double val1 = strcmp($1.type, "int") == 0 ? atoi($1.value) : atof($1.value);
            double val2 = strcmp($3.type, "int") == 0 ? atoi($3.value) : atof($3.value);
            isGreater = (val1 > val2);
        }
        
        snprintf(resultValue, MAX_VALUE_LENGTH - 1, "%s", isGreater ? "true" : "false");
        insertSymbol(symbolTable, temp, $$.type, resultValue, 0, false, true);
        insererQuadreplet(&q, ">", $1.value, $3.value, temp, qc++);
        strcpy($$.value, resultValue);
    }

    | Expression LESS_THAN Expression {
        if (!isComparable($1.type, $3.type)) {
            yyerror("Invalid types for comparison");
            YYERROR;
        }
        
        char resultValue[MAX_VALUE_LENGTH];
        char temp[20];
        sprintf(temp, "t%d", qc);
        
        strcpy($$.type, "boolean");
        bool isLess = false;
        
        if (strcmp($1.type, "string") == 0) {
            isLess = (strcmp($1.value, $3.value) < 0);
        } else if (isNumericType($1.type)) {
            double val1 = strcmp($1.type, "int") == 0 ? atoi($1.value) : atof($1.value);
            double val2 = strcmp($3.type, "int") == 0 ? atoi($3.value) : atof($3.value);
            isLess = (val1 < val2);
        }
        
        snprintf(resultValue, MAX_VALUE_LENGTH - 1, "%s", isLess ? "true" : "false");
        insertSymbol(symbolTable, temp, $$.type, resultValue, 0, false, true);
        insererQuadreplet(&q, "<", $1.value, $3.value, temp, qc++);
        strcpy($$.value, resultValue);
    }

    | Expression GREATER_EQUAL Expression {
        if (!isComparable($1.type, $3.type)) {
            yyerror("Invalid types for comparison");
            YYERROR;
        }
        
        char resultValue[MAX_VALUE_LENGTH];
        char temp[20];
        sprintf(temp, "t%d", qc);
        
        strcpy($$.type, "boolean");
        bool isGreaterEqual = false;
        
        if (strcmp($1.type, "string") == 0) {
            isGreaterEqual = (strcmp($1.value, $3.value) >= 0);
        } else if (isNumericType($1.type)) {
            double val1 = strcmp($1.type, "int") == 0 ? atoi($1.value) : atof($1.value);
            double val2 = strcmp($3.type, "int") == 0 ? atoi($3.value) : atof($3.value);
            isGreaterEqual = (val1 >= val2);
        }
        
        snprintf(resultValue, MAX_VALUE_LENGTH - 1, "%s", isGreaterEqual ? "true" : "false");
        insertSymbol(symbolTable, temp, $$.type, resultValue, 0, false, true);
        insererQuadreplet(&q, ">=", $1.value, $3.value, temp, qc++);
        strcpy($$.value, resultValue);
    }

    | Expression LESS_EQUAL Expression {
        if (!isComparable($1.type, $3.type)) {
            yyerror("Invalid types for comparison");
            YYERROR;
        }
        
        char resultValue[MAX_VALUE_LENGTH];
        char temp[20];
        sprintf(temp, "t%d", qc);
        
        strcpy($$.type, "boolean");
        bool isLessEqual = false;
        
        if (strcmp($1.type, "string") == 0) {
            isLessEqual = (strcmp($1.value, $3.value) <= 0);
        } else if (isNumericType($1.type)) {
            double val1 = strcmp($1.type, "int") == 0 ? atoi($1.value) : atof($1.value);
            double val2 = strcmp($3.type, "int") == 0 ? atoi($3.value) : atof($3.value);
            isLessEqual = (val1 <= val2);
        }
        
        snprintf(resultValue, MAX_VALUE_LENGTH - 1, "%s", isLessEqual ? "true" : "false");
        insertSymbol(symbolTable, temp, $$.type, resultValue, 0, false, true);
        insererQuadreplet(&q, "<=", $1.value, $3.value, temp, qc++);
        strcpy($$.value, resultValue);
    }

    | Expression LOGICAL_AND Expression {
        if (!isBooleanType($1.type) || !isBooleanType($3.type)) {
            yyerror("Logical AND operation requires boolean operands");
            YYERROR;
        }
        
        char resultValue[MAX_VALUE_LENGTH];
        char temp[20];
        sprintf(temp, "t%d", qc);
        
        strcpy($$.type, "boolean");
        bool val1 = strcmp($1.value, "true") == 0;
        bool val2 = strcmp($3.value, "true") == 0;
        snprintf(resultValue, MAX_VALUE_LENGTH - 1, "%s", (val1 && val2) ? "true" : "false");
        
        insertSymbol(symbolTable, temp, $$.type, resultValue, 0, false, true);
        insererQuadreplet(&q, "AND", $1.value, $3.value, temp, qc++);
        strcpy($$.value, resultValue);
    }

    | Expression LOGICAL_OR Expression {
        if (!isBooleanType($1.type) || !isBooleanType($3.type)) {
            yyerror("Logical OR operation requires boolean operands");
            YYERROR;
        }
        
        char resultValue[MAX_VALUE_LENGTH];
        char temp[20];
        sprintf(temp, "t%d", qc);
        
        strcpy($$.type, "boolean");
        bool val1 = strcmp($1.value, "true") == 0;
        bool val2 = strcmp($3.value, "true") == 0;
        snprintf(resultValue, MAX_VALUE_LENGTH - 1, "%s", (val1 || val2) ? "true" : "false");
        
        insertSymbol(symbolTable, temp, $$.type, resultValue, 0, false, true);
        insererQuadreplet(&q, "OR", $1.value, $3.value, temp, qc++);
        strcpy($$.value, resultValue);
    }

    | LOGICAL_NOT Expression {
        if (!isBooleanType($2.type)) {
            yyerror("Logical NOT operation requires boolean operand");
            YYERROR;
        }
        
        char resultValue[MAX_VALUE_LENGTH];
        char temp[20];
        sprintf(temp, "t%d", qc);
        
        strcpy($$.type, "boolean");
        bool val = strcmp($2.value, "true") == 0;
        snprintf(resultValue, MAX_VALUE_LENGTH - 1, "%s", !val ? "true" : "false");
        
        insertSymbol(symbolTable, temp, $$.type, resultValue, 0, false, true);
        insererQuadreplet(&q, "NOT", $2.value, "", temp, qc++);
        strcpy($$.value, resultValue);
    }

    | SUB Expression %prec UMINUS {
        if (!isNumericType($2.type)) {
            yyerror("Unary minus requires numeric operand");
            YYERROR;
        }
        
        char resultValue[MAX_VALUE_LENGTH];
        char temp[20];
        sprintf(temp, "t%d", qc);
        
        strcpy($$.type, $2.type);
        if (strcmp($2.type, "int") == 0) {
            snprintf(resultValue, MAX_VALUE_LENGTH - 1, "%d", -atoi($2.value));
        } else {
            snprintf(resultValue, MAX_VALUE_LENGTH - 1, "%.2f", -atof($2.value));
        }
        
        insertSymbol(symbolTable, temp, $$.type, resultValue, 0, false, true);
        insererQuadreplet(&q, "NEG", $2.value, "", temp, qc++);
        strcpy($$.value, resultValue);
    }
    ;





SimpleExpression:
    INT_LITERAL {
        $$.type = TYPE_INTEGER;
        snprintf($$.value, MAX_NAME_LENGTH, "%d", $1);
    }
    | FLOAT_LITERAL {
        $$.type = TYPE_FLOAT;
        snprintf($$.value, MAX_NAME_LENGTH, "%.2f", $1);
    }
    | STRING_LITERAL {
        $$.type = TYPE_STRING;
        strncpy($$.value, $1, MAX_NAME_LENGTH - 1);
        $$.value[MAX_NAME_LENGTH - 1] = '\0';
    }
    | TRUE {
        $$.type = TYPE_BOOLEAN;
        strcpy($$.value, "true");
    }
    | FALSE {
        $$.type = TYPE_BOOLEAN;
        strcpy($$.value, "false");
    }
    | ID {
        SymbolEntry *symbol = lookupSymbolByName(symbolTable, $1, 0);
        if (!symbol) {
            yyerror("Undefined identifier");
            YYERROR;
        }
        
        if (strcmp(symbol->type, "int") == 0) $$.type = TYPE_INTEGER;
        else if (strcmp(symbol->type, "float") == 0) $$.type = TYPE_FLOAT;
        else if (strcmp(symbol->type, "string") == 0) $$.type = TYPE_STRING;
        else if (strcmp(symbol->type, "bool") == 0) $$.type = TYPE_BOOLEAN;
        
        strncpy($$.value, symbol->value, MAX_NAME_LENGTH - 1);
        $$.value[MAX_NAME_LENGTH - 1] = '\0';
    }
    | ArrayLiteral {
        $$ = $1;
    }
    | DictLiteral
    | LPAREN Expression RPAREN { 
        $$ = $2; 
    }
    | FunctionCall
    ;

Declaration:
    LET Type ID BE Expression {

        if (symbolExistsByName(symbolTable, $3, 0)) {
            char error[100];
            snprintf(error, sizeof(error), "Symbol '%s' already declared", $3);
            yyerror(error);
            YYERROR;
        }

        // Validate types match
        char typeStr[MAX_TYPE_LENGTH];
        getTypeString($2, typeStr);

        // Create value string
        char valueStr[MAX_VALUE_LENGTH];
        createValueString($2, ($5.value), valueStr);
        // Insert into symbol table
        insertSymbol(symbolTable, $3, typeStr, valueStr, 0, false, true);
        
        // Generate quadruplet
        char temp[20];
        sprintf(temp, "t%d", qc);
        insererQuadreplet(&q, ":=", valueStr, "", $3, qc++);

        // Look up the inserted symbol to return it
        $$ = lookupSymbolByName(symbolTable, $3, 0);
        if (!$$) {
            yyerror("Failed to retrieve newly inserted symbol");
            YYERROR;
        }
        
        
    }
    | CONST Type ID BE Expression {
        if (symbolExistsByName(symbolTable, $3, 0)) {
            char error[100];
            snprintf(error, sizeof(error), "Symbol '%s' already declared", $3);
            yyerror(error);
            YYERROR;
        }

                // Validate types match
        char typeStr[MAX_TYPE_LENGTH];
        getTypeString($2, typeStr);

        // Create value string
        char valueStr[MAX_VALUE_LENGTH];
        createValueString($2, ($5.value), valueStr);

        // Insert into symbol table
        insertSymbol(symbolTable, $3, typeStr, valueStr, 0, true, true);
        
        // Generate quadruplet
        char temp[20];
        sprintf(temp, "t%d", qc);
        insererQuadreplet(&q, ":=", valueStr, "", $3, qc++);

        // Look up the inserted symbol to return it
        $$ = lookupSymbolByName(symbolTable, $3, 0);
        if (!$$) {
            yyerror("Failed to retrieve newly inserted symbol");
            YYERROR;
        }
    }
    | Type ID {
        // Check for existing symbol
        if (symbolExistsByName(symbolTable, $2, 0)) {
            char error[100];
            snprintf(error, sizeof(error), "Symbol '%s' already declared", $2);
            yyerror(error);
            YYERROR;
        }

        // Get type string
        char typeStr[MAX_TYPE_LENGTH];
        char valueStr[MAX_VALUE_LENGTH];
        getTypeString($1, typeStr);
        createValueString($1, NULL, valueStr);

        // Insert into symbol table with default value
        insertSymbol(symbolTable, $2, typeStr, valueStr, 0, false, false);
        
        // Generate quadruplet for default initialization
        char temp[20];
        sprintf(temp, "t%d", qc);
        insererQuadreplet(&q, ":=", valueStr, "", $2, qc++);

        // Look up the inserted symbol to return it
        $$ = lookupSymbolByName(symbolTable, $2, 0);
        if (!$$) {
            yyerror("Failed to retrieve newly inserted symbol");
            YYERROR;
        }

    }
    ;
    |   LET ARRAY Type ID BE ArrayLiteral {
        printf("Array declaration with initialization started\n");
        
        // Check for existing symbol
        if (symbolExistsByName(symbolTable, $4, 0)) {
            yyerror("Cannot redeclare identifier");
            YYERROR;
        }
        
        // Get the array's element type
        char typeStr[MAX_TYPE_LENGTH];
        getTypeString(TYPE_ARRAY, typeStr);
        
        // Create an empty array entry in symbol table
        insertSymbol(symbolTable, $4, typeStr, "[]", 0, false, true);
        
        // Get the newly created symbol
        SymbolEntry* arraySymbol = lookupSymbolByName(symbolTable, $4, 0);
        if (!arraySymbol) {
            yyerror("Failed to create array symbol");
            YYERROR;
        }
        
        // Validate array type matches declared type
        expression arrayExpr = $6;
        if (arrayExpr.type != TYPE_ARRAY) {
            yyerror("Type mismatch: Expected array literal");
            YYERROR;
        }
        
        // Update the array value in symbol table
        updateSymbolValue(symbolTable, arraySymbol->id, arrayExpr.value, 0);
        
        // Generate array declaration quadruplet
        char temp[20];
        sprintf(temp, "t%d", qc);
        insererQuadreplet(&q, "ARRAY_DECL", $4, arrayExpr.value, temp, qc++);
        
        $$ = arraySymbol;
        printf("Array '%s' declared successfully\n", $4);
    }
    ;

Type:
    INT     { 
        $$ = TYPE_INTEGER; 
        currentArrayType = TYPE_INTEGER;  
    }
    | FLOAT { 
        $$ = TYPE_FLOAT;
        currentArrayType = TYPE_FLOAT;
    }
    | BOOL  { 
        $$ = TYPE_BOOLEAN;
        currentArrayType = TYPE_BOOLEAN;
    }
    | STR   { 
        $$ = TYPE_STRING;
        currentArrayType = TYPE_STRING;
    }
    | ARRAY Type { 
        $$ = TYPE_ARRAY;
    }
    | DICT
    ;


Assignment:
    ID EQUAL Expression {
        // Check if identifier exists
        SymbolEntry *symbol = lookupSymbolByName(symbolTable, $1, 0);
        if (!symbol) {
            yyerror("Undefined identifier");
            YYERROR;
        }
        
        // Check if trying to modify a constant
        if (symbol->isConst) {
            yyerror("Cannot modify constant value");
            YYERROR;
        }
        
        // Get symbol type
        int symbolType = -1;
        if (strcmp(symbol->type, "int") == 0) symbolType = TYPE_INTEGER;
        else if (strcmp(symbol->type, "float") == 0) symbolType = TYPE_FLOAT;
        else if (strcmp(symbol->type, "string") == 0) symbolType = TYPE_STRING;
        else if (strcmp(symbol->type, "bool") == 0) symbolType = TYPE_BOOLEAN;
        
        // Create variable structure for return value
        variable var;
        var.entry = symbol;
        
        // Validate and update value
        char newValue[MAX_NAME_LENGTH];
        if (!validateAndSetValue(newValue, $3, symbolType)) {
            YYERROR;
        }
        
        // Update symbol table
        updateSymbolValue(symbolTable, symbol->id, newValue, 0);
        
        // Generate quadruplet
        insererQuadreplet(&q, ":=", getExpressionValue($3), "", $1, qc++);
        
        $$ = var;
    }
    ;

PrintStatement:
    PRINT Expression 
    ;

InputStatement:
    INPUT Expression TO ID 
    ;



Function:
    FUNCTION ID COLON Type LPAREN ParameterList RPAREN LBRACE StatementList RBRACE
        
    ;



FunctionCall:
    CALL ID WITH PARAMETERS ParameterList LPAREN ExpressionList RPAREN {
        printf("Appel valide avec parametres\n");
    }
    | CALL ID LPAREN RPAREN {
        printf("Appel valide sans parametres\n");
    }
    ;


ParameterList:
    /* empty */
    | NonEmptyParameterList
    ;

NonEmptyParameterList:
    Parameter
    | NonEmptyParameterList COMMA Parameter
    ;

Parameter:
    Type ID
    ;


Condition:
    SimpleIf
    | IfWithElse
    ;

// A revoir les quadruplet sont pas bien generes
SimpleIf:
    IF Expression COLON StatementList ENDIF {
        char labelFalse[20];
        sprintf(labelFalse, "L%d", qc++);

        insererQuadreplet(&q, "IF_FALSE", getExpressionValue($2), "GOTO", labelFalse, qc++);
        

        // Label for false branch (end of IF)
        insererQuadreplet(&q, "LABEL", labelFalse, "", "", qc++);
    }


IfWithElse:
    IF Expression COLON StatementList ElseIfList {
        char labelFalse[20], labelEnd[20];
        sprintf(labelFalse, "L%d", qc++);
        sprintf(labelEnd, "L%d", qc++);

        // Generate a single quadruplet for the condition
        insererQuadreplet(&q, "IF_FALSE", getExpressionValue($2), "GOTO", labelFalse, qc++);


        // Jump to end after true block
        insererQuadreplet(&q, "GOTO", labelEnd, "", "", qc++);

        // Label for false branch (ELSE/ELSEIF)
        insererQuadreplet(&q, "LABEL", labelFalse, "", "", qc++);


        // End label
        insererQuadreplet(&q, "LABEL", labelEnd, "", "", qc++);
    }


ElseIfList:
    ELSE COLON StatementList ENDIF {
        // Generate quadruplets for ELSE block
        
    }
    | ELSEIF Expression COLON StatementList ElseIfList {
        char labelNext[20];
        sprintf(labelNext, "L%d", qc++);

        // Generate a single quadruplet for ELSEIF condition
        insererQuadreplet(&q, "ELSEIF_FALSE", getExpressionValue($2), "GOTO", labelNext, qc++);

        // Generate quadruplets for true block
        

        // Continue with next ELSEIF/ELSE block
        insererQuadreplet(&q, "LABEL", labelNext, "", "", qc++);
        
        
    }
SwitchStatement:
    SWITCH Expression COLON CaseList ENDSWITCH
    ;

CaseList:
    CaseItems DefaultPart
    ;

CaseItems:
    /* empty */
    | CaseItems CaseItem
    ;

CaseItem:
    CASE Expression COLON StatementList
    ;

DefaultPart:
    /* empty */
    | DEFAULT COLON StatementList
    ;


ArrayLiteral:
    LBRACKET RBRACKET {
        $$.type = TYPE_ARRAY;
        ArrayType* arr = createArray(currentArrayType);
        if (!arr) {
            yyerror("Failed to create empty array");
            YYERROR;
        }
        $$.data = arr;
        strcpy($$.value, "[]");
    }
    | LBRACKET ExpressionList RBRACKET {
        $$.type = TYPE_ARRAY;
        ArrayType* arr = createArrayFromExprList($2, currentArrayType);
        if (!arr) {
            yyerror("Failed to create array from expression list");
            YYERROR;
        }
        $$.data = arr;
        
        // Create string representation of array
        char arrayStr[MAX_NAME_LENGTH] = "[";
        ExpressionList* current = $2;
        while (current) {
            strncat(arrayStr, current->expr.value, MAX_NAME_LENGTH - strlen(arrayStr) - 1);
            if (current->next) strncat(arrayStr, ",", MAX_NAME_LENGTH - strlen(arrayStr) - 1);
            current = current->next;
        }
        strncat(arrayStr, "]", MAX_NAME_LENGTH - strlen(arrayStr) - 1);
        strncpy($$.value, arrayStr, MAX_NAME_LENGTH - 1);
        $$.value[MAX_NAME_LENGTH - 1] = '\0';
    }
    ;

DictLiteral:
    LBRACE RBRACE
    | LBRACE DictItems RBRACE
    ;


ExpressionList:
    Expression {
        $$ = createExpressionNode($1);
    }
    | ExpressionList COMMA Expression {
        $$ = addExpressionToList($1, $3);
    }
    ;


DictItems:
    DictItem
    | DictItems COMMA DictItem
    ;

DictItem:
    STRING_LITERAL COLON Expression
    ;

%%

/* Gestion des erreurs */
void yyerror(const char *s) {
    if (strcmp(s, "syntax error") == 0) {
        fprintf(stderr, "File '%s', line %d, character %d: syntax error, unexpected '%s'\n", 
                file, yylineno, positionCurseur, yytext);
    } else {
        fprintf(stderr, "File '%s', line %d, character %d: %s\n", 
                file, yylineno, positionCurseur, s);
    }
}

int main(void) {
    // ouverture fichier de test
    yyin = fopen("input.txt", "r");
    if (!yyin) {
        fprintf(stderr, "Error: Could not open input file\n");
        return 1;
    }

    // Creation de la table des symboles
    symbolTable = createSymbolTable();
    listAllSymbols(symbolTable);

    if (!symbolTable) {
        fprintf(stderr, "Error: Failed to create symbol table.\n");
        fclose(yyin);
        return 1;
    }

    // Creation de la pile
    stack = malloc(sizeof(pile));
    if (!stack) {
        fprintf(stderr, "Error: Failed to allocate memory for stack.\n");
        fclose(yyin);
        freeSymbolTable(symbolTable);
        return 1;
    }
    initPile(stack);

    // Affichage du message de demarrage
    printf("Starting syntax analysis...\n");

    // Lancement de l'analyse syntaxique
    int result = yyparse();
    listAllSymbols(symbolTable);

    // Affichage du message de fin
    free(stack);
    // Affichage de table des symboles
    
    // Affichage des quadruplets generes
    afficherQuad(q);

    // Liberation de la table des symboles
    freeSymbolTable(symbolTable);
    
    // Fermeture du fichier
    fclose(yyin);
    
    return result;
    return 0;
}