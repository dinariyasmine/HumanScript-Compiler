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
        // cest pour le cas ou on a par exemple : "Hello" + "Aicha"
        if ($1.type == TYPE_STRING && $3.type == TYPE_STRING) {
            $$.type = TYPE_STRING;
            char* result = malloc(strlen($1.stringValue) + strlen($3.stringValue) + 1);
            strcpy(result, $1.stringValue);
            strcat(result, $3.stringValue);
            strncpy($$.stringValue, result, 254);
            $$.stringValue[254] = '\0';
            free(result);
            
            char temp[20];
            sprintf(temp, "t%d", qc);
            insererQuadreplet(&q, "CONCAT", $1.stringValue, $3.stringValue, temp, qc++);
        } else {
            // quand on a par exemple 5 + 3
            $$.type = validateArithmeticOperation($1, $3);
            if ($$.type == TYPE_INTEGER) {
                $$.integerValue = $1.integerValue + $3.integerValue;
            } else if ($$.type == TYPE_FLOAT) {
                $$.floatValue = $1.floatValue + $3.floatValue;
            }
            char temp[20];
            sprintf(temp, "t%d", qc);
            insererQuadreplet(&q, "+", getExpressionValue($1), getExpressionValue($3), temp, qc++);
        }
    }

    | Expression SUB Expression {
        $$.type = validateArithmeticOperation($1, $3);
        if ($$.type == TYPE_INTEGER) {
            $$.integerValue = $1.integerValue - $3.integerValue;
        } else if ($$.type == TYPE_FLOAT) {
            $$.floatValue = $1.floatValue - $3.floatValue;
        }
        char temp[20];
        sprintf(temp, "t%d", qc);
        insererQuadreplet(&q, "-", getExpressionValue($1), getExpressionValue($3), temp, qc++);
    }
    | Expression MUL Expression {
        $$.type = validateArithmeticOperation($1, $3);
        if ($$.type == TYPE_INTEGER) {
            $$.integerValue = $1.integerValue * $3.integerValue;
        } else if ($$.type == TYPE_FLOAT) {
            $$.floatValue = $1.floatValue * $3.floatValue;
        }
        char temp[20];
        sprintf(temp, "t%d", qc);
        insererQuadreplet(&q, "*", getExpressionValue($1), getExpressionValue($3), temp, qc++);
    }
    | Expression DIV Expression {
        if ($3.type == TYPE_INTEGER && $3.integerValue == 0 || 
            $3.type == TYPE_FLOAT && $3.floatValue == 0.0) {
            yyerror("Division by zero");
            YYERROR;
        }
        $$.type = TYPE_FLOAT;
        $$.floatValue = ($1.type == TYPE_INTEGER ? $1.integerValue : $1.floatValue) / 
                       ($3.type == TYPE_INTEGER ? $3.integerValue : $3.floatValue);
        char temp[20];
        sprintf(temp, "t%d", qc);
        insererQuadreplet(&q, "/", getExpressionValue($1), getExpressionValue($3), temp, qc++);
    }
    | Expression INT_DIV Expression {
        if ($3.type == TYPE_INTEGER && $3.integerValue == 0) {
            yyerror("Division by zero");
            YYERROR;
        }
        $$.type = TYPE_INTEGER;
        $$.integerValue = $1.integerValue / $3.integerValue;
        char temp[20];
        sprintf(temp, "t%d", qc);
        insererQuadreplet(&q, "DIV", getExpressionValue($1), getExpressionValue($3), temp, qc++);
    }
    | Expression MOD Expression {
        if ($3.type == TYPE_INTEGER && $3.integerValue == 0) {
            yyerror("Modulo by zero");
            YYERROR;
        }
        $$.type = TYPE_INTEGER;
        $$.integerValue = $1.integerValue % $3.integerValue;
        char temp[20];
        sprintf(temp, "t%d", qc);
        insererQuadreplet(&q, "MOD", getExpressionValue($1), getExpressionValue($3), temp, qc++);
    }
    | Expression EQUAL Expression {
        $$.type = TYPE_BOOLEAN;
        $$.booleanValue = compareExpressions($1, $3) == 0;
        printf("EQUAL Operation: %d == %d = %d\n", 
               $1.integerValue, $3.integerValue, $$.booleanValue);

        char temp[20];
        sprintf(temp, "t%d", qc);
        insererQuadreplet(&q, "==", getExpressionValue($1), getExpressionValue($3), temp, qc++);
    }
    | Expression NOT_EQUAL Expression {
        $$.type = TYPE_BOOLEAN;
        $$.booleanValue = compareExpressions($1, $3) != 0;
        char temp[20];
        sprintf(temp, "t%d", qc);
        insererQuadreplet(&q, "!=", getExpressionValue($1), getExpressionValue($3), temp, qc++);
    }
    | Expression GREATER_THAN Expression {
        $$.type = TYPE_BOOLEAN;
        $$.booleanValue = compareExpressions($1, $3) > 0;
        char temp[20];
        sprintf(temp, "t%d", qc);
        insererQuadreplet(&q, ">", getExpressionValue($1), getExpressionValue($3), temp, qc++);
    }
    | Expression LESS_THAN Expression {
        $$.type = TYPE_BOOLEAN;
        $$.booleanValue = compareExpressions($1, $3) < 0;
        char temp[20];
        sprintf(temp, "t%d", qc);
        insererQuadreplet(&q, "<", getExpressionValue($1), getExpressionValue($3), temp, qc++);
    }
    | Expression GREATER_EQUAL Expression {
        $$.type = TYPE_BOOLEAN;
        $$.booleanValue = compareExpressions($1, $3) >= 0;
        char temp[20];
        sprintf(temp, "t%d", qc);
        insererQuadreplet(&q, ">=", getExpressionValue($1), getExpressionValue($3), temp, qc++);
    }
    | Expression LESS_EQUAL Expression {
        $$.type = TYPE_BOOLEAN;
        $$.booleanValue = compareExpressions($1, $3) <= 0;
        char temp[20];
        sprintf(temp, "t%d", qc);
        insererQuadreplet(&q, "<=", getExpressionValue($1), getExpressionValue($3), temp, qc++);
    }

    | Expression LOGICAL_AND Expression {

        // les 2 expressions doivent etre des booleans
        if ($1.type != TYPE_BOOLEAN || $3.type != TYPE_BOOLEAN) {
            yyerror("Logical AND operation requires boolean operands");
            YYERROR;
        }
        
        
        $$.type = TYPE_BOOLEAN;
        $$.booleanValue = $1.booleanValue && $3.booleanValue;
        
        // Generate quadruplet
        char temp[20];
        sprintf(temp, "t%d", qc);
        insererQuadreplet(&q, "AND", 
            $1.booleanValue ? "true" : "false",
            $3.booleanValue ? "true" : "false", 
            temp, 
            qc++);
    }

    | Expression LOGICAL_OR Expression {
        if ($1.type != TYPE_BOOLEAN || $3.type != TYPE_BOOLEAN) {
            yyerror("Logical OR operation requires boolean operands");
            YYERROR;
        }
        $$.type = TYPE_BOOLEAN;
        $$.booleanValue = $1.booleanValue || $3.booleanValue;
        
        printf("OR Operation: %d || %d = %d\n", 
               $1.booleanValue, $3.booleanValue, $$.booleanValue);
        
        char temp[20];
        sprintf(temp, "t%d", qc);
        insererQuadreplet(&q, "OR", getExpressionValue($1), getExpressionValue($3), temp, qc++);
    }
    | LOGICAL_NOT Expression {
        if ($2.type != TYPE_BOOLEAN) {
            yyerror("Logical NOT operation requires boolean operand");
            YYERROR;
        }
        $$.type = TYPE_BOOLEAN;
        $$.booleanValue = !$2.booleanValue;
        char temp[20];
        sprintf(temp, "t%d", qc);
        insererQuadreplet(&q, "NOT", getExpressionValue($2), "", temp, qc++);
    }
    | SUB Expression %prec UMINUS {
        if ($2.type != TYPE_INTEGER && $2.type != TYPE_FLOAT) {
            yyerror("Unary minus requires numeric operand");
            YYERROR;
        }
        $$.type = $2.type;
        if ($2.type == TYPE_INTEGER) {
            $$.integerValue = -$2.integerValue;
        } else {
            $$.floatValue = -$2.floatValue;
        }
        char temp[20];
        sprintf(temp, "t%d", qc);
        insererQuadreplet(&q, "NEG", getExpressionValue($2), "", temp, qc++);
    }
    ;



