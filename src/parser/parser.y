%{
#include <stdio.h>
#include <stdlib.h>

int yylex(void);
int yyerror(char *s);
extern int yylineno;
extern char *yytext;

#include "semantic/symtab.h"

static int semantic_errors;
static Symbol *current_sub;

static Symbol *declare(const char *name, Category category, Type type, int is_out)
static void use(const char *name)
%}

%union {
    char *str;
    Type type;
}

%type <type> tipo tipo_prim

%token <str> ID LITERAL_INT

%token CONST PROC FUNC INT BOOL IF ELSE WHILE FOR TO
%token SWITCH CASE DEFAULT BREAK CONTINUE RETURN OUT TRUE FALSE

%token ASSIGN EQ NEQ LT LE GT GE
%token PLUS MINUS STAR SLASH
%token AND OR NOT ARROW

%token LPAREN RPAREN LBRACKET RBRACKET LBRACE RBRACE
%token COMMA SEMI DOT

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
    : PROC assinatura bloco             { scope_pop(); }        
    | FUNC assinatura ARROW tipo        {
            if (current_sub) {
                current_sub->category = C_FUNC;
                current_sub->type = $4;
            }
            scope_level(scope_depth())->type_return = $4;
        } 
        bloco                           { scope_pop(); }
    ;

assinatura
    : nome_sub LPAREN RPAREN
    | nome_sub LPAREN params RPAREN
    ;

nome_sub
    : ID
        {
            current_sub = declare($1, C_PROC, T_VOID, 0);
            scope_push(%1, T_VOID, 0);
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

bloco
    : LBRACE RBRACE
    | LBRACE cmds RBRACE
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
    : ID                            { use($1); }
    | ID LBRACKET expr RBRACKET     { use($1); }
    ;

chamada
    : ID LPAREN RPAREN          { use($1); }
    | ID LPAREN args RPAREN     { use($1); }
    ;

args
    : arg
    | arg COMMA args
    ;

arg
    : expr
    | OUT alvo
    ;

if_stmt
    : IF LPAREN expr RPAREN bloco
    | IF LPAREN expr RPAREN bloco ELSE if_stmt
    | IF LPAREN expr RPAREN bloco ELSE bloco
    ;

while_stmt
    : WHILE LPAREN expr RPAREN bloco
    ;

for_stmt
    : FOR LPAREN INT ID ASSIGN expr TO expr RPAREN  {
            scope_push_block(1);
            declare($4, C_VAR, T_INT, 0);
        } 
        bloco                                       { scope_pop(); }
    ;

expr
    : expr OR conj
    | conj
    ;

conj
    : conj AND rel
    | rel
    ;

rel
    : soma op_rel soma
    | soma
    ;

op_rel
    : EQ
    | NEQ
    | LT
    | LE
    | GT
    | GE
    ;

soma
    : soma PLUS termo
    | soma MINUS termo
    | termo
    ;

termo
    : termo STAR fator
    | termo SLASH fator
    | fator
    ;

fator
    : literal
    | alvo
    | chamada
    | LPAREN expr RPAREN
    | MINUS fator
    | NOT fator
    ;

literal
    : LITERAL_INT
    | TRUE
    | FALSE
    ;

%%

static Symbol *declare(const char *name, Category category, Type type, int is_out) {
    Scope *top = scope_level(scope_depth());
    Symbol data = { .category = category, .type = type, .is_out = is_out, .line = yylineno };

    Symbol *sym = table_insert(top->name, name, data);

    if (!sym) {
        fprintf(stderr, "Linha %d: '%s' já declarado no escopo '%s'\n", yylineno, name, top->name);
        semantic_errors++;
    }
    return sym;
}

static void use(const char *name) {
    if (!find_name(name)) {
        fprintf(stderr, "Linha %d: '%s' não declarado\n", yylineno, name);
        semantic_errors++;
    }
}

int main(void) {
    scope_push("global", T_VOID, 0);
    declare("ler", C_PROC, T_VOID, 0);
    declare("escrever", C_PROC, T_VOID, 0);

    int status = yyparse();
    scope_pop();

    table_print();

    if (status == 0 && semantic_errors == 0) {
        printf("ACEITO: programa correto\n");
    } else {
        printf("REJEITADO: programa contém erro\n");
    }
    return status != 0 || semantic_errors != 0;
}

int yyerror(char *msg) {
    fprintf(stderr, "linha %d: %s perto de '%s'\n", yylineno, msg, yytext);
    return 0;
}
