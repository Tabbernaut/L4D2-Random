
Msg("Loaded random_coop mutation script.\n");

// Include the VScript Library
IncludeScript("VSLib");

/*

    Random Coop Mutation
    --------------------

    Version:    1.0.1



    Communicating with the l4d2_random_coop sourcemod plugin:
    ------------------
    enable random_coop_timer_a_1, _2 and _4 for bitvalues to indicate the desired effect (encounter)
    enable random_coop_timer_b_1, _2, _4 and _8 for bitvalues to indicate the desired amount of spawns

    stripper has added these timers
    if any of the timers _a_ are enabled, the plugin will take action

*/

// enum
ENC_HUNTERS         <- 0
ENC_JOCKEYS         <- 1
ENC_CHARGESPIT      <- 2
ENC_WITCHES         <- 3
ENC_BIGATTACK       <- 4
ENC_SUPPORT         <- 5
ENC_FALLEN          <- 6
ENC_PANICHORDE      <- 7        // meh, don't use this for now

ENC_FIRST           <- 0
ENC_LAST            <- 6

ENC_STAGE_NORMAL    <- 0        // 'normal' coop state
ENC_STAGE_BUILDUP   <- 1        // buildup towards encounter
ENC_STAGE_SPAWNING  <- 2        // spawning encounter spawns
ENC_STAGE_DYING     <- 3        // waiting for encounter spawns to all die
ENC_STAGE_GRACE     <- 4        // grace period after hefty attack

ENC_HUNTER_MIN      <- 4
ENC_HUNTER_MAX      <- 12
ENC_JOCKEY_MIN      <- 4
ENC_JOCKEY_MAX      <- 9
ENC_CHARGER_MIN     <- 3
ENC_CHARGER_MAX     <- 6
ENC_SUPPORT_MIN     <- 10
ENC_SUPPORT_MAX     <- 12
ENC_WITCH_MIN       <- 3
ENC_WITCH_MAX       <- 9
ENC_FALLEN_MIN      <- 5
ENC_FALLEN_MAX      <- 20

ENC_SPAWNING_TIMEOUT    <- 9    // how much time the encounter is given to fully time out (after all of its infected have spawned)
ENC_ENCOUNTER_TIMEOUT   <- 25   // how much time the encounter is given to fully time out (after all of its infected have spawned)
ENC_BUILDUP             <- 8
ENC_GRACETIME           <- 3    // how many seconds gracetime survivors get after fully killing an encounter's SI
ENC_GRACETIME_LONG      <- 10
ENC_INTERVALMIN         <- 25   // how much time (min) between grace and buildup
ENC_INTERVALMAX         <- 50

ENC_STARTMIN            <- 5
ENC_STARTMAX            <- 30

ComTimerA1 <- null
ComTimerA2 <- null
ComTimerA4 <- null
ComTimerB1 <- null
ComTimerB2 <- null
ComTimerB4 <- null
ComTimerB8 <- null


//--------------------------------------------------------------------------------------------
// Main
//--------------------------------------------------------------------------------------------

// mutation director options [ refer to with SessionOptions ]
MutationOptions <-
{
    CommonLimit = 25                          // HARD / Maximum number of common zombies alive in the world at the same time
 	//MegaMobSize = 20                        // Total number of common zombies in a mob. (never more than CommonLimit at one time)
 	//WanderingZombieDensityModifier = 0      // lets get rid of the wandering zombies

 	TankLimit = 4
 	WitchLimit = 30

    // just the start-up situation for specials: quiet
	BoomerLimit = 0
 	ChargerLimit = 0
 	HunterLimit = 0
	JockeyLimit = 0
	SpitterLimit = 0
	SmokerLimit = 0

    MaxSpecials = 0
    DominatorLimit = 0

    // ?
    //cm_AggressiveSpecials = true
    //cm_HealingGnome = true
    //GasCansOnBacks = true
}

