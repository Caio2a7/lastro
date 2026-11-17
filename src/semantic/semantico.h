#ifndef SEMANTICO_H
#define SEMANTICO_H

#include "semantic/symtab.h"  /* define Type (T_INT..T_ERRO); T_ERRO propaga em silêncio */

/* Categoria do operador, usada para decidir o tipo do resultado. */
typedef enum { OP_ARITMETICO, OP_RELACIONAL, OP_LOGICO } Op;

/* Atributo sintetizado de uma expressão: texto C, tipo e linha de origem. */
typedef struct {
    char *cod;
    Type tipo;
    int linha;
} Atr;

/* Monta um atributo a partir de seus três componentes. */
Atr atr(char *cod, Type tipo, int linha);

/* Operação binária: cod "a op b", tipo por tipo_resultado, linha de a. */
Atr atr_bin(Atr a, const char *op_c, Atr b, Op op);

/* Operação unária: cod "(op a)"; os parênteses evitam "- -x" virar "--x" em C. */
Atr atr_un(const char *op_c, Atr a, Op op);

/* Tipo resultante de um operador (sem checar compatibilidade; isso é a #9). */
Type tipo_resultado(Op op, Type a, Type b);

/* printf que devolve texto C em memória recém-alocada. */
char *cod_fmt(const char *fmt, ...);

/* Reporta erro semântico em stderr e segue a análise (não aborta). */
void erro_semantico(int linha, const char *fmt, ...);

/* Quantidade de erros semânticos reportados até agora. */
int erros_semanticos(void);

#endif
