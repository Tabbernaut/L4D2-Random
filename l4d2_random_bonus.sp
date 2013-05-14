#include <sourcemod.inc>
#include <sdkhooks>
#include <sdktools>
#include <left4downtown>
#include <l4d2_random>

#define MAX(%0,%1) (((%0) > (%1)) ? (%0) : (%1))

#define TEAM_SURVIVOR   2


public Plugin:myinfo =
{
    name = "Damage Scoring [adjusted for Random config]",
    author = "CanadaRox, Tabun",
    description = "Custom damage scoring based on damage and a static bonus. Adjusted for use with Random config.",
    version = "0.999c",
    url = "https://github.com/CanadaRox/sourcemod-plugins"
};

new Handle: hTeamSize;

new Handle: hSurvivalBonusCvar;
new         iSurvivalBonusDefault;

new Handle: hTieBreakBonusCvar;
new         iTieBreakBonusDefault;

/*
new Handle: hStaticBonusCvar;
new Handle: hMaxDamageCvar;
new Handle: hDamageMultiCvar;
*/

new         iHealth[MAXPLAYERS + 1];
new         bTookDamage[MAXPLAYERS + 1];
new         iTotalDamage[2];
new bool:   bHasWiped[2];                   // true if they didn't get the bonus...
new bool:   bRoundOver[2];                  // whether the bonus will still change or not
new         iStoreBonus[2];                 // what was the actual bonus?
new         iStoreSurvivors[2];             // how many survived that round?
new         iStoreExtra[2];                 // what was the 'extra bonus'?

// random added:
new         iSettingBonus =     400;    // this value is set to random plugin's options, or uses this plugin's cvars
new         iSettingStatic =    0;      // this value is set to random plugin's options, or uses this plugin's cvars
new Float:  fSettingMulti =     0.5;    // same
new         iRoundExtra =       0;      // this amount of points (total, so scaled back against alive-survivor) gets added (for random scoring fun)


/*
 *      Natives
 *      =======
 */
 
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    CreateNative("RNDBNS_GetBonus",         Native_GetBonus);
    CreateNative("RNDBNS_GetBonusMulti",    Native_GetBonusMulti);
    CreateNative("RNDBNS_GetStatic",        Native_GetStatic);
    //CreateNative("RNDBNS_GetDistance",      Native_GetDistance);
    CreateNative("RNDBNS_SetBonus",         Native_SetBonus);
    CreateNative("RNDBNS_SetBonusMulti",    Native_SetBonusMulti);
    CreateNative("RNDBNS_SetStatic",        Native_SetStatic);
    //CreateNative("RNDBNS_SetDistance",      Native_SetDistance);
    CreateNative("RNDBNS_SetExtra",         Native_SetExtra);
    
    MarkNativeAsOptional("RNDMAIN_GetGnomeBonus");  // so we can load this plugin before main
    MarkNativeAsOptional("RNDMAIN_ShowGnomeBonus");
    
    return APLRes_Success;
}


public Native_GetBonus(Handle:plugin, numParams)
{
    new value = iSettingBonus;
    return _:value;
}
public Native_GetBonusMulti(Handle:plugin, numParams)
{
    new Float:value = fSettingMulti;
    return _:value;
}
/*
public Native_GetDistance(Handle:plugin, numParams)
{
    new value = iMapDistance;
    return _:value;
}
*/
public Native_GetStatic(Handle:plugin, numParams)
{
    new value = iSettingStatic;
    return _:value;
}

public Native_SetBonus(Handle:plugin, numParams)
{
    new value = GetNativeCell(1);
    iSettingBonus = value;
    
    // automatically adjust bonus multiplier
    // 800 = 1.0
    fSettingMulti = float(iSettingBonus) / 800.0;
    return;
}
public Native_SetBonusMulti(Handle:plugin, numParams)
{
    new Float: value = Float: GetNativeCell(1);
    fSettingMulti = value;
    return;
}
/*
public Native_SetDistance(Handle:plugin, numParams)
{
    new value = GetNativeCell(1);
    iMapDistance = value;
    return;
}
*/
public Native_SetStatic(Handle:plugin, numParams)
{
    new value = GetNativeCell(1);
    iSettingStatic = value;
    return;
}
public Native_SetExtra(Handle:plugin, numParams)
{
    new value = GetNativeCell(1);
    iRoundExtra = value;
    return;
}




