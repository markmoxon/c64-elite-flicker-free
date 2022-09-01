# Flicker-free Elite on the Commodore 64

This repository contains a patch for Commodore 64 Elite that drastically improves the quality of the graphics. It does this by removing flicker from the ship-drawing routines.

You can clearly see the difference between the patched version on the left, and the original version on the right:

https://user-images.githubusercontent.com/2428251/187879166-74e973e3-aa49-40e3-b629-45d68843c4c9.mp4

To play the flicker-free version, see the section on [playing flicker-free Commodore 64 Elite](playing-flicker-free-commodore-64-elite]).

To read about how the patch weaves its magic, see the section on [how the patch works](#how-the-patch-works).

If you are interested in building and applying the patch yourself, see the section on [building the patch](#building-the-patch).

## Contents

* [Acknowledgements](#acknowledgements)

  * [A note on licences, copyright etc.](#user-content-a-note-on-licences-copyright-etc)

* [Playing flicker-free Commodore 64 Elite](playing-flicker-free-commodore-64-elite])

* [How the patch works](#how-the-patch-works)

  * [A better algorithm](a-better-algorithm)
  * [The patching process](the-patching-process)

* [Building the patch](#building-the-patch)

  * [Requirements](#requirements)
  * [Applying the patch](#applying-the-patch)

## Acknowledgements

Commodore 64 Elite was written by Ian Bell and David Braben and published by Firebird, and is copyright &copy; D. Braben and I. Bell 1985.

The game disks in this repository are similar to those released on [Ian Bell's personal website](http://www.elitehomepage.org/), but to ensure accuracy to the released versions, they're actually the versions from the [Commodore 64 Preservation Project on archive.org](https://archive.org/download/C64_Preservation_Project_10th_Anniversary_Collection) (as it turns out that the disk images on Ian Bell's site differ from the official versions).

The commentary is copyright &copy; Mark Moxon. Any misunderstandings or mistakes in the documentation are entirely my fault.

Huge thanks are due to the original authors for not only creating such an important piece of my childhood, but also for releasing the source code for us to play with. You can find more information about my Elite project in the [accompanying website's project page](https://www.bbcelite.com/about_site/about_this_project.html).

### A note on licences, copyright etc.

This repository is _not_ provided with a licence, and there is intentionally no `LICENSE` file provided.

According to [GitHub's licensing documentation](https://docs.github.com/en/free-pro-team@latest/github/creating-cloning-and-archiving-repositories/licensing-a-repository), this means that "the default copyright laws apply, meaning that you retain all rights to your source code and no one may reproduce, distribute, or create derivative works from your work".

The reason for this is that my patch is intertwined with the original Elite game code, and the original game code is copyright. The whole repository is therefore covered by default copyright law, to ensure that this copyright is respected.

Under GitHub's rules, you have the right to read and fork this repository... but that's it. No other use is permitted, I'm afraid.

My hope is that the educational and non-profit intentions of this repository will enable it to stay hosted and available, but the original copyright holders do have the right to ask for it to be taken down, in which case I will comply without hesitation. I do hope, though, that along with the various other disassemblies, commentaries and disk images of Elite, it will remain viable.

## Playing flicker-free Commodore 64 Elite

The flicker-free version of Commodore 64 Elite is available in two versions: NTSC and PAL. These are both based on the GMA86 release of Elite from 1986.

To play the patched game in an emulator or on a real machine, you can download disk images for both versions from the [flicker-free-disks](flicker-free-disks) folder. These have been tested in the VICE emulator, but should also work in other emulators and on real machines. If you don't know which one to use, try the PAL version first, as that seems to be the default for most emulators.

Loading commander files should work in exactly the same way as in the unpatched GMA86 version; the only changes in the patch are graphical, as you can see in this clip of Lave station (with the flicker-free version on the left, and the original version on the right):

https://user-images.githubusercontent.com/2428251/187880030-1ea634fa-5588-4724-941a-4229b63b59d6.mp4

## How the patch works

### A better algorithm

The 1986 releases of the BBC Master and Apple II versions of Elite saw a marked improvement in the ship-drawing algorithm that seriously reduced flicker without slowing down the game.

In the original versions of Elite, such as those for the BBC Micro, Acorn Electron and Commodore 64, ships were animated on-screen by first erasing them entirely, and then redrawing them in their new positions. The improved algorithm in the BBC Master and Apple II versions is similar, but instead of erasing the entire ship and then redrawing a whole new ship, it erases one line of the old ship and immediately redraws one line of the new ship, repeating the process until the whole ship gets redrawn, one line at a time. This interleaving of the line-drawing process results in much smoother ship graphics, and without adding any extra steps, so it doesn't affect the game speed.

Unfortunately planets are unaffected by the patch, as they use a completely different routine, so they still flicker. However ships, stations, asteroids and missiles are much improved.

For more information on the flicker-free algorithm, see these deep dives on [flicker-free ship drawing](https://www.bbcelite.com/deep_dives/flicker-free_ship_drawing.html) and [backporting the flicker-free algorithm](https://www.bbcelite.com/deep_dives/backporting_the_flicker-free_algorithm.html) in my BBC Micro Elite project.

### The patching process

In order to patch Elite to use the new algorithm, we have to do the following:

* Use c1451 to extract the game binaries from the original disk image

* Use BeebAsm to assemble the additional code that's required for flicker-free ships

* Use Python to inject this new code into the game binaries and adjust the code in a number of places, and to disable any copy protection in the original binaries

* Use c1451 to create a new disk image containing the flicker-free binaries

To find out more about the exact steps in this process, check out the following files, which contain lots of comments about how the process works.

* The [build.sh](build.sh) script controls the build. Read this for an overview of the patching process, which is described above.

* The [elite-flicker-free.asm](src/elite-flicker-free.asm) file assembles and saves out a number of code binaries. These contain larger blocks of code that implements the flicker-free algorithm, which are saved as binary files that are ready to be injected into the game binary to implement the patch.

* The [elite-modify.py](src/elite-modify.py) modifies the game binary. It does this by loading the binary into memory, patching it by injecting the output from BeebAsm, and making a number of modifications to the code before saving out the modified version. It also disables any copy protection so the resulting

## Building the patch

### Requirements

If you want to patch Commodore 64 Elite to the flicker-free version yourself, or you want to explore the patching process in more detail, then you will need the following:

* A Mac or Linux box. The process may work on the Windows Subsystem for Linux, but I haven't tested it.

* BeebAsm, which can be downloaded from the [BeebAsm repository](https://github.com/stardot/beebasm). You will have to build your own executable with `make code`.

* Python. Both versions 2.7 and 3.x should work.

* c1652 from the VICE emulator, which can be downloaded from the [VICE site](https://vice-emu.sourceforge.io).

Let's look at how to patch Commodore 64 Elite to get those flicker-free ships.

### Applying the patch

The patching process is implemented by a bash script called `build.sh` in the root folder of the repository. If any of BeebAsm, Python or c1541 are not on your path, then you can either fix this, or you can edit the `$beebasm`, `$python` or `$c1541` variables in the first three lines of `build.sh` to point to their locations.

You also need to change directory to the repository folder (i.e. the same folder as `build.sh`), and make the script executable.

All being well, doing the following:

```
cd /path/to/c64-elite-flicker-free
chmod a+x build.sh
./build.sh
```

will produce two disk images in the `compiled-game-disks` folder that contain the patched game, which you can then load into an emulator or real machine.

The build process also verifies the build against binaries that are known to be correct, and BeebAsm log files and interim binaries are saved in the `work` folder.

---

Right on, Commanders!

_Mark Moxon_
