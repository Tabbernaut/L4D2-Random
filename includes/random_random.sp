#pragma semicolon 1
#include <sourcemod>

/*
    All the super-interesting random stuff goes in here
    (for easier finding / editing
*/


// Report randomness
// --------------------------
DoReport(client = 0)
{
    new String: sReport[MAX_REPORTLINES][REPLINELENGTH];
    new iLine = 0;
    
    
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
    
    // report special event, if any
    if (g_iSpecialEvent != -1) {
        if (g_iSpecialEvent == _:EVT_ITEM) {
            Format(sReport[iLine], REPLINELENGTH, "\x03Special Event\x01! %s%s.", g_csEventText[g_iSpecialEvent], g_csItemTypeText[g_iSpecialEventExtra] );
        } else if (g_iSpecialEvent == _:EVT_SILENCE) {
            Format(sReport[iLine], REPLINELENGTH, "\x03Special Event\x01! %s%s.", g_csEventText[g_iSpecialEvent], (g_iSpecialEventExtra == SILENCED_SI) ? "special infected" : "survivors" );
        } else {
            Format(sReport[iLine], REPLINELENGTH, "\x03Special Event\x01! %s", g_csEventText[g_iSpecialEvent]);
        }
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
}

DoInsightReport(team=-1)
{
    new String: sReport[MAX_REPORTLINES][REPLINELENGTH];
    new iLine = 0;
    
    
    // whether tank will spawn
    if (g_bTankWillSpawn)
    {
        if (g_bDoubleTank) {
            Format(sReport[iLine], REPLINELENGTH, "There are \x05two\x01 tanks this round, at \x05%d%%\x01 and \x05%d%%\x01.", RoundFloat(100.0 * g_fTankFlowEarly), RoundFloat(100.0 * g_fTankFlowLate));
        } else {
            Format(sReport[iLine], REPLINELENGTH, "There is tank this round, at \x05%d%%\x01.", RoundFloat(100.0 * L4D2Direct_GetVSTankFlowPercent( (g_bSecondHalf) ? 1 : 0 ) ) );
        }
        iLine++;
    }
    
    if (g_bWitchWillSpawn)
    {
        if (g_bMultiWitch && g_iWitchNum > 1) {
            Format(sReport[iLine], REPLINELENGTH, "There are \x05%d\x01 witches this round. The first is at \x03%d%%\x01, the last at \x03%d%%\x01.", RoundFloat(100.0 * g_fArWitchFlows[0]), RoundFloat(100.0 * g_fArWitchFlows[ g_iWitchNum - 1 ] ) );
        } else {
            Format(sReport[iLine], REPLINELENGTH, "There is a witch this round, at \x03%d%%\x01.", RoundFloat(100.0 * L4D2Direct_GetVSWitchFlowPercent( (g_bSecondHalf) ? 1 : 0 ) ) );
        }
        iLine++;
    }
    
    // gnomes / cola
    Format(sReport[iLine], REPLINELENGTH, "Bonus items: this map has \x05%d\x01 gnome%s and \x05%d\x01 cola pack%s.", g_iCountItemGnomes, (g_iCountItemGnomes == 1) ? "" : "s", g_iCountItemCola, (g_iCountItemCola == 1) ? "" : "s" );
    iLine++;
    
    // medkits / defibs
    Format(sReport[iLine], REPLINELENGTH, "Health items: this map has \x05%d\x01 first aid kit%s and \x05%d\x01 defib%s.", g_iCountItemMedkits, (g_iCountItemMedkits == 1) ? "" : "s", g_iCountItemDefibs, (g_iCountItemDefibs == 1) ? "" : "s" );
    iLine++;
    
    
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

// Make random stuff happen
// --------------------------
RANDOM_DetermineRandomStuff()
{
    new bool: bDoItemRePrep = false;        // true if we need to do PrepareChoices()
    
    // prepare random choices (if required)
    if (!g_bSecondHalf) {
        RANDOM_PrepareChoicesEvents();      // rebuild events weighted choices array
    }
    
    // get map name and type
    new String: mapname[64];
    new mapsType: mapnameType;
    GetCurrentMap(mapname, sizeof(mapname));
    GetTrieValue(g_hTrieMaps, mapname, mapnameType);
    
    if (mapnameType == MAPS_NOCOLA) { g_bNoColaItem = true; } else { g_bNoColaItem = false; }
    
    
    // keep old difficulty-rating if it's the second half
    if (!g_bSecondHalf)
    {
        g_iDifficultyRating = 0;
        
        // finales are harder, intros easier
        if (L4D_IsMissionFinalMap()) {
            g_iDifficultyRating += 2;
        } else if (mapnameType == MAPS_INTRO) {
            g_iDifficultyRating--;
        }
    }
    
    
    // random distance
    //      but let's not mess with changing distance halfway through a map though...
    new distMode = GetConVarInt(g_hCvarRandDistance);
    if (!g_bSecondHalf) {
        // store default distance for map, so we can recalculate on the same basis for round 2
        g_iDefaultDistance = L4D_GetVersusMaxCompletionScore();
    }
    new distNew = g_iDefaultDistance;
    
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
        PrintDebug("[rand] Distance for this round: %i.", distNew);
        
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
        
        PrintDebug("[rand] Bonus for this round: %i.", bonusNew);
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
        
        // reset after weather event
        if ( g_iSpecialEvent == _:EVT_WEATHER ||  g_iSpecialEvent == _:EVT_FOG ) {
            new Handle: hTmp = FindConVar("l4d2_storm_fogmode");
            if (hTmp != INVALID_HANDLE) { SetConVarInt(hTmp, 0); }
            SUPPORT_StormReset();
        }
        
        g_iSpecialEvent = -1;
        g_sSpecialEventExtra = "";
        g_iSpecialEventExtra = 0;
        g_iSpecialEventExtraSub = 0;
        
        // force special event if second round and first round got one...
        new Float: fSpecialEventChance = GetConVarFloat(g_hCvarSpecialEventChance);
        if (g_bSecondHalf && g_iSpecialEvent != -1) { fSpecialEventChance = 1.0; }
        
        if (GetRandomFloat(0.001,1.0) <= fSpecialEventChance) {
            
            // pick random from the available weighted choice hat
            
            new randomIndex = GetRandomInt(0, (g_iEventWeightedChoicesTotal-1));
            g_iSpecialEvent = g_iArEventWeightedChoices[randomIndex];

            // avoid random_storm requiring plugins on intro maps
            if (mapnameType == MAPS_INTRO) {
                new count = 0;  // just a safeguard to prevent eternal loops
                while ((g_iSpecialEvent == EVT_WEATHER || g_iSpecialEvent == EVT_FOG) && count < 1000) {
                    count++;
                    randomIndex = GetRandomInt(0, (g_iEventWeightedChoicesTotal-1));
                    g_iSpecialEvent = g_iArEventWeightedChoices[randomIndex];
                }
                if (count == 1000) { g_iSpecialEvent = -1; }
            }
            
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
                }
                case EVT_SNIPER: {
                    EVENT_SetDifficulty(DIFFICULTY_EASY, DIFFICULTY_NOCHANGE);
                    g_iDifficultyRating += 1;
                }
                case EVT_WEATHER: {
                    SUPPORT_StormStart();
                    g_iDifficultyRating++;
                }
                case EVT_FOG: {
                    EVENT_SetDifficulty(DIFFICULTY_NOCHANGE, DIFFICULTY_EASY);
                    new Handle: hTmp = FindConVar("l4d2_storm_fogmode");
                    if (hTmp != INVALID_HANDLE) { SetConVarInt(hTmp, 1); }
                    SUPPORT_StormStart();
                    g_iDifficultyRating++;
                }
                case EVT_DEFIB: {
                    EVENT_SetDifficulty(DIFFICULTY_EASY, DIFFICULTY_EASY);
                    SetConVarInt(FindConVar("vs_defib_penalty"), 5);
                    SetConVarInt(FindConVar("defibrillator_use_duration"), 2);
                    bDoItemRePrep = true;
                    g_iDifficultyRating++;
                }
                case EVT_ADREN: {
                    EVENT_SetDifficulty(DIFFICULTY_EASY, DIFFICULTY_NOCHANGE);
                    bDoItemRePrep = true;
                    SetConVarFloat(FindConVar("pain_pills_decay_rate"), g_fDefPillDecayRate * EVENT_ADREN_DECAY);
                    g_iDifficultyRating++;
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
                }
                case EVT_FF: {
                    EVENT_SetDifficulty(DIFFICULTY_EASY, DIFFICULTY_EASY);
                    SetConVarFloat(FindConVar("survivor_friendly_fire_factor_normal"), EVENT_FF_FACTOR);
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
                case EVT_GUNSWAP: {
                    // don't allow normal weapon spawns
                    g_bNoWeaponsNoAmmo = true;
                }
                case EVT_MINITANKS: {
                    
                    // set health (lower)
                    SetConVarInt(FindConVar("z_tank_health"), MINITANKS_HEALTH);
                    SetConVarInt(FindConVar("z_frustration_lifetime"), MINITANK_FRUST_TIME);
                    
                    L4D2Direct_SetVSWitchToSpawnThisRound(0, false);
                    L4D2Direct_SetVSWitchToSpawnThisRound(1, false);
                    g_bWitchWillSpawn = false;
                    g_bTankWillSpawn = true;
                    
                    SUPPORT_MultiTankRandomization();
                    
                    EVENT_SetDifficulty(DIFFICULTY_EASY, DIFFICULTY_NOCHANGE);
                    g_iDifficultyRating += 2;
                }
                case EVT_KEYMASTER: {
                    // don't need to do anything here
                }
            }
            PrintDebug("[rand] Picked Special Event: %i (%s) [extra, %i, sub: %i, str: %s]", g_iSpecialEvent, g_csEventText[g_iSpecialEvent], g_iSpecialEventExtra, g_iSpecialEventExtraSub, g_sSpecialEventExtra);
            
        } else {
            g_iSpecialEvent = -1;
            PrintDebug("[rand] No Special Event.");
        }
    }
    
    // force the spawns if we have the cvars set
    if (!g_bTankWillSpawn && GetConVarFloat(FindConVar("versus_tank_chance")) == 1.0) {
        L4D2Direct_SetVSTankToSpawnThisRound(0, true);
        L4D2Direct_SetVSTankToSpawnThisRound(1, true);
        g_bTankWillSpawn = true;
    }
    if (!g_bWitchWillSpawn && GetConVarFloat(FindConVar("versus_witch_chance")) == 1.0 && _:g_iSpecialEvent != EVT_MINITANKS) {
        L4D2Direct_SetVSWitchToSpawnThisRound(0, true);
        L4D2Direct_SetVSWitchToSpawnThisRound(1, true);
        g_bWitchWillSpawn = true;
    }
    
    if (g_bTankWillSpawn) { g_iDifficultyRating += 2; }
    if (g_bWitchWillSpawn) { g_iDifficultyRating++; }
    
    PrintDebug("[rand] Boss spawns: Tank: %i (%.2f) / Witch: %i (%.2f)", g_bTankWillSpawn, L4D2Direct_GetVSTankFlowPercent( (g_bSecondHalf) ? 1 : 0 ), g_bWitchWillSpawn, L4D2Direct_GetVSWitchFlowPercent( (g_bSecondHalf) ? 1 : 0 ));
    
    // multi-tanks? if so, set first tank to spawn early and last tank to spawn late
    // only determine if tanks will spawn at all
    //      tanks should not double-spawn on finales or first maps
    if (g_bTankWillSpawn && _:g_iSpecialEvent != EVT_MINITANKS)
    {
        if (!g_bSecondHalf || !(GetConVarInt(g_hCvarEqual) & EQ_TANKS))
        {
            if (mapnameType != MAPS_INTRO && !L4D_IsMissionFinalMap() && GetRandomFloat(0.001,1.0) <= GetConVarFloat(g_hCvarDoubleTankChance))
            {
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
                
                PrintDebug("[rand] Double tank set for this round: %0.f early, %0.f late.", 100.0 * g_fTankFlowEarly, 100.0 * g_fTankFlowLate);
                
                g_iDifficultyRating += 2;  // on top of the 2 for tank already
                
            } else {
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
        }
    } else {
        // no double tanks in any case
        g_bDoubleTank = false;
    }
    
    // multi-witches?
    if (g_bWitchWillSpawn && !g_bDoubleTank && !L4D_IsMissionFinalMap() && (MULTIWITCH_ALLOW_TANK || !g_bTankWillSpawn) && _:g_iSpecialEvent != EVT_MINITANKS )
    {
        if (!g_bSecondHalf || !(GetConVarInt(g_hCvarEqual) & EQ_TANKS))
        {
            if (GetRandomFloat(0.001,1.0) <= GetConVarFloat(g_hCvarMultiWitchChance)) {
                g_bMultiWitch = true;
                SUPPORT_MultiWitchRandomization();
                g_iDifficultyRating += 2;
            } else {
                g_bMultiWitch = false;
            }
        }
    } else {
        // no double tanks in any case
        g_bMultiWitch = false;
    }
    
    // door locking
    if (!g_bSecondHalf || !(GetConVarInt(g_hCvarEqual) & EQ_DOORS) || (_:g_iSpecialEvent == EVT_L4D1 && !(GetConVarInt(g_hCvarEqual) & EQ_EVENT) ) ) {
        RandomizeDoors();
    } else {
        RestoreDoors();
    }
        
    // first attack spawns
    if (!g_bSecondHalf || !(GetConVarInt(g_hCvarEqual) & EQ_FIRST_ATTACK)) {
        RandomizeFirstSpawns();
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
                if (g_iDifficultyRating > DIFF_RATING_GLOW_THRESH && GetRandomFloat(0.001,1.0) <= GetConVarFloat(g_hCvarOutlineChance)) {
                    SetConVarInt(FindConVar("sv_disable_glow_survivors"), 0);
                    g_bGlows = true;
                    
                    PrintDebug("[rand] Survivor glows enabled because of difficulty rating (%i > %i).", g_iDifficultyRating, DIFF_RATING_GLOW_THRESH);
                } else {
                    SetConVarInt(FindConVar("sv_disable_glow_survivors"), 1);
                    g_bGlows = false;
                    g_iDifficultyRating += 3;
                    
                    PrintDebug("[rand] Survivor glows off.");
                }
            }
        }
    }
    
    // incaps
    if (!g_bSecondHalf || !(GetConVarInt(g_hCvarEqual) & EQ_INCAPS))
    {
        if (_:g_iSpecialEvent == EVT_DEFIB) {
            g_iIncaps = 0;
        } else {
            g_iIncaps = GetRandomInt(INCAP_MINIMUM, INCAP_MAXIMUM);
            
            // reduce chances of getting only 1 incap?
            if (g_iIncaps == INCAP_MINIMUM && GetRandomFloat(0.001,1.0) <= GetConVarFloat(g_hCvarAvoidIncapsChance)) {
                g_iIncaps++;
            }
            
            // if difficulty is too great, re-pick with default as minimum
            if (g_iIncaps == INCAP_MINIMUM)
            {
                if (g_iDifficultyRating > DIFF_RATING_INCAP_THRESH) {
                    g_iIncaps = GetRandomInt(2, INCAP_MAXIMUM);
                    PrintDebug("[rand] Survivor incaps increased because of difficulty rating (%i > %i).", g_iDifficultyRating, DIFF_RATING_INCAP_THRESH);
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
        if ((g_bMultiWitch && g_bArWitchSitting[0] == false) || GetRandomInt(0, 2) == 0)
        { 
            SetConVarInt(FindConVar("sv_force_time_of_day"), WITCHES_DAY);
        } else {
            SetConVarInt(FindConVar("sv_force_time_of_day"), WITCHES_NIGHT);
        }
    }
    
    // debug report difficulty rating (only display on first roundhalf or if something's changed)
    if (!g_bSecondHalf || GetConVarInt(g_hCvarEqual) < EQ_EVERYTHING)
    {
        PrintDebug("[rand] Round difficulty rating: %i", g_iDifficultyRating);
    }
}



// Randomization magic
// --------------------------
RandomizeItems()
{
    // let the magic happen, randomize the hell out of everything
    g_iStoredEntities = 0;
    
    new RandomizableOrNot: classnameRoN;
    new entityCount = GetEntityCount();
    
    new iCountNoitem = 0;                   // just some score-keeping for debugging 
    new iCountFinaleAmmo = 0;               // how many forced finale ammo piles (also decreased on re-rolls)
    
    new String:classname[128];
    new curEnt;                             // the entity we're currently storing data for

    new Float: fAmmoVarMore = 1.0 + GetConVarFloat(g_hCvarAmmoVarianceMore);
    new Float: fAmmoVarLess = 1.0 - GetConVarFloat(g_hCvarAmmoVarianceLess);
    
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
            }
            else if (L4D_IsMissionFinalMap() && classnameRoN == RANDOMIZABLE_ITEM_AMMO && GetRandomFloat(0.001,1.0) > GetConVarFloat(g_hCvarFinaleAmmoChance))
            {
                // don't touch ammo piles on finales
                iCountFinaleAmmo++;
                continue;
            }
            
            //PrintDebug("[rand] Entity %d is randomizable: %s.", i, classname);
            
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
            } else if (SAFEDETECT_IsEntityInEndSaferoom(i)) {
                g_strArStorage[curEnt][entInEndSaferoom] = true;
            }
            
            // pick random from the available weighted choice hat
            new randomIndex = GetRandomInt(0, (g_iWeightedChoicesTotal-1));
            new randomPick = g_iArWeightedChoices[randomIndex];
            
            
            // prevent finale flooded with ammo... repick
            if (iCountFinaleAmmo)
            {
                iCountFinaleAmmo--;
                randomIndex = GetRandomInt(0, (g_iWeightedChoicesTotal-1));
                randomPick = g_iArWeightedChoices[randomIndex];
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
                } else {
                    randomPick = INDEX_NOITEM;
                }
                
                // junk => useful items?
                if (GetRandomFloat(0.001,1.0) <= GetConVarFloat(g_hCvarStartItemNoJunk)) {
                    randomIndex = GetRandomInt(g_iWeightedChoicesStartUseful, g_iWeightedChoicesEndUseful);
                    randomPick = g_iArWeightedChoices[randomIndex];
                }
            }
            else if (g_strArStorage[curEnt][entInEndSaferoom])
            {
                if (GetRandomFloat(0.001,1.0) <= GetConVarFloat(g_hCvarEndSafeItem)) {
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
                }
            }
            
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
                    g_strArStorage[curEnt][entAmmoMax] = RoundFloat(GetConVarFloat(FindConVar("ammo_smg_max")) * GetRandomFloat(fAmmoVarLess, fAmmoVarMore));
                }
                
                case INDEX_T1SHOTGUN:
                {
                    if ( GetRandomInt(0, RATE_PUMPSHOT - 1) == 0 || _:g_iSpecialEvent == EVT_L4D1 ) {
                        g_strArStorage[curEnt][entPickedType] = PCK_PUMPSHOTGUN;
                    } else {
                        g_strArStorage[curEnt][entPickedType] = PCK_SHOTGUN_CHROME;
                    }
                    g_strArStorage[curEnt][entAmmoMax] = RoundFloat(GetConVarFloat(FindConVar("ammo_shotgun_max")) * GetRandomFloat(fAmmoVarLess, fAmmoVarMore));
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
                    g_strArStorage[curEnt][entAmmoMax] = RoundFloat(GetConVarFloat(FindConVar("ammo_assaultrifle_max")) * GetRandomFloat(fAmmoVarLess, fAmmoVarMore));
                }
                
                case INDEX_T2SHOTGUN:
                {
                    if ( GetRandomInt(0, RATE_PUMPSHOT - 1) == 0 || _:g_iSpecialEvent == EVT_L4D1 ) {
                        g_strArStorage[curEnt][entPickedType] = PCK_AUTOSHOTGUN;
                    } else {
                        g_strArStorage[curEnt][entPickedType] = PCK_SHOTGUN_SPAS;
                    }                        
                    g_strArStorage[curEnt][entAmmoMax] = RoundFloat(GetConVarFloat(FindConVar("ammo_autoshotgun_max")) * GetRandomFloat(fAmmoVarLess, fAmmoVarMore));
                }
                
                case INDEX_SNIPER:
                {
                    if (_:g_iSpecialEvent == EVT_L4D1) {
                        g_strArStorage[curEnt][entPickedType] = PCK_HUNTING_RIFLE;
                        g_strArStorage[curEnt][entAmmoMax] = RoundFloat(GetConVarFloat(FindConVar("ammo_huntingrifle_max")) * GetRandomFloat(fAmmoVarLess, fAmmoVarMore));
                    }
                    else if (_:g_iSpecialEvent == EVT_SNIPER || GetRandomInt(0, RATE_CSS_SNIPER - 1) == 0) {
                        if (GetRandomInt(0, 1) == 0) {
                            g_strArStorage[curEnt][entPickedType] = PCK_SNIPER_SCOUT;
                        } else {
                            g_strArStorage[curEnt][entPickedType] = PCK_SNIPER_AWP;
                        }
                        g_strArStorage[curEnt][entAmmoMax] = RoundFloat(GetConVarFloat(FindConVar("ammo_sniperrifle_max")) * GetRandomFloat(fAmmoVarLess, fAmmoVarMore));
                    }
                    else {
                        if (GetRandomInt(0, 1) == 0) {
                            g_strArStorage[curEnt][entPickedType] = PCK_HUNTING_RIFLE;
                            g_strArStorage[curEnt][entAmmoMax] = RoundFloat(GetConVarFloat(FindConVar("ammo_huntingrifle_max")) * GetRandomFloat(fAmmoVarLess, fAmmoVarMore));
                        } else {
                            g_strArStorage[curEnt][entPickedType] = PCK_SNIPER_MILITARY;
                            g_strArStorage[curEnt][entAmmoMax] = RoundFloat(GetConVarFloat(FindConVar("ammo_sniperrifle_max")) * GetRandomFloat(fAmmoVarLess, fAmmoVarMore));
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
                    if (!g_bNoColaItem && tmpRnd == 1) {
                        g_strArStorage[curEnt][entPickedType] = PCK_SILLY_COLA;
                    } else {
                        g_strArStorage[curEnt][entPickedType] = PCK_SILLY_GNOME;
                    }
                }
                
                case INDEX_GIFT:
                {
                    g_strArStorage[curEnt][entPickedType] = PCK_SILLY_GIFT;
                }
            }
            
            // TEST
            //PrintDebug("[rand] Picked ent %i: type = %i =pick=> %i", g_iStoredEntities, randomPick, g_strArStorage[curEnt][entPickedType]);

            // lookup position
            decl Float: origin[3];
            decl Float: angles[3];
            
            GetEntPropVector(i, Prop_Send, "m_vecOrigin", origin);
            
            //      if ammo spawn, ignore original angles
            if (    randomPick == INDEX_AMMO
                ||  randomPick == INDEX_UPGRADE
            ) {
                    angles[0] = 0.0; angles[1] = 0.0; angles[2] = 0.0;
            } else {
                GetEntPropVector(i, Prop_Send, "m_angRotation", angles);
            }
            
            g_strArStorage[curEnt][entOrigin_a] = origin[0];
            g_strArStorage[curEnt][entOrigin_b] = origin[1];
            g_strArStorage[curEnt][entOrigin_c] = origin[2];
            g_strArStorage[curEnt][entAngles_a] = angles[0];
            g_strArStorage[curEnt][entAngles_b] = angles[1];
            g_strArStorage[curEnt][entAngles_c] = angles[2];
            
            // copy spawnflags
            if (!(GetEntProp(i, Prop_Data, "m_spawnflags") & 1)) {
                g_strArStorage[curEnt][entSpawnPhysics] = true;
            }
            
            /*
            // debug:
            if (g_strArStorage[curEnt][entInStartSaferoom]) {
                PrintDebug("start saferoom item: %i: %s (became %i (%s)).", i, classname, g_strArStorage[curEnt][entPickedType], g_csItemTypeText[randomPick]);
            } else if (g_strArStorage[curEnt][entInEndSaferoom]) {
                PrintDebug("end saferoom item: %i: %s (became %i (%s)).", i, classname, g_strArStorage[curEnt][entPickedType], g_csItemTypeText[randomPick]);
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
        if (g_strArStorage[i][entInStartSaferoom])
        {
            arStartItems[countStartItems] = i;
            countStartItems++;
            
            if (g_strArStorage[i][entPickedType] == _:PCK_SILLY_GNOME) { countStartGnome++; }
            else if (g_strArStorage[i][entPickedType] == _:PCK_AMMO) { countStartAmmo++; }
        }
    }
    
    // chance/force ammo to be in start saferoom
    if (!countStartAmmo && GetRandomFloat(0.001,1.0) <= GetConVarFloat(g_hCvarStartItemAmmo))
    {
        new changeIndex = GetRandomInt(0, countStartItems - 1);
        
        g_strArStorage[changeIndex][entPickedType] = PCK_AMMO;
        g_strArStorage[changeIndex][entCheckOrigin] = true;
        g_strArStorage[changeIndex][entSpawnPhysics] = false;
        g_strArStorage[changeIndex][entAmmoMax] = 0;
        g_strArStorage[changeIndex][entAngles_a] = 0.0;
        g_strArStorage[changeIndex][entAngles_b] = 0.0;
        g_strArStorage[changeIndex][entAngles_c] = 0.0;
    }
    
    // chance/force gnome to be in start saferoom
    if (!countStartGnome && GetRandomFloat(0.001,1.0) <= GetConVarFloat(g_hCvarStartItemGnome))
    {
        new changeIndex = GetRandomInt(0, countStartItems - 1);
        
        g_strArStorage[changeIndex][entPickedType] = PCK_SILLY_GNOME;
        g_strArStorage[changeIndex][entCheckOrigin] = false;
        g_strArStorage[changeIndex][entSpawnPhysics] = false;
        g_strArStorage[changeIndex][entAmmoMax] = 0;
    }    
    
    // now add the entities (afterwards, so we don't remove intentionally added stuff)
    for (new i=0; i < g_iStoredEntities; i++)
    {
        CreateEntity(i);
    }
    
    // done, do a report
    DoItemsServerReport();
    //PrintDebug("[rand] Randomized and stored %i entities. (Weak weapons: %i, Strong weapons: %i, Health items: %i, Usable items: %i, Silly/Junk: %i, Nothing: %i)", g_iStoredEntities, iCountWeapon, iCountWeaponT2, iCountHealth, iCountUsable, iCountSilly, iCountNoitem);
    //PrintDebug("[rand] Generated %i gnomes and %i random gift boxes.", iCountSillyGnome, iCountSillyGift);
    
    
    // testing: did the item drop underneath the map?
    CreateTimer(TESTENTITY_TIMER, Timer_TestEntityLocation);
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
    
    // testing: did the item drop underneath the map?
    CreateTimer(TESTENTITY_TIMER, Timer_TestEntityLocation);
}

PickRandomItem(bool:onlyUseful = false, bool:noLaserSight = false)
{
    // just pick any random item.
    //  weighted? not for this, not for now.
    //  save in temporary struct
    
    new randomPick = PCK_NOITEM;
    new randomIndex;
    
    if (onlyUseful) {
        randomIndex = GetRandomInt(INDEX_PISTOL, INDEX_LAST_USEFUL);
    } else {
        randomIndex = GetRandomInt(INDEX_PISTOL, INDEX_TOTAL - 1);      // we're not doing NOITEM, so start at pistol (1)
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
        }
    }
    
    if (_:g_iSpecialEvent == EVT_L4D1) {
        if (randomIndex == INDEX_MELEE || randomIndex == INDEX_T3) { randomIndex = INDEX_PISTOL; }
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
            g_strTempItemSingle[entAmmoMax] = RoundFloat(GetConVarFloat(FindConVar("ammo_smg_max")) * GetRandomFloat(fAmmoVarLess, fAmmoVarMore));
        }
        
        case INDEX_T1SHOTGUN: {
            if (GetRandomInt(0, 1) == 0 || _:g_iSpecialEvent == EVT_L4D1) { randomPick = PCK_PUMPSHOTGUN; } else { randomPick = PCK_SHOTGUN_CHROME; }
            g_strTempItemSingle[entAmmoMax] = RoundFloat(GetConVarFloat(FindConVar("ammo_shotgun_max")) * GetRandomFloat(fAmmoVarLess, fAmmoVarMore));
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
            g_strTempItemSingle[entAmmoMax] = RoundFloat(GetConVarFloat(FindConVar("ammo_assaultrifle_max")) * GetRandomFloat(fAmmoVarLess, fAmmoVarMore));
        }
        
        case INDEX_T2SHOTGUN: {
            if (GetRandomInt(0, 1) == 0 || _:g_iSpecialEvent == EVT_L4D1) { randomPick = PCK_AUTOSHOTGUN; } else { randomPick = PCK_SHOTGUN_SPAS; }
            g_strTempItemSingle[entAmmoMax] = RoundFloat(GetConVarFloat(FindConVar("ammo_autoshotgun_max")) * GetRandomFloat(fAmmoVarLess, fAmmoVarMore));
        }
        
        case INDEX_SNIPER: {
            new tmpRnd = GetRandomInt(0, 3);
            if (_:g_iSpecialEvent == EVT_L4D1) { tmpRnd = 2; }
            switch (tmpRnd)  {
                case 0: { randomPick = PCK_SNIPER_SCOUT;
                          g_strTempItemSingle[entAmmoMax] = RoundFloat(GetConVarFloat(FindConVar("ammo_sniperrifle_max")) * GetRandomFloat(fAmmoVarLess, fAmmoVarMore)); }
                case 1: { randomPick = PCK_SNIPER_AWP;
                          g_strTempItemSingle[entAmmoMax] = RoundFloat(GetConVarFloat(FindConVar("ammo_sniperrifle_max")) * GetRandomFloat(fAmmoVarLess, fAmmoVarMore)); }
                case 2: { randomPick = PCK_HUNTING_RIFLE;
                          g_strTempItemSingle[entAmmoMax] = RoundFloat(GetConVarFloat(FindConVar("ammo_huntingrifle_max")) * GetRandomFloat(fAmmoVarLess, fAmmoVarMore)); }
                case 3: { randomPick = PCK_SNIPER_MILITARY;
                          g_strTempItemSingle[entAmmoMax] = RoundFloat(GetConVarFloat(FindConVar("ammo_sniperrifle_max")) * GetRandomFloat(fAmmoVarLess, fAmmoVarMore)); }
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
            if (GetRandomInt(0, 1) == 0 || _:g_iSpecialEvent == EVT_DEFIB && _:g_iSpecialEvent != EVT_L4D1) { randomPick = PCK_DEFIBRILLATOR; } else { randomPick = PCK_FIRST_AID_KIT; }
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
            if (!g_bNoColaItem && GetRandomInt(0, 1) == 0) { randomPick = PCK_SILLY_COLA; } else { randomPick = PCK_SILLY_GNOME; }
        }
        
        case INDEX_GIFT: {
            randomPick = PCK_SILLY_GIFT;
        }
    }
    
    g_strTempItemSingle[entPickedType] = randomPick;
    
    return randomPick;
}


// pick random starting setup for survivors
RandomizeSurvivorItems()
{
    new iCountPrimary = 0;      new iCountPills = 0;
    new iCountGift = 0;         new iCountAdren = 0;
    new iCountMelee = 0;
    new iCountStrip = 0;
    new randomPick;
    new meleeRandomPick;
    
    new Float: fPillsChance = GetConVarFloat(g_hCvarPillsChance);
    
    new Float: fAmmoVarMore = 1.0 + GetConVarFloat(g_hCvarAmmoVarianceMore);
    new Float: fAmmoVarLess = 1.0 - GetConVarFloat(g_hCvarAmmoVarianceLess);
    
    for (new i=0; i < TEAM_SIZE; i++)
    {
        // pick a random option
        // save it to array
        
        randomPick = GetRandomInt(0, (g_iSurvWeightedChoicesTotal-1));
        randomPick = g_iArSurvWeightedChoices[randomPick];
        
        // adjust for l4d1 mode
        if ( _:g_iSpecialEvent == EVT_L4D1 && (randomPick == INDEX_SURV_MELEE || randomPick == INDEX_SURV_MAGNUM) ) { randomPick = INDEX_SURV_DUALS; }
        
        switch (randomPick)
        {
            case INDEX_SURV_NOTHING: {      randomPick = PCK_NOITEM; iCountStrip++; }
            case INDEX_SURV_PISTOL: {       randomPick = PCK_PISTOL; }
            case INDEX_SURV_DUALS: {        randomPick = PCK_DUALS; iCountGift++; }
            case INDEX_SURV_MAGNUM: {       randomPick = PCK_PISTOL_MAGNUM; iCountGift++; }
            
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
                g_iArStorageSurvAmmo[i] = RoundFloat(GetConVarFloat(FindConVar("ammo_smg_max")) * GetRandomFloat(fAmmoVarLess, fAmmoVarMore));
                iCountGift++;
            }
            
            case INDEX_SURV_T1SHOT: {
                iCountPrimary++;
                if ( GetRandomInt(0, RATE_PUMPSHOT - 1) == 0 || _:g_iSpecialEvent == EVT_L4D1 ) {
                    randomPick = PCK_PUMPSHOTGUN;
                } else {
                    randomPick = PCK_SHOTGUN_CHROME;
                }
                g_iArStorageSurvAmmo[i] = RoundFloat(GetConVarFloat(FindConVar("ammo_shotgun_max")) * GetRandomFloat(fAmmoVarLess, fAmmoVarMore));
                iCountGift++;
            }
            
            case INDEX_SURV_MELEE: {
                randomPick = PCK_MELEE;
                meleeRandomPick = GetRandomInt(0, sizeof(g_iMeleeClassCount) - 1);
                g_iArStorageSurvMelee[i] = meleeRandomPick;
                iCountGift++;
                iCountMelee++;
            }
        }
        
        // store current pick
        g_iArStorageSurv[i] = randomPick;
        
        
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
        else if (GetRandomFloat(0.001, 1.0) <= fPillsChance || g_iDifficultyRating > DIFF_RATING_PILL_THRESH) {
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
    //      so many doors locked, guarantee two melees
    //      but ignore for keymaster event, since the keymaster can unlock
    if (g_iSpecialEvent != _:EVT_KEYMASTER)
    {
        if (g_iSpecialEvent == _:EVT_DOORS && iCountMelee < EVENT_DOORS_MINMELEE)
        {
            PrintDebug("[rand] Adding melees to deal with special event.");
            for (new i=0; i < TEAM_SIZE; i++)
            {
                if (g_iArStorageSurv[i] != _:PCK_MELEE) {
                    g_iArStorageSurv[i] = PCK_MELEE;
                    meleeRandomPick = GetRandomInt(0, sizeof(g_iMeleeClassCount) - 1);
                    g_iArStorageSurvMelee[i] = meleeRandomPick;
                    iCountMelee++;
                    if (iCountMelee >= EVENT_DOORS_MINMELEE) { break; }
                }
            }
        }
        // do a similar check if there are early door locks
        else if (g_bEarlyLock && iCountMelee < EARLY_DOORS_MINMELEE)
        {
            PrintDebug("[rand] Adding melees to deal with early locks.");
            for (new i=0; i < TEAM_SIZE; i++)
            {
                if (g_iArStorageSurv[i] != _:PCK_MELEE) {
                    g_iArStorageSurv[i] = PCK_MELEE;
                    meleeRandomPick = GetRandomInt(0, sizeof(g_iMeleeClassCount) - 1);
                    g_iArStorageSurvMelee[i] = meleeRandomPick;
                    iCountMelee++;
                    if (iCountMelee >= EARLY_DOORS_MINMELEE) { break; }
                }
            }
        }
    }
    
    // difficulty-rating based on items? weapons / pills
    if (iCountPrimary < 2) { g_iDifficultyRating++; }
    else if (iCountPrimary < 3 && iCountMelee < 2) { g_iDifficultyRating++; }
    else if (iCountStrip > 1) { g_iDifficultyRating++; }
    
    if (iCountAdren + iCountPills < 3 || (iCountPills == 0 && iCountAdren < TEAM_SIZE) ) { g_iDifficultyRating++; }
    
    // done
    PrintDebug("[rand] Randomized and stored %i survivor setups (%i gifts, %i strips).", TEAM_SIZE, iCountGift, iCountStrip);
    
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
    PrintDebug("[rand] Randomized and stored %i survivor health setups.", TEAM_SIZE);
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
CreateEntity(index, bool:inArray = true)
{
    new type, itemJunkIndex, itemAmmoMax /*, itemSpawnPhysics */;
    new Float: itemOrigin[3], Float: itemAngles[3];
    new bool: itemCheckOrigin;
    new String: itemStorageMelee[MELEE_CLASS_LENGTH];
    
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
    if (g_bNoWeaponsNoAmmo)
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
            
            case PCK_AMMO: { type = PCK_NOITEM; }
            case PCK_UPG_EXPLOSIVE: { type = PCK_NOITEM; }
            case PCK_UPG_INCENDIARY: { type = PCK_NOITEM; }
        }
    }
    
    // anything but weapons
    //      set handled to true/false, so we know we've already built the entity
    handled = true;
    switch (type)
    {
        case PCK_NOITEM: {
            g_strArStorage[index][entNumber] = 0;
            return;
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
            ent = CreateEntityByName("prop_physics");
            DispatchKeyValue(ent, "model", g_csJunkModels[itemJunkIndex]);
            DispatchKeyValue(ent, "Spawnflags", "256");                 // 4 .. might be useful to avoid blockades/abuse
            fPlaceHigher = 10.0;
            dontBlind = true;                                           // don't store for blindinfected
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
        PrintDebug("[rand] Random pick resulted in invalid entity! (index: %d, ent: %d, type: %d).", index, ent, type);
        return;
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
    if (!GetConVarBool(g_hCvarForcePhysics) && !specialCase) {
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
    } else if (GetConVarBool(g_hCvarForcePhysics)) {
        TeleportEntity(ent, origin, NULL_VECTOR, NULL_VECTOR);
    }
    
    // if a weapon, do this to prevent it having only 1 clip:
    if (itemAmmoMax) {
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
                //PrintDebug("[rand] Checked origin for item: %i (ent %i) - distance %.1f - origin:  setpos %.1f %.1f %.1f ", index, ent, fDist, origin[0], origin[1], origin[2]);
                if (FloatAbs(fDist) > 0.0) { SetEntityRenderColor(ent, 80,40,40, 100); }
            }*/
        }
        
    }
    
    
    // store entity number and reset pickup status
    if (inArray && index != -1) {
        g_strArStorage[index][entNumber] = ent;
        g_strArStorage[index][entPickedUp] = false;
    }
    
    // ammo pile to coffee
    if (type == _:PCK_AMMO) {
        if (GetRandomInt(0, 2) == 0) {
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
    PrintDebug("[rand] Created entity %i (index %i, type: %i).", ent, index, type);
    */
    /*
    if (!inArray) {
        PrintDebug("[rand] Spawned entity %i (type: %i).", ent, type);
    }
    */
}

// change the client's weapons/loadout
ChangeSurvivorSetup(index, client)
{
    new type = g_iArStorageSurv[index];
    new ammo = 0;
    new ammoOffset = 0;
    
    // pill-giving?
    switch (g_iArStorageSurvPills[index])
    {
        case PCK_PAIN_PILLS: { GiveItem(client, "weapon_pain_pills", 0, 0); }
        case PCK_ADRENALINE: { GiveItem(client, "weapon_adrenaline", 0, 0); }
    }
    
    // for defib event
    if (_:g_iSpecialEvent == EVT_DEFIB) { GiveItem(client, "weapon_defibrillator", 0, 0); }
    
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
        ||  type == _:PCK_MELEE)
    {
        new weaponIndex = GetPlayerWeaponSlot(client, PLAYER_SLOT_SECONDARY);
        
        if (weaponIndex > -1) {
            new String:classname[STR_MAX_WPCLASSNAME];
            GetEdictClassname(weaponIndex, classname, sizeof(classname)); 
            
            if (StrEqual(classname, "weapon_pistol")) {
                RemovePlayerItem(client, weaponIndex);
            }
        }
    }
        
    new String:weaponname[STR_MAX_ITEMGIVEN] = "";
    
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
            PrintDebug("[rand] Handed melee weapon (%s) to %N.", g_sMeleeClass[(g_iArStorageSurvMelee[index])], client);
            GiveItemMelee(client, g_sMeleeClass[(g_iArStorageSurvMelee[index])]);
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
        ammo = RoundFloat(GetConVarFloat(FindConVar("ammo_huntingrifle_max")) * GetRandomFloat(fAmmoVarLess, fAmmoVarMore));
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
    
    if (strlen(weaponname))
    {
        // debug reporting
        PrintDebug("[rand] Handed %s to %N (ammo: %i).", weaponname, client, ammo);
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
        return: true for normal USE continuation, false for Plugin_Handled there
*/
bool: RANDOM_PlayerGiftUse(client)
{
    // avoid use spam (block use function for some time after gift opening):
    if (g_fGiftUseTimeout[client] != 0.0 && FloatSub(GetEngineTime(), g_fGiftUseTimeout[client]) < GIFTUSE_TIMEOUT) {
        return false;
    } else {
        g_fGiftUseTimeout[client] = 0.0;    // clean up
    }
    
    // gift detection
    new entity = GetClientAimTarget(client, false);
    
    if (entity != -1)
    {
        new String:targetname[32];
        GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));
        if (!StrEqual(targetname, "random_gift")) { return true; }
        
        new Float:playerPos[3];
        new Float:targetPos[3];
        GetEntPropVector(client, Prop_Send, "m_vecOrigin", playerPos);
        GetEntPropVector(entity, Prop_Send, "m_vecOrigin", targetPos);
        new Float:distance = GetVectorDistance(playerPos, targetPos);
        
        if (distance > ITEM_PICKUP_DISTANCE) { return true; }
        
        
        // if readyup is enabled, don't allow opening until we're ready
        if (SUPPORT_IsInReady())
        {
            // show message if we didn't for a while
            if (g_fGiftReportTimeout != 0.0 && FloatSub(GetEngineTime(), g_fGiftReportTimeout) <= GIFTREPORT_TIMEOUT) { return true; }
            
            PrintToChat(client, "\x01[\x05r\x01] You must ready up before you can open a gift...");
            g_fGiftReportTimeout = GetEngineTime();
            return true;
        }
        
        
        // gift is being used
        //PrintDebug("[rand] Gift used: %i", entity);
        
        
        
        // kill the gift
        AcceptEntityInput(entity, "Kill");
        
        // take random action (use targetpos location)
        new randomPick = 0;
        
        if (GetRandomFloat(0.001,1.0) <= GetConVarFloat(g_hCvarGiftPositiveChance)) {
            // positive effect
            
            randomPick = GetRandomInt(0, (g_bInsightSurvDone) ? 8 : 9 );
            
            // special event, no ammo
            if (g_bNoWeaponsNoAmmo && (randomPick == 7 || randomPick == 8)) { randomPick = GetRandomInt(0, 6); }
            
            // fix for chance redistribution
            if (randomPick == 3 || randomPick == 4 || randomPick == 5) { randomPick = 2; }  // items - 4x
            if (randomPick == 7) { randomPick = 8; }                                        // ammo - 2x

            
            // don't give solid health when in adren mode:
            if (_:g_iSpecialEvent == EVT_ADREN && randomPick == 0) { randomPick = 1; }
            
            switch (randomPick)
            {
                case 0: {   // give some solid health
                    new someHealth = GetRandomInt(10,40);
                    new curHealth = GetClientHealth(client);
                    new Float:tmpHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
                    new oldTotal = curHealth + RoundFloat(tmpHealth);
                    
                    if (curHealth < 100) {
                        if (curHealth + someHealth < 100) { curHealth += someHealth; } else { someHealth = 100 - curHealth; curHealth = 100; }
                        SetEntityHealth(client, curHealth);
                        PrintToChatAll("\x01[\x05r\x01] %N opened gift: healed %i solid health.", client, someHealth);
                        // get rid of temp health buffer?
                        if (oldTotal > curHealth) {
                            SetEntPropFloat(client, Prop_Send, "m_healthBuffer", float(oldTotal - curHealth));
                        } else {
                            SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
                        }
                    } else {
                        PrintToChatAll("\x01[\x05r\x01] %N opened gift: useless healing.", client);
                    }
                }
                case 1: {   // give all temp health (in addition to whatever you had)
                    
                    new Float:fGameTime = GetGameTime();
                    new curHealth = GetEntProp(client, Prop_Send, "m_iHealth");
                    //new Float:tmpHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
                    if (curHealth < 100) {
                        SetEntPropFloat(client, Prop_Send, "m_healthBuffer", float(100 - curHealth));
                        SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", fGameTime);
                        PrintToChatAll("\x01[\x05r\x01] %N opened gift: temporary health given.", client);
                    } else {
                        PrintToChatAll("\x01[\x05r\x01] %N opened gift: useless healing.", client);
                    }
                }
                case 2: {   // item spawn
                    PrintToChatAll("\x01[\x05r\x01] %N opened gift: item(s).", client);
                    
                    g_strTempItemSingle[entOrigin_a] = targetPos[0];
                    g_strTempItemSingle[entOrigin_b] = targetPos[1];
                    g_strTempItemSingle[entOrigin_c] = targetPos[2];
                    
                    new itemCount = GetRandomInt(GIFT_MIN_ITEMS, GIFT_MAX_ITEMS);
                    
                    if (GetRandomInt(0, 4) == 0) {
                        // same item X times
                        PickRandomItem(true, true);
                        
                        for (new x = 0; x < itemCount; x++) {
                            g_fTempItemSingleVelocity[0] = GetRandomFloat(-160.0, 160.0);
                            g_fTempItemSingleVelocity[1] = GetRandomFloat(-160.0, 160.0);
                            g_fTempItemSingleVelocity[2] = GetRandomFloat(40.0, 160.0);
                            CreateEntity(-1, false);    // create entity, not from array!
                        }
                    } else {
                        // all different
                        
                        for (new x = 0; x < itemCount; x++) {
                            g_fTempItemSingleVelocity[0] = GetRandomFloat(-160.0, 160.0);
                            g_fTempItemSingleVelocity[1] = GetRandomFloat(-160.0, 160.0);
                            g_fTempItemSingleVelocity[2] = GetRandomFloat(40.0, 160.0);
                            PickRandomItem(true, true);
                            CreateEntity(-1, false);    // create entity, not from array!
                        }
                    }
                }
                case 6: {   // give laser sight
                    if (GetRandomInt(0, 2) == 0) {
                        // for all
                        PrintToChatAll("\x01[\x05r\x01] %N opened gift: team laser sight.", client);
                        for (new i=1; i < MaxClients; i++) {
                            if (IsClientInGame(i) && IsSurvivor(i) && IsPlayerAlive(i)) {
                                CheatCommand(i, "upgrade_add", "LASER_SIGHT");
                            }
                        }
                    } else {
                        // for the opener
                        PrintToChatAll("\x01[\x05r\x01] %N opened gift: laser sight.", client);
                        CheatCommand(client, "upgrade_add", "LASER_SIGHT");
                    }
                }
                case 8: {   // give ammo
                    if (GetRandomInt(0, 2) == 0) {
                        // for all
                        PrintToChatAll("\x01[\x05r\x01] %N opened gift: team ammo refill.", client);
                        for (new i=1; i < MaxClients; i++) {
                            if (IsClientInGame(i) && IsSurvivor(i) && IsPlayerAlive(i)) {
                                CheatCommand(i, "give", "ammo");
                            }
                        }
                    } else {
                        // for the opener
                        PrintToChatAll("\x01[\x05r\x01] %N opened gift: ammo refill.", client);
                        CheatCommand(client, "give", "ammo");
                    }
                }
                case 9: {   // give insight
                    PrintToChatAll("\x01[\x05r\x01] %N opened gift: survivor insight...", client);
                    DoInsightReport(TEAM_SURVIVOR);
                    g_bInsightSurvDone = true;
                }
            }
        }
        else {
            // negative effect
           
            randomPick = GetRandomInt(0, (g_bInsightInfDone) ? 7 : 8 );
            if (randomPick == 0 || randomPick == 2 || randomPick == 4 || randomPick == 6) { randomPick++; } // only insight has lower odds
            
            switch (randomPick) {
                case 1: {   // explosion (small and big)
                    PrintToChatAll("\x01[\x05r\x01] %N opened gift: \x04explosive surprise\x01!", client);
                    if (GetRandomInt(0, 1) == 0) {
                        CreateExplosion(targetPos, EXPLOSION_POWER_LOW);
                    } else {
                        CreateExplosion(targetPos, EXPLOSION_POWER_HIGH);
                    }
                }
                case 3: {   // panic event (sound siren of some sort)
                    PrintToChatAll("\x01[\x05r\x01] %N opened gift: \x04panic surprise\x01!", client);
                    EmitAmbientSound(PANICGIFT_SOUND, targetPos, client, SNDLEVEL_AIRCRAFT, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL);  
                    // spawn a mob (or two)..
                    SpawnPanicHorde(client, GetRandomInt(1,2));     // small or larger one..
                }
                case 5: {   // boom box-opener
                    PrintToChatAll("\x01[\x05r\x01] %N opened gift: \x04vomit surprise\x01!", client);
                    SDKCall(g_CallBileJarPlayer, client, client);
                    EmitSoundToAll(BOOMGIFT_SOUND, client);
                }
                case 7: {   // fire(works)-trap
                    if (GetRandomInt(0, 1) == 0) {
                        PrintToChatAll("\x01[\x05r\x01] %N opened gift: \x04fire surprise\x01!", client);
                        CreateFire(targetPos, false);   // fire
                    } else {
                        PrintToChatAll("\x01[\x05r\x01] %N opened gift: \x04fireworks\x01!", client);
                        CreateFire(targetPos, true);    // fireworks
                    }
                }
                case 8: {   // give insight
                    PrintToChatAll("\x01[\x05r\x01] %N opened gift: infected insight...", client);
                    DoInsightReport(TEAM_INFECTED);
                    g_bInsightInfDone = true;
                }
            }
        }
        
        // block player use function for a short while to avoid spam
        g_fGiftUseTimeout[client] = GetEngineTime();
        
        // block normal function if we opened gift..
        return false;
    }
    
    return true;
}


