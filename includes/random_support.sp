#pragma semicolon 1
#include <sourcemod>


// called as timer (to avoid some problems)
public Action: SUPPORT_RoundPreparation(Handle:timer)
{
    // only reset on first roundhalf:
    if (!g_bSecondHalf)
    {
        g_bStripperAltDetected = false;
        SetConVarInt(FindConVar("sv_force_time_of_day"), -1);
        RNDBNS_SetScaleMode( GetConVarInt(g_hCvarRandBonusScaleMode) );
    }
    
    // only reset on first roundhalf or if event's not equal
    if (!g_bSecondHalf || !(GetConVarInt(g_hCvarEqual) & EQ_EVENT))
    {
        g_bT2Nerfed = true;
        g_bNoPriWeapons = false;
        g_bNoSecWeapons = false;
        g_bNoAmmo = false;
        g_bNoHealthItems = false;
        g_bSpecialEventPlayerCheck = false;
        g_bNoSpawnBalance = false;
        g_bFreezeDistanceOnTank = GetConVarBool( g_hCvarFreezeDistanceTank );
    }
    
    if (!g_bSecondHalf || !(GetConVarInt(g_hCvarEqual) & EQ_TANKS))
    {
        g_bTankFirstRound = false;
        g_bWitchFirstRound = false;
    }
    
    // called before randomization
    g_bIsPaused = false;
    g_fPauseAttemptTime = 0.0;
    
    g_bIsFirstAttack = true;            // set in mapend / roundend... overkill but safeguard
    g_bPlayersLeftStart = false;
    g_bFirstReportDone = false;
    g_iSpectateGhostCount = 0;
    
    g_bInsightSurvDone = false;         // so we only get the insight effect from a gift once per roundhalf
    g_bInsightInfDone = false;
    g_bCarAlarmsDisabled = false;
    
    g_bTeamSurvivorVoted = false;       // for teamshuffle
    g_bTeamInfectedVoted = false;
    g_bTeamSurvivorVotedEvent = false;  // for picking an event for next round
    g_bTeamInfectedVotedEvent = false;
    
    g_bFirstTankSpawned = false;
    g_bFirstTankDied = false;
    g_bSecondTankSet = false;
    //g_bSecondTankSpawned = false;
    g_bIsTankInPlay = false;
    g_fTankPreviousPass = 0.0;
    g_iTankPass = 0;
    g_iTankClient = 0;
    
    g_iWitchesSpawned = 0;
    
    g_iBonusCount = 0;
    g_fDudTimeExpire = 0.0;
    
    // basic cleanup
    SUPPORT_CleanArrays();              // clear general arrays
    ClearArray(g_hBlockedEntities);     // clear blind infected entities
    ClearBoomerTracking();              // clear arrays for tracking boomer combo's
    ResetGnomes();                      // clear gnome tracking array for bonus scoring
    HatsRemoveAll();                    // remove hats (set them with EVENT_RoundStartPrep)
    
    // timer cleanup
    g_hTimePenaltyTimer = INVALID_HANDLE;
    g_hBoomFluTimer = INVALID_HANDLE;
    
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
    RNDBNS_SetPenaltyBonus( 0 );        // clear pbonus display value
    
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
    if (g_iSpecialEvent == EVT_SILENCE || g_iSpecialEvent == EVT_AMMO) {
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
    if (g_iSpecialEvent == EVT_WEATHER || g_iSpecialEvent == EVT_FOG)
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
    if (g_iSpecialEvent == EVT_BOOBYTRAP)
    {
        EVENT_PickBoobyTraps();
    }
    
    // blind infected to items generated
    ItemsBlindInfected();
    
    // output debug info about gnomes
    DoGnomesServerReport();
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
        g_bClassPicked[i] = false;
        
        g_iClientUsing[i] = 0;
        g_bClientHoldingUse[i] = false;
        g_bAlreadyVomitedUpon[i] = false;
        g_bPlayerIsBlinded[i] = false;
        
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


// Event functions
// ---------------

EVENT_ResetOtherCvars()
{
    // don't do this if defaults were not loaded yet
    if (!g_bDefaultCvarsLoaded)
    {
        INIT_TryCVarsGetDefault();
        if (!g_bDefaultCvarsLoaded) { return; }
    }
        
    // for defib event
    PrintDebug(3, "[rand] CVars: Reset defib penalty (to: %i)", g_iDefDefibPenalty);
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
    g_iActiveAmmoAk = GetConVarInt(g_hCvarAmmoAk);
    g_iActiveAmmoScout = GetConVarInt(g_hCvarAmmoScout);
    g_iActiveAmmoAWP = GetConVarInt(g_hCvarAmmoAWP);
    
    SetConVarFloat(FindConVar("survivor_friendly_fire_factor_normal"), g_fDefFFFactor);
    SetConVarInt(FindConVar("z_tank_health"), g_iDefTankHealth);
    SetConVarInt(FindConVar("z_frustration_lifetime"), g_iDefTankFrustTime);
    SetConVarInt(FindConVar("vs_tank_damage"), g_iDefTankDamage);
    SetConVarFloat(FindConVar("versus_tank_flow_team_variation"), g_fDefTankFlowVariation);
    
    SetConVarInt(FindConVar("z_vomit_interval"), g_iDefVomitInterval);
    SetConVarInt(FindConVar("z_spit_interval"), g_iDefSpitInterval);
    
    SetConVarFloat(FindConVar("sv_infected_ceda_vomitjar_probability"), g_fDefCedaBileProb);
    SetConVarFloat(FindConVar("sv_infected_riot_control_tonfa_probability"), g_fDefRiotTonfaProb);
    
    // hittable control
    if (FindConVar("hc_car_standing_damage") != INVALID_HANDLE) {
        new tmpDmg = (g_RI_bWeakHittables) ? g_RC_iWeakHittableDmg : g_iDefTankHittableDamage;
        SetConVarInt(FindConVar("hc_sflog_standing_damage"), tmpDmg);
        SetConVarInt(FindConVar("hc_bhlog_standing_damage"), tmpDmg);
        SetConVarInt(FindConVar("hc_car_standing_damage"), tmpDmg);
        SetConVarInt(FindConVar("hc_bumpercar_standing_damage"), tmpDmg);
        SetConVarInt(FindConVar("hc_forklift_standing_damage"), tmpDmg);
        SetConVarInt(FindConVar("hc_dumpster_standing_damage"), tmpDmg);
        SetConVarInt(FindConVar("hc_haybale_standing_damage"), tmpDmg);
        SetConVarInt(FindConVar("hc_baggage_standing_damage"), tmpDmg);
        SetConVarInt(FindConVar("hc_incap_standard_damage"), tmpDmg);
    }
    
    // pounce uncap
    if (g_hCvarPounceUncapDamage != INVALID_HANDLE && g_hCvarPounceUncapRange != INVALID_HANDLE) {
        SetConVarInt(g_hCvarPounceUncapDamage, g_iPounceUncapDamageMax);
        SetConVarFloat(g_hCvarPounceUncapRange, g_fPounceUncapRangeMax);
    }
}

EVENT_ResetDifficulty()
{
    // don't do this if defaults were not loaded yet
    if (!g_bDefaultCvarsLoaded)
    {
        INIT_TryCVarsGetDefault();
        if (!g_bDefaultCvarsLoaded) { return; }
    }
    
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
            SetConVarInt(FindConVar("z_ghost_delay_min"), RoundFloat(float(g_iDefSpawnTimeMin) * g_RC_fEventSITimeVeryEasy));
            SetConVarInt(FindConVar("z_ghost_delay_max"), RoundFloat(float(g_iDefSpawnTimeMax) * g_RC_fEventSITimeVeryEasy));
        }
        case DIFFICULTY_EASY: {
            SetConVarInt(FindConVar("z_ghost_delay_min"), RoundFloat(float(g_iDefSpawnTimeMin) * g_RC_fEventSITimeEasy));
            SetConVarInt(FindConVar("z_ghost_delay_max"), RoundFloat(float(g_iDefSpawnTimeMax) * g_RC_fEventSITimeEasy));
        }
        case DIFFICULTY_HARD: {
            SetConVarInt(FindConVar("z_ghost_delay_min"), RoundFloat(float(g_iDefSpawnTimeMin) * g_RC_fEventSITimeHard));
            SetConVarInt(FindConVar("z_ghost_delay_max"), RoundFloat(float(g_iDefSpawnTimeMax) * g_RC_fEventSITimeHard));
        }
        case DIFFICULTY_VERYHARD: {
            SetConVarInt(FindConVar("z_ghost_delay_min"), RoundFloat(float(g_iDefSpawnTimeMin) * g_RC_fEventSITimeVeryHard));
            SetConVarInt(FindConVar("z_ghost_delay_max"), RoundFloat(float(g_iDefSpawnTimeMax) * g_RC_fEventSITimeVeryHard));
        }
        
    }
    
    // difficulty change for commons
    switch (commonDiff)
    {
        // set common level to easy
        case DIFFICULTY_SUPEREASY: {
            SetConVarInt(FindConVar("z_common_limit"), RoundFloat(float(g_iDefCommonLimit) * g_RC_fEventCILimSuperEasy));
            SetConVarInt(FindConVar("z_background_limit"), RoundFloat(float(g_iDefBackgroundLimit) * g_RC_fEventCILimSuperEasy));
            SetConVarInt(FindConVar("z_mob_spawn_min_size"), RoundFloat(float(g_iDefHordeSizeMin) * g_RC_fEventCILimSuperEasy));
            SetConVarInt(FindConVar("z_mob_spawn_max_size"), RoundFloat(float(g_iDefHordeSizeMax) * g_RC_fEventCILimSuperEasy));
            SetConVarInt(FindConVar("z_mob_spawn_min_interval_normal"), RoundFloat(float(g_iDefHordeTimeMin) / g_RC_fEventCILimVeryEasy));
            SetConVarInt(FindConVar("z_mob_spawn_max_interval_normal"), RoundFloat(float(g_iDefHordeTimeMax) / g_RC_fEventCILimVeryEasy));
        }
        
        case DIFFICULTY_VERYEASY: {
            SetConVarInt(FindConVar("z_common_limit"), RoundFloat(float(g_iDefCommonLimit) * g_RC_fEventCILimVeryEasy));
            SetConVarInt(FindConVar("z_background_limit"), RoundFloat(float(g_iDefBackgroundLimit) * g_RC_fEventCILimVeryEasy));
            SetConVarInt(FindConVar("z_mob_spawn_min_size"), RoundFloat(float(g_iDefHordeSizeMin) * g_RC_fEventCILimVeryEasy));
            SetConVarInt(FindConVar("z_mob_spawn_max_size"), RoundFloat(float(g_iDefHordeSizeMax) * g_RC_fEventCILimVeryEasy));
            SetConVarInt(FindConVar("z_mob_spawn_min_interval_normal"), RoundFloat(float(g_iDefHordeTimeMin) / g_RC_fEventCILimEasy));
            SetConVarInt(FindConVar("z_mob_spawn_max_interval_normal"), RoundFloat(float(g_iDefHordeTimeMax) / g_RC_fEventCILimEasy));
        }
        
        case DIFFICULTY_EASY: {
            SetConVarInt(FindConVar("z_common_limit"), RoundFloat(float(g_iDefCommonLimit) * g_RC_fEventCILimEasy));
            SetConVarInt(FindConVar("z_background_limit"), RoundFloat(float(g_iDefBackgroundLimit) * g_RC_fEventCILimEasy));
            SetConVarInt(FindConVar("z_mob_spawn_min_size"), RoundFloat(float(g_iDefHordeSizeMin) * g_RC_fEventCILimEasy));
            SetConVarInt(FindConVar("z_mob_spawn_max_size"), RoundFloat(float(g_iDefHordeSizeMax) * g_RC_fEventCILimEasy));
        }
        case DIFFICULTY_HARD: {
            SetConVarInt(FindConVar("z_common_limit"), RoundFloat(float(g_iDefCommonLimit) * g_RC_fEventCILimHard));
            SetConVarInt(FindConVar("z_background_limit"), RoundFloat(float(g_iDefBackgroundLimit) * g_RC_fEventCILimHard));
            SetConVarInt(FindConVar("z_mob_spawn_min_size"), RoundFloat(float(g_iDefHordeSizeMin) * g_RC_fEventCILimHard));
            SetConVarInt(FindConVar("z_mob_spawn_max_size"), RoundFloat(float(g_iDefHordeSizeMax) * g_RC_fEventCILimHard));
            SetConVarInt(FindConVar("z_mob_spawn_max_interval_normal"), RoundFloat(float(g_iDefHordeTimeMax) / g_RC_fEventCILimHard));
        }
        
        case DIFFICULTY_VERYHARD: {
            SetConVarInt(FindConVar("z_common_limit"), RoundFloat(float(g_iDefCommonLimit) * g_RC_fEventCILimVeryHard));
            SetConVarInt(FindConVar("z_background_limit"), RoundFloat(float(g_iDefBackgroundLimit) * g_RC_fEventCILimVeryHard));
            SetConVarInt(FindConVar("z_mob_spawn_min_size"), RoundFloat(float(g_iDefHordeSizeMin) * g_RC_fEventCILimVeryHard));
            SetConVarInt(FindConVar("z_mob_spawn_max_size"), RoundFloat(float(g_iDefHordeSizeMax) * g_RC_fEventCILimVeryHard));
            SetConVarInt(FindConVar("z_mob_spawn_min_interval_normal"), RoundFloat(float(g_iDefHordeTimeMin) / g_RC_fEventCILimVeryHard));
            SetConVarInt(FindConVar("z_mob_spawn_max_interval_normal"), RoundFloat(float(g_iDefHordeTimeMax) / g_RC_fEventCILimVeryHard));
        }
    }
}

