#pragma semicolon 1
#include <sourcemod>


/*
    HUD manipulation
    ------------------ */
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








/*
    Blindness
    ------------------ */
// update blindtimes after pause: add extra time
public Action: Timer_CheckBlindness( Handle:timer, any:client )
{
    if ( !IsClientAndInGame(client) || !IsSurvivor(client) || !IsPlayerAlive(client) || IsFakeClient(client) ) { return; }
    
    new chr = GetPlayerCharacter(client);
    
    if ( g_fGiftBlindTime[chr] != 0.0 && FloatSub( g_fGiftBlindTime[chr], GetGameTime() ) > 0.0 )
    {
        DoBlindSurvivor(client, BLIND_AMOUNT);
    }
}
        
SUPPORT_CheckBlindSurvivors( Float: fExtraTime )
{
    for ( new i = 0; i < MAX_CHARACTERS; i++ )
    {
        if ( g_fGiftBlindTime[i] != 0.0 )
        {
            g_fGiftBlindTime[i] += fExtraTime;
        }
    }
}

public Action: Timer_Blindness ( Handle:timer, any:chr )
{
    if ( g_bIsPaused ) { return Plugin_Continue; }
    
    //PrintDebug(3, "[rand] Checking chr %i: time: now: %.1f, until: %.1f", chr, GetGameTime(), g_fGiftBlindTime[chr]);
    
    if ( g_fGiftBlindTime[chr] == 0.0 || FloatSub( g_fGiftBlindTime[chr], GetGameTime() ) <= 0.0 )
    {
        // find character and unblind
        new tmpClient = GetCharacterClient(chr);
        if ( IsSurvivor(tmpClient) && !IsFakeClient(tmpClient) ) {
            // unblind
            DoBlindSurvivor(tmpClient, 0);
        }
        g_fGiftBlindTime[chr] = 0.0;
        
        return Plugin_Stop;
    }
    
    return Plugin_Continue;
}

/*
    Client status
    ------------------
*/

// just for checking rup at the moment
GetAnySurvivor()
{
    for (new i=1; i <= GetMaxClients(); i++) {
        if (IsClientConnected(i) && IsSurvivor(i)) { return i; }
    }
    return 0;
}
bool: IsClientAndInGame(index) return (index > 0 && index <= MaxClients && IsClientInGame(index));
bool: IsSurvivor(client) {
    if (IsClientAndInGame(client)) {
        return GetClientTeam(client) == TEAM_SURVIVOR;
    }
    return false;
}
bool: IsInfected(client) {
    if (IsClientAndInGame(client)) {
        return GetClientTeam(client) == TEAM_INFECTED;
    }
    return false;
}
bool: IsTank(any:client) {
    new iClass = GetEntProp(client, Prop_Send, "m_zombieClass");
    if (IsPlayerAlive(client) && iClass == ZC_TANK) { return true; }
    return false;
}


bool:IsHangingFromLedge(client) { return bool:(GetEntProp(client, Prop_Send, "m_isHangingFromLedge") || GetEntProp(client, Prop_Send, "m_isFallingFromLedge")); }
bool:IsIncapacitated(client) { return bool:GetEntProp(client, Prop_Send, "m_isIncapacitated"); }
bool: IsPlayerGhost(any:client) {
    if (GetEntProp(client, Prop_Send, "m_isGhost")) { return true; }
    return false;
}

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

// make sure survivors have at least 50h solid
SetMinimumHealthSurvivors()
{
    new health = 0;
    
    PrintDebug(3, "SetMinimumHealthSurvivors()");
    
    // exceptions?
    if ( g_iSpecialEvent == EVT_DEFIB ) { return; }
    
    for ( new i = 1; i <= GetMaxClients(); i++ )
    {
        if ( IsClientInGame(i) && IsSurvivor(i) && IsPlayerAlive(i) )
        {
            // check health
            health = GetClientHealth(i);
            if ( health < COOP_MIN_STARTHEALTH )
            {
                SetEntityHealth( i, COOP_MIN_STARTHEALTH );
                SetEntProp(i, Prop_Send, "m_currentReviveCount", 0);
                SetEntProp(i, Prop_Send, "m_bIsOnThirdStrike", 0);
                SetEntProp(i, Prop_Send, "m_isGoingToDie", 0);
                //SetEntData( i, FindDataMapOffs(i, "m_iHealth"), COOP_MIN_STARTHEALTH, 4, true);
            }
        }
    }
}

