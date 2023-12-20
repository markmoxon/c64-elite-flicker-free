; ******************************************************************************
;
; FLICKER-FREE COMMODORE PLUS/4 ELITE
;
; BBC Master Elite was written by Ian Bell and David Braben and is copyright
; Acornsoft 1986
;
; The code on this site has been reconstructed from a disassembly of the version
; released on Ian Bell's personal website at http://www.elitehomepage.org/
;
; The commentary is copyright Mark Moxon, and any misunderstandings or mistakes
; in the documentation are entirely my fault
;
; The terminology and notations used in this commentary are explained at
; https://www.bbcelite.com/about_site/terminology_used_in_this_commentary.html
;
; The deep dive articles referred to in this commentary can be found at
; https://www.bbcelite.com/deep_dives
;
; ******************************************************************************

 GUARD $CE00            ; Guard against assembling over memory used by game

; ******************************************************************************
;
; Configuration variables
;
; The addresses in the following are from when the game binary is loaded into
; memory. They were calculated by analysing a memory dump of the running game,
; searching for patterns in the bytes to match them with the corrsponding code
; from the BBC Micro version (which is very similar, if you ignore any different
; addresses).
;
; LSNUM is an unused variable in BBC Micro Elite, and the corresponding address
; in Commodore 64 Elite is used by something else. Luckily locations $FB to $FE
; are unused by Elite and the OS, so we can sneak LSNUM and LSNUM2 in there
; instead.
;
; Also, the Y variable contains the height of the space view in pixels, divided
; by 2. This is 96 on the BBC Micro, but the space view is 144 pixels on the
; Commodore 64, so Y needs to be set to 72 instead.
;
; ******************************************************************************

 XX1    = $0009         ; Variables for flicker-free ships
 INWK   = $0009
 XX19   = $002A
 K3     = $0035
 K4     = $0043
 XX0    = $0057
 V      = $005B
 XX15   = $006B
 X1     = $006B
 Y1     = $006C
 X2     = $006D
 Y2     = $006E
 XX12   = $0071
 XX17   = $009F
 CNT    = $00AA
 XX4    = $00AD
 XX20   = $00AE
 LSNUM  = $00FB
 LSNUM2 = $00FC
 PROJ   = $7D1F + $08F0
 LL75   = $9FB8 + $0900
 LL30   = $AB91 + $090C
 Y      = 72

 K      = $0077         ; Variables for flicker-free planets
 LSP    = $007E
 K5     = $0085
 K6     = $0089
 XX13   = $00A2
 TYPE   = $00A5
 FLAG   = $00A9
 CNT2   = $00AB
 STP    = $00AC
 T      = $00BB
 SWAP   = $06F4
 LSX2   = $26A4 - 3
 LSY2   = $27A4 - 3
 PL9_2  = $7DA4 + $08F0
 PL26   = $7DE0 + $08F0
 PLL4   = $7E5F + $08F0
 CIRCLE = $8044 + $08F0
 WP1    = $80F5 + $08F0
 LL145  = $A013 + $0900

; ******************************************************************************
;
;       Name: SHPPT
;       Type: Subroutine
;   Category: Drawing ships
;    Summary: Draw a distant ship as a point rather than a full wireframe
;
; ******************************************************************************

 ORG $9932 + $0900

.SHPPT

 JSR PROJ               ; Project the ship onto the screen, returning:
                        ;
                        ;   * K3(1 0) = the screen x-coordinate
                        ;   * K4(1 0) = the screen y-coordinate
                        ;   * A = K4+1

 ORA K3+1               ; If either of the high bytes of the screen coordinates
 BNE nono               ; are non-zero, jump to nono as the ship is off-screen

 LDA K4                 ; Set A = the y-coordinate of the dot

 CMP #Y*2-2             ; If the y-coordinate is bigger than the y-coordinate of
 BCS nono               ; the bottom of the screen, jump to nono as the ship's
                        ; dot is off the bottom of the space view

 JSR Shpt               ; Call Shpt to draw a horizontal 4-pixel dash for the
                        ; first row of the dot (i.e. a four-pixel dash)

 LDA K4                 ; Set A = y-coordinate of dot + 1 (so this is the second
 CLC                    ; row of the two-pixel-high dot)
 ADC #1

 JSR Shpt               ; Call Shpt to draw a horizontal 4-pixel dash for the
                        ; first row of the dot (i.e. a four-pixel dash)

 LDA #%00001000         ; Set bit 3 of the ship's byte #31 to record that we
 ORA XX1+31             ; have now drawn something on-screen for this ship
 STA XX1+31

 JMP LL155              ; Jump to LL155 to draw any remaining lines that are
                        ; still in the ship line heap and return from the
                        ; subroutine using a tail call

