# Tarefas

Ordem de execução do compilador, da mais urgente para a menos urgente. Cada tarefa tem uma issue no GitHub com o contexto, a checklist e o critério de pronto.

**Áreas:** LÉX léxico (lexical analysis) · SIN sintático (syntax analysis) · SEM semântico (semantic analysis) · GER geração de C (code generation) · TESTE testes · DOC documentação.

**Critérios:** códigos da avaliação do professor (1A–4B) e seções do PDF de documentação (Doc 2E etc.).

> **Antes de tudo:** [#1 Decisões pendentes](https://github.com/Caio2a7/lastro/issues/1) reúne as dúvidas para o professor e o grupo (tipagem dinâmica, tipos sintéticos, `to` inclusivo, `ler`/`escrever` embutidos). As respostas podem mudar as tarefas abaixo.

## Prioridade máxima

Sequência que destrava todo o resto. Fazer agora, nesta ordem.

| # | Issue | Área | Tarefa | Critério |
|---|---|---|---|---|
| 1 | [#2](https://github.com/Caio2a7/lastro/issues/2) | LÉX | **Corrigir erro léxico.** Em `src/lexer/lexer.l:70`, voltar o `return ERRO`. Hoje um programa com `@` sai ACEITO. | 1A |
| 2 | [#3](https://github.com/Caio2a7/lastro/issues/3) | SIN | **Atributos e erros.** Na `%union`, guardar (código C, tipo) e declarar os `%type`. Criar `erro_semantico(linha, msg)`, que conta o erro sem abortar. | — |
| 3 | [#5](https://github.com/Caio2a7/lastro/issues/5) | SEM | **Tabela de símbolos (symbol table).** Hash com chave `escopo#nome`, `insert` que acusa duplicata e `lookup`. O símbolo guarda nome, categoria, tipo, se é `out` e os parâmetros. A entrada não é apagada no `pop`. | — |
| 4 | [#6](https://github.com/Caio2a7/lastro/issues/6) | SEM | **Pilha de escopos (scope stack).** Cada nível guarda (escopo, tipo de retorno) e qualquer nível pode ser lido. Cada bloco recebe um nome único (`main#b2`). | — |
| 5 | [#7](https://github.com/Caio2a7/lastro/issues/7) | SIN/SEM | **Abrir e fechar escopos.** Cabeçalhos `cab_proc`/`cab_func` registram o subprograma antes do corpo (assim a recursão funciona) e inserem os parâmetros; `push`/`pop` em bloco e no `for`; variável de bloco interno pode esconder uma de fora (shadowing); `ler`/`escrever` registrados como embutidos. | 2C, 2D |
| 6 | [#8](https://github.com/Caio2a7/lastro/issues/8) | SEM | **Declarações.** Erro para nome omitido, duplicado no mesmo escopo e tamanho de array que não é `const int`. | 2A, 2B |
| 7 | [#9](https://github.com/Caio2a7/lastro/issues/9) | SEM | **Verificador de tipos (type checking).** Aritmética só com números, lógica só com `bool`, relacionais resultam em `bool`, `=`/`!=` com tipos compatíveis. | 3B |
| 8 | [#10](https://github.com/Caio2a7/lastro/issues/10) | SEM | **Atribuição e indexação.** Tipo compatível, com coerção (coercion) só de `int` para `float`. Proibido atribuir a `const`. O nome indexado tem de ser array e o índice `int`. `[e; n]` coerente com o tipo. | 3B |
| 9 | [#13](https://github.com/Caio2a7/lastro/issues/13) | SEM | **Chamadas e retorno.** O subprograma existe, número e tipo dos argumentos conferem e `out` bate entre chamada e parâmetro. `proc` não pode aparecer em expressão. `return` coerente com `proc` ou `func`. | 4A |
| 10 | [#15](https://github.com/Caio2a7/lastro/issues/15) | GER | **Geração de C.** Todas as construções, com saída em stdout: `./build/compilador < x.txt > x.c && gcc -Wall -Werror x.c`. O `gcc` não pode achar erro no C gerado. `out` vira ponteiro, então o valor muda depois da chamada; parâmetro sem `out` não muda. | 4B |

## Prioridade alta

Completam a linguagem pedida e os testes da avaliação.

| # | Issue | Área | Tarefa | Critério |
|---|---|---|---|---|
| 11 | [#11](https://github.com/Caio2a7/lastro/issues/11) | LÉX/SIN/SEM/GER | **Tipo `float` e coerção `int` → `float`.** Literal real no léxico, `float` em `tipo_prim`, conversão automática de `int` para `float` em expressões e atribuições, e cast explícito no C gerado. Sem um segundo tipo numérico não existe coerção para mostrar. | 3A |
| 12 | [#12](https://github.com/Caio2a7/lastro/issues/12) | SEM/GER | **Verificação de faixas.** Índice constante fora do tamanho do array dá erro em compilação; índice que é expressão ganha uma verificação no C gerado. | Doc 2E |
| 13 | [#14](https://github.com/Caio2a7/lastro/issues/14) | SEM | **Controle de fluxo.** Condição `bool` em `if`/`while`, `break`/`continue` só dentro de laço e o `main` tem de existir. | Doc 2E |
| 14 | [#4](https://github.com/Caio2a7/lastro/issues/4) | SIN | **Modo trace.** Opção `-t` (`yydebug`) que imprime os shifts e reduces, para mostrar a derivação na apresentação. | 1B |
| 15 | [#23](https://github.com/Caio2a7/lastro/issues/23) | TESTE | **Erros léxicos e sintáticos.** Um programa inválido para cada tipo de erro. | 1A |
| 16 | [#24](https://github.com/Caio2a7/lastro/issues/24) | TESTE/DOC | **Conflito shift-reduce.** A gramática atual tem 0 conflitos por construção. Programas com `a - b - c`, `a + b * c` e `if` aninhado com `else` provam que associatividade e precedência saem corretas; uma variante da gramática com `if` sem chaves mostra o conflito e que o yacc resolve com shift. | 1C |
| 17 | [#25](https://github.com/Caio2a7/lastro/issues/25) | TESTE | **Escopos.** Variável omitida, duplicada no mesmo escopo, duplicada em escopos irmãos e em escopos aninhados, conferindo qual valor é acessado. | 2A–2D |
| 18 | [#26](https://github.com/Caio2a7/lastro/issues/26) | TESTE | **Expressões.** Coerções permitidas, com o cast aparecendo no C, e misturas de tipos incompatíveis que precisam dar erro. | 3A, 3B |
| 19 | [#27](https://github.com/Caio2a7/lastro/issues/27) | TESTE | **Parâmetros.** Imprimir o valor antes e depois da chamada, com e sem `out`, executando o binário. | 4A, 4B |
| 20 | [#28](https://github.com/Caio2a7/lastro/issues/28) | TESTE | **Ajustar os testes atuais.** `04_else_if.txt` chama funções não declaradas. `make test` completo: `.txt` → `.c` → `gcc` → execução. | — |
| 21 | [#22](https://github.com/Caio2a7/lastro/issues/22) | TESTE | **Programas do `problemas_avaliacao.pdf`.** Escritos na linguagem e traduzidos sem erro. Requisito eliminatório; o professor ainda vai postar o PDF. | Entrega |

## Prioridade média

Extensões da linguagem.

| # | Issue | Área | Tarefa | Critério |
|---|---|---|---|---|
| 22 | [#16](https://github.com/Caio2a7/lastro/issues/16) | LÉX/SIN/SEM/GER | **Potência.** Operador novo entre `termo` e `fator`, associativo à direita. No C vira `pot_int`/`pow`. | — |
| 23 | [#17](https://github.com/Caio2a7/lastro/issues/17) | SIN/SEM/GER | **Matrizes.** Arrays de N dimensões. | — |
| 24 | [#18](https://github.com/Caio2a7/lastro/issues/18) | SIN/SEM/GER | **`switch`/`case`/`default`.** Os tokens já existem; falta o resto. | — |
| 25 | [#19](https://github.com/Caio2a7/lastro/issues/19) | LÉX/SIN/SEM/GER | **Registros e tipos definidos pelo usuário.** Acesso a campo com `.`; cobre "tipos estruturados" e "tipos sintéticos". | — |
| 26 | [#20](https://github.com/Caio2a7/lastro/issues/20) | SIN/SEM/GER | **Referências e alocação dinâmica.** Inclui a verificação de posse de referências. | — |
| 27 | [#21](https://github.com/Caio2a7/lastro/issues/21) | TESTE | **Listas, árvore e grafo.** Programas de exemplo usando registros e referências (tarefas 25 e 26); não viram tipo primitivo. | — |

## Prioridade baixa

Documentação em PDF, por último.

| # | Issue | Área | Tarefa | Critério |
|---|---|---|---|---|
| 28 | [#29](https://github.com/Caio2a7/lastro/issues/29) | DOC | **(1) Apresentação da linguagem.** Tipos, comandos, subprogramas e a gramática BNF final (também em `docs/gramatica-bnf.md`). | Doc 1 |
| 29 | [#30](https://github.com/Caio2a7/lastro/issues/30) | DOC | **(2A) Léxico.** Tokens, casamento mais longo (longest match) e erros. | Doc 2A |
| 30 | [#31](https://github.com/Caio2a7/lastro/issues/31) | DOC | **(2B) Símbolos.** Tabela de símbolos e pilha de escopos (texto 3.1/3.2 do grupo, com os nomes únicos de bloco). | Doc 2B |
| 31 | [#32](https://github.com/Caio2a7/lastro/issues/32) | DOC | **(2C) Condicionais e repetição.** Gramática, escopo do `for` e tradução para C. | Doc 2C |
| 32 | [#33](https://github.com/Caio2a7/lastro/issues/33) | DOC | **(2D) Subprogramas.** Cabeçalho, recursão, `out` e retorno. | Doc 2D |
| 33 | [#34](https://github.com/Caio2a7/lastro/issues/34) | DOC | **(2E) Verificações.** Tipos, coerções, faixas, duplicidade, chamadas e fluxo. | Doc 2E |
| 34 | [#35](https://github.com/Caio2a7/lastro/issues/35) | DOC | **(3) Instruções de uso.** Build, compilar um programa, gerar C e rodar. Atualizar o README e corrigir o `==` que aparece em `docs/documentacao.pdf`. | Doc 3 |
