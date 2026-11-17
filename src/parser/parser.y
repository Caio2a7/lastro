%{
#include <stdio.h>
#include <stdlib.h>
#include "semantic/semantico.h"

int yylex(void);
int yyerror(char *s);
extern int yylineno;
extern char *yytext;

#include "semantic/symtab.h"

static Symbol *current_sub;

static Symbol *declare(const char *name, Category category, Type type, int is_out);
static Symbol *use(const char *name);
%}

%union {
    char *str;
    Type type;
    Atr atr;   /* atributo sintetizado das expressões: (texto C, tipo, linha) */
}

%type <type> tipo tipo_prim

%token <str> ID LITERAL_INT

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
    : CONST tipo_prim ID ASSIGN literal SEMI { declare($3, C_CONST, $2, 0); }
    ;

subprogs
    : subprog
    | subprog subprogs
    ;

subprog
    : PROC assinatura corpo             { scope_pop(); }        
    | FUNC assinatura ARROW tipo        {
            if (current_sub) {
                current_sub->category = C_FUNC;
                current_sub->type = $4;
            }
            scope_level(scope_depth())->type_return = $4;
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
            current_sub = declare($1, C_PROC, T_VOID, 0);
            scope_push($1, T_VOID, 0);
        }
    ;

params
    : param
    | param COMMA params
    ;

param
    : tipo ID       {declare($2, C_PARAM, $1, 0); }
    | OUT tipo ID   {declare($3, C_PARAM, $2, 1); }
    ;

tipo
    : tipo_prim                             { $$ = $1; }
    | tipo_prim LBRACKET tamanho RBRACKET   { $$ = $1; }
    ;

tipo_prim
    : INT   { $$ = T_INT; }
    | BOOL  { $$ = T_BOOL; }
    ;

tamanho
    : ID            { use($1); }
    | LITERAL_INT
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
    : tipo ID ASSIGN inicial SEMI   { declare($2, C_VAR, $1, 0); }
    ;

inicial
    : expr
    | LBRACKET expr SEMI tamanho RBRACKET
    ;

atrib
    : alvo ASSIGN expr SEMI
    ;

alvo
    /* tipo vem da tabela de símbolos; não declarado => T_ERRO (erro já reportado por use) */
    : ID    {
            Symbol *s = use($1);
            $$ = atr($1, s ? s->type : T_ERRO, yylineno);
        }
    | ID LBRACKET expr RBRACKET {
            Symbol *s = use($1);
            $$ = atr(cod_fmt("%s[%s]", $1, $3.cod), s ? s->type : T_ERRO, yylineno);
        }
    ;

chamada
    : ID LPAREN RPAREN {
            Symbol *s = use($1);
            $$ = atr(cod_fmt("%s()", $1), s ? s->type : T_ERRO, yylineno);
        }
    | ID LPAREN args RPAREN {
            Symbol *s = use($1);
            $$ = atr(cod_fmt("%s(%s)", $1, $3), s ? s->type : T_ERRO, yylineno);
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
            declare($4, C_VAR, T_INT, 0);
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
    : LITERAL_INT  { $$ = atr($1, T_INT, yylineno); }
    | TRUE         { $$ = atr(cod_fmt("1"), T_BOOL, yylineno); }  /* bool vira int no C */
    | FALSE        { $$ = atr(cod_fmt("0"), T_BOOL, yylineno); }
    ;

%%

static Symbol *declare(const char *name, Category category, Type type, int is_out) {
    Scope *top = scope_level(scope_depth());
    Symbol data = { .category = category, .type = type, .is_out = is_out, .line = yylineno };

    Symbol *sym = table_insert(top->name, name, data);

    if (!sym) {
        erro_semantico(yylineno, "'%s' já declarado no escopo '%s'", name, top->name);
    }
    return sym;
}

/* Busca o nome na tabela; NULL (com erro reportado) se não declarado. */
static Symbol *use(const char *name) {
    Symbol *sym = find_name(name);
    if (!sym) {
        erro_semantico(yylineno, "'%s' não declarado", name);
    }
    return sym;
}

int main(void) {
    scope_push("global", T_VOID, 0);
    declare("ler", C_PROC, T_VOID, 0);
    declare("escrever", C_PROC, T_VOID, 0);

    int status = yyparse();
    scope_pop();

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