// 'globals' for the mutation [ refer to with SessionState ]
MutationState <-
{
    // constants
    ENC_VERYHARD            = 1
    ENC_HARD                = 2
    ENC_MEDIUM              = 3
    ENC_EASY                = 4
    ENC_DIFF_STAGE_VERYHARD = -10  // extra time to add to the normal stage
    ENC_DIFF_STAGE_HARD     = 0
    ENC_DIFF_STAGE_MEDIUM   = 10
    ENC_DIFF_STAGE_EASY     = 20
    ENC_DIFF_CI_VERYHARD    = 30
    ENC_DIFF_CI_HARD        = 25
    ENC_DIFF_CI_MEDIUM      = 20
    ENC_DIFF_CI_EASY        = 15

    // general
    Debug = false
    Paused = false
    TimersSet = false

    // difficulty
    CurrentDifficulty = 2   // HARD
    EncounterDiffDelay = 25 // HARD

    // tracking
    ThinkCount = 0
    //TrackSpawns = false

    CurrentStage = ENC_STAGE_NORMAL
    EncounterCounter = RandomInt( ENC_STARTMIN, ENC_STARTMAX )
    CurrentEncounter = -1

    EncounterSpawnCount = 0
    EncounterDeathCount = 0
    EncounterActive = false

    CurrentSIAlive = 0
}

/*
function OnGameplayStart()
{
    printl( "RANDOM COOP MUTATION: OnGamePlayStart()" )
    SessionState.CurrentStage = ENC_STAGE_NORMAL
    SessionState.EncounterCounter = RandomInt( ENC_INTERVALMIN, ENC_INTERVALMAX )
}
*/

function OnGameEvent_player_left_start_area( params )
{
    //printl( "RANDOM COOP MUTATION: player left start area" )
    if ( SessionState.Debug ) {
        Utils.SayToAll( "LEFT START" )
    }
    SessionState.CurrentStage = ENC_STAGE_NORMAL
    SessionState.EncounterCounter = RandomInt( ENC_STARTMIN, ENC_STARTMAX ) + SessionState.EncounterDiffDelay
    EncounterResetToNormal()
}

