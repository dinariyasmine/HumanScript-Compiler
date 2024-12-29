%{ 
#include <stdio.h>
#include "syntaxique.tab.h"
extern void yyerror(const char *s);
extern int CURSOR_POSITION;
#define ADVANCE_CURSOR_POSITION() CURSOR_POSITION += yyleng
void showLexicalError() {
    fprintf(stderr, "Erreur lexicale à la ligne %d, colonne %d: caractère invalide '%s'\n", 
            yylineno, CURSOR_POSITION, yytext);
}


%}
%option noyywrap 
%option yylineno
 
%% 
 
"int"           { ADVANCE_CURSOR_POSITION(); printf("Type: int\n"); return INT; } 
"float"         { ADVANCE_CURSOR_POSITION(); printf("Type: float\n"); return FLOAT; } 
"bool"          { ADVANCE_CURSOR_POSITION(); printf("Type: bool\n"); return BOOL; } 
"str"           { ADVANCE_CURSOR_POSITION(); printf("Type: str\n"); return STR; } 
"const"         { ADVANCE_CURSOR_POSITION(); printf("Mot-clé: const\n"); return CONST; } 
"Array"         { ADVANCE_CURSOR_POSITION(); printf("Mot-clé: Array\n"); return ARRAY; } 
"Dict"          { ADVANCE_CURSOR_POSITION(); printf("Mot-clé: Dict\n"); return DICT; } 
"Function"      { ADVANCE_CURSOR_POSITION(); printf("Mot-clé: Function\n"); return FUNCTION; } 
"Let"           { ADVANCE_CURSOR_POSITION(); printf("Mot-clé: Let\n"); return LET; } 
"be"            { ADVANCE_CURSOR_POSITION(); printf("Mot-clé: be\n"); return BE; } 
"Call"          { ADVANCE_CURSOR_POSITION(); printf("Mot-clé: Call\n"); return CALL; } 
"with"          { ADVANCE_CURSOR_POSITION(); printf("Mot-clé: with\n"); return WITH; } 
"parameters"    { ADVANCE_CURSOR_POSITION(); printf("Mot-clé: parameters\n"); return PARAMETERS; } 
"if"            { ADVANCE_CURSOR_POSITION(); printf("Mot-clé: If\n"); return IF; }
"else"          { ADVANCE_CURSOR_POSITION(); printf("Mot-clé: Else\n"); return ELSE; }
"elseIf"        { ADVANCE_CURSOR_POSITION(); printf("Mot-clé: ElseIf\n"); return ELSEIF; }
"EndIf"         { ADVANCE_CURSOR_POSITION(); printf("Mot-clé: EndIf\n"); return ENDIF; }
"For"           { ADVANCE_CURSOR_POSITION(); printf("Mot-clé: For\n"); return FOR; } 
"each"          { ADVANCE_CURSOR_POSITION(); printf("Mot-clé: each\n"); return EACH; } 
"in"            { ADVANCE_CURSOR_POSITION(); printf("Mot-clé: in\n"); return IN; } 
"EndFor"        { ADVANCE_CURSOR_POSITION(); printf("Mot-clé: EndFor\n"); return ENDFOR; } 
"While"         { ADVANCE_CURSOR_POSITION(); printf("Mot-clé: While\n"); return WHILE; } 
"EndWhile"      { ADVANCE_CURSOR_POSITION(); printf("Mot-clé: EndWhile\n"); return ENDWHILE; } 
"Repeat"        { ADVANCE_CURSOR_POSITION(); printf("Mot-clé: Repeat\n"); return REPEAT; } 
"Until"         { ADVANCE_CURSOR_POSITION(); printf("Mot-clé: Until\n"); return UNTIL; } 
"EndRepeat"     { ADVANCE_CURSOR_POSITION(); printf("Mot-clé: EndRepeat\n"); return ENDREPEAT; } 
"Input"         { ADVANCE_CURSOR_POSITION(); printf("Mot-clé: Input\n"); return INPUT; } 
"to"            { ADVANCE_CURSOR_POSITION(); printf("Mot-clé: to\n"); return TO; } 
"Print"         { ADVANCE_CURSOR_POSITION(); printf("Mot-clé: Print\n"); return PRINT; } 
"Switch"        { ADVANCE_CURSOR_POSITION(); printf("Mot-clé: Switch\n"); return SWITCH; } 
"Case"          { ADVANCE_CURSOR_POSITION(); printf("Mot-clé: Case\n"); return CASE; } 
"Default"       { ADVANCE_CURSOR_POSITION(); printf("Mot-clé: Default\n"); return DEFAULT; } 
"EndSwitch"     { ADVANCE_CURSOR_POSITION(); printf("Mot-clé: EndSwitch\n"); return ENDSWITCH; } 
"return"        { ADVANCE_CURSOR_POSITION(); printf("Mot-clé: Return\n"); return RETURN; } 
"+"             { ADVANCE_CURSOR_POSITION(); printf("Opérateur arithmétique: Addition\n"); return ADD; } 
"-"             { ADVANCE_CURSOR_POSITION(); printf("Opérateur arithmétique: Soustraction\n"); return SUB; } 
"*"             { ADVANCE_CURSOR_POSITION(); printf("Opérateur arithmétique: Multiplication\n"); return MUL; } 
"/"             { ADVANCE_CURSOR_POSITION(); printf("Opérateur arithmétique: Division\n"); return DIV; } 
"//"            { ADVANCE_CURSOR_POSITION(); printf("Opérateur arithmétique: Division entière\n"); return INT_DIV; } 
"%"             { ADVANCE_CURSOR_POSITION(); printf("Opérateur arithmétique: Modulo\n"); return MOD; } 
"=="            { ADVANCE_CURSOR_POSITION(); printf("Opérateur de comparaison : Égal à\n"); return EQUAL; } 
"!="            { ADVANCE_CURSOR_POSITION(); printf("Opérateur de comparaison : Différent de\n"); return NOT_EQUAL; } 
">"             { ADVANCE_CURSOR_POSITION(); printf("Opérateur de comparaison : Plus grand que\n"); return GREATER_THAN; } 
"<"             { ADVANCE_CURSOR_POSITION(); printf("Opérateur de comparaison : Plus petit que\n"); return LESS_THAN; } 
">="            { ADVANCE_CURSOR_POSITION(); printf("Opérateur de comparaison : Plus grand ou égal à\n"); return GREATER_EQUAL; } 
"<="            { ADVANCE_CURSOR_POSITION(); printf("Opérateur de comparaison : Plus petit ou égal à\n"); return LESS_EQUAL; } 
 
