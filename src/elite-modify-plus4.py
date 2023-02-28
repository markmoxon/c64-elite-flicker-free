#!/usr/bin/env python
#
# ******************************************************************************
#
# COMMODORE PLUS/4 ELITE FLICKER-FREE MODIFICATION SCRIPT
#
# Written by Mark Moxon
#
# This script applies flicker-free ship-drawing to Commodore Plus/4 Elite, as
# described here:
#
# https://www.bbcelite.com/deep_dives/flicker-free_ship_drawing.html
#
# It does the following:
#
#   * Modify the PRG file to draw flicker-free ships
#
# Run this script by changing directory to the folder containing the disk files
# and running the script with "python elite-modify.py"
#
# This modification script works with the following disk image, which is the
# Pigmy Plus/4 version from Ian Bell's site, with the demo and packing removed:
#
#   * elite_+4_unpacked.prg
#
# ******************************************************************************

from __future__ import print_function
import os


# Convert a C64 address into the corresponding offset within the gma6 file

def get_offset(addr):
    return addr - load_address


# Insert a binary file into the game code, overwriting what's there

def insert_binary_file(data_block, addr, filename):
    file = open(filename, "rb")
    file_size = os.path.getsize(filename)
    insert_from = get_offset(addr)
    insert_to = insert_from + file_size
    data_block[insert_from:insert_to] = file.read()
    file.close()
    print("[ Modify  ] insert file {} at 0x{:02X}".format(filename, addr))


# Insert an array of bytes into the game code, overwriting what's there

def insert_bytes(data_block, addr, insert):
    insert_from = get_offset(addr)
    insert_to = insert_from + len(insert)
    data_block[insert_from:insert_to] = insert
    print("[ Modify  ] insert {} bytes at 0x{:02X}".format(len(insert), addr))


# Insert a block of NOPs into the game code, overwriting what's there

def insert_nops(data_block, addr, count):
    insert = [0xEA] * count
    insert_bytes(data_block, addr, insert)
    print("[ Modify  ] insert {} NOPs at 0x{:02X}".format(count, addr))


# Print a progess message

print()
print("Modifying Commodore Plus/4 Elite")

# Configuration variables

load_address = 0x1100 - 2

# Set up an array to hold the game binary, so we can modify it

data_block = bytearray()

# Load the main code file into data_block

elite_file = open("elite_+4_unpacked.prg", "rb")
data_block.extend(elite_file.read())
elite_file.close()

print()
print("[ Read    ] elite_+4_unpacked.prg")

# Set the addresses for the extra routines (LLX30, PATCH1, PATCH2) that we will
# load into unused portiong of the main game code

llx30 = 0x7200
patch1 = 0x723E
patch2 = 0x7255

# We now modify the code to implement flicker-free ship drawing. The code
# changes are described here, which can be read alongside the following:
#
# https://www.bbcelite.com/deep_dives/backporting_the_flicker-free_algorithm.html
#
# The addresses in the following are from when the game binary is loaded into
# memory. They were calculated by analysing a memory dump of the running game,
# searching for patterns in the bytes to match them with the corrsponding code
# from the BBC Micro version (which is very similar, if you ignore any different
# addresses).

# SHPPT
#
# We start with the new version of SHPPT, which we have already assembled in
# BeebAsm and saved as the binary file shppt.bin, so we simply drop this over
# the top of the existing routine (which is slightly longer, so there is room).

insert_binary_file(data_block, 0x9932 + 0x900, "shppt-plus4.bin")

# LL9 (Part 1)
#
# This is the modification just after LL9. We insert the extra code with a call
# to the new PATCH1 routine, which implements the original instructions before
# moving on to the new code.
#
# From: LDA #31
#       STA XX4
#
# To:   JSR PATCH1
#       NOP

insert_bytes(data_block, 0x9A8A + 0x900, [
    0x20, patch1 % 256, patch1 // 256   # JSR PATCH1
])
insert_nops(data_block, 0x9A8D + 0x900, 1)

# LL9 (Part 9)
#
# This is the modification at EE31.
#
# From: LDA #%00001000
#       BIT XX1+31
#       BEQ LL74
#       JSR LL155
#
# To:   LDY #9
#       LDA (XX0),Y
#       STA XX20
#       NOP
#       NOP
#       NOP