function Update()
{
    // this automatically called?

    // once every second...
    if ( Director.HasAnySurvivorLeftSafeArea() && !SessionState.Paused )
    {
        if ( SessionState.ThinkCount++ % 10 == 0 )
        {
            SessionState.ThinkCount = 0

            // set timers
            if ( !SessionState.TimersSet )
            {
                ComTimerA1 <- Entity ( "random_coop_timer_a_1" )
                ComTimerA2 <- Entity ( "random_coop_timer_a_2" )
                ComTimerA4 <- Entity ( "random_coop_timer_a_4" )
                ComTimerB1 <- Entity ( "random_coop_timer_b_1" )
                ComTimerB2 <- Entity ( "random_coop_timer_b_2" )
                ComTimerB4 <- Entity ( "random_coop_timer_b_4" )
                ComTimerB8 <- Entity ( "random_coop_timer_b_8" )
            }

            if ( SessionState.EncounterCounter > 0 ) { SessionState.EncounterCounter-- }

            if ( SessionState.EncounterCounter == 0 )
            {
                switch ( SessionState.CurrentStage )
                {
                    case ENC_STAGE_NORMAL:
                        printl( "NORMAL -> BUILDUP" )
                        if ( SessionState.Debug ) {
                            Utils.SayToAll( "-> BUILDUP" )
                        }

                        SessionState.CurrentStage = ENC_STAGE_BUILDUP

                        // skip buildup if there's nothing around already
                        if ( SessionState.CurrentSIAlive < 1 )
                        {
                            SessionState.EncounterCounter = 1
                        }
                        else
                        {
                            SessionState.EncounterCounter = ENC_BUILDUP
                            EncounterBuildUp()
                        }
                        break;

                    case ENC_STAGE_BUILDUP:
                        printl( "BUILDUP -> SPAWNING" )
                        if ( SessionState.Debug ) {
                            Utils.SayToAll( "-> ENCOUNTER" )
                        }
                        // times out after X seconds, even if nothing actually spawned
                        SessionState.EncounterCounter = ENC_SPAWNING_TIMEOUT
                        SessionState.CurrentStage = ENC_STAGE_SPAWNING
                        SessionState.EncounterActive = true

                        SessionState.CurrentEncounter = RandomInt( ENC_FIRST, ENC_LAST )

                        // do the encounter!
                        switch( SessionState.CurrentEncounter )
                        {
                            case ENC_HUNTERS:
                                printl( "encounter: hunters" )
                                DoEncounter_Hunters()
                                break;

                            case ENC_JOCKEYS:
                                printl( "encounter: jockeys" )
                                DoEncounter_Jockeys()
                                break;

                            case ENC_CHARGESPIT:
                                printl( "encounter: chargespit" )
                                DoEncounter_ChargeSpit()
                                break;

                            case ENC_WITCHES:
                                printl( "witches" )
                                // not a spawning encounter, so pass on through to gracetime
                                DoEncounter_Witches()
                                SessionState.EncounterCounter = ENC_GRACETIME
                                SessionState.CurrentStage = ENC_STAGE_GRACE
                                SessionState.EncounterActive = false
                                break;

                            case ENC_PANICHORDE:
                                printl( "encounter: panic horde" )
                                DoEncounter_PanicHorde()
                                SessionState.EncounterCounter = ENC_GRACETIME_LONG
                                SessionState.CurrentStage = ENC_STAGE_GRACE
                                SessionState.EncounterActive = false
                                break;

                            case ENC_BIGATTACK:
                                printl( "encounter: big attack" )
                                DoEncounter_BigAttack()
                                break;

                            case ENC_SUPPORT:
                                printl( "encounter: support" )
                                DoEncounter_Support()
                                break;

                            case ENC_FALLEN:
                                printl( "encounter: fallen" )
                                DoEncounter_Fallen()
                                SessionState.EncounterCounter = ENC_GRACETIME
                                SessionState.CurrentStage = ENC_STAGE_GRACE
                                SessionState.EncounterActive = false
                                break;
                        }
                        break;

                    case ENC_STAGE_SPAWNING:

                        // only switch to dying if we've spawned enough of our encounter
                        if ( SessionState.CurrentSIAlive < SessionState.EncounterSpawnCount )
                        {
                            if ( SessionState.Debug ) {
                                Utils.SayToAll( "-> not switching to DYING yet, still waiting for "+ SessionState.EncounterSpawnCount +" more SI to spawn (attempting to force)" )
                            }
                            ForceEncounterSpawns( SessionState.CurrentEncounter )
                            SessionState.EncounterCounter = ENC_SPAWNING_TIMEOUT
                        }
                        else
                        {
                            printl( "SPAWNING -> DYING" )
                            if ( SessionState.Debug ) {
                                Utils.SayToAll( "-> DYING (encounter spawns: "+ SessionState.EncounterDeathCount +")" )
                            }

                            SessionState.CurrentStage = ENC_STAGE_DYING
                            EncounterResetToNothing()

                            if ( SessionState.EncounterDeathCount == 0 )
                            {
                                // if nothing needs to die, pass straight on to GRACE
                                SessionState.EncounterCounter = 1
                            }
                            else
                            {
                                SessionState.EncounterCounter = ENC_ENCOUNTER_TIMEOUT
                            }
                        }
                        break;

                    case ENC_STAGE_DYING:
                        printl( "DYING -> GRACE" )
                        if ( SessionState.Debug ) {
                            Utils.SayToAll( "-> GRACE" )
                        }
                        SessionState.EncounterCounter = ENC_GRACETIME
                        SessionState.CurrentStage = ENC_STAGE_GRACE
                        SessionState.EncounterActive = false
                        break;

                    case ENC_STAGE_GRACE:
                        printl( "GRACE -> NORMAL" )
                        if ( SessionState.Debug ) {
                            Utils.SayToAll( "-> NORMAL" )
                        }
                        SessionState.EncounterCounter = RandomInt( ENC_INTERVALMIN, ENC_INTERVALMAX ) + SessionState.EncounterDiffDelay
                        SessionState.CurrentStage = ENC_STAGE_NORMAL
                        EncounterResetToNormal()
                        break;
                }

            }
        }
    }
}

