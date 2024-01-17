#ifndef DISPLAY_H_INCLUDED
#define DISPLAY_H_INCLUDED
#include <stdint.h>

#define black 0;
#define white 255  /*black = background*/
#define replace 0
#define paint 1
#define invert 2  /*modes*/
#define Base 0xD0000000
#define Width 1366
#define Height 768


void CopyPattern(int col, uint32_t *patadr, int x, int y, int mode);  /*only for modes = paint, invert*/
void CopyBlock(int sx, int sy, int w, int h, int dx, int dy, int mode); /*only for mode = replace*/

#endif /* DISPLAY_H_INCLUDED */
