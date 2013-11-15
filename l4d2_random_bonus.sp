#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <left4downtown>
#include <l4d2_direct>
#include <l4d2_random>
#undef REQUIRE_PLUGIN
#include <readyup>
#define REQUIRE_PLUGIN

#define MAX(%0,%1) (((%0) > (%1)) ? (%0) : (%1))
#define MIN(%0,%1) (((%0) < (%1)) ? (%0) : (%1))

#define TEAM_SURVIVOR   2

#define TEAMSIZE_DEFAULT    4.0

#define DST_SCALING         1
#define DST_REDUCTION       2

#define MAX_REPORTLINES     15
#define STR_REPLINELENGTH   256
#define MAX_CHARACTERS      4

#define VALUE_MAX_DAMAGE    800
#define VALUE_DAMAGE_MULTI  1.0
#define VALUE_DIST_BASE     800
#define VALUE_DIST_FACTOR   1.0

/*
    Scoring mechanism chosen:
        - 800 base distance => max damage reduced from that base -- reduced to the actual bonus, if larger than maxdamage: scaled instead 
        - solid health is worth 1.5x
*/

public Plugin:myinfo =
{
    name = "Random - Damage Scoring",
    author = "CanadaRox, Tabun",
    description = "Custom damage scoring based on damage. Adjusted for use with Random config.",
    version = "1.6",
    url = "https://github.com/Tabbernaut/L4D2-Random"
};


// plugin internals
new     bool:       g_bLateLoad;
new     bool:       g_bInRound;
new     bool:       g_bSecondHalf;
new     bool:       g_bFirstRoundReallyOver;

// game cvars
new     Handle:     g_hCvarTeamSize;
new     Handle:     g_hCvarSurvivalBonus;
new                 g_iDefaultSurvivalBonus;
new     Handle:     g_hCvarTieBreakBonus;
new                 g_iDefaultTieBreakBonus;

// tracking damage
new                 iHealth[MAX_CHARACTERS];
new                 bTookDamage[MAX_CHARACTERS];
new                 iTotalDamage[2];                        // actual damage done
new                 iSolidHealthDamage[2];                  // damage done to first 100h of each survivor
new     bool:       bHasWiped[2];                           // true if they didn't get the bonus...
new     bool:       bRoundOver[2];                          // whether the bonus will still change or not
new                 iStoreBonus[2];                         // what was the actual bonus?
new                 iStoreSurvivors[2];                     // how many survived that round?
new                 iStoreExtra[2];                         // what was the 'extra bonus'?
new                 iStorePBonus[2];                        // what was the extra bonus for penaltybonus plugin?
new                 iPlayerDamage[MAX_CHARACTERS];          // the damage a player has taken individually (for finding solid health damage)
new     bool:       bPlayerHasBeenIncapped[MAX_CHARACTERS]; // only true after the survivor has been incapped at least once


// Random added defaults:
new                 g_iSettingBonus =       400;            // this value is set to random plugin's options, or uses this plugin's cvars (range is scaled to this)
new                 g_iSettingStatic =      0;              // same
new     Float:      g_fSettingSolid =       2.0;            // same (solid health factor)
new                 g_iSettingScaleMode =   2;              // same (distance/base scaling: 1 = scale; 2 = reduce)
new                 g_iRoundExtra =         0;              // this amount of points (total, so scaled back against alive-survivor) gets added (for random scoring fun)
new                 g_iPenaltyBonus =       0;              // another extra set of points to award to the survivors // THIS DOES NOT GET ADDED TO THE SCORE BY THIS PLUGIN!

new                 g_iStartHealth[2][MAX_CHARACTERS];      // starting health per survivor character


/*
 *      Natives
 *      =======
 */
 
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    CreateNative("RNDBNS_GetBonus",         Native_GetBonus);
    CreateNative("RNDBNS_GetSolidFactor",   Native_GetSolidFactor);
    CreateNative("RNDBNS_GetStatic",        Native_GetStatic);
    CreateNative("RNDBNS_GetScaleMode",     Native_GetScaleMode);
    
    CreateNative("RNDBNS_SetBonus",         Native_SetBonus);
    CreateNative("RNDBNS_SetSolidFactor",   Native_SetSolidFactor);
    CreateNative("RNDBNS_SetStatic",        Native_SetStatic);
    CreateNative("RNDBNS_SetScaleMode",     Native_SetScaleMode);
    
    CreateNative("RNDBNS_SetExtra",         Native_SetExtra);
    CreateNative("RNDBNS_SetPenaltyBonus",  Native_SetPenaltyBonus);
    
    CreateNative("RNDBNS_CheckStartHealth", Native_CheckStartHealth);
    
    MarkNativeAsOptional("RNDMAIN_GetGnomeBonus");  // so we can load this plugin before main
    MarkNativeAsOptional("RNDMAIN_ShowGnomeBonus");
    
    return APLRes_Success;
}


