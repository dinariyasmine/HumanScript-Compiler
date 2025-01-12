%define parse.error verbose

%{
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
    ExpressionList* exprList;
    variable variable;
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
quad *q = NULL;  // quadruplet
int qc = 1; // pile
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
    /* empty */                    
    | StatementList Statement      
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
    WhileStart StatementList ENDWHILE {
        // Get the start label from stack
        int whileId = depiler(stack);
        
        // Generate labels
        char whileConditionLabel[20];
        char whileEndLabel[20];
        sprintf(whileConditionLabel, "WHILE_COND_%d", whileId);
        sprintf(whileEndLabel, "WHILE_END_%d", whileId);
        
        // Generate unconditional jump back to condition
        insererQuadreplet(&q, "BR", "", "", whileConditionLabel, qc++);
        
        // Place end label for the while loop
        insererQuadreplet(&q, whileEndLabel, "", "", "", qc++);
    }
    ;

WhileStart:
    WhileCondition Expression COLON {
        // Validate expression type
        if ($2.type != TYPE_BOOLEAN) {
            yyerror("While condition must be a boolean expression");
            YYERROR;
        }
        
        // Generate unique ID for this while loop
        int whileId = qc;
        
        // Generate label names
        char whileConditionLabel[20];
        char whileEndLabel[20];
        sprintf(whileConditionLabel, "WHILE_COND_%d", whileId);
        sprintf(whileEndLabel, "WHILE_END_%d", whileId);
        
        // Place the condition label
        insererQuadreplet(&q, whileConditionLabel, "", "", "", qc++);
        
        // Generate conditional jump to end if condition is false
        insererQuadreplet(&q, "BZ", $2.value, "", whileEndLabel, qc++);
        
        // Push the while ID onto stack for matching endwhile
        empiler(stack, whileId);
    }
    ;

WhileCondition:
    WHILE
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

    // Validate operands for null values
    if (!$1.value || !$3.value) {
        yyerror("Operands for addition must be initialized and have valid values.");
        YYERROR;
    }

    // Get type information for operands
    char type1Str[MAX_TYPE_LENGTH];
    char type3Str[MAX_TYPE_LENGTH];
    getTypeString($1.type, type1Str);
    getTypeString($3.type, type3Str);

    // Handle string concatenation if both operands are strings
    if (strcmp(type1Str, "string") == 0 && strcmp(type3Str, "string") == 0) {
        snprintf(resultValue, sizeof(resultValue), "%s%s", $1.value, $3.value);
        
        char valueStr[MAX_VALUE_LENGTH];
        createValueString(TYPE_STRING, resultValue, valueStr);

        $$.type = TYPE_STRING;
        strncpy($$.value, resultValue, MAX_NAME_LENGTH - 1);
        $$.value[MAX_NAME_LENGTH - 1] = '\0';

        // Generate quadruplet for concatenation operation
        insererQuadreplet(&q, "CONCAT", $1.value, $3.value, temp, qc++);
    } 
    // Handle numeric addition
    else {
        // Handle floating point addition
        if (strcmp(type1Str, "float") == 0 || strcmp(type3Str, "float") == 0) {
            $$.type = TYPE_FLOAT;
            float val1 = atof($1.value);
            float val2 = atof($3.value);
            snprintf(resultValue, sizeof(resultValue), "%.2f", val1 + val2);
            
            char valueStr[MAX_VALUE_LENGTH];
            createValueString($$.type, resultValue, valueStr);
            
            strncpy($$.value, resultValue, MAX_NAME_LENGTH - 1);
            $$.value[MAX_NAME_LENGTH - 1] = '\0';

            // Generate quadruplet for addition operation
            insererQuadreplet(&q, "+", $1.value, $3.value, temp, qc++);
        } 
        // Handle integer addition
        else {
            $$.type = TYPE_INTEGER;
            int val1 = atoi($1.value);
            int val2 = atoi($3.value);
            snprintf(resultValue, sizeof(resultValue), "%d", val1 + val2);
            
            char valueStr[MAX_VALUE_LENGTH];
            createValueString($$.type, resultValue, valueStr);
            
            strncpy($$.value, resultValue, MAX_NAME_LENGTH - 1);
            $$.value[MAX_NAME_LENGTH - 1] = '\0';

            // Generate quadruplet for addition operation
            insererQuadreplet(&q, "+", $1.value, $3.value, temp, qc++);
        }
    }
}

    | Expression SUB Expression {
    char resultValue[MAX_VALUE_LENGTH];
    char temp[MAX_NAME_LENGTH];
    snprintf(temp, sizeof(temp), "t%d", qc);

    // Validate operands for null values
    if (!$1.value || !$3.value) {
        yyerror("Operands for subtraction must be initialized and have valid values.");
        YYERROR;
    }

    // Get type information for operands
    char type1Str[MAX_TYPE_LENGTH];
    char type3Str[MAX_TYPE_LENGTH];
    getTypeString($1.type, type1Str);
    getTypeString($3.type, type3Str);

    // Handle floating point subtraction
    if (strcmp(type1Str, "float") == 0 || strcmp(type3Str, "float") == 0) {
        $$.type = TYPE_FLOAT;
        float val1 = atof($1.value);
        float val2 = atof($3.value);
        snprintf(resultValue, sizeof(resultValue), "%.2f", val1 - val2);
        
        char valueStr[MAX_VALUE_LENGTH];
        createValueString($$.type, resultValue, valueStr);
        
        // Store result in expression value
        strncpy($$.value, resultValue, MAX_NAME_LENGTH - 1);
        $$.value[MAX_NAME_LENGTH - 1] = '\0';

        // Generate quadruplet for subtraction operation
        insererQuadreplet(&q, "-", $1.value, $3.value, temp, qc++);
    } 
    // Handle integer subtraction
    else {
        $$.type = TYPE_INTEGER;
        int val1 = atoi($1.value);
        int val2 = atoi($3.value);
        snprintf(resultValue, sizeof(resultValue), "%d", val1 - val2);
        
        char valueStr[MAX_VALUE_LENGTH];
        createValueString($$.type, resultValue, valueStr);
        
        // Store result in expression value
        strncpy($$.value, resultValue, MAX_NAME_LENGTH - 1);
        $$.value[MAX_NAME_LENGTH - 1] = '\0';

        // Generate quadruplet for subtraction operation
        insererQuadreplet(&q, "-", $1.value, $3.value, temp, qc++);
    }
}


    | Expression MUL Expression {
    char resultValue[MAX_VALUE_LENGTH];
    char temp[MAX_NAME_LENGTH];
    snprintf(temp, sizeof(temp), "t%d", qc);

    // Validate operands for null values
    if (!$1.value || !$3.value) {
        yyerror("Operands for subtraction must be initialized and have valid values.");
        YYERROR;
    }

    // Get type information for operands
    char type1Str[MAX_TYPE_LENGTH];
    char type3Str[MAX_TYPE_LENGTH];
    getTypeString($1.type, type1Str);
    getTypeString($3.type, type3Str);

    // Handle floating point subtraction
    if (strcmp(type1Str, "float") == 0 || strcmp(type3Str, "float") == 0) {
        $$.type = TYPE_FLOAT;
        float val1 = atof($1.value);
        float val2 = atof($3.value);
        snprintf(resultValue, sizeof(resultValue), "%.2f", val1 * val2);
        
        char valueStr[MAX_VALUE_LENGTH];
        createValueString($$.type, resultValue, valueStr);
        
        // Store result in expression value
        strncpy($$.value, resultValue, MAX_NAME_LENGTH - 1);
        $$.value[MAX_NAME_LENGTH - 1] = '\0';

        // Generate quadruplet for subtraction operation
        insererQuadreplet(&q, "-", $1.value, $3.value, temp, qc++);
    } 
    // Handle integer subtraction
    else {
        $$.type = TYPE_INTEGER;
        int val1 = atoi($1.value);
        int val2 = atoi($3.value);
        snprintf(resultValue, sizeof(resultValue), "%d", val1 * val2);
        
        char valueStr[MAX_VALUE_LENGTH];
        createValueString($$.type, resultValue, valueStr);
        
        // Store result in expression value
        strncpy($$.value, resultValue, MAX_NAME_LENGTH - 1);
        $$.value[MAX_NAME_LENGTH - 1] = '\0';

        // Generate quadruplet for subtraction operation
        insererQuadreplet(&q, "-", $1.value, $3.value, temp, qc++);
    }
}

    | Expression DIV Expression {
    char resultValue[MAX_VALUE_LENGTH];
    char temp[MAX_NAME_LENGTH];
    snprintf(temp, sizeof(temp), "t%d", qc);

    // Validate operands for null values
    if (!$1.value || !$3.value) {
        yyerror("Operands for division must be initialized and have valid values.");
        YYERROR;
    }

    // Check for division by zero
    if (atof($3.value) == 0) {
        yyerror("Division by zero error");
        YYERROR;
    }

    // Get type information for operands
    char type1Str[MAX_TYPE_LENGTH];
    char type3Str[MAX_TYPE_LENGTH];
    getTypeString($1.type, type1Str);
    getTypeString($3.type, type3Str);

    // Always return float for regular division
    $$.type = TYPE_FLOAT;
    float val1 = atof($1.value);
    float val2 = atof($3.value);
    snprintf(resultValue, sizeof(resultValue), "%.2f", val1 / val2);
    
    char valueStr[MAX_VALUE_LENGTH];
    createValueString($$.type, resultValue, valueStr);
    
    // Store result in expression value
    strncpy($$.value, resultValue, MAX_NAME_LENGTH - 1);
    $$.value[MAX_NAME_LENGTH - 1] = '\0';

    // Generate quadruplet for division operation
    insererQuadreplet(&q, "/", $1.value, $3.value, temp, qc++);
}

