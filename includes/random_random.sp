#pragma semicolon 1
#include <sourcemod>


#define FIRE_EXT_SPRAY          "extinguisher_spray"

/*
    All the super-interesting random stuff goes in here
    (for easier finding / editing
*/


// Report randomness
// --------------------------
DoWelcomeMessage(client)
{
    if (!IsClientAndInGame(client) || IsFakeClient(client)) { return; }
    
    //PrintHintText(client, "%s", "Welcome to \x04Random\x01. For help, type \x03!help\x01 in chat.");

    PrintToChat(client, "\x01[\x05r\x01] \x05Welcome to \x03Random\x05. Type \x03!info\x05 in chat for help.");
    PrintToChat(client, "\x01[\x05r\x01] \x05Visit: \x03http://www.tabun.nl/random\x05 for more information.");
}

DoHelpMessage(client)
{
    if (!IsClientAndInGame(client) || IsFakeClient(client)) { return; }
    
    
    PrintToChat(client, "\x03Random\x05: Map items are randomized%s.", (GetConVarInt(g_hCvarEqual) & EQ_ITEMS) ? " but equal between teams" : " and will be different for each team" );
    
    if (GetConVarBool(g_hCvarRandomSpawns)) {
        PrintToChat(client, "\x05Special Infected classes are random and unlimited (any combination is possible).");
    }
    if (GetConVarFloat(g_hCvarSpecialEventChance) > 0.0) {
        PrintToChat(client, "\x05There may be a 'special event' that lasts one round.");
    }
    if (GetConVarInt(g_hArCvarWeight[INDEX_GIFT]) > 0)  {
        PrintToChat(client, "\x05You can find Random gifts that may be opened by holding the USE key.");
    }
    
    PrintToChat(client, "\x05Commands you can type in chat: \x04!rand\x05, \x04!damage\x05, \x04!bonus\x05 and \x04!drop\x01. ");
    PrintToChat(client, "\x05Visit: \x03http://www.tabun.nl/random\x05 for more information.");
}

DoReport(client=0)
{
    new String: sReport[MAX_REPORTLINES][REPLINELENGTH];
    new iLine = 0;
    
    if (!g_bCampaignMode)
    {
        // report distance / bonus changes
        if (GetConVarInt(g_hCvarRandDistance) > 0 && GetConVarInt(g_hCvarRandBonus) > 0) {
            Format(sReport[iLine], REPLINELENGTH, "Random map distance: \x05%i\x01, Bonus: \x04%i\x01.", L4D_GetVersusMaxCompletionScore(), g_iDamageBonus);
            iLine++;
        } else if (GetConVarInt(g_hCvarRandDistance) > 0) {
            Format(sReport[iLine], REPLINELENGTH, "Random map distance: \x05%i\x01.", L4D_GetVersusMaxCompletionScore());
            iLine++;
        } else if (GetConVarInt(g_hCvarRandBonus) > 0) {
            Format(sReport[iLine], REPLINELENGTH, "Random damage bonus: \x04%i\x01.", g_iDamageBonus);
            iLine++;
        }
    }
    
    // report glows (only when gone?)
    if (GetConVarFloat(g_hCvarOutlineChance) < 1.0) {
        if (!g_bGlows) {
            Format(sReport[iLine], REPLINELENGTH, "Survivor glows \x04off\x01!");
            iLine++;
        }
    }
    
    // report incaps
    Format(sReport[iLine], REPLINELENGTH, "Incaps before b/w: \x05%i\x01.", g_iIncaps);
    iLine++;
    
    // report double tanks
    if (g_bDoubleTank) {
        Format(sReport[iLine], REPLINELENGTH, "\x04Two tanks\x01 will spawn!");
        iLine++;
    }
    
    // report multi-witches
    if (g_bMultiWitch) {
        Format(sReport[iLine], REPLINELENGTH, "\x04Multiple witches\x01 will spawn!");
        iLine++;
    }
    
    // harder map path?
    if (g_bStripperAltDetected)
    {
        Format(sReport[iLine], REPLINELENGTH, "This round has \x04harder map pathing\x01!");
        iLine++;
    }
    
    // report special event, if any
    if (g_iSpecialEvent != -1)
    {
        if (g_iSpecialEvent == _:EVT_WOMEN) {
            switch (_:g_iSpecialEventExtra)
            {
                case EVTWOMEN_TYPE_AXE:     { Format(sReport[iLine], REPLINELENGTH, "\x03Special Event\x01! \x04Axe Effect\x01 - deal with the crazy women."); }
                case EVTWOMEN_TYPE_ROCK:    { Format(sReport[iLine], REPLINELENGTH, "\x03Special Event\x01! \x04Rock Stars\x01 - deal with the crazy groupies."); }
                default:                    { Format(sReport[iLine], REPLINELENGTH, "\x03Special Event\x01! \x04Wifebeaters\x01 - it's not right, but you have no choice."); }
            }
        }
        else if (g_iSpecialEvent == _:EVT_ITEM) {
            Format(sReport[iLine], REPLINELENGTH, "\x03Special Event\x01! %s%s.", g_csEventText[g_iSpecialEvent], g_csItemTypeText[g_iSpecialEventExtra] );
        }
        else if (g_iSpecialEvent == _:EVT_SILENCE) {
            Format(sReport[iLine], REPLINELENGTH, "\x03Special Event\x01! %s%s.", g_csEventText[g_iSpecialEvent], (g_iSpecialEventExtra == SILENCED_SI) ? "special infected" : "survivors" );
        }
        else if (g_iSpecialEvent == _:EVT_WEATHER && g_RI_iNoStorm == 2) {
            Format(sReport[iLine], REPLINELENGTH, "\x03Special Event\x01! \x04Eerie Harvest\x01 - special weather...");
        }
        else {
            Format(sReport[iLine], REPLINELENGTH, "\x03Special Event\x01! %s", g_csEventText[g_iSpecialEvent]);
        }
        iLine++;
    }
    
    // report special info for some tricky events
    if (_:g_iSpecialEvent == EVT_AMMO)
    {
        Format(sReport[iLine], REPLINELENGTH, "Deploy your ammo pack to make an ammo pile. Hold the USE key to repack the ammo. Don't forget to bring it along!");
        iLine++;
    }
    
    // send the report
    for (new i=0; i < iLine; i++)
    {
        if (client) {
            PrintToChat(client, "\x01[\x05r\x01] %s", sReport[i]);
        } else {
            PrintToChatAll("\x01[\x05r\x01] %s", sReport[i]);
        }
    }
    
    // special event role (prevent spamming this at start)
    if (g_bFirstReportDone && g_bPlayersLeftStart) {
        ReportSpecialEventRole(false, client);
    }
}

DoInsightReport(team=-1)
{
    new String: sReport[MAX_REPORTLINES][REPLINELENGTH];
    new iLine = 0;
    
    
    // whether tank will spawn
    if (g_bTankWillSpawn)
    {
        new Float: tankFlows[2];
        L4D2_GetVersusTankFlowPercent(tankFlows);
        
        if (g_bDoubleTank) {
            Format(sReport[iLine], REPLINELENGTH, "There are \x05two\x01 tanks this round, at \x05%d%%\x01 and \x05%d%%\x01.", RoundFloat(100.0 * g_fTankFlowEarly), RoundFloat(100.0 * g_fTankFlowLate));
        } else {
            Format(sReport[iLine], REPLINELENGTH, "There is tank this round, at \x05%d%%\x01.", RoundFloat(100.0 * tankFlows[ (g_bSecondHalf) ? 1 : 0 ]) );
        }
    } else {
        Format(sReport[iLine], REPLINELENGTH, "No tank this round.");
    }
    iLine++;
    
    if (g_bMultiWitch && g_iWitchNum > 1) {
        Format(sReport[iLine], REPLINELENGTH, "There are \x05%d\x01 witches this round. The first is at \x05%d%%\x01, the last at \x05%d%%\x01.", g_iWitchNum, RoundFloat(100.0 * g_fArWitchFlows[0]), RoundFloat(100.0 * g_fArWitchFlows[ g_iWitchNum - 1 ] ) );
    } else if (g_bWitchWillSpawn) {
        Format(sReport[iLine], REPLINELENGTH, "There is a witch this round, at \x05%d%%\x01.", RoundFloat(100.0 * L4D2Direct_GetVSWitchFlowPercent( (g_bSecondHalf) ? 1 : 0 ) ) );
    } else {
        Format(sReport[iLine], REPLINELENGTH, "No witch this round.");
    }
    iLine++;
    
    if (!g_bCampaignMode)
    {
        // gnomes / cola
        Format(sReport[iLine], REPLINELENGTH, "Bonus items: \x05%d\x01 gnome%s and \x05%d\x01 cola pack%s.", g_iCountItemGnomes, (g_iCountItemGnomes == 1) ? "" : "s", g_iCountItemCola, (g_iCountItemCola == 1) ? "" : "s" );
        iLine++;
    }
    
    // medkits / defibs
    if (!g_bNoHealthItems) {
        Format(sReport[iLine], REPLINELENGTH, "Health items: \x05%d\x01 first aid kit%s and \x05%d\x01 defib%s.", g_iCountItemMedkits, (g_iCountItemMedkits == 1) ? "" : "s", g_iCountItemDefibs, (g_iCountItemDefibs == 1) ? "" : "s" );
        iLine++;
    }
    
    // send the report
    for (new i=0; i < iLine; i++)
    {
        if (team != -1) {
            for (new j=1; j <= MaxClients; j++)
            {
                if ( (team == TEAM_SURVIVOR && IsSurvivor(j)) || (team == TEAM_INFECTED && IsInfected(j)) && !IsFakeClient(j))
                {
                    PrintToChat(j, "\x01[\x05r\x01] %s", sReport[i]);
                }
            }
        } else {
            PrintToChatAll("\x01[\x05r\x01] %s", sReport[i]);
        }
    }
}

