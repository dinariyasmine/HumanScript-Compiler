#include <stdbool.h>



// on a besoin de cette structure car nous devons a un 
//certain moment stocker le type et la valeur en meme temps
typedef struct expression expression;
struct expression{
    int type;
    char stringValue[255];
    int integerValue;
    double floatValue;
    bool booleanValue;
    
};

typedef struct variable variable;
struct variable{
    struct SymbolEntry* entry;
};

// this function is used for debugging mostly
void valeurToString(expression expression, char * valeur);