insert_bytes(data_block, 0x9F2A + 0x900, [
    0xA0, 0x09,                         # LDY #9
    0xB1, 0x57,                         # LDA (XX0),Y
    0x85, 0xAE                          # STA XX20
])
insert_nops(data_block, 0x9F30 + 0x900, 3)

# LL9 (Part 9)
#
# This is the modification just after LL74.
#
# From: LDY #9
#       LDA (XX0),Y
#       STA XX20
#       LDY #0
#       STY U
#       STY XX17
#       INC U
#
# To:   LDY #0
#       STY XX17
#       NOP x10

insert_bytes(data_block, 0x9F39 + 0x900, [
    0xA0, 0x00,                         # LDY #0
    0x84, 0x9F                          # STY XX17
])
insert_nops(data_block, 0x9F3D + 0x900, 10)

# LL9 (Part 9)
#
# This is the modification at the end of the routine.
#
# From: LDA XX15
#       STA (XX19),Y
#       INY
#       LDA XX15+1
#       STA (XX19),Y
#       INY
#       LDA XX15+2
#       STA (XX19),Y
#       INY
#       LDA XX15+3
#       STA (XX19),Y
#       INY
#       STY U
#
# To:   JSR LLX30
#       NOP x21

insert_bytes(data_block, 0x9F87 + 0x900, [
    0x20, llx30 % 256, llx30 // 256     # JSR LLX30
])
insert_nops(data_block, 0x9F8A + 0x900, 21)

# LL9 (Part 10)
#
# This is the modification around LL75.
#
# From: STA T1
#       LDY XX17
#
# To:   STA CNT
#       LDY #0

insert_bytes(data_block, 0x9FB4 + 0x900, [
    0x85, 0x30,                         # STA CNT
    0xA0, 0x00                          # LDY #0
])

# LL9 (Part 10)
#
# This is the second INY after LL75.
#
# From: INY
#
# To:   NOP

insert_nops(data_block, 0x9FC1 + 0x900, 1)

# LL9 (Part 10)
#
# These are the two modifications at LL79.
#
# From: LDA (V),Y
#       TAX
#       INY
#       LDA (V),Y
#       STA Q
#       ... four lots of unchanged LDA/STA, 5 bytes each ...
#       LDX Q
#
# To:   INY
#       LDA (V),Y
#       TAX
#       ... shuffle the LDA/STA block down by 4 bytes ...
#       INY
#       LDA (V),Y
#       TAX
#       NOP
#       NOP

insert_bytes(data_block, 0x9FD9 + 0x900, [
    0xC8,                                   # INY
    0xB1, 0x5B,                             # LDA (V),Y
    0xAA                                    # TAX
])

lda_sta_block = get_offset(0x9FDD + 0x900)
for n in range(lda_sta_block, lda_sta_block + 4 * 5):
    data_block[n] = data_block[n + 4]

insert_bytes(data_block, 0x9FF1 + 0x900, [
    0xC8,                                   # INY
    0xB1, 0x5B,                             # LDA (V),Y
    0xAA                                    # TAX
])
insert_nops(data_block, 0x9FF5 + 0x900, 2)

# LL9 (Part 10)
#
# This is the modification at the end of the routine. The C64 version has an
# extra JMP LL80 instruction at this point that we can modify to jump to a
# new routine PATCH2, which lets us insert the extra JSR LLX30 without taking
# up any more bytes.
#
# From: JMP LL80
#
# To:   JMP PATCH2

insert_bytes(data_block, 0xA010 + 0x900, [
    0x4C, patch2 % 256, patch2 // 256       # JMP PATCH2
])

# LL9 (Part 11)
#
# This is the modification at LL80.
#
# We blank out the .LL80 section with 28 NOPs

insert_nops(data_block, 0xA13F + 0x900, 28)

# LL9 (Part 11)
#
# We have already assembled the modified part 11 in BeebAsm and saved it as
# the binary file ll78.bin, so now we drop this over the top of the existing
# routine (which is exactly the same size).

insert_binary_file(data_block, 0xA15B + 0x900, "ll78-plus4.bin")