ReportSpecialEventRole(bool:isNew=false, client=0)
{
    new String: sReport[REPLINELENGTH] = "";
    
    switch (_:g_iSpecialEvent)
    {
        case EVT_KEYMASTER: {
            Format(sReport, REPLINELENGTH, "%s keymaster: only \x05%N\x01 can use doors.", (isNew) ? "New" : "Current", g_iSpecialEventRole);
        }
        case EVT_PROTECT: {
            Format(sReport, REPLINELENGTH, "%s baby: \x05%N\x01 needs protection.", (isNew) ? "New" : "Current", g_iSpecialEventRole);
        }
        case EVT_MEDIC: {
            Format(sReport, REPLINELENGTH, "%s medic: \x05%N\x01.", (isNew) ? "New" : "Current", g_iSpecialEventRole);
        }
        case EVT_BOOMFLU: {
            Format(sReport, REPLINELENGTH, "\x05%N\x01 %s the boomer flu!", g_iSpecialEventRole, (isNew) ? "caught" : "has");
        }
        default: { return; }
    }
    
    if (strlen(sReport))
    {
        if (client) {
            PrintToChat(client, "\x01[\x05r\x01] %s", sReport);
        } else {
            PrintToChatAll("\x01[\x05r\x01] %s", sReport);
        }
    }
    
    if ( (!client || client == g_iSpecialEventRole) && IsClientAndInGame(g_iSpecialEventRole))
    {
        // show a hinttext for emphasis
        switch (_:g_iSpecialEvent)
        {
            case EVT_KEYMASTER: { PrintHintText(g_iSpecialEventRole, "You are the keymaster."); }
            case EVT_PROTECT: { PrintHintText(g_iSpecialEventRole, "You are the baby."); }
            case EVT_MEDIC: { PrintHintText(g_iSpecialEventRole, "You are the medic."); }
            case EVT_BOOMFLU: { PrintHintText(g_iSpecialEventRole, "You have the boomer flu."); }
        }
        
        
        // medics should be told some more stuff
        if (_:g_iSpecialEvent == EVT_MEDIC) {
            if (g_iMedicUnits > 0) {
                PrintToChat(g_iSpecialEventRole, "\x01[\x05r\x01] You have \x03%i\x01 medi-unit%s left. Costs: medkit: \x052\x01, pills: \x051\x01.", g_iMedicUnits, (g_iMedicUnits == 1) ? "" : "s" );
            } else {
                PrintToChat(g_iSpecialEventRole, "\x01[\x05r\x01] You have no medical supplies left.");
            }
        }
        else if (_:g_iSpecialEvent == EVT_BOOMFLU) {
            PrintToChat(g_iSpecialEventRole, "\x01[\x05r\x01] Try not to vomit on your teammates...");
        }
    }
}
// Make random stuff happen
// --------------------------
RANDOM_DetermineRandomStuff()
{
    PrintDebug(0, "[rand] Determining Random Stuff (for %s round).", (g_bSecondHalf) ? "second" : "first" );
    
    new bool: bDoItemRePrep = false;        // true if we need to do PrepareChoices()
    new bool: bBlockTank = false;           // so we can block tank on some event picks
    new bool: bBlockDoubleTank = false;     // so we can block double tank on some event picks
    new bool: bBlockWitch = false;
    
    // prepare random choices (if required)
    if (!g_bSecondHalf) {
        RANDOM_PrepareChoicesEvents();      // rebuild events weighted choices array
    }
    
    
    // keep old difficulty-rating if it's the second half
    if (!g_bSecondHalf)
    {
        g_iDifficultyRating = g_RI_iDifficulty;
        
        // finales are harder, intros easier
        if (g_RI_bIsFinale) {
            g_iDifficultyRating += 4;
        } else if (g_RI_bIsIntro) {
            g_iDifficultyRating--;
        }
    }
    
    // what stripper alt is loaded?
    if (g_bStripperPresent && !g_bSecondHalf)
    {
        g_bStripperAltDetected = SUPPORT_StripperDetectAlt();
        
        PrintDebug(1, "[rand] Stripper alt. for this round: %i (harder path: %s).", g_iStripperCurrentAlt, (g_bStripperAltDetected) ? "yes" : "no");
        
        if (g_bStripperAltDetected)
        {
            // _alt stripper paths are harder; if we ever include them, _alt_b are even harder
            if (g_iStripperCurrentAlt == 1) {
                g_iDifficultyRating += 2;
            }
            else if (g_iStripperCurrentAlt == 2) {
                g_iDifficultyRating += 3;
            }
        }
    }
    
    // only worry about distance/bonus in versus
    if (!g_bCampaignMode)
    {
        // random distance
        //      but let's not mess with changing distance halfway through a map though...
        new distMode = GetConVarInt(g_hCvarRandDistance);
        if (!g_bSecondHalf) {
            // store default distance for map, so we can recalculate on the same basis for round 2
            g_iDefaultDistance = L4D_GetVersusMaxCompletionScore();
        }
        new distNew = g_iDefaultDistance;
        
        // replace with RI data if we have it:
        if (g_bStripperAltDetected && g_RI_iDistanceHard > 0) { distNew = g_RI_iDistanceHard; }
        else if (g_RI_iDistance > 0) { distNew = g_RI_iDistance; }
        
        if (distMode != 0 && !g_bSecondHalf || !(GetConVarInt(g_hCvarEqual) & EQ_POINTS))
        {
            if (distMode == 1)
            {
                // variance mode
                new Float: varMin = GetConVarFloat(g_hCvarRandDistVar);
                new Float: varMax = 1.0 + varMin;
                varMin = 1.0 - varMin;
                
                distNew = RoundFloat(float(g_iDefaultDistance) * GetRandomFloat(varMin, varMax));
            }
            else if (distMode == 2)
            {
                // fully random mode
                distNew = GetRandomInt( GetConVarInt(g_hCvarRandDistMin) , GetConVarInt(g_hCvarRandDistMax) );
            }
            
            // make sure it's a neatly divisible number
            distNew = RoundFloat(float(distNew) / 4.0) * 4;
            
            L4D_SetVersusMaxCompletionScore(distNew);
            PrintDebug(2, "[rand] Distance for this round: %i.", distNew);
            
        }
        
        /*
        // set in damage bonus plugin (not using it there now, but might later)
        RNDBNS_SetDistance(distNew);
        */
        
        
        // set damage bonus
        new bonusMode = GetConVarInt(g_hCvarRandBonus);
        if (!g_bSecondHalf || !(GetConVarInt(g_hCvarEqual) & EQ_POINTS)) {
            // generate bonus size
            new bonusNew;
            new Float: bonusBase = GetConVarFloat(g_hCvarRandBonusBase);
            if (bonusMode == 0)
            {
                // base value, no variation
                if (bonusBase == 0.0) {
                    // static
                    bonusNew = GetConVarInt(g_hCvarRandBonusStatic);
                } else {
                    // map distance relative
                    bonusNew = RoundFloat(bonusBase * distNew);
                }
            }
            else if (bonusMode == 1)
            {
                // base value, no variation
                if (bonusBase == 0.0) {
                    // static
                    bonusNew = GetConVarInt(g_hCvarRandBonusStatic);
                } else {
                    // map distance relative
                    bonusNew = RoundFloat(bonusBase * distNew);
                }
                
                // variation from base
                new Float: varMin = GetConVarFloat(g_hCvarRandBonusVar);
                new Float: varMax = 1.0 + varMin;
                varMin = 1.0 - varMin;
                
                bonusNew = RoundFloat(bonusNew * GetRandomFloat(varMin, varMax));
            }
            else if (bonusMode == 2)
            {
                // fully random
                bonusNew = GetRandomInt( GetConVarInt(g_hCvarRandBonusMin) , GetConVarInt(g_hCvarRandBonusMax) );
            }
            
            // make sure it's a neatly divisible number
            bonusNew = RoundFloat(float(bonusNew) / 4.0) * 4;
            
            g_iDamageBonus = bonusNew;
            
            // update damage bonus plugin
            RNDBNS_SetBonus(bonusNew);
            
            PrintDebug(2, "[rand] Bonus for this round: %i.", bonusNew);
        }
    }
    
    // will a tank/witch spawn?
    g_bTankWillSpawn = L4D2Direct_GetVSTankToSpawnThisRound( (g_bSecondHalf) ? 1 : 0 );
    g_bWitchWillSpawn = L4D2Direct_GetVSWitchToSpawnThisRound( (g_bSecondHalf) ? 1 : 0 );
    
    // pick special event for the map:
    if (!g_bSecondHalf || !(GetConVarInt(g_hCvarEqual) & EQ_EVENT))
    {
        // reset cvars for previous events (g_iSpecialEvent == old event)
        
        EVENT_ResetDifficulty();
        EVENT_ResetOtherCvars();
        EVENT_HUDRestoreAll();
        
        new previousEvent = g_iSpecialEvent;
        g_bUsingPBonus = false;
        
        g_iSpecialEvent = -1;
        g_sSpecialEventExtra = "";
        g_iSpecialEventExtra = 0;
        g_iSpecialEventExtraSub = 0;
        g_iNoSpecialEventStreak++;
        
        // force special event if second round and first round got one...
        new Float: fSpecialEventChance = GetConVarFloat(g_hCvarSpecialEventChance);
        if (g_bSecondHalf && g_iSpecialEvent != -1) { fSpecialEventChance = 1.0; }
        
        // force a special event if we haven't had one in a while
        if      (fSpecialEventChance > 0.65 && g_iNoSpecialEventStreak > 1) { fSpecialEventChance = 1.0; }
        else if (fSpecialEventChance > 0.5 && g_iNoSpecialEventStreak > 2)  { fSpecialEventChance = 1.0; }
        
        if (GetRandomFloat(0.001,1.0) <= fSpecialEventChance || g_iSpecialEventToForce != -1)
        {
            g_iNoSpecialEventStreak = 0;    // reset streak, since we got an event
            
            // pick random from the available weighted choice hat

            // forced, for debug (overrides everything else)
            if (g_iSpecialEventToForce != -1)
            {
                g_iSpecialEvent = g_iSpecialEventToForce;
                g_iSpecialEventToForce = -1;
            }
            else
            {
                new randomIndex = GetRandomInt(0, (g_iEventWeightedChoicesTotal-1));
                g_iSpecialEvent = g_iArEventWeightedChoices[randomIndex];
            }
            
            // select, put in timeout
            g_iArEventTimeout[g_iSpecialEvent] = GetConVarInt(g_hCvarSpecialEventTimeout);
            
            switch(_:g_iSpecialEvent)
            {
                case EVT_ITEM: {
                    g_iSpecialEventExtra = GetRandomInt(INDEX_PISTOL, INDEX_TOTAL - 1);
                    bDoItemRePrep = true;
                }
                case EVT_GIFTS: {
                    g_iSpecialEventExtra = INDEX_GIFT;
                    bDoItemRePrep = true;
                }
                case EVT_ABUNDANCE: {
                    EVENT_SetDifficulty(DIFFICULTY_NOCHANGE, DIFFICULTY_HARD);
                    bDoItemRePrep = true;
                    g_iDifficultyRating--;
                }
                case EVT_UNCOMMON: {
                    if (GetRandomInt(0, 2) == 0) {
                        g_iSpecialEventExtra = GetRandomInt(0, sizeof(g_csUncommonModels) - 1);
                    } else {
                        g_iSpecialEventExtra = -1;  // pick a random each time
                    }
                    EVENT_SetDifficulty(DIFFICULTY_EASY, DIFFICULTY_EASY);
                    g_iDifficultyRating++;
                }
                case EVT_CLOWNS: {
                    g_iSpecialEventExtra = 2; /* clown index */
                    EVENT_SetDifficulty(DIFFICULTY_EASY, DIFFICULTY_EASY);
                    g_iDifficultyRating += 2;
                } 
                case EVT_HORDE_HUGE: {
                    EVENT_SetDifficulty(DIFFICULTY_VERYHARD, DIFFICULTY_VERYEASY);
                    g_iDifficultyRating++;
                }
                case EVT_HORDE_NONE: {
                    EVENT_SetDifficulty(DIFFICULTY_SUPEREASY, DIFFICULTY_VERYHARD);
                    g_iDifficultyRating--;
                }
                case EVT_QUADS: {
                    EVENT_SetDifficulty(DIFFICULTY_EASY, DIFFICULTY_EASY);
                    g_iDifficultyRating += 2;
                    
                    SetConVarInt(FindConVar("z_boomer_limit"), 0);
                    SetConVarInt(FindConVar("z_spitter_limit"), 0);
                }
                case EVT_SNIPER: {
                    EVENT_SetDifficulty(DIFFICULTY_EASY, DIFFICULTY_NOCHANGE);
                    g_iDifficultyRating++;
                    
                    g_iActiveAmmoScout = RoundFloat( GetConVarFloat(g_hCvarAmmoScout) * EVENT_FIREPOWER_AMMO);
                    g_iActiveAmmoAWP = RoundFloat( GetConVarFloat(g_hCvarAmmoAWP) * EVENT_FIREPOWER_AMMO);
                }
                case EVT_WEATHER: {
                    new Handle: hTmp = FindConVar("l4d2_storm_fogmode");
                    if (hTmp != INVALID_HANDLE) {
                        SetConVarInt(hTmp, (g_RI_bNoRain) ? 2 : 0); // 2 = storm but without rain
                    }
                    
                    if (g_RI_iNoStorm == 2) {
                        EVENT_SetDifficulty(DIFFICULTY_EASY, DIFFICULTY_NOCHANGE);
                        g_iDifficultyRating += 3;
                    } else {
                        g_iDifficultyRating += 2;
                    }
                }
                case EVT_FOG: {
                    EVENT_SetDifficulty(DIFFICULTY_NOCHANGE, DIFFICULTY_EASY);
                    new Handle: hTmp = FindConVar("l4d2_storm_fogmode");
                    if (hTmp != INVALID_HANDLE) { SetConVarInt(hTmp, 1); }
                    g_iDifficultyRating += 3; // no outlines
                }
                case EVT_DEFIB: {
                    EVENT_SetDifficulty(DIFFICULTY_EASY, DIFFICULTY_EASY);
                    SetConVarInt(FindConVar("vs_defib_penalty"), 5);
                    PBONUS_SetDefibPenalty(5);
                    SetConVarInt(FindConVar("defibrillator_use_duration"), 2);
                    bDoItemRePrep = true;
                    g_iDifficultyRating += 2;
                }
                case EVT_ADREN: {
                    EVENT_SetDifficulty(DIFFICULTY_EASY, DIFFICULTY_NOCHANGE);
                    bDoItemRePrep = true;
                    bBlockTank = true;
                    SetConVarFloat(FindConVar("pain_pills_decay_rate"), g_fDefPillDecayRate * g_RC_fEventAdrenDecay);
                    g_iDifficultyRating += 2;
                }
                case EVT_NOHUD: {
                    // handled in survivor setup handout / playerleftsaferoom, etc
                }
                case EVT_L4D1: {
                    // slightly easier common-wise, since no melee weapons
                    EVENT_SetDifficulty(DIFFICULTY_EASY, DIFFICULTY_NOCHANGE);
                    bDoItemRePrep = true;
                    
                    // just so bots won't become them either, just in case
                    SetConVarInt(FindConVar("z_spitter_limit"), 0);
                    SetConVarInt(FindConVar("z_jockey_limit"), 0);
                    SetConVarInt(FindConVar("z_charger_limit"), 0);
                    
                    SetConVarInt(FindConVar("z_smoker_limit"), 1);
                    SetConVarInt(FindConVar("z_boomer_limit"), 1);
                    
                    // no tonfa's or biles
                    SetConVarFloat(FindConVar("sv_infected_ceda_vomitjar_probability"), 0.0);
                    SetConVarFloat(FindConVar("sv_infected_riot_control_tonfa_probability"), 0.0);
                }
                case EVT_FF: {
                    EVENT_SetDifficulty(DIFFICULTY_EASY, DIFFICULTY_EASY);
                    SetConVarFloat(FindConVar("survivor_friendly_fire_factor_normal"), g_RC_fEventFFFactor);
                    g_iDifficultyRating++;
                }
                case EVT_SILENCE: {
                    // pick type of silence
                    g_iSpecialEventExtra = GetRandomInt(SILENCED_SURV, SILENCED_SI);
                    if (g_iSpecialEventExtra == SILENCED_SI) {
                        EVENT_SetDifficulty(DIFFICULTY_NOCHANGE, DIFFICULTY_VERYEASY);
                        g_iDifficultyRating += 2;
                    }
                }
                case EVT_PEN_ITEM: {
                    g_bUsingPBonus = true;
                }
                case EVT_PEN_HEALTH: {
                    g_bUsingPBonus = true;
                }
                case EVT_PEN_M2: {
                    g_bUsingPBonus = true;
                }
                case EVT_PEN_TIME: {
                    g_bUsingPBonus = true;
                }
                case EVT_SKEET: {
                    g_bUsingPBonus = true;
                    SetConVarInt(FindConVar("z_smoker_limit"), 1);
                    SetConVarInt(FindConVar("z_boomer_limit"), 1);
                    SetConVarInt(FindConVar("z_spitter_limit"), 1);
                    SetConVarInt(FindConVar("z_jockey_limit"), 1);
                    SetConVarInt(FindConVar("z_charger_limit"), 1);
                }
                case EVT_GUNSWAP: {
                    // don't allow normal weapon spawns
                    g_bNoPriWeapons = true;
                    g_bNoAmmo = true;
                }
                case EVT_MINITANKS: {
                    // set health (lower)
                    SetConVarInt(FindConVar("z_tank_health"), GetConVarInt(g_hCvarMiniTankHealth) );
                    SetConVarInt(FindConVar("z_frustration_lifetime"), g_RC_iMinitankFrustTime);
                    SetConVarInt(FindConVar("vs_tank_damage"), g_RC_iMinitankDamage);
                    
                    // hittable control: soften the blow
                    if (FindConVar("hc_car_standing_damage") != INVALID_HANDLE) {
                        new tmpDmg = (g_RI_bWeakHittables) ? g_RC_iWeakHittableDmg : g_RC_iMinitankHittableDmg;
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
                    
                    L4D2Direct_SetVSWitchToSpawnThisRound(0, false);
                    L4D2Direct_SetVSWitchToSpawnThisRound(1, false);
                    g_bWitchWillSpawn = false;
                    g_bTankWillSpawn = true;
                    bBlockDoubleTank = true;
                    
                    SUPPORT_MultiTankRandomization();
                    
                    EVENT_SetDifficulty(DIFFICULTY_EASY, DIFFICULTY_NOCHANGE);
                    g_iDifficultyRating += 3;
                }
                case EVT_KEYMASTER: {
                    g_bSpecialEventPlayerCheck = true;
                }
                case EVT_BADCOMBO: {
                    // not sure about difficulty.. it's only the start, but still
                    //g_iDifficultyRating++;
                }
                case EVT_PROTECT: {
                    g_bSpecialEventPlayerCheck = true;
                    g_iDifficultyRating++;
                }
                case EVT_ENCUMBERED: {
                    g_iDifficultyRating++;
                }
                case EVT_FIREPOWER: {
                    EVENT_SetDifficulty(DIFFICULTY_HARD, DIFFICULTY_HARD);
                    g_iDifficultyRating -= 2;
                    
                    SetConVarInt(FindConVar("ammo_assaultrifle_max"), RoundFloat( GetConVarFloat(FindConVar("ammo_assaultrifle_max")) * EVENT_FIREPOWER_AMMO) );
                    SetConVarInt(FindConVar("ammo_autoshotgun_max"), RoundFloat( GetConVarFloat(FindConVar("ammo_autoshotgun_max")) * EVENT_FIREPOWER_AMMO) );
                    g_iActiveAmmoAk = RoundFloat( GetConVarFloat(g_hCvarAmmoAk) * EVENT_FIREPOWER_AMMO);
                    g_iActiveAmmoScout = RoundFloat( GetConVarFloat(g_hCvarAmmoScout) * EVENT_FIREPOWER_AMMO);
                    g_iActiveAmmoAWP = RoundFloat( GetConVarFloat(g_hCvarAmmoAWP) * EVENT_FIREPOWER_AMMO);
                }
                case EVT_AMMO: {
                    g_bNoAmmo = true;
                    g_bSpecialEventPlayerCheck = true;
                    
                    SetConVarInt(FindConVar("ammo_smg_max"), RoundFloat( float(g_iDefAmmoSmg) * g_RC_fEventAmmoMaxFactor) );
                    SetConVarInt(FindConVar("ammo_shotgun_max"), RoundFloat( float(g_iDefAmmoShotgun) * g_RC_fEventAmmoMaxFactor) );
                    SetConVarInt(FindConVar("ammo_huntingrifle_max"), RoundFloat( float(g_iDefAmmoHR) * g_RC_fEventAmmoMaxFactor) );
                    SetConVarInt(FindConVar("ammo_sniperrifle_max"), RoundFloat( float(g_iDefAmmoSniper) * g_RC_fEventAmmoMaxFactor) );
                    SetConVarInt(FindConVar("ammo_assaultrifle_max"), RoundFloat( float(g_iDefAmmoRifle) * g_RC_fEventAmmoMaxFactor) );
                    SetConVarInt(FindConVar("ammo_autoshotgun_max"), RoundFloat( float(g_iDefAmmoAutoShotgun) * g_RC_fEventAmmoMaxFactor) );
                    g_iActiveAmmoAk = RoundFloat( GetConVarFloat(g_hCvarAmmoAk) * g_RC_fEventAmmoMaxFactor);
                    g_iActiveAmmoScout = RoundFloat( GetConVarFloat(g_hCvarAmmoScout) * g_RC_fEventAmmoMaxFactor);
                    g_iActiveAmmoAWP = RoundFloat( GetConVarFloat(g_hCvarAmmoAWP) * g_RC_fEventAmmoMaxFactor);
                    
                    g_iDifficultyRating++;
                }
                case EVT_WOMEN: {
                    g_bNoPriWeapons = true;
                    g_bNoSecWeapons = true;
                    g_bNoAmmo = true;
                    bBlockTank = true;
                    EVENT_SetDifficulty(DIFFICULTY_VERYHARD, DIFFICULTY_HARD);
                    
                    SetConVarInt(FindConVar("z_smoker_limit"), 0);
                    SetConVarInt(FindConVar("z_hunter_limit"), 0);
                    SetConVarInt(FindConVar("z_jockey_limit"), 0);
                    SetConVarInt(FindConVar("z_charger_limit"), 0);
                    SetConVarInt(FindConVar("z_boomer_limit"), 4);
                    SetConVarInt(FindConVar("z_spitter_limit"), 2);
                    
                    SetConVarInt(FindConVar("z_vomit_interval"), 15);
                    SetConVarInt(FindConVar("z_spit_interval"), 15);
                    
                    // no tonfa's
                    SetConVarFloat(FindConVar("sv_infected_riot_control_tonfa_probability"), 0.0);
                    
                    // which melee is available? this determines the event type
                    new bool: bAxe = IsMeleeAvailable("fireaxe");
                    new bool: bGuitar = IsMeleeAvailable("electric_guitar");
                    
                    if (bAxe && bGuitar) {
                        g_iSpecialEventExtra = GetRandomInt(EVTWOMEN_TYPE_AXE, EVTWOMEN_TYPE_ROCK);
                    }
                    else if (bAxe) {
                        g_iSpecialEventExtra = EVTWOMEN_TYPE_AXE;
                    }
                    else if (bGuitar) {
                        g_iSpecialEventExtra = EVTWOMEN_TYPE_ROCK;
                    }
                    else {
                        g_iSpecialEventExtra = EVTWOMEN_TYPE_BEAT;
                    }
                }
                case EVT_WITCHES: {
                    g_bUsingPBonus = true;
                    bBlockTank = true;
                    //bBlockWitch = true; // block the normal witch so they're all consistent
                    EVENT_SetDifficulty(DIFFICULTY_EASY, DIFFICULTY_NOCHANGE);
                    
                    // set half the distance
                    L4D_SetVersusMaxCompletionScore( RoundFloat( float(L4D_GetVersusMaxCompletionScore()) * 0.5 ) );
                }
                case EVT_BADSANTA: {
                    g_bUsingPBonus = true;
                    g_iSpecialEventExtra = INDEX_GIFT;
                }
                case EVT_MEDIC: {
                    g_bSpecialEventPlayerCheck = true;
                    g_bNoHealthItems = true;
                }
                case EVT_BOOMFLU: {
                    g_bSpecialEventPlayerCheck = true;
                    g_iDifficultyRating++;
                }
            }
            PrintDebug(1, "[rand] Picked Special Event: %i (%s) [extra, %i, sub: %i, str: %s]", g_iSpecialEvent, g_csEventText[g_iSpecialEvent], g_iSpecialEventExtra, g_iSpecialEventExtraSub, g_sSpecialEventExtra);
        }
        else
        {
            g_iSpecialEvent = -1;
            PrintDebug(1, "[rand] No Special Event.");
        }
        
        // reset storm after weather event (but only if the event is not a storm this round)`
        if ( ( previousEvent == _:EVT_WEATHER || previousEvent == _:EVT_FOG ) && g_iSpecialEvent != _:EVT_WEATHER && g_iSpecialEvent != _:EVT_FOG )
        {
            new Handle: hTmp = FindConVar("l4d2_storm_fogmode");
            if (hTmp != INVALID_HANDLE) { SetConVarInt(hTmp, 0); }
            SUPPORT_StormReset();
        }
    }
    
    // force the spawns if we have the cvars set
    if (bBlockTank || g_RI_bNoTank) {
        L4D2Direct_SetVSTankToSpawnThisRound(0, false);
        L4D2Direct_SetVSTankToSpawnThisRound(1, false);
        g_bTankWillSpawn = false;
        g_bTankIsEarly = false;
    }
    else if (!g_bTankWillSpawn && GetConVarFloat(FindConVar("versus_tank_chance")) == 1.0) {
        L4D2Direct_SetVSTankToSpawnThisRound(0, true);
        L4D2Direct_SetVSTankToSpawnThisRound(1, true);
        g_bTankWillSpawn = true;
        g_bTankIsEarly = false;
    }
    
    if (bBlockWitch || g_RI_bNoWitch) {
        L4D2Direct_SetVSWitchToSpawnThisRound(0, false);
        L4D2Direct_SetVSWitchToSpawnThisRound(1, false);
        g_bWitchWillSpawn = false;
    }
    else if (!g_bWitchWillSpawn && GetConVarFloat(FindConVar("versus_witch_chance")) == 1.0 && _:g_iSpecialEvent != EVT_MINITANKS || _:g_iSpecialEvent == EVT_WOMEN) {
        // block witches on minitanks
        // force witch on women event
        L4D2Direct_SetVSWitchToSpawnThisRound(0, true);
        L4D2Direct_SetVSWitchToSpawnThisRound(1, true);
        g_bWitchWillSpawn = true;
    }
    else if (g_bWitchFirstRound && !g_bWitchWillSpawn)
    {
        // force witch if we had one the first round
        L4D2Direct_SetVSWitchToSpawnThisRound(0, true);
        L4D2Direct_SetVSWitchToSpawnThisRound(1, true);
        g_bWitchWillSpawn = true;
    }
    
    if (g_bTankWillSpawn)
    {
        g_iDifficultyRating += 2;
        
        new Float: fTankFlow = L4D2Direct_GetVSTankFlowPercent( (g_bSecondHalf) ? 1 : 0 );
        new iTankSpawn = RoundToNearest(fTankFlow * 100.0);
        
        // safeguard against weird values
        if (fTankFlow > 1.0 || fTankFlow < 0.0) {
            PrintDebug(2, "[rand] Boss spawns -- Found freaky flow value (%.2f), picking random normal value.", fTankFlow);
            fTankFlow = GetRandomFloat(0.16, 0.84);
            L4D2Direct_SetVSTankFlowPercent(0, fTankFlow);
            L4D2Direct_SetVSTankFlowPercent(1, fTankFlow);
        }
        
        // check tank flow bans:
        if (GetConVarBool(g_hCvarBanTankFlows) && g_RI_iTankBanStart != -1 && g_RI_iTankBanEnd != -1)
        {
            // banned range?
            if (iTankSpawn >= g_RI_iTankBanStart && iTankSpawn <= g_RI_iTankBanEnd)
            {
                // banned tank
                new oldSpawn = iTankSpawn;
                
                new minFlow = (g_RI_iTankBanStart < 15) ? 15 : g_RI_iTankBanStart;
                new maxFlow = (g_RI_iTankBanEnd > 85)   ? 85 : g_RI_iTankBanEnd;
                
                new range = maxFlow - minFlow;
                new r = 15 + GetRandomInt(0, 70 - range);
                iTankSpawn = (r >= minFlow) ? r + range : r;
                
                fTankFlow = float(iTankSpawn) / 100.0;
                
                PrintDebug(2, "[rand] Boss spawns -- Found banned tank (@ %i), changing to %.f.", oldSpawn, iTankSpawn);
                
                L4D2Direct_SetVSTankFlowPercent(0, fTankFlow);
                L4D2Direct_SetVSTankFlowPercent(1, fTankFlow);
            }
        }
        
        // is it an early tank?
        if (g_RI_bIsIntro && fTankFlow < 0.6 || fTankFlow < 0.4)
        {
            g_bTankIsEarly = true;
        }
        
        // some maps shouldn't have tank flow variation
        if ( g_fDefTankFlowVariation != 0.0 && g_RI_bNoTankVar )
        {
            SetConVarFloat(FindConVar("versus_tank_flow_team_variation"), 0.0);
        }
    }
    
    PrintDebug(1, "[rand] Boss spawns: Tank: %i (%.2f) / Witch: %i (%.2f)", g_bTankWillSpawn, L4D2Direct_GetVSTankFlowPercent( (g_bSecondHalf) ? 1 : 0 ), g_bWitchWillSpawn, L4D2Direct_GetVSWitchFlowPercent( (g_bSecondHalf) ? 1 : 0 ));
    
    // multi-tanks? if so, set first tank to spawn early and last tank to spawn late
    // only determine if tanks will spawn at all
    //      tanks should not double-spawn on finales or first maps
    //      double-tanks also won't happen if their base positions fall withing a banned range
    if (g_bTankWillSpawn && !bBlockDoubleTank)
    {
        if (!g_bSecondHalf || !(GetConVarInt(g_hCvarEqual) & EQ_TANKS))
        {
            if (!g_RI_bIsIntro && !g_RI_bIsFinale && GetRandomFloat(0.001,1.0) <= GetConVarFloat(g_hCvarDoubleTankChance)
                &&  (       !GetConVarBool(g_hCvarBanTankFlows)
                        ||  g_RI_iTankBanStart == -1
                        ||  g_RI_iTankBanEnd == -1
                        ||  (
                                (MULTITANK_EARLY < g_RI_iTankBanStart || MULTITANK_EARLY > g_RI_iTankBanEnd)
                                &&  (MULTITANK_LATE < g_RI_iTankBanStart || MULTITANK_LATE > g_RI_iTankBanEnd)
                            )
                    )
            ) {
                g_bDoubleTank = true;
                
                new Float: fTmpVarLess = 1.0 - GetConVarFloat(g_hCvarTankFlowVariance);
                new Float: fTmpVarMore = 1.0 + GetConVarFloat(g_hCvarTankFlowVariance);
                
                if (fTmpVarLess < 0.05) { fTmpVarLess = 0.05; }     // safeguard
                if (fTmpVarMore > 1.5) { fTmpVarMore = 1.5; }       // safeguard
                
                g_fTankFlowEarly = MULTITANK_EARLY * GetRandomFloat(fTmpVarLess, fTmpVarMore);
                g_fTankFlowLate = MULTITANK_LATE * GetRandomFloat(fTmpVarLess, fTmpVarMore);
                
                L4D2Direct_SetVSTankToSpawnThisRound(0, true);
                L4D2Direct_SetVSTankToSpawnThisRound(1, true);
                L4D2Direct_SetVSTankFlowPercent(0, g_fTankFlowEarly);
                L4D2Direct_SetVSTankFlowPercent(1, g_fTankFlowEarly);
                
                SetConVarInt(FindConVar("z_tank_health"), GetConVarInt(g_hCvarDoubleTankHealth) );
                
                PrintDebug(1, "[rand] Double tank set for this round: %0.f early, %0.f late.", 100.0 * g_fTankFlowEarly, 100.0 * g_fTankFlowLate);
                
                g_iDifficultyRating += 2;  // on top of the 2 for tank already
                
                // no witches for doubletank round
                g_bWitchWillSpawn = false;
                g_bTankIsEarly = true;
            }
            else {
                g_bDoubleTank = false;
            }
        }
        else if (g_bDoubleTank)
        {
            // must force again, or the late spawn for the previous round is apparently used
            L4D2Direct_SetVSTankToSpawnThisRound(0, true);          // must set for both, for some reason
            L4D2Direct_SetVSTankToSpawnThisRound(1, true);
            L4D2Direct_SetVSTankFlowPercent(0, g_fTankFlowEarly);
            L4D2Direct_SetVSTankFlowPercent(1, g_fTankFlowEarly);
            
            SetConVarInt(FindConVar("z_tank_health"), GetConVarInt(g_hCvarDoubleTankHealth) );
            
            // no witches for doubletank round
            g_bWitchWillSpawn = false;
            g_bTankIsEarly = true;
        }
    } else {
        // no double tanks in any case
        g_bDoubleTank = false;
    }
    
    if (g_bWitchWillSpawn) {
        g_iDifficultyRating++;
        
        // remember in case the game forgets...
        if (!g_bSecondHalf) { g_bWitchFirstRound = true; }
    }
    else {
        L4D2Direct_SetVSWitchToSpawnThisRound(0, false);
        L4D2Direct_SetVSWitchToSpawnThisRound(1, false);
    }
    
    // multi-witches?
    if (g_bWitchWillSpawn && !g_RI_bIsFinale && (g_RC_bMultiwitchAllowTank || !g_bTankWillSpawn) && _:g_iSpecialEvent != EVT_MINITANKS )
    {
        if (!g_bSecondHalf || !(GetConVarInt(g_hCvarEqual) & EQ_TANKS))
        {
            if (GetRandomFloat(0.001,1.0) <= GetConVarFloat(g_hCvarMultiWitchChance)) {
                g_bMultiWitch = true;
                SUPPORT_MultiWitchRandomization();
                g_iDifficultyRating += (g_iWitchNum > 6) ? 4 : ((g_iWitchNum > 4) ? 3 : 2);
                SetConVarInt(FindConVar("sv_force_time_of_day"), (g_bArWitchSitting[0]) ? WITCHES_NIGHT : WITCHES_DAY );
            } else {
                g_bMultiWitch = false;
            }
        }
    } else {
        // no double witches in any case
        g_bMultiWitch = false;
    }
    
    // door locking
    if (!g_bSecondHalf || !(GetConVarInt(g_hCvarEqual) & EQ_DOORS) || (_:g_iSpecialEvent == EVT_L4D1 && !(GetConVarInt(g_hCvarEqual) & EQ_EVENT) ) ) {
        RandomizeDoors();
    } else {
        RestoreDoors();
    }
    
    // prepare random choices for things in the round
    if ( !g_bSecondHalf || !(GetConVarInt(g_hCvarEqual) & EQ_EVENT) )
    {
        RANDOM_PrepareChoicesSpawns();          // build spawns weighted choices array
        RANDOM_PrepareChoicesGiftEffects();     // build gift effects array
    }
    
    // first attack spawns
    if (!g_bCampaignMode)
    {
        if (!g_bSecondHalf || !(GetConVarInt(g_hCvarEqual) & EQ_FIRST_ATTACK)) {
            RandomizeFirstSpawns();
        }
    }
    
    // survivor outlines
    if (!g_bSecondHalf || !(GetConVarInt(g_hCvarEqual) & EQ_GLOWS))
    {
        // fog of war event forces no outlines (unless 0 chance)
        if (_:g_iSpecialEvent == EVT_FOG && GetConVarFloat(g_hCvarOutlineChance) > 0.0)
        {
            SetConVarInt(FindConVar("sv_disable_glow_survivors"), 1);
            g_bGlows = false;
        }
        else
        {
            if (GetRandomFloat(0.001,1.0) <= GetConVarFloat(g_hCvarOutlineChance))
            {
                // have outlines
                SetConVarInt(FindConVar("sv_disable_glow_survivors"), 0);
                g_bGlows = true;
            }
            else
            {
                // remove outlines
                // if round is already too difficult, stack the odds in favor against
                if ( GetConVarBool(g_hCvarDifficultyBalance) && g_iDifficultyRating > DIFF_RATING_GLOW_THRESH && GetRandomFloat(0.001,1.0) <= GetConVarFloat(g_hCvarOutlineChance)) {
                    SetConVarInt(FindConVar("sv_disable_glow_survivors"), 0);
                    g_bGlows = true;
                    
                    PrintDebug(1, "[rand] Survivor glows enabled because of difficulty rating (%i > %i).", g_iDifficultyRating, DIFF_RATING_GLOW_THRESH);
                } else {
                    SetConVarInt(FindConVar("sv_disable_glow_survivors"), 1);
                    g_bGlows = false;
                    g_iDifficultyRating += 3;
                    
                    PrintDebug(1, "[rand] Survivor glows off.");
                }
            }
        }
    }
    
    // incaps
    if (!g_bSecondHalf || !(GetConVarInt(g_hCvarEqual) & EQ_INCAPS))
    {
        if (_:g_iSpecialEvent == EVT_DEFIB) {
            g_iIncaps = 0;
        }
        else if (_:g_iSpecialEvent == EVT_MEDIC) {
            // force default for this
            g_iIncaps = 2;
        }
        else {
            g_iIncaps = GetRandomInt(INCAP_MINIMUM, INCAP_MAXIMUM);
            
            // reduce chances of getting only 1 incap?
            if (g_iIncaps == INCAP_MINIMUM && GetRandomFloat(0.001,1.0) <= GetConVarFloat(g_hCvarAvoidIncapsChance)) {
                g_iIncaps++;
            }
            
            // if difficulty is too great, re-pick with default as minimum
            if (g_iIncaps == INCAP_MINIMUM)
            {
                if ( GetConVarBool(g_hCvarDifficultyBalance) && g_iDifficultyRating > DIFF_RATING_INCAP_THRESH) {
                    g_iIncaps = GetRandomInt(2, INCAP_MAXIMUM);
                    PrintDebug(1, "[rand] Survivor incaps increased because of difficulty rating (%i > %i).", g_iDifficultyRating, DIFF_RATING_INCAP_THRESH);
                } else {
                    g_iDifficultyRating++;
                }
            }
            else if (g_iIncaps == INCAP_MAXIMUM)
            {
                g_iDifficultyRating--;
            }
        }
        
        SetConVarInt(FindConVar("survivor_max_incapacitated_count"), g_iIncaps);
    }
    
    // item randomization preparation
    if (!g_bSecondHalf || bDoItemRePrep) {
        RANDOM_PrepareChoices();            // rebuild weighted choices array (convars might be updated)
    }
    
    
    // survivor setup (health, items)
    if (!g_bSecondHalf || !(GetConVarInt(g_hCvarEqual) & EQ_SURV_HEALTH)) {
        RandomizeSurvivorHealth();
    }
    
    if (!g_bSecondHalf || !(GetConVarInt(g_hCvarEqual) & EQ_ITEMS)) {
        if (g_bSecondHalf && !(GetConVarInt(g_hCvarEqual) & EQ_ITEM_WEIGHTS)) { RANDOM_PrepareChoices(); }
        RandomizeSurvivorItems();
    } else {
        RestoreSurvivorItems();
    }
    
    // randomize witches standing/sitting (time of day)
    if (!g_bSecondHalf || !(GetConVarInt(g_hCvarEqual) & EQ_TANKS))
    {
        if (_:g_iSpecialEvent != EVT_WITCHES && ( (g_bMultiWitch && g_bArWitchSitting[0] == false) || GetRandomInt(0, 3) == 0 ) )
        { 
            SetConVarInt(FindConVar("sv_force_time_of_day"), WITCHES_DAY);
        } else {
            SetConVarInt(FindConVar("sv_force_time_of_day"), WITCHES_NIGHT);
        }
    }
    
    // debug report difficulty rating (only display on first roundhalf or if something's changed)
    if (!g_bSecondHalf || GetConVarInt(g_hCvarEqual) < EQ_EVERYTHING)
    {
        PrintDebug(1, "[rand] Round difficulty rating: %i", g_iDifficultyRating);
    }
}



// Randomization magic
// --------------------------
RandomizeItems()
{
    // let the magic happen, randomize the hell out of everything
    g_iStoredEntities = 0;
    g_iStoredHittables = 0;
    
    new RandomizableOrNot: classnameRoN;
    new entityCount = GetEntityCount();
    
    new iCountNoitem = 0;                   // just some score-keeping for debugging 
    new iCountFinaleAmmo = 0;               // how many forced finale ammo piles (also decreased on re-rolls)
    new iCountStartAmmo = 0;                // how many starting ammo piles?
    new bool: bForceFinaleAmmo;
    new bool: bIsFireExtinguisher;
    
    new String:classname[128];
    new curEnt;                             // the entity we're currently storing data for
    new curHit;                             // the hittable we're currently storing data for

    new Float: fAmmoVarMore = 1.0 + GetConVarFloat(g_hCvarAmmoVarianceMore);
    new Float: fAmmoVarLess = 1.0 - GetConVarFloat(g_hCvarAmmoVarianceLess);
    new Float: fAmmoFactor = (_:g_iSpecialEvent == EVT_AMMO) ? g_RC_fEventAmmoFactor : 1.0;
    
    for (new i=0; i < entityCount; i++)
    {
        bForceFinaleAmmo = false;
        bIsFireExtinguisher = false;
        
        if (IsValidEntity(i)) {
        
            GetEdictClassname(i, classname, sizeof(classname));
            
            if (!GetTrieValue(g_hTrieRandomizableEntity, classname, classnameRoN)) { continue; }                        // if it's not randomizable, we don't need to bother with it at all
            
            if (classnameRoN == RANDOMIZABLE_PHYSICS) 
            {
                new String:modelname[STR_MAX_MODELNAME];
                GetEntPropString(i, Prop_Data, "m_ModelName", modelname, STR_MAX_MODELNAME);
                if (!GetTrieValue(g_hTrieRandomizablePropPhysicsModel, modelname, classnameRoN)) { continue; }          // if it's not one of the prop_physics models we want to randomize, don't worry about it
                
                // hittables
                if (        classnameRoN == HITTABLE_PHYSICS        ||  classnameRoN == HITTABLE_PHYSICS_TURNED
                        ||  classnameRoN == HITTABLE_PHYSICS_SMALL  ||  classnameRoN == HITTABLE_PHYSICS_SMALL_TURNED
                        ||  classnameRoN == HITTABLE_PHYSICS_CAR    ||  classnameRoN == HITTABLE_PHYSICS_CAR_TURNED
                        ||  classnameRoN == HITTABLE_PHYSICS_ADDON
                ) {
                    if (!GetConVarBool(g_hCvarRandomHittables)) { continue; }
                    
                    if (classnameRoN == HITTABLE_PHYSICS_ADDON) {
                        // just remove it
                        AcceptEntityInput(i, "Kill");
                        continue;
                    }
                    
                    // replace with random other hittable?
                    curHit = g_iStoredHittables;
                    g_iStoredHittables++;
            
                    g_strArHittableStorage[curHit][hitPickedType] = 0;          // cleanup, defaults:
                    g_strArHittableStorage[curHit][hitIsCar] = false;
                    g_strArHittableStorage[curHit][hitIsColored] = false;
                    g_strArHittableStorage[curHit][hitIsAlarmed] = false;
                    g_strArHittableStorage[curHit][hitAlarmOff] = false;
                    
                    decl Float: horigin[3];
                    decl Float: hangles[3];
                    
                    GetEntPropVector(i, Prop_Send, "m_vecOrigin", horigin);
                    GetEntPropVector(i, Prop_Send, "m_angRotation", hangles);
                    
                    // taxi's and police cars are rotated 90 degrees to the left (+90 on z-ang)
                    if (classnameRoN == HITTABLE_PHYSICS_CAR_TURNED || classnameRoN == HITTABLE_PHYSICS_SMALL_TURNED || classnameRoN == HITTABLE_PHYSICS_TURNED)
                    {
                        hangles[1] += 90.0;
                    }
                    
                    g_strArHittableStorage[curHit][hitOrigin_a] = horigin[0];
                    g_strArHittableStorage[curHit][hitOrigin_b] = horigin[1];
                    g_strArHittableStorage[curHit][hitOrigin_c] = horigin[2];
                    g_strArHittableStorage[curHit][hitAngles_a] = hangles[0];
                    g_strArHittableStorage[curHit][hitAngles_b] = hangles[1];
                    g_strArHittableStorage[curHit][hitAngles_c] = hangles[2];
                    
                    
                    new randType = GetRandomInt( (classnameRoN == HITTABLE_PHYSICS_SMALL || classnameRoN == HITTABLE_PHYSICS_SMALL_TURNED) ? HITTAB_FIRSTSMALL : 0 , HITTAB_TOTAL - 1);
                    
                    // for car: different odds (repicking?)
                    if ( (classnameRoN == HITTABLE_PHYSICS_CAR || classnameRoN == HITTABLE_PHYSICS_CAR_TURNED) && randType > HITTAB_LASTCAR)
                    {
                        if (GetRandomFloat(0.001, 1.0) <= HITTABLE_CAR_REPICK) {
                            randType = GetRandomInt(0, HITTAB_LASTCAR);
                        }
                    }
                    
                    g_strArHittableStorage[curHit][hitPickedType] = randType;
                    
                    if (randType <= HITTAB_LASTCAR)
                    {
                        g_strArHittableStorage[curHit][hitIsCar] = true;
                        
                        // is it alarmed?
                        if (GetRandomFloat(0.001, 1.0) <= GetConVarFloat(g_hCvarAlarmedCarChance)) {
                            g_strArHittableStorage[curHit][hitIsAlarmed] = true;
                            randType = HITTAB_CAR95;
                        }
                        else {
                            // if not alarmed, use the HITTAB_CAR95 less often
                            if (randType == HITTAB_CAR95 && GetRandomInt(0,1)) {
                                randType = GetRandomInt(0, HITTAB_LASTCAR);
                            }
                        }
                        
                        // rotation on police/taxi cars
                        if (randType == HITTAB_CARTAXI || randType == HITTAB_CARPOLICE)
                        {
                            g_strArHittableStorage[curHit][hitAngles_b] -= 90.0;
                        }
                        
                        // colors
                        if (randType == HITTAB_CARTAXI) {
                            g_strArHittableStorage[curHit][hitIsColored] = true;
                            
                            // yellow or white taxi
                            if (GetRandomInt(0,2) == 0) {
                                g_strArHittableStorage[curHit][hitColor_r] = 255;
                                g_strArHittableStorage[curHit][hitColor_g] = 255;
                                g_strArHittableStorage[curHit][hitColor_b] = 255;
                            } else {
                                g_strArHittableStorage[curHit][hitColor_r] = GetRandomInt(200,254);
                                g_strArHittableStorage[curHit][hitColor_g] = GetRandomInt(180,254);
                                g_strArHittableStorage[curHit][hitColor_b] = GetRandomInt(0,50);
                            }
                        }
                        else {
                            g_strArHittableStorage[curHit][hitIsColored] = (randType == HITTAB_CARPOLICE) ? false : true;
                            
                            // pick a color
                            g_strArHittableStorage[curHit][hitColor_r] = GetRandomInt(1,254);
                            g_strArHittableStorage[curHit][hitColor_g] = GetRandomInt(1,254);
                            g_strArHittableStorage[curHit][hitColor_b] = GetRandomInt(1,254);
                        }
                    }
                    else
                    {
                        // rotation on some objects
                        if (g_cbHittableTurned[randType])
                        {
                            g_strArHittableStorage[curHit][hitAngles_b] -= 90.0;
                        }
                    }
                    
                    AcceptEntityInput(i, "Kill");
                    continue;
                }
                
                // fire extinguisher
                if (StrContains(modelname, "fire_extinguisher", false) != -1)
                {
                    bIsFireExtinguisher = true;
                }
            }
            else if (g_RI_bIsFinale && classnameRoN == RANDOMIZABLE_ITEM_AMMO && GetRandomFloat(0.001,1.0) > GetConVarFloat(g_hCvarFinaleAmmoChance) && !g_bNoAmmo)
            {
                // don't touch ammo piles on finales
                iCountFinaleAmmo++;
                bForceFinaleAmmo = true;
            }
            
            //PrintDebug(1, "[rand] Entity %d is randomizable: %s.", i, classname);
            
            /*
                The entity is randomize-material
                    pick a random alternative
                    store it for later resetting
            */
            
            curEnt = g_iStoredEntities;
            g_iStoredEntities++;
            
            g_strArStorage[curEnt][entPickedType] = 0;           // cleanup, defaults:
            g_strArStorage[curEnt][entSpawnPhysics] = false;
            g_strArStorage[curEnt][entAmmoMax] = 0;
            g_strArStorage[curEnt][entCheckOrigin] = false;
            g_strArStorage[curEnt][entInStartSaferoom] = false;
            g_strArStorage[curEnt][entInEndSaferoom] = false;
            g_sArStorageMelee[curEnt] = "";
            
            // store whether it is in a saferoom
            if (SAFEDETECT_IsEntityInStartSaferoom(i)) {
                g_strArStorage[curEnt][entInStartSaferoom] = true;
            }
            else if (SAFEDETECT_IsEntityInEndSaferoom(i)) {
                g_strArStorage[curEnt][entInEndSaferoom] = true;
            }
            
            // pick random from the available weighted choice hat
            new randomIndex = GetRandomInt(0, (g_iWeightedChoicesTotal-1));
            new randomPick = g_iArWeightedChoices[randomIndex];
            
            
            // prevent finale flooded with ammo... repick
            if (iCountFinaleAmmo && !bForceFinaleAmmo && randomPick == INDEX_AMMO)
            {
                iCountFinaleAmmo--;
                randomIndex = GetRandomInt(0, (g_iWeightedChoicesTotal-1));
                randomPick = g_iArWeightedChoices[randomIndex];
            }
            // force ammo choice for finale pile
            else if (bForceFinaleAmmo) {
                randomPick = INDEX_AMMO;
            }
            
            // saferoom handling
            if (g_strArStorage[curEnt][entInStartSaferoom])
            {
                // noitem chance for start saferoom?
                if (GetRandomFloat(0.001,1.0) <= GetConVarFloat(g_hCvarStartSafeItem)) {
                    
                    if (randomPick == INDEX_NOITEM) {
                        while (randomPick == INDEX_NOITEM) {
                            randomIndex = GetRandomInt(randomIndex + 1, (g_iWeightedChoicesTotal-1));
                            randomPick = g_iArWeightedChoices[randomIndex];
                        }
                    }
                    
                    // t2 in saferoom?
                    if ( (randomPick == INDEX_T2SHOTGUN || randomPick == INDEX_T2RIFLE) && GetRandomFloat(0.001,1.0) > GetConVarFloat(g_hCvarT2StartChance)) {
                        switch (randomPick) {
                            case INDEX_T2SHOTGUN: { randomPick = INDEX_T1SHOTGUN; }
                            case INDEX_T2RIFLE: { randomPick = INDEX_T1SMG; }
                        }
                    }
                    
                } else {
                    randomPick = INDEX_NOITEM;
                }
                
                // junk => useful items?
                if (GetRandomFloat(0.001,1.0) <= GetConVarFloat(g_hCvarStartItemNoJunk)) {
                    randomIndex = GetRandomInt(g_iWeightedChoicesStartUseful, g_iWeightedChoicesEndUseful);
                    randomPick = g_iArWeightedChoices[randomIndex];
                }
                
                // only 1 ammo pile in saferoom -- reduce the odds of more
                if (randomPick == INDEX_AMMO)
                {
                    iCountStartAmmo++;
                    
                    // repick if we already have it
                    if (iCountStartAmmo > 1) {
                        randomIndex = GetRandomInt(0, (g_iWeightedChoicesTotal-1));
                        randomPick = g_iArWeightedChoices[randomIndex];
                        
                        if (randomPick != INDEX_AMMO) { iCountStartAmmo--; }
                    }
                }
            }
            else if (g_strArStorage[curEnt][entInEndSaferoom] && !g_bCampaignMode)
            {
                if (GetConVarFloat(g_hCvarEndSafeItem) > 0.0 && GetRandomFloat(0.001,1.0) <= GetConVarFloat(g_hCvarEndSafeItem)) {
                    if (randomPick == INDEX_NOITEM) {
                        while (randomPick == INDEX_NOITEM) {
                            randomIndex = GetRandomInt(randomIndex + 1, (g_iWeightedChoicesTotal-1));
                            randomPick = g_iArWeightedChoices[randomIndex];
                        }
                    }
                } else {
                    randomPick = INDEX_NOITEM;
                }
            }
            
            // special events:
            //  SNIPER: ignore other t1 and t2 picks, only let snipers go through:
            if (_:g_iSpecialEvent == EVT_SNIPER) {
                switch (randomPick) {
                    case INDEX_T1SMG: { randomPick = INDEX_SNIPER; }
                    case INDEX_T1SHOTGUN: { randomPick = INDEX_SNIPER; }
                    case INDEX_T2RIFLE: { randomPick = INDEX_SNIPER; }
                    case INDEX_T2SHOTGUN: { randomPick = INDEX_SNIPER; }
                    case INDEX_T3: { randomPick = INDEX_SNIPER; }
                }
            }
            // skeeting, only shotguns
            else if (_:g_iSpecialEvent == EVT_SKEET) {
                switch (randomPick) {
                    case INDEX_T1SMG: { randomPick = INDEX_T1SHOTGUN; }
                    case INDEX_SNIPER: { randomPick = INDEX_T1SHOTGUN; }
                    case INDEX_T2RIFLE: { randomPick = INDEX_T2SHOTGUN; }
                    case INDEX_T3: { randomPick = INDEX_T2SHOTGUN; }
                }
            }
            else if (_:g_iSpecialEvent == EVT_BADCOMBO && g_strArStorage[curEnt][entInStartSaferoom]) {
                // remove all primary and secondary weapons from start saferoom
                switch (randomPick) {
                    case INDEX_PISTOL: { randomPick = INDEX_NOITEM; }
                    case INDEX_MELEE: { randomPick = INDEX_NOITEM; }
                    case INDEX_T1SMG: { randomPick = INDEX_NOITEM; }
                    case INDEX_T1SHOTGUN: { randomPick = INDEX_NOITEM; }
                    case INDEX_T2RIFLE: { randomPick = INDEX_NOITEM; }
                    case INDEX_T2SHOTGUN: { randomPick = INDEX_NOITEM; }
                    case INDEX_SNIPER: { randomPick = INDEX_NOITEM; }
                    case INDEX_T3: { randomPick = INDEX_NOITEM; }
                    
                }
            }
            // no t1s
            else if (_:g_iSpecialEvent == EVT_FIREPOWER) {
                switch (randomPick) {
                    case INDEX_T1SMG: { randomPick = INDEX_T2RIFLE; }
                    case INDEX_T1SHOTGUN: { randomPick = INDEX_T2SHOTGUN; }
                }
            }
            
            
            // randomly pick one:
            switch (randomPick)
            {
                case INDEX_PISTOL:
                {
                    if (GetRandomInt(0, RATE_MAGNUM - 1) == 0 && _:g_iSpecialEvent != EVT_L4D1 ) {
                        g_strArStorage[curEnt][entPickedType] = PCK_PISTOL_MAGNUM;
                    } else {
                        g_strArStorage[curEnt][entPickedType] = PCK_PISTOL;
                    }
                }
                
                case INDEX_T1SMG:
                {
                    if (_:g_iSpecialEvent == EVT_L4D1) {
                        g_strArStorage[curEnt][entPickedType] = PCK_SMG;
                    } else {
                        if (GetRandomInt(0, RATE_CSS - 1) == 0) {
                            g_strArStorage[curEnt][entPickedType] = PCK_SMG_MP5;
                        } else {
                            if (GetRandomInt(0, RATE_SMG - 1) == 0) {
                                g_strArStorage[curEnt][entPickedType] = PCK_SMG;
                            } else {
                                g_strArStorage[curEnt][entPickedType] = PCK_SMG_SILENCED;
                            }
                        }
                    }
                    g_strArStorage[curEnt][entAmmoMax] = RoundFloat(GetConVarFloat(FindConVar("ammo_smg_max")) * GetRandomFloat(fAmmoVarLess, fAmmoVarMore) * fAmmoFactor);
                }
                
                case INDEX_T1SHOTGUN:
                {
                    if ( GetRandomInt(0, RATE_PUMPSHOT - 1) == 0 || _:g_iSpecialEvent == EVT_L4D1 ) {
                        g_strArStorage[curEnt][entPickedType] = PCK_PUMPSHOTGUN;
                    } else {
                        g_strArStorage[curEnt][entPickedType] = PCK_SHOTGUN_CHROME;
                    }
                    g_strArStorage[curEnt][entAmmoMax] = RoundFloat(GetConVarFloat(FindConVar("ammo_shotgun_max")) * GetRandomFloat(fAmmoVarLess, fAmmoVarMore) * fAmmoFactor);
                }
                
                case INDEX_T2RIFLE:
                {
                    if (_:g_iSpecialEvent == EVT_L4D1) {
                        g_strArStorage[curEnt][entPickedType] = PCK_RIFLE;
                    } else {
                        if (GetRandomInt(0, RATE_CSS - 1) == 0) {
                            g_strArStorage[curEnt][entPickedType] = PCK_RIFLE_SG552;
                        } else {
                            new tmpRnd = GetRandomInt(0, 2);
                            switch (tmpRnd)  {
                                case 0: {
                                    g_strArStorage[curEnt][entPickedType] = PCK_RIFLE;
                                }
                                case 1: {
                                    g_strArStorage[curEnt][entPickedType] = PCK_RIFLE_AK47;
                                }
                                case 2: {
                                    g_strArStorage[curEnt][entPickedType] = PCK_RIFLE_DESERT;
                                }
                            }
                        }
                    }
                    
                    if (g_strArStorage[curEnt][entPickedType] == _:PCK_RIFLE_AK47) {
                        g_strArStorage[curEnt][entAmmoMax] = RoundFloat(float(g_iActiveAmmoAk) * GetRandomFloat(fAmmoVarLess, fAmmoVarMore) * fAmmoFactor);
                    } else {
                        g_strArStorage[curEnt][entAmmoMax] = RoundFloat(GetConVarFloat(FindConVar("ammo_assaultrifle_max")) * GetRandomFloat(fAmmoVarLess, fAmmoVarMore) * fAmmoFactor);
                    }
                }
                
                case INDEX_T2SHOTGUN:
                {
                    if ( GetRandomInt(0, RATE_PUMPSHOT - 1) == 0 || _:g_iSpecialEvent == EVT_L4D1 ) {
                        g_strArStorage[curEnt][entPickedType] = PCK_AUTOSHOTGUN;
                    } else {
                        g_strArStorage[curEnt][entPickedType] = PCK_SHOTGUN_SPAS;
                    }                        
                    g_strArStorage[curEnt][entAmmoMax] = RoundFloat(GetConVarFloat(FindConVar("ammo_autoshotgun_max")) * GetRandomFloat(fAmmoVarLess, fAmmoVarMore) * fAmmoFactor);
                }
                
                case INDEX_SNIPER:
                {
                    if (_:g_iSpecialEvent == EVT_L4D1) {
                        g_strArStorage[curEnt][entPickedType] = PCK_HUNTING_RIFLE;
                        g_strArStorage[curEnt][entAmmoMax] = RoundFloat(GetConVarFloat(FindConVar("ammo_huntingrifle_max")) * GetRandomFloat(fAmmoVarLess, fAmmoVarMore) * fAmmoFactor);
                    }
                    else if (_:g_iSpecialEvent == EVT_SNIPER || GetRandomInt(0, RATE_CSS_SNIPER - 1) == 0) {
                        if (GetRandomInt(0, 1) == 0) {
                            g_strArStorage[curEnt][entPickedType] = PCK_SNIPER_SCOUT;
                            g_strArStorage[curEnt][entAmmoMax] = RoundFloat(float(g_iActiveAmmoScout) * GetRandomFloat(fAmmoVarLess, fAmmoVarMore) * fAmmoFactor);
                        } else {
                            g_strArStorage[curEnt][entPickedType] = PCK_SNIPER_AWP;
                            g_strArStorage[curEnt][entAmmoMax] = RoundFloat(float(g_iActiveAmmoAWP) * GetRandomFloat(fAmmoVarLess, fAmmoVarMore) * fAmmoFactor);
                        }
                    }
                    else {
                        if (GetRandomInt(0, 1) == 0) {
                            g_strArStorage[curEnt][entPickedType] = PCK_HUNTING_RIFLE;
                            g_strArStorage[curEnt][entAmmoMax] = RoundFloat(GetConVarFloat(FindConVar("ammo_huntingrifle_max")) * GetRandomFloat(fAmmoVarLess, fAmmoVarMore) * fAmmoFactor);
                        } else {
                            g_strArStorage[curEnt][entPickedType] = PCK_SNIPER_MILITARY;
                            g_strArStorage[curEnt][entAmmoMax] = RoundFloat(GetConVarFloat(FindConVar("ammo_sniperrifle_max")) * GetRandomFloat(fAmmoVarLess, fAmmoVarMore) * fAmmoFactor);
                        }
                    }
                }
                
                case INDEX_MELEE:
                {
                    new meleeRandomPick = GetRandomInt(0, g_iMeleeClassCount-1);
                    g_strArStorage[curEnt][entPickedType] = PCK_MELEE;
                    g_sArStorageMelee[curEnt] = g_sMeleeClass[meleeRandomPick];
                }
                
                case INDEX_T3:
                {
                    new tmpRnd = GetRandomInt(0, 2);
                    switch (tmpRnd)  {
                        case 0: {
                            g_strArStorage[curEnt][entPickedType] = PCK_CHAINSAW;
                            //g_strArStorage[curEnt][entAmmoMax] = GetConVarInt(FindConVar("ammo_chainsaw_max"));
                        }
                        case 1: {
                            g_strArStorage[curEnt][entPickedType] = PCK_GRENADE_LAUNCHER;
                            g_strArStorage[curEnt][entAmmoMax] = RoundFloat(GetConVarFloat(FindConVar("ammo_grenadelauncher_max")) * GetRandomFloat(fAmmoVarLess, fAmmoVarMore));
                        }
                        case 2: {
                            g_strArStorage[curEnt][entPickedType] = PCK_RIFLE_M60;
                            g_strArStorage[curEnt][entAmmoMax] = RoundFloat(GetConVarFloat(g_hCvarM60Ammo) * GetRandomFloat(fAmmoVarLess, fAmmoVarMore));
                            
                        }
                    }
                }
                
                case INDEX_CANISTER:
                {
                    if (GetRandomInt(0, RATE_CAN_BARREL - 1) == 0) {
                        g_strArStorage[curEnt][entPickedType] = PCK_EXPLOSIVE_BARREL;

                    } else if (GetRandomInt(0, RATE_CAN_GAS - 1) == 0) {
                        if (GetRandomInt(0, 1) == 0) {
                            g_strArStorage[curEnt][entPickedType] = PCK_PROPANETANK;
                        } else {
                            g_strArStorage[curEnt][entPickedType] = PCK_OXYGENTANK;
                        }
                    } else {
                        if (GetRandomInt(0, 1) == 0) {
                            g_strArStorage[curEnt][entPickedType] = PCK_GASCAN;
                        } else {
                            g_strArStorage[curEnt][entPickedType] = PCK_FIREWORKCRATE;
                        }
                    }
                }
                
                case INDEX_PILL:
                {
                    if ( ( GetRandomInt(0, RATE_ADREN - 1) == 0 || _:g_iSpecialEvent == EVT_ADREN ) && _:g_iSpecialEvent != EVT_L4D1 ) {
                        g_strArStorage[curEnt][entPickedType] = PCK_ADRENALINE;
                    } else {
                        g_strArStorage[curEnt][entPickedType] = PCK_PAIN_PILLS;
                    }
                }
                
                case INDEX_THROWABLE:
                {
                    new tmpRnd = GetRandomInt(0, (_:g_iSpecialEvent == EVT_L4D1) ? 1 : 2 );
                    switch (tmpRnd)  {
                        case 0: {
                            g_strArStorage[curEnt][entPickedType] = PCK_PIPEBOMB;
                        }
                        case 1: {
                            g_strArStorage[curEnt][entPickedType] = PCK_MOLOTOV;
                        }
                        case 2: {
                            g_strArStorage[curEnt][entPickedType] = PCK_VOMITJAR;
                        }
                    }
                }
                
                case INDEX_KIT:
                {
                    // special event: only defibs
                    if ( ( GetRandomInt(0, RATE_DEFIB - 1) == 0 || _:g_iSpecialEvent == EVT_DEFIB || _:g_iSpecialEvent == EVT_ADREN ) && _:g_iSpecialEvent != EVT_L4D1 ) {
                        g_strArStorage[curEnt][entPickedType] = PCK_DEFIBRILLATOR;
                    } else {
                        g_strArStorage[curEnt][entPickedType] = PCK_FIRST_AID_KIT;
                    }
                }
                
                case INDEX_AMMO:
                {
                    g_strArStorage[curEnt][entPickedType] = PCK_AMMO;
                    g_strArStorage[curEnt][entCheckOrigin] = true;
                }
                
                case INDEX_UPGRADE:
                {
                    if (GetRandomInt(0, RATE_UPG_LASER - 1) == 0) {
                        g_strArStorage[curEnt][entPickedType] = PCK_UPG_LASER;
                    } else if (GetRandomInt(0, RATE_UPG_EXPLOSIVE - 1) == 0) {
                        g_strArStorage[curEnt][entPickedType] = PCK_UPG_EXPLOSIVE;
                    } else {
                        g_strArStorage[curEnt][entPickedType] = PCK_UPG_INCENDIARY;
                    }
                    //ammo_ammo_pack_max (required?)
                }
                
                case INDEX_JUNK:
                {
                    g_strArStorage[curEnt][entPickedType] = PCK_JUNK;
                    g_strArStorage[curEnt][entJunkType] = GetRandomInt(0, sizeof(g_csJunkModels) - 1);
                }
                
                case INDEX_NOITEM:
                {
                    g_strArStorage[curEnt][entPickedType] = PCK_NOITEM;
                    iCountNoitem++;
                }
                
                case INDEX_SILLY:
                {
                    new tmpRnd = GetRandomInt(0, 2);
                    if (!g_RI_bNoCola && tmpRnd == 1) {
                        g_strArStorage[curEnt][entPickedType] = PCK_SILLY_COLA;
                    } else {
                        g_strArStorage[curEnt][entPickedType] = PCK_SILLY_GNOME;
                    }
                }
                
                case INDEX_GIFT:
                {
                    g_strArStorage[curEnt][entPickedType] = PCK_SILLY_GIFT;
                    g_strArStorage[curEnt][entCheckOrigin] = true;
                }
            }
            
            // TEST
            //PrintDebug(3, "[rand] Picked ent %i: type = %i =pick=> %i", g_iStoredEntities, randomPick, g_strArStorage[curEnt][entPickedType]);

            // lookup position
            decl Float: origin[3];
            decl Float: angles[3];
            
            GetEntPropVector(i, Prop_Send, "m_vecOrigin", origin);
            GetEntPropVector(i, Prop_Send, "m_angRotation", angles);
            
            // handle fire extinguisher reposition
            if (bIsFireExtinguisher)
            {
                //PrintDebug(3, "fireext: angle: %.f[origin now: %.1f %.1f]", angles[1], origin[0], origin[1]);
                switch (RoundToFloor(angles[1]))
                {
                    case 90:            { origin[1] += FIREEXT_POS_OFFSET; }
                    case -90, 270:      { origin[1] -= FIREEXT_POS_OFFSET; }
                    case 0:             { origin[0] += FIREEXT_POS_OFFSET; }
                    case -180, 180:     { origin[0] -= FIREEXT_POS_OFFSET; }
                }
                //PrintDebug(3, "fireext: [origin new: %.1f %.1f]", origin[0], origin[1]);
                
                // also move it down a bit if it's upright
                if (RoundToFloor(angles[0]) == 0 && RoundToFloor(angles[2]) == 0)
                {
                    origin[2] -= FIREEXT_POS_OFFSET_Z;
                }
            }
            
            //      if ammo spawn, ignore original angles
            if (    randomPick == INDEX_AMMO
                ||  randomPick == INDEX_UPGRADE
            ) {
                    angles[0] = 0.0; angles[1] = 0.0; angles[2] = 0.0;
            }
            
            g_strArStorage[curEnt][entOrigin_a] = origin[0];
            g_strArStorage[curEnt][entOrigin_b] = origin[1];
            g_strArStorage[curEnt][entOrigin_c] = origin[2];
            g_strArStorage[curEnt][entAngles_a] = angles[0];
            g_strArStorage[curEnt][entAngles_b] = angles[1];
            g_strArStorage[curEnt][entAngles_c] = angles[2];

            
            // angle 90 = +in y direction
            
            
            
            // copy spawnflags
            if (!(GetEntProp(i, Prop_Data, "m_spawnflags") & 1)) {
                g_strArStorage[curEnt][entSpawnPhysics] = true;
            }
            
            /*
            // debug:
            if (g_strArStorage[curEnt][entInStartSaferoom]) {
                PrintDebug(2, "start saferoom item: %i: %s (became %i (%s)).", i, classname, g_strArStorage[curEnt][entPickedType], g_csItemTypeText[randomPick]);
            } else if (g_strArStorage[curEnt][entInEndSaferoom]) {
                PrintDebug(2, "end saferoom item: %i: %s (became %i (%s)).", i, classname, g_strArStorage[curEnt][entPickedType], g_csItemTypeText[randomPick]);
            }
            */
            
            // kill the replaced entity
            AcceptEntityInput(i, "Kill");
        }
        
    }
    
    /*
        we can do saferoom checks and balances here
        for ideas, see notes at start of document
    */
    new countStartAmmo = 0;
    new countStartGnome = 0;
    
    // track starting items
    new countStartItems = 0;
    new arStartItems[32];
    
    for (new i=0; i < g_iStoredEntities; i++)
    {
        if (g_strArStorage[i][entInStartSaferoom] == true)
        {
            arStartItems[countStartItems] = i;
            countStartItems++;
            
            if (g_strArStorage[i][entPickedType] == _:PCK_SILLY_GNOME) { countStartGnome++; }
            else if (g_strArStorage[i][entPickedType] == _:PCK_AMMO) { countStartAmmo++; }
        }
    }
    
    // chance/force gnome to be in start saferoom
    if (!countStartGnome && GetRandomFloat(0.001,1.0) <= GetConVarFloat(g_hCvarStartItemGnome))
    {
        new changeIndex = GetRandomInt(0, countStartItems - 1);
        changeIndex = arStartItems[changeIndex];
        
        g_strArStorage[changeIndex][entPickedType] = PCK_SILLY_GNOME;
        g_strArStorage[changeIndex][entCheckOrigin] = false;
        g_strArStorage[changeIndex][entSpawnPhysics] = false;
        g_strArStorage[changeIndex][entAmmoMax] = 0;
    }
    
    // chance/force ammo to be in start saferoom
    if (!countStartAmmo && !g_bNoAmmo && GetRandomFloat(0.001,1.0) <= GetConVarFloat(g_hCvarStartItemAmmo))
    {
        new changeIndex = GetRandomInt(0, countStartItems - 1);
        changeIndex = arStartItems[changeIndex];
        
        g_strArStorage[changeIndex][entPickedType] = PCK_AMMO;
        g_strArStorage[changeIndex][entCheckOrigin] = true;
        g_strArStorage[changeIndex][entSpawnPhysics] = false;
        g_strArStorage[changeIndex][entAmmoMax] = 0;
        g_strArStorage[changeIndex][entAngles_a] = 0.0;
        g_strArStorage[changeIndex][entAngles_b] = 0.0;
        g_strArStorage[changeIndex][entAngles_c] = 0.0;
    }
    
    
    // now add the entities (afterwards, so we don't remove intentionally added stuff)
    for (new i=0; i < g_iStoredEntities; i++)
    {
        CreateEntity(i);
    }
    
    // also add hittables
    for (new i=0; i < g_iStoredHittables; i++)
    {
        CreateHittable(i);
    }
    
    // done, do a report
    DoItemsServerReport();
    
    
    // testing: did the item drop underneath the map?
    CreateTimer(TESTENTITY_TIMER, Timer_TestEntityLocation);
    
    g_bItemsFullyRandomized = true;
}


public Action:Timer_TestEntityLocation(Handle:timer)
{
    // compare current origin z to the one stored
    
    new Float: itemOriginOrg[3], Float: itemOriginCur[3];
    new Float: tmpVec[3];
    tmpVec[2] = -1.0;                                          // small downward push so they still 'drop'
    new entity;

    
    for (new i=0; i < g_iStoredEntities; i++)
    {
        entity = g_strArStorage[i][entNumber];
        //PrintToServer("Entity %i = %i", i, entity);
        
        if (entity > 0 && IsValidEntity(entity)) {
            itemOriginOrg[2] = g_strArStorage[i][entOrigin_c];
            GetEntPropVector(entity, Prop_Send, "m_vecOrigin", itemOriginCur);
            
            if (FloatAbs(itemOriginCur[2] - itemOriginOrg[2]) > TESTENTITY_THRESH)
            {
                // teleport it up a bit higher
                itemOriginOrg[0] = g_strArStorage[i][entOrigin_a];
                itemOriginOrg[1] = g_strArStorage[i][entOrigin_b];
                itemOriginOrg[2] += TESTENTITY_UPSHIFT;
                
                TeleportEntity(entity, itemOriginOrg, NULL_VECTOR, tmpVec);
                
                PrintToServer("Shifted entity that fell through floor %i: %.3f (location: %.1f %.1f %.1f)", entity, FloatAbs(itemOriginCur[2] - itemOriginOrg[2]), itemOriginCur[0], itemOriginCur[1], itemOriginCur[2]);
            }
        }
    }
    
}

// let the same magic happen as before
RestoreItems()
{
    new String:classname[128];
    new RandomizableOrNot: classnameRoN;
    
    new entityCount = GetEntityCount();
    
    for (new i=0; i < entityCount; i++)
    {
        if (IsValidEntity(i)) {
        
            GetEdictClassname(i, classname, sizeof(classname));
            
            if (!GetTrieValue(g_hTrieRandomizableEntity, classname, classnameRoN)) { continue; }                        // if it's not randomizable, we don't need to bother with it at all
            
            if (classnameRoN == RANDOMIZABLE_PHYSICS) 
            {
                new String:modelname[STR_MAX_MODELNAME];
                GetEntPropString(i, Prop_Data, "m_ModelName", modelname, STR_MAX_MODELNAME);
                if (!GetTrieValue(g_hTrieRandomizablePropPhysicsModel, modelname, classnameRoN)) { continue; }          // if it's not one of the prop_physics models, don't worry about it
                
                // hittables
                if ((classnameRoN == HITTABLE_PHYSICS || classnameRoN == HITTABLE_PHYSICS_SMALL || classnameRoN == HITTABLE_PHYSICS_CAR || classnameRoN == HITTABLE_PHYSICS_ADDON))
                {
                    if (!GetConVarBool(g_hCvarRandomHittables)) { continue; }
                    
                    AcceptEntityInput(i, "Kill");
                    continue;
                }
            }
            
            // the entity was randomize material, delete it now
            AcceptEntityInput(i, "Kill");
        }
    }
    
    
    // restore previous round's picks
    for (new i=0; i < g_iStoredEntities; i++)
    {
        CreateEntity(i);
    }
    
    // also add hittables
    for (new i=0; i < g_iStoredHittables; i++)
    {
        CreateHittable(i);
    }
    
    // testing: did the item drop underneath the map?
    CreateTimer(TESTENTITY_TIMER, Timer_TestEntityLocation);
    
    g_bItemsFullyRandomized = true;
}

PickRandomItem(bool:onlyUseful = false, bool:noLaserSight = false, bool:noWeapons = false)
{
    // just pick any random item.
    //  weighted? not for this, not for now.
    //  save in temporary struct
    
    new randomPick = PCK_NOITEM;
    new randomIndex = INDEX_NOITEM;
    new Float: fAmmoFactor = (_:g_iSpecialEvent == EVT_AMMO) ? g_RC_fEventAmmoFactor : 1.0;
    
    // if we're doing weapons, we're still not doing NOITEM, so start at pistol (1)
    // otherwise, start at first non-weapon item
    // then limit to either total or last useful
    
    new count = 0;
    while (randomIndex == INDEX_NOITEM && count < 1000)
    {
        if (onlyUseful) {
            randomIndex = GetRandomInt( (noWeapons) ? INDEX_CANISTER : INDEX_PISTOL, INDEX_LAST_USEFUL);
        } else {
            randomIndex = GetRandomInt( (noWeapons) ? INDEX_CANISTER : INDEX_PISTOL, INDEX_TOTAL - 1);
        }
        
        // don't pick something with 0 weight
        count++;
        if (GetConVarInt(g_hArCvarWeight[randomIndex]) == 0) {
            randomIndex = INDEX_NOITEM;
        }
    }
    
    new Float: fAmmoVarMore = 1.0 + GetConVarFloat(g_hCvarAmmoVarianceMore);
    new Float: fAmmoVarLess = 1.0 - GetConVarFloat(g_hCvarAmmoVarianceLess);
    
    // clean temp storage
    g_strTempItemSingle[entPickedType] = 0;
    g_strTempItemSingle[entSpawnPhysics] = false;
    g_strTempItemSingle[entAmmoMax] = 0;
    g_strTempItemSingle[entCheckOrigin] = false;
    g_sTempItemSingleMelee = "";
    
    // sniper special event
    if (_:g_iSpecialEvent == EVT_SNIPER) {
        switch (randomIndex) {
            case INDEX_T1SMG: { randomIndex = INDEX_SNIPER; }
            case INDEX_T1SHOTGUN: { randomIndex = INDEX_SNIPER; }
            case INDEX_T2RIFLE: { randomIndex = INDEX_SNIPER; }
            case INDEX_T2SHOTGUN: { randomIndex = INDEX_SNIPER; }
            case INDEX_T3: { randomIndex = INDEX_SNIPER; }
        }
    }
    else if (_:g_iSpecialEvent == EVT_SKEET) {
        switch (randomIndex) {
            case INDEX_T1SMG: { randomIndex = INDEX_T1SHOTGUN; }
            case INDEX_SNIPER: { randomIndex = INDEX_T1SHOTGUN; }
            case INDEX_T2RIFLE: { randomIndex = INDEX_T2SHOTGUN; }
            case INDEX_T3: { randomIndex = INDEX_T2SHOTGUN; }
        }
    }
    else if (_:g_iSpecialEvent == EVT_FIREPOWER) {
        switch (randomIndex) {
            case INDEX_T1SMG: { randomIndex = INDEX_T2RIFLE; }
            case INDEX_T1SHOTGUN: { randomIndex = INDEX_T2SHOTGUN; }
        }
    }
    else if (_:g_iSpecialEvent == EVT_L4D1) {
        if ( randomIndex == INDEX_MELEE || randomIndex == INDEX_T3 || randomIndex == INDEX_UPGRADE ) { randomIndex = INDEX_PISTOL; }
    }
    else if (_:g_iSpecialEvent == EVT_GUNSWAP) {
        if ( randomIndex == INDEX_AMMO || randomIndex == INDEX_UPGRADE ) { randomIndex = (GetRandomInt(0,1)) ? INDEX_THROWABLE : INDEX_PILL; }
    }
    else if (_:g_iSpecialEvent == EVT_MEDIC) {
        switch (randomIndex) {
            case INDEX_KIT: { randomIndex = INDEX_PISTOL; }
            case INDEX_PILL: { randomIndex = INDEX_THROWABLE; }
            case INDEX_UPGRADE: { randomIndex = INDEX_MELEE; }
        }
    }
    
    switch (randomIndex)
    {
        case INDEX_PISTOL: {
            if (GetRandomInt(0, 1) == 0 && _:g_iSpecialEvent != EVT_L4D1) { randomPick = PCK_PISTOL_MAGNUM; } else { randomPick = PCK_PISTOL; }
        }
        
        case INDEX_T1SMG: {
            new tmpRnd = GetRandomInt(0, 2);
            if (_:g_iSpecialEvent == EVT_L4D1) { tmpRnd = 1; }
            switch (tmpRnd)  {
                case 0: { randomPick = PCK_SMG_MP5; }
                case 1: { randomPick = PCK_SMG; }
                case 2: { randomPick = PCK_SMG_SILENCED; }
            }
            g_strTempItemSingle[entAmmoMax] = RoundFloat(GetConVarFloat(FindConVar("ammo_smg_max")) * GetRandomFloat(fAmmoVarLess, fAmmoVarMore) * fAmmoFactor);
        }
        
        case INDEX_T1SHOTGUN: {
            if (GetRandomInt(0, 1) == 0 || _:g_iSpecialEvent == EVT_L4D1) { randomPick = PCK_PUMPSHOTGUN; } else { randomPick = PCK_SHOTGUN_CHROME; }
            g_strTempItemSingle[entAmmoMax] = RoundFloat(GetConVarFloat(FindConVar("ammo_shotgun_max")) * GetRandomFloat(fAmmoVarLess, fAmmoVarMore) * fAmmoFactor);
        }
        
        case INDEX_T2RIFLE: {
            new tmpRnd = GetRandomInt(0, 3);
            if (_:g_iSpecialEvent == EVT_L4D1) { tmpRnd = 1; }
            switch (tmpRnd)  {
                case 0: { randomPick = PCK_RIFLE_SG552; }
                case 1: { randomPick = PCK_RIFLE; }
                case 2: { randomPick = PCK_RIFLE_AK47; }
                case 3: { randomPick = PCK_RIFLE_DESERT; }
            }
            
            if (randomPick == _:PCK_RIFLE_AK47) {
                g_strTempItemSingle[entAmmoMax] = RoundFloat(float(g_iActiveAmmoAk) * GetRandomFloat(fAmmoVarLess, fAmmoVarMore) * fAmmoFactor);
            } else {
                g_strTempItemSingle[entAmmoMax] = RoundFloat(GetConVarFloat(FindConVar("ammo_assaultrifle_max")) * GetRandomFloat(fAmmoVarLess, fAmmoVarMore) * fAmmoFactor);
            }
        }
        
        case INDEX_T2SHOTGUN: {
            if (GetRandomInt(0, 1) == 0 || _:g_iSpecialEvent == EVT_L4D1) { randomPick = PCK_AUTOSHOTGUN; } else { randomPick = PCK_SHOTGUN_SPAS; }
            g_strTempItemSingle[entAmmoMax] = RoundFloat(GetConVarFloat(FindConVar("ammo_autoshotgun_max")) * GetRandomFloat(fAmmoVarLess, fAmmoVarMore) * fAmmoFactor);
        }
        
        case INDEX_SNIPER: {
            new tmpRnd = GetRandomInt(0, 3);
            if (_:g_iSpecialEvent == EVT_L4D1) { tmpRnd = 2; }
            switch (tmpRnd)  {
                case 0: { randomPick = PCK_SNIPER_SCOUT;
                          g_strTempItemSingle[entAmmoMax] = RoundFloat(float(g_iActiveAmmoScout) * GetRandomFloat(fAmmoVarLess, fAmmoVarMore) * fAmmoFactor); }
                case 1: { randomPick = PCK_SNIPER_AWP;
                          g_strTempItemSingle[entAmmoMax] = RoundFloat(float(g_iActiveAmmoAWP) * GetRandomFloat(fAmmoVarLess, fAmmoVarMore) * fAmmoFactor); }
                case 2: { randomPick = PCK_HUNTING_RIFLE;
                          g_strTempItemSingle[entAmmoMax] = RoundFloat(GetConVarFloat(FindConVar("ammo_huntingrifle_max")) * GetRandomFloat(fAmmoVarLess, fAmmoVarMore) * fAmmoFactor); }
                case 3: { randomPick = PCK_SNIPER_MILITARY;
                          g_strTempItemSingle[entAmmoMax] = RoundFloat(GetConVarFloat(FindConVar("ammo_sniperrifle_max")) * GetRandomFloat(fAmmoVarLess, fAmmoVarMore) * fAmmoFactor); }
            }
        }
        
        case INDEX_MELEE: {
            randomPick = PCK_MELEE;
            new meleeRandomPick = GetRandomInt(0, g_iMeleeClassCount-1);
            g_sTempItemSingleMelee = g_sMeleeClass[meleeRandomPick];
        }
        
        case INDEX_T3: {
            new tmpRnd = GetRandomInt(0, 2);
            switch (tmpRnd)  {
                case 0: { randomPick = PCK_CHAINSAW; }
                case 1: { randomPick = PCK_GRENADE_LAUNCHER;
                          g_strTempItemSingle[entAmmoMax] = RoundFloat(GetConVarFloat(FindConVar("ammo_grenadelauncher_max")) * GetRandomFloat(fAmmoVarLess, fAmmoVarMore)); }
                case 2: { randomPick = PCK_RIFLE_M60; 
                          g_strTempItemSingle[entAmmoMax] = RoundFloat(GetConVarFloat(g_hCvarM60Ammo) * GetRandomFloat(fAmmoVarLess, fAmmoVarMore)); }
            }
        }
        
        case INDEX_CANISTER: {
            new tmpRnd = GetRandomInt(0, 3);
            if (tmpRnd == 4 && onlyUseful) { tmpRnd = 0; }
            switch (tmpRnd) {
                case 0: { randomPick = PCK_GASCAN; }
                case 1: { randomPick = PCK_PROPANETANK; }
                case 2: { randomPick = PCK_OXYGENTANK; }
                case 3: { randomPick = PCK_FIREWORKCRATE; }
                case 4: { randomPick = PCK_EXPLOSIVE_BARREL; }
            }
        }
        
        case INDEX_PILL: {
            if (GetRandomInt(0, 1) == 0 || _:g_iSpecialEvent == EVT_ADREN && _:g_iSpecialEvent != EVT_L4D1) { randomPick = PCK_ADRENALINE; } else { randomPick = PCK_PAIN_PILLS; }
        }
        
        case INDEX_THROWABLE: {
            new tmpRnd = GetRandomInt(0, (_:g_iSpecialEvent == EVT_L4D1) ? 1 : 2 );
            switch (tmpRnd)  {
                case 0: { randomPick = PCK_PIPEBOMB; }
                case 1: { randomPick = PCK_MOLOTOV; }
                case 2: { randomPick = PCK_VOMITJAR; }
            }
        }
        
        case INDEX_KIT: {
            if (GetRandomInt(0, 4) < 2 || _:g_iSpecialEvent == EVT_DEFIB && _:g_iSpecialEvent != EVT_L4D1) { randomPick = PCK_DEFIBRILLATOR; } else { randomPick = PCK_FIRST_AID_KIT; }
        }
        
        case INDEX_AMMO: { randomPick = PCK_AMMO; }
        
        case INDEX_UPGRADE: {
            new tmpRnd = GetRandomInt(0, 2);
            if (tmpRnd == 0 && noLaserSight) { tmpRnd = 2; }
            switch (tmpRnd)  {
                case 0: { randomPick = PCK_UPG_LASER; }
                case 1: { randomPick = PCK_UPG_EXPLOSIVE; }
                case 2: { randomPick = PCK_UPG_INCENDIARY; }
            }
        }
        
        case INDEX_JUNK: {
            randomPick = PCK_JUNK;
            g_strTempItemSingle[entJunkType] = GetRandomInt(0, sizeof(g_csJunkModels) - 1);
        }
        
        case INDEX_SILLY: {
            if (!g_RI_bNoCola && GetRandomInt(0, 1) == 0) { randomPick = PCK_SILLY_COLA; } else { randomPick = PCK_SILLY_GNOME; }
        }
        
        case INDEX_GIFT: {
            randomPick = PCK_SILLY_GIFT;
        }
    }
    
    //PrintDebug(3, "[rand] PickRandomItem: pick index: %i - item %i", randomIndex, randomPick);
    
    g_strTempItemSingle[entPickedType] = randomPick;
    
    return randomPick;
}


// pick random starting setup for survivors
RandomizeSurvivorItems()
{
    new iCountPrimary = 0;      new iCountPills = 0;
    new iCountGift = 0;         new iCountAdren = 0;
    new iCountMelee = 0;
    new iCountSecondary = 0;
    new iCountStrip = 0;
    new randomPick;
    new secondaryPick;          // additional to primaries, if we force a minimum
    new meleeRandomPick;
    
    new iMinPrimary = 1;
    new iMinSecondary = 2;      // special case though, not used for now
    
    new Float: fPillsChance = GetConVarFloat(g_hCvarPillsChance);
    new bool: bPrimaryForced = false;
    new bool: bSecondaryForced = false;
    
    new Float: fAmmoVarMore = 1.0 + GetConVarFloat(g_hCvarAmmoVarianceMore);
    new Float: fAmmoVarLess = 1.0 - GetConVarFloat(g_hCvarAmmoVarianceLess);
    new Float: fAmmoFactor = (_:g_iSpecialEvent == EVT_AMMO) ? g_RC_fEventAmmoFactor : 1.0;


    // minimum supplies for higher difficulty rounds
    if (GetConVarBool(g_hCvarStartBalanceSurv))
    {
        if (GetConVarBool(g_hCvarDifficultyBalance))
        {
            if (g_iDifficultyRating >= DIFF_RATING_4PRIM_THRESH) {
                iMinPrimary = 4;
                iMinSecondary = 4;
            } else if (g_bTankIsEarly) {                                        // force near full loadout on early tank
                iMinPrimary = 4;
                iMinSecondary = 2;
            } else if (g_iDifficultyRating >= DIFF_RATING_3PRIM_THRESH)  {
                iMinPrimary = 3;
                iMinSecondary = 2;
            } else if (g_iDifficultyRating >= DIFF_RATING_2PRIM_THRESH)  {
                iMinPrimary = 2;
                iMinSecondary = 1;
            }
        }
    } else {
        iMinPrimary = 0;
        iMinSecondary = 0;
    }
    
    for (new i=0; i < TEAM_SIZE; i++)
    {
        // pick a random option
        // save it to array
        
        // primary: adjust for minima
        if (i - iCountPrimary >= TEAM_SIZE - iMinPrimary) { bPrimaryForced = true; } else { bPrimaryForced = false; }
        
        randomPick = GetRandomInt( (bPrimaryForced) ? g_iSurvWeightedChoicesStartPrimary : 0 , (g_iSurvWeightedChoicesTotal-1));
        randomPick = g_iArSurvWeightedChoices[randomPick];
        
        // are we giving a secondary? adjust for minima
        if (i - iCountSecondary >= TEAM_SIZE - iMinSecondary) { bSecondaryForced = true; } else { bSecondaryForced = false; }
        
        if (bSecondaryForced || GetRandomFloat(0.001, 1.0) <= GetConVarFloat(g_hCvarExtraSecondaryChance)) {
            secondaryPick = GetRandomInt(g_iSurvWeightedChoicesStartSecondary, g_iSurvWeightedChoicesEndSecondary);
            secondaryPick = g_iArSurvWeightedChoices[secondaryPick];
        } else {
            secondaryPick = -1;
        }
        
        // adjust for l4d1 mode
        if ( _:g_iSpecialEvent == EVT_L4D1) {
            if (randomPick == INDEX_SURV_MELEE || randomPick == INDEX_SURV_MAGNUM) { randomPick = INDEX_SURV_DUALS; }
            if (secondaryPick == INDEX_SURV_MELEE || secondaryPick == INDEX_SURV_MAGNUM) { secondaryPick = INDEX_SURV_DUALS; }
        }
        // adjust for skeet event
        else if (_:g_iSpecialEvent == EVT_SKEET) {
            if (randomPick == INDEX_SURV_T1SMG) { randomPick = INDEX_SURV_T1SHOT; }
        }
        // only give melees for women event
        else if (_:g_iSpecialEvent == EVT_WOMEN) {
            randomPick = INDEX_SURV_MELEE;
            secondaryPick = -1;
        }
        else if (_:g_iSpecialEvent == EVT_WITCHES) {
            randomPick = INDEX_SURV_T1SHOT;
        }
        
        switch (randomPick)
        {
            case INDEX_SURV_NOTHING: {
                randomPick = PCK_NOITEM;
                iCountStrip++;
                // if we get nothing, keep secondary pick intact if we're forced to give a secondary
                if (!bSecondaryForced) { secondaryPick = -1; }
            }
            case INDEX_SURV_PISTOL: {       randomPick = PCK_PISTOL; iCountSecondary++; secondaryPick = -1; }
            case INDEX_SURV_DUALS: {        randomPick = PCK_DUALS; iCountSecondary++; iCountGift++; secondaryPick = -1; }
            case INDEX_SURV_MAGNUM: {       randomPick = PCK_PISTOL_MAGNUM; iCountSecondary++; iCountGift++; secondaryPick = -1; }
            
            case INDEX_SURV_T1SMG: {
                iCountPrimary++;
                if (_:g_iSpecialEvent == EVT_L4D1) {
                    randomPick = PCK_SMG;
                } else {
                    if (GetRandomInt(0, RATE_CSS - 1) == 0) {
                        randomPick = PCK_SMG_MP5;
                    } else {
                        if (GetRandomInt(0, RATE_SMG - 1) == 0) {
                            randomPick = PCK_SMG;
                        } else {
                            randomPick = PCK_SMG_SILENCED;
                        }
                    }
                }
                g_iArStorageSurvAmmo[i] = RoundFloat(GetConVarFloat(FindConVar("ammo_smg_max")) * GetRandomFloat(fAmmoVarLess, fAmmoVarMore) * fAmmoFactor);
                iCountGift++;
            }
            
            case INDEX_SURV_T1SHOT: {
                iCountPrimary++;
                if ( GetRandomInt(0, RATE_PUMPSHOT - 1) == 0 || _:g_iSpecialEvent == EVT_L4D1 ) {
                    randomPick = PCK_PUMPSHOTGUN;
                } else {
                    randomPick = PCK_SHOTGUN_CHROME;
                }
                g_iArStorageSurvAmmo[i] = RoundFloat(GetConVarFloat(FindConVar("ammo_shotgun_max")) * GetRandomFloat(fAmmoVarLess, fAmmoVarMore) * fAmmoFactor);
                iCountGift++;
            }
            
            case INDEX_SURV_MELEE: {
                randomPick = PCK_MELEE;
                meleeRandomPick = GetRandomInt(0, sizeof(g_iMeleeClassCount) - 1);
                g_iArStorageSurvMelee[i] = meleeRandomPick;
                iCountGift++;
                iCountMelee++;
                iCountSecondary++;
                secondaryPick = -1;
            }
        }
        
        if (secondaryPick != -1)
        {
            switch (secondaryPick)
            {
                case INDEX_SURV_PISTOL: {       secondaryPick = PCK_PISTOL; iCountSecondary++; }
                case INDEX_SURV_DUALS: {        secondaryPick = PCK_DUALS; iCountSecondary++; }
                case INDEX_SURV_MAGNUM: {       secondaryPick = PCK_PISTOL_MAGNUM; iCountSecondary++; }
                
                case INDEX_SURV_MELEE: {
                    secondaryPick = PCK_MELEE;
                    meleeRandomPick = GetRandomInt(0, sizeof(g_iMeleeClassCount) - 1);
                    g_iArStorageSurvMelee[i] = meleeRandomPick;
                    iCountMelee++;
                    iCountSecondary++;
                }
                
                default: { secondaryPick = PCK_NOITEM; /* shouldn't occur */ }
            }
        }
        else
        {
            secondaryPick = PCK_NOITEM;
        }
        
        
        // store current pick
        g_iArStorageSurv[i] = randomPick;
        g_iArStorageSurvSec[i] = secondaryPick;
        
        
        // pills?
        if (_:g_iSpecialEvent == EVT_ADREN) {
            // force adrenaline for special event
            g_iArStorageSurvPills[i] = PCK_ADRENALINE;
            iCountAdren++;
        }
        else if (_:g_iSpecialEvent == EVT_DEFIB) {
            // force defib for special event
            g_iArStorageSurvPills[i] = PCK_PAIN_PILLS;
            iCountPills++;
        }
        else if (_:g_iSpecialEvent == EVT_MEDIC) {
            // no pills for anyone (yet)
            g_iArStorageSurvPills[i] = PCK_NOITEM;
        }
        else if ( GetRandomFloat(0.001, 1.0) <= fPillsChance || (GetConVarBool(g_hCvarStartBalanceSurv) && GetConVarBool(g_hCvarDifficultyBalance) && g_iDifficultyRating > DIFF_RATING_PILL_THRESH) ) {
            // randomly picked.. or difficulty forced
            randomPick = GetRandomInt(0, RATE_ADREN);
            
            switch (randomPick)  {
                case 0:  { g_iArStorageSurvPills[i] = PCK_ADRENALINE; iCountAdren++; }
                default: { g_iArStorageSurvPills[i] = PCK_PAIN_PILLS; iCountPills++; }
            }
        } else {
            g_iArStorageSurvPills[i] = PCK_NOITEM;
        }
    }
    
    // check for special event
    if (g_iSpecialEvent == _:EVT_GUNSWAP)
    {
        // give nothing but pistol (or melee)
        for (new i=0; i < TEAM_SIZE; i++) {
            g_iArStorageSurv[i] = PCK_PISTOL;
            g_iArStorageSurvSec[i] = -1;
        }
    }
    //      so many doors locked, guarantee two melees
    //      but ignore for keymaster event, since the keymaster can unlock
    else if (g_iSpecialEvent != _:EVT_KEYMASTER)
    {
        if (g_iSpecialEvent == _:EVT_DOORS && iCountMelee < EVENT_DOORS_MINMELEE)
        {
            PrintDebug(2, "[rand] Adding melees to deal with special event.");
            for (new i=0; i < TEAM_SIZE; i++)
            {
                if (g_iArStorageSurv[i] != _:PCK_MELEE && g_iArStorageSurvSec[i] != _:PCK_MELEE) {
                    if (g_iArStorageSurv[i] == _:PCK_SMG || g_iArStorageSurv[i] == _:PCK_SMG_SILENCED || g_iArStorageSurv[i] == _:PCK_SMG_MP5 || g_iArStorageSurv[i] == _:PCK_PUMPSHOTGUN || g_iArStorageSurv[i] == _:PCK_SHOTGUN_CHROME) {
                        g_iArStorageSurvSec[i] = PCK_MELEE;
                    } else {
                        g_iArStorageSurv[i] = PCK_MELEE;
                    }
                    meleeRandomPick = GetRandomInt(0, sizeof(g_iMeleeClassCount) - 1);
                    g_iArStorageSurvMelee[i] = meleeRandomPick;
                    iCountMelee++;
                    if (iCountMelee >= EVENT_DOORS_MINMELEE) { break; }
                }
            }
        }
        // do a similar check if there are early door locks
        else if (g_bEarlyLock && iCountMelee < EARLY_DOORS_MINMELEE && _:g_iSpecialEvent != EVT_BADCOMBO)
        {
            PrintDebug(2, "[rand] Adding melees to deal with early locks.");
            for (new i=0; i < TEAM_SIZE; i++)
            {
                if (g_iArStorageSurv[i] != _:PCK_MELEE && g_iArStorageSurvSec[i] != _:PCK_MELEE) {
                    if (g_iArStorageSurv[i] == _:PCK_SMG || g_iArStorageSurv[i] == _:PCK_SMG_SILENCED || g_iArStorageSurv[i] == _:PCK_SMG_MP5 || g_iArStorageSurv[i] == _:PCK_PUMPSHOTGUN || g_iArStorageSurv[i] == _:PCK_SHOTGUN_CHROME) {
                        g_iArStorageSurvSec[i] = PCK_MELEE;
                    } else {
                        g_iArStorageSurv[i] = PCK_MELEE;
                    }
                    meleeRandomPick = GetRandomInt(0, sizeof(g_iMeleeClassCount) - 1);
                    g_iArStorageSurvMelee[i] = meleeRandomPick;
                    iCountMelee++;
                    if (iCountMelee >= EARLY_DOORS_MINMELEE) { break; }
                }
            }
        }
    }
    
    
    /*
        don't do this here (yet) .. too imprecise without taking start saferoom status into account
    // difficulty-rating based on items? weapons / pills
    if (iCountPrimary < 2) { g_iDifficultyRating++; }
    else if (iCountPrimary < 3 && iCountMelee < 2) { g_iDifficultyRating++; }
    else if (iCountStrip > 1) { g_iDifficultyRating++; }
    
    if (iCountAdren + iCountPills < 3 || (iCountPills == 0 && iCountAdren < TEAM_SIZE) ) { g_iDifficultyRating++; }
    */
    
    // done
    PrintDebug(1, "[rand] Randomized and stored %i survivor setups (%i primaries, %i secondaries, %i strips).", TEAM_SIZE, iCountPrimary, iCountSecondary, iCountStrip);
    
    // enable handouts on team switch/join
    g_iSurvHandled = 0;
    g_bSurvHandout = true;
}

RandomizeSurvivorHealth()
{
    new randomPick;

    new Float: fHealthChance = GetConVarFloat(g_hCvarHealthChance);
    if (!fHealthChance) { return; }
    
    for (new i=0; i < TEAM_SIZE; i++)
    {
        // pick a random option
        // save it to array
        
        if (GetRandomFloat(0.001, 1.0) <= fHealthChance) {
            randomPick = GetRandomInt(GetConVarInt(g_hCvarHealthMin), HEALTH_MAXIMUM);
            if (randomPick < 1) { randomPick = 1; }
            
            g_iArStorageSurvHealth[i] = randomPick;
        }        
    }
    
    // done
    PrintDebug(1, "[rand] Randomized and stored %i survivor health setups.", TEAM_SIZE);
}

// restore saved starting setup
RestoreSurvivorItems()
{
    // only thing we need to to is re-enabled handouts...
    g_iSurvHandled = 0;
    g_bSurvHandout = true;
}

// look who's survivor and hand out anything we still need to
CheckSurvivorSetup()
{
    new iSurvivorCount = 0;
    
    // don't do anything if there's nothing to hand out
    if (!g_bSurvHandout || g_iSurvHandled >= TEAM_SIZE) { return; }
    
    for (new i=1; i < MaxClients && iSurvivorCount < TEAM_SIZE; i++)
    {
        if (IsSurvivor(i))
        {
            ChangeSurvivorSetup(g_iSurvHandled, i);
            g_iSurvHandled++;
            
            iSurvivorCount++;
            
            // stop if there's nothing further to hand out
            if (g_iSurvHandled >= TEAM_SIZE) { g_bSurvHandout = false; break; }
        }
    }
}



// Creating entities based on the randomized-entity-list
// ------------------------------------------------------

// build entity out of stored data
CreateEntity(index, bool:inArray = true, bool:overrideBlocks = false)
{
    new type, itemJunkIndex, itemAmmoMax /*, itemSpawnPhysics */;
    new Float: itemOrigin[3], Float: itemAngles[3];
    new bool: itemCheckOrigin;
    new String: itemStorageMelee[MELEE_CLASS_LENGTH];
    new bool: forceNonSolid = false;
    
    if (inArray) {
        // get data from index / storage array
        type = g_strArStorage[index][entPickedType];
        //itemSpawnPhysics = g_strArStorage[index][entSpawnPhysics];
        itemJunkIndex = g_strArStorage[index][entJunkType];
        itemOrigin[0] = g_strArStorage[index][entOrigin_a];
        itemOrigin[1] = g_strArStorage[index][entOrigin_b];
        itemOrigin[2] = g_strArStorage[index][entOrigin_c];
        itemAngles[0] = g_strArStorage[index][entAngles_a];
        itemAngles[1] = g_strArStorage[index][entAngles_b];
        itemAngles[2] = g_strArStorage[index][entAngles_c];
        itemAmmoMax = g_strArStorage[index][entAmmoMax];
        itemCheckOrigin = g_strArStorage[index][entCheckOrigin];
        itemStorageMelee = g_sArStorageMelee[index];
    } else {
        // get data from temporary struct
        type = g_strTempItemSingle[entPickedType];      
        //itemSpawnPhysics = g_strTempItemSingle[entSpawnPhysics];
        itemJunkIndex = g_strTempItemSingle[entJunkType];
        itemOrigin[0] = g_strTempItemSingle[entOrigin_a];
        itemOrigin[1] = g_strTempItemSingle[entOrigin_b];
        itemOrigin[2] = g_strTempItemSingle[entOrigin_c];
        itemAngles[0] = g_strTempItemSingle[entAngles_a];
        itemAngles[1] = g_strTempItemSingle[entAngles_b];
        itemAngles[2] = g_strTempItemSingle[entAngles_c];
        itemAmmoMax = g_strTempItemSingle[entAmmoMax];
        itemCheckOrigin = g_strTempItemSingle[entCheckOrigin];
        itemStorageMelee = g_sTempItemSingleMelee;
    }
    
    new bool: handled = false;
    new bool: specialCase = false;
    new bool: dontBlind = false;
    new Float: fPlaceHigher = 0.0;
    new Float: fZOffset = 0.0;
    new ent;
    
    // if we're not allowing weapon spawns... set to noitem
    if (g_bNoPriWeapons && !overrideBlocks)
    {
        switch (type)
        {
            case PCK_SMG_MP5: { type = PCK_NOITEM; }
            case PCK_SMG: { type = PCK_NOITEM; }
            case PCK_SMG_SILENCED: { type = PCK_NOITEM; }
            case PCK_PUMPSHOTGUN: { type = PCK_NOITEM; }
            case PCK_SHOTGUN_CHROME: { type = PCK_NOITEM; }
            case PCK_HUNTING_RIFLE: { type = PCK_NOITEM; }
            case PCK_SNIPER_AWP: { type = PCK_NOITEM; }
            case PCK_SNIPER_SCOUT: { type = PCK_NOITEM; }
            case PCK_SNIPER_MILITARY: { type = PCK_NOITEM; }
            case PCK_RIFLE: { type = PCK_NOITEM; }
            case PCK_RIFLE_SG552: { type = PCK_NOITEM; }
            case PCK_RIFLE_AK47: { type = PCK_NOITEM; }
            case PCK_RIFLE_DESERT: { type = PCK_NOITEM; }
            case PCK_AUTOSHOTGUN: { type = PCK_NOITEM; }
            case PCK_SHOTGUN_SPAS: { type = PCK_NOITEM; }
            case PCK_GRENADE_LAUNCHER: { type = PCK_NOITEM; }
            case PCK_RIFLE_M60: { type = PCK_NOITEM; }
        }
    }
    if (g_bNoSecWeapons && !overrideBlocks)
    {
        switch (type)
        {
            case PCK_PISTOL: { type = PCK_NOITEM; }
            case PCK_PISTOL_MAGNUM: { type = PCK_NOITEM; }
            case PCK_MELEE: { type = PCK_NOITEM; }
            case PCK_CHAINSAW: { type = PCK_NOITEM; }
        }
    }
    if (g_bNoAmmo && !overrideBlocks)
    {
        switch (type)
        {
            case PCK_AMMO: { type = PCK_NOITEM; }
            case PCK_UPG_EXPLOSIVE: { type = PCK_NOITEM; }
            case PCK_UPG_INCENDIARY: { type = PCK_NOITEM; }
        }
    }
    
    if (g_bNoHealthItems && !overrideBlocks)
    {
        switch (type)
        {
            case PCK_FIRST_AID_KIT: { type = PCK_NOITEM; }
            case PCK_DEFIBRILLATOR: { type = PCK_NOITEM; }
            case PCK_PAIN_PILLS: { type = PCK_NOITEM; }
            case PCK_ADRENALINE: { type = PCK_NOITEM; }
        }
        
        if (_:g_iSpecialEvent == EVT_MEDIC) {
            // no packs either, to simplify slot 4 tricks
            switch (type)
            {
                case PCK_UPG_EXPLOSIVE: { type = PCK_NOITEM; }
                case PCK_UPG_INCENDIARY: { type = PCK_NOITEM; }
            }
        }
    }
    
    
    // anything but weapons
    //      set handled to true/false, so we know we've already built the entity
    handled = true;
    switch (type)
    {
        case PCK_NOITEM: {
            if (index != -1) {
                g_strArStorage[index][entNumber] = 0;
            }
            return -1;
        }
        
        case PCK_SILLY_COLA: {
            ent = CreateEntityByName("prop_physics");
            DispatchKeyValue(ent, "model", "models/w_models/weapons/w_cola.mdl");
            DispatchKeyValue(ent, "Spawnflags", "256");     // 257? (asleep, why?)  or 262?
        }
        
        case PCK_SILLY_GNOME: {
            ent = CreateEntityByName("prop_physics");
            DispatchKeyValue(ent, "model", "models/props_junk/gnome.mdl");
            DispatchKeyValue(ent, "Spawnflags", "256");     // 264 
            fPlaceHigher = 15.0;
        }
        
        case PCK_SILLY_GIFT: {
            ent = CreateEntityByName("prop_dynamic");
            DispatchKeyValue(ent, "targetname", "random_gift");
            DispatchKeyValue(ent, "solid", "6");
            DispatchKeyValue(ent, "spawnflags", "1");
            DispatchKeyValue(ent, "glowcolor", "255 128 0");
            DispatchKeyValue(ent, "glowstate", "3");
            DispatchKeyValue(ent, "glowrange", "96");
            DispatchKeyValue(ent, "model", "models/items/l4d_gift.mdl");
            
            // more after dispatch...
            specialCase = true;
            dontBlind = true;                                           // don't store for blindinfected (its effect is random anyway)`
        }
        
        case PCK_EXPLOSIVE_BARREL: {
            ent = CreateEntityByName("prop_fuel_barrel");
            DispatchKeyValue(ent, "model", "models/props_industrial/barrel_fuel.mdl");
            DispatchKeyValue(ent, "BasePiece", "models/props_industrial/barrel_fuel_partb.mdl");
            DispatchKeyValue(ent, "FlyingPiece01", "models/props_industrial/barrel_fuel_parta.mdl");
            DispatchKeyValue(ent, "DetonateParticles", "weapon_pipebomb");
            DispatchKeyValue(ent, "FlyingParticles", "barrel_fly");
            DispatchKeyValue(ent, "DetonateSound", "BaseGrenade.Explode");            
            //itemSpawnPhysics = true;                                    // force it true for barrels
            dontBlind = true;                                           // don't store for blindinfected
        }
        
        case PCK_PROPANETANK: {
            ent = CreateEntityByName("prop_physics");
            DispatchKeyValue(ent, "model", "models/props_junk/propanecanister001a.mdl");
            DispatchKeyValue(ent, "Spawnflags", "256");
            //itemSpawnPhysics = true;                                    // force it true
            fPlaceHigher = 10.0;
        }
        
        case PCK_OXYGENTANK: {
            ent = CreateEntityByName("prop_physics");
            DispatchKeyValue(ent, "model", "models/props_equipment/oxygentank01.mdl");
            DispatchKeyValue(ent, "Spawnflags", "256");
            //itemSpawnPhysics = true;                                    // force it true
            fPlaceHigher = 10.0;
        }
        
        case PCK_FIREWORKCRATE: {
            ent = CreateEntityByName("prop_physics");
            DispatchKeyValue(ent, "model", "models/props_junk/explosive_box001.mdl");
            DispatchKeyValue(ent, "Spawnflags", "257");                 // it's like this in c2m5
            //itemSpawnPhysics = true;                                    // force
            fPlaceHigher = 10.0;
        }

        case PCK_UPG_LASER: {
            ent = CreateEntityByName("upgrade_spawn");
            DispatchKeyValue(ent, "laser_sight", "1");
            DispatchKeyValue(ent, "count", "1");
            DispatchKeyValue(ent, "classname", "upgrade_spawn");
        }
        
        case PCK_MELEE: {
            ent = CreateEntityByName("weapon_melee");
            DispatchKeyValue(ent, "melee_script_name", itemStorageMelee);
            fPlaceHigher = 5.0;
        }
        
        case PCK_JUNK: {
            ent = CreateEntityByName("prop_physics_override");
            DispatchKeyValue(ent, "model", g_csJunkModels[itemJunkIndex]);
            if (itemJunkIndex >= JUNK_FIRSTNONSOLID) { forceNonSolid = true; }
            fPlaceHigher = 10.0;
            dontBlind = true;                                           // don't store for blindinfected
            
            // add fire extinguisher effects
            /*
                meh, leave it for now. not worth the hassle
            if (itemJunkIndex == JUNK_FIREEXT)
            {
                new particle = CreateEntityByName("info_particle_system");
                new String: tmpName[64], String:tmpCmd[256];
                Format(tmpName, sizeof(tmpName), "rand_%d_fireext_prt", index);
                
                Format(tmpCmd, sizeof(tmpCmd), "rand_%d_fireext_prt,Start,,0,1", index);
                DispatchKeyValue(ent, "OnHealthChanged", tmpCmd);
                
                //Format(tmpCmd, sizeof(tmpCmd), "rand_%d_fireext_prt,Start,,0,1", index);
                //"OnHealthChanged" "InstanceAuto38-steamsound8PlaySound01"
                //"OnHealthChanged" "InstanceAuto38-steamsound8FadeOut361"
                
                DispatchKeyValue(particle, "targetname", tmpName);
                DispatchKeyValue(particle, "effect_name", FIRE_EXT_SPRAY);
                
                DispatchSpawn(particle);
                //ActivateEntity(particle);
            
                Format(tmpName, sizeof(tmpName), "rand_%d_fireext_base", index);
                DispatchKeyValue(ent, "targetname", tmpName);
                SetVariantString(tmpName);
                AcceptEntityInput(particle, "SetParent", particle, particle, 0);
                
                TeleportEntity(particle, itemOrigin, itemAngles, NULL_VECTOR);
            }
            */
        }
        
        default: {
            handled = false;
        }
    }
    
    
    if (!handled) {
        // weapons (last, so we don't need a huge if)
    
        new String:classname[STR_MAX_WPCLASSNAME] = "";
        
        switch (type)
        {
            case PCK_PISTOL: {          classname = "weapon_pistol";            fPlaceHigher = 0.1; }
            case PCK_PISTOL_MAGNUM: {   classname = "weapon_pistol_magnum";     fPlaceHigher = 0.1; }
            case PCK_SMG_MP5: {         classname = "weapon_smg_mp5";           fPlaceHigher = 0.1; }
            case PCK_SMG: {             classname = "weapon_smg";               fPlaceHigher = 0.1; }
            case PCK_SMG_SILENCED: {    classname = "weapon_smg_silenced";      fPlaceHigher = 0.1; }
            case PCK_PUMPSHOTGUN: {     classname = "weapon_pumpshotgun";       fPlaceHigher = 0.1; }
            case PCK_SHOTGUN_CHROME: {  classname = "weapon_shotgun_chrome";    fPlaceHigher = 0.1; }
            case PCK_HUNTING_RIFLE: {   classname = "weapon_hunting_rifle";     fPlaceHigher = 0.1; }
            case PCK_SNIPER_AWP: {      classname = "weapon_sniper_awp";        fPlaceHigher = 0.1; }
            case PCK_SNIPER_SCOUT: {    classname = "weapon_sniper_scout";      fPlaceHigher = 0.1; }
            case PCK_SNIPER_MILITARY: { classname = "weapon_sniper_military";   fPlaceHigher = 0.1; }
            case PCK_RIFLE: {           classname = "weapon_rifle";             fPlaceHigher = 0.1; }
            case PCK_RIFLE_SG552: {     classname = "weapon_rifle_sg552";       fPlaceHigher = 0.1; }
            case PCK_RIFLE_AK47: {      classname = "weapon_rifle_ak47";        fPlaceHigher = 0.1; }
            case PCK_RIFLE_DESERT: {    classname = "weapon_rifle_desert";      fPlaceHigher = 0.1; }
            case PCK_AUTOSHOTGUN: {     classname = "weapon_autoshotgun";       fPlaceHigher = 0.1; }
            case PCK_SHOTGUN_SPAS: {    classname = "weapon_shotgun_spas";      fPlaceHigher = 0.1; }
            case PCK_CHAINSAW: {        classname = "weapon_chainsaw";          fPlaceHigher = 0.1; }
            case PCK_GRENADE_LAUNCHER: {classname = "weapon_grenade_launcher";  fPlaceHigher = 0.1; }
            case PCK_RIFLE_M60: {       classname = "weapon_rifle_m60";         fPlaceHigher = 0.1; }
            
            case PCK_FIRST_AID_KIT: {   classname = "weapon_first_aid_kit"; }
            case PCK_DEFIBRILLATOR: {   classname = "weapon_defibrillator"; }
            case PCK_PAIN_PILLS: {      classname = "weapon_pain_pills"; }
            case PCK_ADRENALINE: {      classname = "weapon_adrenaline"; }
            case PCK_MOLOTOV: {         classname = "weapon_molotov"; }
            case PCK_PIPEBOMB: {        classname = "weapon_pipe_bomb"; }
            case PCK_VOMITJAR: {        classname = "weapon_vomitjar"; }
            
            case PCK_GASCAN: {          classname = "weapon_gascan";                    DispatchKeyValue(ent, "Spawnflags", "256"); }
            
            case PCK_AMMO: {            classname = "weapon_ammo_spawn";                fZOffset = 0.0; }
            case PCK_UPG_EXPLOSIVE: {   classname = "weapon_upgradepack_explosive"; }
            case PCK_UPG_INCENDIARY: {  classname = "weapon_upgradepack_incendiary"; }
        }
        
        ent = CreateEntityByName(classname);
    }
    
    if (!IsValidEntity(ent) || ent == 0)
    {
        g_strArStorage[index][entNumber] = 0;
        PrintDebug(0, "[rand] Random pick resulted in invalid entity! (index: %d, ent: %d, type: %d).", index, ent, type);
        return -1;
    }
    
    // location / angles
    new Float: origin[3];
    new Float: angles[3];
    origin = itemOrigin;
    angles = itemAngles;    
    
    // set it a bit higher, so it won't fall out of the map...
    if (fPlaceHigher) {
        origin[2] += fPlaceHigher;
    }
    
    //  are we setting it neatly, or teleporting to 'shake things loose'?
    //      if physics enabled on everything, it must happen AFTER dispatch...
    if ( /* !GetConVarBool(g_hCvarForcePhysics) && */ !specialCase) {
        DispatchKeyValueVector(ent, "origin", origin);
        DispatchKeyValueVector(ent, "angles", angles);
    }
    
    /*
    // spawn flags (physics only for now)
    if (itemSpawnPhysics) {
        //DispatchKeyValue(ent, "spawnflags", "1");         // does this even do anything?
    }
    */
    
    // create the actual replacement entity
    DispatchSpawn(ent);

    // gift box (quite special case, apparently)
    if (specialCase) {
        TeleportEntity(ent, origin, NULL_VECTOR, NULL_VECTOR);
        
        SetEntProp(ent, Prop_Data, "m_takedamage", 0, 1);
        SetEntProp(ent, Prop_Data, "m_CollisionGroup", 0);
        AcceptEntityInput(ent, "DisableCollision");
        AcceptEntityInput(ent, "EnableCollision");
        AcceptEntityInput(ent, "TurnOn");
        AcceptEntityInput(ent, "EnableMotion");
        AcceptEntityInput(ent, "Wake");
        SetEntityMoveType(ent, MOVETYPE_VPHYSICS);
    }
    
    // physics enabled?
    if (!inArray) {
        TeleportEntity(ent, origin, NULL_VECTOR, g_fTempItemSingleVelocity);
    } /* else if (GetConVarBool(g_hCvarForcePhysics)) {
        TeleportEntity(ent, origin, NULL_VECTOR, NULL_VECTOR);
    } */
    
    // if a weapon, do this to prevent it having only 1 clip:
    if (itemAmmoMax)
    {
        if (type == _:PCK_RIFLE_M60) {
            SetEntProp(ent, Prop_Send, "m_iClip1", itemAmmoMax, 4);
        } else {
            SetEntProp(ent, Prop_Send, "m_iExtraPrimaryAmmo", itemAmmoMax, 4);
        }
    }
    
    // check position, see if it's stuck maybe?
    //  only doing this for items that are too ugly plopped in the air
    if (itemCheckOrigin)
    {
        new Float: fDist = FindDistanceFromFloor(ent);
        if (FloatAbs(fDist) > fZOffset)
        {
            origin[2] -= fDist;
            origin[2] += fZOffset;
            if (inArray) { g_strArStorage[index][entOrigin_c] = origin[2]; }
            TeleportEntity(ent, origin, NULL_VECTOR, NULL_VECTOR);
            
            /*  TEST
                //PrintDebug(2, "[rand] Checked origin for item: %i (ent %i) - distance %.1f - origin:  setpos %.1f %.1f %.1f ", index, ent, fDist, origin[0], origin[1], origin[2]);
                if (FloatAbs(fDist) > 0.0) { SetEntityRenderColor(ent, 80,40,40, 100); }
            }*/
        }
        
    }
    
    // force it non-solid?
    if (forceNonSolid) {
        //SetEntData(ent, g_iOffsetCollisionGroup, COLLISION_GROUP_DEBRIS, 4, true);
        //SetEntProp(ent, Prop_Data, "m_usSolidFlags", 152);
        SetEntProp(ent, Prop_Data, "m_CollisionGroup", 1);
        SetEntProp(ent, Prop_Data, "m_MoveCollide", 0);
        //SetEntProp(ent, Prop_Data, "m_nSolidType", 6);
    }
    
    // store entity number and reset pickup status
    if (inArray && index != -1) {
        g_strArStorage[index][entNumber] = ent;
        g_strArStorage[index][entPickedUp] = false;
    }
    
    // ammo pile to coffee
    if (type == _:PCK_AMMO) {
        if (_:g_iSpecialEvent != EVT_AMMO && GetRandomInt(0, 2) == 0)
        {
            SetEntityModel(ent, MODEL_L4D1AMMO);
        }
    }
    
    // store created entity so we can blind infected to it (and possibly do other stuff)
    //  don't store: junk, because it's solid and might interfere with SI spawning...            
    if (!dontBlind && inArray) {
        g_iArCreatedEntities[g_iCreatedEntities] = ent;
        g_iCreatedEntities++;
    }
    
    // gnome/cola scoring support
    if (type == _:PCK_SILLY_GNOME || type == _:PCK_SILLY_COLA)
    {
        g_iGnomes++;
        g_strArGnomes[g_iGnomes-1][gnomeEntity] = ent;
        if (type == _:PCK_SILLY_COLA) { g_strArGnomes[g_iGnomes-1][gnomebIsCola] = true; }
        
        // if in start saferoom, pre-set its value
        if (inArray && index != -1 && g_strArStorage[index][entInStartSaferoom]) {
            g_strArGnomes[g_iGnomes-1][gnomebFirstPickup] = true;
            g_strArGnomes[g_iGnomes-1][gnomefFirstPickup] = 0.0;
        } else {
            g_strArGnomes[g_iGnomes-1][gnomebFirstPickup] = false;
            g_strArGnomes[g_iGnomes-1][gnomefFirstPickup] = 9999.0; // safeguard?
        }
    }
    
    /*
    // debugging?
    PrintDebug(3, "[rand] Created entity %i (index %i, type: %i).", ent, index, type);
    */
    /*
    if (!inArray) {
        PrintDebug(3, "[rand] Spawned entity %i (type: %i).", ent, type);
    }
    */
    
    return ent;
}

// for the hittables on a map
CreateHittable(index)
{
    new type;
    new ent;
    new Float: itemOrigin[3], Float: itemAngles[3];
    new String: targetName[24];
    
    // if it's an alarmed car, let the support function handle it
    if (g_strArHittableStorage[index][hitIsAlarmed])
    {
        SpawnAlarmCar(index);
        return -1;  // no entity, okay for now.
    }
    
    
    type = g_strArHittableStorage[index][hitPickedType];
    
    itemOrigin[0] = g_strArHittableStorage[index][hitOrigin_a];
    itemOrigin[1] = g_strArHittableStorage[index][hitOrigin_b];
    itemOrigin[2] = g_strArHittableStorage[index][hitOrigin_c];
    itemAngles[0] = g_strArHittableStorage[index][hitAngles_a];
    itemAngles[1] = g_strArHittableStorage[index][hitAngles_b];
    itemAngles[2] = g_strArHittableStorage[index][hitAngles_c];
    
    // temp fix, no rotation other than z
    //itemAngles[0] = 0.0;
    //itemAngles[1] = 0.0;
    
    // move it up a bit to prevent clipping in floor (wrecked sedan)
    itemOrigin[2] += 20.0;
 
    if (type == -1) { return -1; }

    Format(targetName, sizeof(targetName), "RandomHittable%i", index+1);
    
    ent = CreateEntityByName("prop_physics");
    DispatchKeyValue(ent, "model", g_csHittableModels[type]);
    DispatchKeyValue(ent, "spawnflags", "256");
    DispatchKeyValue(ent, "targetname", targetName);
    DispatchKeyValueVector(ent, "origin", itemOrigin);
    DispatchKeyValueVector(ent, "angles", itemAngles);
    
    if (g_strArHittableStorage[index][hitIsColored])
    {
        decl String: tmpStr[24];
        Format(tmpStr, sizeof(tmpStr), "%i %i %i", g_strArHittableStorage[index][hitColor_r], g_strArHittableStorage[index][hitColor_g], g_strArHittableStorage[index][hitColor_b]);
        DispatchKeyValue(ent, "rendercolor", tmpStr);
    }
    
    if (!IsValidEntity(ent) || ent == 0) {
        g_strArHittableStorage[index][hitNumber] = 0;
        PrintDebug(0, "[rand] Random pick resulted in invalid hittable entity! (index: %d, ent: %d, type: %d).", index, ent, type);
        return -1;
    }
    
    // create the actual replacement entity
    DispatchSpawn(ent);
    ActivateEntity(ent);
    
    // add the glass/addon
    if (type <= HITTAB_LASTADDON)
    {
        new entAd;
        // add prop_dynamic
        entAd = CreateEntityByName("prop_dynamic");
        DispatchKeyValue(entAd, "model", g_csHittableModels[type + HITTAB_TOTAL] );
        DispatchKeyValue(entAd, "disableshadows", "1");
        DispatchKeyValueVector(entAd, "origin", itemOrigin);
        DispatchKeyValueVector(entAd, "angles", itemAngles);
        
        if (entAd != 0 && IsValidEntity(entAd)) {
            g_strArHittableStorage[index][hitNumberAddonA] = entAd;
            DispatchSpawn(entAd);
            ActivateEntity(entAd);
            
            SetVariantString(targetName);
            AcceptEntityInput(entAd, "SetParent");
        }
    }
    
    return ent;
}

// change the client's weapons/loadout
ChangeSurvivorSetup(index, client)
{
    new type = g_iArStorageSurv[index];
    new ammo = 0;
    new ammoOffset = 0;
    
    // if we're playing coop, strip survivor items first
    if (g_bCampaignMode)
    {
        for (new i = PLAYER_SLOT_PRIMARY; i <= PLAYER_SLOT_PILL; i++)
        {
            
            new weaponIndex = GetPlayerWeaponSlot(client, i);
            if (weaponIndex > -1) {
                //new String:classname[STR_MAX_WPCLASSNAME];
                //GetEdictClassname(weaponIndex, classname, sizeof(classname)); 
                RemovePlayerItem(client, weaponIndex);
            }
        }
        GiveItem(client, "weapon_pistol", 0, 0);
    }
    
    // pill-giving?
    switch (g_iArStorageSurvPills[index])
    {
        case PCK_PAIN_PILLS: { GiveItem(client, "weapon_pain_pills", 0, 0); }
        case PCK_ADRENALINE: { GiveItem(client, "weapon_adrenaline", 0, 0); }
    }
    
    // for defib event
    if (_:g_iSpecialEvent == EVT_DEFIB) {
        GiveItem(client, "weapon_defibrillator", 0, 0);
    }
    // give first player the ammo kit on ammo event
    else if (_:g_iSpecialEvent == EVT_AMMO) {
        if (index == 0) {
            GiveItem(client, "weapon_upgradepack_incendiary", 0, 0);
        }
    }
        
    // starting health (don't change on bleedout event(s))
    if (_:g_iSpecialEvent != EVT_ADREN)
    {
        if (GetConVarFloat(g_hCvarHealthChance)) {
            if (g_iArStorageSurvHealth[index] && g_iArStorageSurvHealth[index] < 100)
            {
                //SetEntPropFloat(client, Prop_Send, "m_healthBuffer", float(g_iArStorageSurvHealth[index]));
                SetEntProp(client, Prop_Send, "m_iHealth", g_iArStorageSurvHealth[index], 1);
            }
        }
    }
    
    // weapon 'gift':
    // if we're replacing the single pistol, remove it:
    if (    type == _:PCK_NOITEM
        ||  type == _:PCK_PISTOL_MAGNUM
        ||  type == _:PCK_MELEE
        ||  g_iSpecialEvent == _:EVT_BADCOMBO
    ) {
        new weaponIndex = GetPlayerWeaponSlot(client, PLAYER_SLOT_SECONDARY);
        
        if (weaponIndex > -1) {
            new String:classname[STR_MAX_WPCLASSNAME];
            GetEdictClassname(weaponIndex, classname, sizeof(classname)); 
            
            if (StrEqual(classname, "weapon_pistol")) {
                RemovePlayerItem(client, weaponIndex);
            }
        }
    }

    // for bad combo event, give set items and don't do anything else
    if (_:g_iSpecialEvent == EVT_BADCOMBO)
    {
        GiveItem(client, "weapon_chainsaw", 0, 0);
        GiveItem(client, "weapon_grenade_launcher", g_RC_iEventBadComboAmmo, GRENADE_LAUNCHER_OFFSET_IAMMO);
        return;
    }
    
    new String:weaponname[STR_MAX_ITEMGIVEN] = "";
    
    // add secondary (if required)
    new typeSec = g_iArStorageSurvSec[index];
    
    if (typeSec != _:PCK_NOITEM)
    {        
        switch (typeSec)
        {
            case PCK_DUALS: {           weaponname = "weapon_pistol"; }
            case PCK_PISTOL_MAGNUM: {   weaponname = "weapon_pistol_magnum"; }
            case PCK_MELEE: {
                // special case
                PrintDebug(2, "[rand] Handed melee weapon (%s) to %N.", g_sMeleeClass[(g_iArStorageSurvMelee[index])], client);
                GiveItemMelee(client, g_sMeleeClass[(g_iArStorageSurvMelee[index])]);
                weaponname = "";
            }
        }
        
        if (strlen(weaponname))
        {
            // debug reporting
            PrintDebug(2, "[rand] Handed %s to %N.", weaponname, client);
            GiveItem(client, weaponname, ammo, ammoOffset);
        }
    }
    
    weaponname = "";
    
    // add primary
    switch (type)
    {
        case PCK_NOITEM: {          weaponname = "weapon_gnome"; }              // giving gnome for 'nothing' instead, so player can shove
        case PCK_DUALS: {           weaponname = "weapon_pistol"; }
        case PCK_PISTOL_MAGNUM: {   weaponname = "weapon_pistol_magnum"; }
        case PCK_SMG_MP5: {         weaponname = "weapon_smg_mp5";        ammo = g_iArStorageSurvAmmo[index]; ammoOffset = SMG_OFFSET_IAMMO; }
        case PCK_SMG: {             weaponname = "weapon_smg";            ammo = g_iArStorageSurvAmmo[index]; ammoOffset = SMG_OFFSET_IAMMO; }
        case PCK_SMG_SILENCED: {    weaponname = "weapon_smg_silenced";   ammo = g_iArStorageSurvAmmo[index]; ammoOffset = SMG_OFFSET_IAMMO; }
        case PCK_PUMPSHOTGUN: {     weaponname = "weapon_pumpshotgun";    ammo = g_iArStorageSurvAmmo[index]; ammoOffset = SHOTGUN_OFFSET_IAMMO; }
        case PCK_SHOTGUN_CHROME: {  weaponname = "weapon_shotgun_chrome"; ammo = g_iArStorageSurvAmmo[index]; ammoOffset = SHOTGUN_OFFSET_IAMMO; }
        
        case PCK_MELEE: {
            // special case
            PrintDebug(2, "[rand] Handed melee weapon (%s) to %N.", g_sMeleeClass[(g_iArStorageSurvMelee[index])], client);
            
            if (_:g_iSpecialEvent == EVT_WOMEN) {
                // don't use stored, use whatever the event requires
                //  test if this works without melee unlocker..
                switch (_:g_iSpecialEventExtra)
                {
                    case EVTWOMEN_TYPE_AXE:     { GiveItemMelee(client, "fireaxe"); }
                    case EVTWOMEN_TYPE_ROCK:    { GiveItemMelee(client, "electric_guitar"); }
                    default:                    { GiveItemMelee(client, g_sMeleeClass[(g_iArStorageSurvMelee[index])]); }
                }
            }
            else {
                GiveItemMelee(client, g_sMeleeClass[(g_iArStorageSurvMelee[index])]);
            }
            weaponname = "";
        }
    }
    
    // special event, snipers only (marksmen):
    if (    _:g_iSpecialEvent == EVT_SNIPER
        &&  (type == _:PCK_SMG_MP5 || type == _:PCK_SMG || type == _:PCK_SMG_SILENCED || type == _:PCK_PUMPSHOTGUN || type == _:PCK_SHOTGUN_CHROME)
    ) {
        new Float: fAmmoVarMore = 1.0 + GetConVarFloat(g_hCvarAmmoVarianceMore);
        new Float: fAmmoVarLess = 1.0 - GetConVarFloat(g_hCvarAmmoVarianceLess);
        
        weaponname = "weapon_sniper_scout";
        ammo = RoundFloat(float(g_iActiveAmmoScout) * GetRandomFloat(fAmmoVarLess, fAmmoVarMore));
        ammoOffset = MILITARY_SNIPER_OFFSET_IAMMO;
    }
    // special event: magic gun swap == you don't get a primary
    else if (_:g_iSpecialEvent == EVT_GUNSWAP)
    {
        if (type == _:PCK_SMG_MP5 || type == _:PCK_SMG || type == _:PCK_SMG_SILENCED || type == _:PCK_PUMPSHOTGUN || type == _:PCK_SHOTGUN_CHROME) {
            weaponname = "";    // don't proceed to give weapon
        }
        
        // do first swap / swap start
        EVENT_SwapSurvivorGun(client);
    }
    // special event: no t1s
    else if (_:g_iSpecialEvent == EVT_FIREPOWER)
    {
        switch (_:type)
        {
            case PCK_SMG_MP5: {         weaponname = "weapon_rifle_ak47";   ammo = g_iActiveAmmoAk; ammoOffset = ASSAULT_RIFLE_OFFSET_IAMMO; }
            case PCK_SMG: {             weaponname = "weapon_rifle";        ammo = g_iArStorageSurvAmmo[index]; ammoOffset = ASSAULT_RIFLE_OFFSET_IAMMO; }
            case PCK_SMG_SILENCED: {    weaponname = "weapon_rifle_desert"; ammo = g_iArStorageSurvAmmo[index]; ammoOffset = ASSAULT_RIFLE_OFFSET_IAMMO; }
            case PCK_PUMPSHOTGUN: {     weaponname = "weapon_autoshotgun";  ammo = g_iArStorageSurvAmmo[index]; ammoOffset = AUTO_SHOTGUN_OFFSET_IAMMO; }
            case PCK_SHOTGUN_CHROME: {  weaponname = "weapon_shotgun_spas"; ammo = g_iArStorageSurvAmmo[index]; ammoOffset = AUTO_SHOTGUN_OFFSET_IAMMO; }
        }
    }
    
    if (strlen(weaponname))
    {
        // debug reporting
        PrintDebug(2, "[rand] Handed %s to %N (ammo: %i).", weaponname, client, ammo);
        GiveItem(client, weaponname, ammo, ammoOffset);
        
        // if we've given the gnome, make sure the gnome has a value!
        if (type == _:PCK_NOITEM)
        {
            UpdateAfterGnomeGiven(client);
        }
    }
    

}


// Gift usage
// --------------------------
/*
        note:   we don't know for sure that it's a gift if this is called!
                we do know that client is a real client
        return: 1 for normal USE continuation, 0 for Plugin_Handled there, 2 for blocking, but setting flag for usingitemcheck
                however, this doesn't work right (odd progress bar glitch when using 2, so nm)
*/
RANDOM_CheckPlayerGiftUse(client)
{
    // avoid use spam (block use function for some time after gift opening):
    if (g_fGiftUseTimeout[client] != 0.0 && FloatSub(GetEngineTime(), g_fGiftUseTimeout[client]) < GIFTUSE_TIMEOUT) {
        return 0;
    } else {
        g_fGiftUseTimeout[client] = 0.0;    // clean up
    }
    
    // check what we're aiming at
    new entity = GetClientAimTarget(client, false);
    if (entity == -1) { return 1; }
    
    // check if it's a gift
    new String:targetname[32];
    GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));
    if (!StrEqual(targetname, "random_gift")) { return 1; }
    
    // check if it's in reach
    new Float:playerPos[3];
    new Float:targetPos[3];
    GetClientAbsOrigin(client, playerPos);
    GetEntPropVector(entity, Prop_Send, "m_vecOrigin", targetPos);
    new Float:distance = GetVectorDistance(playerPos, targetPos);
    if (distance > ITEM_PICKUP_DISTANCE) { return 1; }
    
    // if we are the one using it, make sure USE goes through as normal
    if (g_iClientUsing[client] == entity) { return 2; }
    
    // check if anyone else is already using it, or we are using something else
    if (SUPPORT_GetClientUsingEntity(entity) != 0 || g_iClientUsing[client] != 0) { return 0; }
    
    // if readyup is enabled, don't allow opening until we're ready
    if (SUPPORT_IsInReady())
    {
        // show message if we didn't for a while
        if (g_fGiftReportTimeout != 0.0 && FloatSub(GetEngineTime(), g_fGiftReportTimeout) <= GIFTREPORT_TIMEOUT) { return 1; }
        
        PrintToChat(client, "\x01[\x05r\x01] You must ready up before you can open a gift...");
        g_fGiftReportTimeout = GetEngineTime();
        return 1;
    }
    
    // start use progress bar
    g_bShowedProgressHint = false;
    g_iClientUsing[client] = entity;
    SetupProgressBar(client, USING_TIME_GIFT, playerPos);
    
    new Handle:pack = CreateDataPack();
    WritePackCell(pack, client);
    WritePackCell(pack, entity);
    WritePackCell(pack, USING_TYPE_GIFT);
    
    CreateTimer(0.05, Timer_CheckPlayerUsing, pack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    
    // play unwrap sound
    EmitSoundToAll(GIFTUNWRAP_SOUND, entity);
    
    // do animation
    //  if gift is high use other animation (40.0 = about waist height)
    //HideWeapon(client);
    if (targetPos[2] - playerPos[2] > 30.0) {
        L4D2Direct_DoAnimationEvent(client, ANIM_EVENT_HEAL_OTHER);
    } else {
        L4D2Direct_DoAnimationEvent(client, ANIM_EVENT_INCAP_PICKUP);
    }
    
    
    // do vocalize effect for opening a prezzie
    //  80% chance of vocalizing
    //  50% chance of special vocalize for survivor
    decl String:model[256];
    GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
    
    if (GetRandomInt(0,4))
    {
        if (StrContains(model, "mechanic", false) != -1 && GetRandomInt(0,1) == 0)
        {
            switch (GetRandomInt(0,3))
            {
                case 0: { Vocalize_Specific(client, "WorldC2m3b13"); }
                case 1: { Vocalize_Specific(client, "WorldC2m3b14"); }
                case 2: { Vocalize_Specific(client, "WorldC2m3b15"); }   // THE line
                case 3: { Vocalize_Specific(client, "WorldC2m3b16"); }   // another good one
            }
            return false;
        }
        else if (StrContains(model, "coach", false) != -1 && GetRandomInt(0,2) == 0)
        {
            switch (GetRandomInt(0,3))
            {
                case 0: { Vocalize_Specific(client, "Defibrillator05"); }
                case 1: { Vocalize_Specific(client, "TakeGrenadeLauncher01"); }
                case 2: { Vocalize_Specific(client, "takemelee01"); }
                case 3: { Vocalize_Specific(client, "takepipebomb02"); }
            }
            return false;
        }
        else if (StrContains(model, "gambler", false) != -1 && GetRandomInt(0,1) == 0)
        {
            switch (GetRandomInt(0,7))
            {
                case 0: { Vocalize_Specific(client, "Defibrillator06"); }
                case 1: { Vocalize_Specific(client, "Defibrillator08"); }
                case 2: { Vocalize_Specific(client, "generic01"); }
                case 3: { Vocalize_Specific(client, "lookthere04"); }
                case 4: { Vocalize_Specific(client, "takebat01"); }
                case 5: { Vocalize_Specific(client, "takemelee02"); }
                case 6: { Vocalize_Specific(client, "takemelee03"); }
                case 7: { Vocalize_Specific(client, "worldc1m1b34"); }
            }
            return false;
        }
        else if (StrContains(model, "producer", false) != -1 && GetRandomInt(0,3) == 0)
        {
            switch (GetRandomInt(0,2))
            {
                case 0: { Vocalize_Specific(client, "Defibrillator07"); }
                case 1: { Vocalize_Specific(client, "Defibrillator09"); }
                case 2: { Vocalize_Specific(client, "takemelee04"); }
            }
            return false;
        }
        // note: it doesn't work at all with l4d1 survivors, so don't bother.
        
        // vocs for all (special options done above)
        switch (GetRandomInt(0,4))
        {
            case 0: { Vocalize_Random(client, "askready"); }
            case 1: { Vocalize_Random(client, "waithere"); }
            case 2: { Vocalize_Random(client, "warncareful"); }
            case 3: { Vocalize_Random(client, "backupquiet"); }
            case 4: { Vocalize_Random(client, "lookhere"); }
        }
    }
    
    
    // block normal function if we opened gift..
    return 0;
}

