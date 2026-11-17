CC      = gcc
LEX     = lex
YACC    = yacc -d -v -t
BUILD   = build
CFLAGS  = -Wall -Isrc -I$(BUILD)
TARGET  = $(BUILD)/compilador
SRCS    = $(wildcard src/semantic/*.c src/gen/*.c)

all: $(TARGET)

$(TARGET): $(BUILD)/y.tab.c $(BUILD)/lex.yy.c $(SRCS) | $(BUILD)
	$(CC) $(CFLAGS) -o $@ $^ -lfl

$(BUILD)/y.tab.c $(BUILD)/y.tab.h: src/parser/parser.y | $(BUILD)
	$(YACC) -o $(BUILD)/y.tab.c $<

$(BUILD)/lex.yy.c: src/lexer/lexer.l $(BUILD)/y.tab.h | $(BUILD)
	$(LEX) -o $@ $<

$(BUILD):
	mkdir -p $@

test: all
	@echo "== Casos válidos =="
	@for f in tests/valido/*.txt; do echo "-- $$f --"; ./$(TARGET) < $$f; echo; done
	@echo "== Casos inválidos (devem dar erro) =="
	@for f in tests/invalido/*.txt; do echo "-- $$f --"; ./$(TARGET) < $$f; echo; done

# Mostra o resumo de conflitos do y.output (gerado pelo -v do yacc),
# útil para conferir contra as tabelas LR(0)/SLR/LR(1)/LALR(1) feitas à mão.
conflitos: $(BUILD)/y.tab.c
	@grep -i "conflict" $(BUILD)/y.output || echo "Nenhum conflito reportado."

clean:
	rm -rf $(BUILD)

.PHONY: all test conflitos clean
