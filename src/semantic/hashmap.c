#include "hashmap.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* djb2 sobre a chave inteira: só escolhe o bucket. Chaves diferentes podem
 * cair no mesmo bucket (colisão); o strcmp em hm_get é que as distingue. */
static unsigned hash(const char *str) {
    unsigned hash = 5381;

    while (*str) {
        hash = (hash * 33) + (unsigned char)(*str++);
    }

    return hash % BUCKETS;
}

void *hm_copy(const void *data, size_t size) {
    void *copy = malloc(size);

    if (!copy) {
        fprintf(stderr, "Erro de alocação de memória.\n");
        exit(EXIT_FAILURE);
    }

    return memcpy(copy, data, size);
}

void *hm_get(HashMap *map, const char *key) {
    for (Entry *entry = map->buckets[hash(key)]; entry; entry = entry->next) {
        if (strcmp(entry->key, key) == 0) {
            return entry->value;
        }
    }

    return NULL;
}

int hm_put(HashMap *map, const char *key, void *value) {
    if (hm_get(map, key)) {
        return 0;
    }

    Entry *entry = hm_copy(&(Entry){ .value = value }, sizeof(Entry));
    entry->key = strdup(key);

    unsigned index = hash(key);
    entry->next = map->buckets[index];  // Início da lista do bucket
    map->buckets[index] = entry;

    if (map->last) {
        map->last->after = entry;
    } else {
        map->first = entry;
    }
    map->last = entry;

    return 1;
}
