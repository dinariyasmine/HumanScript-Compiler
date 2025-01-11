#include "tableSymboles.h"

/***************************************fonction HASH********************************************************/
unsigned int hash(const char *name) {
    unsigned int hashValue = 0;
    for (int i = 0; name[i] != '\0'; i++) {
        hashValue = 31 * hashValue + name[i]; // Calcul incremental du hash
    }
    return hashValue % HASH_TABLE_SIZE; // Reduction dans la plage de taille de table
}

/*************************************** Creer une Table des Symboles ****************************************/
SymbolTable *createSymbolTable() {
    SymbolTable *table = (SymbolTable *)malloc(sizeof(SymbolTable));
    if (!table) {
        fprintf(stderr, "Erreur : Memoire insuffisante pour la table des symboles.\n");
        exit(EXIT_FAILURE);
    }
    for (int i = 0; i < HASH_TABLE_SIZE; i++) {
        table->buckets[i] = NULL; // Initialisation de chaque bucket a NULL
    }
    table->nextId = 0; // Initialisation du compteur d'ID
    return table;
}

/*************************************** Inserer un Symbole *************************************************/
void insertSymbol(SymbolTable *table, const char *name, const char *type, SymbolValue value, int scopeLevel, bool isConst, bool isInitialized) {
    printf("Value being inserted into symbol table: %d\n", value.intValue);
    unsigned int index = hash(name); // Calcul de l'index base sur le hash du nom
    SymbolEntry *newEntry = (SymbolEntry *)malloc(sizeof(SymbolEntry));
    newEntry->id = table->nextId++;       // Assignation d'un ID unique
    strncpy(newEntry->name, name, MAX_NAME_LENGTH - 1); // Copie du nom (fixed-size array)
    newEntry->name[MAX_NAME_LENGTH - 1] = '\0'; // Ensure null-termination
    strncpy(newEntry->type, type, MAX_TYPE_LENGTH - 1); // Copie du type (fixed-size array)
    newEntry->type[MAX_TYPE_LENGTH - 1] = '\0'; // Ensure null-termination
    
    newEntry->value = value;              // Assignation de la valeur
    newEntry->isConst = isConst;          // Indique si le symbole est une constante
    newEntry->isInitialized = isInitialized; // Indique si le symbole est initialisé
    newEntry->scopeLevel = scopeLevel;    // Niveau de portee
    newEntry->next = table->buckets[index]; // Insertion en tete de liste
    table->buckets[index] = newEntry;    // Mise a jour du bucket
}

/*************************************** Rechercher un Symbole par ID ****************************************/
SymbolEntry *lookupSymbolById(SymbolTable *table, int id, int scopeLevel) {
    for (int i = 0; i < HASH_TABLE_SIZE; i++) {
        SymbolEntry *current = table->buckets[i];
        while (current) {
            if (current->id == id && current->scopeLevel == scopeLevel) {
                return current; // Retourne l'entree si l'ID correspond
            }
            current = current->next;
        }

        if (scopeLevel == 1){
            current = table->buckets[i];
            while (current) {
            if (current->id == id && current->scopeLevel == 0) {
                return current; 
            }
            current = current->next;
        }
            
        }
    }
    return NULL; // Aucun symbole trouve pour cet ID
}

/*************************************** Rechercher un Symbole par Nom ***************************************/
SymbolEntry *lookupSymbolByName(SymbolTable *table, const char *name, int scopeLevel) {
    if (!table) {
        fprintf(stderr, "Error: Symbol table is NULL in lookupSymbolByName.\n");
        return NULL;
    }
    if (!name) {
        fprintf(stderr, "Error: Name is NULL in lookupSymbolByName.\n");
        return NULL;
    }

    unsigned int index = hash(name); // Calculate the hash index
    SymbolEntry *current = table->buckets[index];
    while (current) {
        if (strcmp(current->name, name) == 0 && current->scopeLevel == scopeLevel) {
            return current; // Return the entry if found
        }
        current = current->next;
    }

    return NULL; // Return NULL if the symbol is not found
}

