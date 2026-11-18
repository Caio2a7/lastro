%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "semantic/semantico.h"

int yylex(void);
int yyerror(char *s);
extern int yylineno;
extern char *yytext;
extern int yydebug;

static Subprog *current_sub;  /* subprograma cuja assinatura/corpo está sendo analisado */
%}

%union {
    char *str;
    int num;
    TypeDesc *type;
    Atr atr;   /* atributo sintetizado das expressões: (texto C, tipo, linha) */
}

%type <type> tipo tipo_base tipo_prim
%type <num> tamanho

%token <str> ID LITERAL_INT
/* nome que está na tabela de tipos; o léxico decide entre ID e TYPE_ID */
%token <str> TYPE_ID

%type <atr> expr conj rel soma termo fator literal alvo chamada
%type <str> op_rel args arg

%token CONST PROC FUNC INT BOOL IF ELSE WHILE FOR TO
%token SWITCH CASE DEFAULT BREAK CONTINUE RETURN OUT TRUE FALSE

%token ASSIGN EQ NEQ LT LE GT GE
%token PLUS MINUS STAR SLASH
%token AND OR NOT ARROW

%token LPAREN RPAREN LBRACKET RBRACKET LBRACE RBRACE
%token COMMA SEMI DOT
/* devolvido pelo léxico para caractere inválido; não aparece em nenhuma produção */
%token ERRO

%start programa

%%

programa
    : subprogs
    | consts subprogs
    ;

consts
    : decl_const
    | decl_const consts
    ;

decl_const
    : CONST tipo_prim ID ASSIGN literal SEMI {
            Symbol *s = declare_var($3, C_CONST, $2, 0, yylineno);
            if (s) s->value = strtol($5.cod, NULL, 10);  /* usado em int[MAX] */
        }
    ;

subprogs
    : subprog
    | subprog subprogs
    ;

subprog
    : PROC assinatura corpo             { scope_pop(); }        
    | FUNC assinatura ARROW tipo        {
            if (current_sub) {  /* o escopo aponta para current_sub, então o return já enxerga o tipo */
                current_sub->is_func = 1;
                current_sub->ret = $4;
            }
        }
        corpo                           { scope_pop(); }
    ;

assinatura
    : nome_sub LPAREN RPAREN
    | nome_sub LPAREN params RPAREN
    ;

nome_sub
    : ID
        {
            current_sub = declare_sub($1, yylineno);  /* antes do corpo: permite recursão */
            scope_push($1, current_sub, 0);
        }
    ;

params
    : param
    | param COMMA params
    ;

param
    : tipo ID       { append_param(current_sub, declare_var($2, C_PARAM, $1, 0, yylineno)); }
    | OUT tipo ID   { append_param(current_sub, declare_var($3, C_PARAM, $2, 1, yylineno)); }
    ;

tipo
    : tipo_base                             { $$ = $1; }
    | tipo_base LBRACKET tamanho RBRACKET   { $$ = type_array($1, $3); }
    ;

tipo_base
    : tipo_prim     { $$ = $1; }
    | TYPE_ID       { $$ = type_lookup($1); }  /* tipo do usuário (#19) */
    ;

tipo_prim
    : INT   { $$ = &type_int; }
    | BOOL  { $$ = &type_bool; }
    ;

/* tamanho de array: literal ou const int, sempre > 0 */
tamanho
    : ID {
            Symbol *s = use_var($1, yylineno);
            $$ = 0;
            if (s && (s->category != C_CONST || s->type != &type_int))
                erro_semantico(yylineno, "tamanho '%s' não é const int", $1);
            else if (s && s->value <= 0)
                erro_semantico(yylineno, "tamanho '%s' tem de ser > 0", $1);
            else if (s)
                $$ = (int)s->value;
        }
    | LITERAL_INT {
            $$ = atoi($1);
            if ($$ <= 0) erro_semantico(yylineno, "tamanho do array tem de ser > 0");
        }
    ;

/* Corpo de subprograma e de for: o escopo já foi aberto antes. */
corpo
    : LBRACE RBRACE
    | LBRACE cmds RBRACE
    ;

/* Bloco de if/else: abre um escopo próprio. */
bloco
    : abre_bloco fecha_bloco
    ;

/* Bloco de while: escopo próprio, marcado como laço. */
bloco_laco
    : abre_laco fecha_bloco
    ;

abre_bloco
    : LBRACE        { scope_push_block(0); }
    ;

abre_laco
    : LBRACE        { scope_push_block(1); }
    ;

fecha_bloco
    : RBRACE        { scope_pop(); }
    | cmds RBRACE   { scope_pop(); }
    ;

cmds
    : cmd
    | cmd cmds
    ;

cmd
    : decl_var
    | atrib
    | chamada SEMI
    | if_stmt
    | while_stmt
    | for_stmt
    | BREAK SEMI
    | CONTINUE SEMI
    | RETURN SEMI
    | RETURN expr SEMI
    ;

decl_var
    : tipo ID ASSIGN inicial SEMI   { declare_var($2, C_VAR, $1, 0, yylineno); }
    ;

