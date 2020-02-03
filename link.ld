ENTRY(_boot);

SECTIONS
{
    . = 0x0;
    .ipl :
    {
        *(.ipl)
    }

    /* The IPL loader is sensitive on where it is placed. See comments in ipl.S
     * for more details */
    . = 0x230;
    .load :
    {
        ipl.o (.load .text* .rodata*);
    }
 
    . = 0x320;
    /DISCARD/ : { *(.comment) *(.note*) *(.eh_frame*) }
}