public OnPluginStart()
{
    // Score Change Triggers
    HookEvent("door_close", DoorClose_Event);
    HookEvent("player_death", PlayerDeath_Event);
    HookEvent("finale_vehicle_leaving", FinaleVehicleLeaving_Event, EventHookMode_PostNoCopy);
    HookEvent("player_ledge_grab", PlayerLedgeGrab_Event);

    HookEvent("round_end", RoundEnd_Event);

    // Save default Cvar value
    hSurvivalBonusCvar = FindConVar("vs_survival_bonus");
    iSurvivalBonusDefault = GetConVarInt(hSurvivalBonusCvar);
    
    hTieBreakBonusCvar = FindConVar("vs_tiebreak_bonus");
    iTieBreakBonusDefault = GetConVarInt(hTieBreakBonusCvar);

    hTeamSize = FindConVar("survivor_limit");
    
    /*
    // Configuration Cvars
    hStaticBonusCvar = CreateConVar("sm_static_bonus", "25.0", "Extra static bonus that is awarded per survivor for completing the map", FCVAR_PLUGIN, true, 0.0);
    hMaxDamageCvar = CreateConVar("sm_max_damage", "800.0", "Max damage used for calculation (controls x in [x - damage])", FCVAR_PLUGIN);
    hDamageMultiCvar = CreateConVar("sm_damage_multi", "1.0", "Multiplier to apply to damage before subtracting it from the max damage", FCVAR_PLUGIN, true, 0.0);
    */
    
    // Chat cleaning
    AddCommandListener(Command_Say, "say");
    AddCommandListener(Command_Say, "say_team");

    RegConsoleCmd("sm_damage", Damage_Cmd, "Prints the damage taken by both teams");
    RegConsoleCmd("sm_health", Damage_Cmd, "Prints the damage taken by both teams (Legacy option since I'll get yelled at without it!)");
}

public OnPluginEnd()
{
    SetConVarInt(hSurvivalBonusCvar, iSurvivalBonusDefault);
    SetConVarInt(hTieBreakBonusCvar, iTieBreakBonusDefault);
}

public OnMapStart()
{
    for (new i=0; i < 2; i++)
    {
        iTotalDamage[i] = 0;
        iStoreBonus[i] = 0;
        iStoreSurvivors[i] = 0;
        bRoundOver[i] = false;
        bHasWiped[i] = false;
    }
}

public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
    SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
}

public OnClientDisconnect(client)
{
    SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
    SDKUnhook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
}

public Action:Damage_Cmd(client, args)
{
    DisplayBonus(client);
    return Plugin_Handled;
}

public RoundEnd_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
    // set whether the round was a wipe or not
    if (!GetUprightSurvivors()) {
        bHasWiped[GameRules_GetProp("m_bInSecondHalfOfRound")] = true;
    }
    
    // when round is over, 
    bRoundOver[GameRules_GetProp("m_bInSecondHalfOfRound")] = true;

    new reason = GetEventInt(event, "reason");
    if (reason == 5)
    {
        DisplayBonus();
    }
}

public DoorClose_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (GetEventBool(event, "checkpoint"))
    {
        SetConVarInt(hSurvivalBonusCvar, CalculateSurvivalBonus());
        StoreBonus();
    }
}

public PlayerDeath_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));

    if (client && IsSurvivor(client))
    {
        SetConVarInt(hSurvivalBonusCvar, CalculateSurvivalBonus());
        StoreBonus();
    }
}

public FinaleVehicleLeaving_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
    for (new i = 1; i < MaxClients; i++)
    {
        if (IsClientInGame(i) && IsSurvivor(i) && IsPlayerIncap(i))
        {
            ForcePlayerSuicide(i);
        }
    }

    SetConVarInt(hSurvivalBonusCvar, CalculateSurvivalBonus());
    StoreBonus();
}

