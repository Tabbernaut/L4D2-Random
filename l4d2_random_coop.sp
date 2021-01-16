#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define USE_OLD_SPAWN       true            // use z_spawn_old ?

#define FALLEN_MODEL        "models/infected/common_male_fallen_survivor.mdl"

/*
    Make coop more RANDOM FUN.

    Most of the work is now done by the mutationrandomcoop.nut script
    This plugin should help with a few things that vscript can't do well

    - spawn witches
    - force spawns when the director has fallen asleep?
    - spawn special hordes, such as fallen survivors (or other?)
 */

const           TEAM_SPECTATOR          = 1;
const           TEAM_SURVIVOR           = 2;
const           TEAM_INFECTED           = 3;

const           LTIMER_ENABLED          = 0;
const           LTIMER_DISABLED         = 1;

const           ZC_SMOKER               = 1;
const           ZC_BOOMER               = 2;
const           ZC_HUNTER               = 3;
const           ZC_SPITTER              = 4;
const           ZC_JOCKEY               = 5;
const           ZC_CHARGER              = 6;
const           ZC_WITCH                = 7;
const           ZC_TANK                 = 8;
const           ZC_NOTINFECTED          = 9;
const           ZC_TOTAL                = 7;

const           ENC_HUNTERS             = 1;
const           ENC_JOCKEYS             = 2;
const           ENC_CHARGESPIT          = 3;
const           ENC_SUPPORT             = 4;
const           ENC_BIGATTACK           = 5;
const           ENC_FALLEN              = 6;
const           ENC_WITCHES             = 7;

const Float:    SPAWN_VARY_MAX          = 0.5;      // how much variation between SI/witches spawns, maximum (min = 0.0)


new     bool:           g_bLogicTimerEntSet                                 = false;                // whether we can trust the logic timers
new                     g_iLogicTimerEntEncounter[3];
new                     g_iLogicTimerEntAmount[4];

new                     g_iRemainingFallen                                  = 0;                    // how many fallen survivors to spawn

new     Handle:         g_hCvarDebug                                        = INVALID_HANDLE;

new     Handle:         g_hCvarFallenChance                                 = INVALID_HANDLE;



public Plugin:myinfo =
{
    name = "Randomize the Game - Coop Stuff",
    author = "Tabun",
    description = "Makes L4D2 more fun and harder in coop mode.",
    version = "0.9.3",
    url = "https://github.com/Tabbernaut/L4D2-Random"
}

public OnPluginStart()
{
    // cvars
    g_hCvarDebug = CreateConVar("rand_debug_coop", "2",
        "Random debug mode (coop plugin). (0: only error reporting, -1: disable all reports, 1+: set debug report level)",
        FCVAR_NONE, true, -1.0, true, 5.0);

    g_hCvarFallenChance = FindConVar("rand_fallen_chance");

    // prepare weights
    //PrepareChoicesEncounters();

    // precache fallen
    PrecacheModel(FALLEN_MODEL, true);

    // start timer
    CreateTimer(1.0, Timer_CheckLogicTimer, _, TIMER_REPEAT);
}



