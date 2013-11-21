#pragma semicolon 1
#include <sourcemod>


// called as timer (to avoid some problems)
public Action: SUPPORT_RoundPreparation(Handle:timer)
{
    // only reset on first roundhalf:
    if (!g_bSecondHalf || (g_bCampaignMode && g_bCampaignForceRandom))
    {
        g_bStripperAltDetected = false;
        SetConVarInt(FindConVar("sv_force_time_of_day"), -1);
        RNDBNS_SetScaleMode( GetConVarInt(g_hCvarRandBonusScaleMode) );
    }
    
    // only reset on first roundhalf or if event's not equal
    if (!g_bSecondHalf || !(GetConVarInt(g_hCvarEqual) & EQ_EVENT)  || (g_bCampaignMode && g_bCampaignForceRandom))
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
    
    if (!g_bSecondHalf || !(GetConVarInt(g_hCvarEqual) & EQ_TANKS) || (g_bCampaignMode && g_bCampaignForceRandom))
    {
        g_bTankFirstRound = false;
        g_bWitchFirstRound = false;
    }
    
    if ( g_bFrozenPoints )
    {
        SUPPORT_UnFreezePoints();
    }
    
    // don't start horde yet (SetHordeTimer() does this)
    SetConVarInt(FindConVar("z_mob_spawn_min_interval_normal"), STARTING_HORDE_TIMER);
    SetConVarInt(FindConVar("z_mob_spawn_max_interval_normal"), STARTING_HORDE_TIMER);
    
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
    
    g_bTeamSurvivorVotedEvent = false;      // for picking an event for next round
    g_bTeamInfectedVotedEvent = false;
    g_bTeamSurvivorVotedGameEvent = false;  // for picking an event for entire game
    g_bTeamInfectedVotedGameEvent = false;
    g_fPickEventTimeout = 0.0;
    g_iPickEvent = -1;
    g_iPickGameEvent = -1;
    
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
    ClearSpecialRoleMemory();           // forget who had / should have the special role
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
    
    if ( !g_bSecondHalf || !(GetConVarInt(g_hCvarEqual) & EQ_ITEMS) || (g_bCampaignMode && g_bCampaignForceRandom) ) {
        RandomizeItems();
    } else {
        RestoreItems();
    }
    
    // some special event stuff that can't be done earlier
    if (g_iSpecialEvent == EVT_BOOBYTRAP)
    {
        EVENT_PickBoobyTraps();
    }
    
    // coop mode: set health to a minimum value
    if ( g_bCampaignMode ) {
        SetMinimumHealthSurvivors();
    }
    
    // blind infected to items generated
    ItemsBlindInfected();
    
    // output debug info about gnomes
    DoGnomesServerReport();
    
    // call 'all loaded in' on second roundhalf
    if ( g_bSecondHalf )
    {
        EVENT_AllSurvivorsLoadedIn();
    }
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
        g_fWomenBoomCharged[i] = 0.0;
    }
    
    for (new i=ZC_SMOKER; i <= ZC_CHARGER; i++)
    {
        g_iClassTimeout[i] = 0;
    }
    
    for (new i=0; i < MAX_CHARACTERS; i++)
    {
        g_fGiftBlindTime[i] = 0.0;
        g_bPlayerIncapNoSecondary[i] = false;
    }
    
    // arrays for ZC / class changing code
    InitSpawnArrays();
}


public InitSpawnArrays()
{
    for (new i=1; i <= MaxClients; i++)
    {
        g_bHasGhost[i] = false;
        g_bHasSpawned[i] = false;
        g_bSpectateDeath[i] = false;
    }
}

