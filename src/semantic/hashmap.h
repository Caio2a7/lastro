#ifndef HASHMAP_H
#define HASHMAP_H

/**
 * @file hashmap.h
 * @brief Tabela hash genérica (chave string, valor void *), usada pelas três
 *        tabelas do compilador: símbolos, subprogramas e tipos.
 */

#include <stddef.h>

#define BUCKETS 1024

typedef struct Entry {
    char *key;            // Chave completa (ex.: "main#x"); identifica a entrada
    void *value;          // Symbol *, Subprog * ou TypeDesc *
    struct Entry *next;   // Próxima entrada do mesmo bucket (colisão)
    struct Entry *after;  // Próxima entrada na ordem de inserção (para imprimir)
} Entry;

typedef struct {
    Entry *buckets[BUCKETS];
    Entry *first, *last;  // Ordem de inserção
} HashMap;

/**
 * @brief Procura uma chave.
 * @return O valor associado, ou NULL se a chave não existir.
 */
void *hm_get(HashMap *map, const char *key);

/**
 * @brief Associa um valor a uma chave nova.
 * @return 1 se inseriu, 0 se a chave já existia (nada é alterado).
 */
int hm_put(HashMap *map, const char *key, void *value);

/**
 * @brief Copia size bytes de data para memória nova; encerra o programa se faltar memória.
 * @return Ponteiro para a cópia.
 */
void *hm_copy(const void *data, size_t size);

#endif