.nono

 LDA #%11110111         ; Clear bit 3 of the ship's byte #31 to record that
 AND XX1+31             ; nothing is being drawn on-screen for this ship
 STA XX1+31

 JMP LL155              ; Jump to LL155 to draw any remaining lines that are
                        ; still in the ship line heap and return from the
                        ; subroutine using a tail call

.Shpt

                        ; This routine draws a horizontal 4-pixel dash, for
                        ; either the top or the bottom of the ship's dot

 STA Y1                 ; Store A in both y-coordinates, as this is a horizontal
 STA Y2                 ; dash at y-coordinate A

 LDA K3                 ; Set A = screen x-coordinate of the ship dot

 STA X1                 ; Store the x-coordinate of the ship dot in X1, as this
                        ; is where the dash starts

 CLC                    ; Set A = screen x-coordinate of the ship dot + 3
 ADC #3

 BCC P%+4               ; If the addition overflowed, set A = 255, the
 LDA #255               ; x-coordinate of the right edge of the screen

 STA X2                 ; Store the x-coordinate of the ship dot in X1, as this
                        ; is where the dash starts

 JMP LSPUT              ; Draw this edge using flicker-free animation, by first
                        ; drawing the ship's new line and then erasing the
                        ; corresponding old line from the screen, and return
                        ; from the subroutine using a tail call

 SAVE "shppt-plus4.bin", SHPPT, P%

; ******************************************************************************
;
;       Name: LL9 (Part 11 of 12)
;       Type: Subroutine
;   Category: Drawing ships
;    Summary: Draw ship: Loop back for the next edge
;  Deep dive: Drawing ships
;
; ******************************************************************************

 ORG $A15B + $0900

.LL78

 LDA LSNUM              ; If LSNUM >= CNT, skip to LL81 so we don't loop back
 CMP CNT                ; for the next edge (CNT was set to the maximum heap
 BCS LL81               ; size for this ship in part 10, so this checks whether
                        ; we have just run out of space in the ship line heap,
                        ; and stops drawing edges if we have)

 LDA V                  ; Increment V by 4 so V(1 0) points to the data for the
 CLC                    ; next edge
 ADC #4
 STA V

 BCC ll81               ; If the above addition didn't overflow, jump to ll81

 INC V+1                ; Otherwise increment the high byte of V(1 0), as we
                        ; just moved the V(1 0) pointer past a page boundary

.ll81

 INC XX17               ; Increment the edge counter to point to the next edge

 LDY XX17               ; If Y >= XX20, which contains the number of edges in
 CPY XX20               ; the blueprint, skip the following
 BCS P%+5

 JMP LL75-2             ; Loop back to LL75-2 to process the next edge (we jump
                        ; to LL75-2 as we have modified the code around LL75,
                        ; which moves the jump point back by two bytes)

.LL81

 NOP

 SAVE "ll78-plus4.bin", LL78, P%

; ******************************************************************************
;
;       Name: LL9 (Part 12 of 12)
;       Type: Subroutine
;   Category: Drawing ships
;    Summary: Draw ship: Draw all the visible edges from the ship line heap
;  Deep dive: Drawing ships
;
; ******************************************************************************

 ORG $A178 + $0900

.LL155

 LDY LSNUM              ; Set Y to the offset in the line heap LSNUM