RANDOM_DoGiftEffect(client, entity)
{
    if (!IsSurvivor(client) || !IsValidEntity(entity)) { return; }
    
    new Float:playerPos[3];
    new Float:targetPos[3];
    GetClientAbsOrigin(client, playerPos);
    GetEntPropVector(entity, Prop_Send, "m_vecOrigin", targetPos);
    
    // gift is being used
    PrintDebug(2, "[rand] Gift unwrapped by %N (entity: %i)", client, entity);
    
    new bool: inSaferoom = (IsEntityInSaferoom(entity, false, false) || IsEntityInSaferoom(client, true, false));
    
    if ( GetRandomFloat(0.001,1.0) <= GetConVarFloat(g_hCvarGiftPositiveChance) && _:g_iSpecialEvent != EVT_BADSANTA )
    {
        // positive effect
        
        new randomIndex = GetRandomInt( (inSaferoom) ? g_iGiftWeightedChoicesStartPosSaferoom : 0, (g_bInsightSurvDone) ? g_iGiftWeightedChoicesStartPosInsight - 1 : g_iGiftWeightedChoicesStartNegative - 1 );
        new randomPick = g_iArGiftWeightedChoices[randomIndex];
        
        //PrintToChatAll("client: %i, Entity: %i: pos pick: %i", client, entity, randomPick);
        
        switch (randomPick)
        {
            case GIFT_POS_HEALTH: {   // give some solid health
                new someHealth = GetRandomInt(10,40);
                new curHealth = GetClientHealth(client);
                new Float:tmpHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
                new oldTotal = curHealth + RoundFloat(tmpHealth);
                new iMaxIncaps = GetConVarInt(FindConVar("survivor_max_incapacitated_count"));
                if (iMaxIncaps == 0) { iMaxIncaps = 1; }                
                
                if (curHealth < 100) {
                    if (curHealth + someHealth < 100) { curHealth += someHealth; } else { someHealth = 100 - curHealth; curHealth = 100; }
                    SetEntityHealth(client, curHealth);
                    PrintToChatAll("\x01[\x05r\x01] %N opened gift: \x05healed %i solid health\x01.", client, someHealth);
                    
                    // if black and white, set incaps - 1
                    if (GetEntProp(client, Prop_Send, "m_currentReviveCount") >= iMaxIncaps) {
                        SetEntProp(client, Prop_Send, "m_currentReviveCount", (iMaxIncaps - 1));
                        SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 0);
                        SetEntProp(client, Prop_Send, "m_isGoingToDie", 0);
                    }
                    
                    // get rid of temp health buffer?
                    if (oldTotal > curHealth) {
                        SetEntPropFloat(client, Prop_Send, "m_healthBuffer", float(oldTotal - curHealth));
                    } else {
                        SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
                    }
                    
                    Vocalize_Random(client, "PainRelieftFirstAid");
                }
                else {
                    PrintToChatAll("\x01[\x05r\x01] %N opened gift: useless healing.", client);
                    
                    Vocalize_Random(client, "ReactionNegative");
                }
            }
            case GIFT_POS_HEALTH_T: {   // give all temp health (in addition to whatever you had)
                new Float:fGameTime = GetGameTime();
                new curHealth = GetEntProp(client, Prop_Send, "m_iHealth");
                //new Float:tmpHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
                if (curHealth < 100) {
                    SetEntPropFloat(client, Prop_Send, "m_healthBuffer", float(100 - curHealth));
                    SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", fGameTime);
                    PrintToChatAll("\x01[\x05r\x01] %N opened gift: \x05temporary health given\x01.", client);
                    
                    Vocalize_Random(client, "PainRelieftPills");
                }
                else {
                    PrintToChatAll("\x01[\x05r\x01] %N opened gift: useless healing.", client);
                    
                    Vocalize_Random(client, "ReactionNegative");
                }
            }
            case GIFT_POS_ITEMS: {   // item spawn
                PrintToChatAll("\x01[\x05r\x01] %N opened gift: \x05items\x01.", client);
                
                g_strTempItemSingle[entOrigin_a] = targetPos[0];
                g_strTempItemSingle[entOrigin_b] = targetPos[1];
                g_strTempItemSingle[entOrigin_c] = targetPos[2];
                
                new itemCount = GetRandomInt(g_RC_iGiftMinItems, g_RC_iGiftMaxItems);
                new bool: noWeapons = false;
                
                PrintDebug(3, "[rand] Gift items to spawn: %i", itemCount);
                
                if (_:g_iSpecialEvent == EVT_GUNSWAP && inSaferoom) { noWeapons = true; }   // no weapons if we're starting with GLs/CSs and it's in saferoom
                
                if (GetRandomInt(0, 4) == 0) {
                    // same item X times
                    PickRandomItem(true, true, noWeapons); // only useful, no lasersight, no weapons set above
                    
                    for (new x = 0; x < itemCount; x++) {
                        g_fTempItemSingleVelocity[0] = GetRandomFloat(-160.0, 160.0);
                        g_fTempItemSingleVelocity[1] = GetRandomFloat(-160.0, 160.0);
                        g_fTempItemSingleVelocity[2] = GetRandomFloat(40.0, 160.0);
                        
                        CreateEntity(-1, false);    // create entity, not from array!
                    }
                }
                else {
                    // all different
                    for (new x = 0; x < itemCount; x++) {
                        g_fTempItemSingleVelocity[0] = GetRandomFloat(-160.0, 160.0);
                        g_fTempItemSingleVelocity[1] = GetRandomFloat(-160.0, 160.0);
                        g_fTempItemSingleVelocity[2] = GetRandomFloat(40.0, 160.0);
                        
                        PickRandomItem(true, true, noWeapons); // only useful, no lasersight, no weapons set above
                        
                        CreateEntity(-1, false);    // create entity, not from array!
                    }
                }
                
                // check for ellis (so we can do his fancy merry xmas lines)
                decl String:model[32];
                GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
                if (StrContains(model, "mechanic", false) != -1) {
                    // it's ellis
                    switch (GetRandomInt(0,4)) {
                        case 0: { Vocalize_Specific(client, "worldc2m3b13"); }
                        case 1: { Vocalize_Specific(client, "worldc2m3b14"); }
                        case 2: { Vocalize_Specific(client, "worldc2m3b15"); }   // THE line
                        case 3: { Vocalize_Specific(client, "worldc2m3b16"); }   // another good one
                        case 4: { Vocalize_Random(client, "positivenoise"); }
                    }
                } else {
                    switch (GetRandomInt(0,1)) {
                        case 0: { Vocalize_Random(client, "hurrah"); }
                        case 1: { Vocalize_Random(client, "positivenoise"); }
                    }
                }
            }
            case GIFT_POS_LASER: {  // give laser sight
                if (GetRandomInt(0, 2) == 0) {
                    // for all
                    PrintToChatAll("\x01[\x05r\x01] %N opened gift: \x05team laser sight\x01.", client);
                    for (new i=1; i < MaxClients; i++) {
                        if (IsClientInGame(i) && IsSurvivor(i) && IsPlayerAlive(i)) {
                            CheatCommand(i, "upgrade_add", "LASER_SIGHT");
                        }
                    }
                } else {
                    // for the opener
                    PrintToChatAll("\x01[\x05r\x01] %N opened gift: \x05laser sight\x01.", client);
                    CheatCommand(client, "upgrade_add", "LASER_SIGHT");
                }
                Vocalize_Random(client, "lasersights");
            }
            case GIFT_POS_AMMO: {   // give ammo
                if (GetRandomInt(0, 2) == 0) {
                    // for all
                    PrintToChatAll("\x01[\x05r\x01] %N opened gift: \x05team ammo refill\x01.", client);
                    for (new i=1; i < MaxClients; i++) {
                        if (IsClientInGame(i) && IsSurvivor(i) && IsPlayerAlive(i)) {
                            CheatCommand(i, "give", "ammo");
                            SUPPORT_CheckAmmo(i);
                        }
                    }
                } else {
                    // for the opener
                    PrintToChatAll("\x01[\x05r\x01] %N opened gift: \x05ammo refill\x01.", client);
                    CheatCommand(client, "give", "ammo");
                    SUPPORT_CheckAmmo(client);
                }
                Vocalize_Random(client, "spotammo");
            }
            case GIFT_POS_INSIGHT: {   // give insight
                PrintToChatAll("\x01[\x05r\x01] %N opened gift: \x05survivor insight\x01...", client);
                DoInsightReport(TEAM_SURVIVOR);
                g_bInsightSurvDone = true;
                Vocalize_Random(client, "lookhere");
            }
        }
    }
    else
    {
        // negative effect
       
        new randomIndex = GetRandomInt( (inSaferoom) ? g_iGiftWeightedChoicesStartNegSaferoom : g_iGiftWeightedChoicesStartNegative, (g_bInsightInfDone || g_bCampaignMode ) ? g_iGiftWeightedChoicesStartNegInsight - 1 : g_iGiftWeightedChoicesTotal - 1 );
        new randomPick = g_iArGiftWeightedChoices[randomIndex];
        
        //PrintToChatAll("client: %i, Entity: %i: neg pick: %i", client, entity, randomPick);
        
        switch (randomPick)
        {
            case GIFT_NEG_EXPLODE: {   // explosion (small and big)
                PrintToChatAll("\x01[\x05r\x01] %N opened gift: \x04explosive surprise\x01!", client);
                
                new Handle:pack = CreateDataPack();
                WritePackFloat(pack, (GetRandomInt(0, 3)) ? g_RC_fExplosionPowerLow : g_RC_fExplosionPowerLow );
                WritePackFloat(pack, targetPos[0]);
                WritePackFloat(pack, targetPos[1]);
                WritePackFloat(pack, targetPos[2]);
                CreateTimer(GIFT_EXPLODE_DELAY, Timer_CreateExplosion, pack, TIMER_FLAG_NO_MAPCHANGE);
            }
            case GIFT_NEG_PANIC: {   // panic event (sound siren of some sort)
                PrintToChatAll("\x01[\x05r\x01] %N opened gift: \x04panic surprise\x01!", client);
                EmitAmbientSound(PANICGIFT_SOUND, targetPos, client, SNDLEVEL_AIRCRAFT, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL);  
                // spawn a mob (or two)..
                SpawnPanicHorde(client, GetRandomInt(1,2));     // small or larger one..
                
                new Handle:pack = CreateDataPack();
                WritePackCell(pack, client);
                WritePackString(pack, "incoming");
                CreateTimer(0.5, Timer_Vocalize_Random, pack, TIMER_FLAG_NO_MAPCHANGE);
            }
            case GIFT_NEG_VOMIT: {   // boom box-opener
                PrintToChatAll("\x01[\x05r\x01] %N opened gift: \x04vomit surprise\x01!", client);
                EmitSoundToAll(BOOMGIFT_SOUND, client);
                PlayerGetVomitedOn(client);
            }
            case GIFT_NEG_ALLDROP: {   // everone drops everything
                PrintToChatAll("\x01[\x05r\x01] %N opened gift: \x04magic slippery fingers\x01!", client);
                
                // entire team:
                for (new i=1; i <= MaxClients; i++)
                {
                    if (IsSurvivor(i) && IsPlayerAlive(i) && !IsIncapacitated(i) && !IsHangingFromLedge(i))
                    {
                        new iDontMessWith = -1;
                        
                        // find a slot that we shouldn't mess with:
                        if (_:g_iSpecialEvent == EVT_GUNSWAP) {
                            iDontMessWith = 0;
                        } else {
                            for (new j = PLAYER_SLOT_PILL; j >= PLAYER_SLOT_PRIMARY; j--)
                            {
                                new item = GetPlayerWeaponSlot(i, j);
                                if (item != -1 && IsValidEntity(item)) {
                                    iDontMessWith = j;
                                    break;
                                }
                            }
                        }
                        
                        // drop stuff
                        //  for item pickup penalty event, only drop primaries
                        for (new j = PLAYER_SLOT_PRIMARY; j <= ((_:g_iSpecialEvent == EVT_PEN_ITEM) ? PLAYER_SLOT_PRIMARY : PLAYER_SLOT_PILL); j++)
                        {
                            if (j == iDontMessWith) { continue; }
                            
                            SUPPORT_DropItemSlot(i, j);
                            if (j == PLAYER_SLOT_SECONDARY) {
                                // drop twice for dualies
                                SUPPORT_DropItemSlot(i, j);
                            }
                        }
                        
                        new Handle:pack = CreateDataPack();
                        WritePackCell(pack, i);
                        WritePackString(pack, "ReactionNegative");
                        CreateTimer( GetRandomFloat(0.15, 0.35) , Timer_Vocalize_Random, pack, TIMER_FLAG_NO_MAPCHANGE);
                    }
                }
            }
            case GIFT_NEG_FIRE: {   // fire(works)-trap
                if (GetRandomInt(0, 1) == 0) {
                    PrintToChatAll("\x01[\x05r\x01] %N opened gift: \x04fire surprise\x01!", client);
                    CreateFire(targetPos, false);   // fire
                } else {
                    PrintToChatAll("\x01[\x05r\x01] %N opened gift: \x04fireworks\x01!", client);
                    CreateFire(targetPos, true);    // fireworks
                }
                
                new Handle:pack = CreateDataPack();
                WritePackCell(pack, client);
                if (GetRandomInt(0,1)) {
                    WritePackString(pack, "ReactionNegative");
                    CreateTimer(1.0, Timer_Vocalize_Random, pack, TIMER_FLAG_NO_MAPCHANGE);
                } else {
                    WritePackString(pack, "Sorry");
                    CreateTimer(1.5, Timer_Vocalize_Random, pack, TIMER_FLAG_NO_MAPCHANGE);
                }
            }
            case GIFT_NEG_INSIGHT: {   // give insight
                PrintToChatAll("\x01[\x05r\x01] %N opened gift: \x04infected insight\x01...", client);
                DoInsightReport(TEAM_INFECTED);
                g_bInsightInfDone = true;
                
                new Handle:pack = CreateDataPack();
                WritePackCell(pack, client);
                if (GetRandomInt(0,1)) {
                    WritePackString(pack, "ReactionNegative");
                } else {
                    WritePackString(pack, "no");
                }

                CreateTimer(0.5, Timer_Vocalize_Random, pack, TIMER_FLAG_NO_MAPCHANGE);
            }
        }
    }
    
    // kill the gift
    AcceptEntityInput(entity, "Kill");
    
    // block player use function for a short while to avoid spam
    g_fGiftUseTimeout[client] = GetEngineTime();
    
    // give bonus points if event
    if (_:g_iSpecialEvent == EVT_BADSANTA)
    {
        g_iBonusCount++;
        PBONUS_AddRoundBonus( g_RC_iEventBonusBadSanta );
        PrintToChatAll("\x01[\x05r\x01] %N unwrapped a lousy gift for \x04%i\x01 points.", client, g_RC_iEventBonusBadSanta);
    }
}



