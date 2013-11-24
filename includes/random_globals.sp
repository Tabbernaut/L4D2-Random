#pragma semicolon 1

// Support
new     bool:           g_bLateLoad                                         = false;
new     Handle:         g_hTrieRandomizableEntity                           = INVALID_HANDLE;       // trie for recognizing classnames of entities to replace
new     Handle:         g_hTrieRandomizablePropPhysicsModel                 = INVALID_HANDLE;       // trie for recognizing models of prop_physics to replace
new     Handle:         g_hTrieEntityCreated                                = INVALID_HANDLE;       // trie for recognizing classnames of entities to handle
new     Handle:         g_hTrieMeleeType                                    = INVALID_HANDLE;       // trie for recognizing which melees are 'normal'
new     Handle:         g_hTriePenaltyItems                                 = INVALID_HANDLE;       // trie for recognizing items that carry a penalty on EVT_PEN_ITME
new     Handle:         g_hTriePropItems                                    = INVALID_HANDLE;       // trie for recognizing prop items that can be carried (for EVT_ENCUMBERED)
new     Handle:         g_hTrieUseItems                                     = INVALID_HANDLE;       // trie for recognizing usable items
new     Handle:         g_hTrieDropItems                                    = INVALID_HANDLE;       // trie for recognizing dropped items/weapons
new     Handle:         g_hTrieL4D1Common                                   = INVALID_HANDLE;       // trie for recognizing l4d1 commons
new     Handle:         g_hTrieEventWeapons                                 = INVALID_HANDLE;       // trie for recognizing weapons from eventinfo
new     Handle:         g_hTrieTankPlayers                                  = INVALID_HANDLE;       // trie for checking how many times player got tank

new                     g_iMeleeClassCount                                  = 0;                    // melee weapons available?
new     String:         g_sMeleeClass           [MELEE_CLASS_COUNT][MELEE_CLASS_LENGTH];            // available melee class-strings
new     Handle:         g_hSteamIds                                         = INVALID_HANDLE;       // store players so we know who's already been welcomed
new     bool:           g_bReadyUpAvailable                                 = false;                // whether crox's readyup plugin is used
new     bool:           g_bPauseAvailable                                   = false;                // crox's pause
new     bool:           g_bCMTActive                                        = false;                // whether custom map transitions is active (and running a mapset)
new     String:         g_sNextMap              [STR_MAX_MAPNAME];                                  // what the upcoming map is (if any)
new     bool:           g_bHoldoutActive                                    = false;                // whether holdout_bonus is doing its magic this map

new     bool:           g_bDefaultCvarsLoaded                               = false;                // if not loaded, check if they can be loaded and load them
new     bool:           g_bVeryFirstMapLoad                                 = true;                 // for preventing a first-map problem with item randomization
new     bool:           g_bRestartedOnce                                    = false;                // true once the first real map load is going
new     bool:           g_bCampaignMode                                     = false;                // are we playing a coop game?
new                     g_bSecondHalf                                       = false;                // is this the second round-half?
new     bool:           g_bMapStartDone                                     = false;                // has OnMapStart been executed? (to avoid double roundprep calls)
new     bool:           g_bFirstMapDone                                     = false;                // set to true after the first round has been played
new     bool:           g_bRoundIsLive                                      = false;                // only true if readyup is loaded and round went live
new     bool:           g_bInRound                                          = false;                // are we in a live round?
new     bool:           g_bIsFirstAttack                                    = false;                // is this / will this be the first attack of the round(half)?
new     bool:           g_bItemsFullyRandomized                             = false;                // if this is true, all the items are in place and ready to be picked up
new     bool:           g_bBotsAllowedPickup                                = false;                // bots can't start picking stuff up instantly
new     bool:           g_bModelsPrecached                                  = false;                // only true if models precached
new     bool:           g_bFirstReportDone                                  = false;                // true once the first team has had its report for the round (triggered)
new     bool:           g_bPlayersLeftStart                                 = false;                // true once the first survivor has left the start saferoom
new     bool:           g_bSoundHooked                                      = false;                // true when there's a soundhook in place
new                     g_iSpecialEventToForce                              = -1;                   // if this is anything but -1, forces special event for one round(half) -- debug function
new                     g_iSpecialEventToForceAlways                        = -1;                   // same but forever
new     bool:           g_bT2Nerfed                                         = true;                 // true when you can't have > single pistol while holding t2
new     bool:           g_bSurvivorsLoadedIn                                = false;                // to check for calling EVENT_AllSurvivorsLoadedIn()

new     bool:           g_bFreezeDistanceOnTank                             = false;                // if true, freezes distance during tanks
new     bool:           g_bReportFreezing                                   = true;                 // if true, reports when freezing
new     bool:           g_bFrozenPoints                                     = false;                // true if distance points are frozen (for tank)
new                     g_iRememberFrozenDistance                           = 0;                    // distance before freezing distance points

new                     g_iCampaignFailStreak                               = 0;                    // how many times in a row the mission was lost
new     bool:           g_bCampaignForceRandom                              = false;                // force rerandomization
new     bool:           g_bCampaignReRandomPlease                           = false;                // players want to rerandom on next failure

new     bool:           g_bPlayerIncapNoSecondary[MAX_CHARACTERS];                                  // if player (per character) had a secondary before they were incapped

// Menu handling
new                     g_iEventMenu            [MAXPLAYERS+1]              = {0,...};              // what menu to use

// Pause tracking
new     bool:           g_bIsPaused                                         = false;                // whether game is paused
new     Float:          g_fPauseAttemptTime                                 = 0.0;                  // when the !pause command was issued
new     Float:          g_fPauseStartTime                                   = 0.0;                  // when the pause started

// Event forcing handling
new     bool:           g_bTeamSurvivorVotedEvent                           = false;                // whether anyone in survivor team used !teamshuffle or !randteams
new     bool:           g_bTeamInfectedVotedEvent                           = false;
new                     g_iPickEvent                                        = -1;                   // what even we're picking
new     Float:          g_fPickEventTimeout                                 = 0.0;                  // when we can vote again
new     bool:           g_bTeamSurvivorVotedGameEvent                       = false;                // whether anyone in survivor team used !teamshuffle or !randteams
new     bool:           g_bTeamInfectedVotedGameEvent                       = false;
new                     g_iPickGameEvent                                    = -1;                   // what event we're picking