.LL27

 CPY LSNUM2             ; If Y >= LSNUM2, jump to LLEX to return from the ship
 BCS LLEX               ; drawing routine, because the index in Y is greater
                        ; than the size of the existing ship line heap, which
                        ; means we have alrady erased all the old ships lines
                        ; when drawing the new ship

                        ; If we get here then Y < LSNUM2, which means Y is
                        ; pointing to an on-screen line from the old ship that
                        ; we need to erase

 LDA (XX19),Y           ; Fetch the X1 line coordinate from the heap and store
 STA XX15               ; it in XX15

 INY                    ; Increment the heap pointer

 LDA (XX19),Y           ; Fetch the Y1 line coordinate from the heap and store
 STA XX15+1             ; it in XX15+1

 INY                    ; Increment the heap pointer

 LDA (XX19),Y           ; Fetch the X2 line coordinate from the heap and store
 STA XX15+2             ; it in XX15+2

 INY                    ; Increment the heap pointer

 LDA (XX19),Y           ; Fetch the Y2 line coordinate from the heap and store
 STA XX15+3             ; it in XX15+3

 JSR LL30               ; Draw a line from (X1, Y1) to (X2, Y2) to erase it from
                        ; the screen

 INY                    ; Increment the heap pointer

 JMP LL27               ; Loop back to LL27 to draw (i.e. erase) the next line
                        ; from the heap

.LLEX

 LDA LSNUM              ; Store LSNUM in the first byte of the ship line heap
 LDY #0
 STA (XX19),Y

.LL82

 RTS                    ; Return from the subroutine

 SAVE "ll155-plus4.bin", LL155, P%

; ******************************************************************************
;
;       Name: BLINE
;       Type: Subroutine
;   Category: Drawing circles
;    Summary: Draw a circle segment and add it to the ball line heap
;
; ******************************************************************************

 ORG $2977 - 3

 GUARD $2A12 - 3

.BLINE

 TXA                    ; Set K6(3 2) = (T X) + K4(1 0)
 ADC K4                 ;             = y-coord of centre + y-coord of new point
 STA K6+2               ;
 LDA K4+1               ; so K6(3 2) now contains the y-coordinate of the new
 ADC T                  ; point on the circle but as a screen coordinate, to go
 STA K6+3               ; along with the screen y-coordinate in K6(1 0)

 LDA FLAG               ; If FLAG = 0, jump down to BL1
 BEQ BL1

 INC FLAG               ; Flag is $FF so this is the first call to BLINE, so
                        ; increment FLAG to set it to 0, as then the next time
                        ; we call BLINE it can draw the first line, from this
                        ; point to the next

.BL5

 JSR DrawPlanetLine     ; Draw the current line from the old planet

                        ; The following inserts a $FF marker into the LSY2 line
                        ; heap to indicate that the next call to BLINE should
                        ; store both the (X1, Y1) and (X2, Y2) points. We do
                        ; this on the very first call to BLINE (when FLAG is
                        ; $FF), and on subsequent calls if the segment does not
                        ; fit on-screen, in which case we don't draw or store
                        ; that segment, and we start a new segment with the next
                        ; call to BLINE that does fit on-screen

 LDY LSP                ; If byte LSP-1 of LSY2 = $FF, jump to BL7 to tidy up
 LDA #$FF               ; and return from the subroutine, as the point that has
 CMP LSY2-1,Y           ; been passed to BLINE is the start of a segment, so all
 BEQ BL7                ; we need to do is save the coordinate in K5, without
                        ; moving the pointer in LSP

 STA LSY2,Y             ; Otherwise we just tried to plot a segment but it
                        ; didn't fit on-screen, so put the $FF marker into the
                        ; heap for this point, so the next call to BLINE starts
                        ; a new segment

 INC LSP                ; Increment LSP to point to the next point in the heap

 BNE BL7                ; Jump to BL7 to tidy up and return from the subroutine
                        ; (this BNE is effectively a JMP, as LSP will never be
                        ; zero)

.BL1

 LDA K5                 ; Set XX15 = K5 = x_lo of previous point
 STA XX15

 LDA K5+1               ; Set XX15+1 = K5+1 = x_hi of previous point
 STA XX15+1

 LDA K5+2               ; Set XX15+2 = K5+2 = y_lo of previous point
 STA XX15+2

 LDA K5+3               ; Set XX15+3 = K5+3 = y_hi of previous point
 STA XX15+3

 LDA K6                 ; Set XX15+4 = x_lo of new point
 STA XX15+4

 LDA K6+1               ; Set XX15+5 = x_hi of new point
 STA XX15+5

 LDA K6+2               ; Set XX12 = y_lo of new point
 STA XX12

 LDA K6+3               ; Set XX12+1 = y_hi of new point
 STA XX12+1

 JSR LL145              ; Call LL145 to see if the new line segment needs to be
                        ; clipped to fit on-screen, returning the clipped line's
                        ; end-points in (X1, Y1) and (X2, Y2)

 BCS BL5                ; If the C flag is set then the line is not visible on
                        ; screen anyway, so jump to BL5, to avoid drawing and
                        ; storing this line

 LDA SWAP               ; If SWAP = 0, then we didn't have to swap the line
 BEQ BL9                ; coordinates around during the clipping process, so
                        ; jump to BL9 to skip the following swap

 LDA X1                 ; Otherwise the coordinates were swapped by the call to
 LDY X2                 ; LL145 above, so we swap (X1, Y1) and (X2, Y2) back
 STA X2                 ; again
 STY X1
 LDA Y1
 LDY Y2
 STA Y2
 STY Y1