// SI Spawns
// --------------------------
RandomizeFirstSpawns()
{
    // determine the first four spawns
    //  avoids hassle with making the first attacks the same
    //  and makes it possible to control quad cap on first attack

    new tmpPick = 0;
    new tmpSupCount = 0;
    
    new bool: bFirstQuad = bool:(GetRandomFloat(0.001, 1.0) <= GetConVarFloat(g_hCvarFirstQuadChance));
    
    // if we got the quad event, first attack is a quad too
    if (g_iSpecialEvent == _:EVT_QUADS || GetConVarBool(g_hCvarNoSupportSI)) { bFirstQuad = true; }
    else if (g_iSpecialEvent == _:EVT_WOMEN) { bFirstQuad = false; }
    
    for (new i=0; i < TEAM_SIZE; i++)
    {

        // pick any random SI (or only capper)
        tmpPick = GetRandomInt( (bFirstQuad) ? g_iSpawnWeightedChoicesStartCappers : 0 , g_iSpawnWeightedChoicesTotal - 1 );
        tmpPick = g_iArSpawnWeightedChoices[tmpPick];
        g_iArStorageSpawns[i] = tmpPick;
        
        if (_:g_iSpecialEvent == EVT_L4D1)
        {
            // check if there already is a boomer/smoker, if so, replace it
            if (tmpPick == ZC_SMOKER) {
                for (new j=0; j < i; j++) {
                    if (g_iArStorageSpawns[j] == ZC_SMOKER) { tmpPick = ZC_HUNTER; break; }
                }
            } else if (tmpPick == ZC_BOOMER) {
                for (new j=0; j < i; j++) {
                    if (g_iArStorageSpawns[j] == ZC_BOOMER) { tmpPick = ZC_HUNTER; break; }
                }
            }
            g_iArStorageSpawns[i] = tmpPick;
        }
        else if (GetConVarInt(g_hCvarTeamSize) < 3) {
            // no double smoker in 2v2
            if (tmpPick == ZC_SMOKER) {
                for (new j=0; j < i; j++) {
                    if (g_iArStorageSpawns[j] == ZC_SMOKER) {
                        switch (GetRandomInt(0,2)) {
                            case 0: { tmpPick = ZC_HUNTER; }
                            case 1: { tmpPick = ZC_JOCKEY; }
                            case 2: { tmpPick = ZC_CHARGER; }
                        }
                        break;
                    }
                }
            } 
        }
        
        if (tmpPick == ZC_BOOMER || tmpPick == ZC_SPITTER) { tmpSupCount++; }
    }
    
    // check for quad if none supposed (only for 4v4)
    if ( !bFirstQuad && !tmpSupCount && g_iTeamSize > 3 )
    {
        // no support, replace one
        tmpPick = GetRandomInt( 0, g_iSpawnWeightedChoicesStartCappers - 1 );
        tmpPick = g_iArSpawnWeightedChoices[tmpPick];
        
        if ( tmpPick == ZC_SPITTER ) {
            if (_:g_iSpecialEvent == EVT_L4D1) { tmpPick = ZC_BOOMER; }
        }
        g_iArStorageSpawns[0] = tmpPick;
    }

    PrintDebug(1, "[rand] Picked four classes for first attack (%s, %s, %s, %s).",
            g_csSIClassName[g_iArStorageSpawns[0]],
            g_csSIClassName[g_iArStorageSpawns[1]],
            g_csSIClassName[g_iArStorageSpawns[2]],
            g_csSIClassName[g_iArStorageSpawns[3]]
        );
}

