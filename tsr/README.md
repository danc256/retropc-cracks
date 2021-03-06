# TSR Cracks

## TIE.ASM

### Tie Fighter

My most elaborate and probably only trainer. SoftIce was used to set a breakpoint on the port that read the status of the joystick buttons. Pressing the fire button stopped execution just as that value was being consumed, which was expected. From there it was a short distance to the data structure that held the firing cooldown timers. Of course any good programmer is going to keep related values together, so once one is found, the other  values of interest are adjacent.

Thanks to John M for the colors.

## BUDO.ASM

### Budokan

This took a while to figure out. My favorite tactic for doc checks was to type in a nonsense word, then search the data segment for that word, set a memory read breakpoint with SoftIce on the buffer with that word, and submit the check. From there trace it to the validation (usually just a string compare) and patch as needed. But this wasn't asking for a word, it was asking you to select an image. Whoops. This was considerably more tracing. Worth it. The game is awesome.

## CRACK4DB.ASM

### 4D-Boxing

Don't really remember much about this one. The comments say v1.22 but I don't see any prior versions. This is before I started using version control. The naming convention / strategy I used for backups and such is the stuff of nightmares. 

## ARKEY.ASM

### Airborne Ranger

Clearly naming consistency wasn't my strong suit. I think this is an older TSR that you run it first, it sits in memory then you run the game. It's before I figured out that it's better to run the original program directly so it can unload at the end of each execution. All this does is intercept a bunch of BIOS calls and return the values the protection is looking for.

## MODEMWAR.ASM

### Modem War

This was doc check protected but also had a checksum that notified the players if someone was using a modified binary. Hilariously if you patch out the protection with a sector editor the game still plays despite notifying your opponent that you're a cheater. Not even sure if the first version even worked but I remember an earlier version patched too early and tripped the checksum. In looking at the different versions it looks like I rewrote this one to be a wrapper instead of a TSR that remained loaded even after exiting the game. The last version shouldn't trip the checksum either as it patches after the check. I played this a lot.

## ATLANTIS.ASM

### Indiana Jones and the Fate of Atlantis

This took 10 minutes using the same approach for The Secret of Monkey Island.

## MONKEY1.ASM

### The Secret of Monkey Island

Oh man this was hard. I may have been a touch arrogant back then (big fish, small pond, maybe one other person in the area cracked games). This was a lesson in humility. I did my usual stepping and patching on the doc check and called it a day. But as I was playing the game I got stuck on a section that I know should have worked. Hmmmm. Sure enough, restart the game without the patch and pass the protection check legitimately and I got past that area. After more poking around is when I realized they created the copy protection in their interpreter. When I patched what I thought was a dedicated protection check I broke the interpreter, breaking the game. Stomach sinks. Pupils dialate. Do I have to reverse engineer their bytecode to crack this?

This was a marathon week where I spent close to 80 hours on this one title. So many failed attempts, and such a blatant disregard for personal hygiene. Inspiration struck on maybe the 5th day. If I passed the protection and restarted the game, it didn't re-run the doc check. So that means there must be a flag somewhere that is set once the protection check is passed.

The strategy I used was to get up to the protection screen, then save off the entire data segment using the debugger (all 64KB of it). Wait a few seconds, then do it again. Pass the protection check, then do it one more time. I wrote a throwaway program that looked for any bytes that remained consistent between captures 1 and 2, but changed in capture 3. This reduced the number of bytes I had to check to maybe 11 or so? Then it was just a matter of manually flipping each of those bytes after initialization but before the protection screen using a debugger. It only took maybe 3 tries before I found the right one. 

The same technique worked equally well on all the other SCUMM VM games I got my hands on at the time.

The "motivation" from QUARTZ mentioned in the splash screen was a nonstop tirade of beratement that was probably a violation of the 8th Amendment to the US Constitution. It was a public shaming that clawed deep into the psyche, tormented the ego and delighted in skilled manipulation of a fragile self-esteem. The General had met his Waterloo. All past accomplishments were for naught. Put down that keyboard crawl back in your hole. Then when I finally figured it out all I got was a "kewl" on a BBS post and life moved on. You're only as good as your last crack.

## MONKEY2.ASM

### The Secret of Monkey Island II