| Expression DIV Expression {
    char resultValue[MAX_VALUE_LENGTH];
    char temp[MAX_NAME_LENGTH];
    snprintf(temp, sizeof(temp), "t%d", qc);

    // Validate operands for null values
    if (!$1.value || !$3.value) {
        yyerror("Operands for integer division must be initialized and have valid values.");
        YYERROR;
    }

    // Check for division by zero
    if (atoi($3.value) == 0) {
        yyerror("Division by zero error");
        YYERROR;
    }

    // Get type information for operands
    char type1Str[MAX_TYPE_LENGTH];
    char type3Str[MAX_TYPE_LENGTH];
    getTypeString($1.type, type1Str);
    getTypeString($3.type, type3Str);

    // Integer division always returns integer
    $$.type = TYPE_INTEGER;
    int val1 = atoi($1.value);
    int val2 = atoi($3.value);
    snprintf(resultValue, sizeof(resultValue), "%d", val1 / val2);
    
    char valueStr[MAX_VALUE_LENGTH];
    createValueString($$.type, resultValue, valueStr);
    
    // Store result in expression value
    strncpy($$.value, resultValue, MAX_NAME_LENGTH - 1);
    $$.value[MAX_NAME_LENGTH - 1] = '\0';

    // Generate quadruplet for integer division operation
    insererQuadreplet(&q, "DIV", $1.value, $3.value, temp, qc++);
}


    | Expression INT_DIV Expression {
    char resultValue[MAX_VALUE_LENGTH];
    char temp[MAX_NAME_LENGTH];
    snprintf(temp, sizeof(temp), "t%d", qc);

    // Validate operands for null values
    if (!$1.value || !$3.value) {
        yyerror("Operands for integer division must be initialized and have valid values.");
        YYERROR;
    }

    // Check for division by zero
    if (atoi($3.value) == 0) {
        yyerror("Division by zero error");
        YYERROR;
    }

    // Get type information for operands
    char type1Str[MAX_TYPE_LENGTH];
    char type3Str[MAX_TYPE_LENGTH];
    getTypeString($1.type, type1Str);
    getTypeString($3.type, type3Str);

    // Integer division always returns integer
    $$.type = TYPE_INTEGER;
    int val1 = atoi($1.value);
    int val2 = atoi($3.value);
    snprintf(resultValue, sizeof(resultValue), "%d", val1 / val2);
    
    char valueStr[MAX_VALUE_LENGTH];
    createValueString($$.type, resultValue, valueStr);
    
    // Store result in expression value
    strncpy($$.value, resultValue, MAX_NAME_LENGTH - 1);
    $$.value[MAX_NAME_LENGTH - 1] = '\0';

    // Generate quadruplet for integer division operation
    insererQuadreplet(&q, "DIV", $1.value, $3.value, temp, qc++);
}

    | Expression MOD Expression {
    char resultValue[MAX_VALUE_LENGTH];
    char temp[MAX_NAME_LENGTH];
    snprintf(temp, sizeof(temp), "t%d", qc);

    // Validate operands for null values
    if (!$1.value || !$3.value) {
        yyerror("Operands for modulo must be initialized and have valid values.");
        YYERROR;
    }

    // Check for modulo by zero
    if (atoi($3.value) == 0) {
        yyerror("Modulo by zero error");
        YYERROR;
    }

    // Get type information for operands
    char type1Str[MAX_TYPE_LENGTH];
    char type3Str[MAX_TYPE_LENGTH];
    getTypeString($1.type, type1Str);
    getTypeString($3.type, type3Str);

    // Modulo operation always returns integer
    $$.type = TYPE_INTEGER;
    int val1 = atoi($1.value);
    int val2 = atoi($3.value);
    snprintf(resultValue, sizeof(resultValue), "%d", val1 % val2);
    
    char valueStr[MAX_VALUE_LENGTH];
    createValueString($$.type, resultValue, valueStr);
    
    // Store result in expression value
    strncpy($$.value, resultValue, MAX_NAME_LENGTH - 1);
    $$.value[MAX_NAME_LENGTH - 1] = '\0';

    // Generate quadruplet for modulo operation
    insererQuadreplet(&q, "MOD", $1.value, $3.value, temp, qc++);
}


    |Expression EQUAL Expression {
    char resultValue[MAX_VALUE_LENGTH];
    char temp[MAX_NAME_LENGTH];
    snprintf(temp, sizeof(temp), "t%d", qc);

    // Validate operands for null values
    if (!$1.value || !$3.value) {
        yyerror("Operands for equality comparison must be initialized and have valid values.");
        YYERROR;
    }

    // Get type information for operands
    char type1Str[MAX_TYPE_LENGTH];
    char type3Str[MAX_TYPE_LENGTH];
    getTypeString($1.type, type1Str);
    getTypeString($3.type, type3Str);

    // Handle string comparison
    if (strcmp(type1Str, "string") == 0 && strcmp(type3Str, "string") == 0) {
        int result = strcmp($1.value, $3.value) == 0;
        snprintf(resultValue, sizeof(resultValue), "%s", result ? "true" : "false");
    }
    // Handle numeric comparison
    else {
        float val1 = atof($1.value);
        float val2 = atof($3.value);
        int result = (val1 == val2);
        snprintf(resultValue, sizeof(resultValue), "%s", result ? "true" : "false");
    }

    // Set type to boolean
    $$.type = TYPE_BOOLEAN;
    
    char valueStr[MAX_VALUE_LENGTH];
    createValueString($$.type, resultValue, valueStr);
    
    // Store result in expression value
    strncpy($$.value, resultValue, MAX_NAME_LENGTH - 1);
    $$.value[MAX_NAME_LENGTH - 1] = '\0';

    // Generate quadruplet for equality comparison
    insererQuadreplet(&q, "==", $1.value, $3.value, temp, qc++);
}


    | Expression NOT_EQUAL Expression {
    char resultValue[MAX_VALUE_LENGTH];
    char temp[MAX_NAME_LENGTH];
    snprintf(temp, sizeof(temp), "t%d", qc);

    // Validate operands for null values
    if (!$1.value || !$3.value) {
        yyerror("Operands for inequality comparison must be initialized and have valid values.");
        YYERROR;
    }

    // Get type information for operands
    char type1Str[MAX_TYPE_LENGTH];
    char type3Str[MAX_TYPE_LENGTH];
    getTypeString($1.type, type1Str);
    getTypeString($3.type, type3Str);

    // Handle string comparison
    if (strcmp(type1Str, "string") == 0 && strcmp(type3Str, "string") == 0) {
        int result = strcmp($1.value, $3.value) != 0;
        snprintf(resultValue, sizeof(resultValue), "%s", result ? "true" : "false");
    }
    // Handle numeric comparison
    else {
        float val1 = atof($1.value);
        float val2 = atof($3.value);
        int result = (val1 != val2);
        snprintf(resultValue, sizeof(resultValue), "%s", result ? "true" : "false");
    }

    // Set type to boolean
    $$.type = TYPE_BOOLEAN;
    
    char valueStr[MAX_VALUE_LENGTH];
    createValueString($$.type, resultValue, valueStr);
    
    // Store result in expression value
    strncpy($$.value, resultValue, MAX_NAME_LENGTH - 1);
    $$.value[MAX_NAME_LENGTH - 1] = '\0';

    // Generate quadruplet for inequality comparison
    insererQuadreplet(&q, "!=", $1.value, $3.value, temp, qc++);
}


    |Expression GREATER_THAN Expression {
    char resultValue[MAX_VALUE_LENGTH];
    char temp[MAX_NAME_LENGTH];
    snprintf(temp, sizeof(temp), "t%d", qc);

    // Validate operands for null values
    if (!$1.value || !$3.value) {
        yyerror("Operands for greater than comparison must be initialized and have valid values.");
        YYERROR;
    }

    // Get type information for operands
    char type1Str[MAX_TYPE_LENGTH];
    char type3Str[MAX_TYPE_LENGTH];
    getTypeString($1.type, type1Str);
    getTypeString($3.type, type3Str);

    // Handle string comparison
    if (strcmp(type1Str, "string") == 0 && strcmp(type3Str, "string") == 0) {
        int result = strcmp($1.value, $3.value) > 0;
        snprintf(resultValue, sizeof(resultValue), "%s", result ? "true" : "false");
    }
    // Handle float comparison
    else if (strcmp(type1Str, "float") == 0 || strcmp(type3Str, "float") == 0) {
        float val1 = atof($1.value);
        float val2 = atof($3.value);
        int result = (val1 > val2);
        snprintf(resultValue, sizeof(resultValue), "%s", result ? "true" : "false");
    }
    // Handle integer comparison
    else {
        int val1 = atoi($1.value);
        int val2 = atoi($3.value);
        int result = (val1 > val2);
        snprintf(resultValue, sizeof(resultValue), "%s", result ? "true" : "false");
    }

    // Set type to boolean
    $$.type = TYPE_BOOLEAN;
    
    char valueStr[MAX_VALUE_LENGTH];
    createValueString($$.type, resultValue, valueStr);
    
    // Store result in expression value
    strncpy($$.value, resultValue, MAX_NAME_LENGTH - 1);
    $$.value[MAX_NAME_LENGTH - 1] = '\0';

    // Generate quadruplet for greater than comparison
    insererQuadreplet(&q, ">", $1.value, $3.value, temp, qc++);
}



    | Expression LESS_THAN Expression {
    char resultValue[MAX_VALUE_LENGTH];
    char temp[MAX_NAME_LENGTH];
    snprintf(temp, sizeof(temp), "t%d", qc);

    // Validate operands for null values
    if (!$1.value || !$3.value) {
        yyerror("Operands for less than comparison must be initialized and have valid values.");
        YYERROR;
    }

    // Get type information for operands
    char type1Str[MAX_TYPE_LENGTH];
    char type3Str[MAX_TYPE_LENGTH];
    getTypeString($1.type, type1Str);
    getTypeString($3.type, type3Str);

    // Handle string comparison
    if (strcmp(type1Str, "string") == 0 && strcmp(type3Str, "string") == 0) {
        strcpy(resultValue, strcmp($1.value, $3.value) < 0 ? "true" : "false");
    }
    // Handle float comparison
    else if (strcmp(type1Str, "float") == 0 || strcmp(type3Str, "float") == 0) {
        float val1 = atof($1.value);
        float val2 = atof($3.value);
        strcpy(resultValue, val1 < val2 ? "true" : "false");
    }
    // Handle integer comparison
    else {
        int val1 = atoi($1.value);
        int val2 = atoi($3.value);
        strcpy(resultValue, val1 < val2 ? "true" : "false");
    }

    // Set type to boolean
    $$.type = TYPE_BOOLEAN;
    strcpy($$.value, resultValue);

    // Generate quadruplet for less than comparison
    insererQuadreplet(&q, "<", $1.value, $3.value, temp, qc++);
}


    | Expression GREATER_EQUAL Expression {
    char resultValue[MAX_VALUE_LENGTH];
    char temp[MAX_NAME_LENGTH];
    snprintf(temp, sizeof(temp), "t%d", qc);

    // Validate operands for null values
    if (!$1.value || !$3.value) {
        yyerror("Operands for greater than or equal comparison must be initialized and have valid values.");
        YYERROR;
    }

    // Get type information for operands
    char type1Str[MAX_TYPE_LENGTH];
    char type3Str[MAX_TYPE_LENGTH];
    getTypeString($1.type, type1Str);
    getTypeString($3.type, type3Str);

    // Handle string comparison
    if (strcmp(type1Str, "string") == 0 && strcmp(type3Str, "string") == 0) {
        strcpy(resultValue, strcmp($1.value, $3.value) >= 0 ? "true" : "false");
    }
    // Handle float comparison
    else if (strcmp(type1Str, "float") == 0 || strcmp(type3Str, "float") == 0) {
        float val1 = atof($1.value);
        float val2 = atof($3.value);
        strcpy(resultValue, val1 >= val2 ? "true" : "false");
    }
    // Handle integer comparison
    else {
        int val1 = atoi($1.value);
        int val2 = atoi($3.value);
        strcpy(resultValue, val1 >= val2 ? "true" : "false");
    }

    // Set type to boolean
    $$.type = TYPE_BOOLEAN;
    strcpy($$.value, resultValue);

    // Generate quadruplet for greater than or equal comparison
    insererQuadreplet(&q, ">=", $1.value, $3.value, temp, qc++);
}


    | Expression LESS_EQUAL Expression {
    char resultValue[MAX_VALUE_LENGTH];
    char temp[MAX_NAME_LENGTH];
    snprintf(temp, sizeof(temp), "t%d", qc);

    // Validate operands for null values
    if (!$1.value || !$3.value) {
        yyerror("Operands for less than or equal comparison must be initialized and have valid values.");
        YYERROR;
    }

    // Get type information for operands
    char type1Str[MAX_TYPE_LENGTH];
    char type3Str[MAX_TYPE_LENGTH];
    getTypeString($1.type, type1Str);
    getTypeString($3.type, type3Str);

    // Handle string comparison
    if (strcmp(type1Str, "string") == 0 && strcmp(type3Str, "string") == 0) {
        strcpy(resultValue, strcmp($1.value, $3.value) <= 0 ? "true" : "false");
    }
    // Handle float comparison
    else if (strcmp(type1Str, "float") == 0 || strcmp(type3Str, "float") == 0) {
        float val1 = atof($1.value);
        float val2 = atof($3.value);
        strcpy(resultValue, val1 <= val2 ? "true" : "false");
    }
    // Handle integer comparison
    else {
        int val1 = atoi($1.value);
        int val2 = atoi($3.value);
        strcpy(resultValue, val1 <= val2 ? "true" : "false");
    }

    // Set type to boolean
    $$.type = TYPE_BOOLEAN;
    strcpy($$.value, resultValue);

    // Generate quadruplet for less than or equal comparison
    insererQuadreplet(&q, "<=", $1.value, $3.value, temp, qc++);
}


    | Expression LOGICAL_AND Expression {
    char resultValue[MAX_VALUE_LENGTH];
    char temp[MAX_NAME_LENGTH];
    snprintf(temp, sizeof(temp), "t%d", qc);

    // Validate operands for null values
    if (!$1.value || !$3.value) {
        yyerror("Operands for logical AND must be initialized and have valid values.");
        YYERROR;
    }

    // Get type information for operands
    char type1Str[MAX_TYPE_LENGTH];
    char type3Str[MAX_TYPE_LENGTH];
    getTypeString($1.type, type1Str);
    getTypeString($3.type, type3Str);

    // Both operands must be boolean
    if ($1.type != TYPE_BOOLEAN || $3.type != TYPE_BOOLEAN) {
        yyerror("Logical AND requires boolean operands");
        YYERROR;
    }

    // Perform logical AND operation
    bool val1 = strcmp($1.value, "true") == 0;
    bool val2 = strcmp($3.value, "true") == 0;
    strcpy(resultValue, (val1 && val2) ? "true" : "false");

    // Set type to boolean
    $$.type = TYPE_BOOLEAN;
    strcpy($$.value, resultValue);

    // Generate quadruplet for logical AND operation
    insererQuadreplet(&q, "AND", $1.value, $3.value, temp, qc++);
}
 

    | Expression LOGICAL_OR Expression {
    char resultValue[MAX_VALUE_LENGTH];
    char temp[MAX_NAME_LENGTH];
    snprintf(temp, sizeof(temp), "t%d", qc);

    // Validate operands for null values
    if (!$1.value || !$3.value) {
        yyerror("Operands for logical OR must be initialized and have valid values.");
        YYERROR;
    }

    // Get type information for operands
    char type1Str[MAX_TYPE_LENGTH];
    char type3Str[MAX_TYPE_LENGTH];
    getTypeString($1.type, type1Str);
    getTypeString($3.type, type3Str);

    // Both operands must be boolean
    if ($1.type != TYPE_BOOLEAN || $3.type != TYPE_BOOLEAN) {
        yyerror("Logical OR requires boolean operands");
        YYERROR;
    }

    // Perform logical OR operation
    bool val1 = strcmp($1.value, "true") == 0;
    bool val2 = strcmp($3.value, "true") == 0;
    strcpy(resultValue, (val1 || val2) ? "true" : "false");

    // Set type to boolean
    $$.type = TYPE_BOOLEAN;
    strcpy($$.value, resultValue);

    // Generate quadruplet for logical OR operation
    insererQuadreplet(&q, "OR", $1.value, $3.value, temp, qc++);
}


    | LOGICAL_NOT Expression {
    char resultValue[MAX_VALUE_LENGTH];
    char temp[MAX_NAME_LENGTH];
    snprintf(temp, sizeof(temp), "t%d", qc);

    // Validate operand for null value
    if (!$2.value) {
        yyerror("Operand for logical NOT must be initialized and have a valid value.");
        YYERROR;
    }

    // Get type information for operand
    char typeStr[MAX_TYPE_LENGTH];
    getTypeString($2.type, typeStr);

    // Operand must be boolean
    if ($2.type != TYPE_BOOLEAN) {
        yyerror("Logical NOT requires a boolean operand");
        YYERROR;
    }

    // Perform logical NOT operation
    bool val = strcmp($2.value, "true") == 0;
    strcpy(resultValue, (!val) ? "true" : "false");

    // Set type to boolean
    $$.type = TYPE_BOOLEAN;
    strcpy($$.value, resultValue);

    // Generate quadruplet for logical NOT operation
    insererQuadreplet(&q, "NOT", $2.value, "", temp, qc++);
}


    | SUB Expression %prec UMINUS {
    char resultValue[MAX_VALUE_LENGTH];
    char temp[MAX_NAME_LENGTH];
    snprintf(temp, sizeof(temp), "t%d", qc);

    // Validate operand for null value
    if (!$2.value) {
        yyerror("Operand for unary minus must be initialized and have a valid value.");
        YYERROR;
    }

    // Get type information for operand
    char typeStr[MAX_TYPE_LENGTH];
    getTypeString($2.type, typeStr);

    // Handle float negation
    if (strcmp(typeStr, "float") == 0) {
        $$.type = TYPE_FLOAT;
        float val = -atof($2.value);
        snprintf(resultValue, sizeof(resultValue), "%.2f", val);
    }
    // Handle integer negation
    else if (strcmp(typeStr, "int") == 0) {
        $$.type = TYPE_INTEGER;
        int val = -atoi($2.value);
        snprintf(resultValue, sizeof(resultValue), "%d", val);
    }
    // Error for non-numeric types
    else {
        yyerror("Unary minus requires numeric operand");
        YYERROR;
    }

    strcpy($$.value, resultValue);

    // Generate quadruplet for unary minus operation
    insererQuadreplet(&q, "UMINUS", $2.value, "", temp, qc++);
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
        
        // Type compatibility check
        int symbolType;
        if (strcmp(symbol->type, "int") == 0) symbolType = TYPE_INTEGER;
        else if (strcmp(symbol->type, "float") == 0) symbolType = TYPE_FLOAT;
        else if (strcmp(symbol->type, "string") == 0) symbolType = TYPE_STRING;
        else if (strcmp(symbol->type, "bool") == 0) symbolType = TYPE_BOOLEAN;
        
        if (symbolType != $3.type) {
            yyerror("Type mismatch in assignment");
            YYERROR;
        }
        
        // Update symbol table with the new value
        updateSymbolValue(symbolTable, symbol->id, $3.value, 0);
        
        // Generate quadruplet for assignment
        insererQuadreplet(&q, ":=", $3.value, "", $1, qc++);
    }
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


SimpleIf:
    IF Expression COLON StatementList ENDIF


IfWithElse:
    IF Expression COLON StatementList ElseIfList


ElseIfList:
    ELSE COLON StatementList ENDIF {
        // Generate quadruplets for ELSE block
        
    }
    | ELSEIF Expression COLON StatementList ElseIfList 
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