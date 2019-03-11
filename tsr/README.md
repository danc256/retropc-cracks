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