// Event functions
// ---------------
// whenever PBONUS changes
EVENT_PBonusChanged()
{
    if ( !g_bInRound ) { return; }
    // transfer current bonus to random bonus plugin, so it can display it
    RNDBNS_SetPenaltyBonus( PBONUS_GetRoundBonus() );
}

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
    g_iActiveAmmoSniper = GetConVarInt(g_hCvarAmmoSniper);
    g_iActiveAmmoScout = GetConVarInt(g_hCvarAmmoScout);
    g_iActiveAmmoAWP = GetConVarInt(g_hCvarAmmoAWP);
    
    SetConVarFloat(FindConVar("survivor_friendly_fire_factor_normal"), g_fDefFFFactor);
    SetConVarInt(FindConVar("z_tank_health"), g_iDefTankHealth);
    SetConVarInt(FindConVar("z_frustration_lifetime"), g_iDefTankFrustTime);
    SetConVarInt(FindConVar("vs_tank_damage"), g_iDefTankDamage);
    SetConVarFloat(FindConVar("versus_tank_flow_team_variation"), g_fDefTankFlowVariation);
    
    SetConVarInt(FindConVar("z_vomit_interval"), g_iDefVomitInterval);
    SetConVarInt(FindConVar("z_spit_interval"), g_iDefSpitInterval);
    
    SetConVarInt(FindConVar("boomer_pz_claw_dmg"), Z_EXPL_CLAW);
    SetConVarInt(FindConVar("spitter_pz_claw_dmg"), Z_EXPL_CLAW);
    SetConVarInt(FindConVar("z_exploding_speed"), Z_EXPL_SPEED);
    SetConVarInt(FindConVar("z_exploding_force"), Z_EXPL_FORCE);
    SetConVarInt(FindConVar("z_exploding_inner_radius"), Z_EXPL_RADIUS_IN);
    SetConVarInt(FindConVar("z_exploding_outer_radius"), Z_EXPL_RADIUS_OUT);
    SetConVarInt(FindConVar("z_spitter_speed"), Z_SPIT_SPEED);
    SetConVarInt(FindConVar("z_exploding_shove_min"), Z_EXPL_SHOVE_MIN);
    SetConVarInt(FindConVar("z_exploding_shove_max"), Z_EXPL_SHOVE_MAX);
    
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
    
    g_iHordeTimeMin = g_iDefHordeTimeMin;
    g_iHordeTimeMax = g_iDefHordeTimeMax;
    
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
            g_iHordeTimeMin = RoundFloat(float(g_iDefHordeTimeMin) / g_RC_fEventCILimVeryEasy);
            g_iHordeTimeMax = RoundFloat(float(g_iDefHordeTimeMax) / g_RC_fEventCILimVeryEasy);
        }
        
        case DIFFICULTY_VERYEASY: {
            SetConVarInt(FindConVar("z_common_limit"), RoundFloat(float(g_iDefCommonLimit) * g_RC_fEventCILimVeryEasy));
            SetConVarInt(FindConVar("z_background_limit"), RoundFloat(float(g_iDefBackgroundLimit) * g_RC_fEventCILimVeryEasy));
            SetConVarInt(FindConVar("z_mob_spawn_min_size"), RoundFloat(float(g_iDefHordeSizeMin) * g_RC_fEventCILimVeryEasy));
            SetConVarInt(FindConVar("z_mob_spawn_max_size"), RoundFloat(float(g_iDefHordeSizeMax) * g_RC_fEventCILimVeryEasy));
            g_iHordeTimeMin = RoundFloat(float(g_iDefHordeTimeMin) / g_RC_fEventCILimEasy);
            g_iHordeTimeMax = RoundFloat(float(g_iDefHordeTimeMax) / g_RC_fEventCILimEasy);
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
            g_iHordeTimeMax = RoundFloat(float(g_iDefHordeTimeMax) / g_RC_fEventCILimHard);
        }
        
        case DIFFICULTY_VERYHARD: {
            SetConVarInt(FindConVar("z_common_limit"), RoundFloat(float(g_iDefCommonLimit) * g_RC_fEventCILimVeryHard));
            SetConVarInt(FindConVar("z_background_limit"), RoundFloat(float(g_iDefBackgroundLimit) * g_RC_fEventCILimVeryHard));
            SetConVarInt(FindConVar("z_mob_spawn_min_size"), RoundFloat(float(g_iDefHordeSizeMin) * g_RC_fEventCILimVeryHard));
            SetConVarInt(FindConVar("z_mob_spawn_max_size"), RoundFloat(float(g_iDefHordeSizeMax) * g_RC_fEventCILimVeryHard));
            g_iHordeTimeMin = RoundFloat(float(g_iDefHordeTimeMin) / g_RC_fEventCILimVeryHard);
            g_iHordeTimeMax = RoundFloat(float(g_iDefHordeTimeMax) / g_RC_fEventCILimVeryHard);
        }
    }
}

