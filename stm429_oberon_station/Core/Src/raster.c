#include "raster.h"

#include "stm32f4xx_hal.h"

#define NofPixperWord  (32 / NofBPP)

extern DMA_HandleTypeDef hdma_memtomem_dma2_stream0;
/*
  PROCEDURE CopyPattern*(col, patadr, x, y, mode: INTEGER);  (*only for modes = paint, invert*)
    VAR a0, i, j: INTEGER; line: ARRAY 32 DIV NofPixperWord + 1 OF SET;
      w, h: BYTE; ps, psn, last: INTEGER;
  BEGIN SYSTEM.GET(patadr, i); w := i MOD 100H; h := i DIV 10000H MOD 100H; INC(patadr, 4);
    a0 := Base + x DIV NofPixperWord*4 + (Height-1-y)*Span; x := x MOD NofPixperWord;
    FOR i := 1 TO h DO
      (*build frame buffer line w<32*)
      last := (w+x+3) DIV 4 - 1;
      FOR j := 0 TO last DO SYSTEM.GET(a0+j*4, line[j]) END;
      IF x = 0 THEN (*pattern and frame buffer are aligned*)
        FOR j := 0 TO last DO
          SYSTEM.GET(patadr, ps); INC(patadr, 4);
          IF mode = invert THEN line[j] := line[j] / SYSTEM.VAL(SET, ps)
          ELSE line[j] := line[j] + SYSTEM.VAL(SET, ps) END
        END
      ELSE(*pattern must be right shifted by x pixels. Because of little endianness of
            STMF429 processor, words have to be left shifted by x*NofBPP*)
        SYSTEM.GET(patadr, ps); INC(patadr, 4);
        IF mode = invert THEN line[0] := line[0] / SYSTEM.VAL(SET, LSL(ps, x*NofBPP))
        ELSE line[0] := line[0] + SYSTEM.VAL(SET, LSL(ps, x*NofBPP)) END;
        (*process frame buffer words except the last one*)
        j := 1;
        WHILE j < (w+3) DIV 4 DO
          SYSTEM.GET(patadr, psn); INC(patadr, 4);
          ps := LSR(ps, (NofPixperWord - x)*NofBPP) + LSL(psn, x*NofBPP);
          IF mode = invert THEN line[j] := line[j] / SYSTEM.VAL(SET, ps)
          ELSE line[j] := line[j] + SYSTEM.VAL(SET, ps) END;
          ps := psn; INC(j)
        END;
        IF j <= last THEN
          (*process last word*)
          ps := LSR(ps, (NofPixperWord - x)*NofBPP);
          IF mode = invert THEN line[j] := line[j] / SYSTEM.VAL(SET, ps)
          ELSE line[j] := line[j] + SYSTEM.VAL(SET, ps) END
        END
      END;
      (*update frame buffer for this line*)
      FOR j := 0 TO last DO SYSTEM.PUT(a0+j*4, line[j]) END;
      DEC(a0, Span)
    END
  END CopyPattern;
*/

void CopyPattern(int col, uint32_t *patadr, int x, int y, int mode)  /*only for modes = paint, invert*/
{
    uint32_t *a0, i, j, line[32 / NofPixperWord + 1], pattern[(32/NofPixperWord) * (32/NofPixperWord)];
    uint8_t w, h;
    uint32_t ps, psn, last, middle;

    i = *patadr; w = i & 0xFF; h = (i >> 16) & 0xFF; patadr++;

//    if ((x < 0) || (x+w >= Width)) return;
//    if ((y < 0) || (y+h >= Height)) return;

    HAL_DMA_Start(&hdma_memtomem_dma2_stream0, (uint32_t) patadr, (uint32_t) pattern,
    		(w+3)/4*4/NofPixperWord*h);
    if (HAL_DMA_PollForTransfer(&hdma_memtomem_dma2_stream0, HAL_DMA_FULL_TRANSFER, 1) != HAL_OK) {
  	  return;
    }
    patadr = pattern;
    a0 = (uint32_t *)(Base + x/NofPixperWord*4 + (Height-1-y)*Span); x = x% NofPixperWord;
    last = (w+x+3) / 4 - 1; middle = (w+3) / 4;
    for (i = 1; i <= h; i++) {
      /*build frame buffer line w<32*/
      /*for (j = 0; j <= last; j++) line[j] = a0[j];*/
      HAL_DMA_Start(&hdma_memtomem_dma2_stream0, (uint32_t) a0, (uint32_t) line, last+1);
      if (HAL_DMA_PollForTransfer(&hdma_memtomem_dma2_stream0, HAL_DMA_FULL_TRANSFER, 1) != HAL_OK) {
    	  return;
      }
      if (x == 0) { /*pattern and frame buffer are aligned*/
        for (j = 0; j <= last; j++) {
          ps = *patadr; patadr++;
          if (mode == invert) line[j] ^= ps; else line[j] |= ps;
        }
      } else { /*pattern must be right shifted by x pixels. Because of little endianness of
            STMF429 processor, words have to be left shifted by x*NofBPP*/
        ps = *patadr; patadr++;
        if (mode == invert) line[0] ^= (ps << x*NofBPP); else line[0] |= (ps << x*NofBPP);
        /*process frame buffer words except the last one*/
        j = 1;
        while (j < middle) {
          psn = *patadr; patadr++;
          ps = (ps >> ((NofPixperWord - x)*NofBPP)) + (psn << x*NofBPP);
          if (mode == invert) line[j] ^=  ps; else line[j] |= ps;
          ps = psn; j++;
        }
        if (j <= last) {
          /*process last word*/
          ps >>= (NofPixperWord - x)*NofBPP;
          if (mode == invert) line[j] ^= ps; else line[j] |= ps;
        }
      }
      /*update frame buffer for this line*/
      /*
      for (j = 0; j <= last; j++) {
    	  a0[j] = line[j] ;
      }*/
      HAL_DMA_Start(&hdma_memtomem_dma2_stream0, (uint32_t) line, (uint32_t) a0, last+1);
      if (HAL_DMA_PollForTransfer(&hdma_memtomem_dma2_stream0, HAL_DMA_FULL_TRANSFER, 1) != HAL_OK) {
    	  return;
      }

      a0 -= Span/4;
    }
}

