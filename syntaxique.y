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
%type <expression> Expression SimpleExpression ExpressionList
%type <expression> ArrayLiteral
%type <expression> DictLiteral
%type <expression> DictItems
%type <expression> DictItem
%type <type> Type
%type <entry> Declaration Parameter ParameterList NonEmptyParameterList
%type <variable> Assignment

/* Precedence rules */
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
quad * q;
int qc = 1;

void yysuccess(char *s);
void yyerror(const char *s);
void showLexicalError();
%}
%%

Program:
    StatementList
    ;

/* Liste d'instructions : peut être vide ou contenir plusieurs instructions */

StatementList:
    /* empty */                    { }
    | StatementList Statement      { }
    ;

/* Une instruction peut être simple ou composée */
Statement:
    SimpleStatement
    | CompoundStatement
    | COMMENT
    ;

/* Instructions simples : déclarations, affectations, appels... */
SimpleStatement:
    Declaration
    | PrintStatement
    | Assignment
    | FunctionCall
    | InputStatement
    | RETURN Expression
    ;

/* Instructions composées : boucles, fonctions, conditions... */
CompoundStatement:
    LoopStatement
    | Function
    | Condition
    | SwitchStatement
    ;

/* Différents types de boucles */
LoopStatement:
    ForLoop
    | WhileLoop
    | RepeatLoop
    ;


/* Boucle For avec itération sur un tableau */
ForLoop:
    FOR EACH ID IN Expression COLON StatementList ENDFOR
    ;

/* Boucle While classique */
WhileLoop:
    WHILE Expression COLON StatementList ENDWHILE
    ;

/* Boucle Repeat Until */
RepeatLoop:
    REPEAT COLON StatementList UNTIL Expression ENDREPEAT
    ;

/* Expressions avec gestion des priorités */
Expression:
    SimpleExpression
    | Expression ADD Expression
    | Expression SUB Expression
    | Expression MUL Expression
    | Expression DIV Expression
    | Expression INT_DIV Expression
    | Expression MOD Expression
    | Expression EQUAL Expression
    | Expression NOT_EQUAL Expression
    | Expression GREATER_THAN Expression
    | Expression LESS_THAN Expression
    | Expression GREATER_EQUAL Expression
    | Expression LESS_EQUAL Expression
    | Expression LOGICAL_AND Expression
    | Expression LOGICAL_OR Expression
    | LOGICAL_NOT Expression
    | SUB Expression %prec UMINUS
    ;

/* Expressions simples : valeurs, identificateurs, tableaux... */
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
        $$.type = TYPE_STRING;
        strncpy($$.stringValue, $1, 254);  // Now $1 is directly the string
        $$.stringValue[254] = '\0';
        // Note: You might want to look up the actual type from symbol table here
    }
    | TRUE {
        $$.type = TYPE_BOOLEAN;
        $$.booleanValue = true;
    }
    | FALSE {
        $$.type = TYPE_BOOLEAN;
        $$.booleanValue = false;
    }
    | ArrayLiteral
    | DictLiteral
    | LPAREN Expression RPAREN { $$ = $2; }
    | FunctionCall
    ;

