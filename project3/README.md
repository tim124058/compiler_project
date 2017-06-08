# 編譯器 projet3


### 編譯和執行

若要編譯的程式檔名為 "test.go" :

	$ make run file=test

or

	$ make
	$ ./compiler test.go
	$ ./javaa test.jasm
	$ java test



### scanner變動
	無

### parser變動
	1. 改成使用參數輸入檔案
	2. 輸入改成讀檔和新增寫檔
	3. #include "codegen.hpp"
	4. 在需要產生java asm的地方加入codegen中的function

### symbols變動
	1. 新增isGlobal：判斷目前的scope是否為global
	2. 新增getIndex：使用變數名稱取得對應的index
	3. 新增getIntBoolValue：取得struct中的int或bool值，且回傳為int

### 新增codegen
	1. 產成java asm並寫入檔案
	2. 負責管理label的產生順序

