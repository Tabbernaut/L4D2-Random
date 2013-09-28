#pragma semicolon 1
#include <sourcemod>


/*
    Time Penalty
    ------------------
*/
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

/*
    Gun Swap
    ------------------
*/
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


/*
    Ammo Shortage
    ------------------
*/
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


/*
    MEDIC!
    ------------------
*/
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


/*
    Boomer Flu
    ------------------
*/

// boomer flu timer
public Action: Timer_BoomFlu(Handle:timer)
{
    // when paused, don't keep ticking
    if (g_bIsPaused || g_iSpecialEventRole < 1) {
        return Plugin_Continue;
    }
    
    // halt timer on round end
    if ( g_iSpecialEvent != EVT_BOOMFLU || ( !g_bCampaignMode && !g_bInRound ) || g_hBoomFluTimer == INVALID_HANDLE ) {
        g_hBoomFluTimer = INVALID_HANDLE;
        return Plugin_Stop;
    }
    
    g_iBoomFluCounter++;
    
    if ( g_iBoomFluCounter >= g_iBoomFluActivate )
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

/*
    Encumbrance
    ------------------
*/

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


/*
    Booby Traps
    ------------------
*/

EVENT_ReportBoobytrap(client=-1)
{
    // only on BOOBYTRAP event
    if (client > 0) {
        PrintToChatAll("\x01[\x05r\x01] %N triggered a booby trap!", client);
    } else {
        PrintToChatAll("\x01[\x05r\x01] a booby trap was triggered!");
    }
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


/*
    Haunted Doors
    ------------------
*/
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


/*
    Witch Hunt [ CanadaRox's WP code ]
    ------------------
*/
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