/*
  PROCEDURE CopyBlock*(sx, sy, w, h, dx, dy, mode: INTEGER); (*only for mode = replace*)
    VAR sa, da, sa0, sa1, d, len: INTEGER;
      u0, u1, u2, v0, v1, v3, n: INTEGER;
      end, step: INTEGER;
      src, dst, spill: SET;
      m0, m1, m2, m3: SET;
  BEGIN
    ASSERT((w >= 0) & (h >= 0));
    ASSERT((sx >= 0) & (sx+w < Width));
    ASSERT((sy >= 0) & (sy+h < Height));
    ASSERT((dx >= 0) & (dx+w < Width));
    ASSERT((dy >= 0) & (dy+h < Height));

    u0 := sx DIV NofPixperWord; u1 := sx MOD NofPixperWord; u2 := (sx+w) DIV NofPixperWord;
    v0 := dx DIV NofPixperWord; v1 := dx MOD NofPixperWord; v3 := (dx+w) MOD NofPixperWord;
    sa := Base + u0*4 + (Height-1-sy)*Span; da := Base + v0*4 + (Height-1-dy)*Span;
    d := da - sa; n := u1 - v1;   (*displacement in words and pixels*)
    len := (u2 - u0) * 4;
    m0 := {v1*NofBPP .. 31}; m2 := {v3*NofBPP .. 31}; m3 := m0 / m2;
    IF d >= 0 THEN (*copy down, scan up*) sa0 := sa; end := sa - h*Span; step := -Span
    ELSE (*copy up, scan down*) sa0 := sa - (h-1)*Span; end := sa + Span; step := Span
    END ;
    WHILE sa0 # end DO
      IF n >= 0 THEN (*shift right*) m1 := {n*NofBPP .. 31};
        IF v1 + w >= NofPixperWord THEN
          SYSTEM.GET(sa0+len, src); src := ROR(src, n*NofBPP);
          SYSTEM.GET(sa0+len+d, dst);
          SYSTEM.PUT(sa0+len+d, (dst * m2) + (src * m1 - m2));
          spill := src - m1;
          FOR sa1 := sa0 + len-4 TO sa0+4  BY -4 DO
            SYSTEM.GET(sa1, src); src := ROR(src, n*NofBPP);
            SYSTEM.PUT(sa1+d, spill + (src * m1));
            spill := src - m1
          END ;
          SYSTEM.GET(sa0, src); src := ROR(src, n*NofBPP);
          SYSTEM.GET(sa0+d, dst);
          SYSTEM.PUT(sa0+d, ((spill + (src * m1)) * m0) + (dst - m0))
        ELSE SYSTEM.GET(sa0, src); src := ROR(src, n*NofBPP);
          SYSTEM.GET(sa0+d, dst);
          SYSTEM.PUT(sa0+d, (src * m3) + (dst - m3))
        END
      ELSE (*shift left*) m1 := {-n*NofBPP .. 31};
        SYSTEM.GET(sa0, src); src := ROR(src, 32+n*NofBPP);
        SYSTEM.GET(sa0+d, dst);
        IF v1 + w < NofPixperWord THEN
          SYSTEM.PUT(sa0+d, (dst - m3) + (src * m3))
        ELSE SYSTEM.PUT(sa0+d, (dst - m0) + (src * m0));
          spill := src - m1;
          FOR sa1 := sa0+4 TO sa0 + len BY 4 DO
            SYSTEM.GET(sa1, src); src := ROR(src, 32+n*NofBPP);
            SYSTEM.PUT(sa1+d, spill + (src * m1));
            spill := src - m1
          END ;
          IF len+v1 > w THEN
            SYSTEM.GET(sa0+len+4+d, dst);
            SYSTEM.PUT(sa0+len+4+d, (spill - m2) + (dst * m2))
          END
        END
      END ;
      INC(sa0, step)
    END
  END CopyBlock;
*/

