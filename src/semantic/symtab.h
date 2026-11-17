#ifndef SYMTAB_H
#define SYMTAB_H

/**
 * @file symtab.h
 * @brief Definição da tabela de símbolos e funções relacionadas.
 */

/* Definição dos tipos de dados */

typedef enum { T_INT, T_FLOAT, T_BOOL, T_VOID, T_ERRO } Type;
typedef enum { C_VAR, C_CONST, C_PARAM, C_PROC, C_FUNC, C_TYPE } Category;


typedef struct {
    char *key; // Chave do símbolo (nome#escopo)
    char *name, *scope;
    Category category;
    Type type;
    int array_size; // Tamanho do array, se aplicável, senão é 0
    int is_out; // Indica se o parâmetro é de saída (out)
    struct Symbol *params; // Lista de parâmetros, se aplicável para funções e procedimentos
    struct Symbol *next; // Ponteiro para o próximo símbolo na lista encadeada
    int line;
} Symbol;

typedef struct {
    char *name;
    Type type_return;
    int is_loop;
} Scope;


/**
 * @brief Adiciona um novo escopo à pilha de escopos.
 * @param name Nome do escopo.
 * @param type_return Tipo de retorno do escopo.
 * @param is_loop Indica se o escopo é um loop.
 */
void scope_push(const char *name, Type type_return, int is_loop);

/**
 * @brief Adiciona um novo escopo de bloco à pilha de escopos.
 * @param is_loop Indica se o escopo é um loop.
 */
void scope_push_block(int is_loop);

/**
 * @brief Remove o último escopo da pilha de escopos; Não altera a pilha.
 * @return Null
 */
void scope_pop(); 

/**
 * @brief Retorna o escopo na posição especificada (1 = global, ..., n = topo da pilha).
 * @param level Nível do escopo a ser retornado.
 * @return Ponteiro para o escopo na posição especificada, ou NULL se a posição for inválida.
 */
Scope *scope_level(int level); 

/**
 * @brief Retorna a profundidade da pilha de escopos.
 * @return Profundidade da pilha de escopos.
 */
int scope_depth(); 

/* Definição da estrutura de tabela de símbolos */

/**
 * @brief Insere um símbolo na tabela de símbolos.
 * @param scope Nome do escopo onde o símbolo será inserido.
 * @param name Nome do símbolo.
 * @param data Dados do símbolo.
 * @return Ponteiro para o símbolo inserido, ou NULL se o símbolo já existir no escopo especificado.
 */
Symbol *table_insert(const char *scope, const char *name, Symbol data);

/**
 * @brief Procura um símbolo na tabela de símbolos.
 * @param scope Nome do escopo onde o símbolo será procurado.
 * @param name Nome do símbolo.
 * @return Ponteiro para o símbolo encontrado, ou NULL se o símbolo não existir no escopo especificado.
 */
Symbol *table_lookup(const char *scope, const char *name); 

/**
 * @brief Procura um símbolo pelo nome em todos os escopos percorrendo toda a pilha de escopos.
 * @param name Nome do símbolo.
 * @return Ponteiro para o símbolo encontrado, ou NULL se o símbolo não existir em nenhum escopo.
 */
Symbol *find_name(const char *name);

/**
 * @brief Imprime a tabela de símbolos.
 * @return Null
 */
void table_print();

#endif