.BL9

 LDY LSP                ; Set Y = LSP

 LDA LSY2-1,Y           ; If byte LSP-1 of LSY2 is not $FF, jump down to BL8
 CMP #$FF               ; to skip the following (X1, Y1) code
 BNE BL8

                        ; Byte LSP-1 of LSY2 is $FF, which indicates that we
                        ; need to store (X1, Y1) in the heap

 JSR DrawPlanetLine     ; Draw the current line from the old planet

 LDA X1                 ; Store X1 in the LSP-th byte of LSX2
 STA LSX2,Y

 LDA Y1                 ; Store Y1 in the LSP-th byte of LSY2
 STA LSY2,Y

 INY                    ; Increment Y to point to the next byte in LSX2/LSY2

.BL8

 LDA #$FF               ; Set bit 7 of K3+8 so we do not draw the current line
 STA K3+8               ; in the call to DrawPlanetLine, but store the
                        ; coordinates so we we can check them below

 JSR DrawPlanetLine+4   ; Calculate the current line from the old heap, but do
                        ; not draw it, but store the coordinates (X1, Y1) and
                        ; (X2, Y2) in K3+4 to K3+7

 LDA X2                 ; Store X2 in the LSP-th byte of LSX2
 STA LSX2,Y

 LDA Y2                 ; Store Y2 in the LSP-th byte of LSX2
 STA LSY2,Y

 INY                    ; Increment Y to point to the next byte in LSX2/LSY2

 STY LSP                ; Update LSP to point to the same as Y

 JSR DrawNewPlanetLine  ; Draw a line from (X1, Y1) to (X2, Y2), but only if it
                        ; is different to the old line in K3+4 to K3+7

 LDA XX13               ; If XX13 is non-zero, jump up to BL5 to add a $FF
 BNE BL5                ; marker to the end of the line heap. XX13 is non-zero
                        ; after the call to the clipping routine LL145 above if
                        ; the end of the line was clipped, meaning the next line
                        ; sent to BLINE can't join onto the end but has to start
                        ; a new segment, and that's what inserting the $FF
                        ; marker does

.BL7

 LDA K6                 ; Copy the data for this step point from K6(3 2 1 0)
 STA K5                 ; into K5(3 2 1 0), for use in the next call to BLINE:
 LDA K6+1               ;
 STA K5+1               ;   * K5(1 0) = screen x-coordinate of this point
;LDA K6+2               ;
;STA K5+2               ;   * K5(3 2) = screen y-coordinate of this point
;LDA K6+3               ;
;STA K5+3               ; They now become the "previous point" in the next call

 JMP PATCH3             ; Jump to patch to implement the commented out
                        ; instructions above, plus the rest of the routine

 SAVE "bline-plus4.bin", BLINE, P%

; ******************************************************************************
;
;       Name: PL9 (Part 1 of 3)
;       Type: Subroutine
;   Category: Drawing planets
;    Summary: Draw the planet, with either an equator and meridian, or a crater
;
; ******************************************************************************

 ORG $7D8C + $08F0

 GUARD $7DA4 + $08F0

.PL9

 JSR CIRCLE             ; Call CIRCLE to draw the planet's new circle

 BCS PL20A              ; If the call to CIRCLE returned with the C flag set,
                        ; then the circle does not fit on-screen, so jump to
                        ; PL20A to remove the planet from the screen and return
                        ; from the subroutine

 LDA K+1                ; If K+1 is zero, jump to PL25 as K(1 0) < 256, so the
 BEQ PL25               ; planet fits on the screen and we can draw meridians or
                        ; craters

.PL20

 JMP EraseRestOfPlanet  ; We have drawn the new circle, so now we need to erase
                        ; any lines that are left in the ball line heap, before
                        ; returning from the subroutine using a tail call