inicial
    : expr
    | LBRACKET expr SEMI tamanho RBRACKET
    ;

atrib
    : alvo ASSIGN expr SEMI
    ;

alvo
    /* tipo vem da tabela de símbolos; não declarado => type_erro (erro já reportado por use_var) */
    : ID    {
            Symbol *s = use_var($1, yylineno);
            $$ = atr($1, s ? s->type : &type_erro, yylineno);
        }
    | ID LBRACKET expr RBRACKET {
            Symbol *s = use_var($1, yylineno);
            TypeDesc *t = s ? s->type : &type_erro;
            /* v[i] tem o tipo do elemento; acusar indexação de não-array é da #10 */
            $$ = atr(cod_fmt("%s[%s]", $1, $3.cod), t->kind == K_ARRAY ? t->elem : t, yylineno);
        }
    ;

/* chamada consulta só a tabela de subprogramas: x() com x variável é erro */
chamada
    : ID LPAREN RPAREN {
            Subprog *p = use_sub($1, yylineno);
            $$ = atr(cod_fmt("%s()", $1), p ? p->ret : &type_erro, yylineno);
        }
    | ID LPAREN args RPAREN {
            Subprog *p = use_sub($1, yylineno);
            $$ = atr(cod_fmt("%s(%s)", $1, $3), p ? p->ret : &type_erro, yylineno);
        }
    ;

args
    : arg
    | arg COMMA args  { $$ = cod_fmt("%s, %s", $1, $3); }
    ;

arg
    : expr     { $$ = $1.cod; }
    | OUT alvo { $$ = cod_fmt("&%s", $2.cod); }  /* out = passagem por referência: ponteiro no C */
    ;

if_stmt
    : IF LPAREN expr RPAREN bloco
    | IF LPAREN expr RPAREN bloco ELSE if_stmt
    | IF LPAREN expr RPAREN bloco ELSE bloco
    ;

while_stmt
    : WHILE LPAREN expr RPAREN bloco_laco
    ;

for_stmt
    : FOR LPAREN INT ID ASSIGN expr TO expr RPAREN  {
            scope_push_block(1);
            declare_var($4, C_VAR, &type_int, 0, yylineno);
        } 
        corpo                                       { scope_pop(); }
    ;

expr
    : expr OR conj  { $$ = atr_bin($1, "||", $3, OP_LOGICO); }
    | conj
    ;

conj
    : conj AND rel  { $$ = atr_bin($1, "&&", $3, OP_LOGICO); }
    | rel
    ;

rel
    : soma op_rel soma  { $$ = atr_bin($1, $2, $3, OP_RELACIONAL); }
    | soma
    ;

op_rel
    : EQ   { $$ = "=="; }  /* Lastro usa '=' para igualdade; C usa '==' */
    | NEQ  { $$ = "!="; }
    | LT   { $$ = "<"; }
    | LE   { $$ = "<="; }
    | GT   { $$ = ">"; }
    | GE   { $$ = ">="; }
    ;

soma
    : soma PLUS termo   { $$ = atr_bin($1, "+", $3, OP_ARITMETICO); }
    | soma MINUS termo  { $$ = atr_bin($1, "-", $3, OP_ARITMETICO); }
    | termo
    ;

termo
    : termo STAR fator   { $$ = atr_bin($1, "*", $3, OP_ARITMETICO); }
    | termo SLASH fator  { $$ = atr_bin($1, "/", $3, OP_ARITMETICO); }
    | fator
    ;

fator
    : literal
    | alvo
    | chamada
    | LPAREN expr RPAREN  { $$ = atr(cod_fmt("(%s)", $2.cod), $2.tipo, $2.linha); }
    | MINUS fator         { $$ = atr_un("-", $2, OP_ARITMETICO); }
    | NOT fator           { $$ = atr_un("!", $2, OP_LOGICO); }
    ;

literal
    : LITERAL_INT  { $$ = atr($1, &type_int, yylineno); }
    | TRUE         { $$ = atr(cod_fmt("1"), &type_bool, yylineno); }  /* bool vira int no C */
    | FALSE        { $$ = atr(cod_fmt("0"), &type_bool, yylineno); }
    ;

%%

int main(int argc, char **argv) {
    if (argc > 1 && strcmp(argv[1], "-t") == 0) {
        yydebug = 1;
    }

    type_init();
    scope_push("global", NULL, 0);
    declare_sub("ler", 0)->is_builtin = 1;
    declare_sub("escrever", 0)->is_builtin = 1;

    int status = yyparse();
    scope_pop();

    type_print();
    sub_print();
    table_print();

    int erros = erros_semanticos();
    if (status == 0 && erros == 0) {
        printf("ACEITO: programa correto\n");
        return 0;
    }
    if (erros > 0) {
        fprintf(stderr, "%d erro(s) semântico(s)\n", erros);
    }
    printf("REJEITADO: programa contém erro\n");
    return 1;
}

int yyerror(char *msg) {
    fprintf(stderr, "linha %d: %s perto de '%s'\n", yylineno, msg, yytext);
    return 0;
}
