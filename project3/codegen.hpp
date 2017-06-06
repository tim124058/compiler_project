#ifndef _CODEGEN_H_
#define _CODEGEN_H_

#include <iostream>
#include <fstream>
#include <stdio.h>
#include "symbols.hpp"
using namespace std;

extern string outName;
extern ofstream out;

void genProgramStart();

void genMainStart();
void genFuncStart(idInfo);
void genVoidFuncEnd();
void genCompoundEnd();

void genCallFunc(idInfo);

void genGlobalVar(string name,int value);
void genGlobalVarNoInit(string name);

void genSetLocalVar(int index,int value);


void genPrintStart();
void genPrintStr();
void genPrintInt();
void genPrintlnStr();
void genPrintlnInt();


void genConstStr(string);
void genConstInt(int);
void genGetGlobalVar(string s);
void genGetLocalVar(int index);

#endif