public Native_GetBonus(Handle:plugin, numParams)
{
    new value = g_iSettingBonus;
    return _:value;
}
public Native_GetSolidFactor(Handle:plugin, numParams)
{
    new Float:value = g_fSettingSolid;
    return _:value;
}
public Native_GetStatic(Handle:plugin, numParams)
{
    new value = g_iSettingStatic;
    return _:value;
}
public Native_GetScaleMode(Handle:plugin, numParams)
{
    new value = g_iSettingScaleMode;
    return _:value;
}

public Native_SetBonus(Handle:plugin, numParams)
{
    new value = GetNativeCell(1);
    g_iSettingBonus = value;
    return;
}
public Native_SetSolidFactor(Handle:plugin, numParams)
{
    new Float: value = Float: GetNativeCell(1);
    g_fSettingSolid = value;
    return;
}
public Native_SetStatic(Handle:plugin, numParams)
{
    new value = GetNativeCell(1);
    g_iSettingStatic = value;
    return;
}
public Native_SetScaleMode(Handle:plugin, numParams)
{
    new value = GetNativeCell(1);
    g_iSettingScaleMode = value;
    return;
}

public Native_SetExtra(Handle:plugin, numParams)
{
    new value = GetNativeCell(1);
    g_iRoundExtra = value;
    return;
}

public Native_SetPenaltyBonus(Handle:plugin, numParams)
{
    new value = GetNativeCell(1);
    g_iPenaltyBonus = value;
    // if bonus is stored before (last) penalty added, could be ignored
    iStorePBonus[GetCurRound()] = value;
    return;
}

public Native_CheckStartHealth(Handle:plugin, numParams)
{
    // for each character, find their starting health
    // store it for determining the 'solid health amount'
    CheckStartHealth();
    return;
}


public OnPluginStart()
{
    // Score Change Triggers
    HookEvent("door_close", DoorClose_Event);
    HookEvent("player_death", PlayerDeath_Event);
    HookEvent("finale_vehicle_leaving", FinaleVehicleLeaving_Event, EventHookMode_PostNoCopy);
    HookEvent("player_ledge_grab", PlayerLedgeGrab_Event);
    HookEvent("player_incapacitated", PlayerIncap_Event);
    HookEvent("round_start", RoundStart_Event);
    HookEvent("round_end", RoundEnd_Event);

    // save default game cvar values
    g_hCvarTeamSize = FindConVar("survivor_limit");
    g_hCvarSurvivalBonus = FindConVar("vs_survival_bonus");
    g_hCvarTieBreakBonus = FindConVar("vs_tiebreak_bonus");
    g_iDefaultSurvivalBonus = GetConVarInt(g_hCvarSurvivalBonus);
    g_iDefaultTieBreakBonus = GetConVarInt(g_hCvarTieBreakBonus);
    
    // Commands
    RegConsoleCmd("sm_damage", Damage_Cmd, "Prints the damage bonus for both teams");
    RegConsoleCmd("sm_health", Damage_Cmd, "Prints the damage bonus for both teams (Legacy)");
    RegConsoleCmd("sm_damage_explain", Explain_Cmd, "Shows an explanation of the damage bonus calculation.");
    RegConsoleCmd("sm_health_explain", Explain_Cmd, "Shows an explanation of the damage bonus calculation.");
    
    // hooks
    if (g_bLateLoad)
    {
        for (new i=1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i))
            {
                OnClientPutInServer(i);
            }
        }
    }
}

public OnPluginEnd()
{
    SetConVarInt(g_hCvarSurvivalBonus, g_iDefaultSurvivalBonus);
    SetConVarInt(g_hCvarTieBreakBonus, g_iDefaultTieBreakBonus);
}

public OnMapStart()
{
    for (new i=0; i < 2; i++)
    {
        iTotalDamage[i] = 0;
        iSolidHealthDamage[i] = 0;
        iStoreBonus[i] = 0;
        iStoreSurvivors[i] = 0;
        iStoreExtra[i] = 0;
        iStorePBonus[i] = 0;
        bRoundOver[i] = false;
        bHasWiped[i] = false;
        g_bFirstRoundReallyOver = false;
        
        for (new j=0; j < MAX_CHARACTERS; j++)
        {
            g_iStartHealth[i][j] = 100;
        }
    }
}

public OnMapEnd()
{
    g_bSecondHalf = false;
}