SimpleExpression:
    INT_LITERAL {
        $$.type = TYPE_INTEGER;
        $$.integerValue = $1;
    }
    | FLOAT_LITERAL {
        $$.type = TYPE_FLOAT;
        $$.floatValue = $1;  
    }

    | STRING_LITERAL {
        $$.type = TYPE_STRING;
        strncpy($$.stringValue, $1, 254);
        $$.stringValue[254] = '\0';
    }

    | ID {
            // symbol est le symbole recupere a partir de la table des symboles
            SymbolEntry *symbol = lookupSymbolByName(symbolTable, $1, 0);

            // on verifie si le symbole existe
            if (!symbol) {
                yyerror("Undefined identifier");
                YYERROR;
            }
            
            // on extrait le type a partir du symbole recupere et on le stocke dans symbolType c'est pour le cas 
            // ou le symbole est dans une expression ou on a besoin de son type
            if (strcmp(symbol->type, "bool") == 0) {
                
                $$.type = TYPE_BOOLEAN;
                $$.booleanValue = symbol->value.intValue != 0;
            } else if (strcmp(symbol->type, "int") == 0) {
                $$.type = TYPE_INTEGER;
                $$.integerValue = symbol->value.intValue;
            } else if (strcmp(symbol->type, "float") == 0) {
                $$.type = TYPE_FLOAT;
                $$.floatValue = symbol->value.floatValue;
            } else if (strcmp(symbol->type, "string") == 0) {
                $$.type = TYPE_STRING;
                strncpy($$.stringValue, symbol->value.stringValue, 254);
                $$.stringValue[254] = '\0';
            }
        }

    | TRUE {
        // on retourne le type et la valeur du boolean
        $$.type = TYPE_BOOLEAN;
        $$.booleanValue = true;
    }
    | FALSE {
        $$.type = TYPE_BOOLEAN;
        $$.booleanValue = false;
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
    | LET Type ID BE Expression {
        printf("Declaration with initialization\n");
        
        // Check for existing symbol and handle redeclaration
        SymbolEntry *existingSymbol = symbolExistsByName(symbolTable, $3, 0);
        
        if (existingSymbol != NULL) {
            printf("Warning: Redeclaring '%s'. Previous value will be overwritten.\n", $3);
            deleteSymbolByName(symbolTable, $3);
        }
        
        // Initialize symbol value
        SymbolValue value = {0};
        if (!validateAndSetValue(&value, $5, $2)) {
            YYERROR;
        }
        
        // Insert into symbol table
        char typeStr[MAX_TYPE_LENGTH];
        getTypeString($2, typeStr);
        insertSymbol(symbolTable, $3, typeStr, value, 0, false, true);
        
        // Generate quadruplet for initialization
        char tempValue[30];
        switch($2) {
            case TYPE_INTEGER:
                sprintf(tempValue, "%d", value.intValue);
                break;
            case TYPE_FLOAT:
                sprintf(tempValue, "%.2f", value.floatValue);
                break;
            case TYPE_STRING:
                sprintf(tempValue, "\"%s\"", value.stringValue);
                break;
            case TYPE_BOOLEAN:
                sprintf(tempValue, "%s", value.intValue ? "true" : "false");
                break;
        }
        insererQuadreplet(&q, ":=", tempValue, "", $3, qc++);
        
        $$ = lookupSymbolByName(symbolTable, $3, 0);
        printf("Symbol '%s' inserted successfully\n", $3);
    }
    | CONST Type ID BE Expression {
        printf("Constant declaration\n");
        
        // Check for existing symbol
        if (symbolExistsByName(symbolTable, $3, 0)) {
            yyerror("Cannot redeclare identifier");
            YYERROR;
        }
        
        // Initialize and validate constant value
        SymbolValue value = {0};
        if (!validateAndSetValue(&value, $5, $2)) {
            YYERROR;
        }
        
        // Insert constant into symbol table
        char typeStr[MAX_TYPE_LENGTH];
        getTypeString($2, typeStr);
        insertSymbol(symbolTable, $3, typeStr, value, 0, true, true);
        
        // Generate quadruplet for constant initialization
        char tempValue[30];
        switch($2) {
            case TYPE_INTEGER:
                sprintf(tempValue, "%d", value.intValue);
                break;
            case TYPE_FLOAT:
                sprintf(tempValue, "%.2f", value.floatValue);
                break;
            case TYPE_STRING:
                sprintf(tempValue, "\"%s\"", value.stringValue);
                break;
            case TYPE_BOOLEAN:
                sprintf(tempValue, "%s", value.intValue ? "true" : "false");
                break;
        }
        insererQuadreplet(&q, ":=", tempValue, "", $3, qc++);
        
        printf("Constant '%s' declared successfully\n", $3);
    }
    | Type ID {
        printf("Simple declaration without initialization\n");
        
        // Check for existing symbol
        if (symbolExistsByName(symbolTable, $2, 0)) {
            yyerror("Cannot redeclare identifier");
            YYERROR;
        }
        
        // Initialize with default value
        SymbolValue value = {0};
        initDefaultValue(&value, $1);
        
        // Insert into symbol table
        char typeStr[MAX_TYPE_LENGTH];
        getTypeString($1, typeStr);
        insertSymbol(symbolTable, $2, typeStr, value, 0, false, false);
        
        // Generate quadruplet for default initialization
        char defaultValue[30];
        switch($1) {
            case TYPE_INTEGER:
                strcpy(defaultValue, "0");
                break;
            case TYPE_FLOAT:
                strcpy(defaultValue, "0.0");
                break;
            case TYPE_BOOLEAN:
                strcpy(defaultValue, "false");
                break;
            case TYPE_STRING:
                strcpy(defaultValue, "\"\"");
                break;
        }
        insererQuadreplet(&q, ":=", defaultValue, "", $2, qc++);
        
        printf("Symbol '%s' declared without initialization\n", $2);
    }
    | LET ARRAY Type ID BE ArrayLiteral {
        printf("Array declaration with initialization started.\n");
        printf("Current array base type: %d\n", currentArrayType);
        
        // Check for existing symbol
        if (symbolExistsByName(symbolTable, $4, 0)) {
            yyerror("Cannot redeclare identifier");
            YYERROR;
        }
        
        // Verify array initialization
        ArrayType* arr = (ArrayType*)$6.data;
        if (!arr) {
            printf("Error: Array initialization failed for identifier '%s'.\n", $4);
            yyerror("Invalid array initialization");
            YYERROR;
        }
        
        // Verify array type matches declared type
        if (arr->elementType != currentArrayType) {
            char expectedType[MAX_TYPE_LENGTH];
            char gotType[MAX_TYPE_LENGTH];
            getTypeString(currentArrayType, expectedType);
            getTypeString(arr->elementType, gotType);
            printf("Error: Array type mismatch. Expected %s, got %s\n", expectedType, gotType);
            yyerror("Array type mismatch");
            YYERROR;
        }
        
        // Insert into symbol table
        SymbolValue value = {0};
        value.arrayValue = arr;
        char typeStr[MAX_TYPE_LENGTH];
        getTypeString(TYPE_ARRAY, typeStr);
        
        insertSymbol(symbolTable, $4, typeStr, value, 0, false, true);
        
        // Generate array declaration quadruplet
        char arraySize[30];
        sprintf(arraySize, "%d", arr->length);
        insererQuadreplet(&q, "ARRAY", $4, arraySize, "", qc++);
        
        // Generate quadruplets for each array element
        for(size_t i = 0; i < arr->length; i++) {
            char index[30], elemValue[255];
            sprintf(index, "%zu", i);
            sprintf(elemValue, "%s", arr->data[i].stringValue);
            insererQuadreplet(&q, "SET_ELEM", $4, index, elemValue, qc++);
        }
        printf("Array '%s' declared successfully.\n", $4);
    }
    ;

Type:
    INT     { 
        $$ = TYPE_INTEGER; 
        currentArrayType = TYPE_INTEGER;  
        printf("Setting type to INTEGER (%d)\n", TYPE_INTEGER);
    }
    | FLOAT { 
        $$ = TYPE_FLOAT;
        currentArrayType = TYPE_FLOAT;
        printf("Setting type to FLOAT (%d)\n", TYPE_FLOAT);
    }
    | BOOL  { 
        $$ = TYPE_BOOLEAN;
        currentArrayType = TYPE_BOOLEAN;
        printf("Setting type to BOOLEAN (%d)\n", TYPE_BOOLEAN);
    }
    | STR   { 
        $$ = TYPE_STRING;
        currentArrayType = TYPE_STRING;
        printf("Setting type to STRING (%d)\n", TYPE_STRING);
    }
    | ARRAY Type { 
        $$ = TYPE_ARRAY;
        printf("Setting ARRAY type with base type: %d\n", currentArrayType);
        
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
        
        // on extrait le type a partir du symbole recupere et on le stocke dans symbolType
        int symbolType;
        if (strcmp(symbol->type, "int") == 0) {
            symbolType = TYPE_INTEGER;
        } else if (strcmp(symbol->type, "float") == 0) {
            symbolType = TYPE_FLOAT;
        } else if (strcmp(symbol->type, "string") == 0) {
            symbolType = TYPE_STRING;
        } else if (strcmp(symbol->type, "boolean") == 0) {
            symbolType = TYPE_BOOLEAN;
        } else {
            symbolType = -1; // Unknown type
        }
        
        // Create variable structure for return value
        variable var;
        var.entry = symbol;
        
        // Update symbol value
        SymbolValue newValue = {0};
        // on verifie si la valeur a affecter est du meme type que le symbole
        if (!validateAndSetValue(&newValue, $3, symbolType)) {
            yyerror("Type mismatch in assignment");
            YYERROR;
        }
        
        // Update symbol table avec la nouvelle valeur
        updateSymbolValue(symbolTable, symbol->id, newValue, 0);
        
        //on genere le quadruplet pour l'affectation
        char tempValue[30];
        switch($3.type) {
            case TYPE_INTEGER:
                sprintf(tempValue, "%d", $3.integerValue);
                break;
            case TYPE_FLOAT:
                sprintf(tempValue, "%.2f", $3.floatValue);
                break;
            case TYPE_STRING:
                sprintf(tempValue, "\"%s\"", $3.stringValue);
                break;
            case TYPE_BOOLEAN:
                sprintf(tempValue, "%s", $3.booleanValue ? "true" : "false");
                break;
        }
        insererQuadreplet(&q, ":=", tempValue, "", $1, qc++);
        
        $$ = var;
    }
    ;

PrintStatement:
    PRINT Expression {
        // on genere que le quadruplet pour l'affichage
        char tempValue[30];
        switch($2.type) {
            case TYPE_INTEGER:
                sprintf(tempValue, "%d", $2.integerValue);
                break;
            case TYPE_FLOAT:
                sprintf(tempValue, "%.2f", $2.floatValue);
                break;
            case TYPE_STRING:
                sprintf(tempValue, "\"%s\"", $2.stringValue);
                break;
            case TYPE_BOOLEAN:
                sprintf(tempValue, "%s", $2.booleanValue ? "true" : "false");
                break;
        }
        insererQuadreplet(&q, "PRINT", tempValue, "", "", qc++);
    }
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
        printf("Creating empty array with base type: %d\n", currentArrayType);
        if (currentArrayType < 0) {
            yyerror("Invalid array base type");
            YYERROR;
        }
        $$.type = TYPE_ARRAY;
        ArrayType* arr = createArray(currentArrayType);
        if (!arr) {
            yyerror("Failed to create empty array");
            YYERROR;
        }
        $$.data = arr;
    }
    | LBRACKET ExpressionList RBRACKET {
        printf("Creating array with base type: %d\n", currentArrayType);
        if (currentArrayType < 0) {
            yyerror("Invalid array base type");
            YYERROR;
        }
        ArrayType* arr = createArrayFromExprList($2, currentArrayType);
        if (!arr) {
            yyerror("Failed to create array from expression list");
            YYERROR;
        }
        $$.type = TYPE_ARRAY;
        $$.data = arr;
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

    // Affichage du message de fin
    free(stack);
    // Affichage de table des symboles
    listAllSymbols(symbolTable);
    // Affichage des quadruplets generes
    afficherQuad(q);

    // Liberation de la table des symboles
    freeSymbolTable(symbolTable);
    
    // Fermeture du fichier
    fclose(yyin);
    
    return result;
}