#include "stdint.h"
#include "print.h"
#include "interrupt.h"
#include "global.h"
#include "io.h"

#define IDT_DESC_CNT 0x21       //目前总共支持的中断数
#define PIC_M_CTRL 0x20         //主片的控制端口0x20
#define PIC_M_DATA 0x21         //主片的数据端口0x21
#define PIC_S_CTRL 0xa0         //从片的控制端口0xa0
#define PIC_S_DATA 0xa1         //从片的数据端口0xa1

/*中断门描述符结构体*/
struct gate_desc
{
    uint16_t func_offset_low_word;
    uint16_t selector;
    uint8_t dcount;            //双字计数字段，是门描述符中的第4字节，此项是固定值，不用考虑
    uint8_t attribute;         //门描述符的属性
    uint16_t func_offset_high_word;
};

static struct gate_desc idt[IDT_DESC_CNT]; //idt是中段描述符表，本质上是个中断描述符数组
extern intr_handler intr_entry_table[IDT_DESC_CNT]; //声明引用定义在kernel.s中的中断处理程序入口数组
                                                    //intr_handler为void*类型
//静态函数声明，非必须
static void make_idt_desc(struct gate_desc* p_gdesc, uint8_t attr, intr_handler function);

/*初始化可编程中断控制器8259A*/
static void pic_init(void) {
    //初始化主片
    outb(PIC_M_CTRL, 0x11);   //ICW1:0001_0001 边沿触发，级联8259，需要ICW4
    outb(PIC_M_DATA, 0x20);   //ICW2:0010_0000 起始中断向量号0x20，0x20~0x2f
    outb(PIC_M_DATA, 0x04);   //ICW3:0000_0100 IR2接从片
    outb(PIC_M_DATA, 0x01);   //ICW4:0000_0001 8086模式，正常EOI

    //初始化从片
    outb(PIC_S_CTRL, 0x11);   //ICW1:0001_0001 边沿触发，级联8259，需要ICW4
    outb(PIC_S_DATA, 0x28);   //ICW2:0010_1000 起始中断向量号为0x28，0x28~0x2f
    outb(PIC_S_DATA, 0x02);   //ICW3:0000_0010 设置从片连接到主片的IR2引脚
    outb(PIC_S_DATA, 0x01);   //ICW4:0000_0001 8086模式，正常EOI

    //打开主片上IR0，也就是目前只接受始终产生的中断
    outb(PIC_M_DATA, 0xfe);   //OCW1:1111_1110
    outb(PIC_S_DATA, 0xfe);   //COW1:1111_1110

    put_str("   pic_init done\n");
}

/*创建中断门描述符*/
static void make_idt_desc(struct gate_desc* p_gdesc, uint8_t attr, intr_handler function) {
    p_gdesc->func_offset_low_word = (uint32_t)function & 0x0000ffff;
    p_gdesc->selector = SELECTOR_K_CODE;
    p_gdesc->dcount = 0;
    p_gdesc->attribute = attr;
    p_gdesc->func_offset_high_word = ((uint32_t)function & 0xffff0000) >> 16;
}

/*初始化中断描述表*/
static void idt_desc_init(void) {
    int i;
    for(i=0; i<IDT_DESC_CNT; i++) {
        make_idt_desc(&idt[i], IDT_DESC_ATTR_DPL0, intr_entry_table[i]);
    }
    put_str("idt_desc_init done\n");
}

/*完成中断的所有初始化工作*/
void idt_init() {
    put_str("idt_init start\n");
    idt_desc_init();    //初始化中断描述符表
    pic_init();         //初始化8259A

    /* 加载IDT */
    uint64_t idt_operand = ((sizeof(idt)-1) | ((uint64_t)((uint32_t)idt << 16)));
    asm volatile ("lidt %0" : : "m"(idt_operand));
    put_str("idt_init done\n");
}
