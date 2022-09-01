# Flicker-free Elite on the Commodore 64

This repository contains a patch for Commodore 64 Elite that drastically improves the quality of the graphics. It does this by removing flicker from the ship-drawing routines.

You can clearly see the difference in the following clip. The patched version is on the left, and the original version is on the right:

https://user-images.githubusercontent.com/2428251/187879166-74e973e3-aa49-40e3-b629-45d68843c4c9.mp4

To play the flicker-free version, see the section on [playing flicker-free Commodore 64 Elite](#playing-flicker-free-commodore-64-elite).

To read about how the patch weaves its magic, see the section on [how the patch works](#how-the-patch-works).

If you are interested in building and applying the patch yourself, see the section on [building the patch](#building-the-patch).

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

The game disks in this repository are very similar to those released on [Ian Bell's personal website](http://www.elitehomepage.org/), but to ensure accuracy to the released versions, I've used disk images from the [Commodore 64 Preservation Project](https://archive.org/details/C64_Preservation_Project_10th_Anniversary_Collection) (it turns out that the disk images on Ian Bell's site differ slightly from the official versions).

The commentary is copyright &copy; Mark Moxon. Any misunderstandings or mistakes in the documentation are entirely my fault.

Huge thanks are due to the original authors for not only creating such an important piece of my childhood, but also for releasing the source code for us to play with. Also, a big thumbs up to Kroc Camen for his epic [Elite Harmless](https://github.com/Kroc/elite-harmless) project, which was a really useful reference when exploring the C64 binaries, and to the gurus in this [Lemon64 forum thread](https://www.lemon64.com/forum/viewtopic.php?t=67762&start=90) for their sage advice.

You can find more information about my own Elite project in the [fully documented source code for Elite on the BBC Micro](https://www.bbcelite.com).

### A note on licences, copyright etc.

This repository is _not_ provided with a licence, and there is intentionally no `LICENSE` file provided.

According to [GitHub's licensing documentation](https://docs.github.com/en/free-pro-team@latest/github/creating-cloning-and-archiving-repositories/licensing-a-repository), this means that "the default copyright laws apply, meaning that you retain all rights to your source code and no one may reproduce, distribute, or create derivative works from your work".

The reason for this is that my patch is intertwined with the original Elite game code, and the original game code is copyright. The whole repository is therefore covered by default copyright law, to ensure that this copyright is respected.

Under GitHub's rules, you have the right to read and fork this repository... but that's it. No other use is permitted, I'm afraid.

My hope is that the educational and non-profit intentions of this repository will enable it to stay hosted and available, but the original copyright holders do have the right to ask for it to be taken down, in which case I will comply without hesitation. I do hope, though, that along with the various other disassemblies, commentaries and disk images of Elite, it will remain viable.

## Playing flicker-free Commodore 64 Elite

The flicker-free version of Commodore 64 Elite is available in two versions: PAL and NTSC. These are both based on the GMA86 release of Elite from 1986.

To play the patched game in an emulator or on a real machine, you can download disk images for both versions from the [flicker-free-disks](flicker-free-disks) folder, or just click the following links:

* [Download flicker-free Commodore 64 Elite (PAL) as a .d64 disk image](https://github.com/markmoxon/c64-elite-flicker-free/raw/master/flicker-free-disks/c64-elite-flicker-free-pal.d64)

* [Download flicker-free Commodore 64 Elite (NTSC) as a .d64 disk image](https://github.com/markmoxon/c64-elite-flicker-free/raw/master/flicker-free-disks/c64-elite-flicker-free-ntsc.d64)

These have been tested in the VICE emulator and a number of online emulators, but they should also work on a real machine. If you don't know which one to use, try the PAL version first, as that seems to be the default setting for most emulators.

Saved commander files should work in exactly the same way as in the original GMA86 version; the only changes in the patch are graphical, and they don't affect gameplay in any way.

## How the patch works

### A better algorithm

The 1986 releases of the BBC Master and Apple II versions of Elite saw a marked improvement in the ship-drawing algorithm that seriously reduced flicker without slowing down the game.

In the original 1984 and 1985 versions of Elite, such as those for the BBC Micro, Acorn Electron and Commodore 64, ships were animated on-screen by first erasing them entirely, and then redrawing them in their new positions. The improved algorithm in the BBC Master and Apple II versions is similar, but instead of erasing the entire ship and then redrawing a whole new ship, it erases one line of the old ship and immediately redraws one line of the new ship, repeating the process until the whole ship gets redrawn, one line at a time. This interleaving of the line-drawing process results in much smoother ship graphics, and without adding any extra steps, so it doesn't affect the game speed.

Note that this doesn't apply to Elite on Z80-based computers, such as the ZX Spectrum and Amstrad CPC. These were complete rewrites that have totally different drawing routines, and they don't appear to suffer from flicker.

For more information on the flicker-free algorithm, see these deep dives on [flicker-free ship drawing](https://www.bbcelite.com/deep_dives/flicker-free_ship_drawing.html) and [backporting the flicker-free algorithm](https://www.bbcelite.com/deep_dives/backporting_the_flicker-free_algorithm.html) in my BBC Micro Elite project.

Unfortunately planets are unaffected by the patch, as they use a completely different routine, so they still flicker. However ships, stations, asteroids, missiles and cargo canisters are much improved, as you can see in this clip of Lave station. The patched version is on the left, and the original version is on the right:

https://user-images.githubusercontent.com/2428251/187880030-1ea634fa-5588-4724-941a-4229b63b59d6.mp4

### The patching process

In order to patch Commodore 64 Elite to use the new flicker-free algorithm, we have to do the following:

* Use c1451 to extract the game binaries from the original Commodore 64 .g64 disk images

* Use BeebAsm to assemble the additional code that's required for flicker-free ships (we use BeebAsm as the extra code is taken from the BBC Master version of Elite)

* Use Python to inject this new code into the game binaries and disable any copy protection on the original disk

* Use c1451 to create a new disk image containing the modified flicker-free binaries

To find out more about the above steps, check out the following files, which contain lots of comments about how the process works:

* The [build.sh](build.sh) script controls the build. Read this for an overview of the patching process, as described above.

* The [elite-flicker-free.asm](src/elite-flicker-free.asm) file assembles and saves out a number of code binaries. These contain larger blocks of code that implement the flicker-free algorithm, which are saved as binary files that are ready to be injected into the game binary to implement the patch.

* The [elite-modify.py](src/elite-modify.py) script modifies the game binary and applies the patch. It does this by loading the binary into memory, decrypting it, patching it by injecting the output from BeebAsm, making a number of other modifications to the code, encrypting the modified code, and saving out the encrypted and modified version. It also disables any copy protection on the original disk.

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

The patching process is implemented by a bash script called `build.sh` in the root folder of the repository. If any of BeebAsm, Python or c1541 are not on your path, then you can either fix this, or you can edit the `$beebasm`, `$python` or `$c1541` variables in the first three lines of `build.sh` to point to their locations.

You also need to change directory to the repository folder (i.e. the same folder as `build.sh`), and make sure the `build.sh` script is executable, with the following:

```
cd /path/to/c64-elite-flicker-free
chmod a+x build.sh
```

All being well, doing the following:

```
./build.sh
```

will produce two disk images in the `compiled-game-disks` folder. These disk images contain the patched game, one for PAL and one for NTSC, which you can then load into an emulator or real machine.

The build process also verifies the results against binaries that are known to be correct, and BeebAsm log files and interim binaries are saved in the `work` folder. These are useful for debugging purposes.

---

Right on, Commanders!

_Mark Moxon_
