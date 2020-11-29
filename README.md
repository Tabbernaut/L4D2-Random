# L4D2-Random

L4D2 Random config stuff.


## Plugin code

Plugins for making Random config possible.

Yes, I know a lot of this code is ugly. Random started out as a bit of a joke, then slowly grew out to a fairly serious config.  If I have time to spare, I might try and clean this up, but for now it will have to do.

Anyway, this plugin has a single purpose: it is the engine that powers the Random config. It is not designed to be used in other contexts, hence its functions being clumped together and intertwined as they are.

The parts that do serve more general purposes and may well be of use for other projects/configs are separate and found in my L4D2 Plugins repository:
- Saferoom Detect (to detect whether players, entities or coordinates are inside the bounds of a saferoom)
- Penalty Bonus (a non-survival bonus system that uses the defib. penalty)
- Skill Detect (a tracking/detection plugin that is used to detect skeets, crowns, etc)
- Holdout Bonus (a plugin that gives survivors bonus for (partially) surviving camping events)

## Commands

The following commands are available (e.g.: `sm_info` in console, or `!info` in chat).

```
sm_info                 shows general help information about Random
sm_random               alias for sm_info
sm_rand                 shows information about this round
sm_rnd                  alias for sm_rand
sm_bonus                shows the current round bonus
sm_penalty              shows the current round (penalty) bonus
sm_drop                 drops what you're currently holding
sm_eventinfo (<num>)    shows information about a specific special event (or the current one by default)
sm_event <num>          starts a vote for a special event for next round,
sm_gameevent <num>      starts a vote for a special event for all rounds
sm_rerandom             (for coop) rerandomizes the next round, should the survivors fail

forceevent <num>        forces a specific special event for the next round
forcegameevent <num>    forces a specific special events for all following rounds
```

### Debugging

If debug mode is enabled (`rand_debug=1`), the following commands are available aswell:

```
rand_test_gnomes    tests spawning gnomes
rand_test_swap      tests a weapon swap
rand_test_ents      tests entity randomization
rand_test_event     tests special events
```


## Random Coop mutation

If you don't want to play VS, you can still play random. The Random Coop mutation is pretty freaky and intense, spawning many SI. It's very hard to play with bots, so 4 humans works best.

To play Random Coop, start the `randomcoop` match mode.

Warning: Random Coop is *hard*. If you beat a campaign in this on Expert, you've got my respect. To keep it fun, I recommend playing on normal difficulty mode.
For an easier game (recommended if you're playing with a few bots), you can use the match mode `randomcoopeasy`.
You can further tweak the difficulty by using the `!rndmut_diff` command described below.

### Chat commands:

To cycle through the difficulty, enter the following in chat:

```
!rndmut_diff
```

It cycles through difficulty modes: 'very hard', 'hard', 'medium' and 'easy'.
The default difficulty is 'hard'.
The main thing that changes is the time between attacks; you get a bit more time to catch your breath in easier difficulty settings.


You can toggle whether some debug output is shown with:

```
!randmut_debug
```