// set the horde timer to the proper values (for when round goes live)
SetHordeTimer()
{
    SetConVarInt(FindConVar("z_mob_spawn_min_interval_normal"), g_iHordeTimeMin);
    SetConVarInt(FindConVar("z_mob_spawn_max_interval_normal"), g_iHordeTimeMax);
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
            g_hDoorCircusTimer = CreateTimer(1.0, Timer_DoorCircus, _, TIMER_REPEAT);
        }
    }
}

EVENT_AllSurvivorsLoadedIn()
{
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
            if ( !EVENT_IsSpecialRoleOkay() ) {
                EVENT_PickSpecialEventRole(-1, false);
            } else {
                ReportSpecialEventRole();
            }
            SetSpecialRoleMemory(g_iSpecialEventRole);
        }
        
        case EVT_PROTECT: {
            // first time baby gets picked with a visible report
            if (!EVENT_IsSpecialRoleOkay()) {
                EVENT_PickSpecialEventRole(-1, false);
            } else {
                ReportSpecialEventRole();
            }
            SetSpecialRoleMemory(g_iSpecialEventRole);
        }
        
        case EVT_MEDIC: {
            // first time medic gets picked with a visible report
            if (!EVENT_IsSpecialRoleOkay()) {
                EVENT_PickSpecialEventRole(-1, false);
            } else {
                ReportSpecialEventRole();
            }
            SetSpecialRoleMemory(g_iSpecialEventRole);
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
            SetSpecialRoleMemory(g_iSpecialEventRole);
        }
        
    }
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







EVENT_HandleSkeet( skeeter=-1, victim=-1, meleeSkeet=false, sniperSkeet=false )
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
            if (IsClientAndInGame(victim) && !IsFakeClient(victim)) {
                PrintToChatAll("\x01[\x05r\x01] \x05%N\x01 was team-skeeted for \x04%i\x01 points.", victim, g_RC_iEventBonusSkeetTeam);
            } else {
                PrintToChatAll("\x01[\x05r\x01] A hunter was team-skeeted for \x04%i\x01 points.", g_RC_iEventBonusSkeetTeam);
            }
        }
        else if ( IsClientAndInGame(skeeter) && IsClientAndInGame(victim) && !IsFakeClient(victim) ) {
            PrintToChatAll("\x01[\x05r\x01] \x04%N\x01 %sskeeted \x05%N\x01 for \x04%i\x01 points.", skeeter, (meleeSkeet) ? "melee-": ((sniperSkeet) ? "headshot-" : ""), victim, g_RC_iEventBonusSkeet);
        }
        else if ( IsClientAndInGame(skeeter) ) {
            PrintToChatAll("\x01[\x05r\x01] \x04%N\x01 %sskeeted a hunter for \x04%i\x01 points.", skeeter, (meleeSkeet) ? "melee-": ((sniperSkeet) ? "headshot-" : ""), g_RC_iEventBonusSkeet);
        }
        else if (IsClientAndInGame(victim)) {
            PrintToChatAll("\x01[\x05r\x01] \x05%N\x01 was %sskeeted for \x04%i\x01 points.", victim, (meleeSkeet) ? "melee-": ((sniperSkeet) ? "headshot-" : ""), g_RC_iEventBonusSkeet);
        }
        else {
            PrintToChatAll("\x01[\x05r\x01] A hunter was %sskeeted for \x04%i\x01 points.", (meleeSkeet) ? "melee-": ((sniperSkeet) ? "headshot-" : ""), g_RC_iEventBonusSkeet);
        }
    }
    else
    {
        // only report
        if (skeeter == -2) {    // team skeet sets to -2
            if (IsClientAndInGame(victim) && !IsFakeClient(victim)) {
                PrintToChatAll("\x01[\x05r\x01] \x05%N\x01 was team-skeeted.", victim);
            } else {
                PrintToChatAll("\x01[\x05r\x01] A hunter was team-skeeted.");
            }
        }
        else if (IsClientAndInGame(skeeter) && IsClientAndInGame(victim) && !IsFakeClient(victim)) {
            PrintToChatAll("\x01[\x05r\x01] \x04%N\x01 %sskeeted \x05%N\x01.", skeeter, (meleeSkeet) ? "melee-": ((sniperSkeet) ? "headshot-" : ""), victim);
        }
        else if (IsClientAndInGame(skeeter)) {
            PrintToChatAll("\x01[\x05r\x01] \x04%N\x01 %sskeeted a hunter.", skeeter, (meleeSkeet) ? "melee-": ((sniperSkeet) ? "headshot-" : "") );
        }
    }
}
EVENT_HandleNonSkeet( victim, damage, bool:bOverKill=false )
{
    //if (g_iSpecialEvent == EVT_SKEET)
    //{
        if ( IsClientAndInGame(victim) && !IsFakeClient(victim) ) {
            PrintToChatAll("\x01[\x05r\x01] \x05%N\x01 was \x04not\x01 skeeted (\x03%i\x01 damage).%s", victim, damage, (bOverKill) ? "(Would've been a skeet if hunter had not been chipped!)" : "" );
        }
        else {
            PrintToChatAll("\x01[\x05r\x01] Hunter was \x04not\x01 skeeted (\x03%i\x01 damage).%s", damage, (bOverKill) ? "(Would've been a skeet if hunter had not been chipped!)" : "" );
        }
    //}
}