# LL9 (Part 12)
#
# We have already assembled the modified part 11 in BeebAsm and saved it as
# the binary file ll115.bin, so now we drop this over the top of the existing
# routine (which is slightly longer, so there is room).

insert_binary_file(data_block, 0xA178 + 0x900, "ll155-plus4.bin")

# We now load the three extra routines required by the modifications into the
# memory used by the explosion and Trumble sprites, which are not used in the
# Plus/4 version:
#
#   LLX30
#   PATCH1
#   PATCH2
#   DrawPlanetLine

insert_binary_file(data_block, 0x7200, "extra-plus4.bin")

# We now move on to the routines for drawing flicker-free planets

# Set the addresses for the extra routines (EraseRestOfPlanet, PATCH4, PATCH5)
# that we inserted above

erasep = 0x89BC
patch4 = 0x1EA0
patch5 = 0x1EA5

# PL9 (Part 1 of 3)
#
# We have already assembled the modified part 1 of PL9 in BeebAsm and saved
# it as the binary file pl9.bin, so now we drop this over the top of the
# existing routine (the new routine is slightly bigger, so it ends by jumping
# to PATCH6, which contains the spill-over).

insert_binary_file(data_block, 0x7D8C + 0x8F0, "pl9-plus4.bin")

# PL9 (Part 2 of 3)
#
# The above modification moves PL20, so we need to modify the branch instruction
# at the start of part 2 of PL9.

insert_bytes(data_block, 0x7DA8 + 0x8F0, [
    0x90, 0xEB                          # BCC PL20
])

# PL9 (Part 3 of 3)
#
# The above modification moves PL20, so we need to modify the branch instruction
# at the start of part 3 of PL9.

insert_bytes(data_block, 0x7DE2 + 0x8F0, [
    0x30, 0xB1                          # BMI PL20
])

# WPLS2
#
# We have already assembled the modified WPLS2 in BeebAsm and saved it as
# the binary file wpls2.bin, so now we drop this over the top of the
# existing routine. This binary contains the following routines:
#
#   WPLS2
#   EraseRestOfPlanet
#   PATCH3
#   PATCH6

insert_binary_file(data_block, 0x80BB + 0x8F0, "wpls2-plus4.bin")

# PLS22
#
# This is the modification on either side of PL40, with the label moving two
# bytes backwards to accommodate the modified code.
#
# From: BCS PL40
#       ...
#       STA CNT2
#       JMP PLL4
#      .PL40
#       RTS
#
# To:   BCS PL40
#       ...
#       JMP PATCH4
#      .PL40
#       JMP EraseRestOfPlanet

insert_bytes(data_block, 0x7F04 + 0x8F0, [
    0xB0, 0x0A                          # BCS PL40
])
insert_bytes(data_block, 0x7F0D + 0x8F0, [
    0x4C, patch4 % 256, patch4 // 256,  # JMP PATCH4
    0x4C, erasep % 256, erasep // 256   # JMP EraseRestOfPlanet
])

# CIRCLE2
#
# This is the modification at the start of the routine.
#
# From: LDX #&FF
#       STX FLAG
#
# To:   JSR PATCH5
#       NOP

insert_bytes(data_block, 0x805E + 0x8F0, [
    0x20, patch5 % 256, patch5 // 256   # JSR PATCH5
])
insert_nops(data_block, 0x8061 + 0x8F0, 1)

# BLINE
#
# We have already assembled the modified BLINE in BeebAsm and saved it as the
# binary file bline.bin, so now we drop this over the top of the existing
# routine (the new routine is slightly bigger, so it ends by jumping to PATCH3,
# which contains the spill-over).

insert_binary_file(data_block, 0x2974, "bline-plus4.bin")

# We now load the extra routines required by the modifications into the memory
# used by the Trumble sprite-drawing routine, which contains a whole raft of
# NOPs in the Plus/4 version. We can therefore slip the following routines into
# this set of NOPs, adding a JMP beforehand to skip over the patches:
#
#   DrawNewPlanetLine
#   PATCH4
#   PATCH5

insert_binary_file(data_block, 0x1E6A, "trumble-plus4.bin")

# All the modifications are done, so write the output file for the modified PRG

output_file = open("elite_+4_modified.prg", "wb")
output_file.write(data_block)
output_file.close()

print("[ Save    ] elite_+4_modified.prg")