EVENT_RoundStartPreparation()
{
    // apply some settings for special events at round start
    
    g_bSpecialRoleAboutToChange = false;
    
    switch (g_iSpecialEvent)
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
            // start timer to autospawn witches (don't destroy on mapchange, it destroys itself as soon as it sees there is no witch event)
            if (g_hWitchSpawnTimer != INVALID_HANDLE)
            {
                CloseHandle(g_hWitchSpawnTimer);
            }
            g_hWitchSpawnTimer = CreateTimer(g_RC_fEventWitchesSpawnFreq, Timer_WitchSpawn, _, TIMER_REPEAT);
            
            // respawn timer too (only once, destroyed at mapchange)
            if (!g_bSecondHalf)
            {
                CreateTimer(MULTIWITCH_RESPAWN_FREQ, Timer_WitchRespawn, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
            }
        }
        
        case EVT_MEDIC: {
            // calculate and set medi-units available:
            new tmpUnits = (g_iDifficultyRating - EVENT_MEDIC_DIFF_BASE) + EVENT_MEDIC_UNITS_BASE;
            if (tmpUnits < EVENT_MEDIC_UNITS_MIN) { tmpUnits = EVENT_MEDIC_UNITS_MIN; }
            else if (tmpUnits < EVENT_MEDIC_UNITS_MAX) { tmpUnits = EVENT_MEDIC_UNITS_MAX; }
            
            g_iMedicUnits = tmpUnits;
            g_iMedicRanOut = 0;
            g_bMedicFirstHandout = false;
        }
        
        case EVT_BOOMFLU: {
            // start timer
            g_iBoomFluCounter = 0;
            g_hBoomFluTimer = CreateTimer( 1.0 , Timer_BoomFlu, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
        }
        
        case EVT_DOORCIRCUS: {
            // start timer to autospawn witches
            if (g_hDoorCircusTimer != INVALID_HANDLE)
            {
                CloseHandle(g_hDoorCircusTimer);
            }
            g_hDoorCircusTimer = CreateTimer(1.0, Timer_DoorCircus, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

EVENT_AllSurvivorsLoadedIn()
{
    // THIS IS NOT CALLED
    
    // called once, when all survivors are loaded in
    PrintDebug(3, "[rand] All survivors loaded in...");
    
    // (re)pick special event role
    if (g_bSpecialEventPlayerCheck)
    {
        EVENT_PickSpecialEventRole(-1, false);
    }
}

public Action: EVENT_SurvivorsLeftSaferoom(Handle:timer)
{
    PrintDebug(2, "[rand] Survivors left saferoom (doing special event business).");
    
    switch (g_iSpecialEvent)
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
            if (!EVENT_IsSpecialRoleOkay()) {
                EVENT_PickSpecialEventRole(-1, false);
            } else {
                ReportSpecialEventRole();
            }
        }
        
        case EVT_PROTECT: {
            // first time baby gets picked with a visible report
            if (!EVENT_IsSpecialRoleOkay()) {
                EVENT_PickSpecialEventRole(-1, false);
            } else {
                ReportSpecialEventRole();
            }
        }
        
        case EVT_MEDIC: {
            // first time medic gets picked with a visible report
            if (!EVENT_IsSpecialRoleOkay()) {
                EVENT_PickSpecialEventRole(-1, false);
            } else {
                ReportSpecialEventRole();
            }
        }
        
        case EVT_PEN_TIME: {
            // start timer
            g_iTimePenaltyCounter = 0;
            g_hTimePenaltyTimer = CreateTimer( 1.0 , Timer_TimePenalty, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
        }
        
        case EVT_BOOMFLU: {
            // timer is started earlier, so we get some sounds before
            // reset so we don't instantly vomit
            g_iBoomFluCounter = 0;
            
            if (!EVENT_IsSpecialRoleOkay()) {
                EVENT_PickSpecialEventRole(-1, false);
            } else {
                ReportSpecialEventRole();
            }
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


// whenever PBONUS changes
EVENT_PBonusChanged()
{
    // transfer current bonus to random bonus plugin, so it can display it
    RNDBNS_SetPenaltyBonus( PBONUS_GetRoundBonus() );
}
// only for penalties
EVENT_ReportPenalty(client = -1, extraInfo = -1)
{
    switch (g_iSpecialEvent)
    {
        case EVT_PEN_ITEM: {
            if (client != -1) {
                PrintToChatAll("\x01[\x05r\x01] Item pickup by %N cost \x04%i\x01 points.", client, g_RC_iEventPenaltyItem);
            } else {
                PrintToChatAll("\x01[\x05r\x01] Item pickup cost \x04%i\x01 points.", g_RC_iEventPenaltyItem);
            }
        }
        case EVT_PEN_HEALTH: {
            if (client != -1) {
                PrintToChatAll("\x01[\x05r\x01] Healing by %N cost \x04%i\x01 points.", client, g_RC_iEventPenaltyHealth);
            } else {
                PrintToChatAll("\x01[\x05r\x01] Healing cost \x04%i\x01 points.", g_RC_iEventPenaltyHealth);
            }
        }
        case EVT_PEN_M2: {
            new String: tmpStr[20] = "";
            if (extraInfo > 0) { Format(tmpStr, sizeof(tmpStr), "on %s ", g_csSIClassName[extraInfo]); }
            
            if (client != -1) {
                PrintToChatAll("\x01[\x05r\x01] Shove %sby %N cost \x04%i\x01 points.", tmpStr, client, g_RC_iEventPenaltyM2SI);
            } else {
                PrintToChatAll("\x01[\x05r\x01] Shove %scost \x04%i\x01 points.", tmpStr, g_RC_iEventPenaltyM2SI);
            }
        }
        case EVT_PEN_TIME: {
            PrintToChatAll("\x01[\x05r\x01] Minute \x05%d\x01 passed, \x04%i\x01 point penalty.", g_iBonusCount, g_RC_iEventPenaltyTime);
        }
    }
}

// this is also for bonus report
EVENT_DisplayRoundPenalty(client=-1)
{
    switch (g_iSpecialEvent)
    {
        case EVT_PEN_ITEM:
        {
            if (client != -1) {
                PrintToChat(client, "\x01[\x05r\x01] \x04Penalty\x01: \x05%i\x01 item pickup%s cost \x04%i\x01 points.", g_iBonusCount, (g_iBonusCount == 1) ? "" : "s", g_RC_iEventPenaltyItem * g_iBonusCount);
            } else {
                PrintToChatAll("\x01[\x05r\x01] \x04Penalty\x01: \x05%i\x01 item pickup%s cost \x04%i\x01 points.", g_iBonusCount, (g_iBonusCount == 1) ? "" : "s", g_RC_iEventPenaltyItem * g_iBonusCount);
            }
        }
        case EVT_PEN_HEALTH:
        {
            if (client != -1) {
                PrintToChat(client, "\x01[\x05r\x01] \x04Penalty\x01: \x05%i\x01 healing action%s cost \x04%i\x01 points.", g_iBonusCount, (g_iBonusCount == 1) ? "" : "s", g_RC_iEventPenaltyHealth * g_iBonusCount);
            } else {
                PrintToChatAll("\x01[\x05r\x01] \x04Penalty\x01: \x05%i\x01 healing action%s cost \x04%i\x01 points.", g_iBonusCount, (g_iBonusCount == 1) ? "" : "s", g_RC_iEventPenaltyHealth * g_iBonusCount);
            }
        }
        case EVT_PEN_M2:
        {
            if (client != -1) {
                PrintToChat(client, "\x01[\x05r\x01] \x04Penalty\x01: \x05%i\x01 m2%s cost \x04%i\x01 points.", g_iBonusCount, (g_iBonusCount == 1) ? "" : "s", g_RC_iEventPenaltyM2SI * g_iBonusCount);
            } else {
                PrintToChatAll("\x01[\x05r\x01] \x04Penalty\x01: \x05%i\x01 m2%s cost \x04%i\x01 points.", g_iBonusCount, (g_iBonusCount == 1) ? "" : "s", g_RC_iEventPenaltyM2SI * g_iBonusCount);
            }
        }
        
        case EVT_SKEET:
        {
            if (client != -1) {
                PrintToChat(client, "\x01[\x05r\x01] \x04Bonus\x01: \x05%i\x01 skeet%s gave \x04%i\x01 points bonus.", g_iBonusCount, (g_iBonusCount == 1) ? "" : "s", g_RC_iEventBonusSkeet * g_iBonusCount);
            } else {
                PrintToChatAll("\x01[\x05r\x01] \x04Bonus\x01: \x05%i\x01 skeet%s gave \x04%i\x01 points bonus.", g_iBonusCount, (g_iBonusCount == 1) ? "" : "s", g_RC_iEventBonusSkeet * g_iBonusCount);
            }
        }
        case EVT_PEN_TIME:
        {
            PrintToChatAll("\x01[\x05r\x01] \x04Penalty\x01: \x05%i\x01 minute%s cost \x04%i\x01 points so far.", g_iBonusCount, (g_iBonusCount == 1) ? "" : "s", g_RC_iEventPenaltyTime * g_iBonusCount);
        }
        case EVT_WITCHES:
        {
            if (client != -1) {
                PrintToChat(client, "\x01[\x05r\x01] \x04Bonus\x01: \x05%i\x01 witch kill%s gave \x04%i\x01 points bonus.", g_iBonusCount, (g_iBonusCount == 1) ? "" : "s", g_RC_iEventBonusWitch * g_iBonusCount);
            } else {
                PrintToChatAll("\x01[\x05r\x01] \x04Bonus\x01: \x05%i\x01 witch kill%s gave \x04%i\x01 points bonus.", g_iBonusCount, (g_iBonusCount == 1) ? "" : "s", g_RC_iEventBonusWitch * g_iBonusCount);
            }
        }
        case EVT_BADSANTA:
        {
            if (client != -1) {
                PrintToChat(client, "\x01[\x05r\x01] \x04Bonus\x01: \x05%i\x01 gift unwrap%s gave \x04%i\x01 points bonus.", g_iBonusCount, (g_iBonusCount == 1) ? "" : "s", g_RC_iEventBonusBadSanta * g_iBonusCount);
            } else {
                PrintToChatAll("\x01[\x05r\x01] \x04Bonus\x01: \x05%i\x01 gift unwrap%s gave \x04%i\x01 points bonus.", g_iBonusCount, (g_iBonusCount == 1) ? "" : "s", g_RC_iEventBonusBadSanta * g_iBonusCount);
            }
        }
    }
}




// penalty timer
public Action: Timer_TimePenalty(Handle:timer)
{
    // when paused, don't keep ticking
    if (g_bIsPaused || g_bIsTankInPlay || !g_bPlayersLeftStart) {
        return Plugin_Continue;
    }
    
    // halt timer on round end
    if (!g_bInRound || g_hTimePenaltyTimer == INVALID_HANDLE) {
        g_hTimePenaltyTimer = INVALID_HANDLE;
        return Plugin_Stop;
    }
    
    g_iTimePenaltyCounter++;
    
    if (g_iTimePenaltyCounter == 60)
    {
        g_iTimePenaltyCounter = 1;
        
        g_iBonusCount++;
        PBONUS_AddRoundBonus( -1 * g_RC_iEventPenaltyTime );
        EVENT_PBonusChanged();
        EVENT_ReportPenalty();
    }
    
    return Plugin_Continue;
}

// boomer flu timer
public Action: Timer_BoomFlu(Handle:timer)
{
    // when paused, don't keep ticking
    if (g_bIsPaused || g_iSpecialEventRole < 1) {
        return Plugin_Continue;
    }
    
    // halt timer on round end
    if (!g_bInRound || g_hBoomFluTimer == INVALID_HANDLE) {
        g_hBoomFluTimer = INVALID_HANDLE;
        return Plugin_Stop;
    }
    
    g_iBoomFluCounter++;
    
    if (g_iBoomFluCounter >= g_iBoomFluActivate)
    {
        g_iBoomFluActivate = GetRandomInt(g_RC_iEventBoomFluMinInt, g_RC_iEventBoomFluMaxInt);
        g_iBoomFluCounter = 1;
        
        // only boom after we really got going
        if (g_bPlayersLeftStart)
        {
            if (EVENT_IsSpecialRoleOkay(true))
            {
                PlayerDoVomit(g_iSpecialEventRole);
            }
        }
    }
    else if (g_iBoomFluCounter >= g_iBoomFluActivate - 4)
    {
        // you might get some burping sounds before
        new Float:location[3];
        GetClientEyePosition(g_iSpecialEventRole, location);
        location[2] -= 2;

        if (g_iBoomFluCounter == g_iBoomFluActivate - 1)
        {
            // imminent
            if (GetRandomInt(0, 4) > 0)
            {
                new pickSound = GetRandomInt(VOMIT_SOUND_FIRSTIMMINENT, sizeof(g_csPreVomitSounds) - 1);
                EmitSoundToAll( g_csPreVomitSounds[ pickSound ] , 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, location, NULL_VECTOR, false, 0.0);
            }
        } else {
            if (GetRandomInt(0, 3) == 0)
            {
                new pickSound = GetRandomInt(0, VOMIT_SOUND_FIRSTIMMINENT - 1);
                EmitSoundToAll( g_csPreVomitSounds[ pickSound ] , 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, location, NULL_VECTOR, false, 0.0);
            }
        }
    }
    else if (g_iBoomFluCounter == 6)
    {
        if (GetRandomInt(0, 2) == 0) {
            Vocalize_Random(g_iSpecialEventRole, "Sorry");
        }
    }
    else if (g_iBoomFluCounter > 10)
    {
        // cough every once in a while
        if (GetRandomInt(0, 9) == 0) {
            Vocalize_Random(g_iSpecialEventRole, "Cough");
        }
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


EVENT_HandleSkeet(skeeter=-1, victim=-1, meleeSkeet=false)
{
    if (g_iSpecialEvent == EVT_SKEET)
    {
        g_iBonusCount++;
        if (skeeter == -2) {
            PBONUS_AddRoundBonus( g_RC_iEventBonusSkeetTeam );
        } else {
            PBONUS_AddRoundBonus( g_RC_iEventBonusSkeet );
        }
        EVENT_PBonusChanged();
        
        if (skeeter == -2) {    // team skeet sets to -2
            if (IsClientAndInGame(victim)) {
                PrintToChatAll("\x01[\x05r\x01] %N was team-skeeted for \x04%i\x01 points.", victim, g_RC_iEventBonusSkeetTeam);
            } else {
                PrintToChatAll("\x01[\x05r\x01] A hunter was team-skeeted for \x04%i\x01 points.", g_RC_iEventBonusSkeetTeam);
            }
        }
        else if (IsClientAndInGame(skeeter) && IsClientAndInGame(victim)) {
            PrintToChatAll("\x01[\x05r\x01] %N %sskeeted %N for \x04%i\x01 points.", skeeter, (meleeSkeet)?"melee-":"", victim, g_RC_iEventBonusSkeet);
        }
        else if (IsClientAndInGame(skeeter)) {
            PrintToChatAll("\x01[\x05r\x01] %N %sskeeted a hunter for \x04%i\x01 points.", skeeter, (meleeSkeet)?"melee-":"", g_RC_iEventBonusSkeet);
        }
        else if (IsClientAndInGame(victim)) {
            PrintToChatAll("\x01[\x05r\x01] %N was %sskeeted for \x04%i\x01 points.", victim, (meleeSkeet)?"melee-":"", g_RC_iEventBonusSkeet);
        }
        else {
            PrintToChatAll("\x01[\x05r\x01] A hunter was %sskeeted for \x04%i\x01 points.", (meleeSkeet)?"melee-":"", g_RC_iEventBonusSkeet);
        }
    }
    else
    {
        // only report
        if (skeeter == -2) {    // team skeet sets to -2
            if (IsClientAndInGame(victim)) {
                PrintToChatAll("\x01[\x05r\x01] %N was team-skeeted.", victim);
            } else {
                PrintToChatAll("\x01[\x05r\x01] A hunter was team-skeeted.");
            }
        }
        else if (IsClientAndInGame(skeeter) && IsClientAndInGame(victim)) {
            PrintToChatAll("\x01[\x05r\x01] %N %sskeeted %N.", skeeter, (meleeSkeet)?"melee-":"", victim);
        }
        else if (IsClientAndInGame(skeeter)) {
            PrintToChatAll("\x01[\x05r\x01] %N %sskeeted a hunter.", skeeter, (meleeSkeet)?"melee-":"");
        }
        /*
        else if (IsClientAndInGame(victim)) {
            PrintToChatAll("\x01[\x05r\x01] %N was %sskeeted.", victim, (meleeSkeet)?"melee-":"");
        }
        else {
            PrintToChatAll("\x01[\x05r\x01] A hunter was %sskeeted.", (meleeSkeet)?"melee-":"");
        }
        */
    }
}
EVENT_HandleNonSkeet(victim, damage)
{
    //if (g_iSpecialEvent == EVT_SKEET)
    //{
        if (IsClientAndInGame(victim)) {
            PrintToChatAll("\x01[\x05r\x01] %N was \x04not\x01 skeeted (\x03%i\x01 damage).", victim, damage);
        }
        else {
            PrintToChatAll("\x01[\x05r\x01] Hunter was \x04not\x01 skeeted (\x03%i\x01 damage).", damage);
        }
    //}
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
    
    
    // block T2s in startup
    new bool: bT2 = true;
    if (!g_bPlayersLeftStart || SUPPORT_IsInReady()) { bT2 = false; }
    
    // also block t2s more if they're not supposed to spawn normally
    if (GetConVarInt(g_hArCvarWeight[INDEX_T2RIFLE]) == 0 || GetConVarInt(g_hArCvarWeight[INDEX_T2SHOTGUN]) == 0) {
        if (GetRandomInt(0,2)) { bT2 = false; }
    }
    
    // pick new weapon (random)
    new ammo = 0;
    new ammoOffset = -1;
    new String:weaponname[STR_MAX_ITEMGIVEN] = "";
    
    new randomPick = GetRandomInt(0, (bT2) ? 7 : 3);            // disabled t3 for now
    
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
    

    // check here for other events (whether bots have stuff they shouldn't have)
    if (g_iSpecialEvent == EVT_AMMO)
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
    else        // for every other special event role
    {
        // are there any humans in the survivor team?
        new bool: bNoHumanSurvivors = true;
        for (new i=1; i <= MaxClients; i++) {
            if (IsSurvivor(i) && !IsFakeClient(i) && IsPlayerAlive(i)) { 
                bNoHumanSurvivors = false;
                break;
            }
        }
        
        // force new role if the current role's survivor is missing, dead or a bot when there's humans available:
        if ( !IsSurvivor(g_iSpecialEventRole) || !IsPlayerAlive(g_iSpecialEventRole) || ( IsFakeClient(g_iSpecialEventRole) && !bNoHumanSurvivors ) ) {
            g_iSpecialEventRole = 0;
        }
        
        if (!g_iSpecialEventRole)
        {
            EVENT_PickSpecialEventRole( -1, (leftStart) ? false : true);
        }
    }
}

EVENT_PickSpecialEventRole(notClient=-1, bool:notLeftStart=false)
{
    // remove hats
    HatsRemoveAll();
    
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
    
    // give correct hat to picked survivor
    switch (g_iSpecialEvent)
    {
        case EVT_PROTECT: { CreateHat(g_iSpecialEventRole, HAT_BABY); }
        case EVT_KEYMASTER: { CreateHat(g_iSpecialEventRole, HAT_KEYMASTER); }
        case EVT_MEDIC: { CreateHat(g_iSpecialEventRole, HAT_MEDIC); }
        case EVT_BOOMFLU: { CreateHat(g_iSpecialEventRole, HAT_BOOMFLU); }
    }
    
    
    // when picked, do a medic check
    if (g_iSpecialEvent == EVT_MEDIC)
    {
        EVENT_CheckMedic(true);
    }
    
    // report if it's after the saferoom exit (notLeftStart is for timer calls)
    if (!notLeftStart && g_bPlayersLeftStart) {
        ReportSpecialEventRole();
    }
}

bool: EVENT_IsSpecialRoleOkay(bool:allowBots=false)
{
    // check if a living survivor has the special role
    if (g_iSpecialEventRole < 1) { return false; }
    if (    !IsClientAndInGame(g_iSpecialEventRole)
        ||  !IsSurvivor(g_iSpecialEventRole)
        ||  !IsPlayerAlive(g_iSpecialEventRole)
        ||  ( !allowBots && IsFakeClient(g_iSpecialEventRole) )
    ) { return false; }
    
    return true;
}



// medic event
public Action: EVENT_TimerCheckMedic(Handle:timer)
{
    EVENT_CheckMedic();
}

EVENT_CheckMedic(bool:roleSwitch=false)
{
    // see if the medic has the items he needs
    if (!EVENT_IsSpecialRoleOkay(true)) { return; }
    
    // if anyone has kits/pills they shouldn't have, remove them
    for (new i=1; i <= MaxClients; i++)
    {
        if (i == g_iSpecialEventRole) { continue; }
        
        if (IsSurvivor(i) && IsPlayerAlive(i))
        {
            new tmpKit = GetPlayerWeaponSlot(i, PLAYER_SLOT_KIT);
            if (IsValidEntity(tmpKit)) { RemovePlayerItem(i, tmpKit); g_iMedicUnits += 2; }
            
            if (!g_bMedicFirstHandout) {
                // only remove pills if medic hasn't started handing stuff out yet
                new tmpPill = GetPlayerWeaponSlot(i, PLAYER_SLOT_PILL);
                if (IsValidEntity(tmpPill)) { RemovePlayerItem(i, tmpPill); g_iMedicUnits++; }
            }
        }
    }
    
    // if the medic has anything in slot kit/pill, it's always ok
    new slotKit = GetPlayerWeaponSlot(g_iSpecialEventRole, PLAYER_SLOT_KIT);
    new slotPill = GetPlayerWeaponSlot(g_iSpecialEventRole, PLAYER_SLOT_PILL);
    
    if ( g_iMedicUnits < 1 && (!IsValidEntity(slotKit) || !IsValidEntity(slotPill)) && g_iMedicRanOut < 2 )
    {
        g_iMedicRanOut = 2;
        PrintToChat(g_iSpecialEventRole, "\x01[\x05r\x01] You have run out of medical supplies.");
        return;
    }
    
    if (!IsValidEntity(slotKit)) {
        // give kit if units
        if (g_iMedicUnits > 1) {
            g_iMedicUnits -= 2;
            GiveItem(g_iSpecialEventRole, "weapon_first_aid_kit", 0, 0);
            
            // only report if not due to roleswitch
            if (!roleSwitch) {
                if (g_iMedicUnits) {
                    PrintToChat(g_iSpecialEventRole, "\x01[\x05r\x01] Replaced medkit. \x03%i\x01 medi-unit%s left.", g_iMedicUnits, (g_iMedicUnits == 1) ? "" : "s");
                } else {
                    PrintToChat(g_iSpecialEventRole, "\x01[\x05r\x01] Replaced medkit. You have no medical supplies left.", g_iMedicUnits);
                }
            }
        } else {
            if (g_iMedicRanOut < 1) {
                g_iMedicRanOut = 1;
                PrintToChat(g_iSpecialEventRole, "\x01[\x05r\x01] Not enough medi-units left for new medkit.");
            }
        }
    }
    
    if (!IsValidEntity(slotPill)) {
        // give pills if units
        if (g_iMedicUnits > 0) {
            g_iMedicUnits--;
            GiveItem(g_iSpecialEventRole, "weapon_pain_pills", 0, 0);
            
            // only report if not due to roleswitch
            if (!roleSwitch) {
                if (g_iMedicUnits) {
                    PrintToChat(g_iSpecialEventRole, "\x01[\x05r\x01] Replaced pills. \x03%i\x01 medi-unit%s left.", g_iMedicUnits, (g_iMedicUnits == 1) ? "" : "s");
                } else {
                    PrintToChat(g_iSpecialEventRole, "\x01[\x05r\x01] Replaced pills. You have no medical supplies left.", g_iMedicUnits);
                }
            }
        }
    }
}

public Action: Timer_DestroyHealthItems(Handle:timer)
{
    // find any health items not carried by anyone and destroy them
    // currently: just look for kits
    
    new itemDropType: classnameHealth;    
    new String:classname[64];
    new entityCount = GetEntityCount();
    
    for (new i=0; i < entityCount; i++)
    {
        if (IsValidEntity(i))
        {
            GetEdictClassname(i, classname, sizeof(classname));
            if (!GetTrieValue(g_hTrieDropItems, classname, classnameHealth)) { continue; }
            if (classnameHealth != ITEM_DROP_WEAPKIT) { continue; }
            
            // is anyone holding it?
            new bool: bHeld = false;
            for (new j=1; j <= MaxClients; j++) {
                if (IsSurvivor(j) && IsPlayerAlive(j)) {
                    new tmpKit = GetPlayerWeaponSlot(j, PLAYER_SLOT_KIT);
                    if (tmpKit == i) { bHeld = true; break; }
                }
            }
            if (bHeld) { continue; }
            
            // it's a health item we don't want: destroy it
            AcceptEntityInput(i, "Kill");
        }
    }
}


// Stabby's multi-witch stuff
// ===========================================================================

SUPPORT_MultiWitchRandomization()
{
    // how many witches (attempt to spawn, not guaranteed)
    g_iWitchNum = GetRandomInt(g_RC_iMultiwitchMin, g_RC_iMultiwitchMax);
    
    PrintDebug(1, "[rand] Multi-witch: trying to set %i witches... ", g_iWitchNum);
    
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
            
            PrintDebug(2, "[rand] Multi-witch near tank spawn, blocked: %.2f near %.2f (next one possible at %.2f)", tmpSpot, L4D2Direct_GetVSTankFlowPercent( (g_bSecondHalf) ? 1 : 0 ), flowMin );
            
            if (g_iWitchNum - index - 1 > 0 ) {
                flowSection = (MULTIWITCH_FLOW_MAX - flowMin) / (g_iWitchNum - index - 1);
            }
            continue;
        }
        
        // store in array
        g_fArWitchFlows[index] = tmpSpot;
        g_bArWitchSitting[index] = (GetRandomInt(0,4) == 0) ? false : true;
        
        PrintDebug(2, "[rand] Multi-witch [%i] to spawn at: %f (%s)", index, g_fArWitchFlows[index], (g_bArWitchSitting[index]) ? "sitting" : "walking");
        
        index++;
        flowMin = tmpSpot + MULTIWITCH_FLOW_BETWEEN;
    }
    
    g_iWitchNum = index;    // set to actual number set to spawn
}

SUPPORT_MultiWitchRoundPrep()
{
    //PrintDebug(2, "[rand] Multi-witch round prep [%i]...", g_bMultiWitch);
    g_iWitchIndex = 0;
    
    // prepare multi-witch for round
    if (g_bMultiWitch)
    {
        PrintDebug(2, "[rand] Multi-witch: setting first spawn (%.2f)", g_fArWitchFlows[0]);
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
    if (g_iSpecialEvent == EVT_MINITANKS)
    {
        if (g_iMiniTankIndex == g_iMiniTankNum - 1) {
            return;
        }
        
        PrintDebug(3, "[rand] preparing next tank (%i)...", g_iMiniTankIndex+1);
        
        L4D2Direct_SetVSTankToSpawnThisRound(0, true);
        L4D2Direct_SetVSTankToSpawnThisRound(1, true);
        L4D2Direct_SetVSTankFlowPercent(0, g_fArMiniTankFlows[g_iMiniTankIndex]);
        L4D2Direct_SetVSTankFlowPercent(1, g_fArMiniTankFlows[g_iMiniTankIndex]);
        
        g_iMiniTankIndex++;
    }
    else        // 'normal' doubletank
    {
        PrintDebug(3, "[rand] preparing second tank...");
        
        L4D2Direct_SetVSTankToSpawnThisRound(0, true);
        L4D2Direct_SetVSTankToSpawnThisRound(1, true);
        L4D2Direct_SetVSTankFlowPercent(0, g_fTankFlowLate);
        L4D2Direct_SetVSTankFlowPercent(1, g_fTankFlowLate);
        
        g_bSecondTankSet = true;
    }
}

SUPPORT_MultiTankRandomization()
{
    // how many tanks
    g_iMiniTankNum = g_RC_iMinitanksNum;
    
    PrintDebug(1, "[rand] Multi-tank: trying to set %i tanks... ", g_iMiniTankNum);
    
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
        
        PrintDebug(2, "[rand] Multi/mini-tank [%i] to spawn at: %f", index, g_fArMiniTankFlows[index]);
        
        index++;
    }
    
    g_iMiniTankNum = index;    // set to actual number set to spawn
}

SUPPORT_MultiTankRoundPrep()
{
    //PrintDebug("[rand] Multi-witch round prep [%i]...", g_bMultiWitch);
    g_iMiniTankIndex = 0;
    
    // prepare multi-witch for round
    if (g_iSpecialEvent == EVT_MINITANKS)
    {
        PrintDebug(2, "[rand] Multi-tank: setting first spawn (%.2f)", g_fArMiniTankFlows[0]);
        
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
            } else if (StrEqual(classname, "weapon_sniper_scout", false)) {
                // scout's lighter
                fWeight += EVENT_ENC_W_T1;
            } else if (itemHasPenalty == ITEM_PICKUP_PENALTY_PRIMARY_SNIPER) {
                fWeight += EVENT_ENC_W_SNIPER;
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
        if (    g_strArStorage[i][entPickedType] == PCK_NOITEM
            ||  g_strArStorage[i][entPickedType] == PCK_JUNK
            ||  g_strArStorage[i][entPickedType] == PCK_EXPLOSIVE_BARREL
            ||  g_strArStorage[i][entPickedType] == PCK_SILLY_GIFT
            ||  g_strArStorage[i][entPickedType] == PCK_SILLY_GNOME
            ||  g_strArStorage[i][entPickedType] == PCK_SILLY_COLA
        ) { continue; }
        
        if (GetRandomFloat(0.001,1.0) <= g_RC_fEventBoobyTrapChance)
        {
            g_iArBoobyTrap[g_iBoobyTraps] = g_strArStorage[i][entNumber];
            g_iBoobyTraps++;
        }
    }
    
    // if we picked 0, go and add a few
    if (g_iBoobyTraps < g_RC_iEventBoobyTrapMin)
    {
        for (new j=0; j < 1000; j++)
        {
            // try to add one until we've got enough:
            if (g_iBoobyTraps >= g_RC_iEventBoobyTrapMin) { break; }
            
            new i = GetRandomInt(0, g_iStoredEntities - 1);
            
            if (g_strArStorage[i][entInStartSaferoom]) { continue; }
            if (    g_strArStorage[i][entPickedType] == PCK_NOITEM
                ||  g_strArStorage[i][entPickedType] == PCK_JUNK
                ||  g_strArStorage[i][entPickedType] == PCK_EXPLOSIVE_BARREL
                ||  g_strArStorage[i][entPickedType] == PCK_SILLY_GIFT
                ||  g_strArStorage[i][entPickedType] == PCK_SILLY_GNOME
                ||  g_strArStorage[i][entPickedType] == PCK_SILLY_COLA
            ) { continue; }
            
            g_iArBoobyTrap[g_iBoobyTraps] = g_strArStorage[i][entNumber];
            g_iBoobyTraps++;
        }
    }
    
    PrintDebug(1, "[rand] Rigged %i booby traps for special event.", g_iBoobyTraps);
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
    
    CreateExplosion(location, (GetRandomInt(0, 4) == 0) ? g_RC_fExplosionPowerHigh : g_RC_fExplosionPowerLow);
    
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
    
    //PrintToChatAll("AMMO location: %.f %.f %.f", targetPos[0], targetPos[1], targetPos[2]);
    
    new Float:distance = GetVectorDistance(g_fAmmoDeploySpot, targetPos);
    if (distance > AMMO_FIX_RANGE)
    {
        targetPos = g_fAmmoDeploySpot;
        PrintDebug(3, "[rand] Incorrect ammo spawn location. Positioning ammo at player's feet. (Distance: %.f)", distance);
    }
    
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
                    
                    //PrintDebug(3, "[rand] prop_dynamic: ent: %i; hamid: %i; name: %s", i, GetEntProp(i, Prop_Data, "m_iHammerID"), name);
                    
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

/*  Support functions, general
    -------------------------- */

public PrintDebug(debugLevel, const String:Message[], any:...)
{
    if (debugLevel <= GetConVarInt(g_hCvarDebug))
    {
        decl String:DebugBuff[256];
        VFormat(DebugBuff, sizeof(DebugBuff), Message, 3);
        LogMessage(DebugBuff);
        //PrintToServer(DebugBuff);
        //PrintToChatAll(DebugBuff);
    }
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





// hide/show survivor weapon
/* HideWeapon(client)
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
    switch (weapId)
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
    // use native if crox's plugin is loaded
    
    // check if we've readyup loaded (here because now all plugins are loaded)
    if (g_hCvarReadyUp == INVALID_HANDLE || !GetConVarBool(g_hCvarReadyUp)) { return false; }
    
    if (g_bReadyUpAvailable) {
        // use native
        return IsInReady();
    }
    else {
        // use trick:
        // find a survivor
        new client = GetAnySurvivor();
        if (client == 0) { return false; }
        
        // if he's frozen, assume it's readyup time
        return bool: (GetEntityMoveType(client) == MOVETYPE_NONE);
    }
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
    for (new i=1; i <= GetMaxClients(); i++)
    {
        if (IsClientConnected(i) && IsSurvivor(i) && !IsFakeClient(i)) { return i; }
    }
    
    if (onlySurvivors) { return 0; }
    
    // since we're just using this for spawning stuff that requires a client, use infected alternatively
    for (new i=1; i <= GetMaxClients(); i++)
    {
        if (IsClientConnected(i) && IsInfected(i) && !IsFakeClient(i)) { return i; }
    }
    
    // no usable clients...
    return 0;
}

// just for checking rup at the moment
GetAnySurvivor()
{
    for (new i=1; i <= GetMaxClients(); i++) {
        if (IsClientConnected(i) && IsSurvivor(i)) { return i; }
    }
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

/* tankrush blocking */
SUPPORT_FreezePoints( bool:bShowMessage = false ) {
    if ( !g_bFrozenPoints ) {
        g_iRememberFrozenDistance = L4D_GetVersusMaxCompletionScore();
        if ( bShowMessage ) PrintToChatAll("\x01[\x05r\x01] \x04Freezing\x01 distance points until tank is killed.");
        L4D_SetVersusMaxCompletionScore(0);
        g_bFrozenPoints = true;
    }
}

SUPPORT_UnFreezePoints( bool:bShowMessage = false ) {
    if ( g_bFrozenPoints ) {
        if ( bShowMessage ) PrintToChatAll("\x01[\x05r\x01] \x04Unfreezing\x01 distance points.");
        L4D_SetVersusMaxCompletionScore(g_iRememberFrozenDistance);
        g_bFrozenPoints = false;
    }
}

/* GetTankClient()
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


/* bool: IsCommon(entity)
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

CountHumanSurvivors()
{
    new count = 0;
    for (new client = 1; client <= MaxClients; client++)
    {
        if (IsSurvivor(client) && !IsFakeClient(client)) { count++; }
    }
    return count;
}
// give an item to a player
GiveItem(client, String:item[STR_MAX_ITEMGIVEN], ammo, iOffset)
{
    // new approach
    decl entity;
    decl Float:clientOrigin[3];

    entity = CreateEntityByName(item);
    
    if (!IsValidEntity(entity)) {
        PrintDebug(0, "[rand] error: no valid entity for spawning: %s", item);
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
        PrintDebug(0, "[rand] error: no valid entity for spawning: %s", item);
        return;
    }
    
    GetClientAbsOrigin(client, clientOrigin);
    TeleportEntity(entity, clientOrigin, NULL_VECTOR, NULL_VECTOR);
    DispatchKeyValue(entity, "melee_script_name", item);
    
    DispatchSpawn(entity);
    EquipPlayerWeapon(client, entity);
}





// check ammo for too much/too little (call after player receives (full) ammo)
SUPPORT_CheckAmmo(client)
{
    new weapon = GetPlayerWeaponSlot(client, PLAYER_SLOT_PRIMARY);
    if (weapon != -1 && IsValidEntity(weapon))
    {
        // which is it?
        new String: classname[64];
        GetEdictClassname(weapon, classname, sizeof(classname));
        
        new iProperAmmo = -1;
        new iOffset = -1;
        new iAmmoOffset = FindDataMapOffs(client, "m_iAmmo");
        
        if (StrEqual("weapon_rifle_ak47", classname, false)) {
            new iClipAmmo = 40 - GetEntProp(weapon, Prop_Send, "m_iClip1");
            iProperAmmo = g_iActiveAmmoAk + iClipAmmo;
            iOffset = ASSAULT_RIFLE_OFFSET_IAMMO;
        }
        else if (StrEqual("weapon_sniper_scout", classname, false)) {
            new iClipAmmo = 15 - GetEntProp(weapon, Prop_Send, "m_iClip1");
            iProperAmmo = g_iActiveAmmoScout + iClipAmmo;
            iOffset = MILITARY_SNIPER_OFFSET_IAMMO;
        }
        else if (StrEqual("weapon_sniper_awp", classname, false)) {
            new iClipAmmo = 20 - GetEntProp(weapon, Prop_Send, "m_iClip1");
            iProperAmmo = g_iActiveAmmoAWP + iClipAmmo;
            iOffset = MILITARY_SNIPER_OFFSET_IAMMO;
        }
        
        if (iProperAmmo != -1)
        {
            new ammo = GetEntData(client, (iAmmoOffset + iOffset));
            if (ammo != iProperAmmo) {
                SetEntData(client, (iAmmoOffset + iOffset), iProperAmmo);
            }
        }
    }
}

// spawning a zombie (cheap way :()
SpawnCommon(client, mobs = 1)
{
    if (GetConVarBool(g_hCvarUseOldSpawn))
    {
        new flags = GetCommandFlags("z_spawn_old");
        SetCommandFlags("z_spawn_old", flags & ~FCVAR_CHEAT);
        for(new i=0; i < mobs; i++) {
            FakeClientCommand(client, "z_spawn_old infected auto");
        }
        SetCommandFlags("z_spawn_old", flags);
    }
    else
    {
        new flags = GetCommandFlags("z_spawn");
        SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);
        for(new i=0; i < mobs; i++) {
            FakeClientCommand(client, "z_spawn infected auto");
        }
        SetCommandFlags("z_spawn", flags);
    }
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
    if (GetConVarBool(g_hCvarUseOldSpawn))
    {
        new flags = GetCommandFlags("z_spawn_old");
        SetCommandFlags("z_spawn_old", flags & ~FCVAR_CHEAT);
        for(new i=0; i < mobs; i++) {
            FakeClientCommand(client, "z_spawn_old mob auto");
        }
        SetCommandFlags("z_spawn_old", flags);
    }
    else
    {
        new flags = GetCommandFlags("z_spawn");
        SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);
        for(new i=0; i < mobs; i++) {
            FakeClientCommand(client, "z_spawn mob auto");
        }
        SetCommandFlags("z_spawn", flags);
    }
}


// get an entity's distance from the floor
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
    
    // look from up higher, by a bit
    pos[2] += 10.0;
    
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
        fDif = pos[2] - fNewZ - 10.0;
    }
    return fDif;
}

// trace filter: no self
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
    new playerCount = 0;
    
    for (new i=1; i < MaxClients+1; i++)
    {
        if ( IsInfected(i) && !IsFakeClient(i) )
        {
            playerCount++;
            
            // if the player had the previous tank, exclude him from the next pick
            if ( g_iPreviousTankClient[ GameRules_GetProp("m_bAreTeamsFlipped", 4, 0) ] == i ) {
                PrintDebug(3, "[rand tank] Prevented tank pick for %N (had previous tank).", i);
                continue;
            }
            
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
    
    // safeguard, if there's only one player, allow them the pick
    if ( playerCount && !pickCount ) {
        for (new i=1; i < MaxClients+1; i++)
        {
            if ( IsInfected(i) && !IsFakeClient(i) )
            {
                pickArray[pickCount] = i;
                pickCount++;
            }
        }
    }
    
    
    pick = GetRandomInt(0, pickCount - 1);
    pick = pickArray[pick];
    
    PrintDebug(3, "[rand tank] Randomly picking tank player %i (%N) (had %i tanks before).", pick, pick, g_iHadTanks[pick]);
    
    if ( IsClientAndInGame(pick) && !IsFakeClient(pick) ) {
        g_iPreviousTankClient[ GameRules_GetProp("m_bAreTeamsFlipped", 4, 0) ] = pick;
    } else {
        g_iPreviousTankClient[ GameRules_GetProp("m_bAreTeamsFlipped", 4, 0) ] = 0;
    }
    
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



/*  Weapon nerfing 
    -------------- */
bool: SUPPORT_IsNerfSecondary(entity, client, tierType)
{
    if (!entity || !IsValidEntity(entity) || !IsValidEdict(entity)) { return false; }
    
    decl String:wclass[64];
    if (!GetEdictClassname(entity, wclass, sizeof(wclass))) { return false; }

    // if it's a weapon spawn
    if (StrEqual(wclass, "weapon_spawn")) {
        new wepid = GetEntProp(entity, Prop_Send, "m_weaponID");
        switch (wepid)
        {
            case WEPID_PISTOL: {
                // if client already carries one, yes
                if (tierType == NERFTYPE_T2) {
                    return SUPPORT_PlayerHasPistol(client);
                } else {
                    return false;
                }
            }
            case WEPID_PISTOL_MAGNUM, WEPID_CHAINSAW, WEPID_MELEE: {
                return true;
            }
        }
        
        return false;
    }

    // if it's a normal weapon
    new itemPickupPenalty: itemWepType;
    if (GetTrieValue(g_hTriePenaltyItems, wclass, itemWepType))
    {
        switch (itemWepType)
        {
            case ITEM_PICKUP_PENALTY_PISTOL: {
                if (tierType == NERFTYPE_T2) {
                    // if client already carries one, yes
                    return SUPPORT_PlayerHasPistol(client);
                } else {
                    return false;
                }
            }
            case ITEM_PICKUP_PENALTY_SAW, ITEM_PICKUP_PENALTY_MAGNUM, ITEM_PICKUP_PENALTY_MELEE: {
                return true;
            }
        }
    }
    
    return false;
}

// returns 1 for sniper t2/t1.5; 2 for t2
SUPPORT_IsNerfTier2(entity)
{
    // consider adding snipers to this check?
    
    if (!entity || !IsValidEntity(entity) || !IsValidEdict(entity)) { return 0; }
    
    decl String:wclass[64];
    if (!GetEdictClassname(entity, wclass, sizeof(wclass))) { return 0; }

    // if it's a weapon spawn
    if (StrEqual(wclass, "weapon_spawn")) {
        new wepid = GetEntProp(entity, Prop_Send, "m_weaponID");
        switch (wepid)
        {
            case WEPID_AUTOSHOTGUN, WEPID_SHOTGUN_SPAS, WEPID_RIFLE, WEPID_RIFLE_AK47, WEPID_RIFLE_DESERT, WEPID_RIFLE_SG552: {
                return NERFTYPE_T2;
            }
            case WEPID_HUNTING_RIFLE, WEPID_SNIPER_MILITARY, WEPID_SNIPER_AWP: {
                return NERFTYPE_SNIPER;
            }
        }
        
        return 0;
    }

    // if it's a normal weapon
    new itemPickupPenalty: itemWepType;
    if (GetTrieValue(g_hTriePenaltyItems, wclass, itemWepType))
    {
        if ( itemWepType == ITEM_PICKUP_PENALTY_PRIMARY_T2 ) { return NERFTYPE_T2; }
        if ( itemWepType == ITEM_PICKUP_PENALTY_PRIMARY_SNIPER && !StrEqual(wclass, "weapon_sniper_scout", false) ) { return NERFTYPE_SNIPER; }
    }
    
    return 0;
}

bool: SUPPORT_PlayerHasPistol(client)
{
    if (!IsSurvivor(client) || !IsPlayerAlive(client)) { return false; }
    
    new slotSec = GetPlayerWeaponSlot(client, PLAYER_SLOT_SECONDARY);
    if (slotSec < 1 || !IsValidEntity(slotSec)) { return false; }
    
    decl String:classname[64];
    GetEdictClassname(slotSec, classname, sizeof(classname));
    new itemPickupPenalty: itemIsPistol;
    if (GetTrieValue(g_hTriePenaltyItems, classname, itemIsPistol))
    {
        if (itemIsPistol == ITEM_PICKUP_PENALTY_PISTOL) { return true; }
    }
    
    return false;
}
bool: SUPPORT_EntityIsPistol(entity)
{
    if (!entity || !IsValidEntity(entity)) { return false; }
    
    decl String:classname[32];
    GetEdictClassname(entity, classname, sizeof(classname));
    
    new itemPickupPenalty: itemIsPistol;
    if (GetTrieValue(g_hTriePenaltyItems, classname, itemIsPistol))
    {
        if (itemIsPistol == ITEM_PICKUP_PENALTY_PISTOL) { return true; }
    }
    
    return false;
}

// returns 1 for sniper t2/t1.5; 2 for t2
SUPPORT_PlayerHasT2(client)
{
    if (!IsSurvivor(client) || !IsPlayerAlive(client)) { return 0; }
    
    new slotPri = GetPlayerWeaponSlot(client, PLAYER_SLOT_PRIMARY);
    if (slotPri < 1 || !IsValidEntity(slotPri)) { return 0; }
    
    decl String:classname[64];
    GetEdictClassname(slotPri, classname, sizeof(classname));
    new itemPickupPenalty: itemIsT2;
    if (GetTrieValue(g_hTriePenaltyItems, classname, itemIsT2))
    {
        if ( itemIsT2 == ITEM_PICKUP_PENALTY_PRIMARY_T2 ) { return NERFTYPE_T2; }
        if ( itemIsT2 == ITEM_PICKUP_PENALTY_PRIMARY_SNIPER && !StrEqual(classname, "weapon_sniper_scout", false) ) { return NERFTYPE_SNIPER; }
    }
    
    return 0;
}

SUPPORT_FixNerfTier2(client, tierType)
{
    // called when a player picks up a T2
    
    new slotSec = GetPlayerWeaponSlot(client, PLAYER_SLOT_SECONDARY);
    new bool: bDropped = false;
    
    if (IsValidEntity(slotSec))
    {
        decl String:classname[64];
        GetEdictClassname(slotSec, classname, sizeof(classname));
        new itemPickupPenalty: itemHasPenalty;
        if (GetTrieValue(g_hTriePenaltyItems, classname, itemHasPenalty))
        {
            switch (itemHasPenalty)
            {
                case ITEM_PICKUP_PENALTY_PISTOL: {
                    if (GetEntProp(slotSec, Prop_Send, "m_hasDualWeapons") && tierType == NERFTYPE_T2) {
                        // dual wielding. drop one pistol
                        bDropped = SUPPORT_DropItemSlot(client, PLAYER_SLOT_SECONDARY);
                    }
                }
                case ITEM_PICKUP_PENALTY_MAGNUM, ITEM_PICKUP_PENALTY_MELEE, ITEM_PICKUP_PENALTY_SAW: {
                    // drop it
                    bDropped = SUPPORT_DropItemSlot(client, PLAYER_SLOT_SECONDARY);
                }
            }
        }
    }
    
    if (bDropped)
    {
        // report
        if (tierType == NERFTYPE_T2)
        {
            PrintToChat(client, "\x01[\x05r\x01] Only single pistol allowed with \x04T2\x01 rifle/shotgun. Dropped secondary.");
        }
        else {
            PrintToChat(client, "\x01[\x05r\x01] Only single or dual pistol allowed with \x04snipers\x01. Dropped secondary.");
        }
    }
}


public Action: Timer_PushCarUpwards(Handle:timer, any:car)
{
    // send it flying
    if ( !IsValidEntity(car) ) { return Plugin_Continue; }
    
    LaunchCar(car);
    
    return Plugin_Continue;
}





/*  Gnomes
    ------ */
ResetGnomes()
{
    g_iGnomes = 0;
    for (new x=0; x < GNOME_MAX_COUNT; x++)
    {
        g_strArGnomes[x][gnomebIsCola] = false;
        g_strArGnomes[x][gnomebWorthPoints] = true;
        g_strArGnomes[x][gnomebHeldByPlayer] = false;
        g_strArGnomes[x][gnomeiHoldingClient] = 0;
        g_strArGnomes[x][gnomebFirstPickup] = false;
        g_strArGnomes[x][gnomefFirstPickup] = 9999.0;
        g_strArGnomes[x][gnomeEntity] = -1;
        g_strArGnomes[x][gnomebAccountedFor] = false;
    }
    
    g_iGnomesHeld = 0;
    for (new x=0; x < TEAM_SIZE; x++)
    {
        g_iArGnomesHeld[x] = 0;
    }
}

// check if all gnomes are accounted for correctly
//      gnomes set as 'held' to actually be held, by the correct player
//      gnomes with entity set to actually be that entity
CheckGnomes()
{
    new String:classname[128];
    
    for (new i=0; i < g_iGnomes; i++)
    {
        // skip the gnome if already deemed unaccounted for
        if (g_strArGnomes[i][gnomebAccountedFor]) { continue; }
        
        
        new gnomeEnt = g_strArGnomes[i][gnomeEntity];
        new gnomeClient = g_strArGnomes[i][gnomeiHoldingClient];
        
        if ( g_strArGnomes[i][gnomebHeldByPlayer] )
        {
            // is that player really holding the gnome?
            if (    !IsClientAndInGame( gnomeClient )
                ||  !IsPlayerAlive( gnomeClient )
                ||  !IsPlayerHoldingGnome( gnomeClient )
            ) {
                PrintDebug(4, "[rand gnome] Found gnome incorrectly marked as held: #%i (ent: %i; client: %i)", i, gnomeEnt, gnomeClient);
                g_strArGnomes[i][gnomebHeldByPlayer] = false;
                g_strArGnomes[i][gnomeiHoldingClient] = 0;
                RemoveGnomeHeld(gnomeEnt);
                gnomeClient = 0;
            }
            else
            {
                // it is really held by a player - check if the entity is correct
                new tmpEnt = GetEntPropEnt(gnomeClient, Prop_Send, "m_hActiveWeapon");
                if ( tmpEnt != gnomeEnt )
                {
                    PrintDebug(4, "[rand gnome] Found gnome incorrectly marked as held, wrong entity: #%i (ent: %i (expected %i); client: %i [%N])", i, gnomeEnt, tmpEnt, gnomeClient, gnomeClient);
                    
                    // is what the player is holding a gnome?
                    if (IsValidEntity(tmpEnt)) {
                        GetEdictClassname(tmpEnt, classname, sizeof(classname));
                    } else {
                        classname = "";
                    }
                    
                    if ( !StrEqual(classname, "weapon_gnome", false) && !StrEqual(classname, "weapon_cola_bottles", false) )
                    {
                        // it's not even a gnome
                        g_strArGnomes[i][gnomebHeldByPlayer] = false;
                        g_strArGnomes[i][gnomeiHoldingClient] = 0;
                        RemoveGnomeHeld(gnomeEnt);
                        gnomeClient = 0;
                    }
                    else
                    {
                        // it is a gnome
                    
                        // see if any other gnome is currently deemed to be held by this player
                        // if that gnome's entity # matches, consider THIS gnome to not be held
                        new bool: foundGnome = false;
                        for (new j=0; j < g_iGnomes; j++)
                        {
                            if (j == i) { continue; }
                            if (    g_strArGnomes[j][gnomebHeldByPlayer]
                                &&  g_strArGnomes[j][gnomeiHoldingClient] == gnomeClient
                                &&  g_strArGnomes[j][gnomeEntity] == tmpEnt
                            ) {
                                PrintDebug(4, "[rand gnome] player is holding different gnome: #%i (ent: %i)", j, tmpEnt);
                                foundGnome = true;
                            }
                        }
                    
                        if (foundGnome)
                        {
                            // the player is holding a different gnome
                            g_strArGnomes[i][gnomebHeldByPlayer] = false;
                            g_strArGnomes[i][gnomeiHoldingClient] = 0;
                            RemoveGnomeHeld(gnomeEnt);
                            gnomeClient = 0;
                        }
                        else
                        {
                            // otherwise, update held gnome entity
                            RemoveGnomeHeld(gnomeEnt);
                            g_strArGnomes[i][gnomeEntity] = tmpEnt;
                            gnomeEnt = tmpEnt;
                            g_strArGnomes[i][gnomebAccountedFor] = true;
                        }
                    }
                }
                else
                {
                    // correct
                    g_strArGnomes[i][gnomebAccountedFor] = true;
                }
                
                // it is actually held, check the array, add if necessary
                if ( g_strArGnomes[i][gnomebHeldByPlayer] && FindGnomeHeldIndex( gnomeEnt ) == -1 )
                {
                    g_iGnomesHeld++;
                    g_iArGnomesHeld[i] = gnomeEnt;
                }
            }
        }
        
        if ( !g_strArGnomes[i][gnomebHeldByPlayer] )
        {
            // check the gnome entity (if not correctly found to be held)
            if ( gnomeEnt == 0 ){
                PrintDebug(4, "[rand gnome] Found gnome with missing entity number, set as unaccounted for.");
                g_strArGnomes[i][gnomeEntity] = 0;
                g_strArGnomes[i][gnomebAccountedFor] = false;
            } 
            else if ( !IsValidEntity( gnomeEnt ) ) {
                PrintDebug(4, "[rand gnome] Found gnome with wrong entity number: #%i (ent expected %i), set as unaccounted for.", i, gnomeEnt);
                g_strArGnomes[i][gnomeEntity] = 0;
                g_strArGnomes[i][gnomebAccountedFor] = false;
                continue;
            }
            
            // entity exists, check if it's a gnome/cola
            GetEdictClassname(gnomeEnt, classname, sizeof(classname));
            new bool: isGnomeCola = false;
            if (StrEqual(classname, "weapon_gnome", false) || StrEqual(classname, "weapon_cola_bottles", false))
            {
                isGnomeCola = true;
            }
            else if ( StrEqual(classname, "prop_physics", false) )
            {
                // check model
                new String: model[128];
                GetEntPropString(gnomeEnt, Prop_Data, "m_ModelName", model, STR_MAX_MODELNAME);
                if ( StrEqual(model, "models/props_junk/gnome.mdl", false) || StrEqual(model, "models/w_models/weapons/w_cola.mdl", false) ) {
                    isGnomeCola = true;
                }
            }
            
            if (!isGnomeCola)
            {
                // wrong type
                PrintDebug(4, "[rand gnome] Found gnome with wrong entity number (wrong class: %s): #%i (ent expected %i), set as unaccounted for.", classname, i, gnomeEnt);
                g_strArGnomes[i][gnomeEntity] = 0;
                g_strArGnomes[i][gnomebAccountedFor] = false;
                continue;
            }
            
            // it's okay
            g_strArGnomes[i][gnomebAccountedFor] = true;
        }
    }
}
stock bool: IsPlayerHoldingGnome( client )
{
    if (!IsClientAndInGame(client)) { return false; }
    
    new String:classname[128];
    new entity = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    
    if (    !IsValidEntity(entity)
        ||  ( !StrEqual(classname, "weapon_gnome", false) && !StrEqual(classname, "weapon_cola_bottles", false ) )
    ) {
        return false;
    }
    
    return true;
}
FindGnomeIndex(entity)
{
    for (new x=0; x < g_iGnomes; x++)
    {
        if (g_strArGnomes[x][gnomeEntity] == entity) {
            return x;
        }
    }
    return -1;
}

FindGnomeIndexByClient(client)
{
    for (new x=0; x < g_iGnomes; x++)
    {
        if (g_strArGnomes[x][gnomeiHoldingClient] == client) {
            return x;
        }
    }
    return -1;
}

FindGnomeHeldIndex(entity)
{
    for (new i=0; i < g_iGnomesHeld; i++)
    {
        if (g_iArGnomesHeld[i] == entity) { return i; }
    }
    return -1;
}

RemoveGnomeHeld(entity)
{
    // unsets a gnome as held (and cleans up the array)
    new found = FindGnomeHeldIndex(entity);
    
    if (found != -1)
    {
        g_iArGnomesHeld[found] = 0;
        if (found + 1 < g_iGnomesHeld) {
            for (new i = found; i < g_iGnomesHeld - 1; i++) {
                g_iArGnomesHeld[i] = g_iArGnomesHeld[i+1];
            }
        }
        g_iGnomesHeld--;
    }
}

// called when any client picks up a gnome (client is assumed safe, entity too) -- bIsGnome is false when cola
OnPlayerGnomePickup(client, entity, bool: bIsGnome = true)
{
    CheckGnomes();
    
    new gnomeIndex = FindGnomeIndex(entity);
    
    PrintDebug(4, "[rand gnome] Gnome pickup (%s): index %i, entity %i.", (bIsGnome) ? "gnome" : "cola", gnomeIndex, entity);
    
    // if gnomeIndex is not correct, find unaccounted for gnome..
    if ( gnomeIndex == -1 )
    {
        for (new i=0; i < g_iGnomes; i++)
        {
            if (g_strArGnomes[i][gnomebAccountedFor] || bIsGnome == g_strArGnomes[i][gnomebIsCola]) { continue; }
            
            PrintDebug(4, "[rand gnome] assigning to unaccounted for gnome at index %i.", i);
            gnomeIndex = i;
            break;
        }
    }
    
    if ( gnomeIndex == -1 )
    {
        // still not found which gnome it is... this SHOULD never happen...
        // create new index for it
        UpdateClientHoldingGnome(client, entity);
        gnomeIndex = g_iGnomes - 1;
    }
    
    if (gnomeIndex == -1 || !g_strArGnomes[gnomeIndex][gnomebWorthPoints])
    {
        // weird, unknown gnome
        if (!g_bCampaignMode)
        {
            PrintToChat(client, "\x01[\x05r\x01] This %s is not worth any points.", (bIsGnome) ? "gnome" : "cola" );
        }
    }
    else
    {
        // manage held gnomes array
        g_iGnomesHeld++;
        if (g_iGnomesHeld > TEAM_SIZE) { g_iGnomesHeld = 1; PrintDebug(3, "[rand gnome] Excessive 'held gnome/cola' count!"); }     // shouldn't happen after CheckGnomes!
        
        g_iArGnomesHeld[g_iGnomesHeld-1] = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
        
        if (!g_strArGnomes[gnomeIndex][gnomebFirstPickup])
        {
            // first pickup = set value according to flow distance
            g_strArGnomes[gnomeIndex][gnomebFirstPickup] = true;
            g_strArGnomes[gnomeIndex][gnomefFirstPickup] = FloatAbs( L4D2Direct_GetFlowDistance(client) / L4D2Direct_GetMapMaxFlowDistance() );
        }
        
        new tmpPoints = GetGnomeValue( g_strArGnomes[gnomeIndex][gnomefFirstPickup] );
        
        if (!g_bCampaignMode) {
            PrintToChat(client, "\x01[\x05r\x01] This %s is worth \x03%i\x01 point%s.", (bIsGnome) ? "gnome" : "cola", tmpPoints, (tmpPoints > 1) ? "s" : "" );
            //PrintToChatAll("picked up gnomecola [%i]: %i is now: %i", g_iGnomesHeld, g_strArGnomes[gnomeIndex][gnomeEntity], g_iArGnomesHeld[g_iGnomesHeld-1]);
        }
        
        g_strArGnomes[gnomeIndex][gnomeEntity] = g_iArGnomesHeld[g_iGnomesHeld-1];
        g_strArGnomes[gnomeIndex][gnomebHeldByPlayer] = true;
        g_strArGnomes[gnomeIndex][gnomeiHoldingClient] = client;
    }
}

// called when player drops cola (weapondrop event) -- NOT called for gnomes!
OnPlayerDroppingCola(client, entity)
{
    new gnomeIndex = -1;
    
    // can we find it by entity?
    if (entity && IsValidEntity(entity)) {
        gnomeIndex = FindGnomeIndex(entity);
    } else {
        gnomeIndex = FindGnomeIndexByClient(client);
        if (gnomeIndex != -1) {
            entity = g_strArGnomes[gnomeIndex][gnomeEntity];
        }
    }
    
    if (gnomeIndex != -1)
    {
        new found = -1;
        for (new i = 0; i < g_iGnomesHeld; i++)
        {
            if (entity == g_iArGnomesHeld[i]) {
                found = i;
                break;
            }
        }
        
        // cola was dropped, remove from held array
        if (found != -1)
        {
            new gnomeEnt = g_iArGnomesHeld[found];
            RemoveGnomeHeld(gnomeEnt);
            
            //PrintToChatAll("dropped gnome: %i (= %i) (now %i held)", entity, gnomeEnt, g_iGnomesHeld);

            g_iGnomeJustDropped = gnomeEnt;
        }
        
        // adjust gnomes array too
        g_strArGnomes[gnomeIndex][gnomeEntity] = entity;        // though it shouldn't be changed
        g_strArGnomes[gnomeIndex][gnomebHeldByPlayer] = false;
        g_strArGnomes[gnomeIndex][gnomeiHoldingClient] = 0;
    }
    else
    {
        PrintDebug(4, "[rand gnome] couldn't find gnome index for dropped cola entity %i. Checking Gnomes.", entity);
        CheckGnomes();
    }
}

// called when an entity is destroyed (could be a gnome) -- happens when gnome is dropped
OnPossibleGnomeDestroyed(entity)
{
    // entity does not exist anymore
    // check if we find it in the gnomes arrays
    
    // held gnome?
    new found = -1;
    for (new i = 0; i < g_iGnomesHeld; i++) {
        if (entity == g_iArGnomesHeld[i]) {
            found = i;
            break;
        }
    }
    
    // yup, a gnome was dropped
    if (found != -1)
    {
        new gnomeIndex = FindGnomeIndex(entity);
        RemoveGnomeHeld(entity);
        
        PrintDebug(4, "[rand gnome] gnome drop detected: entity: %i, gnome index: %i. ", entity, gnomeIndex);
        
        if (gnomeIndex != -1)
        {
            g_strArGnomes[gnomeIndex][gnomebHeldByPlayer] = false;
            g_strArGnomes[gnomeIndex][gnomeiHoldingClient] = 0;
            //g_strArGnomes[gnomeIndex][gnomeEntity] = 0;
            g_strArGnomes[gnomeIndex][gnomebAccountedFor] = false;
        }
        else
        {
            PrintDebug(4, "[rand gnome] couldn't find gnome index for dropped gnome entity %i. Checking Gnomes.", entity);
            CheckGnomes();
        }
        
        // this is unsafe -- what if two players drop a gnome at the same time?
        // use bAccountedFor instead, just find unaccounted for gnomes and use them
        // just use this as an 'is something dropped?' check
        g_iGnomeJustDropped = entity;
    }
}

// called when a gnome is created that might be dropped (client is assumed safe, entity too) -- not called for cola!
OnPossibleDroppedGnomeCreated(entity)
{
    if (!g_bItemsFullyRandomized) { return; }   // the gnome's created by randomization, not due to player drop
    //if (g_iGnomeJustDropped < 1) { return; }  // wouldn't be called if this were true
    
    new gnomeIndex = FindGnomeIndex(g_iGnomeJustDropped);
    
    PrintDebug(4, "[rand gnome] possible gnome drop: entity %i (index: %i).", entity, gnomeIndex);
    
    // if gnome is indeed unaccounted for, use it
    // if not, find a gnome that IS unaccounted for, and use that
    
    if (gnomeIndex != -1 && !g_strArGnomes[gnomeIndex][gnomebAccountedFor])
    {
        g_strArGnomes[gnomeIndex][gnomeEntity] = entity;
        g_strArGnomes[gnomeIndex][gnomebHeldByPlayer] = false;
        g_strArGnomes[gnomeIndex][gnomeiHoldingClient] = 0;
        g_strArGnomes[gnomeIndex][gnomebAccountedFor] = true;
    }
    else
    {
        PrintDebug(4, "[rand gnome] dropped gnome problem: no index, or gnome at index was not unaccounted for. Checking other gnomes.");
        
        CheckGnomes();
        
        gnomeIndex = -1;
        for (new i=0; i < g_iGnomes; i++)
        {
            if ( g_strArGnomes[i][gnomebFirstPickup] && !g_strArGnomes[i][gnomebAccountedFor] )
            {
                gnomeIndex = i;
            }
        }
        
        if (gnomeIndex != -1)
        {
            // use this unaccounted for gnome
            PrintDebug(4, "[rand gnome] Assigning gnome drop to (new) index: %i.", gnomeIndex);
            
            g_strArGnomes[gnomeIndex][gnomeEntity] = entity;
            g_strArGnomes[gnomeIndex][gnomebHeldByPlayer] = false;
            g_strArGnomes[gnomeIndex][gnomeiHoldingClient] = 0;
            g_strArGnomes[gnomeIndex][gnomebAccountedFor] = true;
        }
        else
        {
            PrintDebug(3, "[rand gnome] dropped gnome created problem: no unaccounted for gnomes. Valueless gnome created! (entity %i)", entity);
        }
    }
    
    g_iGnomeJustDropped = 0;
}

// this should only be called after a gnome is handed to someone for having no weapon at start
UpdateClientHoldingGnome(client, entity=-1, bool:setHeld=true)
{
    // if a client is handed a gnome (at round start)
    if (!IsSurvivor(client)) { return; }
    
    g_iGnomes++;
    g_strArGnomes[g_iGnomes-1][gnomebFirstPickup] = true;
    g_strArGnomes[g_iGnomes-1][gnomefFirstPickup] = 0.0;
    
    if (entity == -1) {
        entity = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    }
    
    g_strArGnomes[g_iGnomes-1][gnomeEntity] = entity;
    g_strArGnomes[g_iGnomes-1][gnomebHeldByPlayer] = true;
    g_strArGnomes[g_iGnomes-1][gnomeiHoldingClient] = client;
    g_strArGnomes[g_iGnomes-1][gnomebAccountedFor] = true;
    
    // if it's not in held gnome array, add it
    if (setHeld && FindGnomeHeldIndex( g_strArGnomes[g_iGnomes-1][gnomeEntity] ) == -1)
    {
        g_iGnomesHeld++;
        g_iArGnomesHeld[g_iGnomesHeld-1] = g_strArGnomes[g_iGnomes-1][gnomeEntity];
    }
}


// value of a gnome when picked up at given distance
GetGnomeValue(Float:distance)
{
    distance = FloatAbs(distance);
    new Float: fBonus = GetConVarFloat(g_hCvarGnomeBonus);
    
    if (g_RI_bIsFinale)
    {
        fBonus = fBonus * GetConVarFloat(g_hCvarGnomeFinaleFactor);
        
        // weigh distance for only this factor, if we're going by distance
        if (fBonus < 10.0) {
            fBonus = fBonus * L4D_GetVersusMaxCompletionScore();
            // factor in distance factor (get right average between full and distance-scaled bonus)
            fBonus = ((1.0 - GNOME_FINALE_DIST_FACTOR) * fBonus) + (GNOME_FINALE_DIST_FACTOR * fBonus * (1.0 - distance));
        }
    } else {
        if (fBonus < 10.0) {
            fBonus = fBonus * L4D_GetVersusMaxCompletionScore() * (1.0 - distance);
        }
    }
    
    return RoundToCeil( fBonus );
}

GetGnomeBonus(bool:showMessage = false)
{
    /*
        This gets called internally only on round-end to display the result
        This gets called by l4d2_random_bonus to actually calculate/get the bonus working
            showMessage is only set by internal calls
    */
    
    // check gnome status on all -- so false gnomes 'held' are not counted
    CheckGnomes();
    
    // check if gnomes are held
    // check which gnomes are in saferoom as props
    
    new countGnomes = 0;
    new countCola = 0;
    new countPoints = 0;
    
    // only do calc if there can be bonus at all
    if (GetConVarFloat(g_hCvarGnomeBonus) == 0.0) { return 0; }
    
    for (new i=0; i < g_iGnomes; i++)
    {
        //PrintToChatAll("gnome %i: held: %i, insafe: %i...", i, g_strArGnomes[i][gnomebHeldByPlayer], IsEntityInSaferoom( g_strArGnomes[i][gnomeEntity] , false, true) );
        
        // is it in saferoom?
        if (!g_strArGnomes[i][gnomebHeldByPlayer] && !IsEntityInSaferoom( g_strArGnomes[i][gnomeEntity], false, true)) { continue; }
        if (!g_strArGnomes[i][gnomebFirstPickup] || !g_strArGnomes[i][gnomebWorthPoints]) { continue; }
        
        if (!g_strArGnomes[i][gnomebIsCola]) { countGnomes++; } else { countCola++; }
        
        countPoints += GetGnomeValue(g_strArGnomes[i][gnomefFirstPickup]);
    }
    
    if (!countGnomes && !countCola) { return 0; }
    
    if (showMessage) {
        new String: msgPart[128] = "";
        if (countGnomes) {
            Format(msgPart, sizeof(msgPart), "\x03%i\x01 gnome%s%s", countGnomes, (countGnomes == 1) ? "" : "s", (countCola) ? " and " : "" );
        }
        if (countCola) {
            Format(msgPart, sizeof(msgPart), "%s\x03%i\x01 colapack%s", msgPart, countCola, (countCola == 1) ? "" : "s");
        }
        
        PrintToChatAll("\x01[\x05r\x01] Survivors brought %s, worth \x04%i\x01 bonus point%s.", msgPart, countPoints, (countPoints == 1) ? "" : "s"  );
    }
    
    return countPoints;
}



/*  Team changes and other votes
    ------------ */
SUPPORT_VoteShuffleTeams(client)
{
    if (!IsClientAndInGame(client) || (GetClientTeam(client) != TEAM_SURVIVOR && GetClientTeam(client) != TEAM_INFECTED) ) { return; }
    
    // see if we're doing a vote at the right time
    new bool: bReadyUpLoaded = bool:(g_hCvarReadyUp != INVALID_HANDLE && GetConVarBool(g_hCvarReadyUp));
    if (bReadyUpLoaded && !SUPPORT_IsInReady())
    {
        PrintToChat(client, "\x01[\x05r\x01] Team shuffles are only allowed before a round is live.");
        return;
    }
    
    if (g_fTeamShuffleTimeout != 0.0 && GetGameTime() < g_fTeamShuffleTimeout)
    {
        PrintToChat(client, "\x01[\x05r\x01] Can't shuffle teams again so quickly (%d second timeout).", RoundToCeil(g_fTeamShuffleTimeout - GetGameTime()) );
        return;
    }
    
    if (g_bTeamSurvivorVoted && g_bTeamInfectedVoted)
    {
        PrintToChat(client, "\x01[\x05r\x01] Shuffle is already under way!");
        return;
    }
    
    // status?
    if (GetClientTeam(client) == TEAM_SURVIVOR)
    {
        if (g_bTeamInfectedVoted) {
            // survivors respond
            if (!g_bTeamSurvivorVoted) {
                g_bTeamSurvivorVoted = true;
                PrintToChatAll("\x01[\x05r\x01] %N (Survivor) accepted the team shuffle. Shuffling in 3 seconds.", client);
                CreateTimer(3.0, Timer_ShuffleTeams, _, TIMER_FLAG_NO_MAPCHANGE);
            }
        } else {
            // survivors first
            if (!g_bTeamSurvivorVoted) {
                g_bTeamSurvivorVoted = true;
                PrintToChatAll("\x01[\x05r\x01] %N (Survivor) voted for a team shuffle. Infected can \x04!teamshuffle\x01 to accept.", client);
            }
        }
    }
    else
    {
        if (g_bTeamSurvivorVoted) {
            // infected respond
            if (!g_bTeamInfectedVoted) {
                g_bTeamInfectedVoted = true;
                PrintToChatAll("\x01[\x05r\x01] %N (Infected) accepted the team shuffle. Shuffling in 3 seconds.", client);
                CreateTimer(3.0, Timer_ShuffleTeams, _, TIMER_FLAG_NO_MAPCHANGE);
            }
        } else {
            // Infected first
            if (!g_bTeamInfectedVoted) {
                g_bTeamInfectedVoted = true;
                PrintToChatAll("\x01[\x05r\x01] %N (Infected team) voted for a team shuffle. Survivors can \x04!teamshuffle\x01 to accept.", client);
            }
        }
    }
}

public Action:Timer_ShuffleTeams(Handle:timer)
{
    g_bTeamSurvivorVoted = false;
    g_bTeamInfectedVoted = false;
    SUPPORT_ShuffleTeams();
}


SUPPORT_ShuffleTeams(client=-1)
{
    new bool: bReadyUpLoaded = bool:(g_hCvarReadyUp != INVALID_HANDLE && GetConVarBool(g_hCvarReadyUp));
    if (bReadyUpLoaded && !SUPPORT_IsInReady())
    {
        if (client == -1) {
            PrintToChatAll("\x01[\x05r\x01] Team shuffles are only allowed before a round is live.");
        } else {
            PrintToChat(client, "\x01[\x05r\x01] Team shuffles are only allowed before a round is live.");
        }
        return;
    }
    
    if (g_fTeamShuffleTimeout != 0.0 && GetGameTime() < g_fTeamShuffleTimeout)
    {
        if (client == -1) {
            PrintToChatAll("\x01[\x05r\x01] Can't shuffle teams again so quickly (%d second timeout).", RoundToCeil(g_fTeamShuffleTimeout - GetGameTime()) );
        } else {
            PrintToChat(client, "\x01[\x05r\x01] Can't shuffle teams again so quickly (%d second timeout).", RoundToCeil(g_fTeamShuffleTimeout - GetGameTime()) );
        }
    }
    
    new specCount = 0;
    new survCount = 0;
    new infCount = 0;
    
    new teamSize = GetConVarInt(g_hCvarTeamSize);
    
    for (new i=1; i <= MaxClients; i++) {
        if (!IsClientInGame(i) || IsFakeClient(i)) { continue; }
        
        switch (GetClientTeam(i)) {
            case TEAM_SPECTATOR: { specCount++; }
            case TEAM_SURVIVOR: { survCount++; }
            case TEAM_INFECTED: { infCount++; }
        }
    }
    
    new iPlayerCount = 0;
    new arPlayerPool[MaxClients+1];
    new arRandomPlayers[ (teamSize * 2) ];
    
    // if teams are full, shuffle only the players in there
    // if not, take spectators into account
    if (survCount + infCount ==  teamSize * 2) {
        for (new i=1; i <= MaxClients; i++) {
            if (!IsClientInGame(i) || IsFakeClient(i)) { continue; }
            switch (GetClientTeam(i)) {
                case TEAM_SURVIVOR, TEAM_INFECTED: { arPlayerPool[iPlayerCount] = i; }
            }
            iPlayerCount++;
        }
    } else {
        for (new i=1; i <= MaxClients; i++) {
            if (!IsClientInGame(i) || IsFakeClient(i)) { continue; }
            arPlayerPool[iPlayerCount] = i;
            iPlayerCount++;
        }
    }
    
    // safeguard
    if (!iPlayerCount) { return; }
    
    // pick random players for pool
    for (new i=0; i < teamSize * 2; i++)
    {
        if (i >= iPlayerCount) { break; }
        
        new tmpPick = -1;
        for (new z=0; z < 1000; z++)
        {
            tmpPick = arPlayerPool[ GetRandomInt(0, iPlayerCount -1) ];
            for (new j=0; j < i; j++) {
                if (arRandomPlayers[j] == tmpPick) { tmpPick = -1; }
            }
            if (tmpPick != -1) { break; }
        }

        arRandomPlayers[i] = tmpPick;
    }
    
    // set all players to spec
    for (new i=1; i <= MaxClients; i++) {
        if (!IsClientInGame(i) || IsFakeClient(i)) { continue; }
        
        ChangePlayerTeam(i, TEAM_SPECTATOR );
    }
        
    // randomly pick one for each until no players left or teams full
    new bool: bSurvTeam = true;
    for (new i=0; i < teamSize * 2; i++)
    {
        if (i >= iPlayerCount) { break; }
        
        // alternate between teams to pick
        /*
        if (bReadyUpLoaded) {
            ServerCommand("sm_swapto #%i %d", GetClientUserId(arRandomPlayers[i]), (bSurvTeam) ? TEAM_SURVIVOR : TEAM_INFECTED);
        } else {
            ChangePlayerTeam(arRandomPlayers[i], (bSurvTeam) ? TEAM_SURVIVOR : TEAM_INFECTED );
        }
        */
        ChangePlayerTeam(arRandomPlayers[i], (bSurvTeam) ? TEAM_SURVIVOR : TEAM_INFECTED );
        
        bSurvTeam = !bSurvTeam;
    }
    
    PrintToChatAll("\x01[\x05r\x01] Teams were shuffled.");
    
    // set timeout
    g_fTeamShuffleTimeout = GetGameTime() + TEAMSHUFFLE_TIMEOUT;
}


stock bool:ChangePlayerTeam(client, team /*, bool:force */)
{
    if ( !IsClientAndInGame(client) || GetClientTeam(client) == team )
    {
        return true;
    }
    /*
    else if (!force && GetTeamHumanCount(team) == GetTeamMaxHumans(team)) 
    {
        return false;
    }
    */
    
    if (team != TEAM_SURVIVOR)
    {
        ChangeClientTeam(client, team);
        return true;
    }
    else
    {
        new bot = FindSurvivorBot();
        if (bot > 0)
        {
            CheatCommand(client, "sb_takecontrol", "");
            return true;
        }
    }
    return false;
}

/* return -1 if no bot found, clientid otherwise */
stock FindSurvivorBot()
{
    for (new client = 1; client <= MaxClients; client++)
    {
        if (IsClientInGame(client) && IsFakeClient(client) && GetClientTeam(client) == TEAM_SURVIVOR)
        {
            return client;
        }
    }
    return -1;
}


SUPPORT_VotePickEvent(event, client)
{
    if (!IsClientAndInGame(client) || (GetClientTeam(client) != TEAM_SURVIVOR && GetClientTeam(client) != TEAM_INFECTED) ) { return; }
    
    // see if we're doing a vote at the right time
    if (g_fPickEventTimeout != 0.0 && GetGameTime() < g_fPickEventTimeout)
    {
        PrintToChat(client, "\x01[\x05r\x01] Can't pick special event again so quickly (%d second timeout).", RoundToCeil(g_fPickEventTimeout - GetGameTime()) );
        return;
    }
    
    // what event?
    if (!g_bTeamSurvivorVotedEvent && !g_bTeamInfectedVotedEvent)
    {
        if (event == -1 || event == 0) {
            g_iEventMenu[client] = EVTMNU_PICK;
            SUPPORT_ShowEventList(client);
            return;
        }
        else if (event < 1 || event > EVT_TOTAL) {
            PrintToChat(client, "\x01[\x05r\x01] Wrong event number: \x04%i\x01. Use \"\x04!event list\x01\" to pick from a list.", event);
            return;
        }
        else if (g_iSpecialEventToForce == event) {
            PrintToChat(client, "\x01[\x05r\x01] That event is already forced to appear next round.");
            return;
        }
        else {
            g_iPickEvent = event - 1;
        }
    }
    else if (event != g_iPickEvent+1 && event >= 1 && event <= EVT_TOTAL) {
        PrintToChat(client, "\x01[\x05r\x01] A vote is already active. Decline with \"\x04!event no\x01\" before suggesting another event.");
        return;
    }
    
    SUPPORT_VotePickEventChoose(event, client);
}

SUPPORT_VotePickEventChoose(event, client)
{
    if (!IsClientAndInGame(client) || (GetClientTeam(client) != TEAM_SURVIVOR && GetClientTeam(client) != TEAM_INFECTED) ) { return; }
    
    // see if we're doing a vote at the right time
    if (g_fPickEventTimeout != 0.0 && GetGameTime() < g_fPickEventTimeout)
    {
        PrintToChat(client, "\x01[\x05r\x01] Can't pick special event again so quickly (%d second timeout).", RoundToCeil(g_fPickEventTimeout - GetGameTime()) );
        return;
    }
    
    if (g_bTeamSurvivorVotedEvent || g_bTeamInfectedVotedEvent)
    {
        if (    (GetClientTeam(client) == TEAM_SURVIVOR && g_bTeamSurvivorVotedEvent)
            ||  (GetClientTeam(client) == TEAM_INFECTED && g_bTeamInfectedVotedEvent)
        ) {
            PrintToChat(client, "\x01[\x05r\x01] A vote is already active. Wait for the other team to respond.");
            return;
        }
        else if (event > 0) {
            PrintToChat(client, "\x01[\x05r\x01] A vote is already active. Decline with \"\x04!event no\x01\" before suggesting another event.");
            return;
        }
    }
    
    // status?
    if (GetClientTeam(client) == TEAM_SURVIVOR)
    {
        if (g_bTeamInfectedVotedEvent) {
            // survivors respond
            if (!g_bTeamSurvivorVotedEvent) {
                if (event == -1) {
                    // declined
                    PrintToChatAll("\x01[\x05r\x01] %N (Survivor) declined the event pick.", client);
                } else {
                    // accepted
                    PrintToChatAll("\x01[\x05r\x01] %N (Survivor) accepted the event. Next round has event \x04%i\x01.", client, g_iPickEvent+1);
                    SUPPORT_PickEvent(g_iPickEvent+1);
                }
                g_bTeamInfectedVotedEvent = false;
                g_bTeamSurvivorVotedEvent = false;
            }
        } else {
            // survivors first
            if (!g_bTeamSurvivorVotedEvent) {
                g_bTeamSurvivorVotedEvent = true;
                PrintToChatAll("\x01[\x05r\x01] %N (Survivor) voted to pick next event: \x04%i\x01. \"%s\".", client, g_iPickEvent+1, g_csEventTextShort[g_iPickEvent] );
                PrintToChatAll("\x01[\x05r\x01] Infected can \x04!event\x01 to accept (\"\x04!event no\x01\" to decline.)");
            }
        }
    }
    else
    {
        if (g_bTeamSurvivorVotedEvent) {
            // infected respond
            if (!g_bTeamInfectedVotedEvent) {
                if (event == -1) {
                    // declined
                    PrintToChatAll("\x01[\x05r\x01] %N (Survivor) declined the event pick.", client);
                } else {
                    // accepted
                    PrintToChatAll("\x01[\x05r\x01] %N (Survivor) accepted. Next round has event \x04%i\x01.", client, g_iPickEvent+1);
                    SUPPORT_PickEvent(g_iPickEvent+1, -1);
                }
                g_bTeamInfectedVotedEvent = false;
                g_bTeamSurvivorVotedEvent = false;
            }
        } else {
            // Infected first
            if (!g_bTeamInfectedVotedEvent) {
                g_bTeamInfectedVotedEvent = true;
                PrintToChatAll("\x01[\x05r\x01] %N (Infected team) voted to pick next event: \x04%i\x01. \"%s\".", client, g_iPickEvent+1, g_csEventTextShort[g_iPickEvent] );
                PrintToChatAll("\x01[\x05r\x01] Survivors can \x04!event\x01 to accept (\"\x04!event no\x01\" to decline.)");
            }
        }
    }
}

SUPPORT_PickEvent(event, client=0)
{
    if (event < 1 || event > EVT_TOTAL)
    {
        if (client > 0) {
            PrintToChat(client, "\x01[\x05r\x01] Wrong event number: \x04%i\x01. For numbers go from \x041\x01 to \x04%i\x01. For a list, see http://www.tabun.nl/random/.", event, EVT_TOTAL);
        }
        return;
    }
    
    g_iPickEvent = event - 1;
    g_iSpecialEventToForce = g_iPickEvent;
    
    if (client > 0)
    {
        // report to all
        PrintToChatAll("\x01[\x05r\x01] Admin forced event: \x04%i\x01. \"%s\".", g_iPickEvent+1, g_csEventTextShort[g_iPickEvent] );
    }
}

SUPPORT_VotePickGameEvent(event, client)
{
    if (!IsClientAndInGame(client) || (GetClientTeam(client) != TEAM_SURVIVOR && GetClientTeam(client) != TEAM_INFECTED) ) { return; }
    
    // see if we're doing a vote at the right time
    if (g_fPickEventTimeout != 0.0 && GetGameTime() < g_fPickEventTimeout)
    {
        PrintToChat(client, "\x01[\x05r\x01] Can't pick special event again so quickly (%d second timeout).", RoundToCeil(g_fPickEventTimeout - GetGameTime()) );
        return;
    }
    
    // what event?
    if (!g_bTeamSurvivorVotedGameEvent && !g_bTeamInfectedVotedGameEvent)
    {
        if (event == -1 || event == 0) {
            g_iEventMenu[client] = EVTMNU_PICKGAME;
            SUPPORT_ShowEventList(client);
            return;
        }
        else if (event < 1 || event > EVT_TOTAL) {
            PrintToChat(client, "\x01[\x05r\x01] Wrong event number: \x04%i\x01. Use \"\x04!gameevent list\x01\" to pick from a list.", event);
            return;
        }
        else {
            g_iPickGameEvent = event - 1;
        }
    }
    else if (event != g_iPickGameEvent+1 && event >= 1 && event <= EVT_TOTAL) {
        PrintToChat(client, "\x01[\x05r\x01] A vote is already active. Decline with \"\x04!gameevent no\x01\" before suggesting another event.");
        return;
    }
    
    
    SUPPORT_VotePickGameEventChoose(event, client);
}

SUPPORT_VotePickGameEventChoose(event, client)
{
    if (!IsClientAndInGame(client) || (GetClientTeam(client) != TEAM_SURVIVOR && GetClientTeam(client) != TEAM_INFECTED) ) { return; }
    
    // see if we're doing a vote at the right time
    if (g_fPickEventTimeout != 0.0 && GetGameTime() < g_fPickEventTimeout)
    {
        PrintToChat(client, "\x01[\x05r\x01] Can't pick special event again so quickly (%d second timeout).", RoundToCeil(g_fPickEventTimeout - GetGameTime()) );
        return;
    }
    
    if (g_bTeamSurvivorVotedGameEvent || g_bTeamInfectedVotedGameEvent)
    {
        if (    (GetClientTeam(client) == TEAM_SURVIVOR && g_bTeamSurvivorVotedGameEvent)
            ||  (GetClientTeam(client) == TEAM_INFECTED && g_bTeamInfectedVotedGameEvent)
        ) {
            PrintToChat(client, "\x01[\x05r\x01] A vote is already active. Wait for the other team to respond.");
            return;
        }
        else if (event > 0) {
            PrintToChat(client, "\x01[\x05r\x01] A vote is already active. Decline with \"\x04!gameevent no\x01\" before suggesting another event.");
            return;
        }
    }
    
    // status?
    if (GetClientTeam(client) == TEAM_SURVIVOR)
    {
        if (g_bTeamInfectedVotedGameEvent) {
            // survivors respond
            if (!g_bTeamSurvivorVotedGameEvent) {
                if (event == -1) {
                    // declined
                    PrintToChatAll("\x01[\x05r\x01] %N (Survivor) declined the game event pick.", client);
                } else {
                    // accepted
                    PrintToChatAll("\x01[\x05r\x01] %N (Survivor) accepted the game event. All rounds will have event \x04%i\x01.", client, g_iPickGameEvent+1);
                    SUPPORT_PickGameEvent(g_iPickGameEvent+1);
                }
                g_bTeamInfectedVotedGameEvent = false;
                g_bTeamSurvivorVotedGameEvent = false;
            }
        } else {
            // survivors first
            if (!g_bTeamSurvivorVotedGameEvent) {
                g_bTeamSurvivorVotedGameEvent = true;
                PrintToChatAll("\x01[\x05r\x01] %N (Survivor) voted to pick event for \x03all rounds\x01: \x04%i\x01. \"%s\".", client, g_iPickGameEvent+1, g_csEventTextShort[g_iPickGameEvent] );
                PrintToChatAll("\x01[\x05r\x01] Infected can \x04!gameevent\x01 to accept (\"\x04!gameevent no\x01\" to decline.)");
            }
        }
    }
    else
    {
        if (g_bTeamSurvivorVotedGameEvent) {
            // infected respond
            if (!g_bTeamInfectedVotedGameEvent) {
                if (event == -1) {
                    // declined
                    PrintToChatAll("\x01[\x05r\x01] %N (Survivor) declined the game event pick.", client);
                } else {
                    // accepted
                    PrintToChatAll("\x01[\x05r\x01] %N (Survivor) accepted the game event. All rounds will have event \x04%i\x01.", client, g_iPickGameEvent+1);
                    SUPPORT_PickGameEvent(g_iPickGameEvent+1, -1);
                }
                g_bTeamInfectedVotedEvent = false;
                g_bTeamSurvivorVotedEvent = false;
            }
        } else {
            // Infected first
            if (!g_bTeamInfectedVotedGameEvent) {
                g_bTeamInfectedVotedGameEvent = true;
                PrintToChatAll("\x01[\x05r\x01] %N (Infected team) voted to pick event for \x03all rounds\x01: \x04%i\x01. \"%s\".", client, g_iPickGameEvent+1, g_csEventTextShort[g_iPickGameEvent] );
                PrintToChatAll("\x01[\x05r\x01] Survivors can \x04!gameevent\x01 to accept (\"\x04!gameevent no\x01\" to decline.)");
            }
        }
    }
}

SUPPORT_PickGameEvent(event, client=0)
{
    if (event < 1 || event > EVT_TOTAL)
    {
        if (client > 0) {
            PrintToChat(client, "\x01[\x05r\x01] Wrong event number: \x04%i\x01. For numbers go from \x041\x01 to \x04%i\x01. For a list, see http://www.tabun.nl/random/.", event, EVT_TOTAL);
        }
        return;
    }
    
    g_iPickGameEvent = event - 1;
    g_iSpecialEventToForceAlways = g_iPickGameEvent;
    
    if (client > 0)
    {
        // report to all
        PrintToChatAll("\x01[\x05r\x01] Admin forced event for \x03all rounds\x01: \x04%i\x01. \"%s\".", g_iPickGameEvent+1, g_csEventTextShort[g_iPickGameEvent] );
    }
    
    RestartMapDelayed();
}


// event list / menu
SUPPORT_ShowEventList(client)
{
    if (IsClientAndInGame(client))
    {
        decl String:sTempA[3];
        new Handle:menu = CreateMenu(EventListHandler);

        if (g_iEventMenu[client] == EVTMNU_INFO)
        {
            IntToString(0, sTempA, sizeof(sTempA));
            AddMenuItem(menu, sTempA, "Current Special Event");
        }
        
        for (new i = 0; i < EVT_TOTAL; i++)
        {
            IntToString(i+1, sTempA, sizeof(sTempA));
            AddMenuItem(menu, sTempA, g_csEventTextShort[i] );
        }

        switch(g_iEventMenu[client])
        {
            case EVTMNU_INFO: {
                SetMenuTitle(menu, "Get Info on Event:");
            }
            case EVTMNU_PICK, EVTMNU_PICKGAME: {
                SetMenuTitle(menu, "Pick Event:");
            }
        }
        SetMenuExitButton(menu, true);
        DisplayMenu(menu, client, MENU_TIME_FOREVER);
    }
}
public EventListHandler(Handle:menu, MenuAction:action, client, index)
{
    if (action == MenuAction_End)
    {
        CloseHandle(menu);
    }
    else if (action == MenuAction_Select)
    {
        decl String:sTemp[32];
        GetMenuItem(menu, index, sTemp, sizeof(sTemp));
        new event = StringToInt(sTemp);
        if (event == 0) { event = -1; }
        
        switch (g_iEventMenu[client])
        {
            case EVTMNU_INFO: {
                DoEventInfo(client, event);
            }
            case EVTMNU_PICK: {
                g_iPickEvent = event - 1;
                SUPPORT_VotePickEventChoose(event, client);
            }
            case EVTMNU_PICKGAME: {
                g_iPickGameEvent = event - 1;
                SUPPORT_VotePickGameEventChoose(event, client);
            }
        }
    }
}

// restarting maps
RestartMapDelayed()
{
    CreateTimer(DELAY_MAPRESTART, Timer_RestartMap, _, TIMER_FLAG_NO_MAPCHANGE);
    PrintToChatAll("\x01[\x05r\x01] Map restarting in \x04%.f\x01 seconds...", DELAY_MAPRESTART );
}
public Action:Timer_RestartMap(Handle:timer)
{
    decl String:currentMap[256];
    GetCurrentMap(currentMap, 256);
    ServerCommand("changelevel %s", currentMap);
}



/* Door Circus */

public SUPPORT_ToggleDoor( entity )
{
    new doorState = GetEntProp(entity, Prop_Data, "m_eDoorState");
    
    AcceptEntityInput(entity, "Unlock");
    if (doorState != 0) {   // closed
        AcceptEntityInput(entity, "Close");
    } else {
        AcceptEntityInput(entity, "Open");
    }
    AcceptEntityInput(entity, "Lock");
}

public Action:Timer_DoorCircus(Handle:timer)
{
    if (g_iSpecialEvent != EVT_DOORCIRCUS) {
        g_hDoorCircusTimer = INVALID_HANDLE;
        return Plugin_Stop;
    }
    
    if (g_bIsPaused || !g_bPlayersLeftStart)
    {
        return Plugin_Continue;
    }
    
    // tick counter(s) down
    // if counter is ready do something!
    new String:classname[64];
    
    for (new i=0; i < 3; i++) {
        
        g_iDoorCircusCount[i]--;
        
        if (g_iDoorCircusCount[i] >= 0 ) {
            continue;
        }
    
        // new time
        if ( !g_bDoorCircusState[i] ) {
            // how long to stay open?
            g_iDoorCircusCount[i] = GetRandomInt( DOORCIRC_MIN_OPEN, DOORCIRC_MAX_OPEN );
        } else {
            g_iDoorCircusCount[i] = GetRandomInt( DOORCIRC_MIN_OPEN, DOORCIRC_MAX_OPEN );
        }
        
        if (!g_bDoorCircusState[i]) {
            // true = open (or should be)
            g_bDoorCircusState[i] = true;
        } else {
            g_bDoorCircusState[i] = false;
        }

        for (new j=0; j < g_iDoorCircusTypeCount[i]; j++)
        {
            if (IsValidEntity( g_iDoorCircusType[i][j] )) {
                // just to be on the safe side:
                GetEdictClassname(g_iDoorCircusType[i][j], classname, sizeof(classname));
                if (StrEqual(classname, "prop_door_rotating")) {
                    SUPPORT_ToggleDoor( g_iDoorCircusType[i][j] );
                }
            }
        }
    }
    
    return Plugin_Continue;
}

/*  CRox multiwitch plugin
    ---------------------- */
public Action:Timer_WitchSpawn(Handle:timer)
{
    if (g_iSpecialEvent != EVT_WITCHES) {
        g_hWitchSpawnTimer = INVALID_HANDLE;
        return Plugin_Stop;
    }
    
    // stop spawning witches when the max is reached
    if (g_RC_iEventWitchesMaxWitches > 0 && g_iWitchesSpawned >= g_RC_iEventWitchesMaxWitches) {
        g_hWitchSpawnTimer = INVALID_HANDLE;
        return Plugin_Stop;
    }
    
    if (!g_bIsTankInPlay && !g_bIsPaused && g_bPlayersLeftStart && NoSurvivorInSaferoom())
    {
        for (new i=1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i))
            {
                g_iWitchesSpawned++;
                PrintDebug(5, "[rand] Witch Timer: spawning witch!");
                
                if (GetConVarBool(g_hCvarUseOldSpawn)) {
                    CheatCommand(i, "z_spawn_old", "witch auto");
                } else {
                    CheatCommand(i, "z_spawn", "witch auto");
                }
                return Plugin_Continue;
            }
        }
    }
    return Plugin_Continue;
}
public Action:Timer_WitchRespawn(Handle:timer)
{
    if (g_iSpecialEvent != EVT_WITCHES) { return Plugin_Stop; }
    
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
                        if (GetConVarBool(g_hCvarUseOldSpawn)) {
                            CheatCommand(i, "z_spawn_old", "witch auto");
                        } else {
                            CheatCommand(i, "z_spawn", "witch auto");
                        }
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





/*  L4D2 Storm plugin
    -------------------------- */
    
SUPPORT_StormReset()
{
    new Handle: hTmpCVar = FindConVar("l4d2_storm_allow");
    if (hTmpCVar != INVALID_HANDLE) {
        SetConVarInt(hTmpCVar, 0);
        ServerCommand("sm_stormreset");
        PrintDebug(2, "[rand] Stopped Storm");
    }
}

SUPPORT_StormStart()
{
    new Handle: hTmpCVar = FindConVar("l4d2_storm_allow");
    if (hTmpCVar != INVALID_HANDLE) {
        SetConVarInt(hTmpCVar, 1);
        ServerCommand("sm_stormrefresh");
        PrintDebug(2, "[rand] Started Storm");
    }
}










/*  // for debugging blindents
DoBlindEntReport()
{
    PrintDebug("[rand] Randomized item table, for %i items:", g_iStoredEntities);
    
    new String: tmpStr[64];
    new count = 0;
    
    PrintDebug("[rand] --------------- stored entity list -----------------");
    
    for (new i=0; i < g_iStoredEntities; i++)
    {
        // don't show stuff that won't be blinded
        if (g_strArStorage[i][entPickedType] == PCK_NOITEM) { continue; }
        if (g_strArStorage[i][entPickedType] == PCK_JUNK) { continue; }
        if (g_strArStorage[i][entPickedType] == PCK_EXPLOSIVE_BARREL) { continue; }
        if (g_strArStorage[i][entPickedType] == PCK_SILLY_GIFT) { continue; }
        
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
    PrintDebug(0, "[rand] Randomized item table, for %i items:", g_iStoredEntities);
    
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
        PrintDebug(0, "[rand] --------------- entity list -----------------");
    }
    
    g_iCountItemGnomes = 0;
    g_iCountItemCola = 0;
    g_iCountItemMedkits = 0;
    g_iCountItemDefibs = 0;
    
    for (new i=0; i < g_iStoredEntities; i++)
    {
        iItemCount[ g_strArStorage[i][entPickedType] ]++;
        
        // count towards group
        switch (g_strArStorage[i][entPickedType])
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
            PrintDebug(0, "  Item: %4i: entity %5i (= %s), classname: %s.", i, g_strArStorage[i][entNumber], g_csItemPickName[ g_strArStorage[i][entPickedType] ], tmpStr );
        }
    }
    
    if (full) { return; }
    
    iTotalRealItems = g_iStoredEntities - iItemCount[PCK_NOITEM];
    
    /*
    PrintDebug(0,"[rand] --------------- item list -----------------");
    
    PrintDebug( "  %18s: %4i ( %5.1f%% /        ).", "no item", iItemCount[0], float(iItemCount[0]) / float(g_iStoredEntities) * 100.0 );
    PrintDebug( "  %18s: %4i ( %5.1f%% /        ).", g_csItemPickName[PCK_JUNK], iItemCount[PCK_JUNK], float(iItemCount[PCK_JUNK]) / float(g_iStoredEntities) * 100.0 );
    PrintDebug("");
    
    for (new i=PCK_PISTOL; i < PCK_DUALS; i++)
    {
        if (i == PCK_JUNK) { continue; }
        PrintDebug( "  %18s: %4i ( %5.1f%% / %5.1f%% ).", g_csItemPickName[i], iItemCount[i], float(iItemCount[i]) / float(g_iStoredEntities) * 100.0, float(iItemCount[i]) / float(iTotalRealItems) * 100.0 );
    }
    */
    PrintDebug(0,"---------------------- type list --------------------------------------------------------- real items: %4i", iTotalRealItems);
    
    PrintDebug(0, "  %18s: %4i ( %5.1f%% /        ). Weighted at: %5.1f%%", "no item", iGroupCount[0], float(iGroupCount[0]) / float(g_iStoredEntities) * 100.0, float(iWeight[0]) / float(iTotalWeight) * 100.0 );
    PrintDebug(0, "  %18s: %4i ( %5.1f%% /        ). Weighted at: %5.1f%%", g_csItemTypeText[INDEX_JUNK], iGroupCount[INDEX_JUNK], float(iGroupCount[INDEX_JUNK]) / float(g_iStoredEntities) * 100.0, float(iWeight[INDEX_JUNK]) / float(iTotalWeight) * 100.0, float(iWeight[INDEX_JUNK]) / float(iTotalWeight) * 100.0  );
    PrintDebug(0, "-----------------------------------------------------------------------------------------------------------");
    
    iTotalWeight = (iTotalWeight - iWeight[0]) - iWeight[INDEX_JUNK];
    
    for (new i=INDEX_PISTOL; i < INDEX_TOTAL; i++)
    {
        if (i == INDEX_JUNK) { continue; }
        PrintDebug(0, "  %18s: %4i ( %5.1f%% / %5.1f%% ). Weighted at: %5.1f%%, expected occurrence: %3i (diff.: %3i).",
                g_csItemTypeText[i], iGroupCount[i],
                float(iGroupCount[i]) / float(g_iStoredEntities) * 100.0, float(iGroupCount[i]) / float(iTotalRealItems) * 100.0,
                float(iWeight[i]) / float(iTotalWeight) * 100.0,
                RoundFloat( (float(iWeight[i]) / float(iTotalWeight)) * iTotalRealItems ),
                iGroupCount[i] - RoundFloat( (float(iWeight[i]) / float(iTotalWeight)) * iTotalRealItems )
            );
    }
    
    PrintDebug(0, "-----------------------------------------------------------------------------------------------------------");
    
}

DoGnomesServerReport()
{
    if (!g_iGnomes) {
        PrintDebug(0, "[rand] no gnomes this map, not displaying table.");
        return;
    }
    
    PrintDebug(0, "[rand] gnomes table for %i gnomes/cola:", g_iGnomes);
    
    new String: tmpStr[64];
    new String: tmpStrB[64];
    
    PrintDebug(0, "-----------------------------------------------------------------------------------------------------------");
    PrintDebug(0, "    #   g or c  status           entity  picked up?  worth points?  accounted for?");
    PrintDebug(0, "-----------------------------------------------------------------------------------------------------------");
    
    for (new i=0; i < g_iGnomes; i++)
    {
        if (g_strArGnomes[i][gnomebHeldByPlayer]) {
            Format(tmpStr, sizeof(tmpStr), "held (by %i)", g_strArGnomes[i][gnomeiHoldingClient]);
        } else {
            Format(tmpStr, sizeof(tmpStr), "lying around");
        }
        
        if (g_strArGnomes[i][gnomebFirstPickup]) {
            Format(tmpStrB, sizeof(tmpStrB), "yes (%1.2f)", g_strArGnomes[i][gnomefFirstPickup]);
        } else {
            Format(tmpStrB, sizeof(tmpStrB), "no");
        }
        
        PrintDebug(0, "  %3i.: %5s  %15s  %4i     %10s  %13s  %4s",
                i,
                (g_strArGnomes[i][gnomebIsCola]) ? "cola" : "gnome",
                tmpStr,
                g_strArGnomes[i][gnomeEntity],
                tmpStrB,
                (g_strArGnomes[i][gnomebWorthPoints]) ? "yes" : "no",
                (g_strArGnomes[i][gnomebAccountedFor]) ? "yes" : "no"
            );
    }
    
    PrintDebug(0, "-----------------------------------------------------------------------------------------------------------");
    
}