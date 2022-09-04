# Flicker-free Elite on the Commodore 64

This repository contains a patch for Commodore 64 Elite that drastically improves the quality of the graphics. It does this by removing flicker from the ship-drawing routines.

* To play the flicker-free version, see the section on [playing flicker-free Commodore 64 Elite](#playing-flicker-free-commodore-64-elite).

* To read about how the patch weaves its magic, see the section on [how the patch works](#how-the-patch-works).

* If you are interested in building and applying the patch yourself, see the section on [building the patch](#building-the-patch).

The code in the patch has been backported from the BBC Master version of Elite, so it is 100% Bell & Braben code that's making its first appearance on the Commodore 64.

You can see the difference it makes in the following clip. The patched version is on the left, and the original version is on the right:

https://user-images.githubusercontent.com/2428251/187879166-74e973e3-aa49-40e3-b629-45d68843c4c9.mp4

## Contents

* [Acknowledgements](#acknowledgements)

  * [A note on licences, copyright etc.](#user-content-a-note-on-licences-copyright-etc)

* [Playing flicker-free Commodore 64 Elite](#playing-flicker-free-commodore-64-elite)

* [How the patch works](#how-the-patch-works)

  * [A better algorithm](#a-better-algorithm)
  * [The patching process](#the-patching-process)

* [Building the patch](#building-the-patch)

  * [Requirements](#requirements)
  * [Applying the patch](#applying-the-patch)

## Acknowledgements

Commodore 64 Elite was written by Ian Bell and David Braben and published by Firebird, and is copyright &copy; D. Braben and I. Bell 1985.

BBC Master Elite was written by Ian Bell and David Braben and is copyright © Acornsoft 1986.

The code in the flicker-free patch was reconstructed from a disassembly of the BBC Master version released on [Ian Bell's personal website](http://www.elitehomepage.org/).

The game disks in this repository are very similar to those released on [Ian Bell's personal website](http://www.elitehomepage.org/), but to ensure accuracy to the released versions, I've used disk images from the [Commodore 64 Preservation Project](https://archive.org/details/C64_Preservation_Project_10th_Anniversary_Collection) (it turns out that the disk images on Ian Bell's site differ slightly from the official versions).

The commentary is copyright &copy; Mark Moxon. Any misunderstandings or mistakes in the documentation are entirely my fault.

Huge thanks are due to the original authors for not only creating such an important piece of my childhood, but also for releasing the source code for us to play with. Also, a big thumbs up to Kroc Camen for his epic [Elite Harmless](https://github.com/Kroc/elite-harmless) project, which is a really useful reference for anyone exploring the C64 binaries. Finally, thanks to the gurus in this [Lemon64 forum thread](https://www.lemon64.com/forum/viewtopic.php?t=67762&start=90) for their sage advice.

You can find more information about my own Elite project in the [fully documented source code for Elite on the BBC Micro](https://www.bbcelite.com).

### A note on licences, copyright etc.

This repository is _not_ provided with a licence, and there is intentionally no `LICENSE` file provided.

According to [GitHub's licensing documentation](https://docs.github.com/en/free-pro-team@latest/github/creating-cloning-and-archiving-repositories/licensing-a-repository), this means that "the default copyright laws apply, meaning that you retain all rights to your source code and no one may reproduce, distribute, or create derivative works from your work".

The reason for this is that my patch is intertwined with the original Elite game code, and the original game code is copyright. The whole repository is therefore covered by default copyright law, to ensure that this copyright is respected.

Under GitHub's rules, you have the right to read and fork this repository... but that's it. No other use is permitted, I'm afraid.

My hope is that the educational and non-profit intentions of this repository will enable it to stay hosted and available, but the original copyright holders do have the right to ask for it to be taken down, in which case I will comply without hesitation. I do hope, though, that along with the various other disassemblies, commentaries and disk images of Elite, it will remain viable.

## Playing flicker-free Commodore 64 Elite

To play the flicker-free version of Commodore 64 Elite, you need to download a disk image and load it into an emulator or a real machine. Just like the original game, the flicker-free version is available in two distinct flavours: PAL and NTSC.

* [Download flicker-free Commodore 64 Elite (PAL) as a .d64 disk image](https://github.com/markmoxon/c64-elite-flicker-free/raw/master/flicker-free-disks/c64-elite-flicker-free-pal.d64) - this is the best version to use for emulators and most European machines

* [Download flicker-free Commodore 64 Elite (NTSC) as a .d64 disk image](https://github.com/markmoxon/c64-elite-flicker-free/raw/master/flicker-free-disks/c64-elite-flicker-free-ntsc.d64) - this is the best version to use for most machines from the Americas

[See here](http://unusedino.de/ec64/technical/misc/vic656x/pal-ntsc.html) for a brief technical summary on the differences between PAL and NTSC on the Commodore 64.

These images have been tested in the [VICE emulator](https://vice-emu.sourceforge.io) and in a number of online emulators, such as [C64 online](https://c64online.com/c64-online-emulator/) and [Virtual Consoles](https://virtualconsoles.com/online-emulators/c64/). They should also work on real machines. If you don't know which one to use, try the PAL version first, as that seems to be the default setting for most emulators. Both disk images are based on the GMA86 release of Elite from 1986.

Saved commander files should work in exactly the same way as in the original GMA86 version; the only changes in the patch are graphical, and they don't affect gameplay in any way.

## How the patch works

### A better algorithm

The 1986 releases of Elite on the BBC Master and Apple II show a marked improvement in the quality of the wireframe graphics when compared to earlier versions. This is down to an improved algorithm that seriously reduces flicker without slowing down the game.

In the original 1984 and 1985 versions of Elite, such as those for the BBC Micro, Acorn Electron and Commodore 64, ships are animated on-screen by first erasing them entirely, and then redrawing them in their new positions. The improved algorithm in the BBC Master and Apple II versions is similar, but instead of erasing the entire ship and then redrawing a whole new ship, it erases one line of the old ship and immediately redraws one line of the new ship, repeating this process until the whole ship gets redrawn, one line at a time. This interleaving of the line-drawing process results in much smoother ship graphics, and without adding any extra steps, so it doesn't affect the game speed.

Note that this doesn't apply to Elite on Z80-based computers, such as the ZX Spectrum and Amstrad CPC. These were complete rewrites that have totally different drawing routines, and they didn't inherit the flicker of the original 6502 versions.

For more information on the flicker-free algorithm, see these deep dives on [flicker-free ship drawing](https://www.bbcelite.com/deep_dives/flicker-free_ship_drawing.html) and [backporting the flicker-free algorithm](https://www.bbcelite.com/deep_dives/backporting_the_flicker-free_algorithm.html) in my BBC Micro Elite project.

Unfortunately planets are unaffected by the patch, as they use a completely different routine, so they still flicker. However ships, stations, asteroids, missiles and cargo canisters are much improved, as you can see in this clip of Lave station. The patched version is on the left, and the original version is on the right:

https://user-images.githubusercontent.com/2428251/187880030-1ea634fa-5588-4724-941a-4229b63b59d6.mp4

### The patching process

In order to patch Commodore 64 Elite to use the new flicker-free algorithm, we have to do the following:

* Extract the game binaries from the original Commodore 64 .g64 disk image (using c1541 from the VICE emulator)

* Assemble the additional code that's required for flicker-free ships (using BeebAsm as the extra code is taken from the BBC Master version of Elite)

* Inject this new code into the game binaries and disable any copy protection code (using Python)

* Create a new disk image containing the modified flicker-free binaries (using c1541 once again)

To find out more about the above steps, take a look at the following files, which contain lots of comments about how the process works:

* The [`build.sh`](build.sh) script controls the build. Read this for an overview of the patching process.

* The [`elite-flicker-free.asm`](src/elite-flicker-free.asm) file is assembled by BeebAsm and produces a number of binary files. These contain the bulk of the code that implements the flicker-free algorithm. These code blocks are saved as binary files that are ready to be injected into the game binary to implement the patch.

* The [`elite-modify.py`](src/elite-modify.py) script modifies the game binary and applies the patch. It does this by:

  * Loading the main binary into memory
  * Decrypting it
  * Patching it by injecting the output from BeebAsm and making a number of other modifications to the code
  * Encrypting the modified code
  * Saving out the encrypted and modified binary
  * Disabling any copy protection from the original disk

The commentary in these files is best read alongside the code changes, which are described in detail in the article on [backporting the flicker-free algorithm](https://www.bbcelite.com/deep_dives/backporting_the_flicker-free_algorithm.html).

## Building the patch

### Requirements

If you want to apply the flicker-free patch to Commodore 64 Elite yourself, or you just want to explore the patching process in more detail, then you will need the following:

* A Mac or Linux box. The process may work on the Windows Subsystem for Linux, but I haven't tested it.

* BeebAsm, which can be downloaded from the [BeebAsm repository](https://github.com/stardot/beebasm). You will have to build your own executable with `make code`.

* Python. Both versions 2.7 and 3.x should work.

* c1652 from the VICE emulator, which can be downloaded from the [VICE site](https://vice-emu.sourceforge.io).

Given these, let's look at how to patch Commodore 64 Elite to get those flicker-free ships.

### Applying the patch

The patching process is implemented by a bash script called [`build.sh`](build.sh) in the root folder of the repository. If any of BeebAsm, Python or c1541 are not on your path, then you can either fix this, or you can edit the `$beebasm`, `$python` or `$c1541` variables in the first three lines of `build.sh` to point to their locations.

You also need to change directory to the repository folder (i.e. the same folder as `build.sh`), and make sure the `build.sh` script is executable, with the following:

```
cd /path/to/c64-elite-flicker-free
chmod a+x build.sh
```

All being well, doing the following:

```
./build.sh
```

will produce two disk images in the [`flicker-free-disks`](flicker-free-disks) folder. These disk images contain the patched game, one for PAL and one for NTSC, which you can then load into an emulator or real machine.

The build process also verifies the results against binaries that are known to be correct, which helps with debugging. Any BeebAsm log files and interim binaries are saved in the `work` folder during compilation, which can be useful if you want to investigate the modified binary files from each of the build steps.

---

Right on, Commanders!

_Mark Moxon_