DetermineSpawnClass(any:client, any:iClass)
{
    // pick a desired class, dependent on Cvar settings
    if ( iClass < ZC_SMOKER || iClass > ZC_CHARGER || !IsClientAndInGame(client) || IsTank(client)) { return; }
    
    // player is given a ghost class, keep track (for sack-exploitation check)
    if (!IsFakeClient(client))
    {
        g_fGotGhost[client] = GetGameTime();
        g_fDeathAfterGhost[client] = 0.0;
    }
    
    new bool: checkSacking = false;     // check for players keeping strong infected
    new bool: forcedClass = false;      // skip check for accepted classes
    
    //new valveClass = iClass;
    //PrintDebug(2, "[random spawns] valve ghost pick (%N = %i)", client, valveClass);
    
    if (g_bIsFirstAttack && !IsFakeClient(client))
    {
        // build first attack
        iClass = GetClassForFirstAttack(client);
        forcedClass = true;
        PrintDebug(2, "[rand si] first attack spawn assigned: %8s => %N", g_csSIClassName[iClass], client);
    }
    else if (g_iSpectateGhostCount && !IsFakeClient(client))
    {
        // someone spectated as a ghost, use the SI they left
        g_iSpectateGhostCount--;
        iClass = g_iSpectateGhost[g_iSpectateGhostCount];
        forcedClass = true;
        PrintDebug(2, "[rand si] spectate ghost reset: %s => %N", g_csSIClassName[iClass], client);
    }
    else if (GetConVarBool(g_hCvarRandomSpawns))
    {
        // pick at random
        new randomIndex = GetRandomInt( (g_iSpecialEvent == _:EVT_QUADS || GetConVarBool(g_hCvarNoSupportSI)) ? g_iSpawnWeightedChoicesStartCappers : 0, g_iSpawnWeightedChoicesTotal - 1);
        iClass = g_iArSpawnWeightedChoices[randomIndex];
        
        // repicks for death order
        if (g_iClassTimeout[iClass] > 0)
        {
            new dMode = GetConVarInt(g_hCvarDeathOrderMode);
            //PrintDebug("[rand] classtimeout: for %i : %i (mode %i) (playing odds for re-pick)", iClass, g_iClassTimeout[iClass], dMode);
            
            if (dMode == 1) {
                if (GetRandomFloat(0.001,1.0) <= (float(g_iClassTimeout[iClass]) / 3.0) * 0.5) {
                    randomIndex = GetRandomInt( (g_iSpecialEvent == _:EVT_QUADS || GetConVarBool(g_hCvarNoSupportSI)) ? g_iSpawnWeightedChoicesStartCappers : 0, g_iSpawnWeightedChoicesTotal - 1);
                    iClass = g_iArSpawnWeightedChoices[randomIndex];
                }
            }
            else if (dMode == 2) {
                if (GetRandomFloat(0.001,1.0) <= (float(g_iClassTimeout[iClass]) / 4.0) * 1.0) {
                    randomIndex = GetRandomInt( (g_iSpecialEvent == _:EVT_QUADS || GetConVarBool(g_hCvarNoSupportSI)) ? g_iSpawnWeightedChoicesStartCappers : 0, g_iSpawnWeightedChoicesTotal - 1);
                    iClass = g_iArSpawnWeightedChoices[randomIndex];
                }
            }
        }
        
        PrintDebug(2, "[rand si] picked class: %s => %N", g_csSIClassName[iClass], client);
        checkSacking = true;
    }
    else
    {
        // nothing changed, return
        PrintDebug(2, "[rand si] valve pick. (%N = %i)", client, iClass);
        return;
    }
    
    // what choices are acceptable this point:
    new acceptClasses[7];
    new acceptCount = 0;
    
    if (g_iSpecialEvent != _:EVT_QUADS && !GetConVarBool(g_hCvarNoSupportSI))
    {
        AddSpawnClass(acceptClasses, acceptCount, ZC_BOOMER);
        
        if (g_iSpecialEvent != _:EVT_L4D1 && (!g_bIsTankInPlay || !GetConVarBool(g_hCvarNoSpitterDuringTank))) {
            AddSpawnClass(acceptClasses, acceptCount, ZC_SPITTER);
        }
    }
    if (g_iSpecialEvent != _:EVT_WOMEN)
    {
        AddSpawnClass(acceptClasses, acceptCount, ZC_SMOKER);
        AddSpawnClass(acceptClasses, acceptCount, ZC_HUNTER);
        
        if (g_iSpecialEvent != _:EVT_L4D1)
        {
            AddSpawnClass(acceptClasses, acceptCount, ZC_JOCKEY);
            AddSpawnClass(acceptClasses, acceptCount, ZC_CHARGER);
        }
    }
    
    if (!forcedClass && g_bIsTankInPlay && iClass == ZC_SPITTER && GetConVarBool(g_hCvarNoSpitterDuringTank))
    {
        // either boomer, or cappers
        //  this is just a prepick - still need to check if accepted below
        if (GetRandomInt(0,3) == 0) {
            iClass = ZC_BOOMER;
        } else {
            new randomIndex = GetRandomInt( g_iSpawnWeightedChoicesStartCappers, g_iSpawnWeightedChoicesTotal - 1);
            iClass = g_iArSpawnWeightedChoices[randomIndex];
        }
    }
    
    // sack protection
    if (!forcedClass && checkSacking && GetConVarBool(g_hCvarSackProtection))
    {
        // check if anyone is keeping a spawn
        new Float: fSackTime = GetConVarFloat(FindConVar("z_ghost_delay_min")) - 0.1;
        new classType = -1;
        new bestSaved = -1;
        new offendingClient = -1;
        
        for (new i=1; i <= MaxClients; i++) {
            if (i == client || !IsClientInGame(i) ) { continue; }
            
            if (IsInfected(i) && g_fDeathAfterGhost[i] != 0.0 && GetGameTime() - g_fDeathAfterGhost[i] > fSackTime && IsPlayerAlive(i) && IsPlayerGhost(i) && !IsTank(i))
            {
                classType = GetEntProp(i, Prop_Send, "m_zombieClass");
                
                //  for two or more saves... worry only about the best spawns (charger, smoker (hunter for events))
                if (classType == ZC_CHARGER && bestSaved != ZC_CHARGER) { bestSaved = ZC_CHARGER; offendingClient = i; }
                else if (classType == ZC_SMOKER && bestSaved != ZC_CHARGER) { bestSaved = ZC_SMOKER; offendingClient = i; }
                else if (classType == ZC_HUNTER && bestSaved != ZC_SMOKER && bestSaved != ZC_CHARGER) { bestSaved = ZC_HUNTER; offendingClient = i; }
            }
        }
        
        // bestSaved = the best spawn held on to (-1 = no sacks)
        //  if there is a saved spawn: prevent charger stacking, prevent smoker stacking and prevent quads
        if (bestSaved != -1)
        {
            // just prevent chargers, if player got a charger
            // and prevent > 2 smokers
            new chargers = CountInfectedClass(ZC_CHARGER, client);
            new smokers = CountInfectedClass(ZC_SMOKER, client);
            new hunters = CountInfectedClass(ZC_HUNTER, client);
            new support = CountInfectedClass(ZC_BOOMER, client) + CountInfectedClass(ZC_SPITTER, client);
            
            // a. force max 1 charger
            if (chargers) { RemoveSpawnClass(acceptClasses, acceptCount, ZC_CHARGER); }
            // b. force max 2 smokers
            if (smokers > 1) { RemoveSpawnClass(acceptClasses, acceptCount, ZC_SMOKER); }
            // c. force max 2 hunters
            if (hunters > 1 && _:g_iSpecialEvent != EVT_L4D1) { RemoveSpawnClass(acceptClasses, acceptCount, ZC_HUNTER); }
            // d. force non-quad (can override previous after-sackdetect-pick)
            if (support == 0 && g_iSpecialEvent != _:EVT_QUADS && !GetConVarBool(g_hCvarNoSupportSI)) {
                // still need to check if pick is acceptable. remove all cappers from choice list
                new randomIndex = GetRandomInt(0, g_iSpawnWeightedChoicesStartCappers - 1);
                iClass = g_iArSpawnWeightedChoices[randomIndex];
                
                RemoveSpawnClass(acceptClasses, acceptCount, ZC_CHARGER);
                RemoveSpawnClass(acceptClasses, acceptCount, ZC_JOCKEY);
                RemoveSpawnClass(acceptClasses, acceptCount, ZC_HUNTER);
                RemoveSpawnClass(acceptClasses, acceptCount, ZC_SMOKER);
            }
            
            // reporting?
            new reportMode = GetConVarInt(g_hCvarReportSackProt);
            
            if (GetGameTime() - g_fLastOffence[offendingClient] > SACKPROT_OFFENCE_GRACE) {
                g_fLastOffence[offendingClient] = GetGameTime();
                g_iOffences[offendingClient]++;
                
                // report to offending client
                if (reportMode == 1 || ( reportMode == 2 && g_iOffences[offendingClient] == 3) )
                {
                    PrintToChat(offendingClient, "\x01[\x05r\x01] Holding onto spawns makes your team get less chargers and no quad-caps. (try to attack together)");
                }
                
                // report to slighted party
                if (reportMode == 1)
                {
                    if (!IsAcceptedClass(acceptClasses, acceptCount, iClass))
                    {
                        PrintToChat(client, "\x01[\x05r\x01] sack block: you did not get a %s because %N kept their spawn.", g_csSIClassName[iClass], offendingClient);
                    }
                }
            }
            
            PrintDebug(1, "[rand si] sack prot.: %N (potentially) not given class %s (punishment for %N keeping class %s). [offenses: %i]", client, g_csSIClassName[iClass], offendingClient, g_csSIClassName[bestSaved], g_iOffences[offendingClient]);
        }
    }
    
    
    // for l4d1 mode, avoid more than 1 boomer or smoker:
    if (_:g_iSpecialEvent == EVT_L4D1) {
        new smokers = CountInfectedClass(ZC_SMOKER, client);
        new boomers = CountInfectedClass(ZC_BOOMER, client);
        if (smokers) { RemoveSpawnClass(acceptClasses, acceptCount, ZC_SMOKER); }
        if (boomers) { RemoveSpawnClass(acceptClasses, acceptCount, ZC_BOOMER); }
    }
    // prevent double smoker in 2v2
    else if (GetConVarInt(g_hCvarTeamSize) < 3) {
        if (CountInfectedClass(ZC_SMOKER, client)) {
            RemoveSpawnClass(acceptClasses, acceptCount, ZC_SMOKER);
        }
    }
    
    // prevent unwanted picks!
    //  if (for whatever reason) a class is not accepted, repick
    if (!forcedClass && !IsAcceptedClass(acceptClasses, acceptCount, iClass))
    {
        new oldClass = iClass;
        iClass = acceptClasses[ GetRandomInt(0, acceptCount - 1) ];
        
        // repicks for death order
        if (g_iClassTimeout[iClass] > 0)
        {
            new dMode = GetConVarInt(g_hCvarDeathOrderMode);
            
            if (dMode == 1) {
                if (GetRandomFloat(0.001,1.0) <= (float(g_iClassTimeout[iClass]) / 3.0) * 0.5) {
                    iClass = acceptClasses[ GetRandomInt(0, acceptCount - 1) ];
                }
            }
            else if (dMode == 2) {
                if (GetRandomFloat(0.001,1.0) <= (float(g_iClassTimeout[iClass]) / 4.0) * 1.0) {
                    iClass = acceptClasses[ GetRandomInt(0, acceptCount - 1) ];
                }
            }
        }
        
        PrintDebug(2, "[rand si] spawn repick for %N: %s => %s instead.", client, g_csSIClassName[oldClass], g_csSIClassName[iClass]);
    }
    
    // debug report for forced spawns
    if (forcedClass)
    {
        PrintDebug(2, "[rand si] forced class pick: %s => %N", g_csSIClassName[iClass], client);
    }
    
    // special case for skeet event: always 2 hunters in the attack at least
    if (_:g_iSpecialEvent == EVT_SKEET)
    {
        new hunters = CountInfectedClass(ZC_HUNTER, -1);
        
        if (hunters < 2) {
            iClass = ZC_HUNTER;
            PrintDebug(2, "[rand si] forcing hunter for skeet event (%N).", client);
        }
    }
    
    // handle timeouts
    for (new i=ZC_SMOKER; i <= ZC_CHARGER; i++)
    {
        if (g_iClassTimeout[i] > 0) { g_iClassTimeout[i]--; }
    }
    
    // prepare ghost for change
    if (IsPlayerGhost(client) && iClass >= ZC_SMOKER)
    {
        new WeaponIndex;
        while ((WeaponIndex = GetPlayerWeaponSlot(client, 0)) != -1) {
            RemovePlayerItem(client, WeaponIndex);
            RemoveEdict(WeaponIndex);
        }
        
        SDKCall(g_setClass, client, iClass);
        
        AcceptEntityInput(MakeCompatEntRef(GetEntProp(client, Prop_Send, "m_customAbility")), "Kill");
        SetEntProp(client, Prop_Send, "m_customAbility", GetEntData(SDKCall(g_createAbility, client), g_oAbility));
    }
    
    // player now has a ghost
    g_bHasGhost[client] = true;
    g_bSpectateDeath[client] = false;
    
    return;
}