// Stripper
new     bool:           g_bStripperPresent                                  = false;                // whether a cvar-configurable Stripper:Source is present
new     String:         g_sStripperDir          [128];                                              // the directory that the stripper cfg files are in
new                     g_iStripperCurrentAlt                               = 0;                    // which stripper alternative is currently loaded (0 = default dir)
new     bool:           g_bStripperAltDetected                              = false;                // whether a stripper set hard path is detected (prop_dynamic with targetname "random_alt_detect")

// Report (timer)
new     Handle:         g_hTimerReport                                      = INVALID_HANDLE;       // timer for delaying roundstart report
new     bool:           g_bTimerReport                                      = false;                // is it running?

// Gift management
new     Float:          g_fGiftReportTimeout                                = 0.0;                  // stores time when 'can't open gift' message last showed (to prevent multiple messages)
new     Float:          g_fGiftUseTimeout       [MAXPLAYERS+1]              = {0.0,...};            // stores time when player last used gift (to prevent use spam after opening)
new                     g_iClientUsing          [MAXPLAYERS+1]              = {0,...};              // entity that a client is doing a progress-bar type use action on, if any
new     bool:           g_bClientHoldingUse     [MAXPLAYERS+1]              = {false,...};          // for some use fixes: whether player is holding use key (while still blocking it)
new     Float:          g_fGiftBlindTime        [MAX_CHARACTERS];                                   // when the character started being blind

// Tanks
//new                     g_iHadTanks             [MAXPLAYERS+1]              = {0,...};              // how many tanks did the player get this game?
new     String:         g_sPreviousTankClient   [2][32];                                            // what was the previous player to get a (first) tank?, per team
new     bool:           g_bIsTankInPlay                                     = false;
new     bool:           g_bTankFirstRound                                   = false;
new     bool:           g_bFirstTankSpawned                                 = false;
new     bool:           g_bFirstTankDied                                    = false;
//new     bool:           g_bSecondTankSpawned                                = false;
new     bool:           g_bSecondTankSet                                    = false;
new                     g_iTankClient                                       = 0;
new     Float:          g_fTankPreviousPass                                 = 0.0;                  // when did the tank previously pass to a player?
new                     g_iTankPass                                         = 0;                    // which (human) tank pass we're on
new     bool:           g_bTankWillSpawn                                    = false;
new     bool:           g_bDoubleTank                                       = false;                // same, reversed, but for reporting uses only
new     Float:          g_fTankFlowEarly                                    = 0.0;
new     Float:          g_fTankFlowLate                                     = 0.0;
new     Float:          g_fTankDeathLocation[3]                             = {0.0,...};            // last tank death location, for item drops
new                     g_iMiniTankIndex;				                                            // current minitank in map
new                     g_iMiniTankNum;				                                                // the number of minitanks to be spawned on the current map
new     Float:          g_fArMiniTankFlows      [MULTITANK_MAX];                                    // stores flow distances for the current round
new     bool:           g_bTankIsEarly                                      = false;                // for balance changes 

// Witches (Stabby)
new     bool:           g_bWitchWillSpawn                                   = false;
new     bool:           g_bWitchFirstRound                                  = false;                // true if there was a witch first round (to prevent 1/0 bugged witch spawns...)
new     bool:           g_bMultiWitch                                       = false;                // whether we'll have multiple witches this round(half)
new                     g_iWitchNum;				                                                // the number of witches to be spawned on the current map
new                     g_iWitchIndex;                                                              // the index of the current witch (in the witch flows array)
new     Float:          g_fArWitchFlows         [MULTIWITCH_MAX];                                   // stores flow distances for the current round
new     bool:           g_bArWitchSitting       [MULTIWITCH_MAX]            = {true,...};           // stores whether each witch is sitting or walking

// SI Spawning / ghosts
new     bool:           g_bHasSpawned           [MAXPLAYERS+1]              = {false,...};          // whether player X has spawned his ghost (only true if still alive and not tank)
new     bool:           g_bHasGhost             [MAXPLAYERS+1]              = {false,...};          // whether player X currently holds a ghost
new     bool:           g_bClassPicked          [MAXPLAYERS+1]              = {false,...};          // whether player X got assigned a class (for catching the few times the l4dt forward doesn't fire)
new                     g_iSpectateGhost        [TEAM_SIZE];                                        // people that spectated while being SI ghosts.. remembered to avoid exploit
new                     g_iSpectateGhostCount                               = 0;                    // amount of ghosts saved
new                     g_iGhostClassOnDeath    [MAXPLAYERS+1];                                     // if a player died as a ghost, what class they were
new     Float:          g_fGhostDeathTime       [MAXPLAYERS+1];                                     // what time it was when the player died as a ghost last    used to check for spectate deaths


// SDK Calls
new     Handle:         g_setClass                                          = INVALID_HANDLE;
new     Handle:         g_createAbility                                     = INVALID_HANDLE;
new                     g_oAbility                                          = 0;
new     Handle:         g_CallPushPlayer                                    = INVALID_HANDLE;       // for CreateExplosion() push
new     Handle:         g_CallBileJarPlayer                                 = INVALID_HANDLE;       // for biling infected at will
new     Handle:         g_CallVomitSurvivor                                 = INVALID_HANDLE;       // for biling survivors at will

// Sack-exploitation checks and Death order effect
new                     g_iClassTimeout         [7]                         = 0;                    // the 'level' / counter for the timeout
new     Float:          g_fGotGhost             [MAXPLAYERS+1]              = {0.0,...};            // when player got their SI ghost most recently
new     Float:          g_fDeathAfterGhost      [MAXPLAYERS+1]              = {0.0,...};            // the first SI death of another teammember after player got their ghost
new                     g_iOffences             [MAXPLAYERS+1]              = {0,...};              // the amount of times a player has done this (since plugin was loaded) - warn at 3 strikes?
new     Float:          g_fLastOffence          [MAXPLAYERS+1]              = {0.0,...};            // time of last offence by client

