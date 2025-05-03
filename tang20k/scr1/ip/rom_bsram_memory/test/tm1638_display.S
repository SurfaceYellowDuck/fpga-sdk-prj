# Программа для вывода цифры 8 на TM1638 через GPIO  
# Для процессора RISC-V 32 IMC  
  
# Константы  
.equ GPIO_BASE, 0xFF1FF800    # Базовый адрес GPIO контроллера  
.equ GPIO_DATA, 0x0           # Смещение для регистра данных  
.equ GPIO_DIR,  0x10          # Смещение для регистра направления (Output Enable Set)  
.equ GPIO_DIR_CLR, 0x14       # Смещение для регистра сброса направления  
  
# Маски для пинов  
.equ STB_PIN, 0x01            # Пин 0 для STB  
.equ DIO_PIN, 0x02            # Пин 1 для DIO  
.equ CLK_PIN, 0x04            # Пин 2 для CLK  
  
# Команды TM1638  
.equ CMD_DATA, 0x40           # Команда установки режима данных (автоинкремент)  
.equ CMD_DISP, 0x80           # Команда управления дисплеем  
.equ CMD_ADDR, 0xC0           # Команда установки адреса  
  
# Значение для цифры 8 на семисегментном дисплее  
.equ DIGIT_8, 0x7F            # Все сегменты включены для цифры 8  
  
.section .text.init  
.global _start  
_start:  
    # Инициализация указателя стека  
    la sp, _stack_top  
  
    # Копирование .data из ROM в RAM (если есть)  
    la a0, _data_start  
    la a1, _data_end  
    la a2, _data_load  
    bgeu a0, a1, 2f  
1:  
    lw t0, 0(a2)  
    sw t0, 0(a0)  
    addi a0, a0, 4  
    addi a2, a2, 4  
    bltu a0, a1, 1b  
2:  
  
    # Очистка .bss (если есть)  
    la a0, _bss_start  
    la a1, _bss_end  
    bgeu a0, a1, 4f  
3:  
    sw zero, 0(a0)  
    addi a0, a0, 4  
    bltu a0, a1, 3b  
4:  
  
    # Начало основной программы  
      
    # Настройка пинов GPIO как выходы  
    li t0, GPIO_BASE  
    li t1, (STB_PIN | DIO_PIN | CLK_PIN)  
    sw t1, GPIO_DIR(t0)  
      
    # Установка STB в высокое состояние, CLK и DIO в низкое  
    li t1, STB_PIN  
    sw t1, GPIO_DATA(t0)  
      
    # Задержка  
    call delay  
      
    # Отправка команды установки режима данных (автоинкремент адреса)  
    li a0, CMD_DATA  
    call send_byte  
      
    # Отправка команды включения дисплея (максимальная яркость)  
    li a0, CMD_DISP | 0x0F  
    call send_byte  
      
    # Установка адреса первого разряда  
    li a0, CMD_ADDR  
    call send_byte  
      
    # Отправка данных для цифры 8  
    li a0, DIGIT_8  
    call send_byte  
      
    # Отправка пустых данных для остальных разрядов (если нужно)  
    li a0, 0x00  
    call send_byte  
      
    # Завершение программы  
    j exit  
  
# Процедура отправки байта  
send_byte:  
    # a0 - байт для отправки  
    # t0 - адрес GPIO  
    # t1 - текущее значение GPIO  
    # t2 - маска для текущего бита  
    # t3 - счетчик битов  
      
    # Сохранение регистров  
    addi sp, sp, -16  
    sw ra, 12(sp)  
    sw t2, 8(sp)  
    sw t3, 4(sp)  
      
    # Установка STB в низкое состояние для начала передачи  
    li t1, 0  
    sw t1, GPIO_DATA(t0)  
      
    # Задержка  
    call delay  
      
    # Инициализация счетчика битов  
    li t3, 8  
      
send_bit_loop:  
    # Проверка текущего бита (LSB first)  
    andi t2, a0, 1  
    slli t2, t2, 1      # Сдвиг для соответствия DIO_PIN  
      
    # Установка DIO в соответствии с текущим битом  
    sw t2, GPIO_DATA(t0)  
      
    # Задержка  
    call delay  
      
    # Установка CLK в высокое состояние  
    ori t2, t2, CLK_PIN  
    sw t2, GPIO_DATA(t0)  
      
    # Задержка  
    call delay  
      
    # Установка CLK в низкое состояние  
    andi t2, t2, ~CLK_PIN  
    sw t2, GPIO_DATA(t0)  
      
    # Сдвиг байта для следующего бита  
    srli a0, a0, 1  
      
    # Уменьшение счетчика битов  
    addi t3, t3, -1  
    bnez t3, send_bit_loop  
      
    # Установка STB в высокое состояние для завершения передачи  
    li t1, STB_PIN  
    sw t1, GPIO_DATA(t0)  
      
    # Восстановление регистров  
    lw t3, 4(sp)  
    lw t2, 8(sp)  
    lw ra, 12(sp)  
    addi sp, sp, 16  
      
    ret  
  
# Процедура чтения байта (если потребуется)  
read_byte:  
    # Возвращает прочитанный байт в a0  
    # t0 - адрес GPIO  
    # t1 - текущее значение GPIO  
    # t2 - временная переменная  
    # t3 - счетчик битов  
    # t4 - результат  
      
    # Сохранение регистров  
    addi sp, sp, -16  
    sw ra, 12(sp)  
    sw t2, 8(sp)  
    sw t3, 4(sp)  
      
    # Установка DIO как вход  
    li t1, DIO_PIN  
    sw t1, GPIO_DIR_CLR(t0)  
      
    # Инициализация счетчика битов и результата  
    li t3, 8  
    li t4, 0  
      
read_bit_loop:  
    # Установка CLK в высокое состояние  
    li t1, CLK_PIN  
    sw t1, GPIO_DATA(t0)  
      
    # Задержка  
    call delay  
      
    # Чтение DIO  
    lw t1, GPIO_DATA(t0)  
    andi t1, t1, DIO_PIN  
    srli t1, t1, 1      # Сдвиг для получения бита  
      
    # Добавление бита к результату  
    slli t4, t4, 1  
    or t4, t4, t1  
      
    # Установка CLK в низкое состояние  
    li t1, 0  
    sw t1, GPIO_DATA(t0)  
      
    # Задержка  
    call delay  
      
    # Уменьшение счетчика битов  
    addi t3, t3, -1  
    bnez t3, read_bit_loop  
      
    # Восстановление DIO как выход  
    li t1, DIO_PIN  
    sw t1, GPIO_DIR(t0)  
      
    # Возврат результата  
    mv a0, t4  
      
    # Восстановление регистров  
    lw t3, 4(sp)  
    lw t2, 8(sp)  
    lw ra, 12(sp)  
    addi sp, sp, 16  
      
    ret  
  
# Простая процедура задержки  
delay:  
    li t4, 1000  
delay_loop:  
    addi t4, t4, -1  
    bnez t4, delay_loop  
    ret  
  
exit:  
    # Бесконечный цикл в случае завершения программы  
    j exit
