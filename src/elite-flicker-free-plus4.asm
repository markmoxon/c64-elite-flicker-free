\ ******************************************************************************
\
\ BBC MASTER ELITE GAME SOURCE (FLICKER-FREE ROUTINES)
\
\ BBC Master Elite was written by Ian Bell and David Braben and is copyright
\ Acornsoft 1986
\
\ The code on this site has been reconstructed from a disassembly of the version
\ released on Ian Bell's personal website at http://www.elitehomepage.org/
\
\ The commentary is copyright Mark Moxon, and any misunderstandings or mistakes
\ in the documentation are entirely my fault
\
\ The terminology and notations used in this commentary are explained at
\ https://www.bbcelite.com/about_site/terminology_used_in_this_commentary.html
\
\ The deep dive articles referred to in this commentary can be found at
\ https://www.bbcelite.com/deep_dives
\
\ ******************************************************************************

GUARD &CE00             \ Guard against assembling over memory used by game

\ ******************************************************************************
\
\ Configuration variables
\
\ The addresses in the following are from when the game binary is loaded into
\ memory. They were calculated by analysing a memory dump of the running game,
\ searching for patterns in the bytes to match them with the corrsponding code
\ from the BBC Micro version (which is very similar, if you ignore any different
\ addresses).
\
\ XX14 is an unused variable in BBC Micro Elite, and the corresponding address
\ in Commodore 64 Elite is used by something else. Luckily locations $FB to $FE
\ are unused by Elite and the OS, so we can sneak XX14 in there instead.
\
\ Also, the Y variable contains the height of the space view in pixels, divided
\ by 2. This is 96 on the BBC Micro, but the space view is 144 pixels on the
\ Commodore 64, so Y needs to be set to 72 instead.
\
\ ******************************************************************************

XX1     = $0009
INWK    = $0009
XX19    = $002A
K3      = $0035
K4      = $0043
XX0     = $0057
V       = $005B
XX15    = $006B
X1      = $006B
Y1      = $006C
X2      = $006D
Y2      = $006E
XX12    = $0071
XX17    = $009F
CNT     = $00AA
XX4     = $00AD
XX20    = $00AE
XX14    = $00FB
PROJ    = $860F         \ Note, this is not equal to $7D1F + $0900
LL75    = $9FB8 + $0900
LL30    = $B49D         \ Note, this is not equal to $AB91 + $0900
Y       = 72

\ ******************************************************************************
\
\       Name: SHPPT
\       Type: Subroutine
\   Category: Drawing ships
\    Summary: Draw a distant ship as a point rather than a full wireframe
\
\ ******************************************************************************

ORG $9932 + $0900

.SHPPT

 JSR PROJ               \ Project the ship onto the screen, returning:
                        \
                        \   * K3(1 0) = the screen x-coordinate
                        \   * K4(1 0) = the screen y-coordinate
                        \   * A = K4+1

 ORA K3+1               \ If either of the high bytes of the screen coordinates
 BNE nono               \ are non-zero, jump to nono as the ship is off-screen

 LDA K4                 \ Set A = the y-coordinate of the dot

 CMP #Y*2-2             \ If the y-coordinate is bigger than the y-coordinate of
 BCS nono               \ the bottom of the screen, jump to nono as the ship's
                        \ dot is off the bottom of the space view

 JSR Shpt               \ Call Shpt to draw a horizontal 4-pixel dash for the
                        \ first row of the dot (i.e. a four-pixel dash)

 LDA K4                 \ Set A = y-coordinate of dot + 1 (so this is the second
 CLC                    \ row of the two-pixel-high dot)
 ADC #1

 JSR Shpt               \ Call Shpt to draw a horizontal 4-pixel dash for the
                        \ first row of the dot (i.e. a four-pixel dash)

 LDA #%00001000         \ Set bit 3 of the ship's byte #31 to record that we
 ORA XX1+31             \ have now drawn something on-screen for this ship
 STA XX1+31

 JMP LL155              \ Jump to LL155 to draw any remaining lines that are
                        \ still in the ship line heap and return from the
                        \ subroutine using a tail call

.nono

 LDA #%11110111         \ Clear bit 3 of the ship's byte #31 to record that
 AND XX1+31             \ nothing is being drawn on-screen for this ship
 STA XX1+31

 JMP LL155              \ Jump to LL155 to draw any remaining lines that are
                        \ still in the ship line heap and return from the
                        \ subroutine using a tail call