// Item drops (from common/SI/Tank)
// --------------------------------

RANDOM_TankDropItems()
{
    if (GetRandomFloat(0.001,1.0) <= GetConVarFloat(g_hCvarTankItemDropChance))
    {
        // location stored in global
        new count = GetRandomInt(g_RC_iTankDropItemsMin, g_RC_iTankDropItemsMax);
        
        for (new i=0; i < count; i++)
        {
            new Float:vel[3];
            vel[0] = GetRandomFloat(-80.0, 80.0);
            vel[1] = GetRandomFloat(-80.0, 80.0);
            vel[2] = GetRandomFloat(40.0, 80.0);
            
            g_fTankDeathLocation[2] += 10.0;
            
            SpawnCommonItem(g_fTankDeathLocation, vel);
        }
    }
}

SpawnCommonItem(Float:loc[3], Float:vel[3])
{
    // spawn an item that pops out of a common
    // pick an item (could add fully weighted item list later)
    
    new ent;
    
    new maxPick = 10;
    if (GetConVarBool(g_hCvarGnomeAllowRandom)) { maxPick = 12; }
    
    new randomPick = GetRandomInt(0, maxPick);
    
    // simple weight distribution
    if (randomPick < 3)       { randomPick = 0; }
    else if (randomPick < 6)  { randomPick = 3; }
    else if (randomPick < 8)  { randomPick = 6; }
    
    // l4d1 event
    if ( _:g_iSpecialEvent == EVT_L4D1 ) {
        if ( randomPick == 3 ) { randomPick = 0; }
        else if (randomPick == 10 ) { randomPick = GetRandomInt(8, 9); }
    } 
    
    switch (randomPick) {
        case 0: {
            // pills
            ent = CreateEntityByName("weapon_pain_pills");
        }
        case 3: {
            // adren
            ent = CreateEntityByName("weapon_adrenaline");
        }
        case 6: {
            // pistol
            ent = CreateEntityByName("weapon_pistol");
        }
        case 8: {
            // pipe
            ent = CreateEntityByName("weapon_pipe_bomb");
        }
        case 9: {
            // molly
            ent = CreateEntityByName("weapon_molotov");
        }
        case 10: {
            // bile
            ent = CreateEntityByName("weapon_vomitjar");
        }
        case 11: {
            // gnome
            ent = CreateEntityByName("prop_physics");
            DispatchKeyValue(ent, "model", "models/props_junk/gnome.mdl");
            DispatchKeyValue(ent, "Spawnflags", "256");
        }
        case 12: {
            // cola
            ent = CreateEntityByName("prop_physics");
            DispatchKeyValue(ent, "model", "models/w_models/weapons/w_cola.mdl");
            DispatchKeyValue(ent, "Spawnflags", "256");
        }
    }
    
    if (!IsValidEntity(ent) || ent == 0)
    {
        PrintDebug(0, "[rand] Common drop resulted in invalid entity! (pick: %i)", randomPick);
        return;
    }
    
    // spawn item
    DispatchSpawn(ent);
    ActivateEntity(ent);
    TeleportEntity(ent, loc, NULL_VECTOR, vel);
}


