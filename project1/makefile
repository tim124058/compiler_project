TARGET = scanner
LEX = flex
CXX = g++

.PHONY: all clean

all: $(TARGET)

$(TARGET): lex.yy.cpp
	$(CXX) lex.yy.cpp -o $@ -ll

lex.yy.cpp: project1.lex
	$(LEX) $^
	mv lex.yy.c lex.yy.cpp

clean:
	$(RM) $(TARGET) lex.yy.cpp