.PL20A

 JMP WPLS2              ; Call WPLS2 to remove the planet from the screen

.PL25

 LDA $1D0F              ; Skip craters and meridians if not configured
 BEQ PL20

 JMP PATCH6             ; Jump to PATCH6 for the rest of the routine

 SAVE "pl9-plus4.bin", PL9, P%

; ******************************************************************************
;
;       Name: WPLS2
;       Type: Subroutine
;   Category: Drawing planets
;    Summary: Remove the planet from the screen
;
; ******************************************************************************

 ORG $80BB + $08F0

 GUARD $80F5 + $08F0

.WPLS2

 LDY LSX2               ; If LSX2 is non-zero (which indicates the ball line
 BNE WP1                ; heap is empty), jump to WP1 to reset the line heap
                        ; without redrawing the planet

 STY LSNUM              ; Reset LSNUM to the start of the ball line heap (we can
                        ; set this to 0 rather than 1 to take advantage of the
                        ; fact that Y is 0 - the effect is the same)

 LDA LSP                ; Set LSNUM2 to the end of the ball line heap
 STA LSNUM2

 JSR EraseRestOfPlanet  ; Draw the contents of the ball line heap to erase the
                        ; old planet

 JMP WP1                ; Reset the ball line heap and return from the
                        ; subroutine using a tail call

; ******************************************************************************
;
;       Name: EraseRestOfPlanet
;       Type: Subroutine
;   Category: Drawing lines
;    Summary: Draw all remaining lines in the ball line heap to erase the rest
;             of the old planet
;
; ******************************************************************************

.EraseRestOfPlanet

 LDY LSNUM              ; Set Y to the offset in LSNUM, which points to the part
                        ; of the heap that we are overwriting with new points

 CPY LSNUM2             ; If LSNUM >= LSNUM2, then we have already redrawn all
 BCS eras1              ; of the lines from the old circle's ball line heap, so
                        ; skip the following

 JSR DrawPlanetLine     ; Erase the next planet line from the ball line heap

 JMP EraseRestOfPlanet  ; Loop back for the next line in the ball line heap

.eras1

 RTS                    ; Return from the subroutine

; ******************************************************************************
;
;       Name: BLINE
;       Type: Subroutine
;   Category: Drawing circles
;    Summary: Draw a circle segment and add it to the ball line heap
;
; ******************************************************************************

.PATCH3

                        ; These are the instructions from the end of BLINE that
                        ; we move here so there's room for the patch

 LDA K6+2               ;
 STA K5+2               ;   * K5(3 2) = screen y-coordinate of this point
 LDA K6+3               ;
 STA K5+3               ; They now become the "previous point" in the next call

 LDA CNT                ; Set CNT = CNT + STP
 CLC
 ADC STP
 STA CNT

 RTS                    ; Return from the subroutine

; ******************************************************************************
;
;       Name: PL9 (Part 1 of 3)
;       Type: Subroutine
;   Category: Drawing planets
;    Summary: Draw the planet, with either an equator and meridian, or a crater
;
; ******************************************************************************

.PATCH6

 LDA TYPE               ; If the planet type is 128 then it has an equator and
 CMP #128               ; a meridian, so this jumps to PL26 if this is not a
 BNE P%+5               ; planet with an equator - in other words, if it is a
                        ; planet with a crater

 JMP PL9_2              ; Otherwise this is a planet with an equator and
                        ; meridian, so jump to the equator routine in part 2 of
                        ; PL9

 JMP PL26               ; Jump to the crater routine

 SAVE "wpls2-plus4.bin", WPLS2, P%

; ******************************************************************************
;
;       Name: LSPUT
;       Type: Subroutine
;   Category: Drawing lines
;    Summary: Draw a ship line using flicker-free animation
;
; ******************************************************************************

 ORG $7200

 GUARD $7300

.LSPUT

 LDY LSNUM              ; Set Y = LSNUM, to get the offset within the ship line
                        ; heap where we want to insert our new line

 CPY LSNUM2             ; Compare LSNUM and LSNUM2 and store the flags on the
 PHP                    ; stack so we can retrieve them later

 LDX #3                 ; We now want to copy the line coordinates (X1, Y1) and
                        ; (X2, Y2) to XX12...XX12+3, so set a counter to copy
                        ; 4 bytes

