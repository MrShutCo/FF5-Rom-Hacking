# FF5-Rom-Hacking
Repo for expirementing with FF5 SNES ROM hacking.

## bettershop
The goal of this hack is QoL improvements to armor and weapon shops. In particular, I would like to know when a piece of equipment is better or worse than what I currently have. A stretch goal is to have it display how much better it is.

![alt text](images/bettershop.png)

##### Checklist:
- [x] Can determine visually if a piece of weaponry is better or worse than currently equipped (slightly bugged)
- [x] Support for left and right hand weapons
- [] Support for left and right hand shields
- [x] Support for all equipment (mostly)
- [x] Better visuals for better/worse than a colored cursor
- [] Fix sprites
- [] (Stretch) Display the current and new armor/attack values in UI


## Building
For linux/Mac users, simply have FF5.sfc in a level above, or modify the assemble.sh script and run that. Requires asar assembler.
