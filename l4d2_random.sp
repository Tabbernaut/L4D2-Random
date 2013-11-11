#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4downtown>
#include <l4d2_direct>
#include <l4d2_random_bonus>
#include <l4d2_penalty_bonus>
#include <l4d2_saferoom_detect>
#undef REQUIRE_PLUGIN
#include <readyup>
#include <pause>
#define REQUIRE_PLUGIN

#include "includes/random_constants.sp"
#include "includes/random_globals.sp"
#include "includes/random_init.sp"
#include "includes/random_random.sp"
#include "includes/random_support_basics.sp"
#include "includes/random_support.sp"
#include "includes/random_support_events.sp"
#include "includes/random_thirdparty.sp"


// note: these must also be defined in includes/random_init
#define FIRE_PARTICLE           "gas_explosion_ground_fire"
#define EXPLOSION_PARTICLE      "FluidExplosion_fps"
#define EXPLOSION_PARTICLE2     "weapon_grenade_explosion"
#define EXPLOSION_PARTICLE3     "explosion_huge_b"
#define BURN_IGNITE_PARTICLE    "fire_small_01"


#define PLUGIN_VERSION "1.0.75"

/*
        L4D2 Random
        -----------
        
        Basic plugin to get some of the freaky randomness going.
        
        randomizes:
            - map items
            - tank hittables
            - survivor starting items
            - survivor starting health
            - map distance and bonus
            - doors (locks a bunch)
            - survivor glows on/off
            - survivor outlines on/off
            - SI spawns / first attack / quads
            - uncommons spawning
            - ammo in weapons lying around
            - special events (various)
            - two-tank rounds (if tank spawns at all) [broken]
            - random item drops by common infected
            - gift boxes and opening results
            - pipebombs (are sometimes duds)
        
        
        Note:
            hittable props with hammerid 1 are always made prop_alarm_cars (to keep events possible)
            hittable props with hammerid 2 are always made 'weak' hittables (tables, handcarts)
        
        equal flags:
        ------------
            1       items (startup & map)
            2       doors
            4       glows
            8       special event
            16      incap count / behaviour
            32      horde [once made available]
            64      item weights (preparechoices())
            128     survivor health (startup value)
            256     first attack (SI setup)
            512     tanks
           1024     points / scoring
 
*/


public Plugin:myinfo = 
{
    name = "Randomize the Game",
    author = "Tabun",
    description = "Makes L4D2 sensibly random. Randomizes items, SI spawns and many other things.",
    version = PLUGIN_VERSION,
    url = "https://github.com/Tabbernaut/L4D2-Random"
}


public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    g_bLateLoad = late;
    
    CreateNative("RNDMAIN_GetGnomeBonus",   Native_GetGnomeBonus);
    CreateNative("RNDMAIN_ShowGnomeBonus",  Native_ShowGnomeBonus);
    
    // depends on the configuration, if no special events are used,
    // we don't need l4d2_penalty_bonus
    MarkNativeAsOptional("PBONUS_GetRoundBonus");
    MarkNativeAsOptional("PBONUS_ReSetRoundBonus");
    MarkNativeAsOptional("PBONUS_SetRoundBonus");
    MarkNativeAsOptional("PBONUS_AddRoundBonus");
    // crox readyup:
    MarkNativeAsOptional("IsInReady");
    
    return APLRes_Success;
}

// crox readyup usage
public OnAllPluginsLoaded()
{
    g_bReadyUpAvailable = LibraryExists("readyup");
    g_bPauseAvailable = LibraryExists("pause");
}

public OnLibraryRemoved(const String:name[])
{
    if ( StrEqual(name, "readyup") ) { g_bReadyUpAvailable = false; }
    if ( StrEqual(name, "pause") ) { g_bPauseAvailable = false; }
}

public OnLibraryAdded(const String:name[])
{
    if ( StrEqual(name, "readyup") ) { g_bReadyUpAvailable = true; }
    if ( StrEqual(name, "pause") ) { g_bPauseAvailable = true; }
    
}

public Native_GetGnomeBonus(Handle:plugin, numParams)
{
    new value = GetGnomeBonus();
    return _:value;
}
public Native_ShowGnomeBonus(Handle:plugin, numParams)
{
    GetGnomeBonus(true); // ignore what it returns, but do printout
}


public OnPluginStart()
{
    // Hooks
    HookEvent("round_start",                Event_RoundStart,               EventHookMode_PostNoCopy);
    HookEvent("round_end",                  Event_RoundEnd,                 EventHookMode_PostNoCopy);
    HookEvent("player_team",                Event_PlayerTeam,               EventHookMode_Post);
    HookEvent("mission_lost",               Event_MissionLostCampaign,      EventHookMode_Post);
    
    HookEvent("player_death",               Event_PlayerDeath,              EventHookMode_Pre);
    HookEvent("player_spawn",               Event_PlayerSpawn,              EventHookMode_Post);
    HookEvent("tank_spawn",                 Event_TankSpawned,              EventHookMode_Post);
    HookEvent("ghost_spawn_time",           Event_GhostSpawnTime,           EventHookMode_Post);
    
    HookEvent("player_now_it",              Event_PlayerBoomed,             EventHookMode_Post);
    HookEvent("player_no_longer_it",        Event_PlayerUnboomed,           EventHookMode_Post);

    HookEvent("player_use",                 Event_PlayerUse,                EventHookMode_Post);
    HookEvent("item_pickup",                Event_ItemPickup,               EventHookMode_Post);
    HookEvent("ammo_pickup",                Event_AmmoPickup,               EventHookMode_Post);
    HookEvent("weapon_drop",                Event_WeaponDrop,               EventHookMode_Post);
    HookEvent("weapon_given",               Event_WeaponGiven,              EventHookMode_Post);    // also works for pills/adren
    HookEvent("weapon_fire",                Event_WeaponFire,               EventHookMode_Post);
    HookEvent("upgrade_pack_added",         Event_SpecialAmmo,              EventHookMode_Post);
    HookEvent("upgrade_pack_begin",         Event_SpecialAmmoDeploy,        EventHookMode_Post);
    HookEvent("defibrillator_used",         Event_PlayerDefibbed,           EventHookMode_Post);
    HookEvent("heal_success",               Event_MedkitUsed,               EventHookMode_Post);
    HookEvent("pills_used",                 Event_PillsUsed,                EventHookMode_Post);
    HookEvent("adrenaline_used",            Event_PillsUsed,                EventHookMode_Post);
    HookEvent("revive_success",             Event_ReviveSuccess,            EventHookMode_Post);
    
    HookEvent("player_incapacitated_start", Event_IncapStart,               EventHookMode_Post);
    
    HookEvent("witch_harasser_set",         Event_WitchHarasserSet,         EventHookMode_Post);
    HookEvent("witch_killed",               Event_WitchDeath,               EventHookMode_Post);
    
    
    // version convar
    CreateConVar("rand_version", PLUGIN_VERSION, "Random plugin version.", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);

    // default convars
    g_hCvarTeamSize = FindConVar("survivor_limit");
    g_bStripperPresent = (FindConVar("stripper_cfg_path") != INVALID_HANDLE);

    // do general init
    INIT_PrepareAllSDKCalls();
    INIT_DefineCVars();
    INIT_FillTries();
    INIT_PrecacheModels(true);
    
    // prepare client array
    g_hSteamIds = CreateArray(32);
    
    // Unset home-grown storm cvar, to be sure
    new Handle: hTmpStormCVar = FindConVar("l4d2_storm_fogmode");
    if (hTmpStormCVar != INVALID_HANDLE) { SetConVarInt(hTmpStormCVar, 0); }
    
    // hooks
    if (g_bLateLoad)
    {
        // for testing, basically
        g_bPlayersLeftStart = true;
        
        for (new i=1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i))
            {
                SDKHook(i, SDKHook_WeaponCanUse,    OnWeaponCanUse);    // hook for t2 nerfing
                SDKHook(i, SDKHook_WeaponEquipPost, OnWeaponEquip);     // hook for penalty item tracking
                SDKHook(i, SDKHook_OnTakeDamage,    OnTakeDamage);      // hook for tank damage mod & protect event
            }
        }
    }

    // Commands
    RegConsoleCmd("sm_info",        RandomHelp_Cmd,         "Show some Random help information.");
    RegConsoleCmd("sm_random",      RandomHelp_Cmd,         "Show some Random help information.");
    RegConsoleCmd("sm_rnd",         RandomReport_Cmd,       "Report what special randomness is currently active.");
    RegConsoleCmd("sm_rand",        RandomReport_Cmd,       "Report what special randomness is currently active.");
    RegConsoleCmd("sm_bonus",       RandomBonus_Cmd,        "Report the special current round bonus (or penalty).");
    RegConsoleCmd("sm_penalty",     RandomBonus_Cmd,        "Report the special current round bonus (or penalty).");
    RegConsoleCmd("sm_drop",        RandomDrop_Cmd,         "Drop your currently selected weapon or item.");
    RegConsoleCmd("sm_eventinfo",   RandomEventInfo_Cmd,    "Show information about the current event. Add number to get information for the event with that number (use number in list on website).");
    
    RegConsoleCmd("sm_event",       RandomPickEvent_Cmd,    "Vote for a special event to appear next round (use number in list on website).");
    RegConsoleCmd("sm_gameevent",   RandomPickGameEvent_Cmd, "Vote for a special event for all rounds (use number in list on website).");
    
    RegConsoleCmd("sm_rerandom",    RandomCoopRerandom_Cmd, "Force a re-randomization of this round, if the survivors fail.");
    
    // Admin and test commands
    RegAdminCmd("forceevent",        RandomForcePickEvent_Cmd,      ADMFLAG_CHEATS, "Force a special event for next round (use number in list on website).");
    RegAdminCmd("forcegameevent",    RandomForcePickGameEvent_Cmd,  ADMFLAG_CHEATS, "Force a special event for all rounds (use number in list on website).");
    
    // disable when debugging is done
    #if DEBUG_MODE
        RegAdminCmd("rand_test_gnomes", TestGnomes_Cmd, ADMFLAG_CHEATS, "...");
        RegAdminCmd("rand_test_swap",   TestSwap_Cmd,   ADMFLAG_CHEATS, "...");
        RegAdminCmd("rand_test_ents",   TestEnts_Cmd,   ADMFLAG_CHEATS, "...");
        RegAdminCmd("rand_test_event",  TestEvent_Cmd,  ADMFLAG_CHEATS, "...");
        // vocalize test
        RegAdminCmd("sm_voc", Cmd_Vocalize_Random, ADMFLAG_CHEATS, "...");
        RegAdminCmd("sm_voc_this", Cmd_Vocalize_Specified, ADMFLAG_CHEATS, "...");
    #endif
    
    // Listen for specating
    RegConsoleCmd("spectate",   Spectate_Cmd,   "...");
    RegConsoleCmd("say",        Say_Cmd,        "...");
    RegConsoleCmd("say_team",   Say_Cmd,        "...");
    
    // Listen for pausing & unpausing
    RegConsoleCmd("unpause",    Unpause_Cmd,    "...");
    AddCommandListener(Listener_Pause, "pause");
    AddCommandListener(Listener_Pause, "set_pause");
    
    // Blind infected
    g_hBlockedEntities = CreateArray(_:EntInfo);
    CreateTimer(BLND_ENT_CHECK_INTERVAL, Timer_EntCheck, _, TIMER_REPEAT);
    
    // Do first randomization to prevent errors
    RANDOM_PrepareChoicesSpawns();
    RANDOM_PrepareChoicesGiftEffects();
    
    // load KeyValues
    RI_KV_Load();                   // get RandomMap info (cvar now set to right dir)
    RConfig_Read();                 // get basic random config values (for 'constants')
}


#if DEBUG_MODE
/*
    START TEST

    Testing vocalize stuff AtomicStryker
*/
public Action:Cmd_Vocalize_Random(client, args)
{
    if (!client || !args || !IsClientInGame(client))
    {
        ReplyToCommand(client, "Must be Ingame for command to work, and dont forget the argument");
        return Plugin_Handled;
    }
    
    decl String:arg[256];
    GetCmdArg(1, arg, sizeof(arg));
    
    PrintToChatAll("SM Vocalize caught by %N, command: %s", client, arg);
    
    // STEP 1: FIGURE OUT WHICH SURVIVOR WERE DEALING WITH
    
    decl String:model[256];
    GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
    
    if (StrContains(model, "gambler") != -1) { FormatEx(model, sizeof(model), "gambler"); }
    else if (StrContains(model, "coach") != -1) { FormatEx(model, sizeof(model), "coach"); }
    else if (StrContains(model, "mechanic") != -1) { FormatEx(model, sizeof(model), "mechanic"); }
    else if (StrContains(model, "producer") != -1) { FormatEx(model, sizeof(model), "producer"); }
    else if (StrContains(model, "namvet") != -1) { FormatEx(model, sizeof(model), "namvet"); }
    else if (StrContains(model, "teengirl") != -1) { FormatEx(model, sizeof(model), "teengirl"); }
    else if (StrContains(model, "biker") != -1) { FormatEx(model, sizeof(model), "biker"); }
    else if (StrContains(model, "manager") != -1) { FormatEx(model, sizeof(model), "manager"); }
    
    // STEP 2: SCAN SCENES FOLDER WITH VOCALIZE ARGUMENT AND NUMBERS FOR FILES
    
    decl String:scenefile[256], String:checknumber[3];
    new foundfilescounter;
    decl validfiles[71];
    
    for (new i = 1; i <= 70; i++)
    {
        if (i < 10)
        {
            FormatEx(checknumber, sizeof(checknumber), "0%i", i);
        }
        else
        {
            FormatEx(checknumber, sizeof(checknumber), "%i", i);
        }
        
        new bool: exists = false;
        for (new j=0; j < 4; j++)
        {
            switch (j)
            {
                case 0: { FormatEx(scenefile, sizeof(scenefile), "scenes/%s/%s%s.vcd", model, arg, checknumber); }
                case 1: { FormatEx(scenefile, sizeof(scenefile), "left4dead2_dlc1/scenes/%s/%s%s.vcd", model, arg, checknumber); }
                case 2: { FormatEx(scenefile, sizeof(scenefile), "left4dead2_dlc2/scenes/%s/%s%s.vcd", model, arg, checknumber); } 
                case 3: { FormatEx(scenefile, sizeof(scenefile), "left4dead2_dlc3/scenes/%s/%s%s.vcd", model, arg, checknumber); }
            }
            if (FileExists(scenefile)) { exists = true; break; }
        }
        
        if (!exists) continue;
        
        foundfilescounter++;
        validfiles[foundfilescounter] = i;
        
        PrintToChatAll("Found valid file at %s, index:%i", scenefile, foundfilescounter);
    }
    
    if (!foundfilescounter)
    {
        PrintToChatAll("No valid files found for arg %s", arg);
        return Plugin_Handled;
    }
    
    // STEP 3: SELECT ONE OF THE FOUND SCENE FILES
    
    new randomint = GetRandomInt(1, foundfilescounter);
    PrintToChatAll("Valid Files Count: %i, randomly chosen index: %i", foundfilescounter, randomint);
    
    if (validfiles[randomint] < 10)
    {
        FormatEx(checknumber, sizeof(checknumber), "0%i", validfiles[randomint]);
    }
    else
    {
        FormatEx(checknumber, sizeof(checknumber), "%i", validfiles[randomint]);
    }
    FormatEx(scenefile, sizeof(scenefile), "scenes/%s/%s%s.vcd", model, arg, checknumber);
    
    PrintToChatAll("Chose Scenefile: %s, attempting to vocalize now", scenefile);
    
    // STEP 4: CALL SCENE AND THUS VOCALIZE
    
    new tempent = CreateEntityByName("instanced_scripted_scene");
    DispatchKeyValue(tempent, "SceneFile", scenefile);
    DispatchSpawn(tempent);
    SetEntPropEnt(tempent, Prop_Data, "m_hOwner", client);
    ActivateEntity(tempent);
    AcceptEntityInput(tempent, "Start", client, client);
    HookSingleEntityOutput(tempent, "OnCompletion", EntityOutput:OnSceneCompletion, true);

    return Plugin_Handled;
}

