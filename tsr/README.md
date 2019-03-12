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