// Boomer tracking
new                     g_iCommonBoomQueue                                  = 0;                    // how many common infected that will spawn are boomer(effect) created
new     bool:           g_bBoomHighRewardMode                               = false;                // whether to reward for a 'normal' combo or a higher combo (2 vs 3)
new                     g_iBoomedSurvivors      [MAXPLAYERS+1]              = {0,...};              // per client: which boomer vomited on it (first) - set to 0 when player is no longer it
new                     g_iBoomsPerBoomer       [TEAM_SIZE]                 = {0,...};              // per iBoomersInCombo index: how many survivors did they get?
new                     g_iBoomersInCombo       [TEAM_SIZE]                 = {0,...};              // the clients that are part of the current boomer combo
new     Float:          g_fBoomTime             [TEAM_SIZE]                 = {0.0,...};            // when the boomer got its most recent boom
new     Float:          g_fDudTimeExpire                                    = 0.0;                  // time when pipeboms will work again after a 2+ boom combo
new     Float:          g_fRewardTime                                       = 0.0;                  // for how long the reward should work (common limit change for women event)

// Blind infected
new                     g_iArCreatedEntities    [ENTITY_COUNT];                                     // Stored entity ids for this roundhalf
new                     g_iCreatedEntities                                  = 0;                    // size of CreatedEntities list
new     Handle:         g_hBlockedEntities;

// Available choices / Weighting
new                     g_iArWeightedChoices        [STORED_MAX_COUNT];                             // all the choices (every category * its weight)
new                     g_iWeightedChoicesTotal;                                                    // total of WeightedChoices 'hat' filled
new                     g_iWeightedChoicesStartUseful;                                              // where the useful choices start (skipping no-item)
new                     g_iWeightedChoicesEndUseful;                                                // where the useful choices end (before junk)
new                     g_iArSurvWeightedChoices    [STORED_SURV_MAX_COUNT];                        // all the choices (every category * its weight) for survivor start
new                     g_iSurvWeightedChoicesStartSecondary;                                       // where the useful secondary choices start
new                     g_iSurvWeightedChoicesEndSecondary;                                         // where the useful secondary choices end (before magnum)
new                     g_iSurvWeightedChoicesStartPrimary;                                         // where the useful primary choices start
new                     g_iSurvWeightedChoicesTotal;                                                // total of WeightedChoices 'hat' filled for survivor start
new                     g_iArEventWeightedChoices   [STORED_MAX_COUNT];                             // all the choices (every category * its weight) for events
new                     g_iEventWeightedChoicesTotal;                                               // total of WeightedChoices 'hat' filled for events
new                     g_iArSpawnWeightedChoices   [STORED_SI_MAX_COUNT];                          // all the choices for SI spawns (every category * its weight)
new                     g_iSpawnWeightedChoicesTotal;                                               // total of WeightedChoices 'hat' filled for spawns
new                     g_iSpawnWeightedChoicesStartCappers;                                        // where the capper spawn choices start (first spit, boom, then the rest)
new                     g_iArGiftWeightedChoices    [STORED_GIFT_MAX_COUNT];                        // all the choices for gift effects
new                     g_iGiftWeightedChoicesTotal;                                                // total of WeightedChoices 'hat' filled for gift effects
new                     g_iGiftWeightedChoicesStartNegative;                                        // where the negative effects start
new                     g_iGiftWeightedChoicesStartPosSaferoom;                                     // where the saferoom-okay effects start (positive)
new                     g_iGiftWeightedChoicesStartNegSaferoom;                                     // where the saferoom-okay effects start (negative)
new                     g_iGiftWeightedChoicesStartPosInsight;                                      // where the insight positive starts
new                     g_iGiftWeightedChoicesStartNegInsight;                                      // where the insight negative starts

// Actual choices storage
new                     g_strArStorage          [ENTITY_COUNT][strEntityData];                      // Stored entities, type is INDEX_
new                     g_iStoredEntities                                   = 0;                    // size of strStoredEntities
new                     g_strArHittableStorage  [HITTABLE_COUNT][strHittableData];                  // Stored entities (hittables)
new                     g_iStoredHittables                                  = 0;                    // size of strStoredEntities
new     String:         g_sArStorageMelee       [ENTITY_COUNT][MELEE_CLASS_LENGTH];                 // Stored melee-class per entity
new                     g_iArStorageSurv        [TEAM_SIZE];                                        // survivor starting choice INDEX_START_
new                     g_iArStorageSurvSec     [TEAM_SIZE];                                        // survivor starting choice INDEX_START_ (secondaries if first choice is a primary)
new                     g_iArStorageSurvHealth  [TEAM_SIZE];                                        // survivor starting health
new                     g_iArStorageSurvMelee   [TEAM_SIZE];                                        // survivor starting choice (if melee): melee type
new                     g_iArStorageSurvPills   [TEAM_SIZE];                                        // survivor starting choice did they get pills?
new                     g_iArStorageSurvAmmo    [TEAM_SIZE];                                        // survivor starting choice -- if T1, ammo count
new                     g_iSurvHandled                                      = 0;                    // how many of the survivor setups have already been handled for this roundhalf
new     bool:           g_bSurvHandout                                      = false;                // whether we still need to hand out any starting setups this round
new     Float:          g_fStorageDoors         [MAX_DOORS][3];                                     // which doors should be locked this round (2 halves), origin[2]
new                     g_iDoorsLocked          [MAX_DOORS];                                        // which doors are currently locked (this half-round), entity-number
new                     g_iDoorsLockedTotal                                 = 0;                    // amount of doors locked
new                     g_iArStorageSpawns      [TEAM_SIZE]                 = {ZC_NOTINFECTED,...}; // classes for first attack

new                     g_strTempItemSingle     [strEntityData];                                    // for temporary storage of 'to create' entities
new     String:         g_sTempItemSingleMelee  [MELEE_CLASS_LENGTH]        = "";
new     Float:          g_fTempItemSingleVelocity[3];                                               // velocity for spawn dynamics

