# TSR Cracks

## TIE.ASM

My most elaborate and probably only trainer. SoftIce was used to set a breakpoint on the port that read the status of the joystick buttons. Pressing the fire button stopped execution just as that value was being consumed, which was expected. From there it was a short distance to the data structure that held the firing cooldown timers. Of course any good programmer is going to keep related values together, so once one is found, the other  values of interest are adjacent.

Thanks to John M for the colors.



