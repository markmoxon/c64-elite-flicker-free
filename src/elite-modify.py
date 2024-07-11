#!/usr/bin/env python
#
# ******************************************************************************
#
# COMMODORE 64 ELITE FLICKER-FREE MODIFICATION SCRIPT
#
# Written by Mark Moxon
#
# This script applies flicker-free ship-drawing to Commodore 64 Elite, as
# described here:
#
# https://elite.bbcelite.com/deep_dives/flicker-free_ship_drawing.html
#
# It does the following:
#
#   * Decrypt the gma6 file
#   * Modify the gma6 file to draw flicker-free ships and planets
#   * Encrypt the gma6 file
#
#   * Decrypt the gma5 file
#   * Modify the gma5 file to draw flicker-free planets
#   * Encrypt the gma5 file
#
#   * Decrypt the gma4 file
#   * Modify the gma4 file to draw flicker-free planets
#   * Encrypt the gma4 file
#
#   * Modify the gma1 file to remove disk protection
#
# Run this script by changing directory to the folder containing the disk files
# and running the script with "python elite-modify.py"
#
# This modification script works with the following disk images from the
# Commodore 64 Preservation Project:
#
#   * elite[firebird_1986](pal)(v040486).g64
#   * elite[firebird_1986](ntsc)(v060186)(!).g64
#
# You can find the Commodore 64 Preservation Project on archive.org here:
#
# https://archive.org/details/C64_Preservation_Project_10th_Anniversary_Collection
#
# ******************************************************************************

from __future__ import print_function
import os
import sys


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


# Fetch the platform (NTSC or PAL) from the command line arguments

if len(sys.argv) >= 2:
    platform = sys.argv[1]
else:
    platform = "pal"

# Print a progess message

print()
print("Modifying Commodore 64 Elite")
print("Platform: {}".format(platform.upper()))

# Configuration variables for gma6

load_address = 0x6A00 - 2
seed = 0x49
scramble_from = 0x6A00
scramble_to = 0x6A00 + 0x62D6

# Set up an array to hold the game binary, so we can modify it

data_block = bytearray()

# Load the main code file into data_block

elite_file = open("gma6", "rb")
data_block.extend(elite_file.read())
elite_file.close()

print()
print("[ Read    ] gma6")

# Decrypt the main code file

updated_seed = seed

for n in range(scramble_to, scramble_from - 1, -1):
    new = (data_block[n - load_address] - updated_seed) % 256
    data_block[n - load_address] = new
    updated_seed = new

print("[ Decrypt ] gma6")

# Write an output file containing the decrypted but unmodified game code, which
# we can use for debugging

output_file = open("gma6.decrypted", "wb")
output_file.write(data_block)
output_file.close()

print("[ Save    ] gma6.decrypted")

# Set the addresses for the extra routines (LLX30, PATCH1, PATCH2) that we will
# append to the end of the main game code (where there is a bit of free space)

llx30 = 0xCCE0
patch1 = 0xCD1E
patch2 = 0xCD35

# We now modify the code to implement flicker-free ship drawing. The code
# changes are described here, which can be read alongside the following:
#
# https://elite.bbcelite.com/deep_dives/backporting_the_flicker-free_algorithm.html
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

insert_binary_file(data_block, 0x9932, "shppt.bin")

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

insert_bytes(data_block, 0x9A8A, [
    0x20, patch1 % 256, patch1 // 256   # JSR PATCH1
])
insert_nops(data_block, 0x9A8D, 1)

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

insert_bytes(data_block, 0x9F2A, [
    0xA0, 0x09,                         # LDY #9
    0xB1, 0x57,                         # LDA (XX0),Y
    0x85, 0xAE                          # STA XX20
])
insert_nops(data_block, 0x9F30, 3)

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

insert_bytes(data_block, 0x9F39, [
    0xA0, 0x00,                         # LDY #0
    0x84, 0x9F                          # STY XX17
])
insert_nops(data_block, 0x9F3D, 10)

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

insert_bytes(data_block, 0x9F87, [
    0x20, llx30 % 256, llx30 // 256     # JSR LLX30
])
insert_nops(data_block, 0x9F8A, 21)

# LL9 (Part 10)
#
# This is the modification around LL75.
#
# From: STA T1
#       LDY XX17
#
# To:   STA CNT
#       LDY #0