// Currently active in this round/map
new                     g_iDifficultyRating                                 = 0;                    // how difficulty this round is expected to be.. (higher = more difficult)
new     bool:           g_bGlows                                            = true;                 // whether survivors have glows this map
new                     g_iIncaps                                           = INCAP_DEFAULT;        // how many incaps before b/w
new                     g_iSpecialEvent                                     = -1;                   // what special event is active for this map
new                     g_iSpecialEventExtra                                = PCK_NOITEM;           // which item (or item type) is special (or other int information)
new                     g_iSpecialEventExtraSub                             = 0;                    // extra event-dependent int value
new     String:         g_sSpecialEventExtra    [MELEE_CLASS_LENGTH]        = "";                   // which melee class is chosen (or other string information)
new     bool:           g_bEarlyLock                                        = false;                // if a really early door is locked (to help survivors out with starting items)
new                     g_iSpecialEventRole                                 = 0;                    // for player-selecting special events
new                     g_iDefaultDistance                                  = 0;                    // how much distance the map is worth normally (at OnMapStart)
new                     g_iDamageBonus                                      = 0;                    // how much bonus for this round (half) can be got (maximally)
new                     g_iHoldoutBonus                                     = 0;                    // if holdout_bonus active, what points of the distance are turned to bonus

// Insight
new     bool:           g_bInsightSurvDone                                  = false;                // already 'had insight'?
new     bool:           g_bInsightInfDone                                   = false;
new                     g_iCountItemGnomes                                  = 0;                    // present on this round
new                     g_iCountItemCola                                    = 0;
new                     g_iCountItemMedkits                                 = 0;
new                     g_iCountItemDefibs                                  = 0;
new     bool:           g_bCarAlarmsDisabled                                = false;                // already disabled all alarms for this team?

// Gnome / bonus scoring
new                     g_iJustPickedItemUp                                 = 0;                    // player_use => item_pickup (so we can exclude non-picked up gnomes)
new     Float:          g_fLastReviveTime       [MAXPLAYERS+1]              = {0.0,...};            // when player was last revived from incap
new                     g_iGnomeJustDropped                                 = 0;                    // for onentitydestroyed => onentitycreated gnome switching
new                     g_iGnomes                                           = 0;                    // how many gnomes/cola items are detected on the map
new                     g_strArGnomes           [GNOME_MAX_COUNT][strGnomeData];                    // the gnomes/cola in this map
new                     g_iGnomesHeld                                       = 0;                    // how many gnomes are held by survivors
new                     g_iArGnomesHeld         [TEAM_SIZE];                                        // which gnomes are held (check for these entities to be destroyed on drop)

new     bool:           g_bUsingPBonus                                      = false;                // whether we're using penaltybonus this round
new     bool:           g_bArJustBeenGiven      [MAXPLAYERS+1]              = {false,...};          // whether the client has just been given something (for tracking pickups/pill passing)
new     bool:           g_bArBlockPickupCall    [MAXPLAYERS+1]              = {false,...};          // whether we should ignore weapon equip/pickup calls for the player now
new                     g_iBonusCount                                       = 0;                    // how many special event bonuses/penalties this roundhalf

// special event stuff
new     bool:           g_bNoSpawnBalance                                   = false;                // whether spawn balance mode is forced to 0 this round
new                     g_iArEventTimeout       [EVT_TOTAL]                 = {0,...};              // per event, how many rounds it will sit in timeout
new                     g_iNoSpecialEventStreak                             = 0;                    // how many times in a row there wasn't a special event
new     bool:           g_bSpecialEventPlayerCheck                          = false;                // whether the special event requires player checks on teamswaps, deaths, etc
new     bool:           g_bSpecialRoleAboutToChange                         = false;                // whether we're already waiting for a timer countdown to do a report (spam prevent)
new     String:         g_sArHadRoleId          [MAXROLES][32];                                     // the steam id of the special role player
new                     g_iHadRoleCount                                     = 0;                    // how many players we're remembering that had the special role (and should get it back)
new                     g_iArGunAmmoCount       [MAXPLAYERS]                = 0;                    // for gun swap event: how many bullets does the survivor have left?
new     bool:           g_bNoPriWeapons                                     = false;                // whether to allow primary weapons to spawn at all
new     bool:           g_bNoSecWeapons                                     = false;                // whether to allow secondary weapons to spawn at all
new     bool:           g_bNoAmmo                                           = false;                // whether to spawn ammo at all
new     bool:           g_bNoHealthItems                                    = false;                // whether to spawn health items / defibs at all
new                     g_iBoobyTraps                                       = 0;                    // how many boobytrap entries in the aray
new                     g_iArBoobyTrap          [MAX_BOOBYTRAPS]            = {-1,...};             // entities that are boobytrapped (this round)
new     Float:          g_fProgressTime         [MAXPLAYERS+1]              = 0.0;                  // for keeping track of progress bar
new     Float:          g_fProgressLocation     [MAXPLAYERS+1][3];                                  // for keeping track of progress bar location
new                     g_iDeployedAmmo                                     = 0;                    // what is the deployed ammo pile?
new     bool:           g_bShowedProgressHint                               = false;                // so we only show the text once
new     Handle:         g_hTimePenaltyTimer                                 = INVALID_HANDLE;       // for the EVT_PEN_TIME
new                     g_iTimePenaltyCounter                               = 0;                    // counts seconds for the time penalty
new     Handle:         g_hWitchSpawnTimer                                  = INVALID_HANDLE;       // crox's multiwitches
new                     g_iMedicUnits                                       = 8;                    // the current 'mediunits' available to the medic
new                     g_iMedicRanOut                                      = 0;                    // so we can prevent over-reporting
new     bool:           g_bMedicFirstHandout                                = false;                // whether the medic has handed out pills to anyone yet (for removal check)
new                     g_iWitchesSpawned                                   = 0;                    // for tracking max no. of witches for witch hunt
new     Handle:         g_hBoomFluTimer                                     = INVALID_HANDLE;       // for the EVT_BOOMFLU
new                     g_iBoomFluCounter                                   = 0;                    // counts seconds for the boom flu
new                     g_iBoomFluActivate                                  = 0;                    // after how many seconds the boomer flu should activate (again)
new     bool:           g_bPlayerIsBlinded      [MAXPLAYERS+1]              = {false,...};          // whether player blinded (NOHUD event)
new     Float:          g_fAmmoDeploySpot       [3]                         = {0.0,...};            // where ammo was last deployed
new     Handle:         g_hDoorCircusTimer                                  = INVALID_HANDLE;       // for the EVT_DOORCIRCUS
new                     g_iDoorCircusCount      [3]                         = 0;
new     bool:           g_bDoorCircusState      [3]                         = false;                // door open closed state
new                     g_iDoorCircusType       [3][MAX_DOORS];                                     // list of all doors per type (for different timings)
new                     g_iDoorCircusTypeCount  [3]                         = 0;                    // amount of doors per type
new                     g_bWitchBungled         [ENTITY_COUNT];                                     // stores, per witch entity, whether survivors bungled her
new     Float:          g_fWomenBoomCharged     [MAXPLAYERS+1];                                     // when a boomer can scratch-boom again