public Action:Cmd_Vocalize_Specified(client, args)
{
    if (!client || !args || !IsClientInGame(client))
    {
        ReplyToCommand(client, "Must be Ingame for command to work, and dont forget the argument");
        return Plugin_Handled;
    }
    
    decl String:arg[256];
    GetCmdArg(1, arg, sizeof(arg));
    
    PrintToChatAll("SM Vocalize caught by %N, command: %s", client, arg);
    
    // STEP 1: FIGURE OUT WHICH SURVIVOR WERE DEALING WITH
    
    decl String:model[256];
    GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
    
    if (StrContains(model, "gambler") != -1) { FormatEx(model, sizeof(model), "gambler"); }
    else if (StrContains(model, "coach") != -1) { FormatEx(model, sizeof(model), "coach"); }
    else if (StrContains(model, "mechanic") != -1) { FormatEx(model, sizeof(model), "mechanic"); }
    else if (StrContains(model, "producer") != -1) { FormatEx(model, sizeof(model), "producer"); }
    else if (StrContains(model, "namvet") != -1) { FormatEx(model, sizeof(model), "namvet"); }
    else if (StrContains(model, "teengirl") != -1) { FormatEx(model, sizeof(model), "teengirl"); }
    else if (StrContains(model, "biker") != -1) { FormatEx(model, sizeof(model), "biker"); }
    else if (StrContains(model, "manager") != -1) { FormatEx(model, sizeof(model), "manager"); }
    
    // STEP 2: INPUT CHOSEN SCENE IN MASK
    
    decl String:scenefile[256];
    
    new bool: exists = false;
    for (new j=0; j < 4; j++)
    {
        switch (j)
        {
            case 0: { FormatEx(scenefile, sizeof(scenefile), "scenes/%s/%s.vcd", model, arg); }
            case 1: { FormatEx(scenefile, sizeof(scenefile), "left4dead2_dlc1/scenes/%s/%s.vcd", model, arg); }
            case 2: { FormatEx(scenefile, sizeof(scenefile), "left4dead2_dlc2/scenes/%s/%s.vcd", model, arg); }
            case 3: { FormatEx(scenefile, sizeof(scenefile), "left4dead2_dlc3/scenes/%s/%s.vcd", model, arg); }
        }
        if (FileExists(scenefile)) { exists = true; break; }
    }
    if (!exists) {
        PrintToChatAll("Specified Scenefile: %s does not exist, aborting", scenefile);
        return Plugin_Handled;
    }
    
    PrintToChatAll("Specified Scenefile: %s, attempting to vocalize now", scenefile);
    
    // STEP 3: CALL SCENE AND THUS VOCALIZE
    
    new tempent = CreateEntityByName("instanced_scripted_scene");
    DispatchKeyValue(tempent, "SceneFile", scenefile);
    DispatchSpawn(tempent);
    SetEntPropEnt(tempent, Prop_Data, "m_hOwner", client);
    ActivateEntity(tempent);
    AcceptEntityInput(tempent, "Start", client, client);
    HookSingleEntityOutput(tempent, "OnCompletion", EntityOutput:OnSceneCompletion, true);

    return Plugin_Handled;
}

/*
    END TEST
*/
#endif

public OnPluginEnd()
{
    INIT_CVarsReset();
    RI_KV_Close();
    
    // storm plugin
    SUPPORT_StormReset();

    HatsRemoveAll();
}


public OnClientDisconnect_Post(client)
{
    SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
    
    if (g_bSpecialEventPlayerCheck)
    {
        new Handle:pack = CreateDataPack();
        WritePackCell(pack, g_bPlayersLeftStart);
        WritePackCell(pack, true);
        WritePackCell(pack, client);
        CreateTimer(0.1, Timer_CheckSpecialEventRole, pack, TIMER_FLAG_NO_MAPCHANGE);
        return;
    }
    
    PrintDebug(3, "Client disconnected: %i (hadspawn %i / wasghost %i)", client, g_bHasSpawned[client], g_bHasGhost[client] );
    
    // safeguard for SI
    g_bHasGhost[client] = false;
    g_bHasSpawned[client] = false;
    
    
    
    if (!g_bIsTankInPlay || client != g_iTankClient) { return; }
    CreateTimer(0.1, Timer_CheckTankDeath, client);
}

public OnClientPostAdminCheck(client)
{
    SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);      // hook for t2 nerfing
    SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquip);    // hook for item penalty
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);        // hook for events damage changes
    
    // safeguard for SI
    //g_bHasSpawned[client] = false;
    
    // special case: gunswap ammo count
    if (g_iSpecialEvent == EVT_GUNSWAP && IsSurvivor(client))
    {
        CreateTimer(0.1, Timer_CheckSurvivorGun, client, TIMER_FLAG_NO_MAPCHANGE);
    }
    
    // bot gets in, check for gnome-holding
    if (IsFakeClient(client))
    {
        CreateTimer(0.05, Timer_ClientPostAdminCheck_Delayed, client, TIMER_FLAG_NO_MAPCHANGE);
    }
    
    // prevent weapon equip calls from counting after bot-join
    g_bArBlockPickupCall[client] = true;
    CreateTimer(0.01, Timer_UnblockWeaponPickupCall, client, TIMER_FLAG_NO_MAPCHANGE);
    
    // message
    new mode = GetConVarInt(g_hCvarWelcomeMode);
    if (mode == WELCOME_NONE || (mode == WELCOME_FIRSTMAP && g_bFirstMapDone)) { return;  }
    if (mode == WELCOME_ONCE) {
        // remember client
        new String: SteamId[32];
        if (GetClientAuthString(client, SteamId, sizeof(SteamId)))
        {
            if (FindStringInArray(g_hSteamIds, SteamId) != -1) { return; }  // already welcomed once
            PushArrayString(g_hSteamIds, SteamId);
        }
    }
    
    CreateTimer(DELAY_WELCOMEMSG, Timer_DoWelcomeMessage, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action: Timer_ClientPostAdminCheck_Delayed(Handle:timer, any:client)
{
    if (!IsClientAndInGame(client)) { return; }
    
    // check for gnome/cola..
    new holdingEnt = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    new gnomeIndex = FindGnomeIndex(holdingEnt);
    
    if (gnomeIndex != -1) {
        // update gnome, held by different client now
        g_strArGnomes[gnomeIndex][gnomebHeldByPlayer] = true;
        g_strArGnomes[gnomeIndex][gnomeiHoldingClient] = client;
    }
}

public Action: Timer_DoWelcomeMessage(Handle:timer, any:client)
{
    DoWelcomeMessage(client);
}

public Action: Timer_UnblockWeaponPickupCall(Handle:timer, any:client)
{
    g_bArBlockPickupCall[client] = false;
}

// test
#if DEBUG_MODE
public Action: TestSwap_Cmd(client, args)
{
    EVENT_SwapSurvivorGun(client);
}

public Action: TestGnomes_Cmd(client, args)
{
    // animation test
    //StartSurvivorAnim_Healing(client);
    
    DoGnomesServerReport();

    /*
    decl String:sMessage[MAX_NAME_LENGTH];
    GetCmdArg(1, sMessage, sizeof(sMessage));
    new setclient = StringToInt(sMessage);
    
    GetCmdArg(2, sMessage, sizeof(sMessage));
    new event = StringToInt(sMessage);
    
    if (args)
    {
        //L4D2Direct_DoAnimationEvent(setclient, event);
        
        // hat test
        if (event) {
            //CreateHat(setclient, event);
            DoBlindSurvivor(setclient, event);
            CreateTimer(5.0, Timer_UnBlindSurvivor, setclient, TIMER_FLAG_NO_MAPCHANGE);
        }
        else {
            if (IsClientAndInGame(setclient)) {
                PlayerDoVomit(setclient);
            }
        }

        return Plugin_Handled;
    }
    
    // test timer
    new oCurrentTimer = FindSendPropInfo("CTerrorPlayer", "m_ghostSpawnClockMaxDelay");
    new oCurrentStamp = FindSendPropInfo("CTerrorPlayer", "m_ghostSpawnClockCurrentDelay");
    new offsetlifeState = FindSendPropInfo("CTerrorPlayer", "m_ghostSpawnState");
    
    PrintToChatAll("Max: %i Current: %i State: %i",
            GetEntData(client, oCurrentTimer, 2), 
            GetEntData(client, oCurrentStamp, 2),
            GetEntData(client, offsetlifeState, 4)
        );
        
    PrintToChatAll("Max: %i Current: %i State: %i",
            GetEntData(client, oCurrentTimer, 2), 
            GetEntData(client, oCurrentStamp, 2),
            GetEntData(client, offsetlifeState, 4)
        );
    
    // test vomit
    //PlayerDoVomit(client);
    
    // test messing around with health
    //SetEntityHealth(client, 1);
    //SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 99.0);
    //SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
    //SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
    //SetEntityHealth(client, 100);
    //SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 1);
    
    
    // test: are we in saferoom?
    new bool: inStart = IsEntityInSaferoom(client, true, false);
    new bool: inEnd = IsEntityInSaferoom(client, true, true);
    
    PrintToChatAll( "\x01Are we in saferoom? Start: \x03%s\x01 - End: \x03%s\x01", (inStart) ? "yes":"no", (inEnd) ? "yes":"no" );
    PrintToChatAll("gnomebonus: %i", GetGnomeBonus() );
    
    // show a little list of all the known gnomes and their status
    for (new i=0; i < g_iGnomes; i++)
    {
        if (g_strArGnomes[i][gnomebFirstPickup]) {
            PrintToChatAll("gnome/cola [%i]: isCola=%i, pickedUp=%i (%.2f), entity: %i, held?: %i (by: %i)", i, g_strArGnomes[i][gnomebIsCola], g_strArGnomes[i][gnomebFirstPickup], g_strArGnomes[i][gnomefFirstPickup], g_strArGnomes[i][gnomeEntity], g_strArGnomes[i][gnomebHeldByPlayer], g_strArGnomes[i][gnomeiHoldingClient]);
        }
    }
    
    for (new x=0; x < g_iGnomesHeld; x++)
    {
        PrintToChatAll("gnome/cola HELD [%i]: %i", x, g_iArGnomesHeld[x]);
    }

    // test:
    //SetEntityHealth(1, 1);
    //SetEntPropFloat(1, Prop_Send, "m_healthBuffer", 100.0);
    
    //CheckGnomes();
    */
    return Plugin_Handled;
}

public Action: TestEnts_Cmd(client, args)
{
    DoItemsServerReport(true);
}

public Action: TestEvent_Cmd(client, args)
{
    // for a special event next round
    decl String:sMessage[MAX_NAME_LENGTH];
    GetCmdArg(1, sMessage, sizeof(sMessage));

    new eventIndex = StringToInt(sMessage);
    
    if (eventIndex < 0 || eventIndex >= EVT_TOTAL)
    {
        if (g_iSpecialEventToForce != -1) {
            PrintToChatAll("[rand_debug] Admin removed event-forcing for next round (previously set to %i).", g_iSpecialEventToForce);
        }
        g_iSpecialEventToForce = eventIndex;
        
        return Plugin_Handled;
    }
    
    // else, force event next round
    PrintToChatAll("[rand_debug] Admin forced event %i for next round (%s)...", eventIndex, g_csEventText[eventIndex]);
    
    g_iSpecialEventToForce = eventIndex;
    
    return Plugin_Handled;
}

#endif
/*
    Commands
    -------------------------- */
public Action: RandomHelp_Cmd(client, args)
{
    DoHelpMessage(client);
    return Plugin_Handled;
}
public Action: RandomReport_Cmd(client, args)
{
    DoReport(client);
    return Plugin_Handled;
}
public Action: RandomBonus_Cmd(client, args)
{
    if (g_bUsingPBonus) {
        EVENT_DisplayRoundPenalty(client);
    } else {
        PrintToChat(client, "\x01[\x05r\x01] This round has no special bonus or penalty.");
    }
    return Plugin_Handled;
}

public Action: RandomDrop_Cmd(client, args)
{
    // only allow when able to drop anything
    if ( !IsSurvivor(client) || !IsPlayerAlive(client) || IsHangingFromLedge(client) || IsIncapacitated(client) ) { return Plugin_Handled; }
    
    if (args)
    {
        decl String:sMessage[3];
        GetCmdArg(1, sMessage, sizeof(sMessage));
        new slot = StringToInt(sMessage);
        
        if (slot > 0 && slot < 6) {
            if ( SUPPORT_DropItem(client, false, 0, slot, true) ) {
                PrintToChat(client, "\x01[\x05r\x01] Dropped.");
            }
        }
        else {
            PrintToChat(client, "\x01[\x05r\x01] Incorrect argument: must be a number between 0 and 6.");
        }
        return Plugin_Handled;
    }
    
    if ( SUPPORT_DropItem(client, true, 0, 0, true) ) {
        PrintToChat(client, "\x01[\x05r\x01] Dropped.");
    }
    
    return Plugin_Handled;
}

public Action: RandomEventInfo_Cmd(client, args)
{
    if (args)
    {
        decl String:sMessage[5];
        GetCmdArg(1, sMessage, sizeof(sMessage));
        
        if (StrEqual(sMessage, "list", false) || StrEqual(sMessage, "l", false)) {
            g_iEventMenu[client] = EVTMNU_INFO;
            SUPPORT_ShowEventList(client);
        }
        else {
            new setevent = StringToInt(sMessage);
            DoEventInfo(client, setevent);
        }
    }
    else {
        if (g_iSpecialEvent != -1) {
            DoEventInfo(client, -1);
        }
        else {
            g_iEventMenu[client] = EVTMNU_INFO;
            SUPPORT_ShowEventList(client);
        }
    }
    return Plugin_Handled;
}
public Action: RandomPickEvent_Cmd(client, args)
{
    if (g_bCampaignMode) {
        PrintToChat(client, "\x01[\x05r\x01] This only works in versus games.");
        return Plugin_Handled;
    }
    
    if (GetConVarBool(g_hCvarBlockEventVotes)) {
        PrintToChat(client, "\x01[\x05r\x01] Event votes are blocked by the server.");
        return Plugin_Handled;
    }
    
    if (args)
    {
        decl String:sMessage[5];
        GetCmdArg(1, sMessage, sizeof(sMessage));
    
        if (StrEqual(sMessage, "no", false)) {
            SUPPORT_VotePickEvent(-1, client);
        }
        else if (StrEqual(sMessage, "list", false)) {
            g_iEventMenu[client] = EVTMNU_PICK;
            SUPPORT_ShowEventList(client);
        }
        else {
            new setevent = StringToInt(sMessage);
            SUPPORT_VotePickEvent(setevent, client);
        }
    }
    else {
        SUPPORT_VotePickEvent(0, client);
    }
    
    return Plugin_Handled;
}
public Action: RandomForcePickEvent_Cmd(client, args)
{
    if (args)
    {
        decl String:sMessage[3];
        GetCmdArg(1, sMessage, sizeof(sMessage));
        new setevent = StringToInt(sMessage);
        
        SUPPORT_PickEvent(setevent, client);
    }
    
    return Plugin_Handled;
}
public Action: RandomPickGameEvent_Cmd(client, args)
{
    if (g_bCampaignMode) {
        PrintToChat(client, "\x01[\x05r\x01] This only works in versus games.");
        return Plugin_Handled;
    }
    
    if (GetConVarBool(g_hCvarBlockEventVotes)) {
        PrintToChat(client, "\x01[\x05r\x01] Event votes are blocked by the server.");
        return Plugin_Handled;
    }
    
    if (args)
    {
        decl String:sMessage[3];
        GetCmdArg(1, sMessage, sizeof(sMessage));
    
        if (StrEqual(sMessage, "no", false)) {
            SUPPORT_VotePickGameEvent(-1, client);
        }
        else {
            new setevent = StringToInt(sMessage);
            SUPPORT_VotePickGameEvent(setevent, client);
        }
    }
    else {
        SUPPORT_VotePickGameEvent(0, client);
    }
    
    return Plugin_Handled;
}
public Action: RandomForcePickGameEvent_Cmd(client, args)
{
    if (args)
    {
        decl String:sMessage[3];
        GetCmdArg(1, sMessage, sizeof(sMessage));
        new setevent = StringToInt(sMessage);
        
        SUPPORT_PickGameEvent(setevent, client);
    }
    
    return Plugin_Handled;
}
public Action: RandomCoopRerandom_Cmd(client, args)
{
    if ( !g_bCampaignMode ) {
        PrintToChat(client, "\x01[\x05r\x01] This only works in campaign mode.");
        return Plugin_Handled;
    }
    
    PrintToChatAll("\x01[\x05r\x01] If you fail (again), the game will be re-randomized.");
    g_bCampaignReRandomPlease = true;
    
    return Plugin_Handled;
}
public Action: Spectate_Cmd(client, args)
{
    if (g_bHasGhost[client]) { g_bSpectateDeath[client] = true; }
    
    return Plugin_Continue;
}
public Action: Say_Cmd(client, args)
{
    new String: full[11];
    GetCmdArgString(full, sizeof(full));
    StripQuotes(full);
    TrimString(full);
    
    new randomCommands: commandTyped;
    if (!GetTrieValue(g_hTrieCommands, full, commandTyped))
    {
        decl String:sMessage[MAX_NAME_LENGTH];
        GetCmdArg(1, sMessage, sizeof(sMessage));
        
        GetTrieValue(g_hTrieCommands, sMessage, commandTyped);
    }
    
    // if !spectate command
    if (commandTyped == RANDOM_COMMAND_SPECTATE) {
        if (g_bHasGhost[client]) { g_bSpectateDeath[client] = true; }
    }
    
    // hide commands typed
    if (IsChatTrigger() && commandTyped == RANDOM_COMMAND)
    {
        return Plugin_Handled;
    }
    
    return Plugin_Continue;
}




// pausing
public Action:Listener_Pause(client, const String:command[], argc)
{
    if ( g_bPauseAvailable ) { return; }
    
    if (GetConVarBool(FindConVar("sv_pausable")))
    {
        g_fPauseAttemptTime = 0.0;
        g_bIsPaused = true;
        PrintDebug(0, "[rand] PAUSED.");
    }
    else
    {
        g_fPauseAttemptTime = GetGameTime();
    }
}
public Action:OnClientCommand(client, args)
{
    if ( g_bPauseAvailable ) { return Plugin_Continue; }
    
    new String:cmd[16];
    GetCmdArg(0, cmd, sizeof(cmd));
    
    if (!g_bIsPaused || GetConVarBool(g_hCvarSimplePauseCheck)) { return Plugin_Continue; }
    
    if (StrEqual(cmd, "sm_pause"))
    {
        if (!SUPPORT_IsInReady())
        {
            // not certain yet, might be blocked/disabled..
            //  if sv_pausable changes, we know
            g_fPauseAttemptTime = GetGameTime();
        }
    }
    
    return Plugin_Continue;
}

public OnCvarPausableChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
    if ( g_bPauseAvailable ) { return; }
    
    if (StringToInt(newVal))
    {
        // if this happens after pause command, we're paused
        if (    !g_bIsPaused && ( (GetConVarBool(g_hCvarSimplePauseCheck) ) &&
                (g_fPauseAttemptTime == 0.0 || FloatSub( GetGameTime(), g_fPauseAttemptTime ) > 5.0) ) 
        ) {
            OnPause();
        }
    }
}