//--------------------------------------------------------------------------------------------
//  Spawn tracking
//--------------------------------------------------------------------------------------------

function Notifications::OnSpawn::PlayerInfectedSpawned ( player, params )
{
    if (!player.IsEntityValid() || ! player.IsPlayer() || !player.IsPlayerEntityValid()) {
        return
    }

    if ( player.GetTeam() == INFECTED )
    {
        //player.GetPlayerType() == HUNTER
        //printl( "player infected spawned: "+ player.GetPlayerType() )
        SessionState.CurrentSIAlive++

        if ( SessionState.CurrentStage == ENC_STAGE_SPAWNING )
        {
            // encounterspawncount = how many we still expect.. count it down to mark them
            SessionState.EncounterSpawnCount--
            // mark up how many we expect still to die, before encounter is naturally over
            SessionState.EncounterDeathCount++

            // if we have enough, stop the event
            if ( SessionState.EncounterSpawnCount <= 0 )
            {
                printl( "full encounter number has spawned." )
                if ( SessionState.Debug ) {
                    Utils.SayToAll( "ALL SPAWNED" )
                }
                // allow next update to start next stage
                SessionState.EncounterCounter = 1
            }
        }
    }
}


function Notifications::OnDeath::PlayerInfectedDied ( victim, attacker, params )
{
    if (!victim.IsEntityValid() || ! victim.IsPlayer() || !victim.IsPlayerEntityValid()) {
        return
    }

    if ( victim.GetTeam() == INFECTED )
    {
        if ( SessionState.CurrentSIAlive < 0 ) { SessionState.CurrentSIAlive = 0 }
        SessionState.CurrentSIAlive--

        //printl( "player infected died: "+ victim.GetPlayerType() )

        if ( SessionState.EncounterActive )
        {
            SessionState.EncounterSpawnCount--
            SessionState.EncounterDeathCount--

            // if all encounter-infected have died, we're back to normal
            if ( SessionState.CurrentStage == ENC_STAGE_DYING && SessionState.EncounterDeathCount <= 0 && SessionState.EncounterCounter > 1 )
            {
                printl( "full encounter number has been killed." )
                if ( SessionState.Debug ) {
                    Utils.SayToAll( "ALL KILLED" )
                }
                // bypass timeout, the encounter is over
                SessionState.EncounterCounter = 1
            }
        }
    }
}

//--------------------------------------------------------------------------------------------
//  Encounters
//--------------------------------------------------------------------------------------------

// set when next encounter should take place
function EncounterPrepareNext()
{
    //SessionState.NextBuildUp = SessionState._EncounterDurationBuildUp
    //SessionState.NextEncounter = SessionState.NextBuildUp + RandomInt( SessionState._EncounterIntervalMin, SessionState._EncounterIntervalMax )
    //printl( ".. encounter prepared (in "+ SessionState.NextEncounter +"s)." )
}

// this is run X seconds before an encounter is to take place (makes it more likely that we have enough open spawns)
function EncounterBuildUp()
{
    //printl( ".. encounter buildup (no spawns)." )
    SessionOptions.BoomerLimit <- 12;
    SessionOptions.SmokerLimit <- 12;
    SessionOptions.HunterLimit <- 12;
    SessionOptions.ChargerLimit <- 12;
    SessionOptions.SpitterLimit <- 12;
    SessionOptions.JockeyLimit <- 12;
    SessionOptions.MaxSpecials <- 0;
    SessionOptions.DominatorLimit <- 0;
    SessionOptions.SpecialRespawnInterval <- 1.0;
}