.Shpt

                        \ This routine draws a horizontal 4-pixel dash, for
                        \ either the top or the bottom of the ship's dot

 STA Y1                 \ Store A in both y-coordinates, as this is a horizontal
 STA Y2                 \ dash at y-coordinate A

 LDA K3                 \ Set A = screen x-coordinate of the ship dot

 STA X1                 \ Store the x-coordinate of the ship dot in X1, as this
                        \ is where the dash starts

 CLC                    \ Set A = screen x-coordinate of the ship dot + 3
 ADC #3

 BCC P%+4               \ If the addition overflowed, set A = 255, the
 LDA #255               \ x-coordinate of the right edge of the screen

 STA X2                 \ Store the x-coordinate of the ship dot in X1, as this
                        \ is where the dash starts

 JMP LLX30              \ Draw this edge using flicker-free animation, by first
                        \ drawing the ship's new line and then erasing the
                        \ corresponding old line from the screen, and return
                        \ from the subroutine using a tail call

SAVE "shppt-plus4.bin", SHPPT, P%

\ ******************************************************************************
\
\       Name: LL9 (Part 11 of 12)
\       Type: Subroutine
\   Category: Drawing ships
\    Summary: Draw ship: Loop back for the next edge
\  Deep dive: Drawing ships
\
\ ******************************************************************************

ORG $A15B + $0900

.LL78

 LDA XX14               \ If XX14 >= CNT, skip to LL81 so we don't loop back for
 CMP CNT                \ the next edge (CNT was set to the maximum heap size
 BCS LL81               \ for this ship in part 10, so this checks whether we
                        \ have just run out of space in the ship line heap, and
                        \ stops drawing edges if we have)

 LDA V                  \ Increment V by 4 so V(1 0) points to the data for the
 CLC                    \ next edge
 ADC #4
 STA V

 BCC ll81               \ If the above addition didn't overflow, jump to ll81

 INC V+1                \ Otherwise increment the high byte of V(1 0), as we
                        \ just moved the V(1 0) pointer past a page boundary

.ll81

 INC XX17               \ Increment the edge counter to point to the next edge

 LDY XX17               \ If Y >= XX20, which contains the number of edges in
 CPY XX20               \ the blueprint, skip the following
 BCS P%+5

 JMP LL75-2             \ Loop back to LL75-2 to process the next edge (we jump
                        \ to LL75-2 as we have modified the code around LL75,
                        \ which moves the jump point back by two bytes)

.LL81

 NOP

SAVE "ll78-plus4.bin", LL78, P%

\ ******************************************************************************
\
\       Name: LL9 (Part 12 of 12)
\       Type: Subroutine
\   Category: Drawing ships
\    Summary: Draw ship: Draw all the visible edges from the ship line heap
\  Deep dive: Drawing ships
\
\ ******************************************************************************

ORG $A178 + $0900

.LL155

 LDY XX14               \ Set Y to the offset in the line heap XX14

.LL27

 CPY XX14+1             \ If Y >= XX14+1, jump to LLEX to return from the ship
 BCS LLEX               \ drawing routine, because the index in Y is greater
                        \ than the size of the existing ship line heap, which
                        \ means we have alrady erased all the old ships lines
                        \ when drawing the new ship

                        \ If we get here then Y < XX14+1, which means Y is
                        \ pointing to an on-screen line from the old ship that
                        \ we need to erase

 LDA (XX19),Y           \ Fetch the X1 line coordinate from the heap and store
 STA XX15               \ it in XX15

 INY                    \ Increment the heap pointer

 LDA (XX19),Y           \ Fetch the Y1 line coordinate from the heap and store
 STA XX15+1             \ it in XX15+1

 INY                    \ Increment the heap pointer

 LDA (XX19),Y           \ Fetch the X2 line coordinate from the heap and store
 STA XX15+2             \ it in XX15+2

 INY                    \ Increment the heap pointer

 LDA (XX19),Y           \ Fetch the Y2 line coordinate from the heap and store
 STA XX15+3             \ it in XX15+3

 JSR LL30               \ Draw a line from (X1, Y1) to (X2, Y2) to erase it from
                        \ the screen

 INY                    \ Increment the heap pointer

 JMP LL27               \ Loop back to LL27 to draw (i.e. erase) the next line
                        \ from the heap

.LLEX

 LDA XX14               \ Store XX14 in the first byte of the ship line heap
 LDY #0
 STA (XX19),Y

.LL82

 RTS                    \ Return from the subroutine

SAVE "ll155-plus4.bin", LL155, P%

ORG $7240

\ ******************************************************************************
\
\       Name: LLX30
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Draw a ship line using flicker-free animation
\
\ ******************************************************************************

.LLX30

 LDY XX14               \ Set Y = XX14, to get the offset within the ship line
                        \ heap where we want to insert our new line

 CPY XX14+1             \ Compare XX14 and XX14+1 and store the flags on the
 PHP                    \ stack so we can retrieve them later

 LDX #3                 \ We now want to copy the line coordinates (X1, Y1) and
                        \ (X2, Y2) to XX12...XX12+3, so set a counter to copy
                        \ 4 bytes