public Action: Timer_CheckLogicTimer (Handle:timer)
{
    if (
        g_bLogicTimerEntSet
        && (g_iLogicTimerEntEncounter[0] == 0 || ! IsValidEntity(g_iLogicTimerEntEncounter[0]))
    ) {
        g_bLogicTimerEntSet = false;
    }

    // find the timers
    if (! g_bLogicTimerEntSet) {
        // find entity
        decl String: sName[24];
        new ent = -1;

        while ((ent = FindEntityByClassname(ent, "logic_timer")) != -1) {
            GetEntPropString(ent, Prop_Data, "m_iName", sName, sizeof(sName));

            if (StrEqual( sName, "random_coop_timer_a_1")) {
                g_iLogicTimerEntEncounter[0] = ent;
            } else if ( StrEqual(sName, "random_coop_timer_a_2")) {
                g_iLogicTimerEntEncounter[1] = ent;
            } else if ( StrEqual(sName, "random_coop_timer_a_4")) {
                g_iLogicTimerEntEncounter[2] = ent;
            } else if ( StrEqual(sName, "random_coop_timer_b_1")) {
                g_iLogicTimerEntAmount[0] = ent;
            } else if ( StrEqual(sName, "random_coop_timer_b_2")) {
                g_iLogicTimerEntAmount[1] = ent;
            } else if ( StrEqual(sName, "random_coop_timer_b_4")) {
                g_iLogicTimerEntAmount[2] = ent;
            } else if ( StrEqual(sName, "random_coop_timer_b_8")) {
                g_iLogicTimerEntAmount[3] = ent;
            }
        }

        if (g_iLogicTimerEntEncounter[0] != 0 && IsValidEntity( g_iLogicTimerEntEncounter[0])) {
            PrintDebug( 0, "[rndcoop] Found timers: %i", g_iLogicTimerEntEncounter[0] );
            g_bLogicTimerEntSet = true;

        }
    }

    if (! g_bLogicTimerEntSet ) {
        return Plugin_Continue;
    }

    // vscript is trying to tell us something if anything but 0
    new iEncounterValue = (
        ((GetEntProp(g_iLogicTimerEntEncounter[0], Prop_Data, "m_iDisabled") == LTIMER_ENABLED) ? 1 : 0)
        * 1
    ) +
    (
        ((GetEntProp(g_iLogicTimerEntEncounter[1], Prop_Data, "m_iDisabled" ) == LTIMER_ENABLED) ? 1 : 0)
        * 2
    ) +
    (
        ((GetEntProp(g_iLogicTimerEntEncounter[2], Prop_Data, "m_iDisabled" ) == LTIMER_ENABLED) ? 1 : 0)
        * 4
    );

    if (iEncounterValue > 0) {

        new iAmountValue = (
            ((GetEntProp( g_iLogicTimerEntAmount[0], Prop_Data, "m_iDisabled" ) == LTIMER_ENABLED) ? 1 : 0 ) * 1
        ) +
        (
            ((GetEntProp( g_iLogicTimerEntAmount[1], Prop_Data, "m_iDisabled" ) == LTIMER_ENABLED) ? 1 : 0 ) * 2
        ) +
        (
            ((GetEntProp( g_iLogicTimerEntAmount[2], Prop_Data, "m_iDisabled" ) == LTIMER_ENABLED) ? 1 : 0 ) * 4
        ) +
        (
            ((GetEntProp( g_iLogicTimerEntAmount[3], Prop_Data, "m_iDisabled" ) == LTIMER_ENABLED) ? 1 : 0 ) * 8
        );

        if ( iAmountValue > 0 )
        {
            PrintDebug( 0, "[rndcoop] Status of timer: %i (amount: %i)", iEncounterValue, iAmountValue );

            switch ( iEncounterValue )
            {
                case ENC_HUNTERS: {
                    for ( new i = 0; i < iAmountValue; i++ )
                    {
                        CreateTimer( GetRandomFloat( 0.0, SPAWN_VARY_MAX ), Timer_SpawnSomething, ZC_HUNTER, TIMER_FLAG_NO_MAPCHANGE );
                    }
                }
                case ENC_JOCKEYS: {
                    for ( new i = 0; i < iAmountValue; i++ )
                    {
                        CreateTimer( GetRandomFloat( 0.0, SPAWN_VARY_MAX ), Timer_SpawnSomething, ZC_JOCKEY, TIMER_FLAG_NO_MAPCHANGE );
                    }
                }
                case ENC_CHARGESPIT: {
                    for ( new i = 0; i < iAmountValue; i++ )
                    {
                        CreateTimer( GetRandomFloat( 0.0, SPAWN_VARY_MAX ), Timer_SpawnSomething, (GetRandomInt(0,2)) ? ZC_CHARGER : ZC_SPITTER, TIMER_FLAG_NO_MAPCHANGE );
                    }
                }
                case ENC_SUPPORT: {
                    for ( new i = 0; i < iAmountValue; i++ )
                    {
                        CreateTimer( GetRandomFloat( 0.0, SPAWN_VARY_MAX ), Timer_SpawnSomething, (GetRandomInt(0,1)) ? ZC_BOOMER : ZC_SPITTER, TIMER_FLAG_NO_MAPCHANGE );
                    }
                }
                case ENC_BIGATTACK: {
                    for ( new i = 0; i < iAmountValue; i++ )
                    {
                        CreateTimer( GetRandomFloat( 0.0, SPAWN_VARY_MAX ), Timer_SpawnSomething, GetRandomInt(ZC_SMOKER, ZC_CHARGER), TIMER_FLAG_NO_MAPCHANGE );
                    }
                }
                case ENC_FALLEN: {
                    // spawn some commons => fallen
                    new spawningclient = GetSpawningClient(true);
                    g_iRemainingFallen = iAmountValue;
                    if ( IsClientAndInGame(spawningclient) ) {
                        SpawnCommon( spawningclient, iAmountValue );
                    }
                }
                case ENC_WITCHES: {
                    for ( new i = 0; i < iAmountValue; i++ )
                    {
                        CreateTimer( GetRandomFloat( 0.0, SPAWN_VARY_MAX ), Timer_SpawnSomething, ZC_WITCH, TIMER_FLAG_NO_MAPCHANGE );
                    }
                }
            }

        }

        // reset all timers back to 0
        AcceptEntityInput( g_iLogicTimerEntEncounter[0], "Disable" );
        AcceptEntityInput( g_iLogicTimerEntEncounter[1], "Disable" );
        AcceptEntityInput( g_iLogicTimerEntEncounter[2], "Disable" );
        AcceptEntityInput( g_iLogicTimerEntAmount[0], "Disable" );
        AcceptEntityInput( g_iLogicTimerEntAmount[1], "Disable" );
        AcceptEntityInput( g_iLogicTimerEntAmount[2], "Disable" );
        AcceptEntityInput( g_iLogicTimerEntAmount[3], "Disable" );
    }

    return Plugin_Continue;
}