// Item drops (from common/SI/Tank)
// ------------------------------

RANDOM_TankDropItems()
{
    if (GetRandomFloat(0.001,1.0) <= GetConVarFloat(g_hCvarTankItemDropChance))
    {
        // location stored in global
        new count = GetRandomInt(1, TANK_DROP_ITEMS_MAX);
        
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
        PrintDebug("[rand] Common drop resulted in invalid entity! (pick: %i)", randomPick);
        return;
    } else {
        PrintDebug("[rand] Common dropped item. (pick: %i)", randomPick);
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
            //PrintDebug("Locked: %i (Location: %.1f %.1f %.1f)", i, g_fStorageDoors[total-1][0], g_fStorageDoors[total-1][1], g_fStorageDoors[total-1][2]);
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
                //PrintDebug("Locked for double doors: %i (Location: %.1f %.1f %.1f)", iDoubleDoorCheck[tmpHit], g_fStorageDoors[total-1][0], g_fStorageDoors[total-1][1], g_fStorageDoors[total-1][2]);
            }
        }
    }
    
    PrintDebug("[rand] Locked %i doors randomly (of which %i for double door pairing).", total, total - g_iDoorsLockedTotal);
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
            PrintDebug("[rand] Early locked door(s) in map detected.");
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
    
    PrintDebug("[rand] Re-locked %i same doors.", total);
    
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
        
        // remove if event is banned for this map
        //      EVT_ADREN: because most finales are campfests, which doesn't rush well
        //      EVT_MINITANKS: because distance works differently
        //      EVT_DOORS: because there are few doors on finales anyway
        if (    L4D_IsMissionFinalMap()
            &&  ( _:g_iSpecialEvent == EVT_ADREN || _:g_iSpecialEvent == EVT_MINITANKS || _:g_iSpecialEvent == EVT_DOORS )
        ) {
            continue;
        }
        
        
        
        for (new j=0; j < count; j++)
        {
            g_iArEventWeightedChoices[total+j] = i;
        }
        total += count;
    }
    g_iEventWeightedChoicesTotal = total;
    
    PrintDebug("[rand] Prepared special event weight array: %i total weight over %i events.", total, EVT_TOTAL);
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
        PrintDebug("[rand] No-Item Variation set to 0 (for abundance).");
    } else {
        if (fNoitemVariance) {
            fNoitemVariance = 1.0 + GetRandomFloat((-1 * fNoitemVariance), fNoitemVariance);
            PrintDebug("[rand] No-Item Variation: %.1f.", fNoitemVariance);
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
            
            new iNoItemExtra = RoundFloat(float(total) / ( ((iSurvivorLimit == 2) ? ITEM_FACTOR_2V2 : ITEM_FACTOR_3V3) * (float(total_items) / float(total)) )) - total;
            if (iNoItemExtra < 0) { iNoItemExtra = 0; }
            
            PrintDebug("[rand] Adding %i to no-item weight for %i-survivor balance.", iNoItemExtra, iSurvivorLimit);

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
        if (L4D_IsMissionFinalMap() && (i == INDEX_JUNK || INDEX_NOITEM) && GetConVarFloat(g_hCvarFinaleItemUseful) > 0.0) {
            count = RoundToCeil( float(count) * GetConVarFloat(g_hCvarFinaleItemUseful) );
        }
        
        if (i == INDEX_NOITEM) {
            count = RoundFloat(float(count) * fNoitemVariance);
        } else {
            if (_:g_iSpecialEvent == EVT_ABUNDANCE && (i == INDEX_JUNK || i == INDEX_CANISTER || i == INDEX_SILLY)) {
                // change count for abundance event:
                count = RoundFloat(float(count) * EVENT_ABUND_JUNKWGHT);
            }
            else if ( (_:g_iSpecialEvent == EVT_ITEM || _:g_iSpecialEvent == EVT_GIFTS) && i == g_iSpecialEventExtra) {
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
                
            if (g_bDoubleTank && i == INDEX_PILL) {
                // increase chances of finding pills/adren for 2-tank maps
                count = RoundFloat(GetConVarInt(g_hArCvarWeight[i]) * MULTITANK_HEALTHITEMS); 
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
        if (i == INDEX_JUNK) { g_iWeightedChoicesEndUseful = total - count; }
        
        //PrintDebug("[rand] choices weighted for: %i = %i", i, count);
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
    
    
    // store total items in weight array
    g_iWeightedChoicesTotal = total;
    
    PrintDebug("[rand] Prepared item weight array: %i total weight over %i categories.", total, INDEX_TOTAL);
    
    
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
        
        //PrintDebug("[rand] choices weighted for: %i = %i", i, count);
    }
    g_iSurvWeightedChoicesTotal = total;
    
    PrintDebug("[rand] Prepared survivor item weight array: %i total weight over %i categories.", total, INDEX_SURV_TOTAL);
    
}