// Random Door Locking
// ------------------------

// randomize doors
RandomizeDoors()
{
    new entityCount = GetEntityCount();
    new String: classname[64];
    new String: mapName[STR_MAX_MAPNAME];
    
    GetCurrentMap(mapName, STR_MAX_MAPNAME);
    
    g_bEarlyLock = false;
    g_iDoorsLockedTotal = 0;
    
    new total = 0;
    new totalNot = 0;                           // how many doors were not locked
    new iDoubleDoorCheck[MAX_DOORS];            // for checking whether some door has a 'partner'
    new Float: fDoubleOrigin[MAX_DOORS][3];
    new Float: fDoubleAngles[MAX_DOORS][3];
    new Float: fFirstAngles[MAX_DOORS][3];      // temp. saved angles of the locked doors    
    new iDoubleOwner[MAX_DOORS];                // temp. saved hOwnerEntity of doors, for partnercheck
    new iFirstOwner[MAX_DOORS];
    
    new Float: fLockedChance = 0.0;
    if (g_iSpecialEvent == _:EVT_DOORS) {
        fLockedChance = EVENT_LOCKEDCHANCE;
    } else if ( g_iSpecialEvent == _:EVT_L4D1) {
        // can't lock doors in l4d1 mode, no melees!
        fLockedChance = 0.0;
    } else if (g_iSpecialEvent == _:EVT_KEYMASTER) {
        // with keymaster, all doors are locked
        fLockedChance = 1.0;
    } else {
        fLockedChance = GetConVarFloat(g_hCvarDoorLockedChance);
    }
    
    if (fLockedChance == 0.0) { return; }
    
    //loop through ents
    for (new i=1; i < entityCount; i++)
    {
        if (!IsValidEntity(i)) { continue; }
        GetEdictClassname(i, classname, sizeof(classname));
        if (!StrEqual(classname, "prop_door_rotating")) { continue; }
        if (GetEntProp(i, Prop_Data, "m_spawnflags") & (1<<19)) { continue; }       //check for unbreakable flag
        
        // in locked doors event, close all doors (even if not locking them)
        if (g_iSpecialEvent == _:EVT_DOORS) { AcceptEntityInput(i, "Close"); }
        
        // save origin so we can find it later
        new Float: origin[3];
        new Float: angles[3];
        GetEntPropVector(i, Prop_Send, "m_vecOrigin", origin);             // can't trust HamId     GetEntProp(i, Prop_Data, "m_iHammerID");
        GetEntPropVector(i, Prop_Send, "m_angRotation", angles);
        
        // randomly determine whether door should be locked:
        if (GetRandomFloat(0.001, 1.0) <= fLockedChance)
        {
            g_fStorageDoors[total][0] = origin[0];  g_fStorageDoors[total][1] = origin[1];  g_fStorageDoors[total][2] = origin[2];
            fFirstAngles[total][0] = angles[0];     fFirstAngles[total][1] = angles[1];     fFirstAngles[total][2] = angles[2];
            iFirstOwner[total] = GetEntPropEnt(i, Prop_Data, "m_hOwnerEntity");
            g_iDoorsLocked[total] = i;
            total++;
            
            // TEST:
            //PrintDebug(3, "Locked: %i (Location: %.1f %.1f %.1f)", i, g_fStorageDoors[total-1][0], g_fStorageDoors[total-1][1], g_fStorageDoors[total-1][2]);
        } else {
            // add to array so we can check doubledoorness
            fDoubleOrigin[totalNot][0] = origin[0];  fDoubleOrigin[totalNot][1] = origin[1];  fDoubleOrigin[totalNot][2] = origin[2];
            fDoubleAngles[totalNot][0] = angles[0];  fDoubleAngles[totalNot][1] = angles[1];  fDoubleAngles[totalNot][2] = angles[2];
            iDoubleOwner[total] = GetEntPropEnt(i, Prop_Data, "m_hOwnerEntity");
            iDoubleDoorCheck[totalNot] = i;
            totalNot++;
        }
    }
    g_iDoorsLockedTotal = total;
    
    // add double doors
    /*
        if  z-placement = the same
            if  x or y placement is near enough, then
                check if other placement is close enough
                AND in the right angle direction!
    */
    if (total && totalNot)
    {
        for (new i=0; i < g_iDoorsLockedTotal; i++)
        {
            new tmpHit = -1;    // to track whether we found a paired door
            
            for (new j=0; j < totalNot; j++)
            {
                // detect double doors in L4D1 maps (targetname paired)
                if (    iFirstOwner[i] == iDoubleDoorCheck[j]
                    ||  iDoubleOwner[j] == g_iDoorsLocked[i]
                ) {                                                                         // master slave pair
                    tmpHit = j;
                    break;
                }
                // detect double doors in L4D2 maps
                else if (FloatAbs(fDoubleOrigin[j][2] - g_fStorageDoors[i][2]) < 2)         // z-aligned
                {
                    if (FloatAbs(fDoubleOrigin[j][0] - g_fStorageDoors[i][0]) < 5)          // x-aligned doors
                    {
                        if (FloatAbs(fDoubleOrigin[j][1] - g_fStorageDoors[i][1]) < 113 &&
                            FloatAbs(fDoubleOrigin[j][1] - g_fStorageDoors[i][1]) > 107 &&
                            fDoubleAngles[j][1] != fFirstAngles[j][1])                      // close enough on the y, but not too close, also not pointing the in the same direction
                        {
                            /*
                                First I'd tested whether the angles were right on the doors
                                but it's just too much hassle with opened/partially opened doors
                                    and all sorts of false positives. I scrapped it.
                            */
                            // they're a pair
                            tmpHit = j;
                            break;
                        }
                    }
                    else if (FloatAbs(fDoubleOrigin[j][1] - g_fStorageDoors[i][1]) < 5)     // y-aligned doors
                    {
                        if (FloatAbs(fDoubleOrigin[j][0] - g_fStorageDoors[i][0]) < 113 &&
                            FloatAbs(fDoubleOrigin[j][0] - g_fStorageDoors[i][0]) > 107 &&
                            fDoubleAngles[j][1] != fFirstAngles[j][1])                      // close enough on the x, but not too close, also not pointing the in the same direction)
                        {
                            // they're a pair
                            tmpHit = j;
                            break;
                        }
                    }
                }
            }
            
            if (tmpHit != -1) {
                g_fStorageDoors[total][0] = fDoubleOrigin[tmpHit][0];
                g_fStorageDoors[total][1] = fDoubleOrigin[tmpHit][1];
                g_fStorageDoors[total][2] = fDoubleOrigin[tmpHit][2];
                g_iDoorsLocked[total] = iDoubleDoorCheck[tmpHit];
                total++;
                // TEST
                //PrintDebug(3, "Locked for double doors: %i (Location: %.1f %.1f %.1f)", iDoubleDoorCheck[tmpHit], g_fStorageDoors[total-1][0], g_fStorageDoors[total-1][1], g_fStorageDoors[total-1][2]);
            }
        }
    }
    
    PrintDebug(1, "[rand] Locked %i doors randomly (of which %i for double door pairing).", total, total - g_iDoorsLockedTotal);
    g_iDoorsLockedTotal = total;
    
    // check for early locks
    if (total)
    {
        if (StrEqual(mapName, "c1m1_hotel")) {
            //
            for (new i=0; i < g_iDoorsLockedTotal; i++) {
                if (    RoundFloat(g_fStorageDoors[i][0]) == 388
                    &&  RoundFloat(g_fStorageDoors[i][1]) == 5604
                    &&  RoundFloat(g_fStorageDoors[i][2]) == 2656
                ) { g_bEarlyLock = true; break; }                   // HiD: 4604160
                if (    RoundFloat(g_fStorageDoors[i][0]) == 1875
                    &&  RoundFloat(g_fStorageDoors[i][1]) == 6364
                    &&  RoundFloat(g_fStorageDoors[i][2]) == 2656
                ) { g_bEarlyLock = true; break; }                   // HiD: 1891660
                if (    RoundFloat(g_fStorageDoors[i][0]) == 1700
                    &&  RoundFloat(g_fStorageDoors[i][1]) == 7680
                    &&  RoundFloat(g_fStorageDoors[i][2]) == 2656
                ) { g_bEarlyLock = true; break; }                   // HiD: 526253
                if (    RoundFloat(g_fStorageDoors[i][0]) == 1700
                    &&  RoundFloat(g_fStorageDoors[i][1]) == 7680
                    &&  RoundFloat(g_fStorageDoors[i][2]) == 2464
                ) { g_bEarlyLock = true; break; }                   // HiD: 570190
            }
        }
        else if (StrEqual(mapName, "c6m1_riverbank")) {
            for (new i=0; i < g_iDoorsLockedTotal; i++) {
                if (    RoundFloat(g_fStorageDoors[i][0]) == 3692
                    &&  RoundFloat(g_fStorageDoors[i][1]) == 2216
                    &&  RoundFloat(g_fStorageDoors[i][2]) == 107
                ) { g_bEarlyLock = true; break; }                   // HiD: 569246
            }
        }
        else if (StrEqual(mapName, "c7m3_port")) {
            for (new i=0; i < g_iDoorsLockedTotal; i++) {
                if (    RoundFloat(g_fStorageDoors[i][0]) == 656
                    &&  RoundFloat(g_fStorageDoors[i][1]) == 2076
                    &&  RoundFloat(g_fStorageDoors[i][2]) == 160
                ) { g_bEarlyLock = true; break; }                   // HiD: 1612186
            }
        }
        else if (StrEqual(mapName, "c8m1_apartment")) {
            for (new i=0; i < g_iDoorsLockedTotal; i++) {
                if (    RoundFloat(g_fStorageDoors[i][0]) == 1785
                    &&  RoundFloat(g_fStorageDoors[i][1]) == 1116
                    &&  RoundFloat(g_fStorageDoors[i][2]) == 484
                ) { g_bEarlyLock = true; break; }                   // HiD: 17131
                if (    RoundFloat(g_fStorageDoors[i][0]) == 1984
                    &&  RoundFloat(g_fStorageDoors[i][1]) == 792
                    &&  RoundFloat(g_fStorageDoors[i][2]) == 348
                ) { g_bEarlyLock = true; break; }                   // HiD: 19691
                if (    RoundFloat(g_fStorageDoors[i][0]) == 1698
                    &&  RoundFloat(g_fStorageDoors[i][1]) == 1013
                    &&  RoundFloat(g_fStorageDoors[i][2]) == 348
                ) { g_bEarlyLock = true; break; }                   // HiD: 19171
                if (    RoundFloat(g_fStorageDoors[i][0]) == 2067
                    &&  RoundFloat(g_fStorageDoors[i][1]) == 988
                    &&  RoundFloat(g_fStorageDoors[i][2]) == 212
                ) { g_bEarlyLock = true; break; }                   // HiD: 19176
                if (    RoundFloat(g_fStorageDoors[i][0]) == 1705
                    &&  RoundFloat(g_fStorageDoors[i][1]) == 1196
                    &&  RoundFloat(g_fStorageDoors[i][2]) == 212
                ) { g_bEarlyLock = true; break; }                   // HiD: 19856
                if (    RoundFloat(g_fStorageDoors[i][0]) == 1604
                    &&  RoundFloat(g_fStorageDoors[i][1]) == 1196
                    &&  RoundFloat(g_fStorageDoors[i][2]) == 76
                ) { g_bEarlyLock = true; break; }                   // HiD: 20046
                if (    RoundFloat(g_fStorageDoors[i][0]) == 1785
                    &&  RoundFloat(g_fStorageDoors[i][1]) == 801
                    &&  RoundFloat(g_fStorageDoors[i][2]) == 76
                ) { g_bEarlyLock = true; break; }                   // HiD: 19181
            }
        }
        else if (StrEqual(mapName, "c8m3_sewers")) {
            for (new i=0; i < g_iDoorsLockedTotal; i++) {
                if (    RoundFloat(g_fStorageDoors[i][0]) == 11360
                    &&  RoundFloat(g_fStorageDoors[i][1]) == 5442
                    &&  RoundFloat(g_fStorageDoors[i][2]) == 76
                ) { g_bEarlyLock = true; break; }                   // HiD: 3219153
            }
        }
        else if (StrEqual(mapName, "c8m4_interior")) {
            for (new i=0; i < g_iDoorsLockedTotal; i++) {
                if (    RoundFloat(g_fStorageDoors[i][0]) == 12243
                    &&  RoundFloat(g_fStorageDoors[i][1]) == 13052
                    &&  RoundFloat(g_fStorageDoors[i][2]) == 68
                ) { g_bEarlyLock = true; break; }                   // HiD: 2868149     double doors @ start
                if (    RoundFloat(g_fStorageDoors[i][0]) == 12271
                    &&  RoundFloat(g_fStorageDoors[i][1]) == 13322
                    &&  RoundFloat(g_fStorageDoors[i][2]) == 68
                ) { g_bEarlyLock = true; break; }                   // HiD: 2868398
                if (    RoundFloat(g_fStorageDoors[i][0]) == 12273
                    &&  RoundFloat(g_fStorageDoors[i][1]) == 13130
                    &&  RoundFloat(g_fStorageDoors[i][2]) == 204
                ) { g_bEarlyLock = true; break; }                   // HiD: 2868899
                if (    RoundFloat(g_fStorageDoors[i][0]) == 12252
                    &&  RoundFloat(g_fStorageDoors[i][1]) == 12291
                    &&  RoundFloat(g_fStorageDoors[i][2]) == 340
                ) { g_bEarlyLock = true; break; }                   // HiD: 2869173     double doors cafet. first
                if (    RoundFloat(g_fStorageDoors[i][0]) == 12156
                    &&  RoundFloat(g_fStorageDoors[i][1]) == 12606
                    &&  RoundFloat(g_fStorageDoors[i][2]) == 340
                ) { g_bEarlyLock = true; break; }                   // HiD: 2871136     double doors cafet. second
                if (    RoundFloat(g_fStorageDoors[i][0]) == 12274
                    &&  RoundFloat(g_fStorageDoors[i][1]) == 13074
                    &&  RoundFloat(g_fStorageDoors[i][2]) == 340
                ) { g_bEarlyLock = true; break; }                   // HiD: 2871468
                if (    RoundFloat(g_fStorageDoors[i][0]) == 12274
                    &&  RoundFloat(g_fStorageDoors[i][1]) == 13074
                    &&  RoundFloat(g_fStorageDoors[i][2]) == 476
                ) { g_bEarlyLock = true; break; }                   // HiD: 2871605     before reception desk, from thereon it's just bad luck :P
            }
        }
        else if (StrEqual(mapName, "c10m5_houseboat")) {
            for (new i=0; i < g_iDoorsLockedTotal; i++) {
                if (    RoundFloat(g_fStorageDoors[i][0]) == 1952
                    &&  RoundFloat(g_fStorageDoors[i][1]) == 3782
                    &&  RoundFloat(g_fStorageDoors[i][2]) == -12
                ) { g_bEarlyLock = true; break; }                   // HiD: 1310913
            }
        }
        else if (StrEqual(mapName, "c11m4_terminal")) {
            for (new i=0; i < g_iDoorsLockedTotal; i++) {
                if (    RoundFloat(g_fStorageDoors[i][0]) == 721
                    &&  RoundFloat(g_fStorageDoors[i][1]) == 4112
                    &&  RoundFloat(g_fStorageDoors[i][2]) == 348
                ) { g_bEarlyLock = true; break; }                   // HiD: 3943602     first double doors
                if (    RoundFloat(g_fStorageDoors[i][0]) == 80
                    &&  RoundFloat(g_fStorageDoors[i][1]) == 5482
                    &&  RoundFloat(g_fStorageDoors[i][2]) == 348
                ) { g_bEarlyLock = true; break; }                   // HiD: 3943773     end of hallway double doors
            }
        }
        else if (StrEqual(mapName, "c12m2_traintunnel")) {
            for (new i=0; i < g_iDoorsLockedTotal; i++) {
                if (    RoundFloat(g_fStorageDoors[i][0]) == -6236
                    &&  RoundFloat(g_fStorageDoors[i][1]) == -6972
                    &&  RoundFloat(g_fStorageDoors[i][2]) == 400
                ) { g_bEarlyLock = true; break; }                   // HiD: 1078154
                if (    RoundFloat(g_fStorageDoors[i][0]) == -6236
                    &&  RoundFloat(g_fStorageDoors[i][1]) == -6971
                    &&  RoundFloat(g_fStorageDoors[i][2]) == 264
                ) { g_bEarlyLock = true; break; }                   // HiD: 1092335
                if (    RoundFloat(g_fStorageDoors[i][0]) == -8634
                    &&  RoundFloat(g_fStorageDoors[i][1]) == -7266
                    &&  RoundFloat(g_fStorageDoors[i][2]) == -12
                ) { g_bEarlyLock = true; break; }                   // HiD: 1121749
            }
        }
        
        if (g_bEarlyLock) {
            PrintDebug(2, "[rand] Early locked door(s) in map detected.");
        }
    }
    
    // and lock the doors straight away
    LockDoors();
}