.LLXL

 LDA X1,X               ; Copy the X-th byte of X1/Y1/X2/Y2 to the X-th byte of
 STA XX12,X             ; XX12

 DEX                    ; Decrement the loop counter

 BPL LLXL               ; Loop back until we have copied all four bytes

 JSR LL30               ; Draw a line from (X1, Y1) to (X2, Y2)

 LDA (XX19),Y           ; Set X1 to the Y-th coordinate on the ship line heap,
 STA X1                 ; i.e. one we are replacing in the heap

 LDA XX12               ; Replace it with the X1 coordinate in XX12
 STA (XX19),Y

 INY                    ; Increment the index to point to the Y1 coordinate

 LDA (XX19),Y           ; Set Y1 to the Y-th coordinate on the ship line heap,
 STA Y1                 ; i.e. one we are replacing in the heap

 LDA XX12+1             ; Replace it with the Y1 coordinate in XX12+1
 STA (XX19),Y

 INY                    ; Increment the index to point to the X2 coordinate

 LDA (XX19),Y           ; Set X1 to the Y-th coordinate on the ship line heap,
 STA X2

 LDA XX12+2             ; Replace it with the X2 coordinate in XX12+2
 STA (XX19),Y

 INY                    ; Increment the index to point to the Y2 coordinate

 LDA (XX19),Y           ; Set Y2 to the Y-th coordinate on the ship line heap,
 STA Y2

 LDA XX12+3             ; Replace it with the Y2 coordinate in XX12+3
 STA (XX19),Y

 INY                    ; Increment the index to point to the next coordinate
 STY LSNUM              ; and store the updated index in LSNUM

 PLP                    ; Restore the result of the comparison above, so if the
 BCS LL82a              ; original value of LSNUM >= LSNUM2, then we have
                        ; alreadyredrawn all the lines from the old ship's line
                        ; heap, so return from the subroutine (as LL82 contains
                        ; an RTS)

 JMP LL30               ; Otherwise there are still more lines to erase from the
                        ; old ship on-screen, so the coordinates in (X1, Y1) and
                        ; (X2, Y2) that we just pulled from the ship line heap
                        ; point to a line that is still on-screen, so call LL30
                        ; to draw this line and erase it from the screen,
                        ; returning from the subroutine using a tail call

.LL82a

 RTS                    ; Return from the subroutine

; ******************************************************************************
;
;       Name: LL9 (Part 1 of 12)
;       Type: Subroutine
;   Category: Drawing ships
;    Summary: Draw ship: Check if ship is exploding, check if ship is in front
;  Deep dive: Drawing ships
;
; ******************************************************************************

.PATCH1

                        ; We replace the following two instructions in part 1 of
                        ; LL9 with JSR PATCH1, so we start with those two
                        ; instructions to ensure that they still get done

 LDA #31                ; Set XX4 = 31 to store the ship's distance for later
 STA XX4                ; comparison with the visibility distance. We will
                        ; update this value below with the actual ship's
                        ; distance if it turns out to be visible on-screen

                        ; We now set things up for flicker-free ship plotting,
                        ; by setting the following:
                        ;
                        ;   LSNUM = offset to the first coordinate in the ship's
                        ;           line heap
                        ;
                        ;   LSNUM2 = the number of bytes in the heap for the
                        ;            ship that's currently on-screen (or 0 if
                        ;            there is no ship currently on-screen)

 LDY #1                 ; Set LSNUM = 1, the offset of the first set of line
 STY LSNUM              ; coordinates in the ship line heap

 DEY                    ; Decrement Y to 0

 LDA #%00001000         ; If bit 3 of the ship's byte #31 is set, then the ship
 BIT INWK+31            ; is currently being drawn on-screen, so skip the
 BNE P%+5               ; following two instructions

 LDA #0                 ; The ship is not being drawn on screen, so set A = 0
                        ; so that LSNUM2 gets set to 0 below (as there are no
                        ; existing coordinates on the ship line heap for this
                        ; ship)

 EQUB $2C               ; Skip the next instruction by turning it into
                        ; $2C $B1 $BD, or BIT $BDB1 which does nothing apart
                        ; from affect the flags

 LDA (XX19),Y           ; Set LSNUM2 to the first byte of the ship's line heap,
 STA LSNUM2             ; which contains the number of bytes in the heap

 RTS

