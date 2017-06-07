#ifndef _CODEGEN_H_
#define _CODEGEN_H_

#include <iostream>
#include <fstream>
#include <stdio.h>
#include <stack>
#include "symbols.hpp"
using namespace std;

extern string outName;
extern ofstream out;

struct LabelStruct{
	int LC;			// The labelCount at that time
	int Max;		// number of Label required for the statement
	LabelStruct(int lc,int max);
};
// manage all label index
class LabelManager{
private:
	int labelCount;
	stack<LabelStruct> lmStack;
public:
	LabelManager();
	void pushNLabel(int);
	void popLabel();
	int takeLabel(int);
	int getLable();
};

void genProgramStart();

void genMainStart();
void genFuncStart(idInfo);
void genVoidFuncEnd();
void genCompoundEnd();

void genCallFunc(idInfo);

void genGlobalVar(string name,int value);
void genGlobalVarNoInit(string name);

void genLocalVar(int index,int value);


void genPrintStart();
void genPrintStr();
void genPrintInt();
void genPrintlnStr();
void genPrintlnInt();


void genConstStr(string);
void genConstInt(int);
void genGetGlobalVar(string s);
void genGetLocalVar(int index);

void genSetGlobalVar(string s);
void genSetLocalVar(int index);

void genOperator(char op);
enum condition{
	IFLT, IFGT, IFLE, IFGE, IFEQ, IFNE
};
void genCondOp(int op);

void genIfStart();
void genElse();
void genIfEnd();
void genIfElseEnd();

void genForStart();
void genForCond();
void genForBody();
void genForEnd();


void genReturn();
void geniReturn();

#endif
