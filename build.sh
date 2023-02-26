#!/usr/bin/env bash

# Set up program locations (change these if they are not aleady in the path)
beebasm="beebasm"
c1541="c1541"
python="python"

# Create an empty work folder
rm -fr work
mkdir work

# First, we build the NTSC version
cd work

# Extract the files from the original disk image
$c1541 -attach "../original-disks/elite[firebird_1986](ntsc)(v060186)(!).g64" \
       -extract

# Assemble the additional code required for flicker-free ships
$beebasm -i ../src/elite-flicker-free.asm -v > compile.txt

# Modify the main game code
$python ../src/elite-modify.py ntsc

# Rebuild the game disk
$c1541 \
    -format "no-flicker elite,1" \
            d64 \
            ../flicker-free-disks/c64-elite-flicker-free-ntsc.d64 \
    -attach ../flicker-free-disks/c64-elite-flicker-free-ntsc.d64 \
    -write firebird \
    -write gma1.modified gma1 \
    -write gma3 \
    -write gma4.encrypted gma4 \
    -write gma5.encrypted gma5 \
    -write gma6.encrypted gma6

# Report checksums
cd ..
$python src/crc32.py reference-binaries/ntsc work

# Next, we build the PAL version
cd work

# Extract the files from the original disk image
$c1541 -attach "../original-disks/elite[firebird_1986](pal)(v040486).g64" \
       -extract

# Assemble the additional code required for flicker-free ships
$beebasm -i ../src/elite-flicker-free.asm -v >> compile.txt

# Modify the main game code
$python ../src/elite-modify.py pal

# Rebuild the game disk
$c1541 \
    -format "no-flicker elite,1" \
            d64 \
            ../flicker-free-disks/c64-elite-flicker-free-pal.d64 \
    -attach ../flicker-free-disks/c64-elite-flicker-free-pal.d64 \
    -write firebird \
    -write byebyejulie \
    -write gma1.modified gma1 \
    -write gma3 \
    -write gma4.encrypted gma4 \
    -write gma5.encrypted gma5 \
    -write gma6.encrypted gma6

# Report checksums
cd ..
$python src/crc32.py reference-binaries/pal work

# And finally we modify the Plus/4 version
cd work

# Copy the decrypted PRG to the work folder
cp ../original-disks/elite_+4_unpacked.prg .

# Assemble the additional code required for flicker-free ships
$beebasm -i ../src/elite-flicker-free-plus4.asm -v >> compile.txt

# Modify the main game code
$python ../src/elite-modify-plus4.py

# Report checksums
cd ..
$python src/crc32.py reference-binaries/plus4 work