public OnRoundIsLive()
{
    // crox readyup
    // if round goes live, make sure all the damage stuff is reset
    new round = GetCurRound();
    
    iTotalDamage[round] = 0;
    iSolidHealthDamage[round] = 0;
    
    //iStoreBonus[round] = 0;           // don't mess with the stuff that's ok anyway
    //iStoreSurvivors[round] = 0;
    //bRoundOver[round] = false;
    //bHasWiped[round] = false;
    
    // also reset player status even if considered 'hanging before'
    for ( new i = 0; i < 4; i++ )
    {
        bPlayerHasBeenIncapped[i] = false;
        iPlayerDamage[i] = 0;
        iSolidHealthDamage[round] = 0;
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

public Action:Explain_Cmd(client, args)
{
    DisplayBonusExplanation(client);
    return Plugin_Handled;
}

public RoundStart_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
    for (new i=0; i < MAX_CHARACTERS; i++)
    {
        iPlayerDamage[i] = 0;
        bPlayerHasBeenIncapped[i] = false;
    }
    
    g_bInRound = true;
    
    if (g_bSecondHalf)
    {
        g_bFirstRoundReallyOver = true;
    }
}

public RoundEnd_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
    // set whether the round was a wipe or not
    if (!GetUprightSurvivors()) {
        bHasWiped[GetCurRound()] = true;
    }
    
    // when round is over...
    
    g_bInRound = false;
    bRoundOver[GetCurRound()] = true;
    g_bSecondHalf = true;
    
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
        SetBonus(CalculateSurvivalBonus());
    }
}

public PlayerDeath_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    new round = GetCurRound();
    
    if (client && IsSurvivor(client))
    {
        SetBonus(CalculateSurvivalBonus());
        
        if (!g_bInRound) { return; }
        
        // check solid health
        if (g_fSettingSolid != 1.0)
        {
            new srvchr = GetPlayerCharacter(client);
            if (iPlayerDamage[srvchr] < g_iStartHealth[round][srvchr])
            {
                iSolidHealthDamage[round] += (g_iStartHealth[round][srvchr] - iPlayerDamage[srvchr]);
                iTotalDamage[round] += (g_iStartHealth[round][srvchr] - iPlayerDamage[srvchr]);
                iPlayerDamage[srvchr] = g_iStartHealth[round][srvchr];
            }
        }
    }
}

public FinaleVehicleLeaving_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && IsSurvivor(i) && IsPlayerIncap(i))
        {
            ForcePlayerSuicide(i);
        }
    }
    
    SetBonus(CalculateSurvivalBonus());
}

public OnTakeDamage(victim, attacker, inflictor, Float:damage, damagetype)
{
    if ( !g_bInRound ) { return; }
    if (!IsSurvivor(victim)) { return; }
    
    new srvchr = GetPlayerCharacter(victim);
    iHealth[srvchr] = (IsPlayerIncap(victim)) ? 0 : (GetSurvivorPermanentHealth(victim) + GetSurvivorTempHealth(victim));
    bTookDamage[srvchr] = true;
}

public PlayerLedgeGrab_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
    if ( !g_bInRound ) { return; }
    
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (!IsSurvivor(client)) { return; }
    
    new health = L4D2Direct_GetPreIncapHealth(client);
    new temphealth = L4D2Direct_GetPreIncapHealthBuffer(client);
    new round = GetCurRound();
    
    iTotalDamage[round] += health + temphealth;
    
    // check solid health
    if (g_fSettingSolid != 1.0)
    {
        new srvchr = GetPlayerCharacter(client);
        if (!bPlayerHasBeenIncapped[srvchr])
        {
            iPlayerDamage[srvchr] += health + temphealth;
            iSolidHealthDamage[round] += health + temphealth;
        }
    }
}

public PlayerIncap_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
    if ( !g_bInRound ) { return; }
    
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (!IsSurvivor(client)) { return; }
    
    new srvchr = GetPlayerCharacter(client);
    new round = GetCurRound();
    
    bPlayerHasBeenIncapped[srvchr] = true;
    
    // check solid health
    if (g_fSettingSolid != 1.0)
    {
        if (iPlayerDamage[srvchr] < g_iStartHealth[round][srvchr])
        {
            iSolidHealthDamage[round] += (g_iStartHealth[round][srvchr] - iPlayerDamage[srvchr]);
            iTotalDamage[round] += (g_iStartHealth[round][srvchr] - iPlayerDamage[srvchr]);
            iPlayerDamage[srvchr] = g_iStartHealth[round][srvchr];
        }
    }
}