.LLXL

 LDA X1,X               \ Copy the X-th byte of X1/Y1/X2/Y2 to the X-th byte of
 STA XX12,X             \ XX12

 DEX                    \ Decrement the loop counter

 BPL LLXL               \ Loop back until we have copied all four bytes

 JSR LL30               \ Draw a line from (X1, Y1) to (X2, Y2)

 LDA (XX19),Y           \ Set X1 to the Y-th coordinate on the ship line heap,
 STA X1                 \ i.e. one we are replacing in the heap

 LDA XX12               \ Replace it with the X1 coordinate in XX12
 STA (XX19),Y

 INY                    \ Increment the index to point to the Y1 coordinate

 LDA (XX19),Y           \ Set Y1 to the Y-th coordinate on the ship line heap,
 STA Y1                 \ i.e. one we are replacing in the heap

 LDA XX12+1             \ Replace it with the Y1 coordinate in XX12+1
 STA (XX19),Y

 INY                    \ Increment the index to point to the X2 coordinate

 LDA (XX19),Y           \ Set X1 to the Y-th coordinate on the ship line heap,
 STA X2

 LDA XX12+2             \ Replace it with the X2 coordinate in XX12+2
 STA (XX19),Y

 INY                    \ Increment the index to point to the Y2 coordinate

 LDA (XX19),Y           \ Set Y2 to the Y-th coordinate on the ship line heap,
 STA Y2

 LDA XX12+3             \ Replace it with the Y2 coordinate in XX12+3
 STA (XX19),Y

 INY                    \ Increment the index to point to the next coordinate
 STY XX14               \ and store the updated index in XX14

 PLP                    \ Restore the result of the comparison above, so if the
 BCS LL82a              \ original value of XX14 >= XX14+1, then we have already
                        \ redrawn all the lines from the old ship's line heap,
                        \ so return from the subroutine (as LL82 contains an
                        \ RTS)

 JMP LL30               \ Otherwise there are still more lines to erase from the
                        \ old ship on-screen, so the coordinates in (X1, Y1) and
                        \ (X2, Y2) that we just pulled from the ship line heap
                        \ point to a line that is still on-screen, so call LL30
                        \ to draw this line and erase it from the screen,
                        \ returning from the subroutine using a tail call

.LL82a

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: LL9 (Part 1 of 12)
\       Type: Subroutine
\   Category: Drawing ships
\    Summary: Draw ship: Check if ship is exploding, check if ship is in front
\  Deep dive: Drawing ships
\
\ ******************************************************************************

.PATCH1

                        \ We replace the following two instructions in part 1 of
                        \ LL9 with JSR PATCH1, so we start with those two
                        \ instructions to ensure that they still get done

 LDA #31                \ Set XX4 = 31 to store the ship's distance for later
 STA XX4                \ comparison with the visibility distance. We will
                        \ update this value below with the actual ship's
                        \ distance if it turns out to be visible on-screen

                        \ We now set things up for flicker-free ship plotting,
                        \ by setting the following:
                        \
                        \   XX14 = offset to the first coordinate in the ship's
                        \          line heap
                        \
                        \   XX14+1 = the number of bytes in the heap for the
                        \            ship that's currently on-screen (or 0 if
                        \            there is no ship currently on-screen)

 LDY #1                 \ Set XX14 = 1, the offset of the first set of line
 STY XX14               \ coordinates in the ship line heap

 DEY                    \ Decrement Y to 0

 LDA #%00001000         \ If bit 3 of the ship's byte #31 is set, then the ship
 BIT INWK+31            \ is currently being drawn on-screen, so skip the
 BNE P%+5               \ following two instructions

 LDA #0                 \ The ship is not being drawn on screen, so set A = 0
                        \ so that XX14+1 gets set to 0 below (as there are no
                        \ existing coordinates on the ship line heap for this
                        \ ship)

 EQUB $2C               \ Skip the next instruction by turning it into
                        \ $2C $B1 $BD, or BIT $BDB1 which does nothing apart
                        \ from affect the flags

 LDA (XX19),Y           \ Set XX14+1 to the first byte of the ship's line heap,
 STA XX14+1             \ which contains the number of bytes in the heap

 RTS

\ ******************************************************************************
\
\       Name: LL9 (Part 10 of 12)
\       Type: Subroutine
\   Category: Drawing ships
\    Summary: Draw ship: Check if ship is exploding, check if ship is in front
\  Deep dive: Drawing ships
\
\ ******************************************************************************

.PATCH2

                        \ We replace the JMP LL78 instruction at the end of part
                        \ 10 of LL9 with JSR PATCH2, so this effectively inserts
                        \ the call to LLX30 at the end of part 10, as required

 JSR LLX30              \ Draw the laser line using flicker-free animation, by
                        \ first drawing the new laser line and then erasing the
                        \ corresponding old line from the screen

 JMP LL78               \ Jump down to part 11


SAVE "extra-plus4.bin", LLX30, P%