// this is run while an encounter is running and all the infected have spawned (block further spawns)
function EncounterResetToNothing()
{
    //printl( ".. encounter status quo (no new spawns)." )
    SessionOptions.BoomerLimit <- 0;
    SessionOptions.SmokerLimit <- 0;
    SessionOptions.HunterLimit <- 0;
    SessionOptions.ChargerLimit <- 0;
    SessionOptions.SpitterLimit <- 0;
    SessionOptions.JockeyLimit <- 0;
    SessionOptions.MaxSpecials <- 0;
    SessionOptions.DominatorLimit <- 0;
    SessionOptions.SpecialRespawnInterval <- 1.0;
}

// this is run after an encounter is (fully) over
function EncounterResetToNormal()
{
    //printl( ".. no encounter, return to normal." )
    SessionOptions.BoomerLimit <- 1;
    SessionOptions.SmokerLimit <- 3;
    SessionOptions.HunterLimit <- 4;
    SessionOptions.ChargerLimit <- 3;
    SessionOptions.SpitterLimit <- 2;
    SessionOptions.JockeyLimit <- 3;
    SessionOptions.MaxSpecials <- 8;
    SessionOptions.DominatorLimit <- 5;
    SessionOptions.SpecialRespawnInterval <- 10.0;
}


// actual encounters!
function DoEncounter_Hunters()
{
    SessionState.EncounterDeathCount = SessionState.CurrentSIAlive
    local spawns = RandomInt( ENC_HUNTER_MIN, ENC_HUNTER_MAX )
    SessionState.EncounterSpawnCount <- spawns
    SessionOptions.BoomerLimit <- 0;
    SessionOptions.SmokerLimit <- 0;
    SessionOptions.HunterLimit <- spawns;
    SessionOptions.ChargerLimit <- 0;
    SessionOptions.SpitterLimit <- 0;
    SessionOptions.JockeyLimit <- 0;
    SessionOptions.MaxSpecials <- spawns;
    SessionOptions.DominatorLimit <- spawns;
    SessionOptions.SpecialRespawnInterval <- 1.0;

    if ( SessionState.Debug ) {
        Utils.SayToAll( " .. Hunters: "+ SessionState.EncounterSpawnCount )
    }
}

function DoEncounter_Jockeys()
{
    SessionState.EncounterDeathCount = SessionState.CurrentSIAlive
    local spawns = RandomInt( ENC_JOCKEY_MIN, ENC_JOCKEY_MAX )
    SessionState.EncounterSpawnCount <- spawns
    SessionOptions.BoomerLimit <- 0;
    SessionOptions.SmokerLimit <- 0;
    SessionOptions.HunterLimit <- 0;
    SessionOptions.ChargerLimit <- 0;
    SessionOptions.SpitterLimit <- 0;
    SessionOptions.JockeyLimit <- spawns;
    SessionOptions.MaxSpecials <- spawns;
    SessionOptions.DominatorLimit <- spawns;
    SessionOptions.SpecialRespawnInterval <- 1.0;

    if ( SessionState.Debug ) {
        Utils.SayToAll( " .. Jockeys: "+ SessionState.EncounterSpawnCount )
    }
}

function DoEncounter_ChargeSpit()
{
    SessionState.EncounterDeathCount = SessionState.CurrentSIAlive
    SessionState.EncounterSpawnCount = 8
    SessionOptions.MaxSpecials <- 8;
    SessionOptions.DominatorLimit <- 4;
    SessionOptions.BoomerLimit <- 0;
    SessionOptions.SmokerLimit <- 0;
    SessionOptions.HunterLimit <- 0;
    SessionOptions.ChargerLimit <- 4;
    SessionOptions.SpitterLimit <- 2;
    SessionOptions.JockeyLimit <- 0;
    SessionOptions.SpecialRespawnInterval <- 1.0;

    if ( SessionState.Debug ) {
        Utils.SayToAll( " .. Charge-Spit: "+ SessionState.EncounterSpawnCount )
    }
}