/*************************************** Supprimer un Symbole par Nom ***************************************/
void deleteSymbolByName(SymbolTable *table, const char *name) {
    unsigned int index = hash(name); // Calcul de l'index du bucket
    SymbolEntry *current = table->buckets[index];
    SymbolEntry *prev = NULL;

    while (current) {
        if (strcmp(current->name, name) == 0) {
            if (prev) {
                prev->next = current->next; // Detache l'entree de la liste chainee
            } else {
                table->buckets[index] = current->next; // Mise a jour du bucket
            }
            free(current); // Libere l'entree du symbole
            return;
        }
        prev = current;
        current = current->next;
    }
}
/*************************************** Supprimer un Symbole par ID ******************************************/
void deleteSymbolById(SymbolTable *table, int id) {
    for (int i = 0; i < HASH_TABLE_SIZE; i++) {
        SymbolEntry *current = table->buckets[i];
        SymbolEntry *prev = NULL;
        while (current) {
            if (current->id == id) { // Symbole trouve
                if (prev) {
                    prev->next = current->next; // Retire le symbole de la liste chainee
                } else {
                    table->buckets[i] = current->next; // Met a jour le bucket si le symbole est en tete de liste
                }
                free(current); // Libere l'entree du symbole
                return;
            }
            prev = current;
            current = current->next;
        }
    }
}

/*************************************** Liberer toute la Table des Symboles ********************************/
void freeSymbolTable(SymbolTable *table) {
    for (int i = 0; i < HASH_TABLE_SIZE; i++) {
        SymbolEntry *current = table->buckets[i];
        while (current) {
            SymbolEntry *toFree = current;
            current = current->next;
            free(toFree); // Libere l'entree du symbole
        }
    }
    free(table); // Libere la structure de la table
}

/*************************************** Vider la Table des Symboles **************************************/
void clearSymbolTable(SymbolTable *table) {
    for (int i = 0; i < HASH_TABLE_SIZE; i++) {
        SymbolEntry *current = table->buckets[i];
        while (current) {
            SymbolEntry *toFree = current;
            current = current->next;
            free(toFree); // Libere l'entree du symbole
        }
        table->buckets[i] = NULL; // Reinitialise le bucket a NULL
    }
}

/*************************************** Verifier si un Symbole Existe par Nom ****************************/
int symbolExistsByName(SymbolTable *table, const char *name, int scopeLevel) {
    return lookupSymbolByName(table, name, scopeLevel) != NULL; // Retourne vrai si le symbole existe
}

/*************************************** Verifier si un Symbole Existe par ID ****************************/
int symbolExistsById(SymbolTable *table, int id, int scopeLevel) {
    return lookupSymbolById(table, id, scopeLevel) != NULL; // Retourne vrai si le symbole existe
}

/*************************************** Calculer les Largeurs des Colonnes *******************************/
void computeColumnWidths(SymbolTable *table, int *idWidth, int *nameWidth, int *typeWidth, int *scopeWidth, int *valueWidth) {
    *idWidth = strlen("ID");
    *nameWidth = strlen("Name");
    *typeWidth = strlen("Type");
    *scopeWidth = strlen("Scope Level");
    *valueWidth = strlen("Value");

    for (int i = 0; i < HASH_TABLE_SIZE; i++) {
        SymbolEntry *current = table->buckets[i];
        while (current) {
            // Calcul de la largeur de l'ID
            int idLength = snprintf(NULL, 0, "%d", current->id);
            if (idLength > *idWidth) *idWidth = idLength;

            // Calcul de la largeur du nom
            if ((int)strlen(current->name) > *nameWidth) *nameWidth = strlen(current->name);

            // Calcul de la largeur du type
            if ((int)strlen(current->type) > *typeWidth) *typeWidth = strlen(current->type);

            // Calcul de la largeur du niveau de portee
            int scopeLength = snprintf(NULL, 0, "%d", current->scopeLevel);
            if (scopeLength > *scopeWidth) *scopeWidth = scopeLength;

            // Calcul de la largeur de la valeur en fonction du type
            int valueLength = 0;
            if (strcmp(current->type, "int") == 0) {
                valueLength = snprintf(NULL, 0, "%d", current->value.intValue);
            } else if (strcmp(current->type, "float") == 0) {
                valueLength = snprintf(NULL, 0, "%.2f", current->value.floatValue);
            } else if (strcmp(current->type, "string") == 0) {
                valueLength = strlen(current->value.stringValue);
            } else {
                valueLength = strlen("N/A"); // Valeur par defaut pour les types non supportes
            }

            if (valueLength > *valueWidth) *valueWidth = valueLength;

            current = current->next;
        }
    }
}