// special roles for special events
public Action: Timer_CheckSpecialEventRole(Handle:timer, any:pack)
{
    g_bSpecialRoleAboutToChange = false;
    
    // read datapack: survivorsLeftSaferoom; client
    ResetPack(pack);
    new bool: leftStart = bool: ReadPackCell(pack);
    new bool: playerAction = bool: ReadPackCell(pack);      // whether it happened by the player doing something
    //new client = ReadPackCell(pack);
    CloseHandle(pack);
    

    // check here for other events (whether bots have stuff they shouldn't have)
    if (g_iSpecialEvent == EVT_AMMO)
    {
        // upgrade kit should not be in possession of bot
        for (new i=1; i <= MaxClients; i++)
        {
            if ( IsSurvivor(i) && IsFakeClient(i) )
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
            if ( IsSurvivor(i) && !IsFakeClient(i) && IsPlayerAlive(i) )
            { 
                bNoHumanSurvivors = false;
                break;
            }
        }
        
        // force new role if the current role's survivor is missing, dead or a bot when there's humans available:
        if ( !IsSurvivor(g_iSpecialEventRole) || !IsPlayerAlive(g_iSpecialEventRole) || ( IsFakeClient(g_iSpecialEventRole) && !bNoHumanSurvivors ) )
        {
            g_iSpecialEventRole = 0;
        }
        
        if ( !g_iSpecialEventRole )
        {
            EVENT_PickSpecialEventRole( -1, (leftStart) ? false : true, (playerAction) ? false : true );
        }
    }
}

