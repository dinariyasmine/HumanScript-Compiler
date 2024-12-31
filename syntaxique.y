/* Description: Grammaire complète pour le langage de programmation HumanScript
 * Ce fichier contient les règles syntaxiques et les actions
 * pour l'analyse du langage
 */

%define parse.error verbose

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
extern int yylex();
extern int yylineno; 
extern char* yytext;
extern FILE* yyin;
int positionCurseur = 0;
char *file = "input.txt";
void yyerror(const char *s);
%}



/* Définition des tokens */
/* Types de données */
%token INT FLOAT BOOL STR 
%token CONST ARRAY DICT FUNCTION 

/* Mots-clés pour les déclarations et appels */
%token LET BE CALL WITH PARAMETERS

/* Structures de contrôle */
%token ELSEIF IF ELSE ENDIF
%token FOR EACH IN ENDFOR
%token WHILE ENDWHILE
%token REPEAT UNTIL ENDREPEAT
%token INPUT TO PRINT
%token SWITCH CASE DEFAULT ENDSWITCH
%token RETURN

/* Opérateurs */
%token ADD SUB MUL DIV INT_DIV MOD
%token EQUAL NOT_EQUAL GREATER_THAN LESS_THAN GREATER_EQUAL LESS_EQUAL
%token COLON LPAREN RPAREN LBRACE RBRACE COMMA LBRACKET RBRACKET
%token LOGICAL_AND LOGICAL_OR LOGICAL_NOT

/* Valeurs littérales et identificateurs */
%token TRUE FALSE
%token INT_LITERAL FLOAT_LITERAL STRING_LITERAL
%token ID COMMENT

/* Définition des priorités et associativités des opérateurs
 * L'ordre des déclarations définit la priorité (du plus bas au plus haut)
 */
%left LOGICAL_OR
%left LOGICAL_AND
%left EQUAL NOT_EQUAL
%left LESS_THAN GREATER_THAN LESS_EQUAL GREATER_EQUAL
%left ADD SUB
%left MUL DIV MOD INT_DIV
%right LOGICAL_NOT
%nonassoc UMINUS  /* Pour la négation unaire */

/* Point de départ de la grammaire */
%start Program

%%

/* Règles de la grammaire */

/* Programme principal : liste de déclarations et instructions */
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
    INT_LITERAL
    | FLOAT_LITERAL
    | STRING_LITERAL
    | ID
    | TRUE
    | FALSE
    | ArrayLiteral
    | DictLiteral
    | LPAREN Expression RPAREN
    | FunctionCall
    ;

/* Déclarations de variables et constantes */
Declaration:
    LET Type ID BE Expression  { printf("Déclaration avec initialisation correcte\n"); }
    | CONST Type ID BE Expression { printf("Déclaration de constante correcte\n"); }
    | Type ID { printf("Déclaration correcte syntaxiquement\n"); }
    ;

/* Types de données supportés */
Type:
    INT | FLOAT | BOOL | STR | ARRAY | DICT
    ;

/* Affectation simple */
Assignment:
    ID EQUAL Expression
    ;

/* Instruction d'affichage */
PrintStatement:
    PRINT Expression
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

/* Programme principal */
int main(void) {
    /* Ouverture du fichier d'entrée */
    yyin = fopen("input.txt", "r");
    if (!yyin) {
        fprintf(stderr, "Error: Could not open input file\n");
        return 1;
    }

    printf("Lancement de l'analyse syntaxique...\n");
    int result = yyparse();
    
    if (result == 0) {
        printf("Analyse syntaxique terminée avec succès.\n");
    } else {
        printf("Erreur lors de l'analyse syntaxique.\n");
    }

    fclose(yyin);
    printf("Fichier d'entrée fermé.\n");

    if (result == 0) {
        printf("Programme terminé avec succès.\n");
    } else {
        printf("Erreur lors de l'exécution du programme.\n");
    }

    return result;
}