#include "tableSymboles.h"
/***************************************fonction HASH********************************************************/
#include <stddef.h> 
#include <stdlib.h> 
#include <string.h> 
#include <stdio.h>  

// Fonctionnement:
//calculer une valeur de hachage basee sur le nom du symbole.
// Utilise une methode simple avec un coefficient multiplicateur pour minimiser les collisions.
unsigned int hash(const char *name) {
    unsigned int hashValue = 0;
    for (int i = 0; name[i] != '\0'; i++) {
        hashValue = 31 * hashValue + name[i]; // Calcul incremental du hash
    }
    return hashValue % HASH_TABLE_SIZE; // Reduction dans la plage de taille de table
}
/*************************************** Creer une Table des Symboles ****************************************/
// Fonctionnement :
// Initialise une nouvelle table des symboles avec des buckets vides.
// Configure un compteur d'ID unique pour les entrees futures.

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
int currentColumn = 1;  // Définition de currentColumn

void showLexicalError(char *msg) {
    fprintf(stderr, "Erreur lexicale : %s\n", msg);
}

/*************************************** Inserer un Symbole *************************************************/
// Fonctionnement :
// Ajoute une nouvelle entree dans la table des symboles avec un ID unique.
// Stocke des informations telles que le nom, le type, la valeur et le niveau de portee.
// Gere les collisions en inserant les nouvelles entrees en tete de liste.

void insertSymbol(SymbolTable *table, const char *name, const char *type, void *value, int scopeLevel) {
    unsigned int index = hash(name); // Calcul de l'index base sur le hash du nom
    SymbolEntry *newEntry = (SymbolEntry *)malloc(sizeof(SymbolEntry));
    newEntry->id = table->nextId++;       // Assignation d'un ID unique
    newEntry->name = strdup(name);        // Copie du nom
    newEntry->type = strdup(type);        // Copie du type
    newEntry->value = value;              // Assignation de la valeur
    newEntry->scopeLevel = scopeLevel;    // Niveau de portee
    newEntry->next = table->buckets[index]; // Insertion en t�te de liste
    table->buckets[index] = newEntry;    // Mise a jour du bucket
}

/*************************************** Rechercher un Symbole par ID ****************************************/
// Fonctionnement :
// Parcourt tous les buckets de la table des symboles pour trouver une entree avec un ID donne.
// Retourne l'entree si trouvee, sinon retourne NULL.

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
// Fonctionnement :
// Recherche une entree dans la table des symboles basee sur son nom.
// Utilise la fonction de hachage pour trouver rapidement le bucket correspondant.
// Parcourt le bucket pour trouver l'entree.

SymbolEntry *lookupSymbolByName(SymbolTable *table, const char *name, int scopeLevel) {
    unsigned int index = hash(name); // Calcul de l'index du bucket
    SymbolEntry *current = table->buckets[index];
    while (current) {
        if (strcmp(current->name, name) == 0 && current->scopeLevel == scopeLevel) {
            return current; // Retourne l'entree si le nom correspond
        }
        current = current->next;
    }

    if (scopeLevel == 1){
        current = table->buckets[index];
        
    while (current) {
        if (strcmp(current->name, name) == 0 && current->scopeLevel == 0) {
            return current; // Retourne l'entree si le nom correspond
        }
        current = current->next;
    }

    }
    return NULL; // Aucun symbole trouve pour ce nom
}

/*************************************** Supprimer un Symbole par Nom ***************************************/
// Fonctionnement :
// Supprime une entree specifique de la table des symboles basee sur son nom.
// Met a jour les pointeurs pour maintenir l'integrite de la liste chainee.

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
            free(current->name); // Libere les ressources
            free(current->type);
            free(current);
            return;
        }
        prev = current;
        current = current->next;
    }
}
/*************************************** Supprimer un Symbole par ID ******************************************/
// Fonctionnement :
// Supprime un symbole de la table des symboles en utilisant son ID.
// Parcourt chaque bucket de la table, et pour chaque symbole, compare son ID.
// Si un symbole avec l'ID donne est trouve, il est supprime de la liste chainee.
// Si l'entree se trouve au debut de la liste, elle est simplement mise a jour pour pointer vers l'entree suivante.
// Libere la memoire associee au nom, au type et a l'entree du symbole.

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
                free(current->name); // Libere le nom
                free(current->type); // Libere le type
                free(current);       // Libere l'entree du symbole
                return;
            }
            prev = current;
            current = current->next;
        }
    }
}