void CopyBlock(int sx, int sy, int w, int h, int dx, int dy, int mode) /*only for mode = replace*/
{
    int sa, da, d, len;
    uint32_t *sa0, *sa1;
    int u0, u1, u2, v0, v1, v3, n;
    int end, step;
    uint32_t src, dst, spill;
    uint32_t m0, m1, m2, m3;

    if ((w < 0) || (h < 0)) return;
    if ((sx < 0) || (sx+w >= Width)) return;
    if ((sy < 0) || (sy+h >= Height)) return;
    if ((dx < 0) || (dx+w >= Width)) return;
    if ((dy < 0) || (dy+h >= Height)) return;

    u0 = sx / NofPixperWord; u1 = sx % NofPixperWord; u2 = (sx+w) / NofPixperWord;
    v0 = dx / NofPixperWord; v1 = dx % NofPixperWord; v3 = (dx+w) % NofPixperWord;
    sa = Base + u0*4 + (Height-1-sy)*Span; da = Base + v0*4 + (Height-1-dy)*Span;
    d = da - sa; n = u1 - v1;   /*displacement in words and pixels*/
    len = (u2 - u0) * 4;
    m0 = (-1) << (v1*NofBPP); m2 = (-1) << (v3*NofBPP); m3 = m0 ^ m2;
    if (d >= 0) { /*copy down, scan up*/ sa0 = (uint32_t *)sa; end = sa - h*Span; step = -Span;
    } else { /*copy up, scan down*/ sa0 = (uint32_t *)(sa - (h-1)*Span); end = sa + Span; step = Span;
    }
    while ((uint32_t)sa0 != end) {
      if (n >= 0) { /*shift right*/ m1 = (-1) << (n*NofBPP);
        if (v1 + w >= NofPixperWord) {
          src = sa0[len/4];
          src = (src << (32-n*NofBPP)) | (src >> (n*NofBPP));
          dst = sa0[(len+d)/4];
          sa0[(len+d)/4] = (dst & m2) | (src & m1 & ~m2);
          spill = src & ~m1;
          for (sa1 = sa0+(len-4)/4; sa1 >= sa0+1; sa1--) {
            src = *sa1;
            src = (src << (32-n*NofBPP)) | (src >> (n*NofBPP));
            sa1[d/4] = spill | (src & m1);
            spill = src & ~m1;
          }
          src = *sa0; src = (src << (32-n*NofBPP)) | (src >> (n*NofBPP));
          dst = sa0[d/4];
          sa0[d/4] = ((spill | (src & m1)) & m0) | (dst & ~m0);
        } else { src = *sa0; src = (src << (32-n*NofBPP)) | (src >> (n*NofBPP));
          dst = sa0[d/4];
          sa0[d/4] = (src & m3) | (dst & ~m3);
        }
      } else { /*shift left*/ m1 = (-1) << (-n*NofBPP);
        src = *sa0;
        src = (src << (-n*NofBPP)) | (src >> (32+n*NofBPP));
        dst = sa0[d/4];
        if (v1 + w < NofPixperWord) {
          sa0[d/4] = (dst & ~m3) | (src & m3);
        } else { sa0[d/4] = (dst & ~m0) | (src & m0);
          spill = src & ~m1;
          for (sa1 = sa0+1; sa1 <= sa0 + len/4; sa1++) {
            src = *sa1; src = (src << (-n*NofBPP)) | (src >> (32+n*NofBPP));
            sa1[d/4] = spill | (src & m1);
            spill = src & ~m1;
          }
          if (len+v1 > w) {
              dst = sa0[(len+4+d)/4];
              sa0[(len+4+d)/4] = (spill & ~m2) | (dst & m2);
          }
        }
      }
      sa0 += step/4;
    }
}

/*
    CopyBlock(400, 400, 100, 200, 600, 550, replace);
    CopyBlock(0, 0, 18, 75, 19, 76, replace);
    CopyBlock(19, 76, 18, 16, 37, 76, replace);
    CopyBlock(19, 76, 18, 75, 37, 151, replace);
*/