// T2 nerf
new     Float:          g_fNerfMsgTimeout       [MAXPLAYERS+1]              = {0.0,...};            // time when player will get a t2 nerf msg again

// Vomiting
new     Handle:         g_hVomitTraceAttack     [MAXPLAYERS+1]              = INVALID_HANDLE;       // for tracking who a player vomits upon
new     bool:           g_bAlreadyVomitedUpon   [MAXPLAYERS+1]              = false;                // so we can just do things once per vomit-covering

// Hats
new                     g_iHatIndex[MAXPLAYERS+1];				// Player hat entity reference
new                     g_iType[MAXPLAYERS+1];					// Stores selected hat to give players.

// RandomMapInfo keyvalues
new     Handle:         g_kRIData                                           = INVALID_HANDLE;       // keyvalues handle for randommapinfo.txt
new     bool:           g_RI_bIsIntro                                       = false;                // only true for intro maps
new     bool:           g_RI_bIsFinale                                      = false;                // only true for finale maps
new                     g_RI_iDifficulty                                    = 0;                    // difficulty offset for this specific map
new                     g_RI_iDoors                                         = 1;                    // 0 = no doors on map, 1 = normal, 2 = many doors
new     bool:           g_RI_bNoTank                                        = false;                // block tank spawns
new     bool:           g_RI_bNoTankVar                                     = false;                // set tank variation to 0
new     bool:           g_RI_bNoWitch                                       = false;                // block witch spawns
new                     g_RI_iNoStorm                                       = 0;                    // block storms for this map 1 = block, 2 = block only fog (special case)
new     bool:           g_RI_bNoRain                                        = false;                // block storm rain effect
new     bool:           g_RI_bNoCola                                        = false;                // block cola spawns
new                     g_RI_iTankBanStart                                  = 0;                    // block specific tank spawn range
new                     g_RI_iTankBanEnd                                    = 0;                    // block specific tank spawn range
new                     g_RI_iTankBanEarly                                  = 0;                    // block specific tank spawn for banning (some) early tanks
new     bool:           g_RI_bWeakHittables                                 = false;                // makes hittables do less damage (like c5m5 normally)
new                     g_RI_iDistance                                      = 0;                    // normal max map distance points
new                     g_RI_iDistanceHard                                  = 0;                    // hard-path max map distance points
new                     g_RI_iEarlyDoors                                    = 0;                    // how many early doors to check
new                     g_RI_iArEarlyDoor       [EARLYDOOR_MAX][3];                                 // early door coordinates (if any)
new     Float:          g_RI_fTankOddsNormal                                = 0.0;                  // if > 0, override value for tank chance this map
new     Float:          g_RI_fTankOddsHard                                  = 0.0;                  // if > 0, override value for tank chance this map (if hard path)
new     bool:           g_RI_bNoRealHittables                               = false;

// ConVars
new     Handle:         g_hArCvarWeight         [INDEX_TOTAL];                                      // cvar, per randomize-type, that sets an integer weight 
new     Handle:         g_hArCvarSurvWeight     [INDEX_SURV_TOTAL];                                 // cvar, per randomize-type, that sets an integer weight -- for handing out starting weapon
new     Handle:         g_hArCvarEvtWeight      [EVT_TOTAL];                                        // cvar, per randomize-type, that sets an integer weight -- for picking events
new     Handle:         g_hArCvarGiftWeight     [GIFT_TOTAL];                                       // cvar, per randomize-type, that sets an integer weight -- for picking gift effects

new     Handle:         g_hCvarDebug                                        = INVALID_HANDLE;       // cvar debug mode
new     Handle:         g_hCvarLoaded                                       = INVALID_HANDLE;       // cvar (for internal check)
new     Handle:         g_hCvarConfogl                                      = INVALID_HANDLE;       // cvar whether to wait one map-restart before reading default cvar values
new     Handle:         g_hCvarSimplePauseCheck                             = INVALID_HANDLE;       // cvar whether we should do a very simple pause check
new     Handle:         g_hCvarUseOldSpawn                                  = INVALID_HANDLE;       // cvar whether we should use z_spawn_old
new     Handle:         g_hCvarStripperMode                                 = INVALID_HANDLE;       // cvar what way to use stripper
new     Handle:         g_hCvarStripperPath                                 = INVALID_HANDLE;       // cvar stripper cfg path (base)
new     Handle:         g_hCvarRIKeyValuesPath                              = INVALID_HANDLE;       // cvar dir to randommap.txt
new     Handle:         g_hCvarRCKeyValuesPath                              = INVALID_HANDLE;       // cvar dir to randomconfig.txt
new     Handle:         g_hCvarWelcomeMode                                  = INVALID_HANDLE;       // cvar which welcome-message mode to use
new     Handle:         g_hCvarBlockL4D1Common                              = INVALID_HANDLE;       // cvar whether to block l4d1 common and not use them for l4d1 event
new     Handle:         g_hCvarNerfT2                                       = INVALID_HANDLE;       // cvar whether to nerf t2 weapons in the game (allowed other weapons)
new     Handle:         g_hCvarStopBotsAtStart                              = INVALID_HANDLE;       // cvar whether to stop bots doing anything before humans are ready
new     Handle:         g_hCvarBlockEventVotes                              = INVALID_HANDLE;       // cvar whether to block event / gameevent votes
new     Handle:         g_hCvarCampaignStreak                               = INVALID_HANDLE;       // cvar how many times in a row no changed event