EVENT_PickSpecialEventRole( notClient=-1, bool:notLeftStart=false, bool:gameChoice=true )
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
    
    PrintDebug(3, "[rand] Picked event role: %i (%N). (by game: %i)", g_iSpecialEventRole, g_iSpecialEventRole, gameChoice);
    
    // if it was the game that decided the role should switch, add the player to the memory
    if ( gameChoice && !IsFakeClient(g_iSpecialEventRole) )
    {
        // check if it was already in the memory, otherwise add
        SetSpecialRoleMemory(g_iSpecialEventRole);
    }

    
    // give correct hat to picked survivor
    switch (g_iSpecialEvent)
    {
        case EVT_PROTECT: {     CreateHat(g_iSpecialEventRole, HAT_BABY); }
        case EVT_KEYMASTER: {   CreateHat(g_iSpecialEventRole, HAT_KEYMASTER); }
        case EVT_MEDIC: {       CreateHat(g_iSpecialEventRole, HAT_MEDIC); }
        case EVT_BOOMFLU: {     CreateHat(g_iSpecialEventRole, HAT_BOOMFLU); }
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

// give special role back to player who should have it
public Action: Timer_ForceSpecialEventRole(Handle:timer, any:client)
{
    if ( !IsClientAndInGame(client) || !IsSurvivor(client) || !IsPlayerAlive(client) || IsFakeClient(client) || g_iSpecialEvent == -1 ) { return Plugin_Continue; }
    
    // check if it's already in order
    if ( g_iSpecialEventRole == client ) { return Plugin_Continue; }
    
    // else, force it
    g_iSpecialEventRole = client;
    
    PrintDebug(2, "[rand] Forcing event role (back) to %i (%N).", client, client);
    
    // fix hats
    HatsRemoveAll();
    switch (g_iSpecialEvent)
    {
        case EVT_PROTECT: {     CreateHat(g_iSpecialEventRole, HAT_BABY); }
        case EVT_KEYMASTER: {   CreateHat(g_iSpecialEventRole, HAT_KEYMASTER); }
        case EVT_MEDIC: {       CreateHat(g_iSpecialEventRole, HAT_MEDIC); }
        case EVT_BOOMFLU: {     CreateHat(g_iSpecialEventRole, HAT_BOOMFLU); }
    }
    
    // when picked, do a medic check
    if (g_iSpecialEvent == EVT_MEDIC)
    {
        EVENT_CheckMedic(true);
    }
    
    // report if it's after the saferoom exit (notLeftStart is for timer calls)
    if ( g_bPlayersLeftStart )
    {
        ReportSpecialEventRole();
    }
    
    return Plugin_Continue;
}

// remember who has special role
SetSpecialRoleMemory( client )
{
    if ( !IsClientAndInGame(client) || !IsSurvivor(client) || !IsPlayerAlive(client) || IsFakeClient(client) ) { return; }
    
    if ( !CheckSpecialRoleMemory(client) )
    {
        GetClientAuthString( client, g_sArHadRoleId[g_iHadRoleCount], 32 );
        g_iHadRoleCount++;
    }
}
// forget who should have special role
ClearSpecialRoleMemory()
{
    g_iHadRoleCount = 0;
}

// returns true if the client should have the special role
// (should be called whenever a client enters the survivor team during a special role event round)
bool: CheckSpecialRoleMemory( client, bool:dontEmpty=false )
{
    if ( !IsClientAndInGame(client) || IsFakeClient(client) || !g_iHadRoleCount ) { return false; }
    
    decl String: sSteamId[32];
    GetClientAuthString( client, sSteamId, 32 );
    
    for ( new i = 0; i < g_iHadRoleCount; i++ )
    {
        if ( StrEqual( sSteamId, g_sArHadRoleId[i], false) )
        {
            // found them
            if ( !dontEmpty) { g_iHadRoleCount = i+1; }
            return true;
        }
    }
    
    return false;
}

bool: EVENT_IsSpecialRoleOkay( bool:allowBots=false )
{
    // check if a living survivor has the special role
    if ( g_iSpecialEventRole < 1 ) { return false; }
    
    if (    !IsClientAndInGame(g_iSpecialEventRole)
        ||  !IsSurvivor(g_iSpecialEventRole)
        ||  !IsPlayerAlive(g_iSpecialEventRole)
        ||  ( !allowBots && IsFakeClient(g_iSpecialEventRole) )
    ) {
        return false;
    }
    
    return true;
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

PickTankPlayer()
{
    // randomly pick one
    
    new pick = 0;
    new pickCount = 0;
    new pickArray[96];
    new tickets = 5;
    new playerCount = 0;
    new round = GameRules_GetProp("m_bAreTeamsFlipped", 4, 0);
    
    decl String: sSteamId[32];
    new tankCount;
    
    for (new i=1; i < MaxClients+1; i++)
    {
        if ( IsInfected(i) && !IsFakeClient(i) )
        {
            playerCount++;
            
            GetClientAuthString( i, sSteamId, sizeof(sSteamId) );
            
            if ( !GetTrieValue(g_hTrieTankPlayers, sSteamId, tankCount) ) { tankCount = 0; }
            
            // if the player had the previous tank, exclude him from the next pick
            if ( StrEqual( g_sPreviousTankClient[ round ], sSteamId, false) )
            {
                PrintDebug(3, "[rand tank] Prevented tank pick for %N (had the last tank).", i);
                continue;
            }
            
            // if you didn't get one before, 5 entries
            tickets = 10;
            
            // -4 per tank you had. otherwise, scratch one, minimum of 1
            if ( tankCount > 0 ) { tickets -= 2 * tankCount; }
            if ( tickets < 1 ) { tickets = 1; }
            
            for ( new j=0; j < tickets; j++ )
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
    
    pick = GetRandomInt( 0, pickCount - 1 );
    pick = pickArray[pick];
    
    
    
    PrintDebug(3, "[rand tank] Randomly picking tank player %i (%N).", pick, pick);
    
    if ( IsClientAndInGame(pick) && !IsFakeClient(pick) ) {
        GetClientAuthString( pick, sSteamId, sizeof(sSteamId) );
        
        PrintDebug(4, "[rand tank] Previous tank stored: %i for team %i ...", pick, round);
        strcopy( g_sPreviousTankClient[ round ], 32, sSteamId );
    } else {
        PrintDebug(4, "[rand tank] NO previous tank stored: %i for team %i ...", pick, round);
        g_sPreviousTankClient[ round ] = "";
    }
    
    return pick;
}

ForceTankPlayer()
{
    // randomly pick a tank player
    new tank = PickTankPlayer();
    
    if (tank == 0) { return; }
    
    if ( IsClientAndInGame(tank) )
    {
        decl String: sSteamId[32];
        new tankCount;
        GetClientAuthString( tank, sSteamId, sizeof(sSteamId) );
        
        if ( !GetTrieValue(g_hTrieTankPlayers, sSteamId, tankCount) )
        {
            tankCount = 0;
        }
        tankCount++;
        
        SetTrieValue(g_hTrieTankPlayers, sSteamId, tankCount);
    }
    
    
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




/*  votes
    ------------ */

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
    
    // check if it is okay for the next map...
    if ( !IsEventOkayForMap( g_sNextMap, event ) )
    {
        PrintToChat( client, "\x01[\x05r\x01] Can't pick this event for the next map ('\x05%s\x01') (or in this game mode). Try another.", g_sNextMap );
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
    
    if ( !IsEventOkayForMap( g_sNextMap, event ) )
    {
        PrintToChat( client, "\x01[\x05r\x01] \x04Warning\x01, this event is unsuited for the next map ('\x05%s\x01') (or in this game mode). Don't complain if it bugs out!", g_sNextMap );
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





/*  L4D2 Storm plugin
    -------------------------- */
    
SUPPORT_StormReset()
{
    new Handle: hTmpCVar = FindConVar("l4d2_storm_allow");
    if (hTmpCVar != INVALID_HANDLE) {
        SetConVarInt(hTmpCVar, 0);
        ServerCommand("sm_stormreset");
        PrintDebug(6, "[rand] Stopped Storm");
    }
}

SUPPORT_StormStart()
{
    new Handle: hTmpCVar = FindConVar("l4d2_storm_allow");
    if (hTmpCVar != INVALID_HANDLE) {
        SetConVarInt(hTmpCVar, 1);
        ServerCommand("sm_stormrefresh");
        PrintDebug(6, "[rand] Started Storm");
    }
}










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