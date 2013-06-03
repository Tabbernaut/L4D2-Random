#pragma semicolon 1
#include <sourcemod>


/*
    Ugly defines for l4d_drop code
    I'll replace it with a nice trie when I feel like it
*/
#define MODEL_V_FIREAXE "models/weapons/melee/v_fireaxe.mdl"
#define MODEL_V_FRYING_PAN "models/weapons/melee/v_frying_pan.mdl"
#define MODEL_V_MACHETE "models/weapons/melee/v_machete.mdl"
#define MODEL_V_BASEBALL_BAT "models/weapons/melee/v_bat.mdl"
#define MODEL_V_CROWBAR "models/weapons/melee/v_crowbar.mdl"
#define MODEL_V_CRICKET_BAT "models/weapons/melee/v_cricket_bat.mdl"
#define MODEL_V_TONFA "models/weapons/melee/v_tonfa.mdl"
#define MODEL_V_KATANA "models/weapons/melee/v_katana.mdl"
#define MODEL_V_ELECTRIC_GUITAR "models/weapons/melee/v_electric_guitar.mdl"
#define MODEL_V_GOLFCLUB "models/weapons/melee/v_golfclub.mdl"
#define MODEL_V_SHIELD "models/weapons/melee/v_riotshield.mdl"
#define MODEL_V_KNIFE "models/v_models/v_knife_t.mdl"


// called as timer (to avoid some problems)
public Action: SUPPORT_RoundPreparation(Handle:timer)
{
    // only reset on first roundhalf:
    if (!g_bSecondHalf)
    {
        g_bStripperAltDetected = false;
    }
    
    // only reset on first roundhalf or if event's not equal
    if (!g_bSecondHalf || !(GetConVarInt(g_hCvarEqual) & EQ_EVENT))
    {
        g_bNoPriWeapons = false;
        g_bNoSecWeapons = false;
        g_bNoAmmo = false;
        g_bSpecialEventPlayerCheck = false;
    }
    
    // called before randomization
    g_bIsPaused = false;
    g_fPauseAttemptTime = 0.0;
    
    g_bIsFirstAttack = true;
    g_bPlayersLeftStart = false;
    g_bFirstReportDone = false;
    g_iSpectateGhostCount = 0;
    
    g_bInsightSurvDone = false;         // so we only get the insight effect from a gift once per roundhalf
    g_bInsightInfDone = false;
    
    g_bFirstTankSpawned = false;
    g_bIsTankInPlay = false;
    g_iTankClient = 0;
    
    g_iBonusCount = 0;
    g_fDudTimeExpire = 0.0;
    
    // basic cleanup
    SUPPORT_CleanArrays();              // clear general arrays
    ClearArray(g_hBlockedEntities);     // clear blind infected entities
    ClearBoomerTracking();              // clear arrays for tracking boomer combo's
    ResetGnomes();                      // clear gnome tracking array for bonus scoring
    
    // timer cleanup
    if (g_hTimePenaltyTimer != INVALID_HANDLE) { KillTimer(g_hTimePenaltyTimer); }
    
    // handle the randomization 
    RANDOM_DetermineRandomStuff();
    
    // handle report / survivor check for second round
    if (g_bSecondHalf) {
        // doing this immediately now
        //CreateTimer(DELAY_SECONDHALF, Timer_RoundStart, _, TIMER_FLAG_NO_MAPCHANGE);
        
        g_hTimerReport = CreateTimer(DELAY_SECONDHALF_REP, Timer_RoundStartReport, _, TIMER_FLAG_NO_MAPCHANGE);
        g_bTimerReport = true;
        
        // for second half, also do a run-through to hand out gifts to all survivors
        //      because playerteam is not reliably fired for everyone
        CheckSurvivorSetup();
    }
    
    
    // do post-randomization prep
    RNDBNS_SetExtra(0);                 // clear extra round bonus
    
    // penalty bonus (only enable when required)
    if (g_bUsingPBonus) {
        SetConVarInt(FindConVar("sm_pbonus_enable"), 1);
        PBONUS_ResetRoundBonus();
    } else {
        SetConVarInt(FindConVar("sm_pbonus_enable"), 0);
    }
    
    EVENT_RoundStartPreparation();      // prepare survivors for special event
    
    SUPPORT_MultiWitchRoundPrep();      // prepare multi-witch for round, if any
    SUPPORT_MultiTankRoundPrep();       // prepare multi-/mini-tanks for round, if any
    
    
    // fix sound hook
    if (_:g_iSpecialEvent == EVT_SILENCE || _:g_iSpecialEvent == EVT_AMMO) {
        if (!g_bSoundHooked) {
            AddNormalSoundHook(Event_SoundPlayed);
            g_bSoundHooked = true;
        }
    } else {
        if (g_bSoundHooked) {
            RemoveNormalSoundHook(Event_SoundPlayed);
            g_bSoundHooked = false;
        }
    }
    
    // launch storm if required
    if (g_iSpecialEvent == _:EVT_WEATHER || g_iSpecialEvent == _:EVT_FOG)
    {
        SUPPORT_StormStart();
    }
    
    // some things need to be delayed to work right
    g_hTimerReport = CreateTimer( (g_bCampaignMode) ? DELAY_ROUNDPREP_COOP : DELAY_ROUNDPREP , Timer_DelayedRoundPrep, _, TIMER_FLAG_NO_MAPCHANGE);
    
}

// delayed call for every round start
public Action: Timer_DelayedRoundPrep(Handle:timer)
{
    // item replacement and blinding
    g_iCreatedEntities = 0;
    
    if (!g_bSecondHalf || !(GetConVarInt(g_hCvarEqual) & EQ_ITEMS)) {
        RandomizeItems();
    } else {
        RestoreItems();
    }
    
    // some special event stuff that can't be done earlier
    if (_:g_iSpecialEvent == EVT_BOOBYTRAP)
    {
        EVENT_PickBoobyTraps();
    }
    
    // blind infected to items generated
    ItemsBlindInfected();
}

SUPPORT_CleanArrays()
{
    // clean some arrays with rounddata
    for (new i=1; i <= MaxClients; i++)
    {
        g_bArJustBeenGiven[i] = false;
        g_bArBlockPickupCall[i] = false;
        
        g_fGotGhost[i] = 0.0;
        g_fDeathAfterGhost[i] = 0.0;
        
        g_iClientUsing[i] = 0;
        g_bClientHoldingUse[i] = false;
        
        // skeet tracking
        ResetHunter(i);
    }
    
    for (new i=ZC_SMOKER; i <= ZC_CHARGER; i++)
    {
        g_iClassTimeout[i] = 0;
    }
    
    // arrays for ZC / class changing code
    InitSpawnArrays();
}


// Event functions / difficulty
// ----------------------------

EVENT_ResetOtherCvars()
{
    // for defib event
    SetConVarInt(FindConVar("vs_defib_penalty"), g_iDefDefibPenalty);
    PBONUS_SetDefibPenalty(g_iDefDefibPenalty);
    
    SetConVarInt(FindConVar("defibrillator_use_duration"), g_iDefDefibDuration);
    SetConVarFloat(FindConVar("pain_pills_decay_rate"), g_fDefPillDecayRate);
    
    SetConVarInt(FindConVar("z_smoker_limit"), g_iDefSmokerLimit);
    SetConVarInt(FindConVar("z_boomer_limit"), g_iDefBoomerLimit);
    SetConVarInt(FindConVar("z_hunter_limit"), g_iDefHunterLimit);
    SetConVarInt(FindConVar("z_spitter_limit"), g_iDefSpitterLimit);
    SetConVarInt(FindConVar("z_jockey_limit"), g_iDefJockeyLimit);
    SetConVarInt(FindConVar("z_charger_limit"), g_iDefChargerLimit);
    
    SetConVarInt(FindConVar("ammo_smg_max"), g_iDefAmmoSmg);
    SetConVarInt(FindConVar("ammo_shotgun_max"), g_iDefAmmoShotgun);
    SetConVarInt(FindConVar("ammo_huntingrifle_max"), g_iDefAmmoHR);
    SetConVarInt(FindConVar("ammo_sniperrifle_max"), g_iDefAmmoSniper);
    SetConVarInt(FindConVar("ammo_assaultrifle_max"), g_iDefAmmoRifle);
    SetConVarInt(FindConVar("ammo_autoshotgun_max"), g_iDefAmmoAutoShotgun);
    
    SetConVarFloat(FindConVar("survivor_friendly_fire_factor_normal"), g_fDefFFFactor);
    SetConVarInt(FindConVar("z_tank_health"), g_iDefTankHealth);
    SetConVarInt(FindConVar("z_frustration_lifetime"), g_iDefTankFrustTime);
    SetConVarInt(FindConVar("vs_tank_damage"), g_iDefTankDamage);
    SetConVarFloat(FindConVar("versus_tank_flow_team_variation"), g_fDefTankFlowVariation);
    
    SetConVarInt(FindConVar("z_vomit_interval"), g_iDefVomitInterval);
    SetConVarInt(FindConVar("z_spit_interval"), g_iDefSpitInterval);
    
    // hittable control
    if (FindConVar("hc_car_standing_damage") != INVALID_HANDLE) {
        SetConVarInt(FindConVar("hc_sflog_standing_damage"), g_iDefTankHittableDamage);
        SetConVarInt(FindConVar("hc_bhlog_standing_damage"), g_iDefTankHittableDamage);
        SetConVarInt(FindConVar("hc_car_standing_damage"), g_iDefTankHittableDamage);
        SetConVarInt(FindConVar("hc_bumpercar_standing_damage"), g_iDefTankHittableDamage);
        SetConVarInt(FindConVar("hc_forklift_standing_damage"), g_iDefTankHittableDamage);
        SetConVarInt(FindConVar("hc_dumpster_standing_damage"), g_iDefTankHittableDamage);
        SetConVarInt(FindConVar("hc_haybale_standing_damage"), g_iDefTankHittableDamage);
        SetConVarInt(FindConVar("hc_baggage_standing_damage"), g_iDefTankHittableDamage);
        SetConVarInt(FindConVar("hc_incap_standard_damage"), g_iDefTankHittableDamage);
    }
    
    SetConVarInt(FindConVar("sv_force_time_of_day"), -1);
}

EVENT_ResetDifficulty()
{
    // reset any changes to cvars related to map difficulty
    
    // common
    SetConVarInt(FindConVar("z_common_limit"), g_iDefCommonLimit);
    SetConVarInt(FindConVar("z_background_limit"), g_iDefBackgroundLimit);
    SetConVarInt(FindConVar("z_mob_spawn_min_size"), g_iDefHordeSizeMin);
    SetConVarInt(FindConVar("z_mob_spawn_max_size"), g_iDefHordeSizeMax);
    SetConVarInt(FindConVar("z_mob_spawn_min_interval_normal"), g_iDefHordeTimeMin);
    SetConVarInt(FindConVar("z_mob_spawn_max_interval_normal"), g_iDefHordeTimeMax);
    
    // SI
    SetConVarInt(FindConVar("z_ghost_delay_min"), g_iDefSpawnTimeMin);
    SetConVarInt(FindConVar("z_ghost_delay_max"), g_iDefSpawnTimeMax);
}

EVENT_SetDifficulty(commonDiff, specialDiff)
{
    // set the map's difficulty (for balancing special event rounds
    // common = whether to change common cvars
    // special = whether to change special infected cvars

    // difficulty change for specials
    switch (specialDiff)
    {
        case DIFFICULTY_VERYEASY: {
            SetConVarInt(FindConVar("z_ghost_delay_min"), RoundFloat(float(g_iDefSpawnTimeMin) * EVENT_VERYEASY_SITIME));
            SetConVarInt(FindConVar("z_ghost_delay_max"), RoundFloat(float(g_iDefSpawnTimeMax) * EVENT_VERYEASY_SITIME));
        }
        case DIFFICULTY_EASY: {
            SetConVarInt(FindConVar("z_ghost_delay_min"), RoundFloat(float(g_iDefSpawnTimeMin) * EVENT_EASY_SITIME));
            SetConVarInt(FindConVar("z_ghost_delay_max"), RoundFloat(float(g_iDefSpawnTimeMax) * EVENT_EASY_SITIME));
        }
        case DIFFICULTY_HARD: {
            SetConVarInt(FindConVar("z_ghost_delay_min"), RoundFloat(float(g_iDefSpawnTimeMin) * EVENT_HARD_SITIME));
            SetConVarInt(FindConVar("z_ghost_delay_max"), RoundFloat(float(g_iDefSpawnTimeMax) * EVENT_HARD_SITIME));
        }
        case DIFFICULTY_VERYHARD: {
            SetConVarInt(FindConVar("z_ghost_delay_min"), RoundFloat(float(g_iDefSpawnTimeMin) * EVENT_VERYHARD_SITIME));
            SetConVarInt(FindConVar("z_ghost_delay_max"), RoundFloat(float(g_iDefSpawnTimeMax) * EVENT_VERYHARD_SITIME));
        }
        
    }
    
    // difficulty change for commons
    switch (commonDiff)
    {
        // set common level to easy
        case DIFFICULTY_SUPEREASY: {
            SetConVarInt(FindConVar("z_common_limit"), RoundFloat(float(g_iDefCommonLimit) * EVENT_SUPEREASY_CILIM));
            SetConVarInt(FindConVar("z_background_limit"), RoundFloat(float(g_iDefBackgroundLimit) * EVENT_SUPEREASY_CILIM));
            SetConVarInt(FindConVar("z_mob_spawn_min_size"), RoundFloat(float(g_iDefHordeSizeMin) * EVENT_SUPEREASY_CILIM));
            SetConVarInt(FindConVar("z_mob_spawn_max_size"), RoundFloat(float(g_iDefHordeSizeMax) * EVENT_SUPEREASY_CILIM));
            SetConVarInt(FindConVar("z_mob_spawn_min_interval_normal"), RoundFloat(float(g_iDefHordeTimeMin) / EVENT_VERYEASY_CILIM));
            SetConVarInt(FindConVar("z_mob_spawn_max_interval_normal"), RoundFloat(float(g_iDefHordeTimeMax) / EVENT_VERYEASY_CILIM));
        }
        
        case DIFFICULTY_VERYEASY: {
            SetConVarInt(FindConVar("z_common_limit"), RoundFloat(float(g_iDefCommonLimit) * EVENT_VERYEASY_CILIM));
            SetConVarInt(FindConVar("z_background_limit"), RoundFloat(float(g_iDefBackgroundLimit) * EVENT_VERYEASY_CILIM));
            SetConVarInt(FindConVar("z_mob_spawn_min_size"), RoundFloat(float(g_iDefHordeSizeMin) * EVENT_VERYEASY_CILIM));
            SetConVarInt(FindConVar("z_mob_spawn_max_size"), RoundFloat(float(g_iDefHordeSizeMax) * EVENT_VERYEASY_CILIM));
            SetConVarInt(FindConVar("z_mob_spawn_min_interval_normal"), RoundFloat(float(g_iDefHordeTimeMin) / EVENT_EASY_CILIM));
            SetConVarInt(FindConVar("z_mob_spawn_max_interval_normal"), RoundFloat(float(g_iDefHordeTimeMax) / EVENT_EASY_CILIM));
        }
        
        case DIFFICULTY_EASY: {
            SetConVarInt(FindConVar("z_common_limit"), RoundFloat(float(g_iDefCommonLimit) * EVENT_EASY_CILIM));
            SetConVarInt(FindConVar("z_background_limit"), RoundFloat(float(g_iDefBackgroundLimit) * EVENT_EASY_CILIM));
            SetConVarInt(FindConVar("z_mob_spawn_min_size"), RoundFloat(float(g_iDefHordeSizeMin) * EVENT_EASY_CILIM));
            SetConVarInt(FindConVar("z_mob_spawn_max_size"), RoundFloat(float(g_iDefHordeSizeMax) * EVENT_EASY_CILIM));
        }
        case DIFFICULTY_HARD: {
            SetConVarInt(FindConVar("z_common_limit"), RoundFloat(float(g_iDefCommonLimit) * EVENT_HARD_CILIM));
            SetConVarInt(FindConVar("z_background_limit"), RoundFloat(float(g_iDefBackgroundLimit) * EVENT_HARD_CILIM));
            SetConVarInt(FindConVar("z_mob_spawn_min_size"), RoundFloat(float(g_iDefHordeSizeMin) * EVENT_HARD_CILIM));
            SetConVarInt(FindConVar("z_mob_spawn_max_size"), RoundFloat(float(g_iDefHordeSizeMax) * EVENT_HARD_CILIM));
            SetConVarInt(FindConVar("z_mob_spawn_max_interval_normal"), RoundFloat(float(g_iDefHordeTimeMax) / EVENT_HARD_CILIM));
        }
        
        case DIFFICULTY_VERYHARD: {
            SetConVarInt(FindConVar("z_common_limit"), RoundFloat(float(g_iDefCommonLimit) * EVENT_VERYHARD_CILIM));
            SetConVarInt(FindConVar("z_background_limit"), RoundFloat(float(g_iDefBackgroundLimit) * EVENT_VERYHARD_CILIM));
            SetConVarInt(FindConVar("z_mob_spawn_min_size"), RoundFloat(float(g_iDefHordeSizeMin) * EVENT_VERYHARD_CILIM));
            SetConVarInt(FindConVar("z_mob_spawn_max_size"), RoundFloat(float(g_iDefHordeSizeMax) * EVENT_VERYHARD_CILIM));
            SetConVarInt(FindConVar("z_mob_spawn_min_interval_normal"), RoundFloat(float(g_iDefHordeTimeMin) / EVENT_VERYHARD_CILIM));
            SetConVarInt(FindConVar("z_mob_spawn_max_interval_normal"), RoundFloat(float(g_iDefHordeTimeMax) / EVENT_VERYHARD_CILIM));
        }
    }
}