public Action: Timer_SpawnSomething (Handle:timer, any:what)
{
    // relay to spawn function
    new client = GetSpawningClient(true);

    PrintDebug( 3, "[rand-coop] Spawning... client: %i.", client );

    if ( !IsClientAndInGame( client ) ) { return Plugin_Continue; }

    PrintDebug( 3, "[rand-coop] Spawning something: %i.", what );

    switch ( what )
    {
        case ZC_SMOKER: { SpawnSpecial( client, what ); }
        case ZC_BOOMER: { SpawnSpecial( client, what ); }
        case ZC_HUNTER: { SpawnSpecial( client, what ); }
        case ZC_SPITTER: { SpawnSpecial( client, what ); }
        case ZC_JOCKEY: { SpawnSpecial( client, what ); }
        case ZC_CHARGER: { SpawnSpecial( client, what ); }

        case ZC_WITCH:  { SpawnWitch(client); }
        //case ZC_TANK:  { SpawnTank(client); }
    }

    return Plugin_Continue;
}


public OnEntityCreated(entity, const String:classname[])
{
	if ( !StrEqual(classname, "infected", false)) { return; }

	if ( g_iRemainingFallen )
    {
        g_iRemainingFallen--;
        SetEntityModel(entity, FALLEN_MODEL);
	}
}

//  General functions
//  ------------------------------

public PrintDebug(debugLevel, const String:Message[], any:...)
{
    if (debugLevel <= GetConVarInt(g_hCvarDebug))
    {
        decl String:DebugBuff[256];
        VFormat(DebugBuff, sizeof(DebugBuff), Message, 3);
        LogMessage(DebugBuff);
        PrintToServer(DebugBuff);
    }
}

bool: IsClientAndInGame(index) return (index > 0 && index <= MaxClients && IsClientInGame(index));
bool: IsSurvivor(client) {
    if (IsClientAndInGame(client)) { return GetClientTeam(client) == TEAM_SURVIVOR; }
    return false;
}
bool: IsInfected(client) {
    if (IsClientAndInGame(client)) { return GetClientTeam(client) == TEAM_INFECTED; }
    return false;
}

// get just any survivor client (param = false = switch to infected too)
GetSpawningClient ( bool:onlySurvivors=false )
{
    for (new i = 1; i <= MaxClients; i++) {
        if (IsClientConnected(i) && IsSurvivor(i) && !IsFakeClient(i) ) {
            return i;
        }
    }

    if (onlySurvivors) {
        return 0;
    }

    // since we're just using this for spawning stuff that requires a client, use infected alternatively
    for (new i = 1; i <= MaxClients; i++) {
        if (IsClientConnected(i) && IsInfected(i) && !IsFakeClient(i)) {
            return i;
        }
    }

    // no usable clients...
    return 0;
}