/*************************************** Lister tous les Symboles avec Colonnes Separees par '|' *********/
void listAllSymbols(SymbolTable *table) {
    if (!table) {
        printf("Table des symboles est NULL\n");
        return;
    }

    int idWidth = 5;      // Minimum width for ID
    int nameWidth = 10;   // Minimum width for Name
    int typeWidth = 8;    // Minimum width for Type
    int scopeWidth = 6;   // Minimum width for Scope
    int valueWidth = 10;  // Minimum width for Value

    // Calculate maximum widths
    computeColumnWidths(table, &idWidth, &nameWidth, &typeWidth, &scopeWidth, &valueWidth);

    // Print header
    printf("\n+-%*s-+-%*s-+-%*s-+-%*s-+-%*s-+\n", 
           idWidth, "---------", 
           nameWidth, "---------", 
           typeWidth, "---------", 
           scopeWidth, "---------",
           valueWidth, "---------");

    printf("| %-*s | %-*s | %-*s | %-*s | %-*s |\n",
           idWidth, "ID",
           nameWidth, "Name",
           typeWidth, "Type",
           scopeWidth, "Scope",
           valueWidth, "Value");

    printf("+-%*s-+-%*s-+-%*s-+-%*s-+-%*s-+\n",
           idWidth, "---------",
           nameWidth, "---------",
           typeWidth, "---------",
           scopeWidth, "---------",
           valueWidth, "---------");

    // Print entries
for (int i = 0; i < HASH_TABLE_SIZE; i++) {
    SymbolEntry *current = table->buckets[i];
    while (current) {
        char valueStr[64]; // Buffer to store the value as a string
        if (strcmp(current->type, "int") == 0) {
            snprintf(valueStr, sizeof(valueStr), "%d", current->value.intValue);
        } else if (strcmp(current->type, "bool") == 0) {
            // Print boolean as true/false
            snprintf(valueStr, sizeof(valueStr), "%s", current->value.intValue ? "true" : "false");
        } else if (strcmp(current->type, "float") == 0) {
            snprintf(valueStr, sizeof(valueStr), "%.2f", current->value.floatValue);
        } else if (strcmp(current->type, "string") == 0) {
            snprintf(valueStr, sizeof(valueStr), "%s", current->value.stringValue);
        } else {
            snprintf(valueStr, sizeof(valueStr), "N/A");
        }

        printf("| %-*d | %-*s | %-*s | %-*d | %-*s |\n",
               idWidth, current->id,
               nameWidth, current->name,
               typeWidth, current->type,
               scopeWidth, current->scopeLevel,
               valueWidth, valueStr);
        current = current->next;
    }
}

    printf("+-%*s-+-%*s-+-%*s-+-%*s-+-%*s-+\n",
           idWidth, "---------",
           nameWidth, "---------",
           typeWidth, "---------",
           scopeWidth, "---------",
           valueWidth, "---------");
}

/*************************************** Mettre a Jour la Valeur d'un Symbole ****************************/
void updateSymbolValue(SymbolTable *table, int id, SymbolValue newValue, int scopeLevel) {
    SymbolEntry *entry = lookupSymbolById(table, id, scopeLevel);
    if (entry) {
        // Mise a jour de la valeur du symbole
        entry->value = newValue;
        printf("La valeur du symbole ID %d a ete mise a jour.\n", id);
    } else {
        printf("Symbole avec ID %d non trouve.\n", id);
    }
}

/*************************************** Liberer une Entree de Symbole Individuelle ************************/
void freeSymbolEntry(SymbolEntry *entry) {
    if (entry) {
        free(entry); // Libere la structure de l'entree elle-meme
    }
}

/*************************************** Redimensionner la Table des Symboles ********************************/
void resizeSymbolTable(SymbolTable *table, int newSize) {
    // Cree une nouvelle table des symboles de la taille souhaitee
    SymbolTable *newTable = createSymbolTable();
    newTable->nextId = table->nextId;  // Conserve la valeur de `nextId` de l'ancienne table

    // Copie tous les symboles de l'ancienne table vers la nouvelle
    for (int i = 0; i < HASH_TABLE_SIZE; i++) {
        SymbolEntry *current = table->buckets[i];
        while (current) {
            insertSymbol(newTable, current->name, current->type, current->value, current->scopeLevel, current->isConst, current->isInitialized);
            current = current->next;
        }
    }

    // Libere la memoire associee a l'ancienne table des symboles
    freeSymbolTable(table);

    // Remplace la table d'origine par la nouvelle table redimensionnee
    *table = *newTable;

    // Libere la memoire de la nouvelle table, car elle a ete copiee dans l'ancienne
    free(newTable);
}