":"             { ADVANCE_CURSOR_POSITION(); printf("Deux-points\n"); return COLON; } 
"("             { ADVANCE_CURSOR_POSITION(); printf("Parenthèse ouvrante\n"); return LPAREN; } 
")"             { ADVANCE_CURSOR_POSITION(); printf("Parenthèse fermante\n"); return RPAREN; } 
"{"             { ADVANCE_CURSOR_POSITION(); printf("Accolade ouvrante\n"); return LBRACE; } 
"}"             { ADVANCE_CURSOR_POSITION(); printf("Accolade fermante\n"); return RBRACE; } 
","             { ADVANCE_CURSOR_POSITION(); printf("Virgule\n"); return COMMA; } 
"["             { ADVANCE_CURSOR_POSITION(); printf("Crochet ouvrant\n"); return LBRACKET; } 
"]"             { ADVANCE_CURSOR_POSITION(); printf("Crochet fermant\n"); return RBRACKET; } 
 
"and"           { ADVANCE_CURSOR_POSITION(); printf("Opérateur logique : ET logique\n"); return LOGICAL_AND; } 
"or"            { ADVANCE_CURSOR_POSITION(); printf("Opérateur logique : OU logique\n"); return LOGICAL_OR; } 
"not"           { ADVANCE_CURSOR_POSITION(); printf("Opérateur logique : Négation logique\n"); return LOGICAL_NOT; } 
 
"true"          { ADVANCE_CURSOR_POSITION(); printf("Booléen: true\n"); return TRUE; } 
"false"         { ADVANCE_CURSOR_POSITION(); printf("Booléen: false\n"); return FALSE; } 
"comment :"[^\n]*"." {ADVANCE_CURSOR_POSITION();  printf("Commentaire: %s\n", yytext); return COMMENT; } 
 
[0-9]+ { 
    ADVANCE_CURSOR_POSITION();
    printf("Nombre entier: %s\n", yytext); 
    return INT_LITERAL; 
} 
 
[0-9]+\.[0-9]+ { 
    ADVANCE_CURSOR_POSITION();
    printf("Nombre réel: %s\n", yytext); 
    return FLOAT_LITERAL; 
} 
 
\"([^\"\\]|\\.)*\" { 
    ADVANCE_CURSOR_POSITION();
    printf("Chaîne de caractères: %s\n", yytext); 
    return STRING_LITERAL; 
} 
 
[ \t]+ {
    for (int i = 0; i < yyleng; i++) {
        if (yytext[i] == '\t') {
            CURSOR_POSITION += 4 - (CURSOR_POSITION % 4); // Assume a tab width of 4 spaces
        } else {
            CURSOR_POSITION++;
        }
    }
}



\n|\r|\r\n {
    CURSOR_POSITION = 0;
}



[a-zA-Z_][a-zA-Z0-9_]* {
    ADVANCE_CURSOR_POSITION(); 
    printf("Identifiant: %s\n", yytext); 
    return ID; 
} 

. {

    CURSOR_POSITION += yyleng; 
    showLexicalError();


}


%%
