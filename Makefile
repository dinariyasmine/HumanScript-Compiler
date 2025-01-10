quicklo: lexical.l syntaxique.y 
	flex -l lexical.l 
	bison -d syntaxique.y 
	gcc lex.yy.c syntaxique.tab.c semantic.c tableSymboles.c quadruplets.c pile.c -lfl -o compiler