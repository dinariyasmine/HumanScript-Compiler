/*************************************** Fichier d'En-Tete pour la Table des Symboles *************************/
// Ce fichier d'en-tete definit les structures de donnees et les prototypes des fonctions associees a la gestion d'une
// table des symboles dans un langage de programmation. La table des symboles est utilisee pour stocker des informations
// sur les variables, fonctions, et autres entites dans le contexte d'un compilateur ou d'un interpreteur.
#include <stddef.h> 
#include <stdlib.h> 
#include <string.h> 
#include <stdio.h> 

#define TYPE_BOOLEAN 0
#define TYPE_INTEGER 1
#define TYPE_FLOAT 2
#define TYPE_STRING 3
#define TYPE_ARRAY_BOOLEAN 4
#define TYPE_ARRAY_INTEGER 5
#define TYPE_ARRAY_FLOAT 6
#define TYPE_ARRAY_STRING 7
#define TYPE_ARRAY 8
#define TYPE_DICT 9
#define TYPE_FUNCTION 10
#define TYPE_ERROR 11

#define ROWS 128
#define COLS 32

// Definitions de constantes
#define HASH_TABLE_SIZE 101 // Taille de la table de hachage (un nombre premier pour une meilleure distribution des hachages)

// Structure representant une entree de symbole dans la table des symboles
typedef struct SymbolEntry {
    int id;                    // Identifiant unique pour le symbole
    char *name;                // Nom lisible du symbole (optionnel)
    char *type;                // Type de donnees du symbole (par exemple, int, float)
    void *value;               // Pointeur vers la valeur du symbole
    int scopeLevel;            // Niveau de portee du symbole
    struct SymbolEntry *next;  // Pointeur vers l'entree suivante pour la gestion des collisions (chainage dans les buckets)
} SymbolEntry;

// Structure representant la table des symboles
typedef struct SymbolTable {
    SymbolEntry *buckets[HASH_TABLE_SIZE]; // Tableau des buckets pour une recherche rapide
    int nextId;                            // Compteur pour generer des identifiants uniques pour les symboles
} SymbolTable;


/*************************************** Fonctions de gestion de la Table des Symboles *************************/

// Cree une nouvelle table des symboles vide
// Retour : Un pointeur vers une nouvelle table des symboles allouee dynamiquement.
SymbolTable *createSymbolTable();

// Insere un nouveau symbole dans la table des symboles
// Parametres :
// - `name` : Le nom du symbole
// - `type` : Le type de donnees du symbole (par exemple, "int", "float")
// - `value` : Pointeur vers la valeur du symbole
// - `scopeLevel` : Le niveau de portee du symbole (par exemple, 1 pour la portee globale, 2 pour une portee locale)
// Retour : Rien.
void insertSymbol(SymbolTable *table, const char *name, const char *type, void *value, int scopeLevel);

// Recherche un symbole dans la table des symboles en utilisant son nom
// Parametres :
// - `name` : Le nom du symbole recherche
// Retour : Un pointeur vers l'entree du symbole si trouve, NULL sinon.
SymbolEntry *lookupSymbolByName(SymbolTable *table, const char *name, int scopeLevel);

// Recherche un symbole dans la table des symboles en utilisant son identifiant unique
// Parametres :
// - `id` : L'identifiant unique du symbole recherche
// Retour : Un pointeur vers l'entree du symbole si trouve, NULL sinon.
SymbolEntry *lookupSymbolById(SymbolTable *table, int id, int scopeLevel);

// Supprime un symbole de la table des symboles en utilisant son identifiant unique
// Parametres :
// - `id` : L'identifiant du symbole a supprimer
// Retour : Rien.
void deleteSymbolById(SymbolTable *table, int id);

// Supprime un symbole de la table des symboles en utilisant son nom
// Parametres :
// - `name` : Le nom du symbole a supprimer
// Retour : Rien.
void deleteSymbolByName(SymbolTable *table, const char *name);

// Libere la memoire associee a la table des symboles
// Parametres :
// - `table` : Pointeur vers la table des symboles a liberer
// Retour : Rien.
void freeSymbolTable(SymbolTable *table);

/*************************************** Fonctions supplementaires *************************/

// Efface tous les symboles dans la table des symboles
// Parametres :
// - `table` : Pointeur vers la table des symboles a effacer
// Retour : Rien.
void clearSymbolTable(SymbolTable *table);

// Verifie si un symbole existe dans la table des symboles en utilisant son nom
// Parametres :
// - `name` : Le nom du symbole a verifier
// Retour : 1 si le symbole existe, 0 sinon.
int symbolExistsByName(SymbolTable *table, const char *name, int scopeLevel);

// Verifie si un symbole existe dans la table des symboles en utilisant son identifiant unique
// Parametres :
// - `id` : L'identifiant du symbole a verifier
// Retour : 1 si le symbole existe, 0 sinon.
int symbolExistsById(SymbolTable *table, int id, int scopeLevel);

// Liste tous les symboles dans la table des symboles
// Parametres :
// - `table` : Pointeur vers la table des symboles
// Retour : Rien.
void listAllSymbols(SymbolTable *table);

// Met a jour la valeur d'un symbole dans la table des symboles
// Parametres :
// - `id` : L'identifiant du symbole a mettre a jour
// - `newValue` : Nouveau pointeur vers la valeur du symbole
// Retour : Rien.
void updateSymbolValue(SymbolTable *table, int id, void *newValue, int scopeLevel);

// Libere la memoire allouee pour une entree de symbole specifique
// Parametres :
// - `entry` : Pointeur vers l'entree de symbole a liberer
// Retour : Rien.
void freeSymbolEntry(SymbolEntry *entry);

// Redimensionne la table des symboles pour accueillir plus de symboles
// Parametres :
// - `newSize` : La nouvelle taille souhaitee pour la table des symboles
// Retour : Rien.
void resizeSymbolTable(SymbolTable *table, int newSize);