stock GetCharacterClient( chr )
{
    for ( new client = 1; client <= MaxClients; client++ )
    {
        if ( IsClientInGame(client) && GetClientTeam(client) == TEAM_SURVIVOR && !IsFakeClient(client) )
        {
            if ( GetPlayerCharacter(client) == chr ) { return client; }
        }
    }
    
    return 0;
}
stock GetPlayerCharacter( client )
{
    new tmpChr = GetEntProp(client, Prop_Send, "m_survivorCharacter");
    
    // use models when incorrect character returned
    if (tmpChr < 0 || tmpChr >= MAX_CHARACTERS)
    {
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

/*
    Scoring manipulation
    -----------------
*/
// get actual map distance, even when frozen, and including holdout bonus
ActualMapDistance()
{
    return ( ( g_bFrozenPoints ) ? g_iRememberFrozenDistance : L4D_GetVersusMaxCompletionScore() ) + ( ( g_bHoldoutActive ) ? g_iHoldoutBonus : 0 );
}

public Action: Timer_FreezePoints ( Handle:timer, any:showMessage )
{
    SUPPORT_FreezePoints( bool:showMessage );
}
SUPPORT_FreezePoints( bool:bShowMessage = false )
{
    if ( !g_bFrozenPoints ) {
        if ( bShowMessage ) PrintToChatAll("\x01[\x05r\x01] \x04Freezing\x01 distance points until tank is killed.");
        PrintDebug(1, "[rand] freezing distance points (old value: %i)", g_iRememberFrozenDistance);
        L4D_SetVersusMaxCompletionScore(0);
        g_bFrozenPoints = true;
    }
}

SUPPORT_UnFreezePoints( bool:bShowMessage = false )
{
    if ( g_bFrozenPoints ) {
        if ( bShowMessage ) PrintToChatAll("\x01[\x05r\x01] \x01Unfreezing\x01 distance points.");
        PrintDebug(1, "[rand] UN-freezing distance points (reset to value: %i)", g_iRememberFrozenDistance);
        L4D_SetVersusMaxCompletionScore(g_iRememberFrozenDistance);
        g_bFrozenPoints = false;
    }
}

/*
    Spawning infected
    ------------------
*/
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

public Action: Timer_KillInfected (Handle:timer, any:client)
{
    if ( IsClientAndInGame(client) && IsPlayerAlive(client))
    {
        ForcePlayerSuicide(client);
    }
}
/*
    Weapon nerfing
    ------------------
 */

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
        if (tierType == NERFTYPE_T2) {
            PrintToChat(client, "\x01[\x05r\x01] Only single pistol allowed with \x04T2\x01 rifle/shotgun. Dropped secondary.");
            PrintHintText(client, "Only single pistol allowed with T2 rifle/shotgun. Dropped secondary!");
        }
        else {
            PrintToChat(client, "\x01[\x05r\x01] Only single or dual pistol allowed with \x04sniper\x01. Dropped secondary.");
            PrintHintText(client, "Only single or dual pistol allowed with sniper. Dropped secondary!");
        }
    }
}


/*
    Items and weapons
    -----------------
*/

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
        else if (StrEqual("weapon_sniper_military", classname, false)) {
            new iClipAmmo = 15 - GetEntProp(weapon, Prop_Send, "m_iClip1");
            iProperAmmo = g_iActiveAmmoSniper + iClipAmmo;
            iOffset = MILITARY_SNIPER_OFFSET_IAMMO;
        }
        
        if (iProperAmmo != -1)
        {
            new ammo = GetEntData(client, (iAmmoOffset + iOffset));
            //PrintDebug(3, "[rand] ammo for client %N: %i (%s)- ammo: %i / %i", client, iOffset, classname, ammo, iProperAmmo);
            if (ammo != iProperAmmo) {
                SetEntData(client, (iAmmoOffset + iOffset), iProperAmmo);
            }
        }
    }
}

/*
    General functions
    ------------------
*/

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
// damage a player
ApplyDamageToPlayer( damage, victim, attacker )
{
    new Handle: pack = CreateDataPack();
    WritePackCell(pack, damage);
    WritePackCell(pack, victim);
    WritePackCell(pack, attacker);
    CreateTimer( 0.1, Timer_ApplyDamage, pack);
}

public Action: Timer_ApplyDamage (Handle:timer, Handle:dataPack)
{
    ResetPack(dataPack);
    new damage = ReadPackCell(dataPack);  
    new victim = ReadPackCell(dataPack);
    new attacker = ReadPackCell(dataPack);
    CloseHandle(dataPack);   

    decl Float:victimPos[3], String:strDamage[16], String:strDamageTarget[16];
    
    GetClientEyePosition(victim, victimPos);
    IntToString(damage, strDamage, sizeof(strDamage));
    Format(strDamageTarget, sizeof(strDamageTarget), "hurtme%d", victim);
    
    new entPointHurt = CreateEntityByName("point_hurt");
    if (!entPointHurt) { return; }

    // Config, create point_hurt
    DispatchKeyValue(victim, "targetname", strDamageTarget);
    DispatchKeyValue(entPointHurt, "DamageTarget", strDamageTarget);
    DispatchKeyValue(entPointHurt, "Damage", strDamage);
    DispatchKeyValue(entPointHurt, "DamageType", "0"); // DMG_GENERIC
    DispatchSpawn(entPointHurt);
    
    // Teleport, activate point_hurt
    TeleportEntity(entPointHurt, victimPos, NULL_VECTOR, NULL_VECTOR);
    AcceptEntityInput(entPointHurt, "Hurt", (IsClientAndInGame(attacker)) ? attacker : -1);
    
    // Config, delete point_hurt
    DispatchKeyValue(entPointHurt, "classname", "point_hurt");
    DispatchKeyValue(victim, "targetname", "null");
    RemoveEdict(entPointHurt);
}

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

// stop animations we triggered
EndSurvivorAnim(client)
{
    // doesn't work right, simply do animation change instead
    //new PropOff_flCycle = FindSendPropInfo("CTerrorPlayer", "m_flCycle");
    //SetEntDataFloat(client, PropOff_flCycle, 2.0, true);
    
    L4D2Direct_DoAnimationEvent(client, ANIM_EVENT_BACK_TO_IDLE);
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

bool: IsEntityInSaferoom(entity, bool:isPlayer=false, bool:endSaferoom=true)
{
    // is it held by someone (we're only calling this at round end by default?
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

// get logical team (that's survivor), taking CMT into consideration
GetCurrentLogicalTeam()
{
    // this is corrected if CMT has mixed the teams up to preserve playing order
    if ( g_bCMTSwapped ) {
        return !GameRules_GetProp("m_bAreTeamsFlipped");
    } else {
        return GameRules_GetProp("m_bAreTeamsFlipped");
    }
}