Again, 10 minutes once I figured out the first one.

## IMMORTAL.ASM

### The Immortal

Another game I loved. Great mood, great music, and it always hung in the same spot on my PC (even without the crack). I really should try this again someday. Would like to see the ending.

## ANTITANK.ASM

### M1 Tank Platoon

I have literally worn out my manual and game box I played this so much. This had a combination disk and doc check (see labels Patch_1 and Patch_2). There was also anti-debugger protection in that the program wiped out the values for INT 0x01 and INT 0x03 which were needed by the debugger. I wrote a helper program that copied the values of these locations, and on pressing a specific key it restored them. I ran the helper program first, let the protection clobber the debugger vectors, pressed a key to restore debugger vectors (might have been NumLock), then use the debugger to step through the protection and write up a patch.

## ANOTHER.ASM

### Another World

This isn't a crack but a fix for the keyboard beeping because the buffer was full. Maybe I was the only person who had this issue and it was specific to my PC at the time. If you play this game with a keyboard and the PC speaker isn't beeping after a few seconds, you don't need this.

## ATOMINO.ASM

### Atomino

Bypasses the doc check. Don't remember much else special about this one.

## AUTODUEL.ASM

### AutoDuel

Skips the disk check. Looks like there's some copypasta slop in there as it also patches INT 21h (DOS) but doesn't appears to actually do anything with that handler.

## BANDIT.ASM

### Time Bandit

Bypasses doc check. I don't even remember doing this one.

## BCEGA.ASM and GCVGA.ASM

### The Simpsons: Bart's House of Wierdness

Two patches, one for each executable. Ok apparently I wrote more than one trainer. Keys in the splash screen when patch is run.

## COM_HQ.ASM

### Command HQ

Two versions. First version takes any password. Second version has a tiny update that just skips the password screen entirely. There was actually a third version that just didn't display the patch splash screen but otherwise does nothing different. I played this a lot and I guess wanted as few keystrokes as possible between me and getting started.

## SAMPATCH.ASM

### Sword of the Samurai

Similar to M1 Tank Platoon. Two different handlers, one for the disk check and another for the doc check. My game manual wore out to the point where pages are falling out.

## EOBSPWAN.ASM

### Eye of the Beholder

Again, great naming convention. There were earlier versions of this patch that were of the type where it just stayed in memory even after the game exits. This one starts the game and exits when it does, hence the "spawn" suffix I guess.

## EXCEL.ASM

### Spirit of Excalibur

This is another one I readlly don't remember much about. I probably enjoyed the crack more than the game.

## FIRECHT.ASM

### Cheat for Firehawk

Simple trainer for Firehawk to replenish consumables.

## GENKEY.ASM

### Genghis Kahn

One of the older patches that stays in memory after the game exists. 

## GODSCHT.ASM

### Patch / Cheat for Gods

Two versions of this. The first one says it's a minor fix for certain hardware platforms (I had some flavor of an HP 386SX and there always seemed to be some flakiness about with with certain games). I have no idea what the patch did or why it was needed. The second version seems to bind some manner of cheat to the number '1' and '2' keys but there's no mention of what it does. Great job documenting this one past self.

## GOMANTIS.ASM

### Mantis: Experimental Fighter

Defeat the doc check.

## GUNSHIP1.ASM

### Gunship

Pretty sure this is incomplete as Gunship has THREE protection checks: A keydisk check, a doc check on startup AND a doc check on landing. You have to return to base after a successful mission to get the third check, and I wasn't the greatest pilot. The only other cracker in the area figured out the 3rd check and handed it to me, but I don't think I worked it into this patch. Also interesting is this patch seems to bypass the disk and first doc check in the same handler. Usually I broke them into two separate routines but again, whatever worked was good enough back then.

## HYPERSPD.ASM

### Hyperspeed

Don't remember much about it. Looks like it's only a doc check.

## INDY3.ASM

### Indiana Jones and the Last Crusade

Don't remember much about it.

## IRONCHT.ASM

### Ironman

Trainer. Two different versions in my archive, with the update making a tiny data tweak of unknown effect.

## KEEN.ASM

### Commander Keen (Episode 4?)

I'm surprised I put so little information in this. Since it runs KEEN4E.EXE I'm assuming episode 4.