public Action:L4D2_OnRevived(client)
{
    if ( !g_bInRound ) { return; }
    if (!IsSurvivor(client)) { return; }
    
    new health = GetSurvivorPermanentHealth(client);
    new temphealth = GetSurvivorTempHealth(client);
    new round = GetCurRound();
    
    iTotalDamage[round] -= (health + temphealth);
    
    // check solid health
    if (g_fSettingSolid != 1.0)
    {
        new srvchr = GetPlayerCharacter(client);
        if (!bPlayerHasBeenIncapped[srvchr]) {
            iPlayerDamage[srvchr] -= (health + temphealth);
            iSolidHealthDamage[round] -= (health + temphealth);
        }
    }
}

public OnTakeDamagePost(victim, attacker, inflictor, Float:damage, damagetype)
{
    if ( !g_bInRound ) { return; }
    if (!IsSurvivor(victim)) { return; }
    
    new srvchr = GetPlayerCharacter(victim);
    new round = GetCurRound();
    
    if (iHealth[srvchr])
    {
        if (!IsPlayerAlive(victim) || (IsPlayerIncap(victim) && !IsPlayerHanging(victim)))
        {
            iTotalDamage[round] += iHealth[srvchr];
        }
        else if (!IsPlayerHanging(victim))
        {
            iTotalDamage[round] += iHealth[srvchr] - (GetSurvivorPermanentHealth(victim) + GetSurvivorTempHealth(victim));
            
            if (!bPlayerHasBeenIncapped[srvchr])
            {
                iPlayerDamage[srvchr] += iHealth[srvchr] - (GetSurvivorPermanentHealth(victim) + GetSurvivorTempHealth(victim));
                iSolidHealthDamage[round] += iHealth[srvchr] - (GetSurvivorPermanentHealth(victim) + GetSurvivorTempHealth(victim));
                
                if (iPlayerDamage[srvchr] > g_iStartHealth[round][srvchr])
                {
                    iSolidHealthDamage[round] -= (g_iStartHealth[round][srvchr] - iPlayerDamage[srvchr]);
                    bPlayerHasBeenIncapped[srvchr] = true;
                }
            }
        }
        iHealth[srvchr] = (IsPlayerIncap(victim)) ? 0 : (GetSurvivorPermanentHealth(victim) + GetSurvivorTempHealth(victim));
    }
}

stock GetDamage(round=-1)
{
    return (round == -1) ? iTotalDamage[GetCurRound()] : iTotalDamage[round];
}

stock SetBonus(iBonus)
{
    if ( !g_bInRound ) { return; }
    
    SetConVarInt(g_hCvarSurvivalBonus, iBonus);
    StoreBonus(iBonus);
}

stock StoreBonus(iBonus)
{
    // store bonus for display
    new round = GetCurRound();
    new aliveSurvs = GetAliveSurvivors();

    iStoreBonus[round] = iBonus;
    iStoreSurvivors[round] = aliveSurvs;
    iStoreExtra[round] = g_iRoundExtra;
    iStorePBonus[round] = g_iPenaltyBonus;
}

