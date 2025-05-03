OUTPUT_ARCH("riscv")  
ENTRY(_start)  
  
MEMORY  
{  
  ROM (rx)  : ORIGIN = 0xFFFF0000, LENGTH = 64K    /* ROM память по адресу 0xFFFF0000 */  
  RAM (rwx) : ORIGIN = 0xF0000000, LENGTH = 64K    /* RAM память по адресу 0xF0000000 */  
}  
  
SECTIONS  
{  
  /* Секции кода и констант размещаем в ROM */  
  .text 0xFFFF0300 :  
  {  
    *(.text.init)  
    *(.text)  
    *(.text.*)  
  } > ROM  
  
  .rodata :  
  {  
    *(.rodata)  
    *(.rodata.*)  
  } > ROM  
  
  /* Изменяемые данные размещаем в RAM, но их начальные значения хранятся в ROM */  
  .data :   
  {  
    _data_start = .;  
    *(.data)  
    *(.data.*)  
    . = ALIGN(4);  
    _data_end = .;  
  } > RAM AT > ROM  
    
  _data_load = LOADADDR(.data);  
  
  /* Неинициализированные данные размещаем в RAM */  
  .bss :  
  {  
    _bss_start = .;  
    *(.bss)  
    *(.bss.*)  
    *(COMMON)  
    . = ALIGN(4);  
    _bss_end = .;  
  } > RAM  
  
  /* Стек размещаем в конце RAM */  
  .stack (NOLOAD) :  
  {  
    . = ALIGN(16);  
    . = . + 4K;  
    _stack_top = .;  
  } > RAM  
}  