function DoEncounter_Witches()
{
    SessionState.EncounterSpawnCount <- RandomInt( ENC_WITCH_MIN, ENC_WITCH_MAX )

    // witches = 7
    ComTimerA1.Input( "Enable" )
    ComTimerA2.Input( "Enable" )
    ComTimerA4.Input( "Enable" )

    if ( SessionState.EncounterSpawnCount & 1 ) { ComTimerB1.Input( "Enable" ) }
    if ( SessionState.EncounterSpawnCount & 2 ) { ComTimerB2.Input( "Enable" ) }
    if ( SessionState.EncounterSpawnCount & 4 ) { ComTimerB4.Input( "Enable" ) }
    if ( SessionState.EncounterSpawnCount & 8 ) { ComTimerB8.Input( "Enable" ) }

    if ( SessionState.Debug ) {
        Utils.SayToAll( " .. Witches [through plugin]: "+ SessionState.EncounterSpawnCount )
    }
}


function DoEncounter_PanicHorde()
{
    //Director.PlayMegaMobWarningSounds()
    Utils.ForcePanicEvent()

    if ( SessionState.Debug ) {
        Utils.SayToAll( " .. Horde." )
    }
}

function DoEncounter_BigAttack()
{
    // just a huge attack with some 'balance'
    SessionState.EncounterDeathCount = SessionState.CurrentSIAlive
    SessionState.EncounterSpawnCount <- 12
    SessionOptions.BoomerLimit <- 1;
    SessionOptions.SmokerLimit <- 2;
    SessionOptions.HunterLimit <- 3;
    SessionOptions.ChargerLimit <- 3;
    SessionOptions.SpitterLimit <- 1;
    SessionOptions.JockeyLimit <- 2;
    SessionOptions.MaxSpecials <- 12;
    SessionOptions.DominatorLimit <- 12;
    SessionOptions.SpecialRespawnInterval <- 1.0;

    if ( SessionState.Debug ) {
        Utils.SayToAll( " .. Big Attack: "+ SessionState.EncounterSpawnCount )
    }
}

function DoEncounter_Support()
{
    SessionState.EncounterDeathCount = SessionState.CurrentSIAlive
    local spawns = RandomInt( ENC_SUPPORT_MIN, ENC_SUPPORT_MAX )
    SessionState.EncounterSpawnCount <- spawns
    SessionOptions.BoomerLimit <- spawns;
    SessionOptions.SmokerLimit <- 0;
    SessionOptions.HunterLimit <- 0;
    SessionOptions.ChargerLimit <- 0;
    SessionOptions.SpitterLimit <- spawns;
    SessionOptions.JockeyLimit <- 0;
    SessionOptions.MaxSpecials <- spawns;
    SessionOptions.DominatorLimit <- 0;
    SessionOptions.SpecialRespawnInterval <- 1.0;

    if ( SessionState.Debug ) {
        Utils.SayToAll( " .. Support: "+ SessionState.EncounterSpawnCount )
    }
}

function DoEncounter_Fallen()
{
    SessionState.EncounterSpawnCount <- RandomInt( ENC_FALLEN_MIN, ENC_FALLEN_MAX )

    // fallen = 6
    ComTimerA2.Input( "Enable" )
    ComTimerA4.Input( "Enable" )

    if ( SessionState.EncounterSpawnCount & 1 ) { ComTimerB1.Input( "Enable" ) }
    if ( SessionState.EncounterSpawnCount & 2 ) { ComTimerB2.Input( "Enable" ) }
    if ( SessionState.EncounterSpawnCount & 4 ) { ComTimerB4.Input( "Enable" ) }
    if ( SessionState.EncounterSpawnCount & 8 ) { ComTimerB8.Input( "Enable" ) }

    if ( SessionState.Debug ) {
        Utils.SayToAll( " .. Fallen Survivors [through plugin]: "+ SessionState.EncounterSpawnCount )
    }
}