## MICROBRK.ASM

### Helper program to defeat Microprose anti-debugger protection

This was a TSR not a loader. During initialization you can see it would preserve the original values of INT 0x00 - 0x03 in 'Vectors' then hook the disk interrupt (0x13) looking for certain conditions. When those conditions were met, the interrupt handler would restore the first four vector's original values, re-enabling the debugger. I thought it required a keypress to restore the data. I guess it just looks for certain conditions. Anyway, this is moot with DOSBOX's integrated debugger.

## NICKGOLF.ASM

### Jack Nicklaus Golf

No comments.

## NUKE.ASM

### Before there was DELTREE there was NUKE

A useful utility at the time. I remember either debugging some other DOS utilities or DOS itself to figure out that an 8.3 filename of all question marks gave good performance.

## NUTARG.ASM

### Targhan

I have no idea why this patch is as complicated as it is. Likely an artifact of where I hooked the routine. The doc check is in the middle of the game, making it extra complicated to debug.

## PROTO.ASM

### Crack for Protostar

One of the few collaborative efforts on a patch. Gunship may have been the only other one, but then again I thought I only wrote one trainer.

## RAMPARTV.ASM and RAMPARTE.ASM

### Rampart

Probably should have made the patch smart enough to figure out which version was run rather than make 2 entirely separate executables. Only difference between the two is a word offset and a little text in the splash screen.

## RSR.ASM

### Red Storm Rising

No comments.

## STARCON.ASM

### Star Control

I bought a copy of Star Control off eBay and the codewheel was a drag. Wanted to test the integrated debugger in DosBox-X so this is the first patch I did using more modern tooling.

## RUNGOLF.ASM

### Hole-in-One Golf

Odd in that it asks you to specify the name of the executable. Perhaps there were multiple executables depending on which video mode you wanted. Looks like it defeats a key disk check.

## STUNT.ASM

### Stunts

Originally released then updated 4 years later. This seems to be a theme that there are long gaps between updates. I'm pretty sure these patches never made it outside an isolated area so there wasn't exactly a large number of people testing them, nor much in the way of viable feedback if there was a problem. 

## TENTACLE.ASM

### Day of the Tentacle (Maniac Mansion II)

Another SCUMM-based game. No idea where the original non-working patch is. I probably just overwrote it with the update. The soup that is the directory I'm pulling all these patches from is the most hideous mess of inconsistency. It took 3 days sifting through backups of backups while running a de-duplicator program to get it distilled enough to even start looking at this.

## TERM.ASM

### Terminator 2029

Game developers spend an agonizing amount of time balancing a game for pain and pleasure just for someone to patch it where it's fun for maybe 10 minutes and then you never touch it again because beating it is trivial. Then there's oldschool RPGs like The Bard's Tale that even if you cheat it still has no problem murdering you in your sleep. I must have hated this game to write something like this. The Tie Fighter trainer was probably the best approach because it was adjustable. Unsurprisingly I loved that game and played it for hours.

## VGALEMMI.ASM and TGALEMMI.ASM

### Lemmings II: Oh No! More Lemmings...

Two patches for two binaries. Nice copypasta in TGALEMMI (comments reference The Immortal). Despite having a directory of 'clean' base shells I often just copied some other patch, manually scooped out the guts and started implementing the next one. While I did make some use of macros, the better way to structure this would have been to use two files to separate the base functionality from the program-specific functionality. Did not occur to me at the time.

## ULTIMA.ASM

### Ultima I and II

Originally this patch was for Utima II but I found out it worked unmodified on Ultima I as well. This is one of the first patches I ever wrote. Spartan, stays in memory after execution, but it worked so good enough to start.

## WOLF3D.ASM

### Castle Wolfenstein 3D v1.1

Splash screen says it only works for Wolfenstein v1.1. Another heavy-handed trainer that just let you go on a rampage. After having read the "Wolfenstein Black Book" and all the work that went into the game it seems criminal to patch a few bytes and throw the balance out the window.

## XEEN.ASM

### Might and Magic: Clouds of Xeen

This game was awesome. I hung onto the saved game archive for ages. Might still have it somewhere. Might and Magic is on a short list of games to revisit.