new     Handle:         g_hCvarEqual                                        = INVALID_HANDLE;       // cvar flags what to equalize between teams
new     Handle:         g_hCvarDoReport                                     = INVALID_HANDLE;       // cvar whether to report anything at all
new     Handle:         g_hCvarReportDelay                                  = INVALID_HANDLE;       // cvar by how many seconds to delay the report for special events
new     Handle:         g_hCvarReportSackProt                               = INVALID_HANDLE;       // cvar whether to report sack protection measures
new     Handle:         g_hCvarDifficultyBalance                            = INVALID_HANDLE;       // cvar whether to balance round settings based on estimated difficulty
new     Handle:         g_hCvarM60Ammo                                      = INVALID_HANDLE;       // cvar for setting m60 ammo
new     Handle:         g_hCvarClipFactorInc                                = INVALID_HANDLE;       // cvar for factor of incendiary ammo clip
new     Handle:         g_hCvarClipFactorExp                                = INVALID_HANDLE;       // cvar for factor of explosive ammo clip
new     Handle:         g_hCvarRandomSpawns                                 = INVALID_HANDLE;       // cvar whether to make SI spawns random
new     Handle:         g_hCvarSackProtection                               = INVALID_HANDLE;       // cvar whether to punish SI sacking (to any degree)
new     Handle:         g_hCvarDeathOrderMode                               = INVALID_HANDLE;       // cvar whether (and in what mode) to deal with death order
new     Handle:         g_hCvarNoSupportSI                                  = INVALID_HANDLE;       // cvar whether to always spawn only cappers (for 2v2/3v3 etc)
new     Handle:         g_hCvarTeamSize                                     = INVALID_HANDLE;       // cvar how many survivors in a team? used for balancing item spread (convar survivor_limit)
new     Handle:         g_hCvarRestrictMelee                                = INVALID_HANDLE;       // cvar whether to restrict melee weapons to normal l4d2-material
new     Handle:         g_hCvarRandomTank                                   = INVALID_HANDLE;       // cvar whether player selection for tank is random
new     Handle:         g_hCvarNoSpitterDuringTank                          = INVALID_HANDLE;       // cvar like it says
new     Handle:         g_hCvarFreezeDistanceTank                           = INVALID_HANDLE;       // cvar whether distance points should be frozen during tank
new     Handle:         g_hCvarBoomedTime                                   = INVALID_HANDLE;       // cvar boomed window in seconds
new     Handle:         g_hCvarGnomeBonus                                   = INVALID_HANDLE;       // cvar how many points for a full gnome start->end delivery
new     Handle:         g_hCvarGnomeFinaleFactor                            = INVALID_HANDLE;       // cvar scaling gnome bonus for finale maps
new     Handle:         g_hCvarGnomeAllowRandom                             = INVALID_HANDLE;       // cvar whether gnomes can drop at random
new     Handle:         g_hCvarSpecialEventTimeout                          = INVALID_HANDLE;       // cvar how many maps it takes for a special event to be pickable again
new     Handle:         g_hCvarMiniTankHealth                               = INVALID_HANDLE;       // cvar how much health a minitank has
new     Handle:         g_hCvarDoubleTankHealth                             = INVALID_HANDLE;       // cvar how much health a tank on a double-tank round has
new     Handle:         g_hCvarBanTankFlows                                 = INVALID_HANDLE;       // cvar whether to take banned tank flow into account
new     Handle:         g_hCvarRandomHittables                              = INVALID_HANDLE;       // cvar whether to randomize the hittables

new     Handle:         g_hCvarFinaleItemUseful                             = INVALID_HANDLE;       // cvar the factor by which non-useful items are reduced for finale maps
new     Handle:         g_hCvarStartItemNoJunk                              = INVALID_HANDLE;       // cvar the odds that junk gets changed to something useful in start saferoom
new     Handle:         g_hCvarStartItemAmmo                                = INVALID_HANDLE;       // cvar the odds that there will be at least one ammo pile in start saferoom
new     Handle:         g_hCvarStartItemGnome                               = INVALID_HANDLE;       // cvar the odds that there will be at least one gnome in the start saferoom (including handouts)
new     Handle:         g_hCvarStartBalanceSurv                             = INVALID_HANDLE;       // cvar whether we'll adjust survivor handouts based on difficulty
new     Handle:         g_hCvarSpawnBalanceMode                             = INVALID_HANDLE;       // cvar mode in which we balance out spawns of chargers/spitters/boomers