function ForceEncounterSpawns ( type )
{
    // tell plugin through timers what we want
    switch ( type )
    {
        case ENC_HUNTERS:
            // hunters = 1
            ComTimerA1.Input( "Enable" )
            break;

        case ENC_JOCKEYS:
            // jockeys = 2
            ComTimerA2.Input( "Enable" )
            break;

        case ENC_CHARGESPIT:
            // chargespit = 3
            ComTimerA1.Input( "Enable" )
            ComTimerA2.Input( "Enable" )
            break;

        case ENC_SUPPORT:
            // support = 4
            ComTimerA4.Input( "Enable" )
            break;

        case ENC_BIGATTACK:
            // big attack = 5
            ComTimerA1.Input( "Enable" )
            ComTimerA4.Input( "Enable" )
            break;

    }

    // send amount desired
    if ( SessionState.EncounterSpawnCount & 1 ) { ComTimerB1.Input( "Enable" ) }
    if ( SessionState.EncounterSpawnCount & 2 ) { ComTimerB2.Input( "Enable" ) }
    if ( SessionState.EncounterSpawnCount & 4 ) { ComTimerB4.Input( "Enable" ) }
    if ( SessionState.EncounterSpawnCount & 8 ) { ComTimerB8.Input( "Enable" ) }

    if ( SessionState.Debug ) {
        Utils.SayToAll( " .... Attempting to force spawns for encounter [through plugin]: "+ SessionState.EncounterSpawnCount )
    }
}

//--------------------------------------------------------------------------------------------
//  Difficulty
//--------------------------------------------------------------------------------------------

function ChatTriggers::rndmut_diff ( player, args, text )
{
    // toggle debug state
    switch ( SessionState.CurrentDifficulty )
    {
        case SessionState.ENC_VERYHARD:
            Utils.SayToAll( "Random Coop Mutation: HARD Difficulty Set" )
            SessionState.CurrentDifficulty = 2
            SessionState.EncounterDiffDelay = SessionState.ENC_DIFF_STAGE_HARD
            SessionOptions.CommonLimit = SessionState.ENC_DIFF_CI_HARD
            break;

        case SessionState.ENC_HARD:
            Utils.SayToAll( "Random Coop Mutation: MEDIUM Difficulty Set" )
            SessionState.CurrentDifficulty = 3
            SessionState.EncounterDiffDelay = SessionState.ENC_DIFF_STAGE_MEDIUM
            SessionOptions.CommonLimit = SessionState.ENC_DIFF_CI_MEDIUM
            break;

        case SessionState.ENC_MEDIUM:
            Utils.SayToAll( "Random Coop Mutation: EASY Difficulty Set" )
            SessionState.CurrentDifficulty = 4
            SessionState.EncounterDiffDelay = SessionState.ENC_DIFF_STAGE_EASY
            SessionOptions.CommonLimit = SessionState.ENC_DIFF_CI_EASY
            break;

        case SessionState.ENC_EASY:
            Utils.SayToAll( "Random Coop Mutation: VERY HARD Difficulty Set" )
            SessionState.CurrentDifficulty = 1
            SessionState.EncounterDiffDelay = SessionState.ENC_DIFF_STAGE_VERYHARD
            SessionOptions.CommonLimit = SessionState.ENC_DIFF_CI_VERYHARD
            break;
    }
}

//--------------------------------------------------------------------------------------------
//  Debug
//--------------------------------------------------------------------------------------------

function ChatTriggers::rndmut_debug ( player, args, text )
{
    // toggle debug state
    if ( SessionState.Debug ) {
        Utils.SayToAll( "Random Coop Mutation: Debug Prints Disabled" )
        SessionState.Debug = false
    } else {
        Utils.SayToAll( "Random Coop Mutation: Debug Prints Enabled" )
        SessionState.Debug = true
    }
}

function ChatTriggers::rndmut_pause ( player, args, text )
{
    // toggle pause
    if ( SessionState.Paused ) {
        Utils.SayToAll( "Random Coop Mutation: Unpaused" )
        SessionState.Paused = false
    } else {
        Utils.SayToAll( "Random Coop Mutation: Paused" )
        SessionState.Paused = true
    }
}
