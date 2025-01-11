%define parse.error verbose

%{


#define simpleToArrayOffset 4
#include <stdio.h>
#include <stdlib.h>
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
%type <type> Type
%type <symbole> Declaration Parameter ParameterList NonEmptyParameterList
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
    SymbolEntry *existingSymbol = symbolExistsByName(symbolTable, $3, 0);
      if (existingSymbol != NULL) {  // If symbol exists
          printf("Warning: Identifier '%s' already exists. Replacing old value.\n", $3);
          
          // Remove the old symbol
          deleteSymbolByName(symbolTable, $3);
      }
    
    // Create a new symbol value
    SymbolValue value = {0};
    char type_str[MAX_TYPE_LENGTH] = {0};
    char valueStr[255] = {0};  // Buffer for string representation
    bool type_match = true;

    // Print the declared type and expression type
    printf("Declared type: %d, Expression type: %d\n", $2, $5.type);
    printf("Identifier name: %s\n", $3);

    // Convert expression value to string for debug
    valeurToString($5, valueStr);
    printf("Expression value: %s\n", valueStr);

    // Handle type matching and assignment
    switch($2) {
        case TYPE_INTEGER:
            strncpy(type_str, "int", MAX_TYPE_LENGTH - 1);
            if ($5.type == TYPE_INTEGER) {
                value.intValue = $5.integerValue;
                printf("Setting integer value: %d\n", value.intValue);
            } else {
                type_match = false;
            }
            break;

        case TYPE_FLOAT:
            strncpy(type_str, "float", MAX_TYPE_LENGTH - 1);
            if ($5.type == TYPE_FLOAT) {
                value.floatValue = $5.floatValue;
                printf("Setting float value: %f\n", value.floatValue);
            } else {
                type_match = false;
            }
            break;

        case TYPE_STRING:
            strncpy(type_str, "string", MAX_TYPE_LENGTH - 1);
            if ($5.type == TYPE_STRING) {
                strncpy(value.stringValue, $5.stringValue, MAX_NAME_LENGTH - 1);
                value.stringValue[MAX_NAME_LENGTH - 1] = '\0';
                printf("Setting string value: %s\n", value.stringValue);
            } else {
                type_match = false;
            }
            break;

        case TYPE_BOOLEAN:
            strncpy(type_str, "bool", MAX_TYPE_LENGTH - 1);
            if ($5.type == TYPE_BOOLEAN) {
                value.intValue = $5.booleanValue ? 1 : 0;  // Assigning 1 for true and 0 for false
                printf("Boolean value set to: %d\n", value.intValue);  // Check if value is correct
            } else {
                type_match = false;
            }
            break;


        default:
            printf("Unsupported type in declaration\n");
            YYERROR;
    }

    // Check for type mismatch
    if (!type_match) {
        printf("Type mismatch: Expected %s, got %s\n", type_str, valueStr);
        YYERROR;
    }

    // Insert the symbol into the symbol table
    insertSymbol(symbolTable, $3, type_str, value, 0, false, true);
    printf("Symbol inserted successfully\n");
}

    | CONST Type ID BE Expression {
        printf("Constant declaration\n");
        
        // Create a new symbol value
        SymbolValue value = {0};
        char type_str[MAX_TYPE_LENGTH] = {0};
        bool type_match = true;

        printf("Declared type: %d, Expression type: %d\n", $2, $5.type);
        printf("Identifier name: %s\n", $3);  // $3 is now directly the identifier string

        // Convert numeric type to string representation and check type match
        switch($2) {
            case TYPE_INTEGER:
                strncpy(type_str, "int", MAX_TYPE_LENGTH - 1);
                if ($5.type == TYPE_INTEGER) {
                    value.intValue = $5.integerValue;
                    printf("Setting integer value: %d\n", value.intValue);
                } else {
                    type_match = false;
                }
                break;
            case TYPE_FLOAT:
                strncpy(type_str, "float", MAX_TYPE_LENGTH - 1);
                if ($5.type == TYPE_FLOAT) {
                    value.floatValue = $5.floatValue;
                } else {
                    type_match = false;
                }
                break;
            case TYPE_STRING:
                strncpy(type_str, "string", MAX_TYPE_LENGTH - 1);
                if ($5.type == TYPE_STRING) {
                    strncpy(value.stringValue, $5.stringValue, MAX_NAME_LENGTH - 1);
                    value.stringValue[MAX_NAME_LENGTH - 1] = '\0';
                } else {
                    type_match = false;
                }
                break;
            case TYPE_BOOLEAN:
              strncpy(type_str, "bool", MAX_TYPE_LENGTH - 1);
              type_str[MAX_TYPE_LENGTH - 1] = '\0';
              if ($5.type == TYPE_BOOLEAN) {
                  value.intValue = $5.booleanValue ? 1 : 0;
                  printf("Boolean value set to: %d\n", value.intValue);
              } else {
                  type_match = false;
              }
              break;

            default:
                printf("Unsupported type in constant declaration\n");
                YYERROR;
        }

        if (!type_match) {
            printf("Type mismatch: Expected type %s\n", type_str);
            YYERROR;
        }

        // Insert the constant into the table
        insertSymbol(symbolTable, $3, type_str, value, 0, true, true);
        printf("Constant inserted successfully\n");
    }
    | Type ID { 
        printf("Simple declaration without initialization\n");
        printf("Declaring identifier: %s\n", $2);  // $2 
        
        // Create a new symbol value with default initialization
        SymbolValue value = {0};
        char type_str[MAX_TYPE_LENGTH] = {0};

        // Convert numeric type to string representation
        switch($1) {
            case TYPE_INTEGER:
                strncpy(type_str, "int", MAX_TYPE_LENGTH - 1);
                break;
            case TYPE_FLOAT:
                strncpy(type_str, "float", MAX_TYPE_LENGTH - 1);
                break;
            case TYPE_STRING:
                strncpy(type_str, "string", MAX_TYPE_LENGTH - 1);
                break;
            case TYPE_BOOLEAN:
                strncpy(type_str, "bool", MAX_TYPE_LENGTH - 1);
                break;
            default:
                printf("Unsupported type in declaration\n");
                YYERROR;
        }

        // Insert the uninitialized symbol into the table
        insertSymbol(symbolTable, $2, type_str, value, 0, false, false);
        printf("Symbol inserted successfully\n");
    }

Type:
    INT { $$ = TYPE_INTEGER; printf("Type entier\n"); }
    | FLOAT { $$ = TYPE_FLOAT; printf("Type flottant\n"); }
    | BOOL { $$ = TYPE_BOOLEAN; printf("Type booléen\n"); }
    | STR { $$ = TYPE_STRING; printf("Type chaîne de caractères\n"); }
    | ARRAY 
    | DICT
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
    LBRACKET RBRACKET
    | LBRACKET ExpressionList RBRACKET
    ;

/* Liste d'expressions pour les tableaux */
ExpressionList:
    Expression
    | ExpressionList COMMA Expression
    ;

/* Définition des littéraux dictionnaire */
DictLiteral:
    LBRACE RBRACE
    | LBRACE DictItems RBRACE
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