/*************************************** Liberer toute la Table des Symboles ********************************/
// Fonctionnement :
// Libere toutes les entrees de la table des symboles et la table elle-meme.
// Parcourt chaque bucket et libere chaque entree de la liste chainee.
// Une fois les symboles liberes, la table elle-meme est egalement liberee.

void freeSymbolTable(SymbolTable *table) {
    for (int i = 0; i < HASH_TABLE_SIZE; i++) {
        SymbolEntry *current = table->buckets[i];
        while (current) {
            SymbolEntry *toFree = current;
            current = current->next;
            free(toFree->name); // Libere le nom
            free(toFree->type); // Libere le type
            free(toFree);       // Libere l'entree
        }
    }
    free(table); // Libere la structure de la table
}





/*************************************** Vider la Table des Symboles **************************************/
// Fonctionnement :
// Efface tous les symboles de la table sans liberer la table elle-meme.
// Parcourt chaque bucket et libere les entrees, puis reinitialise chaque bucket a NULL.

void clearSymbolTable(SymbolTable *table) {
    for (int i = 0; i < HASH_TABLE_SIZE; i++) {
        SymbolEntry *current = table->buckets[i];
        while (current) {
            SymbolEntry *toFree = current;
            current = current->next;
            free(toFree->name); // Libere le nom
            free(toFree->type); // Libere le type
            free(toFree);       // Libere l'entree
        }
        table->buckets[i] = NULL; // Reinitialise le bucket a NULL
    }
}


/*************************************** Verifier si un Symbole Existe par Nom ****************************/
// Fonctionnement :
// Verifie si un symbole existe dans la table des symboles en fonction de son nom.
// Utilise la fonction `lookupSymbolByName` pour effectuer la recherche.
// Retourne 1 si le symbole existe, sinon 0.

int symbolExistsByName(SymbolTable *table, const char *name, int scopeLevel) {
    return lookupSymbolByName(table, name, scopeLevel) != NULL; // Retourne vrai si le symbole existe
}

/*************************************** Verifier si un Symbole Existe par ID ****************************/
// Fonctionnement :
// Verifie si un symbole existe dans la table des symboles en fonction de son ID.
// Utilise la fonction `lookupSymbolById` pour effectuer la recherche.
// Retourne 1 si le symbole existe, sinon 0.

int symbolExistsById(SymbolTable *table, int id, int scopeLevel) {
    return lookupSymbolById(table, id, scopeLevel) != NULL; // Retourne vrai si le symbole existe
}

/*************************************** Calculer les Largeurs des Colonnes *******************************/
// Fonctionnement :
// Calcule la largeur maximale necessaire pour chaque colonne lors de l'affichage des symboles.
// Parcourt tous les symboles de la table pour determiner la largeur maximale pour l'ID, le nom, le type,
// le niveau de portee et la valeur (selon le type).
// Met a jour les variables fournies pour chaque largeur.

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
                valueLength = snprintf(NULL, 0, "%d", *((int *)current->value));
            } else if (strcmp(current->type, "float") == 0) {
                valueLength = snprintf(NULL, 0, "%.2f", *((float *)current->value));
            } else if (strcmp(current->type, "char*") == 0) {
                valueLength = strlen((char *)current->value);
            } else {
                valueLength = strlen("N/A"); // Valeur par defaut pour les types non supportes
            }

            if (valueLength > *valueWidth) *valueWidth = valueLength;

            current = current->next;
        }
    }
}


/*************************************** Lister tous les Symboles avec Colonnes Separees par '|' *********/
// Fonctionnement :
// Affiche tous les symboles presents dans la table avec des colonnes bien formatees, Separees par des barres verticales '|',
// pour chaque attribut du symbole (ID, nom, type, niveau de portee, valeur).
// Utilise la fonction `computeColumnWidths` pour calculer la largeur des colonnes afin de rendre l'affichage lisible.

