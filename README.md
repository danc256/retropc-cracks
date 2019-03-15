# Retro PC Cracks
These are some crusty old PC game cracks I did long ago. Preserved unmodified for historical purposes. Consider that many of the comments were in a mindset from decades ago as well.

## About the collection

This is a mix of TSR (Terminate and Stay Resident) cracks and sector edits. The easiest cracks were just patching out a few bytes and done. More sophisticated patches checked for certain conditions in memory then either modified code or data to defeat the protection. This was useful for bypassing checksums, self-modifying code, compressed binaries, and multi-factor protection. Microprose is a good example of using both disk and documentation checks (though they later published patches on their FTP site that removed the disk checks).

## Philosophy

The approach was more about defeating the protection than exhaustively reverse engineering the underlying copy protection mechanism. This is regrettable in many cases, but modern emulators not only make this feasible to revisit, in many cases they significantly simplify the process.

## Tools

Back then I largely used Borland's Turbo Debugger, later moving on to NuMega's Soft-Ice. I was unaware of the other decompilers and reverse engineering tools that were available at the time like Sourcerer. 

I wrote my first TSR as an experiment in reading "Undocumented DOS". Easily one of the best books I read back then. The entire TSR collection came as a result of reading that book.

## Coding style

Like the cracks, it was more about getting it to work than making it pretty or correct. While there are some good practices like comments and intuitive naming conventions, there are also many abominations. The worst is probably writing executable C code in a header file. I remember I called Borland support one day, and when I explained that I did that the exhasperated reply was memorable. Seemed like a good idea at the time. Also it worked.

## Compiling

I still have all my old tools imaged and backed up in multiple locations. I made a weak effort at getting some of these to compile using modern tools but figured that I'd rather put these up first then figure out how to make them more accessible later. That and I want the unmodified originals preserved as well. For now I'll compile them and push the binaries up under releases. The fact that some of my coding practices were not the best likely doesn't help. If you have any suggestions on modern tools that would make binaries out of these please let me know.

See the individual sub-folders for notes on compiling these using the original tools.