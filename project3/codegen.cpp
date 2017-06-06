#include "codegen.hpp"

void genProgramStart(){
	out << "class " << 	outName << endl;
	out << "{" << endl;
}


// function
void genMainStart(){
	out << "method public static void main(java.lang.String[])\n";
	out << "max_stack 15\n";
	out << "max_locals 15\n{\n";
}
void genFuncStart(idInfo info){
	out << "method public static ";
	out << ((info.type == Void_type)? "void":"int");
	out << " " + info.name + "(";
	for (int i = 0; i < info.value.aval.size(); i++) {
		if(i!=0) out << ",";
		out << "int";
	}
	out << ")\n";
	out << "max_stack 15\n";
	out << "max_locals 15\n{\n";
	for (int i = 0; i < info.value.aval.size(); i++) {
		out << "iload " << i << "\n";
	}
}
void genVoidFuncEnd(){
	out << "return\n}\n";
}
void genCompoundEnd(){
	out << "}" << endl;
}

void genCallFunc(idInfo info){
	out << "invokestatic ";
	out << ((info.type == Void_type)? "void":"int");
	out << " " + outName + "." + info.name + "(";
	for (int i = 0; i < info.value.aval.size(); i++) {
		if(i!=0) out << ",";
		out << "int";
	}
	out << ")\n";
}

void genGlobalVar(string name, int value){
	out << "field static integer " << name << " = " << value << "\n";
}

void genGlobalVarNoInit(string name){
	out << "field static integer " << name << "\n";
}

void genSetLocalVar(int index,int value){
	out << "ldc " << value << "\nistore " << index << "\n";
}


// print
void genPrintStart(){
	out << "getstatic java.io.PrintStream java.lang.System.out\n";
}
void genPrintStr(){
	out << "invokevirtual void java.io.PrintStream.print(java.lang.String)\n";
}
void genPrintInt(){
	out << "invokevirtual void java.io.PrintStream.print(int)\n";
}
void genPrintlnStr(){
	out << "invokevirtual void java.io.PrintStream.println(java.lang.String)\n";
}
void genPrintlnInt(){
	out << "invokevirtual void java.io.PrintStream.println(int)\n";
}

void genConstStr(string s){
	out << "ldc \"" << s << "\"\n";
}
void genConstInt(int v){
	out << "ldc " << v << "\n";
}


void genGetGlobalVar(string s){
	out << "getstatic int " << outName << "." << s << "\n";
}
void genGetLocalVar(int index){
	out << "iload " << index << "\n";
}