EVENT_RoundStartPreparation()
{
    // apply some settings for special events at round start
    
    g_bSpecialRoleAboutToChange = false;
    
    switch (_:g_iSpecialEvent)
    {
        case EVT_DEFIB: {
            for (new i=1; i <= MaxClients; i++) {
                if (IsSurvivor(i)) {
                    SetEntProp(i, Prop_Send, "m_bIsOnThirdStrike", 1);
                    //SetEntProp(i, Prop_Send, "m_isGoingToDie", 1);    // breaks hud
                }
            }
        }
        
        case EVT_ADREN: {
            /*
                don't set temp health here:
                it would make survivors bleed out even in readyup...
            */
        }
        
        case EVT_BOOBYTRAP: {
            // traps are picked after items are randomized
        }
        
        case EVT_WITCHES: {
            // start timer to autospawn witches
            if (g_hWitchSpawnTimer != INVALID_HANDLE)
            {
                CloseHandle(g_hWitchSpawnTimer);
            }
            g_hWitchSpawnTimer = CreateTimer(EVENT_WITCHES_SPAWNFREQ, Timer_WitchSpawn, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
            
            // respawn timer too (only once, destroyed at mapchange)
            if (!g_bSecondHalf)
            {
                CreateTimer(MULTIWITCH_RESPAWN_FREQ, Timer_WitchRespawn, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
            }
        }
    }
}

public Action: EVENT_SurvivorsLeftSaferoom(Handle:timer)
{
    switch (_:g_iSpecialEvent)
    {
        case EVT_ADREN: {
            // makes survivors start with 99 bleeding health
            for (new i=1; i <= MaxClients; i++) {
                if (IsSurvivor(i)) {
                    SetEntityHealth(i, 1);
                    SetEntPropFloat(i, Prop_Send, "m_healthBufferTime", GetGameTime());
                    SetEntPropFloat(i, Prop_Send, "m_healthBuffer", 99.0);
                }
            }
        }
        
        case EVT_NOHUD: {
            // no huds for survivors this round
            EVENT_HUDRemoveSurvivors();
        }
        
        case EVT_KEYMASTER: {
            // first time keymaster gets picked with a visible report
            EVENT_PickSpecialEventRole(-1, false);
        }
        
        case EVT_PROTECT: {
            // first time baby gets picked with a visible report
            EVENT_PickSpecialEventRole(-1, false);
        }
        
        case EVT_PEN_TIME: {
            // start timer
            g_iTimePenaltyCounter = 0;
            g_hTimePenaltyTimer = CreateTimer( 1.0 , Timer_TimePenalty, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
        }
        
    }
}

EVENT_HUDRemoveSurvivors()
{
    for (new i=1; i <= MaxClients; i++) {
        if (IsSurvivor(i)) {
            HUDRemoveClient(i);
        }
    }
}

EVENT_HUDRestoreAll()
{
    for (new i=1; i <= MaxClients; i++) {
        if (IsClientAndInGame(i)) {
            HUDRestoreClient(i);
        }
    }
}

HUDRemoveClient(client)
{
    if (IsFakeClient(client)) { return; }
    SetEntProp(client, Prop_Send, "m_iHideHUD", EVENT_NOHUD_MASK);
}
HUDRestoreClient(client)
{
    if (IsFakeClient(client)) { return; }
    SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
}


// only for penalties
EVENT_ReportPenalty(client = -1, extraInfo = -1)
{
    switch (_:g_iSpecialEvent)
    {
        case EVT_PEN_ITEM: {
            if (client != -1) {
                PrintToChatAll("\x01[\x05r\x01] Item pickup by %N cost \x04%i\x01 points.", client, EVENT_PENALTY_ITEM);
            } else {
                PrintToChatAll("\x01[\x05r\x01] Item pickup cost \x04%i\x01 points.", EVENT_PENALTY_ITEM);
            }
        }
        case EVT_PEN_HEALTH: {
            if (client != -1) {
                PrintToChatAll("\x01[\x05r\x01] Healing by %N cost \x04%i\x01 points.", client, EVENT_PENALTY_HEALTH);
            } else {
                PrintToChatAll("\x01[\x05r\x01] Healing cost \x04%i\x01 points.", EVENT_PENALTY_HEALTH);
            }
        }
        case EVT_PEN_M2: {
            new String: tmpStr[20] = "";
            if (extraInfo > 0) { Format(tmpStr, sizeof(tmpStr), "on %s ", g_csSIClassName[extraInfo]); }
            
            if (client != -1) {
                PrintToChatAll("\x01[\x05r\x01] Shove %sby %N cost \x04%i\x01 points.", tmpStr, client, EVENT_PENALTY_M2_SI);
            } else {
                PrintToChatAll("\x01[\x05r\x01] Shove %scost \x04%i\x01 points.", tmpStr, EVENT_PENALTY_M2_SI);
            }
        }
        case EVT_PEN_TIME: {
            PrintToChatAll("\x01[\x05r\x01] Minute passed, \x04%i\x01 point penalty.", EVENT_PENALTY_TIME);
        }
    }
}

// this is also for bonus report
EVENT_DisplayRoundPenalty(client=-1)
{
    switch (_:g_iSpecialEvent)
    {
        case EVT_PEN_ITEM:
        {
            if (client != -1) {
                PrintToChat(client, "\x01[\x05r\x01] \x04Penalty\x01: \x05%i\x01 item pickup%s cost \x04%i\x01 points.", g_iBonusCount, (g_iBonusCount == 1) ? "" : "s", EVENT_PENALTY_ITEM * g_iBonusCount);
            } else {
                PrintToChatAll("\x01[\x05r\x01] \x04Penalty\x01: \x05%i\x01 item pickup%s cost \x04%i\x01 points.", g_iBonusCount, (g_iBonusCount == 1) ? "" : "s", EVENT_PENALTY_ITEM * g_iBonusCount);
            }
        }
        case EVT_PEN_HEALTH:
        {
            if (client != -1) {
                PrintToChat(client, "\x01[\x05r\x01] \x04Penalty\x01: \x05%i\x01 healing action%s cost \x04%i\x01 points.", g_iBonusCount, (g_iBonusCount == 1) ? "" : "s", EVENT_PENALTY_HEALTH * g_iBonusCount);
            } else {
                PrintToChatAll("\x01[\x05r\x01] \x04Penalty\x01: \x05%i\x01 healing action%s cost \x04%i\x01 points.", g_iBonusCount, (g_iBonusCount == 1) ? "" : "s", EVENT_PENALTY_HEALTH * g_iBonusCount);
            }
        }
        case EVT_PEN_M2:
        {
            if (client != -1) {
                PrintToChat(client, "\x01[\x05r\x01] \x04Penalty\x01: \x05%i\x01 m2%s cost \x04%i\x01 points.", g_iBonusCount, (g_iBonusCount == 1) ? "" : "s", EVENT_PENALTY_M2_SI * g_iBonusCount);
            } else {
                PrintToChatAll("\x01[\x05r\x01] \x04Penalty\x01: \x05%i\x01 m2%s cost \x04%i\x01 points.", g_iBonusCount, (g_iBonusCount == 1) ? "" : "s", EVENT_PENALTY_M2_SI * g_iBonusCount);
            }
        }
        
        case EVT_SKEET:
        {
            if (client != -1) {
                PrintToChat(client, "\x01[\x05r\x01] \x04Bonus\x01: \x05%i\x01 skeet%s gave \x04%i\x01 points bonus.", g_iBonusCount, (g_iBonusCount == 1) ? "" : "s", EVENT_SKEET_BONUS * g_iBonusCount);
            } else {
                PrintToChatAll("\x01[\x05r\x01] \x04Bonus\x01: \x05%i\x01 skeet%s gave \x04%i\x01 points bonus.", g_iBonusCount, (g_iBonusCount == 1) ? "" : "s", EVENT_SKEET_BONUS * g_iBonusCount);
            }
        }
        case EVT_PEN_TIME:
        {
            PrintToChatAll("\x01[\x05r\x01] \x04Penalty\x01: \x05%i\x01 minute%s cost \x04%i\x01 points so far.", g_iBonusCount, (g_iBonusCount == 1) ? "" : "s", EVENT_PENALTY_TIME * g_iBonusCount);
        }
    }
}




// penalty timer
public Action: Timer_TimePenalty(Handle:timer)
{
    // when paused, don't keep ticking
    if (g_bIsPaused) {
        return Plugin_Continue;
    }
    
    // halt timer on round end
    if (!g_bInRound) {
        PrintToChatAll("not in round");
        g_hTimePenaltyTimer = INVALID_HANDLE;
        return Plugin_Stop;
    }
    
    g_iTimePenaltyCounter++;
    
    if (g_iTimePenaltyCounter == 60)
    {
        g_iTimePenaltyCounter = 1;
        
        g_iBonusCount++;
        PBONUS_AddRoundBonus( -1 * EVENT_PENALTY_TIME );
        EVENT_ReportPenalty();
    }
    
    return Plugin_Continue;
}

EVENT_ReportBoobytrap(client=-1)
{
    // only on BOOBYTRAP event
    if (client > 0) {
        PrintToChatAll("\x01[\x05r\x01] %N triggered a booby trap!", client);
    } else {
        PrintToChatAll("\x01[\x05r\x01] a booby trap was triggered!");
    }
}


EVENT_HandleSkeet(skeeter=-1, victim=-1)
{
    if (_:g_iSpecialEvent == EVT_SKEET)
    {
        g_iBonusCount++;
        if (skeeter == -2) {
            PBONUS_AddRoundBonus( EVENT_SKEET_BONUS_TEAM );
        } else {
            PBONUS_AddRoundBonus( EVENT_SKEET_BONUS );
        }
        
        if (skeeter == -2) {    // team skeet sets to -2
            if (IsClientAndInGame(victim)) {
                PrintToChatAll("\x01[\x05r\x01] %N was team-skeeted for \x04%i\x01 points.", victim, EVENT_SKEET_BONUS_TEAM);
            } else {
                PrintToChatAll("\x01[\x05r\x01] A hunter was team-skeeted for \x04%i\x01 points.", EVENT_SKEET_BONUS_TEAM);
            }
        }
        else if (IsClientAndInGame(skeeter) && IsClientAndInGame(victim)) {
            PrintToChatAll("\x01[\x05r\x01] %N skeeted %N for \x04%i\x01 points.", skeeter, victim, EVENT_SKEET_BONUS);
        }
        else if (IsClientAndInGame(skeeter)) {
            PrintToChatAll("\x01[\x05r\x01] %N skeeted a hunter for \x04%i\x01 points.", skeeter, EVENT_SKEET_BONUS);
        }
        else if (IsClientAndInGame(victim)) {
            PrintToChatAll("\x01[\x05r\x01] %N was skeeted for \x04%i\x01 points.", victim, EVENT_SKEET_BONUS);
        }
        else {
            PrintToChatAll("\x01[\x05r\x01] A hunter was skeeted for \x04%i\x01 points.", EVENT_SKEET_BONUS);
        }
    }
}

// magic guns wap
EVENT_SwapSurvivorGun(client)
{
    if (!IsClientAndInGame(client) || !IsPlayerAlive(client)) { return; }
    
    // swap out old weapon, if any
    new weaponIndex = GetPlayerWeaponSlot(client, PLAYER_SLOT_PRIMARY);
    if (weaponIndex > -1 && IsValidEdict(weaponIndex))
    {
        RemovePlayerItem(client, weaponIndex);
        RemoveEdict(weaponIndex);
    }
    
    // pick new weapon (random)
    new ammo = 0;
    new ammoOffset = -1;
    new String:weaponname[STR_MAX_ITEMGIVEN] = "";
    
    new randomPick = GetRandomInt(0, 7);            // disabled t3 for now
    
    if (randomPick < 4) { randomPick = 0; }         // t1 4x
    else if (randomPick < 6) { randomPick = 4; }    // sniper 2x
    else if (randomPick < 8) { randomPick = 6; }    // t2 2x
    
    switch (randomPick)
    {
        case 0:     // t1
        {
            if (GetRandomInt(0,1) == 0) {   // smg
                ammo = 50;
                ammoOffset = SMG_OFFSET_IAMMO;
                
                randomPick = GetRandomInt(0, 2);
                switch (randomPick) {
                    case 0: { weaponname = "weapon_smg"; }
                    case 1: { weaponname = "weapon_smg_silenced"; } 
                    case 2: { weaponname = "weapon_smg_mp5"; } 
                }
            } else {                // shotgun
                ammo = 8;
                ammoOffset = SHOTGUN_OFFSET_IAMMO;
                
                randomPick = GetRandomInt(0, 1);
                switch (randomPick) {
                    case 0: { weaponname = "weapon_pumpshotgun"; }
                    case 1: { weaponname = "weapon_shotgun_chrome"; } 
                }
            }
        }
        case 4:     // sniper
        {
            ammo = 15;
            
            randomPick = GetRandomInt(0, 3);
            switch (randomPick) {
                case 0: { weaponname = "weapon_hunting_rifle"; ammoOffset = SNIPER_OFFSET_IAMMO; }
                case 1: { weaponname = "weapon_sniper_scout"; ammoOffset = MILITARY_SNIPER_OFFSET_IAMMO; }
                case 2: { weaponname = "weapon_sniper_military"; ammoOffset = MILITARY_SNIPER_OFFSET_IAMMO; ammo = 20; } 
                case 3: { weaponname = "weapon_sniper_awp"; ammoOffset = MILITARY_SNIPER_OFFSET_IAMMO; } 
            }
        }
        case 6:     // t2
        {
            if (GetRandomInt(0,1) == 0) {   // rifle
                ammoOffset = ASSAULT_RIFLE_OFFSET_IAMMO;
                
                randomPick = GetRandomInt(0, 3);
                switch (randomPick) {
                    case 0: { weaponname = "weapon_rifle"; ammo = 50; }
                    case 1: { weaponname = "weapon_rifle_ak47"; ammo = 40; } 
                    case 2: { weaponname = "weapon_rifle_desert"; ammo = 60; } 
                    case 3: { weaponname = "weapon_rifle_sg552"; ammo = 50; } 
                }
            } else {                // shotgun
                ammo = 10;
                ammoOffset = AUTO_SHOTGUN_OFFSET_IAMMO;
                
                randomPick = GetRandomInt(0, 1);
                switch (randomPick) {
                    case 0: { weaponname = "weapon_autoshotgun"; }
                    case 1: { weaponname = "weapon_shotgun_spas"; } 
                }
            }
        }
        case 8:     // t3
        {
            // note: m60 can't do ammo offset, use weapon's m_iClip1 netprop instead
            // GL should work pretty much as normal
        }
    
    }
    
    // experiment: give gun but force client to reload that gun!
    // give weapon and remember
    g_iArGunAmmoCount[client] = ammo;
    new ent = GiveItem(client, weaponname, ammo, ammoOffset);
    
    // set clip size to what we set above
    SetEntProp(ent, Prop_Send, "m_iClip1", 0, 4);
}

public Action: Timer_CheckSurvivorGun(Handle:timer, any:client)
{
    EVENT_CheckSurvivorGun(client);
}

EVENT_CheckSurvivorGun(client)
{
    // check after team switch / player join
    // reset available ammo during gunswap event
    new ammo = 0;
    
    // swap out old weapon, if any
    new weaponIndex = GetPlayerWeaponSlot(client, PLAYER_SLOT_PRIMARY);
    if (weaponIndex < 1 || !IsValidEdict(weaponIndex)) {
        EVENT_SwapSurvivorGun(client);
        return;
    }
    
    ammo = GetEntProp(weaponIndex, Prop_Send, "m_iClip1");
    
    // check weapon ammo at offset
    new iOffset = -1;
    new String:classname[128];
    GetEdictClassname(weaponIndex, classname, sizeof(classname));
    
    if ( StrEqual("weapon_smg", classname, false) || StrEqual("weapon_smg_silenced", classname, false) || StrEqual("weapon_smg_mp5", classname, false) ) {
        iOffset = SMG_OFFSET_IAMMO;
    } else if ( StrEqual("weapon_pumpshotgun", classname, false) || StrEqual("weapon_shotgun_chrome", classname, false) ) {
        iOffset = SHOTGUN_OFFSET_IAMMO;
    } else if ( StrEqual("weapon_rifle", classname, false) || StrEqual("weapon_rifle_ak47", classname, false) || StrEqual("weapon_rifle_desert", classname, false) || StrEqual("weapon_rifle_sg552", classname, false)) {
        iOffset = ASSAULT_RIFLE_OFFSET_IAMMO;
    } else if ( StrEqual("weapon_autoshotgun", classname, false) || StrEqual("weapon_shotgun_spas", classname, false) ) {
        iOffset = AUTO_SHOTGUN_OFFSET_IAMMO;
    } else if ( StrEqual("weapon_hunting_rifle", classname, false) ) {
        iOffset = SNIPER_OFFSET_IAMMO;
    } else if ( StrEqual("weapon_sniper_military", classname, false) || StrEqual("weapon_sniper_scout", classname, false) || StrEqual("weapon_sniper_awp", classname, false) ) {
        iOffset = MILITARY_SNIPER_OFFSET_IAMMO;
    } else if ( StrEqual("weapon_grenade_launcher", classname, false) ) {
        iOffset = GRENADE_LAUNCHER_OFFSET_IAMMO;
    }

    if (iOffset != -1) {
        new iAmmoOffset = FindDataMapOffs(client, "m_iAmmo");
        ammo += GetEntData(client, (iAmmoOffset + iOffset));
    }
    
    if (ammo == 0) {
        EVENT_SwapSurvivorGun(client);
    } else {
        g_iArGunAmmoCount[client] = ammo;
    }
}




// special roles for special events
public Action: Timer_CheckSpecialEventRole(Handle:timer, any:pack)
{
    g_bSpecialRoleAboutToChange = false;
    
    // read datapack: survivorsLeftSaferoom; client
    ResetPack(pack);
    new bool: leftStart = bool: ReadPackCell(pack);
    //new client = ReadPackCell(pack);
    CloseHandle(pack);
    
    // special roles
    //  must change if the role is nonexistant, not a survivor, dead or a bot
    if (_:g_iSpecialEvent == EVT_KEYMASTER || _:g_iSpecialEvent == EVT_PROTECT)
    {
        if ( !IsSurvivor(g_iSpecialEventRole) || !IsPlayerAlive(g_iSpecialEventRole) || IsFakeClient(g_iSpecialEventRole) ) {
            g_iSpecialEventRole = 0;
        }
        
        if (!g_iSpecialEventRole)
        {
            EVENT_PickSpecialEventRole( -1, (leftStart) ? false : true);
        }
    }
    // check here for other events (whether bots have stuff they shouldn't have)
    else if (_:g_iSpecialEvent == EVT_AMMO)
    {
        // upgrade kit should not be in possession of bot
        for (new i=1; i <= MaxClients; i++)
        {
            if (IsSurvivor(i) && IsFakeClient(i))
            {
                new slotKit = GetPlayerWeaponSlot(i, PLAYER_SLOT_KIT);
                if (IsValidEntity(slotKit))
                {
                    new String: classname[64];
                    GetEdictClassname(slotKit, classname, sizeof(classname));
                    
                    if (StrEqual(classname, "weapon_upgradepack_incendiary", false) || StrEqual(classname, "weapon_upgradepack_explosive", false))
                    {
                        if (SUPPORT_DropItemSlot(i, PLAYER_SLOT_KIT)) {
                            // send the report
                            for (new j=1; j <= MaxClients; j++)
                            {
                                if (IsSurvivor(j) && !IsFakeClient(j))
                                {
                                    PrintToChat(j, "\x01[\x05r\x01] Ammo pack dropped!");
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

EVENT_PickSpecialEventRole(notClient=-1, bool:notLeftStart=false)
{
    // survivors
    new count = 0;
    new survivors[TEAM_SIZE];
    
    for (new i=1; i <= MaxClients; i++)
    {
        if (i != notClient && IsClientInGame(i) && IsSurvivor(i) && IsPlayerAlive(i) && !IsFakeClient(i))
        {
            survivors[count] = i;
            count++;
        }
    }
    
    // allow bots if there's no-one else
    if (!count) {
        for (new i=1; i <= MaxClients; i++)
        {
            if (i != notClient && IsClientInGame(i) && IsSurvivor(i) && IsPlayerAlive(i))
            {
                survivors[count] = i;
                count++;
            }
        }
    }
    
    if (!count) { g_iSpecialEventRole = 0; return; }
    
    // pick one at random
    new pick = GetRandomInt(0, count-1);
    
    g_iSpecialEventRole = survivors[pick];
    
    // report if it's after the saferoom exit (notLeftStart is for timer calls)
    if (!notLeftStart && g_bPlayersLeftStart) {
        ReportSpecialEventRole();
    }
}


// Stabby's multi-witch stuff
// ===========================================================================

SUPPORT_MultiWitchRandomization()
{
    // how many witches (attempt to spawn, not guaranteed)
    g_iWitchNum = GetRandomInt(MULTIWITCH_MIN, MULTIWITCH_MAX);
    
    PrintDebug("[rand] Multi-witch: trying to set %i witches... ", g_iWitchNum);
    
    // find random spots for multiple witches to spawn in
    new Float: flowMin = MULTIWITCH_FLOW_MIN;
    new Float: flowSection = (MULTIWITCH_FLOW_MAX - MULTIWITCH_FLOW_MIN) / g_iWitchNum;
    
    new index = 0;
    
    for (new i = 0; i < g_iWitchNum; i++)
    {
        // find a spot
        if (flowMin > MULTIWITCH_FLOW_MAX) { continue; }
        if (flowMin + flowSection > MULTIWITCH_FLOW_MAX) { flowSection = MULTIWITCH_FLOW_MAX - flowMin; }
            
        new Float: tmpSpot = GetRandomFloat(flowMin, flowMin + flowSection);
        
        // safeguard
        if (tmpSpot > MULTIWITCH_FLOW_MAX) { tmpSpot = MULTIWITCH_FLOW_MAX; }
        
        // only set witch if a tank doesn't spawn near
        if (g_bTankWillSpawn && FloatAbs( L4D2Direct_GetVSTankFlowPercent( (g_bSecondHalf) ? 1 : 0 ) - tmpSpot) < MULTIWITCH_FLOW_TANK ) {
            
            flowMin = L4D2Direct_GetVSTankFlowPercent( (g_bSecondHalf) ? 1 : 0 ) + MULTIWITCH_FLOW_TANK;
            
            PrintDebug("[rand] Multi-witch near tank spawn, blocked: %.2f near %.2f (next one possible at %.2f)", tmpSpot, L4D2Direct_GetVSTankFlowPercent( (g_bSecondHalf) ? 1 : 0 ), flowMin );
            
            if (g_iWitchNum - index - 1 > 0 ) {
                flowSection = (MULTIWITCH_FLOW_MAX - flowMin) / (g_iWitchNum - index - 1);
            }
            continue;
        }
        
        // store in array
        g_fArWitchFlows[index] = tmpSpot;
        g_bArWitchSitting[index] = (GetRandomInt(0,3) == 0) ? true : false;
        
        PrintDebug("[rand] Multi-witch [%i] to spawn at: %f (%s)", index, g_fArWitchFlows[index], (g_bArWitchSitting[index]) ? "sitting" : "walking");
        
        index++;
        flowMin = tmpSpot + MULTIWITCH_FLOW_BETWEEN;
    }
    
    g_iWitchNum = index;    // set to actual number set to spawn
}

SUPPORT_MultiWitchRoundPrep()
{
    //PrintDebug("[rand] Multi-witch round prep [%i]...", g_bMultiWitch);
    g_iWitchIndex = 0;
    
    // prepare multi-witch for round
    if (g_bMultiWitch)
    {
        PrintDebug("[rand] Multi-witch: setting first spawn (%.2f)", g_fArWitchFlows[0]);
        //both rounds because I remember there being weirdness with this native
        L4D2Direct_SetVSWitchToSpawnThisRound(0, true);
        L4D2Direct_SetVSWitchToSpawnThisRound(1, true);
        
        // set first witch
        L4D2Direct_SetVSWitchFlowPercent(0, g_fArWitchFlows[0]);
        L4D2Direct_SetVSWitchFlowPercent(1, g_fArWitchFlows[0]);
        
        g_iWitchIndex++;
    }
}

public Action:L4D_OnSpawnWitch(const Float:vector[3], const Float:qangle[3])
{
    if (g_bMultiWitch)
    {
        CreateTimer(1.0, Timer_PrepareNextWitch, _, TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Action: Timer_PrepareNextWitch(Handle:timer)
{
    if (g_iWitchIndex == g_iWitchNum - 1)
    {
        //g_fWitchIndex = -1;    //no witches left: could be useful knowledge for other functions?
        return;
    }
    
    L4D2Direct_SetVSWitchToSpawnThisRound(0, true);
    L4D2Direct_SetVSWitchToSpawnThisRound(1, true);    
    L4D2Direct_SetVSWitchFlowPercent(0, g_fArWitchFlows[g_iWitchIndex]);
    L4D2Direct_SetVSWitchFlowPercent(1, g_fArWitchFlows[g_iWitchIndex]);
    
    SetConVarInt(FindConVar("sv_force_time_of_day"), (g_bArWitchSitting[g_iWitchIndex]) ? WITCHES_NIGHT : WITCHES_DAY );
    
    g_iWitchIndex++;
}

// ===========================================================================
//  Double-tank && minitanks
public Action: Timer_PrepareNextTank(Handle:timer)
{
    if (_:g_iSpecialEvent == EVT_MINITANKS)
    {
        if (g_iMiniTankIndex == g_iMiniTankNum - 1) {
            return;
        }
        
        L4D2Direct_SetVSTankToSpawnThisRound(0, true);
        L4D2Direct_SetVSTankToSpawnThisRound(1, true);
        L4D2Direct_SetVSTankFlowPercent(0, g_fArMiniTankFlows[g_iMiniTankIndex]);
        L4D2Direct_SetVSTankFlowPercent(1, g_fArMiniTankFlows[g_iMiniTankIndex]);
        
        g_iMiniTankIndex++;
    }
    else        // 'normal' doubletank
    {
        L4D2Direct_SetVSTankToSpawnThisRound(0, true);
        L4D2Direct_SetVSTankToSpawnThisRound(1, true);
        L4D2Direct_SetVSTankFlowPercent(0, g_fTankFlowLate);
        L4D2Direct_SetVSTankFlowPercent(1, g_fTankFlowLate);
    }
}

SUPPORT_MultiTankRandomization()
{
    // how many tanks
    g_iMiniTankNum = MINITANKS_NUM;
    
    PrintDebug("[rand] Multi-tank: trying to set %i tanks... ", g_iMiniTankNum);
    
    // find random spots for multiple witches to spawn in
    new index = 0;
    for (new i = 0; i < g_iMiniTankNum; i++)
    {
        new Float: tmpSpot = MINITANKS_FLOW_MIN + (float(i) * MINITANKS_FLOW_INT) + GetRandomFloat( -1 * MINITANKS_FLOW_VAR, MINITANKS_FLOW_VAR);
        
        // safeguard
        if (tmpSpot < MINITANKS_FLOW_MIN) { tmpSpot = MINITANKS_FLOW_MIN; }
        else if (tmpSpot > MINITANKS_FLOW_MAX) { tmpSpot = MINITANKS_FLOW_MAX; }
        
        // store in array
        g_fArMiniTankFlows[index] = tmpSpot;
        
        PrintDebug("[rand] Multi/mini-tank [%i] to spawn at: %f", index, g_fArMiniTankFlows[index]);
        
        index++;
    }
    
    g_iMiniTankNum = index;    // set to actual number set to spawn
}

SUPPORT_MultiTankRoundPrep()
{
    //PrintDebug("[rand] Multi-witch round prep [%i]...", g_bMultiWitch);
    g_iMiniTankIndex = 0;
    
    // prepare multi-witch for round
    if (_:g_iSpecialEvent == EVT_MINITANKS)
    {
        PrintDebug("[rand] Multi-tank: setting first spawn (%.2f)", g_fArMiniTankFlows[0]);
        
        L4D2Direct_SetVSTankToSpawnThisRound(0, true);
        L4D2Direct_SetVSTankToSpawnThisRound(1, true);
        
        // set first tank
        L4D2Direct_SetVSTankFlowPercent(0, g_fArMiniTankFlows[0]);
        L4D2Direct_SetVSTankFlowPercent(1, g_fArMiniTankFlows[0]);
        
        g_iMiniTankIndex++;
    }
}

// ===========================================================================

// for item using (progress bar stuff), see what client is using an entity is used
SUPPORT_GetClientUsingEntity(entity)
{
    for (new i=1; i <= MaxClients; i++)
    {
        if (IsSurvivor(i) && g_iClientUsing[i] == entity) {
            return i;
        }
    }
    
    return 0;
}

// for encumbrance etc, target = client
Float: SUPPORT_GetSpeedFactor(target)
{
    // check player's weight
    new Float: fWeight = 0.0;
    new Float: fSpeedFactor = 1.0;
    new String: classname[64];
    
    new slotPrim = GetPlayerWeaponSlot(target, PLAYER_SLOT_PRIMARY);
    new slotSec = GetPlayerWeaponSlot(target, PLAYER_SLOT_SECONDARY);
    new slotThr = GetPlayerWeaponSlot(target, PLAYER_SLOT_THROWABLE);
    new slotKit = GetPlayerWeaponSlot(target, PLAYER_SLOT_KIT);
    new slotPill = GetPlayerWeaponSlot(target, PLAYER_SLOT_PILL);
    
    if (IsValidEntity(slotPrim)) {
        GetEdictClassname(slotPrim, classname, sizeof(classname));
        new itemPickupPenalty: itemHasPenalty;
        if (GetTrieValue(g_hTriePenaltyItems, classname, itemHasPenalty))
        {
            if (itemHasPenalty == ITEM_PICKUP_PENALTY_PRIMARY_T3) {
                fWeight += EVENT_ENC_W_T3;
            } else if (itemHasPenalty == ITEM_PICKUP_PENALTY_PRIMARY_T2) {
                fWeight += EVENT_ENC_W_T2;
            } else if (itemHasPenalty == ITEM_PICKUP_PENALTY_PRIMARY_T1) {
                fWeight += EVENT_ENC_W_T1;
            }
        }
    }
    
    if (IsValidEntity(slotSec)) {
        GetEdictClassname(slotSec, classname, sizeof(classname));
        new itemPickupPenalty: itemHasPenalty;
        if (GetTrieValue(g_hTriePenaltyItems, classname, itemHasPenalty))
        {
            if (itemHasPenalty == ITEM_PICKUP_PENALTY_PISTOL) {
                fWeight += EVENT_ENC_W_PISTOL;
                // dual wielding?
                if (GetEntProp(slotSec, Prop_Send, "m_hasDualWeapons")) {
                    fWeight += EVENT_ENC_W_PISTOL;
                }
            }
            else if (itemHasPenalty == ITEM_PICKUP_PENALTY_MAGNUM) {
                fWeight += 2.0 * EVENT_ENC_W_PISTOL;
            }
            else if (itemHasPenalty == ITEM_PICKUP_PENALTY_MELEE) {
                fWeight += EVENT_ENC_W_MELEE;
            }
            else if (itemHasPenalty == ITEM_PICKUP_PENALTY_SAW) {
                fWeight += EVENT_ENC_W_T3;
            }
        }
    }
    
    if (IsValidEntity(slotThr)) { fWeight += EVENT_ENC_W_THROWABLE; }
    if (IsValidEntity(slotKit)) { fWeight += EVENT_ENC_W_KIT; }
    if (IsValidEntity(slotPill)) { fWeight += EVENT_ENC_W_PILL; }
    
    // check prop carring
    new tmpEnt = GetEntPropEnt(target, Prop_Send, "m_hActiveWeapon");
    if (IsValidEntity(tmpEnt)) {
        GetEdictClassname(tmpEnt, classname, sizeof(classname));
        new itemPropType: itemIsProp;
        if (GetTrieValue(g_hTriePropItems, classname, itemIsProp))
        {
            fWeight += EVENT_ENC_W_PROP;
        }
    }
    
    //PrintToChatAll("weight: %.2f", fWeight);
    
    // if weight is too great, set speed factor
    if (fWeight > EVENT_ENC_W_THRESH + EVENT_ENC_W_RANGE) {
        fSpeedFactor *= 1.0 - EVENT_ENC_SLOW_MAX;
    }
    else if (fWeight > EVENT_ENC_W_THRESH) {
        fSpeedFactor *= 1.0 - ((fWeight - EVENT_ENC_W_THRESH) / EVENT_ENC_W_RANGE) * EVENT_ENC_SLOW_MAX;
    }
    else if (fWeight < EVENT_ENC_W_FAST_THRESH) {
        fSpeedFactor *= 1.0 + ((EVENT_ENC_W_FAST_THRESH - fWeight) / EVENT_ENC_W_FAST_THRESH) * EVENT_ENC_FAST_MAX;
    }
    
    //PrintToChatAll("speed: %.2f", fSpeedFactor);
    
    return fSpeedFactor;
}



// for EVT_BOOBYTRAP
EVENT_PickBoobyTraps()
{
    // note: this must be called AFTER the item randomization
    g_iBoobyTraps = 0;
    
    for (new i=0; i < g_iStoredEntities && i < MAX_BOOBYTRAPS; i++)
    {
        if (g_strArStorage[i][entInStartSaferoom]) { continue; }
        if (    g_strArStorage[i][entPickedType] == _:PCK_NOITEM
            ||  g_strArStorage[i][entPickedType] == _:PCK_JUNK
            ||  g_strArStorage[i][entPickedType] == _:PCK_EXPLOSIVE_BARREL
            ||  g_strArStorage[i][entPickedType] == _:PCK_SILLY_GIFT
        ) { continue; }
        
        if (GetRandomFloat(0.001,1.0) <= EVENT_BOOBYTRAP_CHANCE)
        {
            g_iArBoobyTrap[g_iBoobyTraps] = g_strArStorage[i][entNumber];
            g_iBoobyTraps++;
        }
    }
    
    PrintDebug("[rand] Rigged %i booby traps for special event.", g_iBoobyTraps);
}

// returns true if it was a booby trap (but handles everything itself)
bool: EVENT_CheckBoobyTrap(entity, Float:location[3], client=-1)
{
    if (g_iBoobyTraps < 1) { return false; }
    
    // is it booby-trapped?
    new index = -1;
    
    for (new i=0; i < g_iBoobyTraps; i++)
    {
        if (g_iArBoobyTrap[i] == entity) {
            index = i;
        }
    }
    
    if (index == -1) { return false; }
    
    // it's booby-trapped!
    EVENT_ArrayRemoveBoobyTrap(index);
    EVENT_ReportBoobytrap(client);
    
    if (location[0] == 0.0 && location[1] == 0.0 && location[2] == 0.0) {
        if (client != -1) {
            GetClientAbsOrigin(client, location);
        } else {
            // lucky malfunction...
            return false;
        }
    }
    
    CreateExplosion(location, (GetRandomInt(0, 4) == 0) ? EXPLOSION_POWER_HIGH : EXPLOSION_POWER_LOW);
    
    return true;
}

// manage booby trap array:
EVENT_ArrayRemoveBoobyTrap(index)
{
    // condense array, overwriting index
    for (new i=index; i < g_iBoobyTraps; i++)
    {
        g_iArBoobyTrap[i] = g_iArBoobyTrap[i+1];
    }
    g_iBoobyTraps--;
}


public Action: EVENT_DeployAmmo(Handle:timer, any:entity)
{
    // deploys ammo pile in spot of indicated entity
    if (!IsValidEntity(entity)) { return; }
    
    new Float:targetPos[3];
    GetEntPropVector(entity, Prop_Send, "m_vecOrigin", targetPos);
    
    g_strTempItemSingle[entOrigin_a] = targetPos[0];
    g_strTempItemSingle[entOrigin_b] = targetPos[1];
    g_strTempItemSingle[entOrigin_c] = targetPos[2];
    
    g_fTempItemSingleVelocity[0] = 0.0;
    g_fTempItemSingleVelocity[1] = 0.0;
    g_fTempItemSingleVelocity[2] = 0.0;
    
    g_strTempItemSingle[entPickedType] = PCK_AMMO;
    g_strTempItemSingle[entSpawnPhysics] = false;
    g_strTempItemSingle[entAmmoMax] = 0;
    g_strTempItemSingle[entCheckOrigin] = false;
    g_sTempItemSingleMelee = "";
    
    g_iDeployedAmmo = CreateEntity(-1, false, true);    // create entity, not from array, and override type blocks
    
    // kill original ammo deploy thing
    AcceptEntityInput(entity, "Kill");
}

EVENT_RepackAmmo(client, ammo)
{
    if (!IsClientAndInGame(client) || !IsValidEntity(ammo)) { return; }

    // give client an upgrade pack
    GiveItem(client, "weapon_upgradepack_incendiary", 0, 0);
    
    // kill ammo pile
    AcceptEntityInput(ammo, "Kill");
}

// find out whether a hard path is loaded
bool: SUPPORT_StripperDetectAlt()
{
    if (!g_bStripperPresent) { return false; }
    
    // the marker is a prop_dynamic(_override) with 999999 hammerid and targetname "random_detect_alt"
    
    new entityCount = GetEntityCount();
    new String: classname[64] = "";
    
    for (new i=0; i < entityCount; i++)
    {
        if (IsValidEntity(i)) {
            GetEdictClassname(i, classname, sizeof(classname));
            
            if (StrEqual(classname, "prop_dynamic", false))
            {
                if (GetEntProp(i, Prop_Data, "m_iHammerID") == 999999)
                {
                    new String:name[20] = "";
                    GetEntPropString(i, Prop_Data, "m_iName", name, sizeof(name));
                    
                    //PrintDebug("[rand] prop_dynamic: ent: %i; hamid: %i; name: %s", i, GetEntProp(i, Prop_Data, "m_iHammerID"), name);
                    
                    if (StrEqual(name, "random_detect_alt", false)) {
                        return true;
                    }
                }
            }
        }
    }
    
    return false;
}


// stop animations we triggered
EndSurvivorAnim(client)
{
    // doesn't work right, simply do animation change instead
    //new PropOff_flCycle = FindSendPropInfo("CTerrorPlayer", "m_flCycle");
    //SetEntDataFloat(client, PropOff_flCycle, 2.0, true);
    
    L4D2Direct_DoAnimationEvent(client, ANIM_EVENT_BACK_TO_IDLE);
}

/*
    Support functions, general
    --------------------------
    Actually: any general function
    that I probably won't touch
    ever again
*/

public PrintDebug(const String:Message[], any:...)
{
    #if DEBUG_MODE
        decl String:DebugBuff[256];
        VFormat(DebugBuff, sizeof(DebugBuff), Message, 2);
        LogMessage(DebugBuff);
        //PrintToServer(DebugBuff);
        //PrintToChatAll(DebugBuff);
    #endif
}

// cheat command
CheatCommand(client, const String:command[], const String:arguments[])
{
    if (!client) return;
    new admindata = GetUserFlagBits(client);
    SetUserFlagBits(client, ADMFLAG_ROOT);
    new flags = GetCommandFlags(command);
    SetCommandFlags(command, flags & ~FCVAR_CHEAT);
    FakeClientCommand(client, "%s %s", command, arguments);
    SetCommandFlags(command, flags);
    SetUserFlagBits(client, admindata);
}

bool: SUPPORT_DropItem(client, bool:dropCurrent, count, bool:throwItem)
{
    new dropCount = 0;
    
    if (dropCurrent)
    {
        new slot = SUPPORT_GetCurrentWeaponSlot(client);
        if (slot >= 0) {
            if (_:g_iSpecialEvent != EVT_GUNSWAP || slot != 0) {
                if ( SUPPORT_DropItemSlot(client, slot, throwItem) ) { dropCount++; } 
            }
        }
    }
    
    if (count == 0 && !dropCurrent) { count = 1; }
    
    if (count > 0)
    {
        new slot[5];
        new m = 0;
        
        for (new i=0; i < 5; i++)
        {
            if (GetPlayerWeaponSlot(client, i) > 0)
            {
                slot[m++]=i;
            }
        }
        if (m <= count) { count = m; }
        
        for (new i=0; i < count && m > 0; i++)
        {
            new r = GetRandomInt(0, m-1);
            if (_:g_iSpecialEvent != EVT_GUNSWAP || slot[r] != 0)
            {
                if ( SUPPORT_DropItemSlot(client, slot[r], throwItem) ) { dropCount++; }
            }
            slot[r] = slot[m-1];
            m--;
        }
    }
    
    return bool:(dropCount > 0);
}

bool: SUPPORT_DropItemSlot(client, slot, bool:throwItem=false)
{
    /*
        taken verbatim from l4d_drop.sp (by Pan Xiaohai & Frustian & kwski43)
        needs cleanup, but will have to do for now
    */
    new oldweapon = GetPlayerWeaponSlot(client, slot);
    new bool: success = false;
    
    if (oldweapon > 0)
    {
        new String:weapon[32];
        new ammo;
        new clip;
        new upgrade;
        new upammo;
        new ammoOffset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
        
        GetEdictClassname(oldweapon, weapon, 32);

        new index = CreateEntityByName(weapon);
        new bool: dual = false;
        
        if (slot == 0)
        {
            clip = GetEntProp(oldweapon, Prop_Send, "m_iClip1");
            upgrade = GetEntProp(oldweapon, Prop_Send, "m_upgradeBitVec");
            upammo = GetEntProp(oldweapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded");
            
            if (StrEqual(weapon, "weapon_rifle") || StrEqual(weapon, "weapon_rifle_sg552") || StrEqual(weapon, "weapon_rifle_desert") || StrEqual(weapon, "weapon_rifle_ak47"))
            {
                ammo = GetEntData(client, ammoOffset+(12));
                SetEntData(client, ammoOffset+(12), 0);
            }
            else if (StrEqual(weapon, "weapon_smg") || StrEqual(weapon, "weapon_smg_silenced") || StrEqual(weapon, "weapon_smg_mp5"))
            {
                ammo = GetEntData(client, ammoOffset+(20));
                SetEntData(client, ammoOffset+(20), 0);
            }
            else if (StrEqual(weapon, "weapon_pumpshotgun") || StrEqual(weapon, "weapon_shotgun_chrome"))
            {
                ammo = GetEntData(client, ammoOffset+(28));
                SetEntData(client, ammoOffset+(28), 0);
            }
            else if (StrEqual(weapon, "weapon_autoshotgun") || StrEqual(weapon, "weapon_shotgun_spas"))
            {
                ammo = GetEntData(client, ammoOffset+(32));
                SetEntData(client, ammoOffset+(32), 0);
            }
            else if (StrEqual(weapon, "weapon_hunting_rifle"))
            {
                ammo = GetEntData(client, ammoOffset+(36));
                SetEntData(client, ammoOffset+(36), 0);
            }
            else if (StrEqual(weapon, "weapon_sniper_scout") || StrEqual(weapon, "weapon_sniper_military") || StrEqual(weapon, "weapon_sniper_awp"))
            {
                ammo = GetEntData(client, ammoOffset+(40));
                SetEntData(client, ammoOffset+(40), 0);
            }
            else if (StrEqual(weapon, "weapon_grenade_launcher"))
            {
                ammo = GetEntData(client, ammoOffset+(68));
                SetEntData(client, ammoOffset+(68), 0);
            }
            else { return false; }
        }
        else if (slot == 1)
        {
            if (StrEqual(weapon, "weapon_melee"))
            {
                new String:item[150];
                GetEntPropString(oldweapon , Prop_Data, "m_ModelName", item, sizeof(item));
                //PrintToChat(client, "%s", item);
                if (StrEqual(item, MODEL_V_FIREAXE))
                {
                    DispatchKeyValue(index, "melee_script_name", "fireaxe");
                }
                else if (StrEqual(item, MODEL_V_FRYING_PAN))
                {
                    DispatchKeyValue(index, "melee_script_name", "frying_pan");
                }
                else if (StrEqual(item, MODEL_V_MACHETE))
                {
                    DispatchKeyValue(index, "melee_script_name", "machete");
                }
                else if (StrEqual(item, MODEL_V_BASEBALL_BAT))
                {
                    DispatchKeyValue(index, "melee_script_name", "baseball_bat");
                }
                else if (StrEqual(item, MODEL_V_CROWBAR))
                {
                    DispatchKeyValue(index, "melee_script_name", "crowbar");
                }
                else if (StrEqual(item, MODEL_V_CRICKET_BAT))
                {
                    DispatchKeyValue(index, "melee_script_name", "cricket_bat");
                }
                else if (StrEqual(item, MODEL_V_TONFA))
                {
                    DispatchKeyValue(index, "melee_script_name", "tonfa");
                }
                else if (StrEqual(item, MODEL_V_KATANA))
                {
                    DispatchKeyValue(index, "melee_script_name", "katana");
                }
                else if (StrEqual(item, MODEL_V_ELECTRIC_GUITAR))
                {
                    DispatchKeyValue(index, "melee_script_name", "electric_guitar");
                }
                else if (StrEqual(item, MODEL_V_GOLFCLUB))
                {
                    DispatchKeyValue(index, "melee_script_name", "golfclub");
                }
                else if (StrEqual(item, MODEL_V_SHIELD))
                {
                    DispatchKeyValue(index, "melee_script_name", "riotshield");
                }
                else if (StrEqual(item, MODEL_V_KNIFE))
                {
                    DispatchKeyValue(index, "melee_script_name", "hunting_knife");
                }    
                else return false;
            }
            else if (StrEqual(weapon, "weapon_chainsaw"))
            {
                clip = GetEntProp(oldweapon, Prop_Send, "m_iClip1");
            }
            else if (StrEqual(weapon, "weapon_pistol"))
            {
                clip = GetEntProp(oldweapon, Prop_Send, "m_iClip1");
                dual = bool: GetEntProp(oldweapon, Prop_Send, "m_hasDualWeapons"); 
                if(dual)clip=0;
            }
            else { return false; }
        }
        
        success = RemovePlayerItem(client, oldweapon);
        
        new Float:origin[3];
        new Float:ang[3];
        GetClientEyePosition(client,origin);
        GetClientEyeAngles(client, ang);
        GetAngleVectors(ang, ang, NULL_VECTOR,NULL_VECTOR);
        NormalizeVector(ang,ang);
        
        if (throwItem) { ScaleVector(ang, 500.0); }
        else { ScaleVector(ang, 300.0); }
        
        DispatchSpawn(index);
        TeleportEntity(index, origin, NULL_VECTOR, ang);        
        ActivateEntity(index);         

        if (slot == 0)
        {
            SetEntProp(index, Prop_Send, "m_iExtraPrimaryAmmo", ammo);
            SetEntProp(index, Prop_Send, "m_iClip1", clip);
            SetEntProp(index, Prop_Send, "m_upgradeBitVec", upgrade);
            SetEntProp(index, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", upammo);
        }
        else if (slot == 1)
        {
            if (StrEqual(weapon, "weapon_chainsaw") || StrEqual(weapon, "weapon_pistol"))
            {
                SetEntProp(index, Prop_Send, "m_iClip1", clip);
            }
            
            if (dual)
            {
                GiveItem(client, "weapon_pistol", 0, 0);
            }
        }
    }
    else
    {
        return false;
    }
    
    return success;
}

SUPPORT_GetCurrentWeaponSlot(client)
{
    /*
        taken verbatim from l4d_drop.sp (by Pan Xiaohai & Frustian & kwski43)
        needs cleanup, but will have to do for now
    */
    new slot=-1; 
    
    decl String:weapon[32];
    GetClientWeapon(client, weapon, 32);
    
    if (StrEqual(weapon, "weapon_pumpshotgun") || StrEqual(weapon, "weapon_autoshotgun") || StrEqual(weapon, "weapon_rifle") || StrEqual(weapon, "weapon_smg") || StrEqual(weapon, "weapon_hunting_rifle") || StrEqual(weapon, "weapon_sniper_scout") || StrEqual(weapon, "weapon_sniper_military") || StrEqual(weapon, "weapon_sniper_awp") || StrEqual(weapon, "weapon_smg_silenced") || StrEqual(weapon, "weapon_smg_mp5") || StrEqual(weapon, "weapon_shotgun_spas") || StrEqual(weapon, "weapon_shotgun_chrome") || StrEqual(weapon, "weapon_rifle_sg552") || StrEqual(weapon, "weapon_rifle_desert") || StrEqual(weapon, "weapon_rifle_ak47") || StrEqual(weapon, "weapon_grenade_launcher") || StrEqual(weapon, "weapon_rifle_m60"))
        slot=0;
    else if (StrEqual(weapon, "weapon_pistol") || StrEqual(weapon, "weapon_pistol_magnum") || StrEqual(weapon, "weapon_chainsaw") || StrEqual(weapon, "weapon_melee"))
        slot=1;
    else if (StrEqual(weapon, "weapon_pipe_bomb") || StrEqual(weapon, "weapon_molotov") || StrEqual(weapon, "weapon_vomitjar"))
        slot=2;
    else if (StrEqual(weapon, "weapon_first_aid_kit") || StrEqual(weapon, "weapon_defibrillator") || StrEqual(weapon, "weapon_upgradepack_explosive") || StrEqual(weapon, "weapon_upgradepack_incendiary"))
        slot=3;
    else if (StrEqual(weapon, "weapon_pain_pills") || StrEqual(weapon, "weapon_adrenaline"))
        slot=4;
 
    if(slot    <0 )
    {
        for(new i=0; i<5; i++)
        {
            new s=GetPlayerWeaponSlot(client, i);
            if(s>0)
            {
                slot=i;
                break;
            }
        } 
    }
    return slot;
}



// hide/show survivor weapon
/*
HideWeapon(client)
{
    // cannot be done
    //  apparently, this only works for weapons on the ground etc, weapons
    //  on the model will never disappear, unless you hide the entire player model
    new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    
    new String: classname[64];
    GetEdictClassname(weapon, classname, sizeof(classname));
    
    if (IsValidEntity(weapon)) {
        SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
        SetEntityRenderColor(weapon, 255, 255, 255, 0);
    }
}
ShowWeapon(client)
{
    new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    
    if (IsValidEntity(weapon)) {
        SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
        SetEntityRenderColor(weapon, 255, 255, 255, 255);
    }
}
*/

// progress bar handling
SetupProgressBar(client, Float:time, Float:location[3])
{
    g_fProgressTime[client] = GetGameTime();
    g_fProgressLocation[client] = location;
    
    SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", g_fProgressTime[client]);
    SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", time);
}
KillProgressBar(client)
{
    SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
    SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
}

bool: SUPPORT_IsWeaponPrimary(weapId)
{
    switch (_:weapId)
    {
        case WEPID_SMG: { return true; }
        case WEPID_PUMPSHOTGUN: { return true; }
        case WEPID_AUTOSHOTGUN: { return true; }
        case WEPID_RIFLE: { return true; }
        case WEPID_HUNTING_RIFLE: { return true; }
        case WEPID_SMG_SILENCED: { return true; }
        case WEPID_SHOTGUN_CHROME: { return true; }
        case WEPID_RIFLE_DESERT: { return true; }
        case WEPID_SNIPER_MILITARY: { return true; }
        case WEPID_SHOTGUN_SPAS: { return true; }
        case WEPID_GRENADE_LAUNCHER: { return true; }
        case WEPID_RIFLE_AK47: { return true; }
        case WEPID_SMG_MP5: { return true; }
        case WEPID_RIFLE_SG552: { return true; }
        case WEPID_SNIPER_AWP: { return true; }
        case WEPID_SNIPER_SCOUT: { return true; }
        case WEPID_RIFLE_M60: { return true; }
    }
    return false;
}

bool: SUPPORT_IsInReady()
{
    // do a check that's compatible with new and old readyup plugins
    
    // check if we've readyup loaded (here because now all plugins are loaded)
    if (g_hCvarReadyUp == INVALID_HANDLE || !GetConVarBool(g_hCvarReadyUp)) { return false; }
    
    // find a survivor
    new client = GetSpawningClient(true);
    if (client == 0) { return false; }
    
    // if he's frozen, assume it's readyup time
    return bool: (GetEntityMoveType(client) == MOVETYPE_NONE);
}

bool: IsEntityInSaferoom(entity, bool:isPlayer=false, bool:endSaferoom=true)
{
    // 1. is it held by someone (we're only calling this at round end by default?
    
    if (isPlayer) {
        if (endSaferoom) {
            return bool: SAFEDETECT_IsPlayerInEndSaferoom(entity);
        } else {
            return bool: SAFEDETECT_IsPlayerInStartSaferoom(entity);
        }
    }
    
    // entity
    if (endSaferoom) {
        return bool: SAFEDETECT_IsEntityInEndSaferoom(entity);
    } else {
        return bool: SAFEDETECT_IsEntityInStartSaferoom(entity);
    }
}


// get just any survivor client (param = false = switch to infected too)
GetSpawningClient(bool:onlySurvivors=false)
{
    for (new i=1; i <= GetMaxClients(); i++) {
        if (IsClientConnected(i) && IsSurvivor(i) && !IsFakeClient(i)) { return i; }
    }
    
    if (onlySurvivors) { return 0; }
    
    // since we're just using this for spawning stuff that requires a client, use infected alternatively
    for (new i=1; i <= GetMaxClients(); i++) {
        if (IsClientConnected(i) && IsInfected(i) && !IsFakeClient(i)) { return i; }
    }
    
    // no usable clients...
    return 0;
}

bool: IsClientAndInGame(index) return (index > 0 && index <= MaxClients && IsClientInGame(index));
bool: IsSurvivor(client)
{
    if (IsClientAndInGame(client)) {
        return GetClientTeam(client) == TEAM_SURVIVOR;
    }
    return false;
}
bool: IsInfected(client)
{
    if (IsClientAndInGame(client)) {
        return GetClientTeam(client) == TEAM_INFECTED;
    }
    return false;
}
bool: IsTank(any:client)
{
    new iClass = GetEntProp(client, Prop_Send, "m_zombieClass");
    if (IsPlayerAlive(client) && iClass == ZC_TANK) { return true; }
    return false;
}


bool:IsHangingFromLedge(client) { return bool:(GetEntProp(client, Prop_Send, "m_isHangingFromLedge") || GetEntProp(client, Prop_Send, "m_isFallingFromLedge")); }
bool:IsIncapacitated(client) { return bool:GetEntProp(client, Prop_Send, "m_isIncapacitated"); }

/*
GetTankClient()
{
    if (!g_bIsTankInPlay) return 0;
    new tankclient = g_iTankClient;
 
    if (!IsClientInGame(tankclient))
    {
        tankclient = FindTankClient();
        if (!tankclient) return 0;
        g_iTankClient = tankclient;
    }
    return tankclient;
}
*/

FindTankClient()
{
    for (new client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client) ||
            GetClientTeam(client) != TEAM_INFECTED ||
            !IsPlayerAlive(client) ||
            GetEntProp(client, Prop_Send, "m_zombieClass") != ZC_TANK)
            continue;

        return client;
    }
    return 0;
}

bool: IsPlayerGhost(any:client)
{
    if (GetEntProp(client, Prop_Send, "m_isGhost")) { return true; }
    return false;
}


/*
bool: IsCommon(entity)
{
    if (entity <= 0 || entity > 2048 || !IsValidEdict(entity)) return false;
    
    decl String:model[128];
    GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
    
    if (StrContains(model, "_ceda") != -1)      { return false; }
    if (StrContains(model, "_clown") != -1)     { return false; }
    if (StrContains(model, "_mud") != -1)       { return false; }
    if (StrContains(model, "_riot") != -1)      { return false; }
    if (StrContains(model, "_roadcrew") != -1)  { return false; }
    if (StrContains(model, "_jimmy") != -1)     { return false; }
    return true;
}
*/

AnyoneLoadedIn()
{
    // see if there are humans on the server
    for (new i=1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR && !IsFakeClient(i))  {
            return true;
        }
    }
    return false;
}

CountInfectedClass(any:ZClass, ignoreClient)
{
    // note: ghosts are considered 'alive', so return IsPlayerAlive() true too.
    
    // counts infected currently spawned/ghosted
    new classCount = 0, classType;

    for (new i=1; i <= MaxClients; i++)
    {
        if (i == ignoreClient) { continue; }                                // so it doesn't count the client's class that it is about to change..
        if (IsClientInGame(i) && GetClientTeam(i) == TEAM_INFECTED)
        {
            if ( IsPlayerAlive(i) )
            {
                classType = GetEntProp(i, Prop_Send, "m_zombieClass");
                if (classType == ZClass) { classCount++; }
            }
        }
    }
    return classCount;
}

// give an item to a player
GiveItem(client, String:item[STR_MAX_ITEMGIVEN], ammo, iOffset)
{
    // new approach
    decl entity;
    decl Float:clientOrigin[3];

    entity = CreateEntityByName(item);
    
    if (!IsValidEntity(entity)) {
        PrintDebug("[rand] error: no valid entity for spawning: %s", item);
        return -1;
    }
    
    GetClientAbsOrigin(client, clientOrigin);
    TeleportEntity(entity, clientOrigin, NULL_VECTOR, NULL_VECTOR);
    
    DispatchSpawn(entity);
    
    if (!ammo && StrEqual(item, "weapon_pistol")) {
        AcceptEntityInput(entity, "use", client);
    } else {
        EquipPlayerWeapon(client, entity);
        
        if (ammo > -1)
        {
            new iAmmoOffset = FindDataMapOffs(client, "m_iAmmo");
            SetEntData(client, (iAmmoOffset + iOffset), ammo);
        }
        else
        {
            new iAmmoOffset = FindDataMapOffs(client, "m_iAmmo");
            SetEntData(client, (iAmmoOffset + iOffset), 0);
        }
    }
    
    return entity;
}

GiveItemMelee(client, String:item[MELEE_CLASS_LENGTH])
{
    // new approach
    decl entity;
    decl Float:clientOrigin[3];

    entity = CreateEntityByName("weapon_melee");
    
    if (!IsValidEntity(entity)) {
        PrintDebug("[rand] error: no valid entity for spawning: %s", item);
        return;
    }
    
    GetClientAbsOrigin(client, clientOrigin);
    TeleportEntity(entity, clientOrigin, NULL_VECTOR, NULL_VECTOR);
    DispatchKeyValue(entity, "melee_script_name", item);
    
    DispatchSpawn(entity);
    EquipPlayerWeapon(client, entity);
}


// throw molotov
/*
public ThrowMolotov(i_Client)
{
    decl i_Ent, Float:f_Origin[3], Float:f_Speed[3], Float:f_Angles[3], String:s_TargetName[32], Float:f_CvarSpeed, String:s_Ent[4];
    
    i_Ent = CreateEntityByName("molotov_projectile");
    
    if (IsValidEntity(i_Ent)) {
        SetEntPropEnt(i_Ent, Prop_Data, "m_hOwnerEntity", i_Client);
        SetEntityModel(i_Ent, MODEL_W_MOLOTOV);
        FormatEx(s_TargetName, sizeof(s_TargetName), "molotov%d", i_Ent);
        DispatchKeyValue(i_Ent, "targetname", s_TargetName);
        DispatchSpawn(i_Ent);
    }
    
    g_ThrewGrenade[i_Client] = i_Ent;

    GetClientEyePosition(i_Client, f_Origin);
    GetClientEyeAngles(i_Client, f_Angles);
    GetAngleVectors(f_Angles, f_Speed, NULL_VECTOR, NULL_VECTOR);
    f_CvarSpeed = GetConVarFloat(h_CvarMolotovSpeed);
    
    f_Speed[0] *= f_CvarSpeed;
    f_Speed[1] *= f_CvarSpeed;
    f_Speed[2] *= f_CvarSpeed;
    
    GetRandomAngles(f_Angles);
    TeleportEntity(i_Ent, f_Origin, f_Angles, f_Speed);
    EmitSoundToAll(SOUND_MOLOTOV, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, f_Origin, NULL_VECTOR, false, 0.0);

    IntToString(i_Ent, s_Ent, sizeof(s_Ent));
    SetTrieValue(g_t_GrenadeOwner, s_Ent, i_Client);
    
    g_h_GrenadeTimer[i_Client] = CreateTimer(0.1, Timer_MolotovThink, i_Ent, TIMER_REPEAT);
}

public Action:Timer_MolotovThink(Handle:h_Timer, any:i_Ent)
{
    decl i_Client, String:s_Ent[4], String:s_ClassName[32];

    IntToString(i_Ent, s_Ent, sizeof(s_Ent));
    GetTrieValue(g_t_GrenadeOwner, s_Ent, i_Client);
    GetEdictClassname(i_Ent, s_ClassName, sizeof(s_ClassName));
    
    if (!IsValidEdict(i_Ent) || StrContains(s_ClassName, "projectile") == -1) {
        if (g_h_GrenadeTimer[i_Client] != INVALID_HANDLE) {
            KillTimer(g_h_GrenadeTimer[i_Client]);
            g_h_GrenadeTimer[i_Client] = INVALID_HANDLE;
            g_ThrewGrenade[i_Client] = 0;
            RemoveFromTrie(g_t_GrenadeOwner, s_Ent);
        }
        
        return Plugin_Handled;
    }
    
    decl Float:f_Origin[3];

    GetEntPropVector(i_Ent, Prop_Send, "m_vecOrigin", f_Origin);
    
    if (0.0 < OnGroundUnits(i_Ent) <= 10.0) {    
        if (g_h_GrenadeTimer[i_Client] != INVALID_HANDLE) {
            KillTimer(g_h_GrenadeTimer[i_Client]);
            g_h_GrenadeTimer[i_Client] = INVALID_HANDLE;
        }    
        
        g_ThrewGrenade[i_Client] = 0;
        RemoveEdict(i_Ent);
        
        i_Ent = CreateEntityByName("prop_physics");
        DispatchKeyValue(i_Ent, "physdamagescale", "0.0");
        DispatchKeyValue(i_Ent, "model", MODEL_GASCAN);
        DispatchSpawn(i_Ent);
        TeleportEntity(i_Ent, f_Origin, NULL_VECTOR, NULL_VECTOR);
        SetEntityMoveType(i_Ent, MOVETYPE_VPHYSICS);
        AcceptEntityInput(i_Ent, "Break");
        
        return Plugin_Continue;
    }
    else
    {
        decl Float:f_Angles[3];
        
        GetRandomAngles(f_Angles);
        TeleportEntity(i_Ent, NULL_VECTOR, f_Angles, NULL_VECTOR);
    }
    
    return Plugin_Continue;
}
*/


// spawning a zombie (cheap way :()
SpawnCommon(client, mobs = 1)
{
    new flags = GetCommandFlags("z_spawn");
    SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);
    for(new i=0; i < mobs; i++) {
        FakeClientCommand(client, "z_spawn infected auto");
    }
    SetCommandFlags("z_spawn", flags);
}

// spawning a zombie (in exact location, normal way)
SpawnCommonLocation(Float:location[3], bool: isFemale = false)
{
    new zombie = CreateEntityByName("infected");
    
    if (isFemale)
    {
        // force female model
        SetEntityModel(zombie, g_csFemaleCommonModels[ GetRandomInt(0, sizeof(g_csFemaleCommonModels) - 1) ]);
    }
    
    new ticktime = RoundToNearest( FloatDiv( GetGameTime() , GetTickInterval() ) ) + 5;
    SetEntProp(zombie, Prop_Data, "m_nNextThinkTick", ticktime);

    DispatchSpawn(zombie);
    ActivateEntity(zombie);
    
    TeleportEntity(zombie, location, NULL_VECTOR, NULL_VECTOR);
}
// spawning a horde (cheap way.. damnit)
SpawnPanicHorde(client, mobs = 1)
{
    new flags = GetCommandFlags("z_spawn");
    SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);
    for(new i=0; i < mobs; i++) {
        FakeClientCommand(client, "z_spawn mob auto");
    }
    SetCommandFlags("z_spawn", flags);
}



// create explosion (delayed)
public Action: Timer_CreateExplosion(Handle:timer, any:pack)
{
    new Float:targetPos[3];
    
    ResetPack(pack);
    new Float: power = ReadPackFloat(pack);
    targetPos[0] = ReadPackFloat(pack);
    targetPos[1] = ReadPackFloat(pack);
    targetPos[2] = ReadPackFloat(pack);
    CloseHandle(pack);
    
    CreateExplosion(targetPos, power);
    
    return Plugin_Continue;
}
// create explosion
CreateExplosion(Float:carPos[3], Float:power, bool:fire = false)
{
    decl String:sRadius[256];
    decl String:sPower[256];
    new Float:flMxDistance = float(EXPLOSION_RADIUS);
    if (!power) { power = EXPLOSION_POWER_LOW; }
    
    IntToString(EXPLOSION_RADIUS, sRadius, sizeof(sRadius));
    IntToString(RoundFloat(power), sPower, sizeof(sPower));
    new exParticle2 = CreateEntityByName("info_particle_system");
    new exParticle3 = CreateEntityByName("info_particle_system");
    new exPhys = CreateEntityByName("env_physexplosion");
    new exTrace = 0;
    new exHurt = CreateEntityByName("point_hurt");
    new exParticle = CreateEntityByName("info_particle_system");
    new exEntity = CreateEntityByName("env_explosion");
    /*new exPush = CreateEntityByName("point_push");*/
    
    //Set up the particle explosion
    DispatchKeyValue(exParticle, "effect_name", EXPLOSION_PARTICLE);
    DispatchSpawn(exParticle);
    ActivateEntity(exParticle);
    TeleportEntity(exParticle, carPos, NULL_VECTOR, NULL_VECTOR);
    
    DispatchKeyValue(exParticle2, "effect_name", EXPLOSION_PARTICLE2);
    DispatchSpawn(exParticle2);
    ActivateEntity(exParticle2);
    TeleportEntity(exParticle2, carPos, NULL_VECTOR, NULL_VECTOR);
    
    DispatchKeyValue(exParticle3, "effect_name", EXPLOSION_PARTICLE3);
    DispatchSpawn(exParticle3);
    ActivateEntity(exParticle3);
    TeleportEntity(exParticle3, carPos, NULL_VECTOR, NULL_VECTOR);
    
    if (fire) {
        exTrace = CreateEntityByName("info_particle_system");
        DispatchKeyValue(exTrace, "effect_name", FIRE_PARTICLE);
        DispatchSpawn(exTrace);
        ActivateEntity(exTrace);
        TeleportEntity(exTrace, carPos, NULL_VECTOR, NULL_VECTOR);
    }
    
    //Set up explosion entity
    DispatchKeyValue(exEntity, "fireballsprite", "sprites/muzzleflash4.vmt");
    DispatchKeyValue(exEntity, "iMagnitude", sPower);
    DispatchKeyValue(exEntity, "iRadiusOverride", sRadius);
    DispatchKeyValue(exEntity, "spawnflags", "828");
    DispatchSpawn(exEntity);
    TeleportEntity(exEntity, carPos, NULL_VECTOR, NULL_VECTOR);
    
    //Set up physics movement explosion
    DispatchKeyValue(exPhys, "radius", sRadius);
    DispatchKeyValue(exPhys, "magnitude", sPower);
    DispatchSpawn(exPhys);
    TeleportEntity(exPhys, carPos, NULL_VECTOR, NULL_VECTOR);
    
    
    //Set up hurt point
    DispatchKeyValue(exHurt, "DamageRadius", sRadius);
    DispatchKeyValue(exHurt, "DamageDelay", "0.5");
    DispatchKeyValue(exHurt, "Damage", "5");
    DispatchKeyValue(exHurt, "DamageType", "8");
    DispatchSpawn(exHurt);
    TeleportEntity(exHurt, carPos, NULL_VECTOR, NULL_VECTOR);
    
    switch(GetRandomInt(1,3)) {
        case 1: {
            if(!IsSoundPrecached(EXPLOSION_SOUND)) { PrecacheSound(EXPLOSION_SOUND); }
            EmitSoundToAll(EXPLOSION_SOUND);
        }
        case 2: {
            if(!IsSoundPrecached(EXPLOSION_SOUND2)) { PrecacheSound(EXPLOSION_SOUND2); }
            EmitSoundToAll(EXPLOSION_SOUND2);
        }
        case 3: {
            if(!IsSoundPrecached(EXPLOSION_SOUND3)) { PrecacheSound(EXPLOSION_SOUND3); }
            EmitSoundToAll(EXPLOSION_SOUND3);
        }
    }
    
    if(!IsSoundPrecached(EXPLOSION_DEBRIS)) {
        PrecacheSound(EXPLOSION_DEBRIS);
    }
    EmitSoundToAll(EXPLOSION_DEBRIS);
    
    //BOOM!
    AcceptEntityInput(exParticle, "Start");
    AcceptEntityInput(exParticle2, "Start");
    AcceptEntityInput(exParticle3, "Start");
    if (fire) { AcceptEntityInput(exTrace, "Start"); }
    AcceptEntityInput(exEntity, "Explode");
    AcceptEntityInput(exPhys, "Explode");
    AcceptEntityInput(exHurt, "TurnOn");
    
    new Handle:pack2 = CreateDataPack();
    WritePackCell(pack2, exParticle);
    WritePackCell(pack2, exParticle2);
    WritePackCell(pack2, exParticle3);
    if (fire) { WritePackCell(pack2, exTrace); } else { WritePackCell(pack2, -1); }
    WritePackCell(pack2, exEntity);
    WritePackCell(pack2, exPhys);
    if (fire) { WritePackCell(pack2, exHurt); } else { WritePackCell(pack2, -1); }
    CreateTimer(EXPLOSION_DURATION + 1.5, Timer_DeleteParticles, pack2, TIMER_FLAG_NO_MAPCHANGE);
    
    if (!fire) { 
        new Handle:pack3 = CreateDataPack();
        WritePackCell(pack3, exHurt);
        CreateTimer(EXPLOSION_DURATION_MIN, Timer_DeleteParticlesMin, pack3, TIMER_FLAG_NO_MAPCHANGE);
    }
    
    if (fire) {
        new Handle:pack = CreateDataPack();
        WritePackCell(pack, exTrace);
        WritePackCell(pack, exHurt);
        CreateTimer(EXPLOSION_DURATION, Timer_StopFire, pack, TIMER_FLAG_NO_MAPCHANGE);
    }
    
    decl Float:survivorPos[3], Float:traceVec[3], Float:resultingFling[3], Float:currentVelVec[3];
    for(new i=1; i<=MaxClients; i++)
    {
        if(!IsClientAndInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != TEAM_SURVIVOR) { continue; }

        GetEntPropVector(i, Prop_Data, "m_vecOrigin", survivorPos);
        
        //Vector and radius distance calcs by AtomicStryker!
        if(GetVectorDistance(carPos, survivorPos) <= flMxDistance)
        {
            MakeVectorFromPoints(carPos, survivorPos, traceVec);                // draw a line from car to Survivor
            GetVectorAngles(traceVec, resultingFling);                            // get the angles of that line
            
            resultingFling[0] = Cosine(DegToRad(resultingFling[1])) * power;    // use trigonometric magic
            resultingFling[1] = Sine(DegToRad(resultingFling[1])) * power;
            resultingFling[2] = power;
            
            GetEntPropVector(i, Prop_Data, "m_vecVelocity", currentVelVec);        // add whatever the Survivor had before
            resultingFling[0] += currentVelVec[0];
            resultingFling[1] += currentVelVec[1];
            resultingFling[2] += currentVelVec[2];
            
            FlingPlayer(i, resultingFling, i);
        }
    }
}

public Action:Timer_StopFire(Handle:timer, Handle:pack)
{
    ResetPack(pack);
    new particle = ReadPackCell(pack);
    new hurt = ReadPackCell(pack);
    CloseHandle(pack);
    
    if (IsValidEntity(particle)) {
        AcceptEntityInput(particle, "Stop");
    }
    
    if (IsValidEntity(hurt)) {
        AcceptEntityInput(hurt, "TurnOff");
    }
}

public Action:Timer_DeleteParticles(Handle:timer, Handle:pack)
{
    ResetPack(pack);
    
    new entity;
    for (new i = 1; i <= 7; i++) {
        entity = ReadPackCell(pack);
        
        if (IsValidEntity(entity)) {
            AcceptEntityInput(entity, "Kill");
        }
    }
    CloseHandle(pack);
}
public Action:Timer_DeleteParticlesMin(Handle:timer, Handle:pack)
{
    ResetPack(pack);
    
    new entity;
    entity = ReadPackCell(pack);
    
    if (IsValidEntity(entity)) {
        AcceptEntityInput(entity, "Kill");
    }
    
    CloseHandle(pack);
}

stock FlingPlayer(target, Float:vector[3], attacker, Float:stunTime = 3.0)
{
    SDKCall(g_CallPushPlayer, target, vector, 76, attacker, stunTime);
}





// fire explosion (trick)
public CreateFire(Float:f_Origin[3], bool:fireWorks)
{
    new i_Ent = CreateEntityByName("prop_physics");
    DispatchKeyValue(i_Ent, "physdamagescale", "0.0");
    if (fireWorks) {
        DispatchKeyValue(i_Ent, "model", MODEL_FIREWORKS);
    } else {
        DispatchKeyValue(i_Ent, "model", MODEL_GASCAN);
    }
    DispatchSpawn(i_Ent);
    TeleportEntity(i_Ent, f_Origin, NULL_VECTOR, NULL_VECTOR);
    SetEntityMoveType(i_Ent, MOVETYPE_VPHYSICS);
    AcceptEntityInput(i_Ent, "Break");
}



Float: FindDistanceFromFloor(entity)
{
    new Float: pos[3];
    new Float: tmpPos[3];
    new Float: floor[3];
    new Float: direction[3];
    new Handle: trace;
    
    direction[0] = 89.0; // downwards
    GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
    
    new bool: bFoundFloor = false;
    new Float: fNewZ = pos[2];
    
    // do a bunch of TRs and save what we find
    for (new i=0; i < 3; i++)
    {
        tmpPos = pos;
        switch (i) {
            case 1: { tmpPos[0] += 3; tmpPos[1] += 3; }
            case 2: { tmpPos[0] -= 3; tmpPos[1] -= 3; }
        }
        
        trace = TR_TraceRayFilterEx(tmpPos, direction, MASK_SOLID, RayType_Infinite, _TraceFilter, entity);
        if (TR_DidHit(trace))
        {
            TR_GetEndPosition(floor, trace);
            if (FloatAbs(pos[2] - floor[2]) && FloatAbs(pos[2] - floor[2]) < MAX_RAYDIF) {
                // if it's absolutely farther away than what we found before, keep it
                if (FloatAbs(pos[2] - floor[2]) > FloatAbs(pos[2] - fNewZ)) {
                    bFoundFloor = true;
                    fNewZ = floor[2];
                }
            }
        }
        if (trace != INVALID_HANDLE) { CloseHandle(trace); }
    }
        
    new Float: fDif = fNewZ;
    
    if (bFoundFloor == false) {          // no floor found, so don't change
        fDif = 0.0;
    } else {
        fDif = pos[2] - fNewZ;
    }
    return fDif;
}

public bool:_TraceFilter(entity, contentsMask, any:data)
{
    // only check if we're not hitting ourselves
    if (!entity || entity == data || !IsValidEntity(entity)) { return false; }
    return true;
}   





PickTankPlayer()
{
    // randomly pick one
    
    new pick = 0;
    new pickCount = 0;
    new pickArray[96];
    new tickets = 5;
    
    for (new i=1; i < MaxClients+1; i++)
    {
        if (IsInfected(i) && !IsFakeClient(i))
        {
            // if you didn't get one before, 5 entries
            tickets = 5;
            
            // -1 per tank you had. otherwise, scratch one, minimum of 1
            if (g_iHadTanks[i] > 0) { tickets -= g_iHadTanks[i]; }
            if (tickets < 1) { tickets = 1; }
            
            for (new j=0; j < tickets; j++)
            {
                pickArray[pickCount] = i;
                pickCount++;
            }
        }
    }
    
    pick = GetRandomInt(0, pickCount - 1);
    pick = pickArray[pick];
    
    return pick;
}

ForceTankPlayer()
{
    // randomly pick a tank player
    new tank = PickTankPlayer();
    
    if (tank == 0) { return; }
    
    if (g_iHadTanks[tank] < 100) { g_iHadTanks[tank]++; }
    
    for (new i = 1; i < MaxClients+1; i++)
    {
        if (!IsClientConnected(i) || !IsClientInGame(i)) { continue; }
        
        if (IsInfected(i))
        {
            if (tank == i) {
                L4D2Direct_SetTankTickets(i, 20000);
            }
            else {
                L4D2Direct_SetTankTickets(i, 0);
            }
        }
    }
}

// checking for availability of melee weapons:
bool: IsMeleeAvailable(const String:type[])
{
    for (new i=0; i < g_iMeleeClassCount; i++)
    {
        if (StrEqual(type, g_sMeleeClass[i], false)) {
            return true;
        }
    }
    
    return false;
}


/*  Support, spawn class selection
    ------------------------------ */
// manipulate array by reference so we can easily manage a tmp pick-array
AddSpawnClass(classes[], &numFilled, zclass)
{
    for (new i=0; i < numFilled; i++)
    {
        if (classes[i] == zclass) { return; }
    }
    classes[numFilled] = zclass;
    numFilled++;
}

RemoveSpawnClass(classes[], &numFilled, zclass)
{
    if (numFilled == 0) { return; }
    
    new bool: found = false;
    for (new i=0; i < numFilled; i++)
    {
        if (classes[i] == zclass) {
            found = true;
        }
        if (found && i + 1 < numFilled) {
            classes[i] = classes[i+1];
        }
    }
    if (found) {
        numFilled--;
    }
}

bool: IsAcceptedClass(classes[], numFilled, zclass)
{
    for (new i=0; i < numFilled; i++)
    {
        if (classes[i] == zclass) { return true; }
    }
    return false;
}


/*  Support, blind infected
    -------------------------- */

public Action:Timer_EntCheck(Handle:timer)
{
    new size = GetArraySize(g_hBlockedEntities);
    decl currentEnt[EntInfo];

    for (new i; i < size; i++)
    {
        GetArrayArray(g_hBlockedEntities, i, currentEnt[0]);
        if (!currentEnt[hasBeenSeen] && IsVisibleToSurvivors(currentEnt[iEntity]))
        {
            //PrintDebug("Unblinding for item %i", i);
            //decl String:tmp[128];
            //GetEntPropString(currentEnt[iEntity], Prop_Data, "m_ModelName", tmp, sizeof(tmp));      // why this? I don't get it, but okay. (try removing it once it works)
            currentEnt[hasBeenSeen] = true;
            SetArrayArray(g_hBlockedEntities, i, currentEnt[0]);
        }
    }
}

public ItemsBlindInfected()
{
    decl bhTemp[EntInfo];
    
    PrintDebug("[rand] Blinding for %i items...", g_iCreatedEntities);
    
    // use list of created items to handle only the entities we need
    for (new i = 0; i < g_iCreatedEntities; i++)
    {
        SDKHook(g_iArCreatedEntities[i], SDKHook_SetTransmit, OnTransmit);
        bhTemp[iEntity] = g_iArCreatedEntities[i];
        bhTemp[hasBeenSeen] = false;
        //PrintDebug("Blinding for item %i", bhTemp[0]);
        PushArrayArray(g_hBlockedEntities, bhTemp[0]);
    }
}

bool:IsVisibleToSurvivors(entity)
{
    new iSurv;

    for (new i = 1; i < MaxClients && iSurv < 4; i++) {
        if (IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR) {
            iSurv++;
            if (IsPlayerAlive(i) && IsVisibleTo(i, entity)) {
                return true;
            }
        }
    }

    return false;
}

// check an entity for being visible to a client
bool:IsVisibleTo(client, entity) 
{
    decl Float:vAngles[3], Float:vOrigin[3], Float:vEnt[3], Float:vLookAt[3];
    
    if ( !IsValidEntity(entity) ) {
        //PrintDebug("BlindEntCheck: not a valid entity: %i (client: %N)", entity, client);
        // remove it from blind-check list (by tagging it as 'seen')
        SetBlindEntityAsSeen(entity);
        return false;
    }
    
    // check classname to catch weird predicted_viewmodel problem:
    decl String:classname[64];
    GetEdictClassname(entity, classname, sizeof(classname));
    new entityBlindable: classnameBlindable;
    
    if (GetTrieValue(g_hTrieBlindable, classname, classnameBlindable)) {
        if (classnameBlindable == ENTITY_NOT_BLINDABLE) {
            //PrintDebug("BlindEntCheck: unblindable entity problem: %i (class: %s) (client: %N)", entity, classname, client);
            SetBlindEntityAsSeen(entity);
            return false;
        }
    }
    
    GetClientEyePosition(client,vOrigin);
    GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vEnt);
    MakeVectorFromPoints(vOrigin, vEnt, vLookAt);
    GetVectorAngles(vLookAt, vAngles);
    
    new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, BlindTraceFilter);
    
    new bool:isVisible = false;
    if (TR_DidHit(trace))
    {
        decl Float:vStart[3];
        TR_GetEndPosition(vStart, trace);
        
        if ((GetVectorDistance(vOrigin, vStart, false) + BLND_TRACE_TOLERANCE) >= GetVectorDistance(vOrigin, vEnt))
        {
            isVisible = true;
        }
    }
    else
    {
        isVisible = true;
    }
    CloseHandle(trace);
    return isVisible;
}

public bool:BlindTraceFilter(entity, contentsMask)
{
    if (entity <= MaxClients || !IsValidEntity(entity)) { return false; }
    
    decl String:class[128];
    GetEdictClassname(entity, class, sizeof(class));
    
    return !StrEqual(class, "prop_physics", false);
}


// this simply sets an entity as visible (basically to be ignored if it causes problems)
public SetBlindEntityAsSeen(entity)
{
    new size = GetArraySize(g_hBlockedEntities);
    decl currentEnt[EntInfo];

    for (new i; i < size; i++)
    {
        GetArrayArray(g_hBlockedEntities, i, currentEnt[0]);
        if (entity == currentEnt[iEntity])
        {
            currentEnt[hasBeenSeen] = true;
            SetArrayArray(g_hBlockedEntities, i, currentEnt[0]);
            break;
        }
    }
}


// returns true as long as no survivor is in any saferoom
bool: NoSurvivorInSaferoom()
{
    for (new i=1; i <= MaxClients; i++)
    {
        if (IsSurvivor(i) && IsPlayerAlive(i))
        {
            if (IsEntityInSaferoom(i, true, false) || IsEntityInSaferoom(i, true, true)) { return false; }
        }
    }
    return true;
}

/*  CRox multiwitch plugin
    ---------------------- */
public Action:Timer_WitchSpawn(Handle:timer)
{
    if (_:g_iSpecialEvent != EVT_WITCHES) {
        g_hWitchSpawnTimer = INVALID_HANDLE;
        return Plugin_Stop;
    }
    
    if (!g_bIsTankInPlay && !g_bIsPaused && g_bPlayersLeftStart && NoSurvivorInSaferoom())
    {
        
        for (new i=1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i))
            {
                CheatCommand(i, "z_spawn", "witch auto");
                return Plugin_Continue;
            }
        }
    }
    return Plugin_Continue;
}
public Action:Timer_WitchRespawn(Handle:timer)
{
    if (_:g_iSpecialEvent != EVT_WITCHES) { return Plugin_Stop; }
    
    if (!g_bIsTankInPlay && !g_bIsPaused && g_bPlayersLeftStart && NoSurvivorInSaferoom())
    {
        new psychonic = GetMaxEntities();
        decl String:buffer[64];
        decl Address:pNavArea;
        decl Float:flow;
        new Float:survMaxFlow = MULTIWITCH_GetMaxSurvivorCompletion();
        new witchSpawnCount = 0;
        decl Float:origin[3];
        decl m_nSequence;

        if (survMaxFlow > MULTIWITCH_EXTRA_FLOW)
        {
            for (new entity = MaxClients+1; entity <= psychonic; entity++)
            {
                if (IsValidEntity(entity) && GetEntityClassname(entity, buffer, sizeof(buffer)) && StrEqual(buffer, "witch"))
                {
                    m_nSequence = GetEntProp(entity, Prop_Send, "m_nSequence");
                    // We only want to respawn fully passive witches
                    switch (m_nSequence)
                    {
                        case 2, 10, 11, 4:
                        {
                            GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
                            pNavArea = L4D2Direct_GetTerrorNavArea(origin);
                            flow = L4D2Direct_GetTerrorNavAreaFlow(pNavArea);
                            if (survMaxFlow > flow + MULTIWITCH_EXTRA_FLOW) {
                                AcceptEntityInput(entity, "Kill");
                                witchSpawnCount++;
                            }
                        }
                    }
                }
            }
        }

        if (witchSpawnCount)
        {
            for (new client = 1; client <= MaxClients; client++)
            {
                if (IsClientInGame(client)) {
                    for (new i = 0; i < witchSpawnCount; i++)
                    {
                        CheatCommand(i, "z_spawn", "witch auto");
                    }
                    break;
                }
            }
        }
    }
    
    return Plugin_Continue;
}

Float:MULTIWITCH_GetMaxSurvivorCompletion()
{
    new Float:flow = 0.0;
    decl Float:tmp_flow;
    decl Float:origin[3];
    decl Address:pNavArea;
    for (new client = 1; client <= MaxClients; client++)
    {
        if (IsClientInGame(client) && GetClientTeam(client) == TEAM_SURVIVOR)
        {
            GetClientAbsOrigin(client, origin);
            pNavArea = L4D2Direct_GetTerrorNavArea(origin);
            if (pNavArea != Address_Null)
            {
                tmp_flow = L4D2Direct_GetTerrorNavAreaFlow(pNavArea);
                flow = (flow > tmp_flow) ? flow : tmp_flow;
            }
        }
    }
    return flow;
}

/*
    L4D2 Storm plugin
    -------------------------- */
    
SUPPORT_StormReset()
{
    new Handle: hTmpCVar = FindConVar("l4d2_storm_allow");
    if (hTmpCVar != INVALID_HANDLE) {
        SetConVarInt(hTmpCVar, 0);
        ServerCommand("sm_stormreset");
        PrintDebug("[rand] Stopped Storm");
    }
    //PrintDebug("storm convar: %i", GetConVarInt(FindConVar("l4d2_storm_allow")));
}

SUPPORT_StormStart()
{
    new Handle: hTmpCVar = FindConVar("l4d2_storm_allow");
    if (hTmpCVar != INVALID_HANDLE) {
        SetConVarInt(hTmpCVar, 1);
        ServerCommand("sm_stormrefresh");
        PrintDebug("[rand] Started Storm");
    }
}






/*  Vocalization (by AtomicStryker)
    ----------------------------- */

public Action: Timer_Vocalize_Random(Handle:timer, any:pack)
{
    ResetPack(pack);
    new client = ReadPackCell(pack);
    new String: arg[256];
    ReadPackString(pack, arg, sizeof(arg));
    CloseHandle(pack);
    
    Vocalize_Random(client, arg);
}

public Vocalize_Random(client, String:arg[256])
{
    if (!client || !IsClientAndInGame(client)) { return; }
    
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
    
    
    decl String:scenefile[256], String:checknumber[3];
    new foundfilescounter;
    decl validfiles[71];
    for (new i = 1; i <= 70; i++) {
        if (i < 10) {
            FormatEx(checknumber, sizeof(checknumber), "0%i", i);
        }
        else {
            FormatEx(checknumber, sizeof(checknumber), "%i", i);
        }
        
        FormatEx(scenefile, sizeof(scenefile), "scenes/%s/%s%s.vcd", model, arg, checknumber);
        
        if (!FileExists(scenefile)) continue;
        
        foundfilescounter++;
        validfiles[foundfilescounter] = i;
    }
    
    if (!foundfilescounter) { return; }
    
    
    new randomint = GetRandomInt(1, foundfilescounter);
    if (validfiles[randomint] < 10) {
        FormatEx(checknumber, sizeof(checknumber), "0%i", validfiles[randomint]);
    }
    else {
        FormatEx(checknumber, sizeof(checknumber), "%i", validfiles[randomint]);
    }
    FormatEx(scenefile, sizeof(scenefile), "scenes/%s/%s%s.vcd", model, arg, checknumber);
    
    
    // do vocalization    
    new tempent = CreateEntityByName("instanced_scripted_scene");
    DispatchKeyValue(tempent, "SceneFile", scenefile);
    DispatchSpawn(tempent);
    SetEntPropEnt(tempent, Prop_Data, "m_hOwner", client);
    ActivateEntity(tempent);
    AcceptEntityInput(tempent, "Start", client, client);
    HookSingleEntityOutput(tempent, "OnCompletion", EntityOutput:OnSceneCompletion, true);

    return;
}

public Vocalize_Specific(client, String:arg[256])
{
    if (!client || !IsClientAndInGame(client)) { return; }
    
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
    
    decl String:scenefile[256];
    FormatEx(scenefile, sizeof(scenefile), "scenes/%s/%s.vcd", model, arg);
    
    if (!FileExists(scenefile)) { return; }
    
    
    new tempent = CreateEntityByName("instanced_scripted_scene");
    DispatchKeyValue(tempent, "SceneFile", scenefile);
    DispatchSpawn(tempent);
    SetEntPropEnt(tempent, Prop_Data, "m_hOwner", client);
    ActivateEntity(tempent);
    AcceptEntityInput(tempent, "Start", client, client);
    HookSingleEntityOutput(tempent, "OnCompletion", EntityOutput:OnSceneCompletion, true);

    return;
}

public OnSceneCompletion(const String:s_Output[], i_Caller, i_Activator, Float:f_Delay)
{
    RemoveEdict(i_Caller);
}




/*
// for debugging blindents
DoBlindEntReport()
{
    PrintDebug("[rand] Randomized item table, for %i items:", g_iStoredEntities);
    
    new String: tmpStr[64];
    new count = 0;
    
    PrintDebug("[rand] --------------- stored entity list -----------------");
    
    for (new i=0; i < g_iStoredEntities; i++)
    {
        // don't show stuff that won't be blinded
        if (g_strArStorage[i][entPickedType] == _:PCK_NOITEM) { continue; }
        if (g_strArStorage[i][entPickedType] == _:PCK_JUNK) { continue; }
        if (g_strArStorage[i][entPickedType] == _:PCK_EXPLOSIVE_BARREL) { continue; }
        if (g_strArStorage[i][entPickedType] == _:PCK_SILLY_GIFT) { continue; }
        
        count++;
        
        if (IsValidEntity(g_strArStorage[i][entNumber])) {
            GetEntityClassname( g_strArStorage[i][entNumber], tmpStr, sizeof(tmpStr) );
        } else {
            tmpStr = "";
        }
        
        PrintDebug( "  Item: %4i:  entity %5i (= %s), classname: %s.", i, g_strArStorage[i][entNumber], g_csItemPickName[ g_strArStorage[i][entPickedType] ], tmpStr );
    }
    
    PrintDebug("[rand] how many blindable stored: %4i", count);
    count = 0;
    
    PrintDebug("[rand] --------------- blinded entity list -----------------");
    
    new size = GetArraySize(g_hBlockedEntities);
    decl currentEnt[EntInfo];

    for (new i; i < size; i++)
    {
        GetArrayArray(g_hBlockedEntities, i, currentEnt[0]);
        
        if (currentEnt[hasBeenSeen]) { continue; }
        
        if (currentEnt[iEntity] != 0 && IsValidEntity(currentEnt[iEntity])) {
            GetEntityClassname( currentEnt[iEntity], tmpStr, sizeof(tmpStr) );
        } else {
            tmpStr = "";
        }
        
        count++;
        
        PrintDebug( "  BlindEnt: %4i:  entity %5i = classname: %s.", i, currentEnt[iEntity], tmpStr );
        
    }
    
    PrintDebug("[rand] how many blindable blinded: %4i", count);
}
*/

// for debugging item balance
DoItemsServerReport(full=false)
{
    PrintDebug("[rand] Randomized item table, for %i items:", g_iStoredEntities);
    
    new iGroupCount[INDEX_TOTAL];        // counts per index group
    new iItemCount[pickType];   // counts per item
    new iTotalRealItems = 0;    // how many non-no-item
    
    // weights
    new iWeight[INDEX_TOTAL];
    new iTotalWeight = 0;
    for (new i=INDEX_NOITEM; i < INDEX_TOTAL; i++)
    {
        iWeight[i] = GetConVarInt(g_hArCvarWeight[i]);
        iTotalWeight += iWeight[i];
    }
    
    new String: tmpStr[64];
    
    if (full) {
        PrintDebug("[rand] --------------- entity list -----------------");
    }
    
    g_iCountItemGnomes = 0;
    g_iCountItemCola = 0;
    g_iCountItemMedkits = 0;
    g_iCountItemDefibs = 0;
    
    for (new i=0; i < g_iStoredEntities; i++)
    {
        iItemCount[ g_strArStorage[i][entPickedType] ]++;
        
        // count towards group
        switch (_:g_strArStorage[i][entPickedType])
        {
            case PCK_NOITEM: { iGroupCount[INDEX_NOITEM]++; }
            case PCK_PISTOL: { iGroupCount[INDEX_PISTOL]++; } case PCK_PISTOL_MAGNUM: { iGroupCount[INDEX_PISTOL]++; }
            case PCK_SMG_MP5: { iGroupCount[INDEX_T1SMG]++; } case PCK_SMG: { iGroupCount[INDEX_T1SMG]++; } case PCK_SMG_SILENCED: { iGroupCount[INDEX_T1SMG]++; }
            case PCK_PUMPSHOTGUN: { iGroupCount[INDEX_T1SHOTGUN]++; } case PCK_SHOTGUN_CHROME: { iGroupCount[INDEX_T1SHOTGUN]++; }
            case PCK_RIFLE_SG552: { iGroupCount[INDEX_T2RIFLE]++; } case PCK_RIFLE: { iGroupCount[INDEX_T2RIFLE]++; } case PCK_RIFLE_AK47: { iGroupCount[INDEX_T2RIFLE]++; } case PCK_RIFLE_DESERT: { iGroupCount[INDEX_T2RIFLE]++; }
            case PCK_AUTOSHOTGUN: { iGroupCount[INDEX_T2SHOTGUN]++; } case PCK_SHOTGUN_SPAS: { iGroupCount[INDEX_T2SHOTGUN]++; }
            case PCK_HUNTING_RIFLE: { iGroupCount[INDEX_SNIPER]++; } case PCK_SNIPER_MILITARY: { iGroupCount[INDEX_SNIPER]++; } case PCK_SNIPER_SCOUT: { iGroupCount[INDEX_SNIPER]++; } case PCK_SNIPER_AWP: { iGroupCount[INDEX_SNIPER]++; }
            case PCK_MELEE: { iGroupCount[INDEX_MELEE]++; }
            case PCK_CHAINSAW: { iGroupCount[INDEX_T3]++; } case PCK_GRENADE_LAUNCHER: { iGroupCount[INDEX_T3]++; } case PCK_RIFLE_M60: { iGroupCount[INDEX_T3]++; }
            case PCK_EXPLOSIVE_BARREL: { iGroupCount[INDEX_CANISTER]++; } case PCK_GASCAN: { iGroupCount[INDEX_CANISTER]++; } case PCK_PROPANETANK: { iGroupCount[INDEX_CANISTER]++; } case PCK_OXYGENTANK: { iGroupCount[INDEX_CANISTER]++; } case PCK_FIREWORKCRATE: { iGroupCount[INDEX_CANISTER]++; }
            case PCK_AMMO: { iGroupCount[INDEX_AMMO]++; }
            case PCK_PAIN_PILLS: { iGroupCount[INDEX_PILL]++; } case PCK_ADRENALINE: { iGroupCount[INDEX_PILL]++; }
            case PCK_MOLOTOV: { iGroupCount[INDEX_THROWABLE]++; } case PCK_PIPEBOMB: { iGroupCount[INDEX_THROWABLE]++; } case PCK_VOMITJAR: { iGroupCount[INDEX_THROWABLE]++; }
            case PCK_FIRST_AID_KIT: { iGroupCount[INDEX_KIT]++; g_iCountItemMedkits++; } case PCK_DEFIBRILLATOR: { iGroupCount[INDEX_KIT]++; g_iCountItemDefibs++; }
            case PCK_UPG_LASER: { iGroupCount[INDEX_UPGRADE]++; } case PCK_UPG_EXPLOSIVE: { iGroupCount[INDEX_UPGRADE]++; } case PCK_UPG_INCENDIARY: { iGroupCount[INDEX_UPGRADE]++; }
            case PCK_JUNK: { iGroupCount[INDEX_JUNK]++; }
            case PCK_SILLY_GNOME: { iGroupCount[INDEX_SILLY]++; g_iCountItemGnomes++; } case PCK_SILLY_COLA: { iGroupCount[INDEX_SILLY]++; g_iCountItemCola++; }
            case PCK_SILLY_GIFT: { iGroupCount[INDEX_GIFT]++; }
        }
        
        if (g_strArStorage[i][entNumber] == 0) { continue; }
        
        if (IsValidEntity(g_strArStorage[i][entNumber])) {
            GetEntityClassname( g_strArStorage[i][entNumber], tmpStr, sizeof(tmpStr) );
        } else {
            tmpStr = "";
        }
        
        if (full) {
            PrintDebug( "  Item: %4i: entity %5i (= %s), classname: %s.", i, g_strArStorage[i][entNumber], g_csItemPickName[ g_strArStorage[i][entPickedType] ], tmpStr );
        }
    }
    
    if (full) { return; }
    
    iTotalRealItems = g_iStoredEntities - iItemCount[PCK_NOITEM];
    
    /*
    PrintDebug("[rand] --------------- item list -----------------");
    
    PrintDebug( "  %18s: %4i ( %5.1f%% /        ).", "no item", iItemCount[0], float(iItemCount[0]) / float(g_iStoredEntities) * 100.0 );
    PrintDebug( "  %18s: %4i ( %5.1f%% /        ).", g_csItemPickName[PCK_JUNK], iItemCount[PCK_JUNK], float(iItemCount[PCK_JUNK]) / float(g_iStoredEntities) * 100.0 );
    PrintDebug("");
    
    for (new i=PCK_PISTOL; i < _:PCK_DUALS; i++)
    {
        if (i == _:PCK_JUNK) { continue; }
        PrintDebug( "  %18s: %4i ( %5.1f%% / %5.1f%% ).", g_csItemPickName[i], iItemCount[i], float(iItemCount[i]) / float(g_iStoredEntities) * 100.0, float(iItemCount[i]) / float(iTotalRealItems) * 100.0 );
    }
    */
    PrintDebug("---------------------- type list --------------------------------------------------------- real items: %4i", iTotalRealItems);
    
    PrintDebug( "  %18s: %4i ( %5.1f%% /        ). Weighted at: %5.1f%%", "no item", iGroupCount[0], float(iGroupCount[0]) / float(g_iStoredEntities) * 100.0, float(iWeight[0]) / float(iTotalWeight) * 100.0 );
    PrintDebug( "  %18s: %4i ( %5.1f%% /        ). Weighted at: %5.1f%%", g_csItemTypeText[INDEX_JUNK], iGroupCount[INDEX_JUNK], float(iGroupCount[INDEX_JUNK]) / float(g_iStoredEntities) * 100.0, float(iWeight[INDEX_JUNK]) / float(iTotalWeight) * 100.0, float(iWeight[INDEX_JUNK]) / float(iTotalWeight) * 100.0  );
    PrintDebug("-----------------------------------------------------------------------------------------------------------");
    
    iTotalWeight = (iTotalWeight - iWeight[0]) - iWeight[INDEX_JUNK];
    
    for (new i=INDEX_PISTOL; i < _:INDEX_TOTAL; i++)
    {
        if (i == _:INDEX_JUNK) { continue; }
        PrintDebug( "  %18s: %4i ( %5.1f%% / %5.1f%% ). Weighted at: %5.1f%%, expected occurrence: %3i (diff.: %3i).",
                g_csItemTypeText[i], iGroupCount[i],
                float(iGroupCount[i]) / float(g_iStoredEntities) * 100.0, float(iGroupCount[i]) / float(iTotalRealItems) * 100.0,
                float(iWeight[i]) / float(iTotalWeight) * 100.0,
                RoundFloat( (float(iWeight[i]) / float(iTotalWeight)) * iTotalRealItems ),
                iGroupCount[i] - RoundFloat( (float(iWeight[i]) / float(iTotalWeight)) * iTotalRealItems )
            );
    }
    
    PrintDebug("-----------------------------------------------------------------------------------------------------------");
    
}