new     Handle:         g_hCvarNoitemVariance                               = INVALID_HANDLE;       // cvar the variance of PCK_NOITEM
new     Handle:         g_hCvarPillsChance                                  = INVALID_HANDLE;       // cvar odds that survivor is given pills/adren at start
new     Handle:         g_hCvarPistolChance                                 = INVALID_HANDLE;       // cvar odds that survivor is given pistol as secondary at start when receiving a primary and nothing else
new     Handle:         g_hCvarExtraSecondaryChance                         = INVALID_HANDLE;       // cvar odds that survivor is given a secondary if he's already being given a primary
new     Handle:         g_hCvarHealthChance                                 = INVALID_HANDLE;       // cvar odds that survivor is given different starting health
new     Handle:         g_hCvarHealthMin                                    = INVALID_HANDLE;       // cvar minimum amount of health a survivor will have
new     Handle:         g_hCvarSpecialEventChance                           = INVALID_HANDLE;       // cvar the odds of a special event kicking in for a map
new     Handle:         g_hCvarOutlineChance                                = INVALID_HANDLE;       // cvar the odds of there being survivor outlines this round
new     Handle:         g_hCvarDoorLockedChance                             = INVALID_HANDLE;       // cvar the odds of any door being locked
new     Handle:         g_hCvarStartSafeItem                                = INVALID_HANDLE;       // cvar chances an item in the start saferoom will exist
new     Handle:         g_hCvarEndSafeItem                                  = INVALID_HANDLE;       // cvar chances an item in the end saferoom will exist
new     Handle:         g_hCvarUncommonChance                               = INVALID_HANDLE;       // cvar the odds of any spawning common to become an uncommon
new     Handle:         g_hCvarFallenChance                                 = INVALID_HANDLE;       // cvar the odds of any spawning uncommon to become a fallen survivor
new     Handle:         g_hCvarJimmyChance                                  = INVALID_HANDLE;       // cvar the odds of any spawning uncommon to become jimmy gibbs
new     Handle:         g_hCvarFirstQuadChance                              = INVALID_HANDLE;       // cvar the odds of the first attack being a quad cap
new     Handle:         g_hCvarAmmoVarianceMore                             = INVALID_HANDLE;       // cvar the variance of ammo in fresh weapons, positive
new     Handle:         g_hCvarAmmoVarianceLess                             = INVALID_HANDLE;       // cvar the variance of ammo in fresh weapons, negative
new     Handle:         g_hCvarDoubleTankChance                             = INVALID_HANDLE;       // cvar the odds double tanks spawning in a round
new     Handle:         g_hCvarMultiWitchChance                             = INVALID_HANDLE;       // cvar the odds multiple witch spawning in a round
new     Handle:         g_hCvarTankFlowVariance                             = INVALID_HANDLE;       // cvar by how much to vary tank spawns around set points for 2-tank-rounds
new     Handle:         g_hCvarItemDropChance                               = INVALID_HANDLE;       // cvar the odds of any common dropping an item
new     Handle:         g_hCvarTankItemDropChance                           = INVALID_HANDLE;       // cvar the odds of tanks dropping some items
new     Handle:         g_hCvarGiftPositiveChance                           = INVALID_HANDLE;       // cvar the odds of opening a gift resulting in something good
new     Handle:         g_hCvarPipeDudChance                                = INVALID_HANDLE;       // cvar the odds of any pipebomb being a dud
new     Handle:         g_hCvarAvoidIncapsChance                            = INVALID_HANDLE;       // cvar the odds of changing 1-incap-per-round back to 2 (so we can make it easier with a cvar)
new     Handle:         g_hCvarNormalAmmoChance                             = INVALID_HANDLE;       // cvar the odds that ammo is randomized on normal maps
new     Handle:         g_hCvarFinaleAmmoChance                             = INVALID_HANDLE;       // cvar the odds that finale ammo is randomized
new     Handle:         g_hCvarAlarmedCarChance                             = INVALID_HANDLE;       // cvar the odds that a car is alarmed
new     Handle:         g_hCvarT2StartChance                                = INVALID_HANDLE;       // cvar odds that t2's are allowed in start saferoom
new     Handle:         g_hCvarCarExplodeChance                             = INVALID_HANDLE;       // cvar chances a car can explode

new     Handle:         g_hCvarStaticBonus                                  = INVALID_HANDLE;       // cvar: the static survival bonus to use
new     Handle:         g_hCvarRandDistance                                 = INVALID_HANDLE;       // cvar whether we're using random distance points (mode)
new     Handle:         g_hCvarRandDistVar                                  = INVALID_HANDLE;       // cvar the variance when using normal map distances
new     Handle:         g_hCvarRandDistMin                                  = INVALID_HANDLE;       // cvar the minimum random distance points for a map
new     Handle:         g_hCvarRandDistMax                                  = INVALID_HANDLE;       // cvar the maximum random distance
new     Handle:         g_hCvarRandBonus                                    = INVALID_HANDLE;       // cvar whether we're using random damage bonus points (mode)
new     Handle:         g_hCvarRandBonusBase                                = INVALID_HANDLE;       // cvar 0.0 = use static bonus; anything else = scale distance points to get bonus
new     Handle:         g_hCvarRandBonusStatic                              = INVALID_HANDLE;       // cvar if we're using a static damage bonus value, this is it
new     Handle:         g_hCvarRandBonusVar                                 = INVALID_HANDLE;       // cvar the variance when using bonus variance mode
new     Handle:         g_hCvarRandBonusMin                                 = INVALID_HANDLE;       // cvar the minimum random distance points for a map
new     Handle:         g_hCvarRandBonusMax                                 = INVALID_HANDLE;       // cvar the maximum random distance
new     Handle:         g_hCvarRandBonusSolidFactor                         = INVALID_HANDLE;       // cvar what solid health is worth (compared to normal health)
new     Handle:         g_hCvarRandBonusScaleMode                           = INVALID_HANDLE;       // cvar how to scale for bonus: scale entire bonus or reduce

new     Handle:         g_hCvarAmmoAk                                       = INVALID_HANDLE;       // cvar how much ammo in AK47s
new     Handle:         g_hCvarAmmoScout                                    = INVALID_HANDLE;       // cvar how much ammo in Scout rifle
new     Handle:         g_hCvarAmmoAWP                                      = INVALID_HANDLE;       // cvar how much ammo in AWP rifle
new     Handle:         g_hCvarAmmoSniper                                   = INVALID_HANDLE;       // cvar how much ammo in Military Sniper (used to avoid scout/awp bugs)

// Default convars
new     Handle:         g_hCvarReadyUp                                      = INVALID_HANDLE;       // cvar handle for readyup checking
new     Handle:         g_hCvarPausable                                     = INVALID_HANDLE;       // cvar handle for pausable/pausing checking
new     Handle:         g_hCvarBotStop                                      = INVALID_HANDLE;       // cvar handle for sb_stop

//new     Handle:         g_hCvarPounceInterrupt                              = INVALID_HANDLE;       // pounce interrupt (150)
new     Handle:         g_hCvarPounceUncapDamage                            = INVALID_HANDLE;       // z_pounce_max_bonus_damage
new     Handle:         g_hCvarPounceUncapRange                             = INVALID_HANDLE;       // z_pounce_damage_range_max


new                     g_iHordeTimeMin                                     = 30;                   // these are set when round goes live
new                     g_iHordeTimeMax                                     = 180;

// Default values
new                     g_iTeamSize                                         = 4;
new                     g_iDefSpawnTimeMin                                  = 15;
new                     g_iDefSpawnTimeMax                                  = 18;
new                     g_iDefCommonLimit                                   = 30;
new                     g_iDefBackgroundLimit                               = 20;
new                     g_iDefHordeSizeMin                                  = 5;
new                     g_iDefHordeSizeMax                                  = 35;
new                     g_iDefHordeTimeMin                                  = 30;
new                     g_iDefHordeTimeMax                                  = 180;

new                     g_iDefDefibPenalty                                  = 25;
new                     g_iDefDefibDuration                                 = 3;
new     Float:          g_fDefPillDecayRate                                 = 0.27;