public Action: Unpause_Cmd(client, args)
{
    if ( g_bPauseAvailable ) { return Plugin_Continue; }
    
    // detect if we're in a pause
    if ( GetConVarBool(FindConVar("sv_pausable")) )
    {
        OnUnpause();
    }
    
    return Plugin_Continue;
}
// if pause library is available, direct forwards:
public OnPause()
{
    g_bIsPaused = true;
    g_fPauseAttemptTime = GetGameTime();
    g_fPauseStartTime = g_fPauseAttemptTime;
    PrintDebug( 1, "[rand] Paused." );
}

public OnUnpause()
{
    g_bIsPaused = false;
    PrintDebug( 1, "[rand] Unpaused. (%.1fs)", FloatSub(GetGameTime(), g_fPauseStartTime) );
    
    SUPPORT_CheckBlindSurvivors( FloatSub(GetGameTime(), g_fPauseStartTime) );
    
    g_fPauseStartTime = 0.0;
    g_fPauseAttemptTime = 0.0;
}

/*
    Forwards from custom_map_transitions
    ------------------------------------- */
// called when the first map is about to be loaded
public OnCMTStart( rounds, const String:mapname[] )
{
    // reset stats
    g_bCMTActive = true;
    strcopy( g_sNextMap, sizeof(g_sNextMap), mapname );
    PrintDebug(3, "[RI] First map expected (CMT): '%s'.", g_sNextMap);
}

// called when map begins (mapname is the name of the map *after* this)
public OnCMTNextKnown( const String:mapname[] )
{
    // store mapname, so we can block votes for events that shouldn't be
    // run on that next map...
    strcopy( g_sNextMap, sizeof(g_sNextMap), mapname );
    PrintDebug(3, "[RI] Next map expected (CMT): '%s'.", g_sNextMap);
}

// called after the last round has ended
public OnCMTEnd()
{
    g_bCMTActive = false;
    FormatEx( g_sNextMap, sizeof(g_sNextMap), "" );
}

/*
    Round management
    -------------------------- */

public Event_MissionLostCampaign(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
    if (!g_bCampaignMode) { return; }
    
    g_iCampaignFailStreak++;
    
    PrintDebug(1, "[rand] Survivors failed (%i time(s) in a row).", g_iCampaignFailStreak );
    
    // reroll if tried too many times
    new max = GetConVarInt(g_hCvarCampaignStreak);
    if ( g_bCampaignReRandomPlease || ( max && g_iCampaignFailStreak > max ) ) {
        g_iCampaignFailStreak = 0;
        g_bCampaignForceRandom = true;
    }
    else {
        g_bCampaignForceRandom = false;
    }
    
    g_bCampaignReRandomPlease = false;
    
    // safeguards?
    g_bPlayersLeftStart = false;
}

