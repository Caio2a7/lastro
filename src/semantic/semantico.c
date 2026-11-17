#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include "semantico.h"

/* Contador de erros semânticos; define o código de saída do compilador. */
static int total_erros = 0;

Atr atr(char *cod, Type tipo, int linha) {
    Atr a = { cod, tipo, linha };
    return a;
}

Type tipo_resultado(Op op, Type a, Type b) {
    if (a == T_ERRO || b == T_ERRO) return T_ERRO;  /* sem cascata de erros */
    if (op == OP_ARITMETICO) return (a == T_FLOAT || b == T_FLOAT) ? T_FLOAT : T_INT;
    return T_BOOL;  /* relacional e lógico */
}

/* Formata fmt/ap em memória nova; encerra o programa se faltar memória. */
static char *vcod_fmt(const char *fmt, va_list ap) {
    va_list copia;
    va_copy(copia, ap);
    int n = vsnprintf(NULL, 0, fmt, copia);  /* 1ª passada: mede */
    va_end(copia);
    char *buf = n < 0 ? NULL : malloc((size_t)n + 1);
    if (buf == NULL) {
        perror("cod_fmt");
        exit(1);
    }
    vsnprintf(buf, (size_t)n + 1, fmt, ap);  /* 2ª passada: escreve */
    return buf;
}

char *cod_fmt(const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    char *s = vcod_fmt(fmt, ap);
    va_end(ap);
    return s;
}

Atr atr_bin(Atr a, const char *op_c, Atr b, Op op) {
    return atr(cod_fmt("%s %s %s", a.cod, op_c, b.cod),
               tipo_resultado(op, a.tipo, b.tipo), a.linha);
}

Atr atr_un(const char *op_c, Atr a, Op op) {
    return atr(cod_fmt("(%s%s)", op_c, a.cod), tipo_resultado(op, a.tipo, a.tipo), a.linha);
}

void erro_semantico(int linha, const char *fmt, ...) {
    va_list ap;
    fprintf(stderr, "linha %d: erro semântico: ", linha);
    va_start(ap, fmt);
    vfprintf(stderr, fmt, ap);
    va_end(ap);
    fputc('\n', stderr);
    total_erros++;
}

int erros_semanticos(void) {
    return total_erros;
}