new                     g_iDefSmokerLimit                                   = 1;
new                     g_iDefBoomerLimit                                   = 1;
new                     g_iDefHunterLimit                                   = 1;
new                     g_iDefSpitterLimit                                  = 1;
new                     g_iDefJockeyLimit                                   = 1;
new                     g_iDefChargerLimit                                  = 1;

new                     g_iDefAmmoSmg                                       = 650;
new                     g_iDefAmmoShotgun                                   = 80;
new                     g_iDefAmmoHR                                        = 150;
new                     g_iDefAmmoSniper                                    = 180;
new                     g_iDefAmmoRifle                                     = 360;
new                     g_iDefAmmoAutoShotgun                               = 90;

new     Float:          g_fDefFFFactor                                      = 0.1;

new                     g_iDefTankHealth                                    = 4000;     // 2/3rds of versus value
new                     g_iDefTankFrustTime                                 = 20;
new                     g_iDefTankDamage                                    = 24;
new                     g_iDefTankHittableDamage                            = 100;      // for hittable control
new     Float:          g_fDefTankFlowVariation                             = 0.1;

new                     g_iDefVomitInterval                                 = 30;
new                     g_iDefSpitInterval                                  = 20;

new     Float:          g_fDefCedaBileProb                                  = 0.1;
new     Float:          g_fDefRiotTonfaProb                                 = 0.15;

new                     g_iActiveAmmoAk                                     = 250;
new                     g_iActiveAmmoSniper                                 = 65;
new                     g_iActiveAmmoScout                                  = 90;
new                     g_iActiveAmmoAWP                                    = 60;

new                     g_iPounceUncapDamageMax                             = 24;
new     Float:          g_fPounceUncapRangeMax                              = 1000.0;

// RandomConfig keyvalues
new     Float:          g_RC_fItemFactor2v2                                 = 0.5;
new     Float:          g_RC_fItemFactor3v3                                 = 0.75;

new                     g_RC_iGiftMinItems                                  = 2;
new                     g_RC_iGiftMaxItems                                  = 5;

new                     g_RC_iMultiwitchMin                                 = 3;
new                     g_RC_iMultiwitchMax                                 = 7;
new     bool:           g_RC_bMultiwitchAllowTank                           = true;

new                     g_RC_iMinitanksNum                                  = 9;
new     Float:          g_RC_fMinitankMeleeDmg                              = 200.0;
new                     g_RC_iMinitankFrustTime                             = 10;
new                     g_RC_iMinitankDamage                                = 20;
new                     g_RC_iMinitankHittableDmg                           = 50;

new                     g_RC_iWeakHittableDmg                               = 25;

new                     g_RC_iTankDropItemsMin                              = 1;
new                     g_RC_iTankDropItemsMax                              = 2;

new     Float:          g_RC_fEventSITimeVeryHard                           = 0.5;
new     Float:          g_RC_fEventSITimeHard                               = 0.75;
new     Float:          g_RC_fEventSITimeEasy                               = 1.25;
new     Float:          g_RC_fEventSITimeVeryEasy                           = 1.5;

new     Float:          g_RC_fEventCILimVeryHard                            = 1.5;
new     Float:          g_RC_fEventCILimHard                                = 1.25;
new     Float:          g_RC_fEventCILimEasy                                = 0.75;
new     Float:          g_RC_fEventCILimVeryEasy                            = 0.5;
new     Float:          g_RC_fEventCILimSuperEasy                           = 0.25;

new     Float:          g_RC_fEventAdrenDecay                               = 1.5;
new                     g_RC_iEventPenaltyItem                              = 5;
new                     g_RC_iEventPenaltyHealth                            = 15;
new                     g_RC_iEventPenaltyM2SI                              = 10;
new                     g_RC_iEventPenaltyTime                              = 25;
new                     g_RC_iEventBonusSkeet                               = 15;
new                     g_RC_iEventBonusSkeetTeam                           = 15;
new                     g_RC_iEventBonusWitch                               = 25;
new                     g_RC_iEventBonusBadSanta                            = 15;

new     Float:          g_RC_fEventWomenMeleeDmg                            = 500.0;    // on witches
new     Float:          g_RC_fEventWomenWitchDmg                            = 25.0;     // to survivors
new     Float:          g_RC_fEventWitchesWitchDmg                          = 50.0;     // to survivors
new                     g_RC_iEventWitchesMaxWitches                        = 30;       // after this, no new witches will spawn

new     Float:          g_RC_fEventFFFactor                                 = 0.3;      // cvar value for hard
new                     g_RC_iEventBadComboAmmo                             = 25;

new     Float:          g_RC_fEventProtectWeak                              = 2.0;
new     Float:          g_RC_fEventProtectStrong                            = 0.75;

new     Float:          g_RC_fEventBoobyTrapChance                          = 0.12;
new                     g_RC_iEventBoobyTrapMin                             = 5;

new     Float:          g_RC_fEventAmmoMaxFactor                            = 0.5;      // max-ammo changer
new     Float:          g_RC_fEventAmmoFactor                               = 0.12;     // init-ammo changer

new     Float:          g_RC_fEventWitchesSpawnFreq                         = 30.0;     // s

new                     g_RC_iEventBoomFluMinInt                            = 20;
new                     g_RC_iEventBoomFluMaxInt                            = 55;

new     Float:          g_RC_fEventBaySIChance                              = 0.55;
new     Float:          g_RC_fEventBayCIChance                              = 0.025;

new     Float:          g_RC_fBoomComboDudChance                            = 0.66;     // chance a pipe will dud till 10s after combo

new                     g_RC_iVomitOnType                                   = 7;        // 1 = survivors; 2 = special infected; 4 = common infected [ flags ]
new     Float:          g_RC_fVomitRange                                    = 125.0;
new     Float:          g_RC_fVomitStreamTime                               = 3.5;      // time in s vomit can hit anything

new     Float:          g_RC_fExplosionPowerHigh                            = 30.0;
new     Float:          g_RC_fExplosionPowerLow                             = 20.0;

new     Float:          g_RC_fBlindTime                                     = 15.0;

new                     g_RC_iPounceUncapDamageMax                          = 49;
new     Float:          g_RC_fPounceUncapRangeMax                           = 1729.1666;

// other RC options
new     bool:           g_RC_bExtraCommonModels                             = true;
new     bool:           g_RC_bDrawPanelReport                               = true;