// Apply doorlocks
RestoreDoors()
{
    if (!g_iDoorsLockedTotal) { return; }
    
    // find doors to lock by hammerid
    new entityCount = GetEntityCount();
    new String: classname[64];
    new total = 0;
    
    for (new i=1; i < entityCount; i++)
    {
        if (!IsValidEntity(i)) continue;
        
        GetEdictClassname(i, classname, sizeof(classname));
        if (!StrEqual(classname, "prop_door_rotating")) { continue; }
        if (GetEntProp(i, Prop_Data, "m_spawnflags") & (1<<19)) { continue; }       //check for unbreakable flag
        
        // in locked doors event, close all doors (even if not locking them)
        if (g_iSpecialEvent == _:EVT_DOORS) { AcceptEntityInput(i, "Close"); }
        
        new Float: origin[3];
        GetEntPropVector(i, Prop_Send, "m_vecOrigin", origin);                      // can't trust HamId     GetEntProp(i, Prop_Data, "m_iHammerID");
        
        new bool: inArray = false;
        for (new j=0; j < g_iDoorsLockedTotal; j++)
        {
            if (    origin[0] == g_fStorageDoors[j][0]
                &&  origin[1] == g_fStorageDoors[j][1]
                &&  origin[2] == g_fStorageDoors[j][2]
            ) {
                inArray = true;
                break;
            }
        }
        if (!inArray) { continue; }
        
        // this is a door that should be locked (again):
        g_iDoorsLocked[total] = i;
        total++;
    }
    
    PrintDebug(1, "[rand] Re-locked %i same doors.", total);
    
    LockDoors();
}

LockDoors()
{
    // lock doors by entity-index
    new tmpDoor = 0;
    
    for (new i=0; i < g_iDoorsLockedTotal; i++)
    {
        tmpDoor = g_iDoorsLocked[i];
        
        AcceptEntityInput(tmpDoor, "Close");
        AcceptEntityInput(tmpDoor, "Lock");
    }
}




//  Randomization preparation
//  ------------------------------

// preparation of choice-hat (events)
RANDOM_PrepareChoicesEvents()
{
    new total = 0;
    new count = 0;
    
    
    // special event choices
    // ---------------------
    
    for (new i=0; i < EVT_TOTAL; i++)
    {
        count = GetConVarInt(g_hArCvarEvtWeight[i]);
        
        // if event is sitting in timeout, ignore it
        if (g_iArEventTimeout[i] > 0) { continue; }
        
        // remove if event is banned for this map
        //      EVT_ADREN: because most finales are campfests, which doesn't rush well
        //      EVT_MINITANKS: because distance works differently
        //      EVT_AMMO: because of fancy way ammo is handled in finales anyway
        //      EVT_WITCHES: don't mix it with tanks
        if (    g_RI_bIsFinale
            &&  ( i == EVT_ADREN || i == EVT_MINITANKS || i == EVT_AMMO || i == EVT_WOMEN || i == EVT_WITCHES || i == EVT_PEN_TIME )
        ) {
            continue;
        }
        
        
        
        // remove some events if we have fixed tanks
        if (    g_RI_bNoTank
            &&  ( i == EVT_ADREN || i == EVT_MINITANKS || i == EVT_WOMEN || i == EVT_WITCHES )
        ) {
            continue;
        }
        
        // remove some events if we can't spawn witches
        if (    g_RI_bNoWitch
            &&  ( i == EVT_WITCHES )
        ) {
            continue;
        }
        
        // remove some events if we're in campaign mode
        //      EVT_QUADS: because AI isn't much fun anyway
        //      EVT_L4D1: because it's not worth making the spawns compatible just for coop
        //      EVT_FF: because that messes with skill level
        //      EVT_MINITANKS: because of health values etc
        //      all scoring events, because no score
        if (    g_bCampaignMode
            &&  (   i == EVT_QUADS || i == EVT_L4D1 || i == EVT_FF || i == EVT_MINITANKS
                ||  i == EVT_PEN_ITEM || i == EVT_PEN_HEALTH || i == EVT_PEN_M2 || i == EVT_PEN_TIME || i == EVT_SKEET || i == EVT_WITCHES || i == EVT_BADSANTA )
        ) {
            continue;
        }
        
        // many or no doors? change event availability
        if ( i == EVT_DOORS || i == EVT_KEYMASTER )
        {
            if (g_RI_iDoors == 0) {
                continue;
            }
            else if (g_RI_iDoors == 2) {
                count *= MANY_DOORS_EVENTFACTOR;
            }
        }
        
        // storm maps? ( 2 == blood harvest weather )
        if (g_RI_iNoStorm == 2)
        {
            if (i == EVT_FOG) {
                continue;
            }
            else if (i == EVT_WEATHER) {
                // give more chance -- make FOV => WEATHER
                count += GetConVarInt(g_hArCvarEvtWeight[EVT_FOG]);
            }
        }
        else if ( g_RI_iNoStorm == 1 && (i == EVT_WEATHER || i == EVT_FOG) )
        {
            continue;
        }
        
        // note: on g_RI_bNoWitch, block future EVT_MINIWITCH event...
        
        for (new j=0; j < count; j++)
        {
            g_iArEventWeightedChoices[total+j] = i;
        }
        total += count;
    }
    g_iEventWeightedChoicesTotal = total;
    
    PrintDebug(0, "[rand] Prepared special event weight array: %i total weight over %i events.", total, EVT_TOTAL);
}

// preparation of choice-hat (gift effects)
RANDOM_PrepareChoicesGiftEffects()
{
    new total = 0;
    new count = 0;
    
    
    // gift effect choices
    // ---------------------
    for (new i=0; i < GIFT_TOTAL; i++)
    {
        count = GetConVarInt(g_hArCvarGiftWeight[i]);
        
        // remove if event / map condition blocks effect
        if (    g_bNoAmmo && ( i == GIFT_POS_AMMO ) ) {
            continue;
        }
        
        // temp-health event(s): give temp health instead of full health
        if ( _:g_iSpecialEvent == EVT_ADREN ) {
            if (i == GIFT_POS_HEALTH) {
                continue;
            }
            else if (i == GIFT_POS_HEALTH_T) {
                count += GetConVarInt(g_hArCvarGiftWeight[GIFT_POS_HEALTH]);
            }
        }
        
        // events that have special weapon rules: don't steal primary
        else if ( _:g_iSpecialEvent == EVT_GUNSWAP ) {
            // no gift steal effects yet
        }
        
        for (new j=0; j < count; j++)
        {
            g_iArGiftWeightedChoices[total+j] = i;
        }
        total += count;        

        if (i == GIFT_FIRST_NEG) { g_iGiftWeightedChoicesStartNegative = total - count; }
        else if (i == GIFT_FIRST_POS_NSR) { g_iGiftWeightedChoicesStartPosSaferoom = total - count; }
        else if (i == GIFT_FIRST_NEG_NSR) { g_iGiftWeightedChoicesStartNegSaferoom = total - count; }
        else if (i == GIFT_POS_INSIGHT) { g_iGiftWeightedChoicesStartPosInsight = total - count; }
        else if (i == GIFT_NEG_INSIGHT) { g_iGiftWeightedChoicesStartNegInsight = total - count; }
    }

    g_iGiftWeightedChoicesTotal = total;
    
    PrintDebug(1, "[rand] Prepared gift weight array: %i total weight over %i events.", total, GIFT_TOTAL);
}

// preparation of choice-hat (SI spawns)
RANDOM_PrepareChoicesSpawns()
{
    new total = 0;
    new count = 0;
    new i = 0;
    
    for (new x = 1; x <= 6; x++)
    {
        // change order, so we can use a 'start cappers' offset
        //  i = class type, x = just for looping
        if (x == ZC_SMOKER) { i = ZC_SPITTER; }
        else if (x == ZC_SPITTER) { i = ZC_SMOKER; }
        else { i = x; }
        
        count = g_ciSpawnClassWeight[i];
        
        // different weight for special events
        if (_:g_iSpecialEvent == EVT_SKEET)
        {
            // big chance of hunters, small chance for remaining cappers
            if (i == ZC_HUNTER) {
                count = 21;  // 8/10 for sum of 7,7,7,6 = 27
            } else if (i != ZC_BOOMER && i != ZC_SPITTER) {
                count = 2;
            }
        }
        else if (_:g_iSpecialEvent == EVT_QUADS)
        {
            g_iSpawnWeightedChoicesStartCappers = 0;
            if (i == ZC_BOOMER || i == ZC_SPITTER) { continue; }
        }
        else if (_:g_iSpecialEvent == EVT_L4D1)
        {
            // no tickets for non-L4D1 classes
            if (i > ZC_HUNTER) { continue; }
        }
        else if (_:g_iSpecialEvent == EVT_WOMEN)
        {
            // no tickets for cappers
            if (i == ZC_BOOMER)         { count = 5; }
            else if (i == ZC_SPITTER)   { count = 2; }
            else                        { continue; }
        }
        else if (_:g_iSpecialEvent == EVT_HORDE_NONE)
        {
            if (i == ZC_BOOMER)         { count -= 2; }
        }
        
        for (new j=0; j < count; j++)
        {
            g_iArSpawnWeightedChoices[total+j] = i;
        }
        total += count;
        
        // set start/end of secondary choices
        if (i == ZC_BOOMER) { g_iSpawnWeightedChoicesStartCappers = total; }
        
    }
    g_iSpawnWeightedChoicesTotal = total;

    //PrintDebug(2, "[rand] Prepared spawn classes weight array: %i total weight over %i categories.", total, ZC_CHARGER);
}

// preparation of choice-hat (items etc)
RANDOM_PrepareChoices()
{

    /*
        build the array from which choices will be picked each time
        each index represents 1/[total]th chance
            the advantage of this is that the loop is only needed once
            the array can be used at any time for quick picks
    */
    
    // map items:
    // ----------
    
    // apply noitem variance
    new Float: fNoitemVariance = GetConVarFloat(g_hCvarNoitemVariance);
    new iSpecialItemWeight = 0;                                             // used only for EVT_ITEM
    
    // special case: abundance event = no 'no item' category
    if (_:g_iSpecialEvent == EVT_ABUNDANCE) {
        fNoitemVariance = 0.0;
        PrintDebug(1, "[rand] No-Item Variation set to 0 (for abundance).");
    } else {
        if (fNoitemVariance) {
            
            // let item variance be determined by difficulty setting in campaign mode
            if (g_bCampaignMode)
            {
                new String:tmpStr[16];
                GetConVarString(FindConVar("z_difficulty"), tmpStr, sizeof(tmpStr));
                if (StrEqual(tmpStr, "impossible", false)) {
                    fNoitemVariance = 2.0;
                } else if (StrEqual(tmpStr, "hard", false)) {
                    fNoitemVariance = 1.5;
                } else if (StrEqual(tmpStr, "easy", false)) {
                    fNoitemVariance = 0.5;
                } else {
                    fNoitemVariance = 1.0;
                }
            }
            else
            {
                fNoitemVariance = 1.0 + GetRandomFloat((-1 * fNoitemVariance), fNoitemVariance);
                
                new Float: fVarianceTmp = 0.0;
                
                if (GetConVarBool(g_hCvarDifficultyBalance))
                {
                    // adjust for difficulty setting (weighs in 2-to-1)
                    if (g_iDifficultyRating <= DIFF_RATING_NOITEM_DIF_LOW) {
                        fVarianceTmp = DIFF_RATING_NOITEM_HIGH;
                    } else if (g_iDifficultyRating >= DIFF_RATING_NOITEM_DIF_HIGH) {
                        fVarianceTmp = DIFF_RATING_NOITEM_LOW;
                    } else {
                        // scale tmp noitem variance according to difficulty within range (reverse because higher difficulty => lower noitem variance)
                        fVarianceTmp = DIFF_RATING_NOITEM_LOW + ( (DIFF_RATING_NOITEM_HIGH - DIFF_RATING_NOITEM_LOW) * ( 1.0 - ( (float(g_iDifficultyRating) - DIFF_RATING_NOITEM_DIF_LOW) / DIFF_RATING_NOITEM_DIF_HIGH ) ) );
                        //PrintDebug(3, "[rand] Var calc: LOW: %.2f - HIGH-LOW: %.2f - scale: %.2f ", DIFF_RATING_NOITEM_LOW, DIFF_RATING_NOITEM_HIGH - DIFF_RATING_NOITEM_LOW, 1.0 - ( (float(g_iDifficultyRating) - DIFF_RATING_NOITEM_DIF_LOW) / DIFF_RATING_NOITEM_DIF_HIGH ));
                    }
                }
                
                if (fVarianceTmp != 0.0) {
                    // take average of 2* difficulty-rating variance + 1* random variance
                    fNoitemVariance = ( (2.0 * fNoitemVariance) + (3.0 * fVarianceTmp) ) / 5;
                    
                    PrintDebug(1, "[rand] No-Item Variation: %.1f (scaled towards: %.1f for difficulty).", fNoitemVariance, fVarianceTmp);
                } else {
                    PrintDebug(1, "[rand] No-Item Variation: %.1f (not scaled according to difficulty).", fNoitemVariance);
                }
                
                
            }
        } else {
            fNoitemVariance = 1.0;
        }
    }
    
    new total = 0;
    new total_items = 0;
    new count = 0;
    
    // adjust for 2v2 or 3v3 (prepend INDEX_NOITEM x times)
    new iSurvivorLimit = GetConVarInt(g_hCvarTeamSize);
    if (iSurvivorLimit == 2 || iSurvivorLimit == 3) {
        
        if (total_items != total) {
            
            new iNoItemExtra = RoundFloat(float(total) / ( ((iSurvivorLimit == 2) ? g_RC_fItemFactor2v2 : g_RC_fItemFactor3v3) * (float(total_items) / float(total)) )) - total;
            if (iNoItemExtra < 0) { iNoItemExtra = 0; }
            
            PrintDebug(2, "[rand] Adding %i to no-item weight for %i-survivor balance.", iNoItemExtra, iSurvivorLimit);

            for (new j=0; j < iNoItemExtra; j++) {
                g_iArWeightedChoices[total+j] = INDEX_NOITEM;
            }        
            
            total += iNoItemExtra;
        }
    }
    
    // add for each type's index
    for (new i=0; i < INDEX_TOTAL; i++)
    {
        count = GetConVarInt(g_hArCvarWeight[i]);
        
        // descrease non-useful items / noitems for finales (by a factor)
        if (g_RI_bIsFinale && (i == INDEX_JUNK || INDEX_NOITEM) && GetConVarFloat(g_hCvarFinaleItemUseful) > 0.0) {
            count = RoundToCeil( float(count) * GetConVarFloat(g_hCvarFinaleItemUseful) );
        }
        
        if (i == INDEX_NOITEM) {
            count = RoundFloat(float(count) * fNoitemVariance);
        } else {
            if (_:g_iSpecialEvent == EVT_ABUNDANCE && (i == INDEX_JUNK || i == INDEX_CANISTER || i == INDEX_SILLY)) {
                // change count for abundance event:
                count = RoundFloat(float(count) * EVENT_ABUND_JUNKWGHT);
            }
            else if ( (_:g_iSpecialEvent == EVT_ITEM || _:g_iSpecialEvent == EVT_GIFTS || _:g_iSpecialEvent == EVT_BADSANTA) && i == g_iSpecialEventExtra) {
                count = 0;  // set to 0 for now, insert real value later
            }
            else if (_:g_iSpecialEvent == EVT_DEFIB) {
                // no kits, more pills for defib event
                if (i == INDEX_KIT) { count = RoundFloat(float(count) * EVENT_DEFIB_EXTRA); }
                else if (i == INDEX_PILL) { count = RoundFloat(float(count) * EVENT_DEFIB_PILLS); }
            }
            else if (_:g_iSpecialEvent == EVT_ADREN) {
                // shift item balance around for rush
                if (i == INDEX_PILL) { count = RoundFloat(float(count) * EVENT_ADREN_EXTRA); }
                else if (i == INDEX_KIT) { count = 0; }
                else if (i == INDEX_UPGRADE || i == INDEX_CANISTER) { count = RoundToCeil(float(count) * EVENT_ADREN_LESSER); }
            }
            else if (_:g_iSpecialEvent == EVT_L4D1) {
                // no l4d2-only items
                if (i == INDEX_UPGRADE || i == INDEX_MELEE || i == INDEX_T3) { count = 0; }
            }
            total_items += count;
        }
        
        for (new j=0; j < count; j++)
        {
            g_iArWeightedChoices[total+j] = i;
        }
        total += count;
        
        // set start/end of useful
        if (i == INDEX_NOITEM) { g_iWeightedChoicesStartUseful = total; }
        //else if (i == INDEX_CANISTER) { g_iWeightedChoicesStartNonWeapons = total - count; }
        else if (i == INDEX_JUNK) { g_iWeightedChoicesEndUseful = total - count; }
        
        //PrintDebug(2, "[rand] choices weighted for: %i = %i", i, count);
    }
    
    // adjust for special event: item type
    if (_:g_iSpecialEvent == EVT_ITEM || _:g_iSpecialEvent == EVT_GIFTS) {
        iSpecialItemWeight = RoundFloat(float(total) * EVENT_ITEM_WEIGHT);
        for (new j=0; j < iSpecialItemWeight; j++)
        {
            g_iArWeightedChoices[total+j] = g_iSpecialEventExtra;
        }
        total += iSpecialItemWeight;
        total_items += iSpecialItemWeight;
    }
    else if (_:g_iSpecialEvent == EVT_BADSANTA) {
        iSpecialItemWeight = RoundFloat(float(total) * EVENT_BADSANTA_WEIGHT);
        for (new j=0; j < iSpecialItemWeight; j++)
        {
            g_iArWeightedChoices[total+j] = g_iSpecialEventExtra;
        }
        total += iSpecialItemWeight;
        total_items += iSpecialItemWeight;
    }
    
    // store total items in weight array
    g_iWeightedChoicesTotal = total;
    
    PrintDebug(0, "[rand] Prepared item weight array: %i total weight over %i categories.", total, INDEX_TOTAL);
    
    
    // survivor start items
    // --------------------
    total = 0;
    count = 0;
    
    for (new i=0; i < INDEX_SURV_TOTAL; i++)
    {
        count = GetConVarInt(g_hArCvarSurvWeight[i]);
        
        // different weight for special picked item EVT_ITEM
        if (_:g_iSpecialEvent == EVT_ITEM && i == g_iSpecialEventExtra) {
            count = iSpecialItemWeight;
        }
        
        for (new j=0; j < count; j++)
        {
            g_iArSurvWeightedChoices[total+j] = i;
        }
        total += count;
        
        // set start/end of secondary choices
        if (i == INDEX_SURV_NOTHING) { g_iSurvWeightedChoicesStartSecondary = total; }
        else if (i == INDEX_SURV_MAGNUM) { g_iSurvWeightedChoicesEndSecondary = total - count; g_iSurvWeightedChoicesStartPrimary = total; }
        
        //PrintDebug("[rand] choices weighted for: %i = %i", i, count);
    }
    g_iSurvWeightedChoicesTotal = total;
    
    PrintDebug(1, "[rand] Prepared survivor item weight array: %i total weight over %i categories.", total, INDEX_SURV_TOTAL);
}