public OnTakeDamage(victim, attacker, inflictor, Float:damage, damagetype)
{
    iHealth[victim] = (!IsSurvivor(victim) || IsPlayerIncap(victim)) ? 0 : (GetSurvivorPermanentHealth(victim) + GetSurvivorTempHealth(victim));
    bTookDamage[victim] = true;
}

public PlayerLedgeGrab_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    new health = GetEntData(client, 14804, 4);
    new temphealth = GetEntData(client, 14808, 4);

    iTotalDamage[GameRules_GetProp("m_bInSecondHalfOfRound")] += health + temphealth;
}

public Action:L4D2_OnRevived(client)
{
    new health = GetSurvivorPermanentHealth(client);
    new temphealth = GetSurvivorTempHealth(client);

    iTotalDamage[GameRules_GetProp("m_bInSecondHalfOfRound")] -= (health + temphealth);
}

public OnTakeDamagePost(victim, attacker, inflictor, Float:damage, damagetype)
{
    if (iHealth[victim])
    {
        if (!IsPlayerAlive(victim) || (IsPlayerIncap(victim) && !IsPlayerHanging(victim)))
        {
            iTotalDamage[GameRules_GetProp("m_bInSecondHalfOfRound")] += iHealth[victim];
        }
        else if (!IsPlayerHanging(victim))
        {
            iTotalDamage[GameRules_GetProp("m_bInSecondHalfOfRound")] += iHealth[victim] - (GetSurvivorPermanentHealth(victim) + GetSurvivorTempHealth(victim));
        }
        iHealth[victim] = (!IsSurvivor(victim) || IsPlayerIncap(victim)) ? 0 : (GetSurvivorPermanentHealth(victim) + GetSurvivorTempHealth(victim));
    }
}

public Action:Command_Say(client, const String:command[], args)
{
    if (IsChatTrigger())
    {
        decl String:sMessage[MAX_NAME_LENGTH];
        GetCmdArg(1, sMessage, sizeof(sMessage));

        if (StrEqual(sMessage, "!damage")) return Plugin_Handled;
        else if (StrEqual (sMessage, "!sm_damage")) return Plugin_Handled;
        else if (StrEqual (sMessage, "!health")) return Plugin_Handled;
        else if (StrEqual (sMessage, "!sm_health")) return Plugin_Handled;
    }

    return Plugin_Continue;
}

stock GetDamage(round=-1)
{
    return (round == -1) ? iTotalDamage[GameRules_GetProp("m_bInSecondHalfOfRound")] : iTotalDamage[round];
}

stock StoreBonus()
{
    // store bonus for display
    new round = GameRules_GetProp("m_bInSecondHalfOfRound");
    new aliveSurvs = GetAliveSurvivors();
    
    iStoreBonus[round] = GetConVarInt(hSurvivalBonusCvar) * aliveSurvs;
    iStoreSurvivors[round] = GetAliveSurvivors();
    iStoreExtra[round] = iRoundExtra;
}