stock DisplayBonus(client=-1)
{
    new String:msgPartHdr[48];
    new String:msgPartDmg[64];
    
    new curRound = GetCurRound();
    
    // call for gnome bonus scoring native if we just finished a round
    if ((!curRound && bRoundOver[0]) || (curRound && bRoundOver[1]))
    {
        if (!bHasWiped[curRound])
        {
            RNDMAIN_ShowGnomeBonus();
        }
    }
    
    for (new round = 0; round <= curRound; round++)
    {
        if (bRoundOver[round]) {
            FormatEx(msgPartHdr, sizeof(msgPartHdr), "Round \x05%i\x01 bonus", round+1);
        } else {
            FormatEx(msgPartHdr, sizeof(msgPartHdr), "Current Bonus");
        }

        if (bHasWiped[round]) {
            FormatEx(msgPartDmg, sizeof(msgPartDmg), "\x03wipe\x01 (\x05%4d\x01 damage)", iTotalDamage[round]);
        }
        else {
            new tmpAlive = GetAliveSurvivors();
            new tmpBonus = (bRoundOver[round]) ? iStoreBonus[round] * iStoreSurvivors[round] : CalculateSurvivalBonus() * tmpAlive;
            new tmpStatic = g_iSettingStatic * ( (bRoundOver[round]) ? iStoreSurvivors[round] : tmpAlive );
            
            tmpBonus -= tmpStatic;
            if (bRoundOver[round]) {
                if (iStoreExtra[round]) {
                    tmpBonus -= RoundToFloor(float(iStoreExtra[round]) / float(iStoreSurvivors[round]));
                }
            } else if (g_iRoundExtra) {
                tmpBonus -= RoundToFloor(float(g_iRoundExtra) / float(tmpAlive));
            }
            
            // safeguard: no negative bonus:
            tmpBonus = MAX( tmpBonus, 0 );
            
            FormatEx(msgPartDmg, sizeof(msgPartDmg), "\x04%4d\x01 (\x05%4d\x01 damage)", tmpBonus, iTotalDamage[round] );
            
            // add static bonus
            if (tmpStatic) {
                Format(msgPartDmg, sizeof(msgPartDmg), "%s + \x04%d\x01", msgPartDmg, tmpStatic);
            }
            
            // add extra bonus for random
            if ( bRoundOver[round] ) {
                if ( iStoreExtra[round] ) {
                    Format(msgPartDmg, sizeof(msgPartDmg), "%s + \x05%d\x01", msgPartDmg, iStoreExtra[round]);
                }
            } else if ( g_iRoundExtra ) {
                Format(msgPartDmg, sizeof(msgPartDmg), "%s + \x05%d\x01", msgPartDmg, g_iRoundExtra);
            }
        }
        
        // add extra bonus for penaltybonus scoring
        if ( bRoundOver[round] ) {
            if ( iStorePBonus[round] ) {
                Format(msgPartDmg, sizeof(msgPartDmg), "%s %s \x03%d\x01", msgPartDmg, (iStorePBonus[round] < 0) ? "-" : "+", (iStorePBonus[round] < 0) ? iStorePBonus[round] * -1 : iStorePBonus[round]);
            }
        } else if ( g_iPenaltyBonus ) {
            Format(msgPartDmg, sizeof(msgPartDmg), "%s %s \x03%d\x01", msgPartDmg, (g_iPenaltyBonus < 0) ? "-" : "+", (g_iPenaltyBonus < 0) ? g_iPenaltyBonus * -1 : g_iPenaltyBonus );
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

stock DisplayBonusExplanation(client=-1)
{
    // show exactly how the calculated bonus is constructed
    
    new String: sReport[MAX_REPORTLINES][STR_REPLINELENGTH];
    new iLine = 0;
    
    new round = GetCurRound();
    new living = (bRoundOver[round]) ? iStoreSurvivors[round] : GetAliveSurvivors();
    new iDistMode = g_iSettingScaleMode;
    new iBonusExtra = (bRoundOver[round]) ? RoundToFloor(float(iStoreExtra[round]) / float(living)) : RoundToFloor(float(g_iRoundExtra) / float(living));
    
    new Float: fBaseMaxDamage = float( VALUE_MAX_DAMAGE );
    
    new Float: fCalcMaxDamage = fBaseMaxDamage;
    new Float: fCalcTakenDamage = float(iTotalDamage[round]);
    new Float: fBaseBonus = fCalcMaxDamage;
    new Float: fPerc = 0.0;

    
    // damage taken
    Format(sReport[iLine], STR_REPLINELENGTH, "Damage taken:       \x05%i\x01", iTotalDamage[round]);
    if (g_fSettingSolid != 1.0) {
        Format(sReport[iLine], STR_REPLINELENGTH, "%s (\x04%i\x01 of which on solid health).", sReport[iLine], iSolidHealthDamage[round]);
    } else {
        Format(sReport[iLine], STR_REPLINELENGTH, "%s.", sReport[iLine]);
    }
    iLine++;
    
    // base bonus to max damage calc
    fBaseBonus = fCalcMaxDamage - ( fCalcTakenDamage * VALUE_DAMAGE_MULTI );
    fPerc = ( ( fCalcTakenDamage * VALUE_DAMAGE_MULTI ) / fCalcMaxDamage ) * 100.0;
    if (fBaseBonus < 0.0) { fBaseBonus = 0.0; fPerc = 0.0; }
    
    if (VALUE_DAMAGE_MULTI != 1.0) {
        // damage scaled 
        FormatEx(sReport[iLine], STR_REPLINELENGTH, "Dmg taken/maximum:  (\x05%.f\x01 * %.2f) out of \x05%.f\x01 [\x04%.1f%%\x01] => base bonus: \x03%i\x01",
                fCalcTakenDamage, VALUE_DAMAGE_MULTI, fCalcMaxDamage,
                fPerc,
                RoundToFloor( fBaseBonus / TEAMSIZE_DEFAULT ) * RoundFloat(TEAMSIZE_DEFAULT)
            );
        fCalcTakenDamage = fCalcTakenDamage * VALUE_DAMAGE_MULTI;
    }
    else {
        // 1-1
        FormatEx(sReport[iLine], STR_REPLINELENGTH, "Dmg taken/maximum:  \x05%.f\x01 out of \x05%.f\x01 [\x04%.1f%%\x01] => base bonus: \x03%i\x01",
                fCalcTakenDamage, fCalcMaxDamage,
                (fCalcTakenDamage / fCalcMaxDamage) * 100.0,
                RoundToFloor( fBaseBonus )
            );
    }
    iLine++;
    
    // factoring in the solid-health damage
    if (g_fSettingSolid != 1.0)
    {
        fCalcTakenDamage = ( float( iTotalDamage[round] - iSolidHealthDamage[round] ) * VALUE_DAMAGE_MULTI ) + ( float(iSolidHealthDamage[round]) * VALUE_DAMAGE_MULTI * g_fSettingSolid );
        new Float: fCalcMaxDamageSolidPart = float(GetStartHealthTotal()) * VALUE_DAMAGE_MULTI;
        fCalcMaxDamage = (fBaseMaxDamage - fCalcMaxDamageSolidPart ) + ( fCalcMaxDamageSolidPart * g_fSettingSolid );
        // scale basebonus back to the maxdamage count
        fBaseBonus = ( fCalcMaxDamage - fCalcTakenDamage ) * ( fBaseMaxDamage / fCalcMaxDamage );
        fPerc = ( fCalcTakenDamage / fCalcMaxDamage ) * 100.0;
        if (fBaseBonus < 0.0) { fBaseBonus = 0.0; fPerc = 0.0; }
        
        FormatEx(sReport[iLine], STR_REPLINELENGTH, "Solid-health value: (\x05%.f\x01+(\x04%.f\x01*\x05%.1f\x01)) out of (\x05%.f\x01+(\x04%.f\x01*\x05%.1f\x01)) [\x04%.1f%%\x01] => \x03%i\x01",
                float(iTotalDamage[round] - iSolidHealthDamage[round]) * VALUE_DAMAGE_MULTI,
                float(iSolidHealthDamage[round]) * VALUE_DAMAGE_MULTI,
                g_fSettingSolid,
                
                fBaseMaxDamage - ( float(GetStartHealthTotal()) * VALUE_DAMAGE_MULTI),
                float(GetStartHealthTotal()) * VALUE_DAMAGE_MULTI,
                g_fSettingSolid,
                
                fPerc,
                RoundToFloor( fBaseBonus / TEAMSIZE_DEFAULT ) * RoundFloat(TEAMSIZE_DEFAULT)
            );
    }
    iLine++;
    
    // scale for distance [base bonus]
    if (g_iSettingBonus != VALUE_DIST_BASE)
    {
        switch (iDistMode)
        {
            case DST_SCALING:
            {
                fBaseBonus = fBaseBonus * ( float(g_iSettingBonus) / float(VALUE_DIST_BASE) );
                FormatEx(sReport[iLine], STR_REPLINELENGTH, "Rand.base (scaled): \x04%i\x01 / \x05%i\x01 [base] = \x04%.2f\x01x => \x03%i\x01",
                        L4D_GetVersusMaxCompletionScore(),
                        VALUE_DIST_BASE,
                        float(g_iSettingBonus) / float(VALUE_DIST_BASE),
                        RoundToFloor( fBaseBonus / TEAMSIZE_DEFAULT ) * RoundFloat(TEAMSIZE_DEFAULT)
                    );
            }
            
            case DST_REDUCTION:
            {
                if (VALUE_DIST_BASE - g_iSettingBonus > 0)
                {
                    if (g_fSettingSolid != 1.0)
                    {
                        fBaseMaxDamage -= ( float(VALUE_DIST_BASE - g_iSettingBonus) * VALUE_DIST_FACTOR );
                        new Float: fCalcMaxDamageSolidPart = MIN( fBaseMaxDamage , float(GetStartHealthTotal()) );
                        fCalcMaxDamage = ( fBaseMaxDamage - fCalcMaxDamageSolidPart ) + ( fCalcMaxDamageSolidPart * g_fSettingSolid );
                        fBaseBonus = (fCalcMaxDamage - fCalcTakenDamage ) * ( fBaseMaxDamage / fCalcMaxDamage );
                    }
                    else {
                        fCalcMaxDamage -= ( float(VALUE_DIST_BASE - g_iSettingBonus) );
                        fBaseBonus = fCalcMaxDamage - fCalcTakenDamage;
                    }
                }
                fPerc = ( fCalcTakenDamage / fCalcMaxDamage ) * 100.0;
                if (fBaseBonus < 0.0) { fBaseBonus = 0.0; fPerc = 0.0; }
                
                if (VALUE_DIST_BASE - g_iSettingBonus > 0)
                {
                    FormatEx(sReport[iLine], STR_REPLINELENGTH, "Rand.base (reduce): \x04%i\x01 diff. => new dmg: [\x04%.1f%%\x01] out of \x05%.f\x01 max => \x03%i\x01",
                            g_iSettingBonus - VALUE_DIST_BASE,
                            fPerc,
                            fBaseMaxDamage,
                            RoundToFloor( fBaseBonus / TEAMSIZE_DEFAULT ) * RoundFloat(TEAMSIZE_DEFAULT)
                        );
                }
                else {
                    // base smaller than bonus required, scale up instead
                    fBaseBonus = fBaseBonus * ( float(g_iSettingBonus) / float(VALUE_DIST_BASE) );
                    FormatEx(sReport[iLine], STR_REPLINELENGTH, "Rand.base (scaled): \x04%i\x01 / \x05%i\x01 [base] = \x04%.2f\x01x => \x03%i\x01 [not reduced, because base is > max damage]",
                            L4D_GetVersusMaxCompletionScore(),
                            VALUE_DIST_BASE,
                            float(g_iSettingBonus) / float(VALUE_DIST_BASE),
                            RoundToFloor( fBaseBonus / TEAMSIZE_DEFAULT ) * RoundFloat(TEAMSIZE_DEFAULT)
                        );
                }
            }
        }
        iLine++;
    }
    
    // scale for survivors
    new iTmpBonus;
    iTmpBonus = RoundToFloor( fBaseBonus / TEAMSIZE_DEFAULT ) * living;
    if (living != TEAMSIZE_DEFAULT)
    {
        iTmpBonus = RoundToFloor( fBaseBonus / TEAMSIZE_DEFAULT ) * living;
        FormatEx(sReport[iLine], STR_REPLINELENGTH, "Living survivors:   \x05%i\x01 living: \x04%.2f%\x01x => \x03%i\x01",
                    living,
                    (float(living) / TEAMSIZE_DEFAULT),
                    iTmpBonus
                );
        iLine++;
    }
    
    // add static survival bonus
    if (g_iSettingStatic > 0)
    {
        FormatEx(sReport[iLine], STR_REPLINELENGTH, "Static bonus: +\x04%i\x01 x \x05%i\x01 => \x03%i\x01",
                    g_iSettingStatic,
                    living,
                    iTmpBonus + ( g_iSettingStatic * living )
                );
        iLine++;
    }
    
    // add random bonus (gnome)
    if (iBonusExtra)
    {
        iTmpBonus += iBonusExtra;
        FormatEx(sReport[iLine], STR_REPLINELENGTH, "Gnome bonus: +\x04%i\x01 x \x05%i\x01 => \x03%i\x01",
                    iBonusExtra,
                    living,
                    iTmpBonus + ( g_iSettingStatic * living )
                );
        iLine++;
    }
    
    // compare to actual bonus:
    new iDiff = ( iTmpBonus + ( g_iSettingStatic * living ) ) - ( CalculateSurvivalBonus() * living );
    if (iDiff != 0)
    {
        FormatEx(sReport[iLine], STR_REPLINELENGTH, "(ignore \x04%i\x01 points diff. from actual bonus (expl. rounding error))", iDiff);
        iLine++;
    }
    
    // send the report
    for (new i=0; i < iLine; i++)
    {
        if (client == -1) {
            PrintToChatAll("\x01%s", sReport[i]);
        }
        else if (client) {
            PrintToChat(client, "\x01%s", sReport[i]);
        }
        else {
            PrintToServer("\x01%s", sReport[i]);
        }
    }
}


stock bool:IsPlayerIncap(client) return bool:GetEntProp(client, Prop_Send, "m_isIncapacitated");
stock bool:IsPlayerHanging(client) return bool:GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
stock bool:IsPlayerLedgedAtAll(client) return bool:(GetEntProp(client, Prop_Send, "m_isHangingFromLedge") | GetEntProp(client, Prop_Send, "m_isFallingFromLedge"));


stock GetStartHealthTotal(round = -1)
{
    new totalHealth = 0;
    
    if (round == -1) { round = GetCurRound(); }
    
    for (new j=0; j < MAX_CHARACTERS; j++)
    {
        totalHealth += g_iStartHealth[round][j];
    }
    
    if (!totalHealth)
    {
        totalHealth = 100 * RoundFloat( TEAMSIZE_DEFAULT );
    }
    
    return totalHealth;
}

stock CheckStartHealth(round = -1)
{
    if (round == -1) { round = GetCurRound(); }
    
    new currentHealth[MAX_CHARACTERS] = {100,...};
    
    for (new i=1; i <= MaxClients; i++)
    {
        if (!IsClientAndInGame(i) || !IsSurvivor(i) || !IsPlayerAlive(i)) { continue; }
        
        currentHealth[ GetPlayerCharacter(i) ] = GetSurvivorPermanentHealth(i);
    }
    
    for (new j=0; j < MAX_CHARACTERS; j++)
    {
        g_iStartHealth[round][j] = currentHealth[j];
    }
}


stock GetSurvivorTempHealth(client)
{
    new temphp = RoundToCeil(GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * GetConVarFloat(FindConVar("pain_pills_decay_rate")))) - 1;
    return (temphp > 0 ? temphp : 0);
}

stock GetSurvivorPermanentHealth(client) return GetEntProp(client, Prop_Send, "m_iHealth");

stock CalculateSurvivalBonus()
{
    new iRound = GetCurRound();

    g_iRoundExtra = RNDMAIN_GetGnomeBonus();
    
    new iDistMode = g_iSettingScaleMode;
    
    new Float: fBonus = 0.0;
    new iBonusPart;
    new Float: fBaseMaxDamage = float( VALUE_MAX_DAMAGE );
    
    // [base] distance reduction (needs be done before dmg calc)
    if (iDistMode == DST_REDUCTION)
    {
        new iDiff = VALUE_DIST_BASE - g_iSettingBonus;
        if (iDiff > 0) {
            fBaseMaxDamage -= float( MAX( VALUE_DIST_BASE - g_iSettingBonus , 0 ) );
        }
        else if (iDiff < 0) {
            // too big a bonus, fall back on scaling
            iDistMode = DST_SCALING;
        }
    }
    
    // damage calc: solid health damage, damage multiplier, max - taken damage (+ scaled back to 0-maxdmg range)
    new iDmg = GetDamage();
    new Float: fMaxDamageSolidPart = MIN( fBaseMaxDamage , float(GetStartHealthTotal()) );
    new Float: fTakenDamage = ( float( iDmg - iSolidHealthDamage[iRound] ) * VALUE_DAMAGE_MULTI ) + ( float(iSolidHealthDamage[iRound]) * VALUE_DAMAGE_MULTI * g_fSettingSolid );
    new Float: fMaxDamage = ( fBaseMaxDamage - fMaxDamageSolidPart ) + ( fMaxDamageSolidPart * g_fSettingSolid );
    
    // calculate bonus
    fBonus = ( fMaxDamage - fTakenDamage ) * ( fBaseMaxDamage / fMaxDamage );
    
    // [base] distance scaling (+ factor weighing)
    if (iDistMode == DST_SCALING)
    {
        fBonus = fBonus * ( float(g_iSettingBonus) / float(VALUE_DIST_BASE) );
    }
    
    // at least 0 (before adding the extra & static)
    fBonus = MAX( fBonus, 0.0 );
    
    // extra bonus
    if (g_iRoundExtra)
    {
        new aliveSurvs = GetAliveSurvivors();
        if (aliveSurvs > 0) {
            fBonus += float( RoundToFloor(float(g_iRoundExtra) / float(aliveSurvs)) );
        }
    }
    
    // scale for living + static
    iBonusPart = RoundToFloor( fBonus / TEAMSIZE_DEFAULT ) + g_iSettingStatic;
    
    return iBonusPart;
}

stock GetAliveSurvivors()
{
    new iAliveCount;
    new iSurvivorCount;
    new maxSurvs = (g_hCvarTeamSize != INVALID_HANDLE) ? GetConVarInt(g_hCvarTeamSize) : 4;
    for (new i = 1; i <= MaxClients && iSurvivorCount < maxSurvs; i++)
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
    new maxSurvs = (g_hCvarTeamSize != INVALID_HANDLE) ? GetConVarInt(g_hCvarTeamSize) : 4;
    for (new i=1; i <= MaxClients && iSurvivorCount < maxSurvs; i++)
    {
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

stock GetCurRound() { return (g_bSecondHalf && g_bFirstRoundReallyOver) ? 1 : 0; }
stock GetPlayerCharacter(client)
{
    new tmpChr = GetEntProp(client, Prop_Send, "m_survivorCharacter");
    
    // use models when incorrect character returned
    if (tmpChr < 0 || tmpChr >= MAX_CHARACTERS)
    {
        LogMessage("[dmgflx] Incorrect character code: %i (for %N) (using model instead)", tmpChr, client);
        
        decl String:model[256];
        GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
        
        if (StrContains(model, "gambler") != -1) {          tmpChr = 0; }
        else if (StrContains(model, "coach") != -1) {       tmpChr = 2; }
        else if (StrContains(model, "mechanic") != -1) {    tmpChr = 3; }
        else if (StrContains(model, "producer") != -1) {    tmpChr = 1; }
        else if (StrContains(model, "namvet") != -1) {      tmpChr = 0; }
        else if (StrContains(model, "teengirl") != -1) {    tmpChr = 1; }
        else if (StrContains(model, "biker") != -1) {       tmpChr = 3; }
        else if (StrContains(model, "manager") != -1) {     tmpChr = 2; }
        else {                                              tmpChr = 0; }
    }
    
    return tmpChr;
}