; ******************************************************************************
;
;       Name: LL9 (Part 10 of 12)
;       Type: Subroutine
;   Category: Drawing ships
;    Summary: Draw ship: Check if ship is exploding, check if ship is in front
;  Deep dive: Drawing ships
;
; ******************************************************************************

.PATCH2

                        ; We replace the JMP LL78 instruction at the end of part
                        ; 10 of LL9 with JSR PATCH2, so this effectively inserts
                        ; the call to LSPUT at the end of part 10, as required

 JSR LSPUT              ; Draw the laser line using flicker-free animation, by
                        ; first drawing the new laser line and then erasing the
                        ; corresponding old line from the screen

 JMP LL78               ; Jump down to part 11

; ******************************************************************************
;
;       Name: DrawPlanetLine
;       Type: Subroutine
;   Category: Drawing lines
;    Summary: Draw a segment of the old planet from the ball line heap
;
; ------------------------------------------------------------------------------
;
; Other entry points:
;
;   DrawPlanetLine+4    If bit 7 of K3+8 is set, store the line coordinates in
;                       K3+4 to K3+7 (X1, Y1, X2, Y2) and do not draw the line
;
; ******************************************************************************

.DrawPlanetLine

 LDA #0                 ; Clear bit 7 of K3+8 so we draw the current line below
 STA K3+8

 LDA #0                 ; Clear bit 7 of K3+9 to indicate that there is no line
 STA K3+9               ; to draw (we may change this below)

 LDA LSNUM              ; If LSNUM = 1, then this is the first point from the
 CMP #2                 ; heap, so jump to plin3 to set the previous coordinate
 BCC plin3              ; and return from the subroutine

 LDA X1                 ; Save X1, X2, Y1, Y2 and Y on the stack
 PHA
 LDA Y1
 PHA
 LDA X2
 PHA
 LDA Y2
 PHA
 TYA
 PHA

 LDY LSNUM              ; Set Y to the offset in LSNUM, which points to the part
                        ; of the heap that we are overwriting with new points

 CPY LSNUM2             ; If LSNUM >= LSNUM2, then we have already redrawn all
 BCS plin1              ; of the lines from the old circle's ball line heap, so
                        ; jump to plin1 to return from the subroutine

                        ; Otherwise we need to draw the line from the heap, to
                        ; erase it from the screen

 LDA K3+2               ; Set X1 = K3+2 = screen x-coordinate of previous point
 STA X1                 ; from the old heap

 LDA K3+3               ; Set Y1 = K3+3 = screen y-coordinate of previous point
 STA Y1                 ; from the old heap

 LDA LSX2,Y             ; Set X2 to the y-coordinate from the LSNUM-th point in
 STA X2                 ; the heap

 STA K3+2               ; Store the x-coordinate of the point we are overwriting
                        ; in K3+2, so we can use it on the next iteration

 LDA LSY2,Y             ; Set Y2 to the y-coordinate from the LSNUM-th point in
 STA Y2                 ; the heap

 STA K3+3               ; Store the y-coordinate of the point we are overwriting
                        ; in K3+3, so we can use it on the next iteration

 INC LSNUM              ; Increment LSNUM to point to the next coordinate, so we
                        ; work our way through the current heap

 LDA Y1                 ; If Y1 or Y2 = $FF then this indicates a break in the
 CMP #$FF               ; circle, so jump to plin1 to skip the following and
 BEQ plin1              ; return from the subroutine, asthere is no line to
 LDA Y2                 ; erase
 CMP #$FF
 BEQ plin1

 DEC K3+9               ; Decrement K3+9 to $FF to indicate that there is a line
                        ; to draw

 BIT K3+8               ; If bit 7 of K3+8 is set, jump to plin2 to store the
 BMI plin2              ; line coordinates rather than drawing the line

 JSR LL30               ; The coordinates in (X1, Y1) and (X2, Y2) that we just
                        ; pulled from the ball line heap point to a line that is
                        ; still on-screen, so call LL30 to draw this line and
                        ; erase it from the screen

.plin1

 PLA                    ; Restore Y, X1, X2, Y1 and Y2 from the stack
 TAY
 PLA
 STA Y2
 PLA
 STA X2
 PLA
 STA Y1
 PLA
 STA X1

 RTS                    ; Return from the subroutine

