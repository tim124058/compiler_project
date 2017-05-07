TARGET = parser
LEX = flex
YACC = yacc
YACCFLAG = -y -d
CXX = g++

.PHONY: all clean

all: $(TARGET)

$(TARGET): lex.yy.cpp symbols.cpp y.tab.cpp
	$(CXX) $^ -o $@ -ll -ly

lex.yy.cpp: scanner.l
	$(LEX) -o $@ $^

y.tab.cpp: parser.y
	$(YACC) $(YACCFLAG) $^ -o $@

clean:
	$(RM) $(TARGET) lex.yy.cpp y.tab.*