void listAllSymbols(SymbolTable *table) {
    if (!table) {
        printf("Table des symboles est NULL\n");
        return;
    }

    int idWidth = 5;      // Minimum width for ID
    int nameWidth = 10;    // Minimum width for Name
    int typeWidth = 8;     // Minimum width for Type
    int scopeWidth = 6;    // Minimum width for Scope

    // Calculate maximum widths
    for (int i = 0; i < HASH_TABLE_SIZE; i++) {
        SymbolEntry *current = table->buckets[i];
        while (current) {
            int currentIdWidth = snprintf(NULL, 0, "%d", current->id);
            idWidth = (currentIdWidth > idWidth) ? currentIdWidth : idWidth;
            
            int currentNameWidth = current->name ? strlen(current->name) : 4;
            nameWidth = (currentNameWidth > nameWidth) ? currentNameWidth : nameWidth;
            
            int currentTypeWidth = current->type ? strlen(current->type) : 4;
            typeWidth = (currentTypeWidth > typeWidth) ? currentTypeWidth : typeWidth;
            
            int currentScopeWidth = snprintf(NULL, 0, "%d", current->scopeLevel);
            scopeWidth = (currentScopeWidth > scopeWidth) ? currentScopeWidth : scopeWidth;
            
            current = current->next;
        }
    }

    // Print header
    printf("\n+-%*s-+-%*s-+-%*s-+-%*s-+\n", 
           idWidth, "---------", 
           nameWidth, "---------", 
           typeWidth, "---------", 
           scopeWidth, "---------");

    printf("| %-*s | %-*s | %-*s | %-*s |\n",
           idWidth, "ID",
           nameWidth, "Name",
           typeWidth, "Type",
           scopeWidth, "Scope");

    printf("+-%*s-+-%*s-+-%*s-+-%*s-+\n",
           idWidth, "---------",
           nameWidth, "---------",
           typeWidth, "---------",
           scopeWidth, "---------");

    // Print entries
    for (int i = 0; i < HASH_TABLE_SIZE; i++) {
        SymbolEntry *current = table->buckets[i];
        while (current) {
            printf("| %-*d | %-*s | %-*s | %-*d |\n",
                   idWidth, current->id,
                   nameWidth, current->name ? current->name : "NULL",
                   typeWidth, current->type ? current->type : "NULL",
                   scopeWidth, current->scopeLevel);
            current = current->next;
        }
    }

    printf("+-%*s-+-%*s-+-%*s-+-%*s-+\n",
           idWidth, "---------",
           nameWidth, "---------",
           typeWidth, "---------",
           scopeWidth, "---------");
}

/*************************************** Mettre a Jour la Valeur d'un Symbole ****************************/
// Fonctionnement :
// Met a jour la valeur d'un symbole dans la table des symboles, en utilisant son ID.
// Si le symbole est trouve, la valeur est mise a jour et un message est affiche.

void updateSymbolValue(SymbolTable *table, int id, void *newValue, int scopeLevel) {
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
// Fonctionnement :
// Libere la memoire allouee pour une entree de symbole specifique, y compris son nom, son type et la structure elle-meme.
// Si l'entree est valide (non NULL), la fonction libere la memoire associee a chaque champ de l'entree (nom, type, et structure de l'entree).
// Apres la liberation, l'entree elle-meme est egalement liberee.

void freeSymbolEntry(SymbolEntry *entry) {
    if (entry) {
        free(entry->name);  // Libere le nom du symbole
        free(entry->type);  // Libere le type du symbole
        free(entry);        // Libere la structure de l'entree elle-meme
    }
}

/*************************************** Redimensionner la Table des Symboles ********************************/
// Fonctionnement :
// Permet de redimensionner la table des symboles pour qu'elle puisse contenir un plus grand nombre de symboles.
// Cree une nouvelle table des symboles de taille `newSize`, copie les symboles de l'ancienne table vers la nouvelle,
// puis libere la memoire de l'ancienne table et met a jour la table d'origine avec la nouvelle table redimensionnee.
//
// - `newSize` : la nouvelle taille de la table des symboles (pour de plus grandes tables si necessaire).
// - La fonction conserve egalement le champ `nextId` (le prochain ID disponible) pour qu'il soit coherent apres le redimensionnement.

void resizeSymbolTable(SymbolTable *table, int newSize) {
    // Cree une nouvelle table des symboles de la taille souhaitee
    SymbolTable *newTable = createSymbolTable();
    newTable->nextId = table->nextId;  // Conserve la valeur de `nextId` de l'ancienne table

    // Copie tous les symboles de l'ancienne table vers la nouvelle
    for (int i = 0; i < HASH_TABLE_SIZE; i++) {
        SymbolEntry *current = table->buckets[i];
        while (current) {
            insertSymbol(newTable, current->name, current->type, current->value, current->scopeLevel);  // Insere chaque symbole dans la nouvelle table
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
