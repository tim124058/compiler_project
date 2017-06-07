TARGET = compiler
LEX = flex
YACC = yacc
YACCFLAG = -y -d
CXX = g++
CXXFLAG = -std=c++11 -Wno-deprecated-register

.PHONY: all clean run

all: $(TARGET)

$(TARGET): lex.yy.cpp y.tab.cpp symbols.cpp symbols.hpp codegen.cpp codegen.hpp
	$(CXX) $(CXXFLAG) y.tab.cpp symbols.cpp codegen.cpp -o $@ -ll -ly

lex.yy.cpp: scanner.l
	$(LEX) -o $@ $^

y.tab.cpp: parser.y
	$(YACC) $(YACCFLAG) $^ -o $@

clean:
	$(RM) $(TARGET) lex.yy.cpp y.tab.*


run: $(TARGET)
	@test $(file)
	./$(TARGET) $(file).go
	./javaa $(file).jasm
	@echo "--------- run -----------"
	@java $(file)
	@echo "--------- end -----------"
	@#rm $(file).jasm $(file).class