stock DisplayBonus(client=-1)
{
    new String:msgPartHdr[48];
    new String:msgPartDmg[48];
    
    // call for gnome bonus scoring native if we just finished a round
    if ((!GameRules_GetProp("m_bInSecondHalfOfRound") && bRoundOver[0]) || (GameRules_GetProp("m_bInSecondHalfOfRound") && bRoundOver[1])) {
        if (!bHasWiped[GameRules_GetProp("m_bInSecondHalfOfRound")]) {
            RNDMAIN_ShowGnomeBonus();
        }
    }
    
    for (new round = 0; round <= GameRules_GetProp("m_bInSecondHalfOfRound"); round++)
    {
        if (bRoundOver[round]) {
            Format(msgPartHdr, sizeof(msgPartHdr), "Round \x05%i\x01 bonus", round+1);
        } else {
            Format(msgPartHdr, sizeof(msgPartHdr), "Current Bonus");
        }

        if (bHasWiped[round]) {
            Format(msgPartDmg, sizeof(msgPartDmg), "\x03wipe\x01 (\x05%4d\x01 damage)", iTotalDamage[round]);
        } else {
            
            new tmpBonus = (bRoundOver[round]) ? iStoreBonus[round] : CalculateSurvivalBonus() * GetAliveSurvivors();
            
            if (bRoundOver[round] && iStoreExtra[round]) {
                tmpBonus -= iStoreExtra[round];
            } else if (iRoundExtra) {
                tmpBonus -= iRoundExtra;
            }
            
            Format(msgPartDmg, sizeof(msgPartDmg), "\x04%4d\x01 (\x05%4d\x01 damage)", tmpBonus, iTotalDamage[round] );
            
            // add extra bonus for random
            if (bRoundOver[round] && iStoreExtra[round]) {
                Format(msgPartDmg, sizeof(msgPartDmg), "%s + \x04%d\x01", msgPartDmg, iStoreExtra[round]);
            } else if (iRoundExtra) {
                Format(msgPartDmg, sizeof(msgPartDmg), "%s + \x04%d\x01", msgPartDmg, iRoundExtra);
            }
        }
        
        if (client == -1) {
            PrintToChatAll("\x01%s: %s", msgPartHdr, msgPartDmg);
        } else if (client) {
            PrintToChat(client, "\x01%s: %s", msgPartHdr, msgPartDmg);
        } else {
            PrintToServer("\x01%s: %s", msgPartHdr, msgPartDmg);
        }
    }
}

stock bool:IsPlayerIncap(client) return bool:GetEntProp(client, Prop_Send, "m_isIncapacitated");
stock bool:IsPlayerHanging(client) return bool:GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
stock bool:IsPlayerLedgedAtAll(client) return bool:(GetEntProp(client, Prop_Send, "m_isHangingFromLedge") | GetEntProp(client, Prop_Send, "m_isFallingFromLedge"));

stock GetSurvivorTempHealth(client)
{
    new temphp = RoundToCeil(GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * GetConVarFloat(FindConVar("pain_pills_decay_rate")))) - 1;
    return (temphp > 0 ? temphp : 0);
}

stock GetSurvivorPermanentHealth(client) return GetEntProp(client, Prop_Send, "m_iHealth");

stock CalculateSurvivalBonus()
{
    // add extra bonus, if any
    new bonus = RoundToFloor(( MAX(float(iSettingBonus) - GetDamage() * fSettingMulti, 0.0) ) / 4 + float(iSettingStatic));
    
    iRoundExtra = RNDMAIN_GetGnomeBonus();
    
    if (iRoundExtra) {
        new aliveSurvs = GetAliveSurvivors();
        if (aliveSurvs > 0) {
            bonus += RoundToFloor(float(iRoundExtra) / float(aliveSurvs));
        }
    }
    return bonus;
}

stock GetAliveSurvivors()
{
    new iAliveCount;
    new iSurvivorCount;
    new maxSurvs = (hTeamSize != INVALID_HANDLE) ? GetConVarInt(hTeamSize) : 4;
    for (new i = 1; i < MaxClients && iSurvivorCount < maxSurvs; i++)
    {
        if (IsSurvivor(i))
        {
            iSurvivorCount++;
            if (IsPlayerAlive(i)) iAliveCount++;
        }
    }
    return iAliveCount;
}

stock GetUprightSurvivors()
{
    new iAliveCount;
    new iSurvivorCount;
    new maxSurvs = (hTeamSize != INVALID_HANDLE) ? GetConVarInt(hTeamSize) : 4;
    for (new i=1; i < MaxClients && iSurvivorCount < maxSurvs; i++) {
        if (IsSurvivor(i)) {
            iSurvivorCount++;
            if (IsPlayerAlive(i) && !IsPlayerIncap(i) && !IsPlayerLedgedAtAll(i)) {
                iAliveCount++;
            }
        }
    }
    return iAliveCount;
}

stock bool:IsSurvivor(client)
{
    return IsClientAndInGame(client) && GetClientTeam(client) == TEAM_SURVIVOR;
}

stock bool:IsClientAndInGame(index) return (index > 0 && index <= MaxClients && IsClientInGame(index));