public OnMapStart()
{
    g_bItemsFullyRandomized = false;
    
    // check gamemode for 'coop'
    new String:tmpStr[24];
    GetConVarString(FindConVar("mp_gamemode"), tmpStr, sizeof(tmpStr));
    if (    StrEqual(tmpStr, "coop", false) ||
            StrEqual(tmpStr, "mutation4", false) ||         // hard eight
            StrEqual(tmpStr, "mutation14", false) ||        // gib fest
            StrEqual(tmpStr, "mutation20", false) ||        // healing gnome
            StrEqual(tmpStr, "mutationrandomcoop", false)   // healing gnome
    ) {
        g_bCampaignMode = true;
        g_bItemsFullyRandomized = true;
        g_bRestartedOnce = true;
    }
    else {
        g_bCampaignMode = false;
    }
    
    
    INIT_PrecacheModels();
    INIT_PrecacheParticles();
    INIT_GetMeleeClasses();
    
    // read in default cvars?
    if (!g_bDefaultCvarsLoaded)
    {
        INIT_TryCVarsGetDefault();
    }
    
    // only do special random activation when we've seen at least one map restart
    if (GetConVarBool(g_hCvarConfogl) && !g_bRestartedOnce && !g_bCampaignMode)
    {
        g_bRestartedOnce = true;
        g_bItemsFullyRandomized = true;
        PrintDebug(0, "[rand] First OnMapStart, starting randomization on the next.");
        return;
    }
    
    if (!g_bDefaultCvarsLoaded)
    {
        PrintDebug(0, "[rand] Default cvars were not loaded. OnMapStart preparation halted. Restart map.");
        return;
    }
    
    // campaign mode
    g_iCampaignFailStreak = 0;
    g_bCampaignReRandomPlease = false;
    
    INIT_EventCycleTimeout();           // cycle event timeout, so we know what we can pick
    SUPPORT_StormReset();               // safety to catch plugin acting on its own
    
    g_bSecondHalf = false;
    
    if (g_bVeryFirstMapLoad)
    {
        //INIT_CVarsGetDefault();         // do this here so the variables are config set [new approach, see above]
        g_bVeryFirstMapLoad = false;
    }
    
    RI_KV_UpdateRandomMapInfo();        // get this map's random-related info
    
    // update static survival bonus
    RNDBNS_SetStatic( GetConVarInt(g_hCvarStaticBonus) );
    
    CreateTimer(0.1, SUPPORT_RoundPreparation, _, TIMER_FLAG_NO_MAPCHANGE);
    
    // Start checking for humans loading in...
    CreateTimer(TIMER_HUMANCHECK, Timer_CheckForHumans, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    
    g_bMapStartDone = true;
    g_bInRound = true;
}

public OnMapEnd()
{
    if (g_kRIData != INVALID_HANDLE) { KvRewind(g_kRIData); }
    
    // switch stripper file for next map
    INIT_StripperSwitch();
    
    g_bSecondHalf = false;
    g_bInRound = false;
    g_bMapStartDone = false;
    g_bIsFirstAttack = true;
    g_bModelsPrecached = false;
    
    if (!g_bVeryFirstMapLoad)
    {
        g_bFirstMapDone = true;
    }
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    g_bSurvivorsLoadedIn = false;
    g_bBotsAllowedPickup = false;
    if (GetConVarBool(g_hCvarStopBotsAtStart)) { SetConVarInt(g_hCvarBotStop, 1); }
    
    // this is a bit silly, since roundstart gets called before onmapstart...
    // so just do the round start stuff in onmapstart
    if (g_bMapStartDone && !g_bInRound)
    {
        g_bInRound = true;
        
        CreateTimer(0.1, SUPPORT_RoundPreparation, _, TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    // this is only called once in versus games, so we know which round we're in
    g_bSecondHalf = true;
    g_bIsFirstAttack = true;
    g_bBotsAllowedPickup = false;
    g_bItemsFullyRandomized = false;
    
    if (g_bInRound && g_bUsingPBonus)   // only display once, and only when using pbonus
    {
        EVENT_DisplayRoundPenalty();
    }
    
    // stop timers we might have been using
    if (g_hWitchSpawnTimer != INVALID_HANDLE)
    {
        CloseHandle(g_hWitchSpawnTimer);
        g_hWitchSpawnTimer = INVALID_HANDLE;
    }
    
    if (g_bInRound) { g_bInRound = false; }
}


public OnRoundIsLive()
{
    g_bBotsAllowedPickup = true;
    
    // only if a readyup plugin is active
    // if not, display panel with a timer?
    CreateTimer(DELAY_PANELAFTERLIVE, Timer_DoPanelReport, _, TIMER_FLAG_NO_MAPCHANGE);
}
public Action: Timer_DoPanelReport(Handle:timer)
{
    DoPanelReport();
}

/*  General hooks
    ------------- */

// for blind infected
public Action:OnTransmit(entity, client)
{
    if (GetClientTeam(client) != TEAM_INFECTED) return Plugin_Continue;

    new size = GetArraySize(g_hBlockedEntities);
    decl currentEnt[EntInfo];

    for (new i=0; i < size; i++)
    {
        GetArrayArray(g_hBlockedEntities, i, currentEnt[0]);
        if (entity == currentEnt[iEntity])
        {
            if (currentEnt[hasBeenSeen]) return Plugin_Continue;
            else return Plugin_Handled;
        }
    }
    
    return Plugin_Continue;
}

// for making hats invisible to wearer
public Action:Hat_Hook_SetTransmit(entity, client)
{
    if( EntIndexToEntRef(entity) == g_iHatIndex[client] )
        return Plugin_Handled;
    return Plugin_Continue;
}
    
// for detecting when a player uses a gift box:
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if (g_iSpecialEvent == EVT_PROHOPS)
    {
        // automatic pro bunnyhops
        if (!(GetEntityFlags(client) & FL_ONGROUND))
        {
            if (!(GetEntityMoveType(client) & MOVETYPE_LADDER))
            {
                if (GetEntProp(client, Prop_Data, "m_nWaterLevel") <= 1)
                {
                    buttons &= ~IN_JUMP;
                }
            }
        }
    }
    
    if (!IsSurvivor(client) || !IsPlayerAlive(client)) { return Plugin_Continue; }


    if (g_iSpecialEvent == EVT_NOHUD)
    {
        // hide/show view depending on score showing
        if (buttons & IN_SCORE)
        {
            if (!g_bPlayerIsBlinded[client]) {
                g_bPlayerIsBlinded[client] = true;
                DoBlindSurvivor(client, 254, false);
            }
        }
        else if (g_bPlayerIsBlinded[client])
        {
            g_bPlayerIsBlinded[client] = false;
            DoBlindSurvivor(client, 0, false);
        }
    }
    
    if ((buttons & IN_USE))
    {
        // note: only human players get blocked this way (bots don't fire IN_USE)
        // block all use button use before items are ready
        if (!g_bItemsFullyRandomized && !g_bCampaignMode) { return Plugin_Handled; }
        
        // handle item use on gifts
        new check = RANDOM_CheckPlayerGiftUse(client);
        if (!check) { return Plugin_Handled; }
    }
    // crox's glow code for EVT_WITCHES
    else if (g_iSpecialEvent == EVT_WITCHES)
    {
        if (IsPlayerAlive(client) && GetClientTeam(client) == TEAM_SURVIVOR)
        {
            new psychonic = GetEntityCount();
            decl Float:clientOrigin[3];
            GetClientAbsOrigin(client, clientOrigin);
            decl Float:witchOrigin[3];
            decl String:buffer[32];
            for (new entity = MaxClients + 1; entity < psychonic; entity++)
            {
                if (IsValidEntity(entity)
                && GetEntityClassname(entity, buffer, sizeof(buffer))
                && StrEqual(buffer, "witch"))
                {
                    GetEntPropVector(entity, Prop_Send, "m_vecOrigin", witchOrigin);
                    if (GetVectorDistance(clientOrigin, witchOrigin, true) < EVENT_WITCHES_RANGE)
                    {
                        SetEntProp(entity, Prop_Send, "m_iGlowType", 0);
                    }
                }
            }
        }
    }
    
    return Plugin_Continue;
}


// for encumbered mode
public Action: L4D_OnGetRunTopSpeed(target, &Float:retVal)
{
    if (!IsClientAndInGame(target) || GetClientTeam(target) != TEAM_SURVIVOR) { return Plugin_Continue; }
    
    if (g_iSpecialEvent == EVT_ENCUMBERED)
    {
        new Float: fSpeedFactor = SUPPORT_GetSpeedFactor(target);
        if (fSpeedFactor != 1.0) {
            retVal = retVal * fSpeedFactor;
            return Plugin_Handled;
        }
    }
    // freeze player while using something
    else if (g_iClientUsing[target] > 0 && GetGameTime() - g_fProgressTime[target] >= ITEM_USE_FREEZE_TIME)
    {
        retVal = 0.0001;
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Action: L4D_OnGetWalkTopSpeed(target, &Float:retVal)
{
    if (!IsClientAndInGame(target) || GetClientTeam(target) != TEAM_SURVIVOR) { return Plugin_Continue; }
    
    if (g_iSpecialEvent == EVT_ENCUMBERED)
    {
        new Float: fSpeedFactor = SUPPORT_GetSpeedFactor(target);
        if (fSpeedFactor != 1.0) {
            retVal = retVal * fSpeedFactor;
            return Plugin_Handled;
        }
    }
    // freeze player while using something
    else if (g_iClientUsing[target] > 0 && GetGameTime() - g_fProgressTime[target] >= ITEM_USE_FREEZE_TIME)
    {
        retVal = 0.0001;
        return Plugin_Handled;
    }
    return Plugin_Continue;
}
public Action: L4D_OnGetCrouchTopSpeed(target, &Float:retVal)
{
    if (!IsClientAndInGame(target) || GetClientTeam(target) != TEAM_SURVIVOR) { return Plugin_Continue; }
    
    if (g_iSpecialEvent == EVT_ENCUMBERED)
    {
        new Float: fSpeedFactor = SUPPORT_GetSpeedFactor(target);
        if (fSpeedFactor != 1.0) {
            retVal = retVal * fSpeedFactor;
            return Plugin_Handled;
        }
    }
    // freeze player while using something
    else if (g_iClientUsing[target] > 0 && GetGameTime() - g_fProgressTime[target] >= ITEM_USE_FREEZE_TIME)
    {
        retVal = 0.0001;
        return Plugin_Handled;
    }
    return Plugin_Continue;
}


/*  SDK-Hooks
    ------------- */

// sound catching for silence special event
public Action: Event_SoundPlayed(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
    // temporary deafness: remove the client from the clients list, reduce numclients by one?
    
    if (g_iSpecialEvent == EVT_SILENCE)
    {
        // hush
        if (IsClientAndInGame(entity))
        {
            if (g_iSpecialEventExtra == SILENCED_SURV && IsSurvivor(entity))
            {
                return Plugin_Handled;
            }
            else if (g_iSpecialEventExtra == SILENCED_SI)
            {
                if (IsInfected(entity) && !IsTank(entity)) {
                    // block all
                    return Plugin_Handled;
                }
                else if (IsSurvivor(entity)) {
                    // pick out a few things they can't say anymore
                    if (    StrContains(sample, "warnboom", false) != -1
                        ||  StrContains(sample, "warncharger", false) != -1
                        ||  StrContains(sample, "warnhunter", false) != -1
                        ||  StrContains(sample, "warnjockey", false) != -1
                        ||  StrContains(sample, "warnspitter", false) != -1
                    ) {
                        return Plugin_Handled;
                    }
                } 
                
            }
        }
    }
    else if (g_iSpecialEvent == EVT_AMMO)
    {
        // stop all the bs about 'incendiary' ammo, when it's normal :)
        if (IsSurvivor(entity))
        {
            if (StrContains(sample, "incendammo", false) != -1 || StrContains(sample, "explosiveammo", false) != -1)
            {
                // do a vocalize from the player
                Vocalize_Random(entity, "spotammo");
                return Plugin_Handled;
            }
        }
    }
    return Plugin_Continue;
}


/* public Action: TraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
    if (!IsClientAndInGame(victim) || !IsClientAndInGame(attacker)) { return; }
}
*/

public Action: OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
    if (damage == 0.0 || !IsValidEntity(attacker) || !IsValidEntity(victim)) { return Plugin_Continue; }
    
    // chainsaws vs tanks
    if (    damagetype == DMGTYPE_CHAINSAW
        &&  IsClientAndInGame(victim) && GetClientTeam(victim) == TEAM_INFECTED && IsPlayerAlive(victim)
        &&  GetEntProp(victim, Prop_Send, "m_zombieClass") == ZC_TANK
        &&  IsValidEntity(inflictor)
        &&  IsClientAndInGame(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR
    ) {
        // safeguard: is it really the saw?
        new String: classname[32];
        if ( IsValidEdict(inflictor) ) {
            GetEdictClassname(inflictor, classname, sizeof(classname));
        }
        
        if (StrEqual(classname, "weapon_chainsaw", false))
        {
            damage *= CSAW_TANK_DMG_FACTOR;
            return Plugin_Changed;
        }
    }
    
    // bay event: propane tanks should do less damage to survivors
    if ( g_iSpecialEvent == EVT_BAY )
    {
        if (IsValidEntity(inflictor))
        {
            new String: classnameb[32];
            GetEdictClassname(inflictor, classnameb, sizeof(classnameb));
            if (StrEqual(classnameb, "pipe_bomb_projectile", false)) {
                damage = EVENT_BAY_PIPEDAMAGE;
                return Plugin_Changed;
            }
        }
    }
    // women, where the witch should die more easily to melee swings
    else if ( g_iSpecialEvent == EVT_WOMEN || g_iSpecialEvent == EVT_WITCHES )
    {
        if (!IsClientAndInGame(attacker) && IsValidEdict(attacker) )
        {
            // only change damage for swings at upright survivors
            if ( !IsClientAndInGame(victim) || GetClientTeam(victim) != TEAM_SURVIVOR ) { return Plugin_Continue; }
        
            decl String:attackClass[64];
            GetEdictClassname(attacker, attackClass, 64);
            if (!StrEqual(attackClass, "witch")) { return Plugin_Continue; }
            
            // survivors bungled the witch!
            if ( g_iSpecialEvent == EVT_WITCHES ) {
                //PrintDebug(4, "[rand] witch bungled: entity: %i; victim: %i", attacker, victim);
                g_bWitchBungled[attacker] = true;
            }
            
            if ( IsIncapacitated( victim ) ) { return Plugin_Continue; }
            
            damage = (g_iSpecialEvent == EVT_WOMEN) ? g_RC_fEventWomenWitchDmg : g_RC_fEventWitchesWitchDmg;
            return Plugin_Changed;
        }
    }
    // protect, baby player takes more damage (the others less)
    else if (g_iSpecialEvent == EVT_PROTECT)
    {
        if ( !IsClientAndInGame(victim) ) { return Plugin_Continue; }
        if ( GetClientTeam(victim) != TEAM_SURVIVOR ) { return Plugin_Continue; }
        
        new String: classname[32];
        
        if ( IsValidEdict(inflictor) ) {
            GetEdictClassname(inflictor, classname, sizeof(classname));
        }
        
        if (StrEqual(classname, "infected", false))
        {
            // CI-to-survivor
            if (victim == g_iSpecialEventRole) {
                damage *= EVENT_PROTECT_CIWEAK;
            } else {
                damage *= EVENT_PROTECT_CISTRONG;
            }
            return Plugin_Changed;
        }
        else if ( IsClientAndInGame(attacker) && GetClientTeam(attacker) == TEAM_INFECTED ) {
            // SI-to-survivor
            if (victim == g_iSpecialEventRole) {
                damage = damage * g_RC_fEventProtectWeak;
            } else {
                damage = damage * g_RC_fEventProtectStrong;
            }
            return Plugin_Changed;
        }
    }
    // set a fixed damage amount for melee weaps on tank
    else if (g_iSpecialEvent == EVT_MINITANKS)
    {
        if ( !IsClientAndInGame(victim) ) { return Plugin_Continue; }
        if ( !IsClientAndInGame(attacker) ) { return Plugin_Continue; }
        
        if ( GetClientTeam(attacker) != TEAM_SURVIVOR || GetClientTeam(victim) != TEAM_INFECTED || !IsTank(victim) || !IsValidEdict(inflictor) ) { return Plugin_Continue; }
    
        new String: classname[32];
        if ( IsValidEdict(inflictor) ) {
            GetEdictClassname(inflictor, classname, sizeof(classname));
        }
        
        // does this work well with chainsaw?
        if (StrEqual(classname, "weapon_melee", false))
        {
            damage = g_RC_fMinitankMeleeDmg;
            return Plugin_Changed;
        }
    }
    
    return Plugin_Continue;
}

public Action: OnTakeDamage_Witch(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
    // only hooked on EVT_WOMEN, for making melees do diff. damage to witches
    if (    g_iSpecialEvent != EVT_WOMEN
        ||  damage == 0.0
        ||  !IsClientAndInGame(attacker)
        ||  GetClientTeam(attacker) != TEAM_SURVIVOR
        ||  !IsValidEntity(victim)
        ||  !IsValidEntity(inflictor)
    ) {
        return Plugin_Continue;
    }

    decl String:victimClass[64];
    GetEdictClassname(victim, victimClass, 64);
    if (!StrEqual(victimClass, "witch")) { return Plugin_Continue; }
    
    new String: classname[32];
    GetEdictClassname(inflictor, classname, sizeof(classname));
    if (!StrEqual(classname, "weapon_melee", false)) { return Plugin_Continue; }
    
    damage = g_RC_fEventWomenMeleeDmg;
    return Plugin_Changed;
}

public Action: OnTakeDamage_Door(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
    // only hooked on EVT_WOMEN, for making melees do diff. damage to witches
    if ( g_iSpecialEvent != EVT_KEYMASTER && g_iSpecialEvent != EVT_DOORCIRCUS ) { return Plugin_Continue; }
    
    if ( g_iSpecialEvent == EVT_DOORCIRCUS ) {
        // nothing can damage doors
        // block all damage to doors
        damage = 0.0;
        return Plugin_Changed;
    }
    
    // only infected can damage doors
    // KEYMASTER
    if (    damage == 0.0
        ||  !IsClientAndInGame(attacker)
        ||  GetClientTeam(attacker) != TEAM_SURVIVOR
        ||  !IsValidEntity(victim)
    ) {
        return Plugin_Continue;
    }
    

    // block damage survivors do to doors
    damage = 0.0;
    return Plugin_Changed;
}

public Action: OnTakeDamage_Hittable(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
    // this is already only hooked on BAY event
    // wait until round is live
    if ( SUPPORT_IsInReady() ) { return Plugin_Continue; }
    
    if (    damage == 0.0
        ||  !IsClientAndInGame(attacker)
        ||  GetClientTeam(attacker) != TEAM_SURVIVOR
        ||  !IsValidEntity(victim)
    ) {
        return Plugin_Continue;
    }
    
    
    
    new bool: doBlowUp = false;
    new index = 0;
    
    // if damage is enough, explode car
    if ( damage >= EVENT_BAY_CARDAMAGE ) {
        doBlowUp = true;
    }
    else {
        // count up and check
        // find hittable index
        for (new i=0; i < g_iStoredHittables; i++) {
            if ( victim == g_strArHittableStorage[i][hitNumber] ) {
                index = i;
                doBlowUp = true;
                break;
            }
        }
        // only blow up if enough damage total
        if ( doBlowUp )
        {
            g_strArHittableStorage[index][hitDamageRcvd] += RoundFloat( damage );
            if ( g_strArHittableStorage[index][hitDamageRcvd] < EVENT_BAY_CARDAMAGE ) {
                doBlowUp = false;
            }
        }
    }
        
    if ( doBlowUp )
    {
        if ( index == 0 ) {
            for (new i=0; i < g_iStoredHittables; i++) {
                if ( victim == g_strArHittableStorage[i][hitNumber] ) {
                    index = i;
                    break;
                }
            }
        }
        
        SDKUnhook( victim, SDKHook_OnTakeDamage, OnTakeDamage_Hittable );
        if ( g_strArHittableStorage[index][hitBlownUp] ) { return Plugin_Continue; }
        
        
        
        PrintDebug(3, "[rand] Michael bay car blowing up!");
        g_strArHittableStorage[index][hitBlownUp] = true;
        
        
        // get car location
        new Float: targetPos[3];
        GetEntPropVector(victim, Prop_Send, "m_vecOrigin", targetPos);
        
        new Handle:pack = CreateDataPack();
        WritePackFloat(pack, g_RC_fExplosionPowerHigh);
        WritePackFloat(pack, targetPos[0]);
        WritePackFloat(pack, targetPos[1]);
        WritePackFloat(pack, targetPos[2]);
        WritePackCell(pack, (GetRandomInt(0,2) == 0) ? 0 : 1 ); // for fire
        CreateTimer(CAR_EXPLODE_DELAY, Timer_CreateExplosion, pack, TIMER_FLAG_NO_MAPCHANGE);
        
        // push the car upwards to simulate explosion blowup thingy
        CreateTimer(CAR_EXPLODE_DELAY, Timer_PushCarUpwards, victim, TIMER_FLAG_NO_MAPCHANGE);
    }
    
    return Plugin_Continue;
}


/*      see note @ hooking car in random_thirdparty spawnalarmcar
public Action: OnTakeDamage_AlarmedCar(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
    // alarmed car gets punched
    if (!IsValidEntity(victim) || !IsValidEntity(attacker)) { return Plugin_Continue; }
    
    //PrintToChatAll("attacker: %d - inflictor: %d - victim: %i", attacker, inflictor, victim);
    
    if (attacker == inflictor) {
        // check if one hittable collided with another
        new String: classname[32];
        GetEdictClassname(attacker, classname, sizeof(classname));
        
        if (StrEqual(classname, "prop_physics", false) || StrEqual(classname, "prop_car_alarm", false))
        {
            for (new i=0; i < g_iStoredHittables; i++)
            {
                if (!g_strArHittableStorage[i][hitIsAlarmed] || g_strArHittableStorage[i][hitNumber] != victim || g_strArHittableStorage[i][hitAlarmOff]) { continue; }
                DisableAlarmCar(i);
            }
        }
    }
    
    return Plugin_Continue;
}
*/

/*  Human tracking (join/etc)
    -------------------------- */

public Action: Timer_CheckForHumans(Handle:hTimer)
{
    if (AnyoneLoadedIn()) {
        DoFirstHumanDetected();
        //g_bTimerCheckFirstHuman = false;
        return Plugin_Stop;
    }
    return Plugin_Continue;
}

stock DoFirstHumanDetected()
{
    // finally the first real player loaded in (survivor side)
    
    // report if still necessary:
    if (!g_bFirstReportDone)
    {
        g_hTimerReport = CreateTimer(GetConVarFloat(g_hCvarReportDelay), Timer_RoundStartReport, _, TIMER_FLAG_NO_MAPCHANGE);
        g_bTimerReport = true;
    }

    // hand out gifts, if any 'remain'
    if (g_bSurvHandout) {
        CreateTimer(DELAY_SURVSETUP, Timer_PlayerJoinedSurvivor, _, TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Action: Timer_RoundStartReport(Handle:timer)
{
    // fallback for when no readyup: re-enable bot action
    if (g_hCvarReadyUp == INVALID_HANDLE || !GetConVarBool(g_hCvarReadyUp))
    {
        g_bBotsAllowedPickup = true;
        if (GetConVarBool(g_hCvarStopBotsAtStart)) { SetConVarInt(g_hCvarBotStop, 0); }
    }
    
    // do the report
    g_bTimerReport = false;
    if (GetConVarBool(g_hCvarDoReport)) { DoReport(); }
    g_bFirstReportDone = true;
    
    // if no readyup, draw the panel
    if (g_hCvarReadyUp == INVALID_HANDLE || !GetConVarBool(g_hCvarReadyUp))
    {
        DoPanelReport();
    }
}

public Action: Timer_PlayerJoinedSurvivor(Handle:timer, any:pack)
{
    // just do a general survivor check
    //  should give items early enough
    CheckSurvivorSetup();
}

public Action: L4D_OnFirstSurvivorLeftSafeArea( client )
{
    PrintDebug(6, "[rand] Survivors left saferoom [L4DT forward].");
    SurvivorsReallyLeftSaferoom();
}
// this is called iff the round has actually really started
SurvivorsReallyLeftSaferoom()
{
    g_bIsFirstAttack = false;
    g_bBotsAllowedPickup = true;
    if (GetConVarBool(g_hCvarStopBotsAtStart)) { SetConVarInt(g_hCvarBotStop, 0); }
    
    // if report hasn't been shown by now, show it!
    if (!g_bFirstReportDone)
    {
        // stop the report timer, if it's running
        if (g_bTimerReport) {
            KillTimer(g_hTimerReport);
            g_bTimerReport = false;
        }
        
        // do the report
        g_bFirstReportDone = true;
        if (GetConVarBool(g_hCvarDoReport)) { DoReport(); }
        
    }
    
    // do special late round prep
    if (!g_bPlayersLeftStart)
    {
        g_bPlayersLeftStart = true;
        CreateTimer(0.1, EVENT_SurvivorsLeftSaferoom, _, TIMER_FLAG_NO_MAPCHANGE);
        
        // enable all car alarms
        EnableAllCarAlarms();
    }
}

public Action:Event_PlayerTeam(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
    if (!IsClientAndInGame(client)) { return Plugin_Continue; }

    new newTeam = GetEventInt(hEvent, "team");
    new oldTeam = GetEventInt(hEvent, "oldteam");
    
    // count survivors joined after round start
    if (!g_bPlayersLeftStart && !g_bSurvivorsLoadedIn && newTeam == TEAM_SURVIVOR && !IsFakeClient(client))
    {
        CreateTimer( DELAY_SURVLOADEDCHECK, Timer_CheckSurvivorsLoadedIn, client, TIMER_FLAG_NO_MAPCHANGE );
    }
    
    // survivor-based events
    if (g_iSpecialEvent == EVT_PEN_ITEM)
    {
        // temporarily block pickup
        g_bArBlockPickupCall[client] = true;
        CreateTimer(0.01, Timer_UnblockWeaponPickupCall, client, TIMER_FLAG_NO_MAPCHANGE);
    }
    else if (g_iSpecialEvent == EVT_GUNSWAP && newTeam == TEAM_SURVIVOR)
    {
        CreateTimer(0.1, Timer_CheckSurvivorGun, client, TIMER_FLAG_NO_MAPCHANGE);
    }
    else if (g_bSpecialEventPlayerCheck)
    {
        // check if it's a client that should get the special role
        if ( newTeam == TEAM_SURVIVOR && CheckSpecialRoleMemory(client) && IsPlayerAlive(client) )
        {
            CreateTimer(DELAY_FORCEROLE, Timer_ForceSpecialEventRole, client, TIMER_FLAG_NO_MAPCHANGE);
        }
        
        if (!g_bSpecialRoleAboutToChange)
        {
            g_bSpecialRoleAboutToChange = true;
            
            new Handle:pack = CreateDataPack();
            WritePackCell(pack, g_bPlayersLeftStart);
            WritePackCell(pack, true);
            WritePackCell(pack, client);
            CreateTimer(DELAY_TEAMSWAP, Timer_CheckSpecialEventRole, pack, TIMER_FLAG_NO_MAPCHANGE);
        }
    }
    // do some delayed checks/changes when people go survivor/infected
    else if (g_iSpecialEvent == EVT_NOHUD || g_iSpecialEvent == EVT_DEFIB)
    {
        // oddity:  somehow timers swap the order of the infected => spec => survivor switch
        //          so just ignore specs for now
        new Handle:pack = CreateDataPack();
        WritePackCell(pack, client);
        WritePackCell(pack, newTeam);
        CreateTimer(DELAY_TEAMSWAP, Timer_TeamSwapDelayed, pack, TIMER_FLAG_NO_MAPCHANGE);
    }
    
    // spectate check / ghost check
    if (newTeam == TEAM_SPECTATOR && oldTeam == TEAM_INFECTED)
    {
        /*
            if they were a ghost (didn't spawn, didn't get tank and didn't die),
            remember and reset when a player returns
            no need to remember if it's still first attack (that's handled)
        */
        if (!g_bIsFirstAttack && !IsFakeClient(client) && g_bHasGhost[client])
        {
            new tmpClass = GetEntProp(client, Prop_Send, "m_zombieClass");
            if (tmpClass >= ZC_SMOKER && tmpClass <= ZC_CHARGER)
            {
                g_iSpectateGhost[g_iSpectateGhostCount] = tmpClass;
                if (g_iSpectateGhostCount < (TEAM_SIZE - 1)) {
                    g_iSpectateGhostCount++;
                }
            }
        }
        
    }
    
    if (oldTeam == TEAM_INFECTED) {
        g_bHasGhost[client] = false;
        g_bHasSpawned[client] = false;
    }
    
    return Plugin_Continue;
}

public Action:Timer_CheckSurvivorsLoadedIn(Handle:hTimer, any:client)
{
    if ( !IsClientAndInGame(client) ) { return Plugin_Continue; }
    
    PrintDebug(5, "[rand] Survivor loaded in (%N). %i / %i", client, GetConVarInt(g_hCvarTeamSize), CountHumanSurvivors());
    if (CountHumanSurvivors() >= GetConVarInt(g_hCvarTeamSize))
    {
        g_bSurvivorsLoadedIn = true;
        g_bBotsAllowedPickup = true;
        if (GetConVarBool(g_hCvarStopBotsAtStart)) { SetConVarInt(g_hCvarBotStop, 0); }
        EVENT_AllSurvivorsLoadedIn();
    }
    
    return Plugin_Continue;
}

public Action:Timer_TeamSwapDelayed(Handle:hTimer, any:pack)
{
    ResetPack(pack);
    new client = ReadPackCell(pack);
    new newTeam = ReadPackCell(pack);
    CloseHandle(pack);
    
    if (!IsClientAndInGame(client)) { return; }
    
    // remove / add hud
    if (g_iSpecialEvent == EVT_NOHUD && g_bPlayersLeftStart && !IsFakeClient(client))
    {
        if (newTeam == TEAM_INFECTED) {
            HUDRestoreClient(client);
        } else {
            HUDRemoveClient(client);
        }
    }
    // set thirdstrike
    else if (g_iSpecialEvent == EVT_DEFIB && newTeam == TEAM_SURVIVOR)
    {
        SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 1);
        //SetEntProp(client, Prop_Send, "m_isGoingToDie", 1);       // nice idea, but this breaks the health bars
    }
}



/*  Boomers
    --------------------------
    boomer stuff can't be (cleanly/consistently) done. it's a shame, but multiple boomers getting double booms on single survivors cannot be correctly detected
    combo's on multiple survivors can be done though, and we're doing it.
*/    
public Event_PlayerBoomed(Handle:event, const String:name[], bool:dontBroadcast)
{
    // only do it if there's a reward window
    if (GetConVarFloat(g_hCvarBoomedTime) == 0.0) { return; }
    
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    
    // only do it for infected booming survivors
    if (!IsSurvivor(client) || !IsInfected(attacker)) { return; }
    
    // boomer combo tracking
    g_iBoomedSurvivors[client] = attacker;
    new alreadyIn = false;
    for (new i = 0; i < TEAM_SIZE; i++)
    {
        if (g_iBoomersInCombo[i] == attacker) {
            g_iBoomsPerBoomer[i]++; // add one to the count
            g_fBoomTime[i] = GetEngineTime();
            alreadyIn = true;
        }
    }
    
    if (!alreadyIn) { 
        for (new i=0; i < TEAM_SIZE; i++)
        {
            if (g_iBoomersInCombo[i] == 0)
            {
                g_iBoomersInCombo[i] = attacker;
                g_iBoomsPerBoomer[i] = 1;
                g_fBoomTime[i] = GetEngineTime();
                //PrintToChatAll("Added to combo tracking: %i: %i", i, attacker);
                break;
            }
        }
        
        // only check/report combo's in this case -- on this boomer's first victim
        BoomerCheckCombo(client);
    }
}

public Event_PlayerUnboomed(Handle:event, const String:name[], bool:dontBroadcast)
{
    // only do it if there is a boom combo reward window
    if (GetConVarFloat(g_hCvarBoomedTime) == 0.0) { return; }
    
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    //PrintToChatAll("Boomer effect wore off (%i)", client);
    
    // remove client/boomer from combo tracking (if 0 survivors are boomed by it)
    if (client < 1 || client > MAXPLAYERS) { return; }
    
    for (new i=0; i < TEAM_SIZE; i++) {
        if (g_iBoomersInCombo[i] == g_iBoomedSurvivors[client]) {
            g_iBoomsPerBoomer[i]--;
            if (g_iBoomsPerBoomer[i] < 1) {
                g_iBoomsPerBoomer[i] = 0;
                //PrintToChatAll("Removing from combo tracking: %i: %i", i, g_iBoomedSurvivors[client]);
                g_iBoomersInCombo[i] = 0;
                g_fBoomTime[i] = 0.0;
            }
        }
    }
    g_iBoomedSurvivors[client] = 0;
}


// see if the boomer tracking shows 2+ combo
public BoomerCheckCombo(victim)
{
    new countBoomers = 0;
    new countTry = 0;
    new Float: fWindowTime = GetConVarFloat(g_hCvarBoomedTime);
    
    for (new i=0; i < TEAM_SIZE; i++) {
        if (g_iBoomersInCombo[i] == 0) { continue; }
        
        countTry = 1;
        
        // try this boomer's boom time as the start of the boom window
        //  if any of the other boomers' booms fit in the window, count them
        for (new j=0; j < TEAM_SIZE; j++) {
            if (j == i || g_iBoomersInCombo[j] == 0) { continue; }
            
            if (g_fBoomTime[j] >= g_fBoomTime[i] && g_fBoomTime[j] <= g_fBoomTime[i] + fWindowTime) {
                countTry++;
            }
        }
        
        //PrintToChatAll("Trying for boomer %i, start time: %.f: %i combo.", i, g_fBoomTime[i], countTry);
        if (countTry > countBoomers) { countBoomers = countTry; }
    }
    
    if (countBoomers > 1) {
        PrintToChatAll("\x01[\x05r\x01] \x04%i\x01-way boomer combo!", countBoomers);
        
        DoBoomerComboReward(countBoomers, victim);
    }
    
    return countBoomers;
}

// give boomers a reward for getting the combo
public DoBoomerComboReward(combo, victim)
{
    // do pipedud reward
    g_fDudTimeExpire = GetGameTime() + BOOMCOMBO_DUDTIME;
    
    // make sure we have a spawning client
    if (!IsClientAndInGame(victim) && !IsFakeClient(victim)) {
        victim = GetSpawningClient();
    }
    if ( !IsClientAndInGame(victim) ) {
        PrintDebug(2, "[rand] Couldn't reward %i-way boom combo (no spawning client available).", combo);
        return;
    }
    
    // give appropriate reward
    if (g_iSpecialEvent == EVT_WOMEN) 
    {
        // do something special for evt women?
        if (combo > 1)
        {
            SetConVarInt(FindConVar("z_common_limit"), RoundFloat(float(g_iDefCommonLimit) * g_RC_fEventCILimVeryHard) + (EVENT_WOMEN_EXTRACOMMON * (combo - 1)) );
            CreateTimer(1.0, Timer_CheckEndBoomComboReward, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
        }
        
        
        //  for now, just spawn panic hordes..
        if (combo > 2)
        {
            SpawnPanicHorde(victim, combo - 1);
        }
        
    }
    else
    {
        if (combo == 2 || combo == 3 || combo != TEAM_SIZE) {
            g_bBoomHighRewardMode = (combo == 3);
            g_iCommonBoomQueue += BOOMCOMBO_REWARD;
            SpawnCommon(BOOMCOMBO_REWARD);
        } else {
            // reward quad-combo with huge horde
            SpawnPanicHorde(victim, 2);
        }
    }
}

// unset common limit
public Action: Timer_CheckEndBoomComboReward(Handle:timer)
{
    if (GetGameTime() - g_fRewardTime > EVENT_WOMEN_LIMITTIME || !g_bInRound)
    {
        SetConVarInt( FindConVar("z_common_limit"), RoundFloat(float(g_iDefCommonLimit) * g_RC_fEventCILimVeryHard) );
        return Plugin_Stop;
    }
    return Plugin_Continue;
}

// boomer track
stock ClearBoomerTracking()
{
    for (new i = 1; i <= MAXPLAYERS; i++) {
        g_iBoomedSurvivors[i] = 0;
    }
    for (new i = 0; i < TEAM_SIZE; i++) {
        g_iBoomersInCombo[i] = 0;
        g_iBoomsPerBoomer[i] = 0;
        g_fBoomTime[i] = 0.0;
    }
}

/*  Player use & item pickup
    ------------------------ */
public Action:Event_PlayerUse(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    new entity = GetEventInt(event, "targetid");
    
    if (!IsValidEntity(entity) || !IsClientAndInGame(client) || IsFakeClient(client) || GetClientTeam(client) != TEAM_SURVIVOR) { return Plugin_Continue; }
    
    new String:classname[128];
    GetEdictClassname(entity, classname, sizeof(classname));
    
    //PrintToChatAll("%s", classname);
    
    new itemUseType: classnameUsed;
    if (!GetTrieValue(g_hTrieUseItems, classname, classnameUsed)) { return Plugin_Continue; }
    
    // check for boobytraps...
    if (g_iSpecialEvent == EVT_BOOBYTRAP)
    {
        new Float:targetPos[3];
        GetEntPropVector(entity, Prop_Send, "m_vecOrigin", targetPos);
        
        EVENT_CheckBoobyTrap(entity, targetPos, client);
    }
    
    /*
        new tmpHamId = GetEntProp(door, Prop_Data, "m_iHammerID");
        new tmpData = GetEntPropEnt(door, Prop_Data, "m_hOwnerEntity");
    */
    
    if (classnameUsed == ITEM_USE_DOOR)
    {
        // door:
        
        new bool: inArray = false;
        for (new i = 0; i < g_iDoorsLockedTotal; i++)
        {
            if (entity == g_iDoorsLocked[i]) {
                inArray = true;
                break;
            }
        }
        if (inArray)
        {
            // keymaster event!
            if (g_iSpecialEvent == EVT_KEYMASTER)
            {
                if (client != g_iSpecialEventRole) {
                    EmitSoundToAll(DOOR_SOUND, entity);
                    PrintToChat(client, "\x01[\x05r\x01] This door is locked, only keymaster %N may open it.", g_iSpecialEventRole);
                    return Plugin_Continue;
                } else {
                    
                    SUPPORT_ToggleDoor( entity );
                    return Plugin_Continue;
                }
            }
            else if (g_iSpecialEvent == EVT_DOORCIRCUS) {
                EmitSoundToAll(DOOR_SOUND, entity);
                PrintToChat(client, "\x01[\x05r\x01] This door opens and closes by itself...");
            }
            else {
                EmitSoundToAll(DOOR_SOUND, entity);
                PrintToChat(client, "\x01[\x05r\x01] This door is locked, break it down.");
            }
        }
    }
    else if (classnameUsed == ITEM_USE_PROP || classnameUsed == ITEM_USE_COLA)
    {
        // gnome/cola:
        if (GetConVarFloat(g_hCvarGnomeBonus) == 0.0) { return Plugin_Continue; }
        
        new String:modelname[STR_MAX_MODELNAME];
        GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, STR_MAX_MODELNAME);
        
        new bool: isGnome = false;
        new bool: isCola = false;
        if (classnameUsed != ITEM_USE_COLA)
        {
            isGnome = StrEqual(modelname, "models/props_junk/gnome.mdl", false);
            isCola = StrEqual(modelname, "models/w_models/weapons/w_cola.mdl", false);
        } else {
            isCola = true;
        }
        
        if (isGnome || isCola)
        {
            if (g_iJustPickedItemUp == GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"))
            {
                OnPlayerGnomePickup(client, entity, isGnome);
            }
            
            g_iJustPickedItemUp = 0;
        }
        
    }
    else if (g_iSpecialEvent == EVT_AMMO && classnameUsed == ITEM_USE_AMMO)
    {
        // pack in ammo again
        new Float:startPos[3];
        GetClientAbsOrigin(client, startPos);
        
        g_bShowedProgressHint = false;
        g_iClientUsing[client] = entity;
        SetupProgressBar(client, EVENT_AMMO_PACKTIME, startPos);
        
        new Handle:pack = CreateDataPack();
        WritePackCell(pack, client);
        WritePackCell(pack, entity);
        WritePackCell(pack, USING_TYPE_AMMO);
        
        CreateTimer(0.05, Timer_CheckPlayerUsing, pack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
        
        // do animation
        L4D2Direct_DoAnimationEvent(client, ANIM_EVENT_PLACE_THING);
    }
    return Plugin_Continue;
}

// track player holding use button (for special events)
public Action:Timer_CheckPlayerUsing(Handle:timer, any:pack)
{
    ResetPack(pack);
    new client = ReadPackCell(pack);
    new entity = ReadPackCell(pack);
    new itemType = ReadPackCell(pack);
    
    if (!IsClientAndInGame(client) || !IsValidEntity(entity)) { return Plugin_Stop; }
    
    new buttons = GetClientButtons(client);

    // if a player is close enough and still using... keep checking
    
    new Float:playerPos[3];
    GetClientAbsOrigin(client, playerPos);
    new Float: fDistance = GetVectorDistance(playerPos, g_fProgressLocation[client]);
    
    if ((!(buttons & IN_USE) && !g_bClientHoldingUse[client]) || fDistance > ITEM_USE_DISTANCE || client != SUPPORT_GetClientUsingEntity(entity))
    {
        KillProgressBar(client);
        g_bShowedProgressHint = false;
        g_iClientUsing[client] = 0;
        CloseHandle(pack);
        EndSurvivorAnim(client);
        //ShowWeapon(client);
        return Plugin_Stop;
    }
    
    // show hint text once
    if (!g_bShowedProgressHint && GetGameTime() - g_fProgressTime[client] > 0.5)
    {
        g_bShowedProgressHint = true;
        switch (itemType)
        {
            case USING_TYPE_AMMO: { PrintHintText(client, "Repacking ammo pile..."); }
            case USING_TYPE_GIFT: { PrintHintText(client, "Unwrapping gift..."); }
            default: { PrintHintText(client, "Doing something that takes time..."); }
        }
    }
    
    switch (itemType)
    {
        case USING_TYPE_AMMO:
        {
            if (GetGameTime() - g_fProgressTime[client] > EVENT_AMMO_PACKTIME)
            {
                EVENT_RepackAmmo(client, g_iDeployedAmmo);  // could use entity here.. see if we can remove iDeployedAmmo?
                g_bShowedProgressHint = false;
                g_iClientUsing[client] = 0;
                CloseHandle(pack);
                EndSurvivorAnim(client);
                //ShowWeapon(client);
                return Plugin_Stop;
            }
        }
        case USING_TYPE_GIFT:
        {
            if (GetGameTime() - g_fProgressTime[client] > USING_TIME_GIFT)
            {
                RANDOM_DoGiftEffect(client, g_iClientUsing[client]);
                g_bShowedProgressHint = false;
                g_iClientUsing[client] = 0;
                CloseHandle(pack);
                EndSurvivorAnim(client);
                //ShowWeapon(client);
                return Plugin_Stop;
            }
        }
        default: {
            // USING_TIME_DEFAULT;
            // do what?
            CloseHandle(pack);
            return Plugin_Stop;
        }
    }
    
    return Plugin_Continue;
}

public Action:Event_AmmoPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
    // when players use an ammo pile to fill their ak/scout/awp, change ammo total to new max
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (!IsClientAndInGame(client) || GetClientTeam(client) != TEAM_SURVIVOR) { return; }
    
    SUPPORT_CheckAmmo(client);
}

public Action:Event_ItemPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
    // this gets called first (but only if item was really picked up),
    // so use it to prepare player_use call
    
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (!IsClientAndInGame(client) || GetClientTeam(client) != TEAM_SURVIVOR) { return; }
    
    new String:sItem[32];
    GetEventString(event, "item", sItem, sizeof(sItem));
    
    // debug:
    //PrintToChatAll("picked up: %s", sItem);
    
    // special event:
    if (g_iSpecialEvent == EVT_PEN_ITEM)
    {
        // only give penalty outside of saferoom
        if (!SAFEDETECT_IsPlayerInStartSaferoom(client))
        {
            new itemPickupPenalty: itemHasPenalty;
            if (GetTrieValue(g_hTriePenaltyItems, sItem, itemHasPenalty))
            {
                // prevent double penalties for some items that are also weapons:
                if (itemHasPenalty == ITEM_PICKUP_PENALTY_SAW || itemHasPenalty == ITEM_PICKUP_PENALTY_MELEE) { return; }
                
                // it's a penaltied item, check if it's really picked up
                g_bArJustBeenGiven[client] = false;
                CreateTimer(TIMER_PICKUPCHECK, Timer_CheckItemPickup, client, TIMER_FLAG_NO_MAPCHANGE);
            }
        }
    }
    
    if (GetConVarFloat(g_hCvarGnomeBonus) == 0.0) { return; }
    
    // gnome
    new bool: isGnome = StrEqual(sItem, "gnome", false);
    new bool: isCola = (isGnome) ? false : StrEqual(sItem, "cola_bottles", false);
    
    if (isGnome || isCola)
    {
        // store entity no. -- rest is handled on PlayerUse event (called directly after ItemPickup)
        g_iJustPickedItemUp = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    }
}

// this is never called:
//public Action:Event_WeaponPickup(Handle:event, const String:name[], bool:dontBroadcast) { }

// for checking whether an item pickup call is really a weapon_given call
public Action:Timer_CheckItemPickup(Handle:hTimer, any:client)
{
    if (g_bArJustBeenGiven[client]) { return Plugin_Continue; }
    
    if (g_iSpecialEvent == EVT_PEN_ITEM)
    {
        g_iBonusCount++;
        PBONUS_AddRoundBonus( -1 * g_RC_iEventPenaltyItem );
        EVENT_PBonusChanged();
        EVENT_ReportPenalty(client);
    }
    
    return Plugin_Continue;
}

public Action:OnWeaponEquip(client, weapon)
{
    // SDKHooks weapon equiped
    if (!IsValidEntity(weapon) || !IsClientAndInGame(client)) { return Plugin_Continue; }
    
    // do nerf check (drops disallowed secondaries)
    if (g_bT2Nerfed && GetConVarBool(g_hCvarNerfT2))
    {
        new iTmpTierType = SUPPORT_IsNerfTier2(weapon);
        if (iTmpTierType)
        {
            g_fNerfMsgTimeout[client] = GetGameTime() + DELAY_T2_NERF_TIMEOUT;
            SUPPORT_FixNerfTier2(client, iTmpTierType);
        }
    }
    
    if (g_iSpecialEvent != EVT_PEN_ITEM) { return Plugin_Continue; }
    if (GetClientTeam(client) != TEAM_SURVIVOR || g_bArBlockPickupCall[client]) { return Plugin_Continue; }
    
    new String: classname[64];
    GetEdictClassname(weapon, classname, sizeof(classname));
    
    // debug
    //PrintToChatAll("%N equipped %i: %s", client, weapon, classname);
    
    // not the pistol you get when incapacitated -- or the weapon you get handed back on revived
    if (IsHangingFromLedge(client) || IsIncapacitated(client)) { return Plugin_Continue; }
    else if (g_fLastReviveTime[client] != 0.0 && GetGameTime() - g_fLastReviveTime[client] < 0.05) { return Plugin_Continue; }
    
    if (!SAFEDETECT_IsPlayerInStartSaferoom(client))
    {
        new itemPickupPenalty: itemHasPenalty;
        if (GetTrieValue(g_hTriePenaltyItems, classname, itemHasPenalty))
        {
            g_iBonusCount++;
            PBONUS_AddRoundBonus( -1 * g_RC_iEventPenaltyItem );
            EVENT_PBonusChanged();
            EVENT_ReportPenalty(client);
        }
    }
    
    return Plugin_Continue;
}


public Action:OnWeaponCanUse(client, weapon)
{
    // if we're blocking bots:
    if (!g_bCampaignMode && !GetConVarBool(g_hCvarStopBotsAtStart) && !g_bBotsAllowedPickup && IsFakeClient(client))
    {
        // still allow single pistol pickup
        if (!SUPPORT_PlayerHasPistol(client) && SUPPORT_EntityIsPistol(weapon))
        {
            return Plugin_Continue;
        }
        return Plugin_Handled;
    }
    
    // if we're nerfing t2s, block pickup of anything but single pistol
    if (!g_bT2Nerfed || !GetConVarBool(g_hCvarNerfT2)) { return Plugin_Continue; }
    if (!IsSurvivor(client)) { return Plugin_Continue; }
    
    new iNerfType = SUPPORT_PlayerHasT2(client);
    if (iNerfType && SUPPORT_IsNerfSecondary(weapon, client, iNerfType))
    {
        // not allowed
        if (g_fNerfMsgTimeout[client] == 0.0 || g_fNerfMsgTimeout[client] < GetGameTime())
        {
            if (iNerfType == NERFTYPE_T2) {
                PrintToChat(client, "\x01[\x05r\x01] Only single pistol allowed with \x04T2\x01 rifle/shotgun.");
                PrintHintText(client, "Only single pistol allowed with T2 rifle/shotgun.");
            } else {
                PrintToChat(client, "\x01[\x05r\x01] Only single or dual pistol allowed with \x04sniper\x01.");
                PrintHintText(client, "Only single or dual pistol allowed with sniper.");
            }
            g_fNerfMsgTimeout[client] = GetGameTime() + DELAY_T2_NERF_TIMEOUT;
            
        }
        return Plugin_Handled;
    }
    
    return Plugin_Continue;
}

public Action:Event_WeaponGiven(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (!IsClientAndInGame(client)) { return; }
    
    new weapId = GetEventInt(event, "weapon");
    
    if (weapId == WEPID_PAIN_PILLS || weapId == WEPID_ADRENALINE)
    {
        g_bArJustBeenGiven[client] = true;
        //PrintToChatAll("weapon given to %N: %i", client, weapId);
        
        // medic event: could be that the medic passed pills, check to be sure
        if (g_iSpecialEvent == EVT_MEDIC && client != g_iSpecialEventRole)
        {
            g_bMedicFirstHandout = true;
            CreateTimer(0.05, EVENT_TimerCheckMedic, _, TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

public Action:Event_WeaponDrop(Handle:event, const String:name[], bool:dontBroadcast)
{
    // this gets called first (but only if item was really picked up),
    // so use it to prepare player_use call
    
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    new entity = GetClientOfUserId(GetEventInt(event, "propid"));

    if (!IsClientAndInGame(client)) { return; }
    if (GetConVarFloat(g_hCvarGnomeBonus) == 0.0) { return; }
    
    new String:sItem[32];
    GetEventString(event, "item", sItem, sizeof(sItem));
    
    //PrintToChatAll("dropped weapon: ent %s", sItem);
    
    new itemDropType: nameDropped;
    if (!GetTrieValue(g_hTrieDropItems, sItem, nameDropped)) { return; }
    
    // only cola?
    if (nameDropped == ITEM_DROP_COLA)
    {
        // we're starting a gnome/cola drop (picked up when entity is created)
        OnPlayerDroppingCola(client, entity);
    }
    else if (g_iSpecialEvent == EVT_MEDIC && nameDropped == ITEM_DROP_HEALTH)
    {
        // find and kill the dropped item(s)
        CreateTimer(0.05, Timer_DestroyHealthItems, _, TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Action:Event_ReviveSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "subject"));
    if (!IsClientAndInGame(client)) { return; }
    g_fLastReviveTime[client] = GetGameTime();
    
    CreateTimer(0.1, Timer_CheckReviveStatus, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action: Timer_CheckReviveStatus ( Handle:timer, any:client )
{
    if (!IsClientAndInGame(client)) { return Plugin_Continue; }
    new chr = GetPlayerCharacter(client);
    
    // remove secondary weap if they had none on incapping
    if ( g_bPlayerIncapNoSecondary[chr] )
    {
        new weaponIndex = GetPlayerWeaponSlot(client, PLAYER_SLOT_SECONDARY);
        if ( weaponIndex > 0 )
        {
            RemovePlayerItem(client, weaponIndex);
        }
    }
    
    return Plugin_Continue;
}

/*  Weapon fire and item use
    ------------------------ */
public Action:Event_PlayerDefibbed(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "subject"));
    if (!IsClientAndInGame(client)) { return; }
    
    // if we're in no-hud mode, hide hud after defib
    if (g_iSpecialEvent == EVT_NOHUD && !IsFakeClient(client)) {
        HUDRemoveClient(client);
        return;
    }
    
    new user = GetClientOfUserId(GetEventInt(event, "userid"));
    
    if (g_iSpecialEvent == EVT_PEN_HEALTH) {
        g_iBonusCount++;
        PBONUS_AddRoundBonus( -1 * g_RC_iEventPenaltyHealth );
        EVENT_PBonusChanged();
        EVENT_ReportPenalty(user);
    }
    
    // if we want to be entirely spot on, we'll set any solid health to bleed health too
    // if we're doing EVT_DEFIB
    // but meh. random uses bwdefib plugin
}

public Action:Event_MedkitUsed(Handle:event, const String:name[], bool:dontBroadcast)
{
    new user = GetClientOfUserId(GetEventInt(event, "userid"));
    
    if (g_iSpecialEvent == EVT_PEN_HEALTH) {
        g_iBonusCount++;
        PBONUS_AddRoundBonus( -1 * g_RC_iEventPenaltyHealth );
        EVENT_PBonusChanged();
        EVENT_ReportPenalty(user);
    }
    else if (g_iSpecialEvent == EVT_MEDIC) {
        CreateTimer(0.05, EVENT_TimerCheckMedic, _, TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Action:Event_PillsUsed(Handle:event, const String:name[], bool:dontBroadcast)
{
    new user = GetClientOfUserId(GetEventInt(event, "userid"));
    
    if (g_iSpecialEvent == EVT_PEN_HEALTH) {
        g_iBonusCount++;
        PBONUS_AddRoundBonus( -1 * g_RC_iEventPenaltyHealth );
        EVENT_PBonusChanged();
        EVENT_ReportPenalty(user);
    }
    else if (g_iSpecialEvent == EVT_MEDIC && user == g_iSpecialEventRole) {
        CreateTimer(0.05, EVENT_TimerCheckMedic, _, TIMER_FLAG_NO_MAPCHANGE);
    }
}


// weaponfire
public Action:Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (!IsClientAndInGame(client) || GetClientTeam(client) != TEAM_SURVIVOR) { return; }
    
    // only on special event
    if (g_iSpecialEvent != EVT_GUNSWAP) { return; }

    // only if the weapon is a primary
    new weapId = GetEventInt(event, "weaponid");
    if (!SUPPORT_IsWeaponPrimary(weapId)) { return; }    
    
    g_iArGunAmmoCount[client]--;
    //PrintToChat(client, "primary fired: %i bullets left", g_iArGunAmmoCount[client]);
    
    if (g_iArGunAmmoCount[client] <= 0)
    {
        EVENT_SwapSurvivorGun(client);
    }
}


/*
    Ghosts and spawning events
    -------------------------- */

// l4downtown forward - players getting ghosts [warning: doesn't ALWAYS fire]
public L4D_OnEnterGhostState(client)
{
    PrintDebug( (g_bHasSpawned[client]) ? 4 : 6, "[rand si] %N entered ghost state (class %s).%s", client, g_csSIClassName[ GetEntProp(client, Prop_Send, "m_zombieClass") ], (g_bHasSpawned[client]) ? " Was spawned before." : "");
    
    if (IsInfected(client) && IsPlayerGhost(client))
    {
        if (!g_bHasSpawned[client])
        {
            g_bClassPicked[client] = true;
            DetermineSpawnClass(client, GetEntProp(client, Prop_Send, "m_zombieClass"));
        }
        else
        {
            // if it's a despawn/respawn, reset sack detection
            g_fGotGhost[client] = GetGameTime();
            g_fDeathAfterGhost[client] = 0.0;
        }
        
        g_bHasSpawned[client] = false;
    }
    
}

public Action:Event_GhostSpawnTime(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
    new Float: spawntime = GetEventFloat(hEvent, "spawntime");
    
    if (!IsInfected(client) || IsFakeClient(client)) { return; }
    
    // do a check after we're supposed to have a ghost -- to see if a class was properly picked
    CreateTimer(spawntime + 0.15, Timer_GhostStateCheck, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_GhostStateCheck(Handle:timer, any:client)
{
    if (g_bIsPaused || !IsInfected(client) || IsFakeClient(client)) { return Plugin_Continue; }

    if (!IsPlayerAlive(client) || !IsPlayerGhost(client)) { return Plugin_Continue; }
    
    if (!g_bClassPicked[client])
    {
        new zClass = GetEntProp(client, Prop_Send, "m_zombieClass");
        PrintDebug(1, "[rand si] caught non-detected ghost handout: %N did not get assigned a spawn (is now %s), doing it now.", client, (zClass > 0 && zClass <= ZC_CHARGER) ? g_csSIClassName[zClass] : "no class" );
        
        DetermineSpawnClass(client, zClass);
    }

    return Plugin_Continue;
}


// l4downtown forward - tank selection
public Action:L4D_OnTryOfferingTankBot(tank_index, &bool:enterStatis)
{
    if ( g_bCampaignMode ) { return Plugin_Continue; }
    
    // debug output
    new String: tmpPass[32];
    if (g_fTankPreviousPass != 0.0) {
        Format(tmpPass, sizeof(tmpPass), "previous pass: %.1fs ago", GetGameTime() - g_fTankPreviousPass);
    } else {
        Format(tmpPass, sizeof(tmpPass), "start of first pass");
    }
    if (IsClientAndInGame(g_iTankClient)) {
        PrintDebug(2, "[rand] debug tank pass: %N (bot: %i) -- iTankClient: %i (%N) (%s) - pass: %i / %i.",
                tank_index,
                IsFakeClient(tank_index),
                g_iTankClient,
                g_iTankClient,
                tmpPass,
                g_iTankPass,
                L4D2Direct_GetTankPassedCount()
            );
    }
    else {
        PrintDebug(2, "[rand] debug tank pass: %N (bot: %i) -- iTankClient: (none) (%s) - pass: %i / %i.",
                tank_index,
                IsFakeClient(tank_index),
                tmpPass,
                g_iTankPass,
                L4D2Direct_GetTankPassedCount()
            );
    }
    
    /*
        note: if tank_index is always the bot, even on real passes,
        switch to g_iTankClient, if that IS reliable, for the next bit:
    */
    
    // passing when a player passes it...
    if (!IsFakeClient(tank_index) || g_fTankPreviousPass != 0.0)
    {
        // check if it's a double pass
        if (g_fTankPreviousPass != 0.0 && GetGameTime() - g_fTankPreviousPass < DOUBLE_PASS_CHECK_TIME)
        {
            PrintDebug(2, "[rand] Preventing double pass on tank. Previous pass was %.2f seconds ago.", GetGameTime() - g_fTankPreviousPass);
            
            SetEntProp(tank_index, Prop_Send, "m_frustration", 0);
            //L4D2Direct_SetTankPassedCount(L4D2Direct_GetTankPassedCount() + 1);
            
            g_fTankPreviousPass = GetGameTime();
            return Plugin_Handled;
        }
        // 25% chance of keeping tank
        else if (GetRandomInt(0, GetConVarInt(g_hCvarTeamSize) - 1) == 0)
        {
            for (new i=1; i <= MaxClients; i++)
            {
                if (!IsClientInGame(i))
                    continue;
            
                if (!IsInfected(i))
                    continue;
                
                if (i == g_iTankClient) {
                    PrintHintText(i, "You get to keep the tank. Rage Meter Refilled");
                    PrintToChat(i, "\x01[\x05r\x01] You get to keep the tank. Rage Meter Refilled.");
                } else {
                    PrintHintText(i, "%N gets to keep the tank. Rage Meter Refilled", tank_index);
                    PrintToChat(i, "\x01[\x05r\x01] %N gets to keep the tank. Rage Meter Refilled.", tank_index);
                }
            }
            
            SetEntProp(tank_index, Prop_Send, "m_frustration", 0);
            L4D2Direct_SetTankPassedCount(L4D2Direct_GetTankPassedCount() + 1);
            
            g_fTankPreviousPass = GetGameTime();
            
            PrintDebug(2, "[rand] Allowing %N to keep tank for second pass.", tank_index);
            g_iTankPass++;
            return Plugin_Handled;
        }
        
        g_fTankPreviousPass = GetGameTime();
        g_iTankPass++;
        
        PrintDebug(3, "[rand] Passing tank (vanilla style).");
        return Plugin_Continue;
    }
    
    if (GetConVarBool(g_hCvarRandomTank))
    {
        ForceTankPlayer();
    }
    
    g_fTankPreviousPass = GetGameTime();
    g_iTankPass++;

    return Plugin_Continue;
}

// right before player goes down
public Action:Event_IncapStart(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
    
    // check whether they had a secondary
    new slotSec = GetPlayerWeaponSlot(client, PLAYER_SLOT_SECONDARY);
    new chr = GetPlayerCharacter(client);
    
    g_bPlayerIncapNoSecondary[chr] = bool:( slotSec < 1 || !IsValidEntity(slotSec) );
    
}

public Action:Event_PlayerSpawn(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));

    if (!IsClientAndInGame(client) || GetClientTeam(client) != TEAM_INFECTED) { return Plugin_Continue; }
    
    new iClass = GetEntProp(client, Prop_Send, "m_zombieClass");
    
    // for special women event, replace male with female boomer
    if ( g_iSpecialEvent == EVT_WOMEN && iClass == ZC_BOOMER )
    {
        new String:model[64];
        GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
        
        if (StrEqual(model, "models/infected/boomer.mdl", false)) {
            SetEntityModel(client, MODEL_BOOMETTE);
        }
    }
    
    if (IsFakeClient(client)) { return Plugin_Continue; }
    
    g_bHasGhost[client] = false;
    
    if (iClass >= ZC_SMOKER && iClass <= ZC_CHARGER) {
        g_bHasSpawned[client] = true;
    }

    return Plugin_Continue;
}

public Action:Event_PlayerDeath(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
    new victim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
    new attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker")); 
    
    if ( !victim )
    {
        // common infected died
        new common = GetEventInt(hEvent, "entityid");
        
        if (GetRandomFloat(0.001, 1.0) <= GetConVarFloat(g_hCvarItemDropChance))
        {
            new Float: loc[3];
            new Float:vel[3];
            
            GetEntPropVector(common, Prop_Send, "m_vecOrigin", loc);
            loc[2] += 10.0;
            vel[0] = GetRandomFloat(-80.0, 80.0);
            vel[1] = GetRandomFloat(-80.0, 80.0);
            vel[2] = GetRandomFloat(40.0, 80.0);
            
            // pick a random item (different list) and spawn it
            SpawnCommonItem(loc, vel);
        }
        else if ( g_iSpecialEvent == EVT_BAY )
        {
            if (GetRandomFloat(0.001,1.0) <= g_RC_fEventBayCIChance)
            {
                new Float: targetPos[3];
                GetEntPropVector(common, Prop_Send, "m_vecOrigin", targetPos);
                
                new Handle:pack = CreateDataPack();
                if ( GetRandomInt(0, 9) == 0 ) { 
                    WritePackFloat(pack, g_RC_fExplosionPowerLow);
                } else {
                    WritePackFloat(pack, -2.0); // -2 = small explosion
                }
                WritePackFloat(pack, targetPos[0]);
                WritePackFloat(pack, targetPos[1]);
                WritePackFloat(pack, targetPos[2]);
                WritePackCell(pack, 0); // for fire
                CreateTimer(0.1, Timer_CreateExplosion, pack, TIMER_FLAG_NO_MAPCHANGE);
            }
        }
        
        return Plugin_Continue;
    }
    
    if ( !IsClientAndInGame(victim) ) { return Plugin_Continue; }
    
    // survivor dies
    // -------------------
    if (IsSurvivor(victim))
    {
        RemoveHat(victim);
        
        // remove hud if we're in special event
        if (g_iSpecialEvent == EVT_NOHUD && !IsFakeClient(victim))
        {
            HUDRemoveClient(victim);
        }
        else if (g_bSpecialEventPlayerCheck)
        {
            new Handle:pack = CreateDataPack();
            WritePackCell(pack, true);
            WritePackCell(pack, false);
            WritePackCell(pack, victim);
            CreateTimer(0.1, Timer_CheckSpecialEventRole, pack, TIMER_FLAG_NO_MAPCHANGE);
        }
        
        // check gnome status
        new gnomeIndex = FindGnomeIndexByClient(victim);
        
        if (gnomeIndex == -1) {
            gnomeIndex = FindGnomeIndex( GetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon") );
        }
        
        if (gnomeIndex != -1) {
            // update gnome, not held anymore
            RemoveGnomeHeld(g_strArGnomes[gnomeIndex][gnomeEntity]);
            
            g_strArGnomes[gnomeIndex][gnomebHeldByPlayer] = false;
            g_strArGnomes[gnomeIndex][gnomeiHoldingClient] = 0;
        }
        
        if ( g_iSpecialEvent == EVT_BAY ) {
            new Float: targetPos[3];
            GetClientAbsOrigin(victim, targetPos);
            
            new Handle:pack = CreateDataPack();
            WritePackFloat(pack, -2.0); // -2 = small explosion
            WritePackFloat(pack, targetPos[0]);
            WritePackFloat(pack, targetPos[1]);
            WritePackFloat(pack, targetPos[2]);
            WritePackCell(pack, 0); // for fire
            CreateTimer(0.1, Timer_CreateExplosion, pack, TIMER_FLAG_NO_MAPCHANGE);
        }
    }
    // -------------------
    
    if ( !IsClientAndInGame(attacker) || GetClientTeam(victim) != TEAM_INFECTED ) { return Plugin_Continue; }
    
    new zClass = GetEntProp(victim, Prop_Send, "m_zombieClass");
    
    if (!IsFakeClient(victim))
    {
        // death order:
        if (GetConVarInt(g_hCvarDeathOrderMode) > 0 && zClass >= ZC_SMOKER && zClass <= ZC_CHARGER)
        {
            new dMode = GetConVarInt(g_hCvarDeathOrderMode);
            
            // no timeouts for some special event classes
            if (    ( (g_iSpecialEvent != EVT_SKEET || g_iSpecialEvent != EVT_L4D1) || zClass != ZC_HUNTER)
                &&  (g_iSpecialEvent != EVT_WOMEN || (zClass != ZC_BOOMER && zClass != ZC_SPITTER) )
            ) {
                if (dMode == 1) {
                    g_iClassTimeout[zClass] = 3;
                } else {
                    g_iClassTimeout[zClass] = 4;
                }
            }
        }
        
        // sack protection, check if someone got a ghost and doesn't have a first death set yet
        g_fGotGhost[victim] = 0.0;
        g_fDeathAfterGhost[victim] = 0.0;
        
        // do we need to !g_bIsFirstAttack block this? try with leftstart only
        if (g_bPlayersLeftStart)
        {
            for (new i=0; i <= MaxClients; i++) {
                if (i == victim) { continue; }
                
                if (g_fGotGhost[i] != 0.0 && g_fDeathAfterGhost[i] == 0.0 && GetGameTime() - g_fGotGhost[i] > SACKPROT_MARGIN)
                {
                    g_fDeathAfterGhost[i] = GetGameTime();
                }
            }
        }
        
        /*
            this is also called when a player spectates
            so we have to distinguish between an actual death and a 'spectate death'
        */
        if (!g_bSpectateDeath[victim]) {
            g_bHasGhost[victim] = false;
            g_bHasSpawned[victim] = false;
        } else {
            g_bSpectateDeath[victim] = false;
        }
        g_bClassPicked[victim] = false;
    }
    
    // explode?
    if ( g_iSpecialEvent == EVT_BAY ) {
        
        if (GetRandomFloat(0.001,1.0) <=  g_RC_fEventBaySIChance)
        {
            new Float: targetPos[3];
            GetClientAbsOrigin(victim, targetPos);
            
            new Handle:pack = CreateDataPack();
            if ( GetRandomInt(0, 9) == 0 ) { 
                WritePackFloat(pack, g_RC_fExplosionPowerLow);
            } else {
                WritePackFloat(pack, -2.0); // -2 = small explosion
            }
            WritePackFloat(pack, targetPos[0]);
            WritePackFloat(pack, targetPos[1]);
            WritePackFloat(pack, targetPos[2]);
            WritePackCell(pack, 0); // for fire
            CreateTimer(0.1, Timer_CreateExplosion, pack, TIMER_FLAG_NO_MAPCHANGE);
        }
    }
    
    // tank stuff:
    if (!g_bIsTankInPlay || victim != g_iTankClient) { return Plugin_Continue; }
    
    // remember place where tank died
    GetClientAbsOrigin(victim, g_fTankDeathLocation);
    //GetEntPropVector(victim, Prop_Send, "m_vecOrigin", g_fTankDeathLocation); <- better or worse? test.
    
    CreateTimer(0.1, Timer_CheckTankDeath, victim); // Use a delayed timer due to bugs where the tank passes to another player
    
    return Plugin_Continue;
}

public Action:Event_TankSpawned(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
    
    PrintDebug(4, "[rand si] Tank spawned: %N.", client);
    
    // freeze points?
    if ( g_bFreezeDistanceOnTank )
    {
        if ( g_iSpecialEvent == EVT_MINITANKS ) {
            CreateTimer( DELAY_MINITANKFREEZE, Timer_FreezePoints, (g_bReportFreezing) ? 1 : 0, TIMER_FLAG_NO_MAPCHANGE );
        } else {
            SUPPORT_FreezePoints( g_bReportFreezing );
        }
    }
    
    // tank and ghost stuff:
    g_iTankClient = client;
    
    // if we have multitanks, prepare next
    if (g_iSpecialEvent == EVT_MINITANKS)
    {
        // only when it's the first pass
        /*
            try when tank dies, to avoid 2 tanks at the same time...
        if (!g_bIsTankInPlay) {
            CreateTimer(1.0, Timer_PrepareNextTank, _, TIMER_FLAG_NO_MAPCHANGE);
        }
        */
        //CreateTimer(1.0, Timer_SetTankMiniScale, client, TIMER_FLAG_NO_MAPCHANGE);
    }
    else if ( !g_bFirstTankSpawned )  // double tank ?
    {
        if (!g_bIsTankInPlay)
        {
            g_bFirstTankSpawned = true;
        }
    }
    /*
    else if ( g_bDoubleTank && g_bSecondTankSet )
    {
        g_bSecondTankSpawned = true;
    }
    */
    
    if (!g_bIsTankInPlay) { g_bIsTankInPlay = true; }
    
    // ghost stuff:
    if (!IsClientAndInGame(client) || IsFakeClient(client)) { return Plugin_Continue; }
    
    g_bHasGhost[client] = false;
    g_bHasSpawned[client] = false;
    g_bClassPicked[client] = false;
    
    return Plugin_Continue;
}


public Action:Timer_CheckTankDeath(Handle:hTimer, any:client_oldTank)
{
    if (g_iTankClient != client_oldTank) { return Plugin_Continue; }
 
    new tankclient = FindTankClient();
    if (tankclient && tankclient != client_oldTank)
    {
        g_iTankClient = tankclient;
        return Plugin_Continue;
    }
    
    // do whatever you do when tank is dead...
    g_iTankClient = 0;
    g_fTankPreviousPass = 0.0;
    g_iTankPass = 0;
    g_bIsTankInPlay = false;
    
    if ( !g_bFirstTankDied ) {
        g_bFirstTankDied = true;
        g_bSecondTankSet = false;       // safeguard
        //g_bSecondTankSpawned = false;   // safeguard
    }
    
    // spawn/set next tank
    if (g_iSpecialEvent == EVT_MINITANKS || (g_bDoubleTank && !g_bSecondTankSet) )
    {
        CreateTimer(0.5, Timer_PrepareNextTank, _, TIMER_FLAG_NO_MAPCHANGE);
    }
    
    // unfreeze points (if no further tanks in play)
    if ( g_bFreezeDistanceOnTank && FindTankClient() == 0 ) {
        SUPPORT_UnFreezePoints( g_bReportFreezing );
    }
    
    // drop stuff?
    if (g_iSpecialEvent != EVT_MINITANKS) {
        RANDOM_TankDropItems();
    }
    
    // explode?
    if ( g_iSpecialEvent == EVT_BAY ) {
        
        if ( GetRandomFloat(0.001,1.0) <= g_RC_fEventBaySIChance )
        {
            new Handle:pack = CreateDataPack();
            WritePackFloat(pack, g_RC_fExplosionPowerHigh);
            WritePackFloat(pack, g_fTankDeathLocation[0]);
            WritePackFloat(pack, g_fTankDeathLocation[1]);
            WritePackFloat(pack, g_fTankDeathLocation[2]);
            WritePackCell(pack, GetRandomInt(0,1) ); // for fire
            CreateTimer(0.1, Timer_CreateExplosion, pack, TIMER_FLAG_NO_MAPCHANGE);
        }
    }
    
    return Plugin_Continue;
}


/* Witch events */
public Event_WitchDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (g_iSpecialEvent != EVT_WITCHES) { return; }
    
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    new witchEnt = GetEventInt(event, "witchid");
    
    // witch was killed, give bonus to survivors (if killer was a survivor)
    if (!IsClientAndInGame(client) || GetClientTeam(client) != TEAM_SURVIVOR) { return; }
    
    PrintDebug(4, "[rand] witch died: entity: %i; bungled: %i", witchEnt, g_bWitchBungled[witchEnt]);
    
    // only give points if not bungled
    if ( g_bWitchBungled[witchEnt] ) {
        PrintToChatAll("\x01[\x05r\x01] Survivors bungled the witch kill. Bonus points denied.");
        g_bWitchBungled[witchEnt] = false;
    }
    else {
        g_iBonusCount++;
        PBONUS_AddRoundBonus( g_RC_iEventBonusWitch );
        EVENT_PBonusChanged();
        PrintToChatAll("\x01[\x05r\x01] Survivors killed a witch for \x04%i\x01 points.", g_RC_iEventBonusWitch);
    }
}
/* public Event_WitchSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
} */

public Event_WitchHarasserSet(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (g_iSpecialEvent != EVT_WITCHES) { return; }
    
    new witch = GetEventInt(event, "witchid");
    SetEntProp(witch, Prop_Send, "m_iGlowType", 0);
}



/*
    Uncommon infected spawning
    and pipebomb dudding
    -------------------------- */
public OnEntityCreated(entity, const String:classname[])
{
    if (!g_bModelsPrecached) { return; }
    if (entity < 1 || !IsValidEntity(entity) || !IsValidEdict(entity)) { return; }
    
    //PrintToChatAll("created: %s", classname);
    
    new CreatedEntityType: classnameOEC;
    if (!GetTrieValue(g_hTrieEntityCreated, classname, classnameOEC)) { return; }
    
    if (classnameOEC == CREATED_WITCH)
    {
        if (g_iSpecialEvent == EVT_WOMEN)
        {
            // hook witch for damage
            SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage_Witch);
        }
        else if (g_iSpecialEvent == EVT_WITCHES)
        {
            CreateTimer(0.1, Timer_WitchSetGlows, entity, TIMER_FLAG_NO_MAPCHANGE);
        }
        
        if ( entity > 0 && entity < ENTITY_COUNT ) {
            g_bWitchBungled[entity] = false;
        }
        
        PrintDebug(3, "[rand] Witch spawned: entity %i", entity);
    }
    else if (classnameOEC == CREATED_INFECTED) 
    {
        
        // for women special event... make them female, no uncommon
        if (g_iSpecialEvent == EVT_WOMEN)
        {
            if (entity > 0 && IsValidEntity(entity) && IsValidEdict(entity))
            {
                SDKHook(entity, SDKHook_SpawnPost, OnCommonInfectedSpawned);
            }
            return;
        }
        else if (g_iSpecialEvent == EVT_L4D1)
        {
            if (entity > 0 && IsValidEntity(entity) && IsValidEdict(entity))
            {
                SDKHook(entity, SDKHook_SpawnPost, OnL4D1CommonInfectedSpawned);
            }
            return;
        }
        
        new iBlockL4D1 = GetConVarInt(g_hCvarBlockL4D1Common);
        new Float: fChance = GetConVarFloat(g_hCvarUncommonChance);
        new bool: isUncommon = false;
        
        if (g_iSpecialEvent == EVT_UNCOMMON) { fChance = EVENT_UNCOMMON_CHANCE; }
        else if (g_iSpecialEvent == EVT_CLOWNS) { fChance = EVENT_CLOWNS_CHANCE; }
            
        // common infected, chance to spawn something else:
        if (g_iCommonBoomQueue == 0 && GetRandomFloat(0.001,1.0) <= fChance)
        {
            isUncommon = true;
            if (GetRandomFloat(0.001,1.0) <= GetConVarFloat(g_hCvarJimmyChance))
            {
                SetEntityModel(entity, "models/infected/common_male_jimmy.mdl");
            }
            else if (GetRandomFloat(0.001,1.0) <= GetConVarFloat(g_hCvarFallenChance))
            {
                SetEntityModel(entity, "models/infected/common_male_fallen_survivor.mdl");
            }
            else
            {
                if ((g_iSpecialEvent != EVT_UNCOMMON && g_iSpecialEvent !=  EVT_CLOWNS)
                    || g_iSpecialEventExtra == -1)
                {
                    SetEntityModel(entity, g_csUncommonModels[GetRandomInt(0, sizeof(g_csUncommonModels) - 1)]);
                } else {
                    // special event picked one type
                    SetEntityModel(entity, g_csUncommonModels[g_iSpecialEventExtra]);
                }
            }
        }
        else if (g_RC_bExtraCommonModels && GetRandomInt(0, CISKIN_EXTRA_RATE) == 0) {
            // it's still a common now, but it has a small chance of getting a sweet model
            SetEntityModel(entity, g_csExtraCommonModels[GetRandomInt(0, sizeof(g_csExtraCommonModels) - 1)]);
        }
        else if (iBlockL4D1 > 1) {
            // block all normally appearing l4d1 commons
            if (entity > 0 && IsValidEntity(entity) && IsValidEdict(entity))
            {
                SDKHook(entity, SDKHook_SpawnPost, OnL4D1CommonInfectedSpawned);
            }
        }
        
        // check boom queue
        if (g_iCommonBoomQueue > 0)
        {
            // this is an infected that was spawned by a boomer effect
            
            // so it is made, as a reward, an uncommon
            if (!isUncommon) {
                if (!g_bBoomHighRewardMode) {
                    // low reward: clowns, mudmen or construction workers
                    SetEntityModel(entity, g_csUncommonModels[ GetRandomInt(2, 4) ]);
                } else {
                    // high reward: riot COPSJ (index 0)
                    SetEntityModel(entity, g_csUncommonModels[0]);
                }
            }
            
            SetEntProp(entity, Prop_Send, "m_mobRush", 2);
            new ticktime = RoundToNearest( FloatDiv( GetGameTime() , GetTickInterval() ) ) + 5;
            SetEntProp(entity, Prop_Data, "m_nNextThinkTick", ticktime);
            
            ActivateEntity(entity);
            
            // clear the queue so we don't keep spawning
            g_iCommonBoomQueue--;
        }
    }
    else if (classnameOEC == CREATED_PIPEBOMB)
    {
        // this is not always a pipebomb (thanks valve :/)
        CreateTimer( 0.1, Timer_PipeCheck, entity);
    }
    else if (classnameOEC == CREATED_PROP_PHYSICS)
    {
        // is really the gnome?
        if (GetConVarFloat(g_hCvarGnomeBonus) == 0.0) { return; }
        
        CreateTimer(0.01, Timer_CreatedPropPhysics, entity, TIMER_FLAG_NO_MAPCHANGE);
    }
    else if (g_iSpecialEvent == EVT_AMMO && classnameOEC == CREATED_AMMO_DEPLOYED)
    {
        SetEntityModel(entity, "models/props/terror/ammo_stack.mdl");
        
        // create an ammo pile instead
        CreateTimer(0.01, EVENT_DeployAmmo, entity, TIMER_FLAG_NO_MAPCHANGE);
        //CreateTimer(0.025, EVENT_CheckDeployedAmmo, entity, TIMER_FLAG_NO_MAPCHANGE);
    }
    /* else if (g_iSpecialEvent == EVT_BAY && classnameOEC == CREATED_TANKROCK && GetEntProp(entity, Prop_Send, "m_iTeamNum") >= 0)
    {
        SDKHook(entity, SDKHook_Touch, OnTankRockTouchesSomething);
    } */
}

public Action: Timer_CreatedPropPhysics(Handle:timer, any:entity)
{
    // now the gnome we held is destroyed, so only check if we did drop one
    if (!IsValidEntity(entity) || !g_iGnomeJustDropped) { return Plugin_Continue; }
    
    new String:modelname[STR_MAX_MODELNAME];
    GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, STR_MAX_MODELNAME);
    
    new bool: isGnome = StrEqual(modelname, "models/props_junk/gnome.mdl", false);
    new bool: isCola = (isGnome) ? false : StrEqual(modelname, "models/w_models/weapons/w_cola.mdl", false);
    if (isGnome || isCola)
    {
        OnPossibleDroppedGnomeCreated(entity);
    }
    
    return Plugin_Continue;
}


public OnEntityDestroyed(entity)
{
    // can't check entity properties (since it's already destroyed)
    // so just check if a gnome was just created...
    
    if (g_iGnomesHeld && GetConVarFloat(g_hCvarGnomeBonus) >= 0.0)
    {
        OnPossibleGnomeDestroyed(entity);
    }
}


public Action:Timer_WitchSetGlows(Handle:timer, any:entity)
{
    // set glows for witch hunt
    if (IsValidEntity(entity)) {
        SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
        SetEntProp(entity, Prop_Send, "m_glowColorOverride", 0xFFFFFF);
    }
}
public Action:Timer_PipePreExplode(Handle:timer, any:entity)
{
    new Float: targetPos[3];
    GetEntPropVector(entity, Prop_Send, "m_vecOrigin", targetPos);
    
    // dudding pipebomb (simple kill)
    AcceptEntityInput(entity, "Kill");
    
    new Handle:pack = CreateDataPack();
    WritePackFloat(pack, g_RC_fExplosionPowerLow);
    WritePackFloat(pack, targetPos[0]);
    WritePackFloat(pack, targetPos[1]);
    WritePackFloat(pack, targetPos[2]);
    WritePackCell(pack, (GetRandomInt(0,5) == 0) ? 1 : 0 ); // for fire
    CreateTimer(0.1, Timer_CreateExplosion, pack, TIMER_FLAG_NO_MAPCHANGE);
}
public Action:Timer_PipeDud(Handle:timer, any:entity)
{
    // dudding pipebomb (simple kill)
    PrintToChatAll("\x01[\x05r\x01] Pipebomb was a dud!");
    AcceptEntityInput(entity, "Kill");
}

public Action:Timer_PipeCheck(Handle:timer, any:entity)
{
    // only proceed if it is really a pipe
    if (!IsValidEntity(entity)) { return; }
    
    new String:classname[64];
    GetEdictClassname(entity, classname, sizeof(classname));
    if (!StrEqual(classname, "pipe_bomb_projectile", false)) { return; }
    
    // bay event
    if ( g_iSpecialEvent == EVT_BAY )
    {
        CreateTimer( PIPEPRE_MINTIME + GetRandomFloat(0.0, PIPEPRE_ADDTIME) , Timer_PipePreExplode, entity);
        return;
    }
    
    // dud chance...
    //  affected by boomer combo
    new Float: fDudChance = GetConVarFloat(g_hCvarPipeDudChance);
    if (fDudChance > 0.0 && GetGameTime() < g_fDudTimeExpire) { fDudChance = g_RC_fBoomComboDudChance; }
    PrintDebug(6, "[rand] Dud chance: %.3f...", fDudChance);
    
    if ( GetRandomFloat(0.01,1.0) < fDudChance ) {
        CreateTimer( PIPEDUD_MINTIME + GetRandomFloat(0.0, PIPEDUD_ADDTIME) , Timer_PipeDud, entity);
    }
}





// hooked for BAY
/* rock hook
public OnTankRockTouchesSomething(entity)
{
    new Float: targetPos[3];
    GetEntPropVector(entity, Prop_Send, "m_vecOrigin", targetPos);
    
    new Handle:pack = CreateDataPack();
    WritePackFloat(pack, -1.0); // no damage just graphics
    WritePackFloat(pack, targetPos[0]);
    WritePackFloat(pack, targetPos[1]);
    WritePackFloat(pack, targetPos[2]);
    WritePackCell(pack, 0 ); // for fire
    CreateTimer(0.1, Timer_CreateExplosion, pack, TIMER_FLAG_NO_MAPCHANGE);
    
    SDKUnhook(entity, SDKHook_Touch, OnTankRockTouchesSomething);
}
*/

// from skill_detect
public OnSkeet ( attacker, victim )
{
    EVENT_HandleSkeet( attacker, victim );
}
public OnSkeetHurt ( attacker, victim, damage, bool:overkill )
{
    EVENT_HandleNonSkeet( victim, damage, overkill );
}
public OnSkeetMelee ( attacker, victim )
{
    EVENT_HandleSkeet( attacker, victim, true );
}
/* public OnSkeetMeleeHurt ( attacker, victim, damage )
{
    EVENT_HandleNonSkeet( victim, damage, overkill );
}
*/
public OnSkeetSniper ( attacker, victim )
{
    EVENT_HandleSkeet( attacker, victim, false, true );
}
public OnSkeetSniperHurt ( attacker, victim, damage, bool:overkill )
{
    EVENT_HandleNonSkeet( victim, damage, overkill );
}

public OnSpecialShoved ( attacker, victim )
{
    if ( !IsClientAndInGame(attacker) || GetClientTeam(attacker) != TEAM_SURVIVOR || !IsClientAndInGame(victim) || GetClientTeam(victim) != TEAM_INFECTED) { return; }
    
    // don't count bots shoving...
    if ( g_iSpecialEvent == EVT_PEN_M2 && !IsFakeClient(attacker) )
    {
        // only on cappers (except charger)
        new classType = GetEntProp(victim, Prop_Send, "m_zombieClass");
        if ( classType == ZC_JOCKEY || classType == ZC_HUNTER || classType == ZC_SMOKER )
        {
            g_iBonusCount++;
            PBONUS_AddRoundBonus( -1 * g_RC_iEventPenaltyM2SI );
            EVENT_PBonusChanged();
            EVENT_ReportPenalty(attacker, classType);
        }
    }
}

// hooked on EVT_WOMEN
public OnCommonInfectedSpawned(entity)
{
    // only proceed if it is really a pipe
    if (!IsValidEntity(entity)) { return; }
    
    new String:model[64];
    GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
    
    if (    StrContains(model, "_ceda") != -1
        ||  StrContains(model, "_clown") != -1
        ||  StrContains(model, "_mud") != -1
        ||  StrContains(model, "_riot") != -1
        ||  StrContains(model, "_roadcrew") != -1
    ) {
        // uncommon
        
        new Float: location[3];
        GetEntPropVector(entity, Prop_Send, "m_vecOrigin", location);
        
        AcceptEntityInput(entity, "Kill");
        
        SpawnCommonLocation(location, true);    // female common
        return;
    }
    
    // it's a normal common
    // if male, change it
    if (StrContains(model, "_male_") != -1)
    {
        SetEntityModel(entity, g_csFemaleCommonModels[ GetRandomInt(0, sizeof(g_csFemaleCommonModels) - 1) ]);
    }
}

public OnL4D1CommonInfectedSpawned(entity)
{
    // only proceed if it is really a pipe
    if (!IsValidEntity(entity)) { return; }
    
    new iBlockL4D1 = GetConVarInt(g_hCvarBlockL4D1Common);
    new String:model[64];
    GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
    
    new commonL4D1Type: modelCommon;
    
    // block uncommon infected, if it's the event
    if (g_iSpecialEvent == EVT_L4D1)
    {
        if (    StrContains(model, "_ceda") != -1
            ||  StrContains(model, "_clown") != -1
            ||  StrContains(model, "_mud") != -1
            ||  StrContains(model, "_riot") != -1
            ||  StrContains(model, "_roadcrew") != -1
        ) {
            // uncommon: block
            
            new Float: location[3];
            GetEntPropVector(entity, Prop_Send, "m_vecOrigin", location);
            
            AcceptEntityInput(entity, "Kill");
            
            SpawnCommonLocation(location, true);
            return;
        }
        else if (iBlockL4D1 == 3)
        {
            // common: replace with l4d1 common (safe)
            // only pick non-problematic skins
            SetEntityModel(entity, g_csL4D1CommonModels[GetRandomInt(L4D1_CI_FIRSTLOWERCHANCE + 1, sizeof(g_csL4D1CommonModels) - 1)] );
        }
        else if (iBlockL4D1 == 0)
        {
            // common: replace with l4d1 common
            if (GetRandomInt(0, CISKIN_L4D1_LESSER_RATE) == 0) {
                // less common skins
                if (GetRandomInt(0, CISKIN_L4D1_LEAST_RATE) == 0) {
                    SetEntityModel(entity, g_csL4D1CommonModels[GetRandomInt(L4D1_CI_FIRSTLOWERCHANCE, L4D1_CI_FIRSTLOWESTCHANCE - 1)] );
                } else {
                    SetEntityModel(entity, g_csL4D1CommonModels[GetRandomInt(L4D1_CI_FIRSTLOWESTCHANCE, sizeof(g_csL4D1CommonModels) - 1)] );
                }
            } else {
                // commonest
                SetEntityModel(entity, g_csL4D1CommonModels[GetRandomInt(0, L4D1_CI_FIRSTLOWERCHANCE - 1)]);
            }
        }
        
        return;
    }
    
    // replace l4d1 commons with l4d2 common (only gets called on blockmode 1)
    if (!GetTrieValue(g_hTrieL4D1Common, model, modelCommon)) { return; }
    
    if ( iBlockL4D1 == 2 || iBlockL4D1 == 3 && modelCommon == COMMON_L4D1_PROBSKIN )
    {
        // l4d2 common
        if (GetRandomInt(0,1)) {
            SetEntityModel(entity, g_csMaleCommonModels[ GetRandomInt(0, sizeof(g_csMaleCommonModels) - 1) ] );
        } else {
            SetEntityModel(entity, g_csFemaleCommonModels[ GetRandomInt(0, sizeof(g_csFemaleCommonModels) - 1) ] );
        }
        
        SetEntProp(entity, Prop_Send, "m_nSkin", (GetRandomInt(0,1)) ? 1 : 4 );
    }
}

/*  SI Spawning
    ----------- */
public GetClassForFirstAttack(ignoreClient)
{
    // check the current spawns up and compare them to the stored spawns
    //  add one that isn't up yet
    
    new classCount[ZC_TOTAL], neededCount[ZC_TOTAL], classType;
    
    for (new i=1; i <= MaxClients; i++)
    {
        if (i == ignoreClient) { continue; }                                // so it doesn't count the client's class that it is about to change..

        if (IsValidEntity(i) && IsClientInGame(i) && GetClientTeam(i) == TEAM_INFECTED && !IsFakeClient(i) && IsPlayerAlive(i))
        {
            classType = GetEntProp(i, Prop_Send, "m_zombieClass");
            if (classType < 0 || classType > ZC_TOTAL - 1) { classType = 0; }  // safeguard
            classCount[classType]++;
        }
    }
        
    // got all the counts, check what we still need
    for (new j=0; j < TEAM_SIZE; j++) {
        classType = g_iArStorageSpawns[j];
        neededCount[classType]++;
    }
    
    // if any class still needs a spawn, return it
    for (new j = ZC_SMOKER; j <= ZC_CHARGER; j++) {
        if (classCount[j] < neededCount[j]) { return j; }
    }
    
    // shouldn't happen, but just return hunter
    PrintDebug(0, "[rand si] ERROR, no first attack storage entry found. should never happen");
    return ZC_HUNTER;
}


// special ammo types
public Action:Event_SpecialAmmoDeploy(Handle:event, const String:name[], bool:dontBroadcast)
{
    // if it's the ammo pack
    if (g_iSpecialEvent != EVT_AMMO) { return; }
    
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (!IsClientAndInGame(client)) { return; }
    
    new Float: targetPos[3];
    GetClientAbsOrigin(client, targetPos);
    
    g_fAmmoDeploySpot = targetPos;
}
    
//      used to limit amount of special ammo in extra clip..
public Action:Event_SpecialAmmo(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    
    new upgradeid = GetEventInt(event, "upgradeid");
    decl String:class[256];
    GetEdictClassname(upgradeid, class, sizeof(class));
    
    if (!IsClientAndInGame(client)) { return; }
    if (StrEqual(class, "upgrade_laser_sight")) { return; }
    
    // get clipsize for special ammo, apply factor
    new gunEnt = GetPlayerWeaponSlot(client, 0);
    if (!IsValidEdict(gunEnt)) { return; }
    
    new oldAmmo = GetEntProp(gunEnt, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", 1);
    new newAmmo = 0;
    
    if (StrEqual(class, "upgrade_ammo_incendiary"))
    {
        newAmmo = RoundFloat(float(oldAmmo) * GetConVarFloat(g_hCvarClipFactorInc));
        SetEntProp(gunEnt, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", newAmmo, 1);
    }
    else if (StrEqual(class, "upgrade_ammo_explosive"))    
    {
        newAmmo = RoundFloat(float(oldAmmo) * GetConVarFloat(g_hCvarClipFactorExp));
        SetEntProp(gunEnt, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", newAmmo, 1);
    }
}