insert_bytes(data_block, 0x9FB4, [
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

insert_nops(data_block, 0x9FC1, 1)

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

insert_bytes(data_block, 0x9FD9, [
    0xC8,                               # INY
    0xB1, 0x5B,                         # LDA (V),Y
    0xAA                                # TAX
])

lda_sta_block = get_offset(0x9FDD)
for n in range(lda_sta_block, lda_sta_block + 4 * 5):
    data_block[n] = data_block[n + 4]

insert_bytes(data_block, 0x9FF1, [
    0xC8,                               # INY
    0xB1, 0x5B,                         # LDA (V),Y
    0xAA                                # TAX
])
insert_nops(data_block, 0x9FF5, 2)

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

insert_bytes(data_block, 0xA010, [
    0x4C, patch2 % 256, patch2 // 256   # JMP PATCH2
])

# LL9 (Part 11)
#
# This is the modification at LL80.
#
# We blank out the .LL80 section with 28 NOPs

insert_nops(data_block, 0xA13F, 28)

# LL9 (Part 11)
#
# We have already assembled the modified part 11 in BeebAsm and saved it as
# the binary file ll78.bin, so now we drop this over the top of the existing
# routine (which is exactly the same size).

insert_binary_file(data_block, 0xA15B, "ll78.bin")

# LL9 (Part 12)
#
# We have already assembled the modified part 11 in BeebAsm and saved it as
# the binary file ll115.bin, so now we drop this over the top of the existing
# routine (which is slightly longer, so there is room).

insert_binary_file(data_block, 0xA178, "ll155.bin")

# We now append the three extra routines required by the modifications to the
# end of the main binary (where there is enough free space for them):
#
#   LLX30
#   PATCH1
#   PATCH2
#
# We have already assembled these in BeebAsm and saved them as the binary file
# extra.bin, so we simply append this file to the end.

elite_file = open("extra.bin", "rb")
data_block.extend(elite_file.read())
elite_file.close()

print("[ Modify  ] append file extra.bin")

# We now move on to the routines for drawing flicker-free planets

# Set the addresses for the extra routines (EraseRestOfPlanet, PATCH4, PATCH5)
# that we will insert into the sprite area (where there is a bit of free space)

erasep = 0xCD3B
patch4 = 0x69D0
patch5 = 0x69D5

# PL9 (Part 1 of 3)
#
# We have already assembled the modified part 1 of PL9 in BeebAsm and saved
# it as the binary file pl9.bin, so now we drop this over the top of the
# existing routine (the new routine is slightly bigger, so it ends by jumping
# to PATCH6, which contains the spill-over).

insert_binary_file(data_block, 0x7D8C, "pl9.bin")

# PL9 (Part 2 of 3)
#
# The above modification moves PL20, so we need to modify the branch instruction
# at the start of part 2 of PL9.

insert_bytes(data_block, 0x7DA8, [
    0x90, 0xEB                          # BCC PL20
])

# PL9 (Part 3 of 3)
#
# The above modification moves PL20, so we need to modify the branch instruction
# at the start of part 3 of PL9.

insert_bytes(data_block, 0x7DE2, [
    0x30, 0xB1                          # BMI PL20
])

# WPLS2
#
# We have already assembled the modified part 1 of PL9 in BeebAsm and saved
# it as the binary file pl9.bin, so now we drop this over the top of the
# existing routine (which is quite a bit longer, so there is room).

insert_binary_file(data_block, 0x80BB, "wpls2.bin")

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

insert_bytes(data_block, 0x7F04, [
    0xB0, 0x0A                          # BCS PL40
])
insert_bytes(data_block, 0x7F0D, [
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

insert_bytes(data_block, 0x805E, [
    0x20, patch5 % 256, patch5 // 256  # JSR PATCH5
])
insert_nops(data_block, 0x8061, 1)

# All the modifications are done, so write the output file for gma6.modified,
# which we can use for debugging

output_file = open("gma6.modified", "wb")
output_file.write(data_block)
output_file.close()

print("[ Save    ] gma6.modified")

# Encrypt the main code file

for n in range(scramble_from, scramble_to):
    data_block[n - load_address] = (data_block[n - load_address] + data_block[n + 1 - load_address]) % 256

data_block[scramble_to - load_address] = (data_block[scramble_to - load_address] + seed) % 256

print("[ Encrypt ] gma6.modified")

# Write the output file for gma6.encrypted, which contains our modified game
# binary with the flicker-free code

output_file = open("gma6.encrypted", "wb")
output_file.write(data_block)
output_file.close()

print("[ Save    ] gma6.encrypted")

# Configuration variables for gma5

load_address = 0x1D00 - 2
seed = 0x36
scramble_from = 0x1D00
scramble_to = 0x1D00 + 0x21D1

# Set up an array to hold the gma5 binary, so we can modify it

data_block = bytearray()

# Load the gma5 code file into data_block

elite_file = open("gma5", "rb")
data_block.extend(elite_file.read())
elite_file.close()

print()
print("[ Read    ] gma5")

# Decrypt the gma5 code file

updated_seed = seed

for n in range(scramble_to, scramble_from - 1, -1):
    new = (data_block[n - load_address] - updated_seed) % 256
    data_block[n - load_address] = new
    updated_seed = new

print("[ Decrypt ] gma5")

# Write an output file containing the decrypted but unmodified gma5 code, which
# we can use for debugging

output_file = open("gma5.decrypted", "wb")
output_file.write(data_block)
output_file.close()

print("[ Save    ] gma5.decrypted")

# BLINE
#
# We have already assembled the modified BLINE in BeebAsm and saved it as the
# binary file bline.bin, so now we drop this over the top of the existing
# routine (the new routine is slightly bigger, so it ends by jumping to PATCH3,
# which contains the spill-over).

insert_binary_file(data_block, 0x2977, "bline.bin")

# All the modifications are done, so write the output file for gma5.modified,
# which we can use for debugging

output_file = open("gma5.modified", "wb")
output_file.write(data_block)
output_file.close()

print("[ Save    ] gma5.modified")

# Encrypt the gma5 code file

for n in range(scramble_from, scramble_to):
    data_block[n - load_address] = (data_block[n - load_address] + data_block[n + 1 - load_address]) % 256

data_block[scramble_to - load_address] = (data_block[scramble_to - load_address] + seed) % 256

print("[ Encrypt ] gma5.modified")

# Write the output file for gma5.encrypted, which contains our modified game
# binary with the flicker-free code

output_file = open("gma5.encrypted", "wb")
output_file.write(data_block)
output_file.close()

print("[ Save    ] gma5.encrypted")

# Configuration variables for gma4

load_address = 0x4000 - 2
seed = 0x8E
scramble_from = 0x75E4
scramble_to = 0x4000 + 0x465A

# Set up an array to hold the gma4 binary, so we can modify it

data_block = bytearray()

# Load the gma4 code file into data_block

elite_file = open("gma4", "rb")
data_block.extend(elite_file.read())
elite_file.close()

print()
print("[ Read    ] gma4")

# Decrypt the gma4 code file

updated_seed = seed

for n in range(scramble_to, scramble_from - 1, -1):
    new = (data_block[n - load_address] - updated_seed) % 256
    data_block[n - load_address] = new
    updated_seed = new

print("[ Decrypt ] gma4")

# Write an output file containing the decrypted but unmodified gma4 code, which
# we can use for debugging

output_file = open("gma4.decrypted", "wb")
output_file.write(data_block)
output_file.close()

print("[ Save    ] gma4.decrypted")

# We now insert the four extra routines required by the modifications into
# the unused space just after the sprites:
#
#   PATCH3
#   PATCH4
#   PATCH5
#   PATCH6
#
# We have already assembled these in BeebAsm and saved them as the binary file
# extra2.bin, so we simply insert this file at the correct address. The contents
# of the GMA4 file is moved after decryption, so although the routines end up at
# $69C0, they actually get loaded and decrypted at $7C3A, so that's the address
# we use when inserting the code into the gm4 file:

insert_binary_file(data_block, 0x7C3A, "extra2.bin")

# All the modifications are done, so write the output file for gma4.modified,
# which we can use for debugging

output_file = open("gma4.modified", "wb")
output_file.write(data_block)
output_file.close()

print("[ Save    ] gma4.modified")

# Encrypt the gma4 code file

for n in range(scramble_from, scramble_to):
    data_block[n - load_address] = (data_block[n - load_address] + data_block[n + 1 - load_address]) % 256

data_block[scramble_to - load_address] = (data_block[scramble_to - load_address] + seed) % 256

print("[ Encrypt ] gma4.modified")

# Write the output file for gma4.encrypted, which contains our modified game
# binary with the flicker-free code

output_file = open("gma4.encrypted", "wb")
output_file.write(data_block)
output_file.close()

print("[ Save    ] gma4.encrypted")

# Finally, we need to remove the disk protection from gma1, as described here:
# https://www.lemon64.com/forum/viewtopic.php?t=67762&start=90

data_block = bytearray()

elite_file = open("gma1", "rb")
data_block.extend(elite_file.read())
elite_file.close()

print()
print("[ Read    ] gma1")

if platform == "pal":
    # For elite[firebird_1986](pal)(v040486).g64
    data_block[0x25] = 0xEA
    data_block[0x26] = 0xEA
    data_block[0x27] = 0xEA
    data_block[0x2C] = 0xD0
else:
    # For elite[firebird_1986](ntsc)(v060186)(!).g64
    data_block[0x14] = 0xEA
    data_block[0x16] = 0xEA
    data_block[0x15] = 0xEA

print("[ Modify  ] gma1")

output_file = open("gma1.modified", "wb")
output_file.write(data_block)
output_file.close()

print("[ Save    ] gma1.modified")
print()