.plin2

 LDA X1                 ; Store X1, Y1, X2, Y2 in K3+4 to K3+7
 STA K3+4
 LDA Y1
 STA K3+5
 LDA X2
 STA K3+6
 LDA Y2
 STA K3+7

 JMP plin1              ; Jump to plin1 to return from the subroutine

.plin3

 LDA LSX2+1             ; Store the heap's first coordinate in K3+2 and K3+3
 STA K3+2
 LDA LSY2+1
 STA K3+3

 INC LSNUM              ; Increment LSNUM to point to the next coordinate, so we
                        ; work our way through the current heap

 RTS                    ; Return from the subroutine

 SAVE "extra-plus4.bin", LSPUT, P%

; ******************************************************************************
;
;       Name: TRUMBLE
;       Type: Subroutine
;   Category: Drawing lines
;    Summary: Put patches into NOPs in Trumble code
;
; ******************************************************************************

 ORG $1E6A

 GUARD $1EB6

.TRUMBLE

 JMP PATCHEND           ; We inject the following into the batch of NOPs that
                        ; the Plus/4 version has inserted into the middle of the
                        ; Trumble sprite-plotting routine, so this instruction
                        ; just skips over the patches so the routine can still
                        ; run (the Trumble routine does not have an entry point
                        ; within the NOPs, so this is safe)

; ******************************************************************************
;
;       Name: DrawNewPlanetLine
;       Type: Subroutine
;   Category: Drawing lines
;    Summary: Draw a ball line, but only if it is different to the old line
;
; ------------------------------------------------------------------------------
;
; Arguments:
;
;   K3+4 to K3+7        The (X1, Y1) and (X2, Y2) coordinates of the old line
;
; ******************************************************************************

.DrawNewPlanetLine

 BIT K3+9               ; If bit 7 of K3+9 is clear, then there is no old line
 BPL nlin2              ; to draw, so jump to nlin2 to draw the new line only

 LDA K3+4               ; If the old line equals the new line, jump to nlin3
 CMP X1                 ; to skip drawing both lines
 BNE nlin1
 LDA K3+5
 CMP Y1
 BNE nlin1
 LDA K3+6
 CMP X2
 BNE nlin1
 LDA K3+7
 CMP Y2
 BEQ nlin3

.nlin1

                        ; If we get here then the old line is different to the
                        ; new line, so we draw them both

 JSR LL30               ; Draw the new line from (X1, Y1) to (X2, Y2)

 LDA K3+4               ; Set up the old line's coordinates
 STA X1
 LDA K3+5
 STA Y1
 LDA K3+6
 STA X2
 LDA K3+7
 STA Y2

.nlin2

 JSR LL30               ; Draw the old line to erase it

.nlin3

 RTS                    ; Return from the subroutine

; ******************************************************************************
;
;       Name: PLS22
;       Type: Subroutine
;   Category: Drawing planets
;    Summary: Draw an ellipse or half-ellipse
;
; ******************************************************************************

.PATCH4

                        ; We replace the following instruction just before PL40
                        ; in PLS22 with JMP PATCH4, so we now do this
                        ; instruction to ensure that it still gets done

 STA CNT2               ; Set CNT2 = (CNT2 + STP) mod 64

 JMP PLL4               ; Jump back to PLL4 to draw the next segment

; ******************************************************************************
;
;       Name: CIRCLE2
;       Type: Subroutine
;   Category: Drawing circles
;    Summary: Draw a circle (for the planet or chart)
;  Deep dive: Drawing circles
;
; ******************************************************************************

.PATCH5

 LDX #0                 ; Set LSNUM = 0, to point to the offset before the first
 STX LSNUM              ; set of circle coordinates in the ball line heap

 LDX LSP                ; Set LSNUM2 to the last byte of the ball line heap
 STX LSNUM2

 LDX #1                 ; Set LSP = 1 to reset the ball line heap pointer
 STX LSP

                        ; We replace the following instructions at CIRCLE2 with
                        ; JSR PATCH5, so we now do those two instructions to
                        ; ensure that they still get done

 LDX #$FF               ; Set FLAG = $FF to reset the ball line heap in the call
 STX FLAG               ; to the BLINE routine below

 RTS                    ; Return from the subroutine

.PATCHEND

 SAVE "trumble-plus4.bin", TRUMBLE, P%