Declaration:
    | LET Type ID BE Expression {
        printf("Declaration with initialization\n");
        
        // Check for existing symbol and handle redeclaration
        SymbolEntry *existingSymbol = symbolExistsByName(symbolTable, $3, 0);
        if (existingSymbol != NULL) {
            if (existingSymbol->isConst) {
                yyerror("Cannot redeclare constant");
                YYERROR;
            }
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
        printf("Symbol '%s' declared without initialization\n", $2);
    }
    | LET ARRAY Type ID BE ArrayLiteral {
    printf("Array declaration with initialization\n");

    // Check for existing symbol and handle redeclaration
    SymbolEntry *existingSymbol = symbolExistsByName(symbolTable, $4, 0);
    if (existingSymbol != NULL) {
        yyerror("Cannot redeclare identifier");
        YYERROR;
    }

    // Handle array initialization based on the base type
    ArrayType* arr = (ArrayType*)$6.integerValue; // This is not correct - we need to use the base type here
    if (!arr) {
        yyerror("Invalid array initialization");
        YYERROR;
    }

    // Insert array into the symbol table
    SymbolValue value = {0};
    value.arrayValue = arr;
    char typeStr[MAX_TYPE_LENGTH];
    getTypeString(TYPE_ARRAY, typeStr);
    insertSymbol(symbolTable, $4, typeStr, value, 0, false, true);
    printf("Array '%s' declared successfully\n", $4);
}

    ;

/* Type definitions including array and dict */
Type:
    INT     { $$ = TYPE_INTEGER; }
    | FLOAT { $$ = TYPE_FLOAT; }
    | BOOL  { $$ = TYPE_BOOLEAN; }
    | STR   { $$ = TYPE_STRING; }
    | ARRAY Type {
        $$ = TYPE_ARRAY;
        printf("Array type of %d parsed\n", $2); // Base type of the array
    }
    | DICT Type Type { $$ = TYPE_DICT; }
;



/* Affectation simple */
/* Affectation simple */
Assignment:
    ID EQUAL Expression 
    ;




/* Instruction d'affichage */
PrintStatement:
    PRINT Expression
    ;
InputStatement:
    INPUT Expression TO ID
;

/* Déclaration de fonction */
Function:
    FUNCTION ID COLON Type LPAREN ParameterList RPAREN LBRACE StatementList RBRACE {
        printf("Fonction correcte syntaxiquement\n");
    }
    | FUNCTION ID COLON LPAREN ParameterList RPAREN LBRACE StatementList RBRACE {
        printf("Procédure correcte syntaxiquement\n");
    }
    ;

/* Appel de fonction */
FunctionCall:
    CALL ID WITH PARAMETERS ParameterList LPAREN ExpressionList RPAREN {
        printf("Appel valide avec paramètres\n");
    }
    | CALL ID LPAREN RPAREN {
        printf("Appel valide sans paramètres\n");
    }
    ;

/* Liste des paramètres de fonction */
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

/* Structure conditionnelle If-Else */

Condition:
    SimpleIf
    | IfWithElse
    ;

SimpleIf:
    IF Expression COLON StatementList ENDIF
    ;

IfWithElse:
    IF Expression COLON StatementList ElseIfList
    ;

ElseIfList:
    ELSE COLON StatementList ENDIF
    | ELSEIF Expression COLON StatementList ElseIfList
    ;

/* Structure Switch-Case */
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

/* Définition des littéraux tableau */
ArrayLiteral:
    LBRACKET RBRACKET {
        // Empty array, default initialization
        $$.type = TYPE_ARRAY;
        ArrayType* arr = createArray(TYPE_INTEGER); // Default to int or based on $2
        $$.integerValue = (intptr_t)arr;
    }
    | LBRACKET ExpressionList RBRACKET {
        // Array with elements
        $$.type = TYPE_ARRAY;
        ArrayType* arr = createArrayFromExprList($2); // Create array from expressions
        $$.integerValue = (intptr_t)arr;
    }
;


DictLiteral:
    LBRACE RBRACE {
        // Empty dictionary
        $$.type = TYPE_DICT;
        DictType* dict = createDict($<type>0, $<type>1);  // Get key and value types from context
        $$.integerValue = (intptr_t)dict;
    }
    | LBRACE DictItems RBRACE {
        // Dictionary with items
        $$.type = TYPE_DICT;
        DictType* dict = createDictFromItems($2);
        $$.integerValue = (intptr_t)dict;
    }
    ;

/* Liste d'expressions pour les tableaux */
ExpressionList:
    Expression
    | ExpressionList COMMA Expression
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
    /* Ouverture du fichier d'entrée */
    yyin = fopen("input.txt", "r");
    if (!yyin) {
        fprintf(stderr, "Error: Could not open input file\n");
        return 1;
    }

    // Initialize the symbol table before calling yyparse()
    symbolTable = createSymbolTable();
    if (!symbolTable) {
        fprintf(stderr, "Error: Failed to create symbol table.\n");
        fclose(yyin);
        return 1;
    }

    printf("Lancement de l'analyse syntaxique...\n");
    int result = yyparse();
    
    if (result == 0) {
        printf("Analyse syntaxique terminée avec succès.\n");
    } else {
        printf("Erreur lors de l'analyse syntaxique.\n");
    }

    // Free the symbol table after parsing is complete
    listAllSymbols(symbolTable);  
    freeSymbolTable(symbolTable);

    // Close the input file
    fclose(yyin);
    printf("Fichier d'entrée fermé.\n");

    if (result == 0) {
        printf("Programme terminé avec succès.\n");
    } else {
        printf("Erreur lors de l'exécution du programme.\n");
    }
    
    return result;
}