//  Spawning infected
//  ------------------

// spawning a zombie (cheap way :()
SpawnCommon(client, mobs = 1)
{
    if (USE_OLD_SPAWN) {
        new flags = GetCommandFlags("z_spawn_old");
        SetCommandFlags("z_spawn_old", flags & ~FCVAR_CHEAT);
        for(new i=0; i < mobs; i++) {
            FakeClientCommand(client, "z_spawn_old infected auto");
        }
        SetCommandFlags("z_spawn_old", flags);
    } else {
        new flags = GetCommandFlags("z_spawn");
        SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);
        for (new i = 0; i < mobs; i++) {
            FakeClientCommand(client, "z_spawn infected auto");
        }
        SetCommandFlags("z_spawn", flags);
    }
}

// spawning a SI
SpawnSpecial(client, siClass)
{
    PrintDebug( 4, "[rand-coop] Spawning something..." );

    if (USE_OLD_SPAWN) {
        new flags = GetCommandFlags("z_spawn_old");
        SetCommandFlags("z_spawn_old", flags & ~FCVAR_CHEAT);
        switch ( siClass ) {
            case ZC_SMOKER: {  FakeClientCommand(client, "z_spawn_old smoker auto"); }
            case ZC_BOOMER: {  FakeClientCommand(client, "z_spawn_old boomer auto"); }
            case ZC_HUNTER: {  FakeClientCommand(client, "z_spawn_old hunter auto"); }
            case ZC_SPITTER: { FakeClientCommand(client, "z_spawn_old spitter auto"); }
            case ZC_JOCKEY: {  FakeClientCommand(client, "z_spawn_old jockey auto"); }
            case ZC_CHARGER: { FakeClientCommand(client, "z_spawn_old charger auto"); }
        }
        SetCommandFlags("z_spawn_old", flags);
    } else {
        new flags = GetCommandFlags("z_spawn");
        SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);
        switch ( siClass ) {
            case ZC_SMOKER: {  FakeClientCommand(client, "z_spawn_old smoker auto"); }
            case ZC_BOOMER: {  FakeClientCommand(client, "z_spawn_old boomer auto"); }
            case ZC_HUNTER: {  FakeClientCommand(client, "z_spawn_old hunter auto"); }
            case ZC_SPITTER: { FakeClientCommand(client, "z_spawn_old spitter auto"); }
            case ZC_JOCKEY: {  FakeClientCommand(client, "z_spawn_old jockey auto"); }
            case ZC_CHARGER: { FakeClientCommand(client, "z_spawn_old charger auto"); }
        }
        SetCommandFlags("z_spawn", flags);
    }
}
// spawning a witch
SpawnWitch(client)
{
    if (USE_OLD_SPAWN) {
        new flags = GetCommandFlags("z_spawn_old");
        SetCommandFlags("z_spawn_old", flags & ~FCVAR_CHEAT);
        FakeClientCommand(client, "z_spawn_old witch auto");
        SetCommandFlags("z_spawn_old", flags);
    } else {
        new flags = GetCommandFlags("z_spawn");
        SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);
        FakeClientCommand(client, "z_spawn witch auto");
        SetCommandFlags("z_spawn", flags);
    }
}

public Action: SpawnFallen(number, Float:location[3])
{
    // Don't spawn a fallen if we shouldn't
    if (GetConVarFloat(g_hCvarFallenChance) < 0.01) {
        return;
    }

	new zombie = CreateEntityByName("infected");

	SetEntityModel(zombie, FALLEN_MODEL);

	new ticktime = RoundToNearest((GetGameTime() / GetTickInterval())) + 5;
	SetEntProp(zombie, Prop_Data, "m_nNextThinkTick", ticktime);

	DispatchSpawn(zombie);
	ActivateEntity(zombie);

	location[2] -= 25.0; //reduce the 'drop' effect
	TeleportEntity( zombie, location, NULL_VECTOR, NULL_VECTOR );
}
