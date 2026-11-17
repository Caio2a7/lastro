#include "symtab.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define BUCKETS 1024
#define MAX_SCOPE_DEPTH 100

static Symbol *table[BUCKETS]; // Tabela de símbolos
static Scope stack[MAX_SCOPE_DEPTH]; // Pilha de escopos
static int depth; // Profundidade da pilha de escopos
static int block_counter; // Contador de blocos para gerar nomes únicos

/* Funções auxiliares */

/**
 * @brief Função de hash DJB2para a tabela de símbolos.
 * @param str String a ser hasheada.
 * @return Valor hash da string.
 */
static unsigned hash(const char *str) {
    unsigned hash = 5381;
    
    while (*str) {
        hash = (hash * 33) + (unsigned char)(*str++);
    }
    
    return hash % BUCKETS;
}

/**
 * @brief Cria uma chave única para o símbolo com base no escopo e no nome.
 * @param scope Nome do escopo.
 * @param name Nome do símbolo.
 * @return Ponteiro para a chave criada (deve ser liberado pelo chamador).
 */
static char *make_key(const char *scope, const char *name) {
    size_t len = strlen(scope) + strlen(name) + 2; // +1 para o separador e +1 para o '\0'
    char *key = malloc(len);
    
    if (!key) {
        fprintf(stderr, "Erro de alocação de memória para chave.\n");
        exit(EXIT_FAILURE);
    }
    
    snprintf(key, len, "%s#%s", scope, name);
    
    return key;
}


/**
 * @brief Procura um símbolo na tabela de símbolos.
 * @param scope Nome do escopo onde o símbolo está localizado.
 * @param name Nome do símbolo a ser procurado.
 * @return Ponteiro para o símbolo encontrado, ou NULL se não encontrado.
 */
Symbol *table_lookup(const char *scope, const char *name) {
    char *key = make_key(scope, name);
    Symbol *sym = table[hash(key)];
    
    while (sym && strcmp(sym->key, key) != 0) {
        sym = sym->next;
    }
    
    free(key);

    return sym;
}

/**
 * @brief Insere um símbolo na tabela de símbolos.
 * @param scope Nome do escopo onde o símbolo será inserido.
 * @param name Nome do símbolo.
 * @param data Estrutura Symbol contendo os dados do símbolo a ser inserido.
 * @return Ponteiro para o símbolo inserido, ou NULL se o símbolo já existir no escopo especificado.
 */
Symbol *table_insert(const char *scope, const char *name, Symbol data) {
    if (table_lookup(scope, name)) {
        return NULL; // Símbolo já existe
    }

    Symbol *sym = malloc(sizeof *sym);
    *sym = data;
    sym->key = make_key(scope, name);
    sym->scope = strdup(scope);
    sym->name = strdup(name);

    unsigned index = hash(sym->key); // Índice na tabela de símbolos
    sym->next = table[index]; // Adiciona o símbolo no início da lista encadeada
    table[index] = sym; // Atualiza a tabela de símbolos

    return sym;
}

/**
 * @brief Empilha um novo escopo.
 * @param name Nome do escopo.
 * @param type_return Tipo de retorno do escopo.
 * @param is_loop Indica se o escopo é um loop.
 */
void scope_push(const char *name, Type type_return, int is_loop) {
    if (depth == MAX_SCOPE_DEPTH) {
        fprintf(stderr, "Erro interno: mais de %d escopos aninhados.\n", MAX_SCOPE_DEPTH);
        exit(EXIT_FAILURE);
    }
    stack[depth++] = (Scope){ strdup(name), type_return, is_loop };
}

/**
 * @brief Adiciona um novo escopo de bloco à pilha de escopos.
 * @param is_loop Indica se o escopo é um loop.
 */
void scope_push_block(int is_loop) {
    Scope *top = scope_level(depth);
    size_t len = strlen(top->name) + 20; // Espaço suficiente para o nome do bloco e o contador
    char *block_name = malloc(len);

    snprintf(block_name, len, "%s#block%d", top->name, block_counter++);
    scope_push(block_name, top->type_return, top->is_loop || is_loop);

    free(block_name); // Libera o nome do escopo anterior
}

/**
 * @brief Remove o último escopo da pilha de escopos; Não altera a pilha.
 * @return Null
 */
void scope_pop() {
    if (depth <= 0) {
        fprintf(stderr, "Erro interno: tentativa de desempilhar escopo vazio ou inexistente.\n");
        exit(EXIT_FAILURE);
    }

    free(stack[--depth].name); // Libera o nome do escopo
}
/**
 * @brief Retorna o escopo na posição especificada (1 = global, ..., n = topo da pilha).
 * @param level Nível do escopo a ser retornado.
 * @return Ponteiro para o escopo na posição especificada, ou NULL se a posição for inválida.
 */
Scope *scope_level(int level) {
    return (level > 0 && level <= depth) ? &stack[level - 1] : NULL;
}

/**
 * @brief Retorna a profundidade da pilha de escopos.
 * @return Profundidade da pilha de escopos.
 */
int scope_depth() {
    return depth;
}

/**
 * @brief Procura um símbolo pelo nome, percorrendo os escopos do topo da pilha até o escopo global.
 * @param name Nome do símbolo a ser procurado.
 * @return Ponteiro para o símbolo encontrado, ou NULL se não encontrado.
 */
Symbol *find_name(const char *name) {
    for (int i = scope_depth(); i > 0; i--) {
        Scope *scope = scope_level(i);
        Symbol *sym = table_lookup(scope->name, name);
        if (sym) {
            return sym;
        }
    }
    return NULL; // Não encontrado
}

/**
 * @brief Imprime a tabela de símbolos.
 */
void table_print(void) {
    static const char *category[] = {"var", "const", "param", "proc", "func", "type"};
    static const char *type[] = {"int", "float", "bool", "void", "erro"};

    printf("Tabela de Símbolos:\n");
    printf("%-24s %-6s %6s %5s %3s %5s\n", "Chave", "Categ", "Tipo", "Tam", "Out", "Linha");
    printf("--------------------------------------------------------------------------------\n");
    for (int index = 0; index < BUCKETS; index++) {
        for (Symbol *sym = table[index]; sym; sym = sym->next) {
            printf("%-24s %-6s %6s %5d %3d %5d\n", sym->key, category[sym->category], type[sym->type], sym->array_size, sym->is_out, sym->line);
        }
    }
}