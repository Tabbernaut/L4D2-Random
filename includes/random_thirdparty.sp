/*
    Just for my own mental health: separated all the copied third party code
    to this file.
*/

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

#define VOMIT_PARTICLE          "boomer_vomit"


/*  Drop weapons/items slots
    ------------------------ */
bool: SUPPORT_DropItem(client, bool:dropCurrent, count, dropSlot = 0, bool:throwItem = false)
{
    new dropCount = 0;
    
    if (dropCurrent || dropSlot)
    {
        if (dropCurrent) {
            dropSlot = SUPPORT_GetCurrentWeaponSlot(client);
        } else {
            // 1-5 => actual slot index
            dropSlot--;
        }
        if (dropSlot >= 0)
        {
            if ( g_iSpecialEvent == EVT_MEDIC && g_iSpecialEventRole == client && (dropSlot == PLAYER_SLOT_KIT || dropSlot == PLAYER_SLOT_PILL) ) {
                PrintToChat(client, "\x01[\x05r\x01] A medic cannot drop health items.");
            }
            else if ( g_iSpecialEvent != EVT_GUNSWAP || dropSlot != PLAYER_SLOT_PRIMARY ) {
                if ( SUPPORT_DropItemSlot(client, dropSlot, throwItem) ) { dropCount++; } 
            }
            
        }
    }
    
    if (count == 0 && !dropCurrent && !dropSlot) { count = 1; }
    
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
            if (    (g_iSpecialEvent != EVT_GUNSWAP || slot[r] != PLAYER_SLOT_PRIMARY)
                &&  (g_iSpecialEvent != EVT_MEDIC || (slot[r] != PLAYER_SLOT_KIT && slot[r] != PLAYER_SLOT_PILL) )
            ) {
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
                ammo = GetEntData(client, ammoOffset+(ASSAULT_RIFLE_OFFSET_IAMMO));
                SetEntData(client, ammoOffset+(ASSAULT_RIFLE_OFFSET_IAMMO), 0);
            }
            else if (StrEqual(weapon, "weapon_smg") || StrEqual(weapon, "weapon_smg_silenced") || StrEqual(weapon, "weapon_smg_mp5"))
            {
                ammo = GetEntData(client, ammoOffset+(SMG_OFFSET_IAMMO));
                SetEntData(client, ammoOffset+(SMG_OFFSET_IAMMO), 0);
            }
            else if (StrEqual(weapon, "weapon_pumpshotgun") || StrEqual(weapon, "weapon_shotgun_chrome"))
            {
                ammo = GetEntData(client, ammoOffset+(SHOTGUN_OFFSET_IAMMO));
                SetEntData(client, ammoOffset+(SHOTGUN_OFFSET_IAMMO), 0);
            }
            else if (StrEqual(weapon, "weapon_autoshotgun") || StrEqual(weapon, "weapon_shotgun_spas"))
            {
                ammo = GetEntData(client, ammoOffset+(AUTO_SHOTGUN_OFFSET_IAMMO));
                SetEntData(client, ammoOffset+(AUTO_SHOTGUN_OFFSET_IAMMO), 0);
            }
            else if (StrEqual(weapon, "weapon_hunting_rifle"))
            {
                ammo = GetEntData(client, ammoOffset+(SNIPER_OFFSET_IAMMO));
                SetEntData(client, ammoOffset+(SNIPER_OFFSET_IAMMO), 0);
            }
            else if (StrEqual(weapon, "weapon_sniper_scout") || StrEqual(weapon, "weapon_sniper_military") || StrEqual(weapon, "weapon_sniper_awp"))
            {
                ammo = GetEntData(client, ammoOffset+(MILITARY_SNIPER_OFFSET_IAMMO));
                SetEntData(client, ammoOffset+(MILITARY_SNIPER_OFFSET_IAMMO), 0);
            }
            else if (StrEqual(weapon, "weapon_grenade_launcher"))
            {
                ammo = GetEntData(client, ammoOffset+(GRENADE_LAUNCHER_OFFSET_IAMMO));
                SetEntData(client, ammoOffset+(GRENADE_LAUNCHER_OFFSET_IAMMO), 0);
            }
            else if (StrEqual(weapon, "weapon_rifle_m60"))
            {
                ammo = -1;
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
            else if (StrEqual(weapon, "weapon_pistol_magnum"))
            {
                clip = GetEntProp(oldweapon, Prop_Send, "m_iClip1");
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
            if (ammo != -1) {
                SetEntProp(index, Prop_Send, "m_iExtraPrimaryAmmo", ammo);
            }
            SetEntProp(index, Prop_Send, "m_iClip1", clip);
            SetEntProp(index, Prop_Send, "m_upgradeBitVec", upgrade);
            SetEntProp(index, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", upammo);
        }
        else if (slot == 1)
        {
            if (StrEqual(weapon, "weapon_chainsaw") || StrEqual(weapon, "weapon_pistol") || StrEqual(weapon, "weapon_pistol_magnum"))
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
    
    new itemPickupPenalty: itemCheck;
    if (GetTrieValue(g_hTriePenaltyItems, weapon, itemCheck))
    {
        switch (itemCheck)
        {
            case ITEM_PICKUP_PENALTY_PRIMARY_T1, ITEM_PICKUP_PENALTY_PRIMARY_T2, ITEM_PICKUP_PENALTY_PRIMARY_SNIPER, ITEM_PICKUP_PENALTY_PRIMARY_T3: { slot = PLAYER_SLOT_PRIMARY; }
            case ITEM_PICKUP_PENALTY_SAW, ITEM_PICKUP_PENALTY_MELEE, ITEM_PICKUP_PENALTY_MAGNUM, ITEM_PICKUP_PENALTY_PISTOL: { slot = PLAYER_SLOT_SECONDARY; }
        }
    }
    else
    {
        if (StrEqual(weapon, "weapon_pipe_bomb") || StrEqual(weapon, "weapon_molotov") || StrEqual(weapon, "weapon_vomitjar")) {  slot = PLAYER_SLOT_THROWABLE; }
        else if (StrEqual(weapon, "weapon_first_aid_kit") || StrEqual(weapon, "weapon_defibrillator") || StrEqual(weapon, "weapon_upgradepack_explosive") || StrEqual(weapon, "weapon_upgradepack_incendiary")) { slot = PLAYER_SLOT_KIT; }
        else if (StrEqual(weapon, "weapon_pain_pills") || StrEqual(weapon, "weapon_adrenaline")) { slot = PLAYER_SLOT_PILL; }
    }
 
    if (slot < 0)
    {
        for (new i=0; i < 5; i++) {
            new s = GetPlayerWeaponSlot(client, i);
            if ( s > 0) {
                slot=i;
                break;
            }
        }
    }
    return slot;
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
            //PrintDebug(3, "Unblinding for item %i", i);
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
    
    PrintDebug(2, "[rand] Blinding for %i items...", g_iCreatedEntities);
    
    // use list of created items to handle only the entities we need
    for (new i = 0; i < g_iCreatedEntities; i++)
    {
        SDKHook(g_iArCreatedEntities[i], SDKHook_SetTransmit, OnTransmit);
        bhTemp[iEntity] = g_iArCreatedEntities[i];
        bhTemp[hasBeenSeen] = false;
        //PrintDebug(3, "Blinding for item %i", bhTemp[0]);
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
        PrintDebug(1, "[rand] BlindEntCheck: not a valid entity: %i (client: %N)", entity, client);
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


/*  Alarmed cars
    -------------------------- */

#define ALARMCAR_MODEL      "models/props_vehicles/cara_95sedan.mdl"
#define ALARMCAR_GLASS      "models/props_vehicles/cara_95sedan_glass_alarm.mdl"
#define ALARMCAR_GLASS_OFF  "models/props_vehicles/cara_95sedan_glass.mdl"
#define COLOR_REDCAR        "222 92 86"
#define COLOR_REDLIGHT      "255 13 19"
#define COLOR_WHITELIGHT    "252 243 226"
#define COLOR_YELLOWLIGHT   "224 162 44"
#define DISTANCE_BACK       103.0
#define DISTANCE_FRONT      101.0
#define DISTANCE_SIDE       27.0
#define DISTANCE_SIDETURN   34.0
#define DISTANCE_UPBACK     31.0
#define DISTANCE_UPFRONT    29.0

public EnableAllCarAlarms() {
    // find all alarmed cars and enable them
    for (new x = 0; x < g_iStoredHittables; x++) {
        if ( g_strArHittableStorage[x][hitIsAlarmed] && IsValidEntity(g_strArHittableStorage[x][hitNumber]) ) {
            AcceptEntityInput( g_strArHittableStorage[x][hitNumber], "Enable");
        }
    }
}
public DisableAllCarAlarms() {
    // find all alarmed cars and disable them
    for (new x = 0; x < g_iStoredHittables; x++) {
        if ( g_strArHittableStorage[x][hitIsAlarmed] && IsValidEntity(g_strArHittableStorage[x][hitNumber]) ) {
            AcceptEntityInput( g_strArHittableStorage[x][hitNumber], "Disable");
            // also hide glass if still in on position?
            DisableAlarmCarEffects(x);
        }
    }
}

SpawnAlarmCar(index) {
    
    // init
    new carEntity, glassEntity, glassOffEntity, alarmTimer, chirpSound, alarmSound;
    new carLights[6], gameEventInfo;
    
    new Float: itemOrigin[3], Float: itemAngles[3];
    itemOrigin[0] = g_strArHittableStorage[index][hitOrigin_a];
    itemOrigin[1] = g_strArHittableStorage[index][hitOrigin_b];
    itemOrigin[2] = g_strArHittableStorage[index][hitOrigin_c];
    itemAngles[0] = g_strArHittableStorage[index][hitAngles_a];
    itemAngles[1] = g_strArHittableStorage[index][hitAngles_b];
    itemAngles[2] = g_strArHittableStorage[index][hitAngles_c];
    
    // move it up a bit to prevent clipping in floor
    itemOrigin[2] += 20.0;
    
    decl String:carName[64], String:glassName[64], String:glassOffName[64], String:alarmTimerName[64];
    decl String:chirpSoundName[64], String:alarmSoundName[64], String:carLightsName[64];
    decl String:carHeadLightsName[64], String:tempString[256];
    
    Format(carName, 64, "sm_alarmcar_car%d", index+1);
    Format(glassName, 64, "sm_alarmcar_glass%d", index+1);
    Format(glassOffName, 64, "sm_alarmcar_glassoff%d", index+1);
    Format(alarmTimerName, 64, "sm_alarmcar_alarmtimer%d", index+1);
    Format(chirpSoundName, 64, "sm_alarmcar_chirpsound%d", index+1);
    Format(alarmSoundName, 64, "sm_alarmcar_alarmsound%d", index+1);
    Format(carLightsName, 64, "sm_alarmcar_carlights%d", index+1);
    Format(carHeadLightsName, 64, "sm_alarmcar_carheadlights%d", index+1);
    
    // create car model
    carEntity = CreateAlarmCar();
    if (carEntity == -1) {
        return;
    }
    
    // update entity number in array
    g_strArHittableStorage[index][hitNumber] = carEntity;
    g_strArHittableStorage[index][hitGlassEntity] = -1;
    g_strArHittableStorage[index][hitGlassOffEntity] = -1;
    g_strArHittableStorage[index][hitLightEntity_a] = -1;
    g_strArHittableStorage[index][hitLightEntity_b] = -1;
    g_strArHittableStorage[index][hitLightEntity_c] = -1;
    g_strArHittableStorage[index][hitLightEntity_d] = -1;
    g_strArHittableStorage[index][hitLightEntity_e] = -1;
    g_strArHittableStorage[index][hitLightEntity_f] = -1;
    
    DispatchKeyValue(carEntity, "targetname", carName);
    DispatchKeyValue(carEntity, "model", ALARMCAR_MODEL);
    DispatchKeyValue(carEntity, "renderamt", "255");    
    
    if (g_strArHittableStorage[index][hitIsColored])
    {
        decl String: tmpStr[24];
        Format(tmpStr, sizeof(tmpStr), "%i %i %i", g_strArHittableStorage[index][hitColor_r], g_strArHittableStorage[index][hitColor_g], g_strArHittableStorage[index][hitColor_b]);
        DispatchKeyValue(carEntity, "rendercolor", tmpStr);
    }
    
    // try to disable this keyvalue set.. and then add it only after
    // the round goes live?
    Format(tempString, 256, "%s,Enable,,0,-1", alarmTimerName);
    DispatchKeyValue(carEntity, "OnCarAlarmStart", tempString);
    Format(tempString, 256, "%s,Disable,,0,-1", alarmTimerName);
    DispatchKeyValue(carEntity, "OnCarAlarmEnd", tempString);
    Format(tempString, 256, "%s,PlaySound,,0,-1", alarmSoundName);
    DispatchKeyValue(carEntity, "OnCarAlarmStart", tempString);
    Format(tempString, 256, "%s,StopSound,,0,-1", alarmSoundName);
    DispatchKeyValue(carEntity, "OnCarAlarmEnd", tempString);
    Format(tempString, 256, "%s,PlaySound,,0.2,-1", chirpSoundName);
    DispatchKeyValue(carEntity, "OnCarAlarmChirpStart", tempString);
    Format(tempString, 256, "%s,HideSprite,,0.7,-1", carLightsName);
    DispatchKeyValue(carEntity, "OnCarAlarmChirpEnd", tempString);
    Format(tempString, 256, "%s,ShowSprite,,0.2,-1", carLightsName);
    DispatchKeyValue(carEntity, "OnCarAlarmChirpStart", tempString);
    Format(tempString, 256, "%s,Disable,,0,-1", glassName);
    DispatchKeyValue(carEntity, "OnCarAlarmStart", tempString);
    Format(tempString, 256, "%s,Enable,,0,-1", glassOffName);
    DispatchKeyValue(carEntity, "OnCarAlarmStart", tempString);
    
    // only enable car alarms after the survivors leave the saferoom
    DispatchKeyValue(carEntity, "StartDisabled", "1");
    
    
    // this works for tank-car interaction
    Format(tempString, 256, "%s,Kill,,0,-1", carLightsName);
    DispatchKeyValue(carEntity, "OnHitByTank", tempString);
    Format(tempString, 256, "%s,Kill,,0,-1", glassName);
    DispatchKeyValue(carEntity, "OnHitByTank", tempString);
    
    TeleportEntity(carEntity, itemOrigin, itemAngles, NULL_VECTOR);
    DispatchSpawn(carEntity);
    ActivateEntity(carEntity);
    SetEntityMoveType(carEntity, MOVETYPE_NONE);
    
    // create glass model
    glassEntity = CreateCarGlass(ALARMCAR_GLASS, glassName, itemOrigin, itemAngles, carName);
    if (glassEntity == -1) {
        KillEntity(carEntity);
        PrintDebug(0, "[rand] car alarm problem: could not create car glass entity");
        return;
    }

    // create off glass model 
    glassOffEntity = CreateCarGlass(ALARMCAR_GLASS_OFF, glassOffName, itemOrigin, itemAngles, carName);
    if (glassOffEntity == -1) {
        KillEntity(carEntity);
        PrintDebug(0, "[rand] car alarm problem: could not create car glass entity");
        return;
    }
    
    // update entity number in array
    g_strArHittableStorage[index][hitGlassEntity] = glassEntity;
    g_strArHittableStorage[index][hitGlassOffEntity] = glassOffEntity;
    
    // create alarm timer`
    alarmTimer = CreateEntityByName("logic_timer");    
    if (alarmTimer == -1) {
        KillEntity(carEntity);
        PrintDebug(0, "[rand] car alarm problem: could not create logic timer entity!");
        return;
    }    
    
    DispatchKeyValue(alarmTimer, "UseRandomTime", "0");
    DispatchKeyValue(alarmTimer, "targetname", alarmTimerName);
    DispatchKeyValue(alarmTimer, "StartDisabled", "1");
    DispatchKeyValue(alarmTimer, "spawnflags", "0");
    DispatchKeyValue(alarmTimer, "RefireTime", ".75");
    
    Format(tempString, 256, "%s,ShowSprite,,0,-1", carLightsName);
    DispatchKeyValue(alarmTimer, "OnTimer", tempString);
    Format(tempString, 256, "%s,HideSprite,,0.5,-1", carLightsName);
    DispatchKeyValue(alarmTimer, "OnTimer", tempString);
    Format(tempString, 256, "%s,HideSprite,,0.5,-1", carLightsName);
    DispatchKeyValue(alarmTimer, "OnTimer", tempString);
    Format(tempString, 256, "%s,ShowSprite,,0,-1", carLightsName);
    DispatchKeyValue(alarmTimer, "OnTimer", tempString);
    
    Format(tempString, 256, "%s,LightOff,,0.5,-1", carHeadLightsName);
    DispatchKeyValue(alarmTimer, "OnTimer", tempString);
    Format(tempString, 256, "%s,LightOn,,0,-1", carHeadLightsName);
    DispatchKeyValue(alarmTimer, "OnTimer", tempString);    

    TeleportEntity(alarmTimer, itemOrigin, NULL_VECTOR, NULL_VECTOR);
    DispatchSpawn(alarmTimer);

    // create game event info
    gameEventInfo = CreateGameEvent(itemOrigin);
    if (gameEventInfo == -1) {
        KillEntity(carEntity);
        KillEntity(alarmTimer);
        
        PrintDebug(0, "[rand] car alarm problem: could not create game event info entity!");
        return;
    }    
    
    // create sounds
    new Float:soundsPosition[3];
    CopyVector(itemOrigin, soundsPosition);
    soundsPosition[2] += 80.0;
    
    chirpSound = CreateCarSound(soundsPosition, chirpSoundName, carName, "Car.Alarm.Chirp2", "48");
    alarmSound = CreateCarSound(soundsPosition, alarmSoundName, carName, "Car.Alarm", "16");
    
    // create lights
    new Float:distances[9] = {DISTANCE_FRONT, DISTANCE_SIDETURN, DISTANCE_UPFRONT, DISTANCE_BACK, DISTANCE_SIDE, DISTANCE_UPBACK, DISTANCE_FRONT, DISTANCE_SIDE, DISTANCE_UPFRONT};
    CreateLights(index, carLights, itemOrigin, itemAngles, distances, carLightsName, carHeadLightsName, carName);

    // check entities
    decl String:entityName[16];
    new bool:somethingWrong;
    
    if (chirpSound == -1 || alarmSound == -1) {
        entityName = "sound";
        somethingWrong = true;    
    }
    else {
        for (new i = 0; i < 6; i++) {
            if (carLights[i] == -1) {
                entityName = "lights";
                somethingWrong = true;
                break;
            }
        }
    }        
    
    if (somethingWrong) {
        // delete everything
        KillEntity(carEntity);
        KillEntity(alarmTimer);    
        KillEntity(gameEventInfo);    
        
        PrintDebug(0, "[rand] car alarm problem: could not create %s entity!", entityName);
        return;
    }
    
    /*
        don't hook: leave alarms enabled on cars hitting other cars
        // hook car entity for damage, so we can destroy its lights (when hit by another hittable)
        //SDKHook(carEntity, SDKHook_OnTakeDamage, OnTakeDamage_AlarmedCar);
    */
    
    // remember car entity
    g_strArHittableStorage[index][hitNumber] = carEntity;
    
    // michael bay event: if it's something that might explode, hook it for damage checks
    if ( g_iSpecialEvent == EVT_BAY ) {
        g_strArHittableStorage[index][hitDamageRcvd] = 0;
        SDKHook( carEntity, SDKHook_OnTakeDamage, OnTakeDamage_Hittable );
    }
    
    // allow car moving
    CreateTimer(0.2, Timer_CarMove, carEntity, TIMER_FLAG_NO_MAPCHANGE);
}
CreateAlarmCar() {
    new carEntity = CreateEntityByName("prop_car_alarm");
    if (carEntity == -1) return -1;
    
    DispatchKeyValue(carEntity, "spawnflags", "256");
    DispatchKeyValue(carEntity, "fadescale", "1");
    DispatchKeyValue(carEntity, "fademindist", "-1"); 
    DispatchKeyValue(carEntity, "inertiaScale", "1.0"); 
    DispatchKeyValue(carEntity, "physdamagescale", "0.1"); 
    DispatchKeyValue(carEntity, "BreakableType", "0");
    DispatchKeyValue(carEntity, "forcetoenablemotion", "0");
    DispatchKeyValue(carEntity, "massScale", "0");
    DispatchKeyValue(carEntity, "PerformanceMode", "0");
    DispatchKeyValue(carEntity, "nodamageforces", "0");
    
    DispatchKeyValue(carEntity, "skin", "0");
    DispatchKeyValue(carEntity, "shadowcastdist", "0");
    DispatchKeyValue(carEntity, "rendermode", "0");
    DispatchKeyValue(carEntity, "renderfx", "0");
    DispatchKeyValue(carEntity, "pressuredelay", "0");
    DispatchKeyValue(carEntity, "minhealthdmg", "0");
    DispatchKeyValue(carEntity, "mindxlevel", "0");
    DispatchKeyValue(carEntity, "maxdxlevel", "0");
    DispatchKeyValue(carEntity, "fademaxdist", "0");
    DispatchKeyValue(carEntity, "ExplodeRadius", "0");
    DispatchKeyValue(carEntity, "ExplodeDamage", "0");
    DispatchKeyValue(carEntity, "disableshadows", "0");
    DispatchKeyValue(carEntity, "disablereceiveshadows", "0");
    DispatchKeyValue(carEntity, "Damagetype", "0");
    DispatchKeyValue(carEntity, "damagetoenablemotion", "0");
    DispatchKeyValue(carEntity, "body", "0");
    
    return carEntity;
}

CreateCarGlass(const String:modelName[], const String:targetName[], const Float:position[3], const Float:angle[3], const String:carName[]) {
    new glassEntity = CreateEntityByName("prop_car_glass");
    if (glassEntity == -1) return -1;
    
    DispatchKeyValue(glassEntity, "model", modelName);
    DispatchKeyValue(glassEntity, "targetname", targetName);
    
    DispatchKeyValue(glassEntity, "spawnflags", "0");    
    DispatchKeyValue(glassEntity, "solid", "6");
    DispatchKeyValue(glassEntity, "MinAnimTime", "5");
    DispatchKeyValue(glassEntity, "MaxAnimTime", "10");
    DispatchKeyValue(glassEntity, "fadescale", "1");
    DispatchKeyValue(glassEntity, "fademindist", "-1");
    
    // teleport and spawn
    TeleportEntity(glassEntity, position, angle, NULL_VECTOR);
    DispatchSpawn(glassEntity);
    ActivateEntity(glassEntity);
    
    // parent to car
    SetVariantString(carName);
    AcceptEntityInput(glassEntity, "SetParent", glassEntity, glassEntity, 0);    
    
    return glassEntity;
}

CreateGameEvent(const Float:position[3]) {
    new gameEventInfo = CreateEntityByName("info_game_event_proxy");
    if (gameEventInfo == -1) return -1;
    
    DispatchKeyValue(gameEventInfo, "targetname", "caralarm_game_event");
    DispatchKeyValue(gameEventInfo, "spawnflags", "1");
    DispatchKeyValue(gameEventInfo, "range", "100");
    DispatchKeyValue(gameEventInfo, "event_name", "explain_disturbance");
    
    TeleportEntity(gameEventInfo, position, NULL_VECTOR, NULL_VECTOR);
    DispatchSpawn(gameEventInfo);    
    ActivateEntity(gameEventInfo);
    
    return gameEventInfo;
}

CreateCarSound(const Float:entityPosition[3], const String:targetName[], const String:sourceName[], const String:messageName[], const String:spawnFlags[]) {
    new soundEntity = CreateEntityByName("ambient_generic");
    if (soundEntity == -1) {
        return -1;
    }    
    
    DispatchKeyValue(soundEntity, "targetname", targetName);
    DispatchKeyValue(soundEntity, "SourceEntityName", sourceName);
    DispatchKeyValue(soundEntity, "message", messageName);
    DispatchKeyValue(soundEntity, "radius", "4000");
    DispatchKeyValue(soundEntity, "pitchstart", "100");
    DispatchKeyValue(soundEntity, "pitch", "100");
    DispatchKeyValue(soundEntity, "health", "10");
    DispatchKeyValue(soundEntity, "spawnflags", spawnFlags);    
    DispatchKeyValue(soundEntity, "volstart", "0");
    DispatchKeyValue(soundEntity, "spinup", "0");
    DispatchKeyValue(soundEntity, "spindown", "0");
    DispatchKeyValue(soundEntity, "preset", "0");
    DispatchKeyValue(soundEntity, "lfotype", "0");
    DispatchKeyValue(soundEntity, "lforate", "0");
    DispatchKeyValue(soundEntity, "lfomodvol", "0");
    DispatchKeyValue(soundEntity, "lfomodpitch", "0");
    DispatchKeyValue(soundEntity, "fadeoutsecs", "0");
    DispatchKeyValue(soundEntity, "fadeinsecs", "0");
    DispatchKeyValue(soundEntity, "cspinup", "0");
    
    TeleportEntity(soundEntity, entityPosition, NULL_VECTOR, NULL_VECTOR);
    DispatchSpawn(soundEntity);
    ActivateEntity(soundEntity);
    
    SetVariantString(sourceName);
    AcceptEntityInput(soundEntity, "SetParent", soundEntity, soundEntity, 0);
    
    return soundEntity;
}

CreateLights(index, carLights[6], const Float:position[3], const Float:angle[3], const Float:distance[9], const String:lightName[], const String:headLightName[], const String:carName[]) {
    decl Float:lightPosition[3], Float:lightDistance[3];
    
    CopyVector(position, lightPosition);
    lightDistance[0] = distance[0];
    lightDistance[1] = distance[1]*-1.0;
    lightDistance[2] = distance[2];
    MoveVectorPosition3D(lightPosition, angle, lightDistance); // front left
    carLights[0] = CreateCarLight(lightPosition, lightName, carName, COLOR_YELLOWLIGHT);
    
    CopyVector(position, lightPosition);
    lightDistance[1] = distance[1];
    MoveVectorPosition3D(lightPosition, angle, lightDistance); // front right
    carLights[1] = CreateCarLight(lightPosition, lightName, carName, COLOR_YELLOWLIGHT);
    
    CopyVector(position, lightPosition);
    lightDistance[0] = distance[3]*-1.0;
    lightDistance[1] = distance[4]*-1.0;
    lightDistance[2] = distance[5];
    MoveVectorPosition3D(lightPosition, angle, lightDistance); // back left
    carLights[2] = CreateCarLight(lightPosition, lightName, carName, COLOR_REDLIGHT);
    
    CopyVector(position, lightPosition);
    lightDistance[1] = distance[4];
    MoveVectorPosition3D(lightPosition, angle, lightDistance); // back right
    carLights[3] = CreateCarLight(lightPosition, lightName, carName, COLOR_REDLIGHT);
    
    // create head lights
    CopyVector(position, lightPosition);
    lightDistance[0] = distance[6];
    lightDistance[1] = distance[7]*-1.0;
    lightDistance[2] = distance[8];
    MoveVectorPosition3D(lightPosition, angle, lightDistance); // front left
    carLights[4] = CreateCarHeadLight(lightPosition, angle, headLightName, carName);    

    CopyVector(position, lightPosition);
    lightDistance[1] = distance[7];
    MoveVectorPosition3D(lightPosition, angle, lightDistance); // front right
    carLights[5] = CreateCarHeadLight(lightPosition, angle, headLightName, carName);
    
    // update entity numbers in array
    g_strArHittableStorage[index][hitLightEntity_a] = carLights[0];
    g_strArHittableStorage[index][hitLightEntity_b] = carLights[1];
    g_strArHittableStorage[index][hitLightEntity_c] = carLights[2];
    g_strArHittableStorage[index][hitLightEntity_d] = carLights[3];
    g_strArHittableStorage[index][hitLightEntity_e] = carLights[4];
    g_strArHittableStorage[index][hitLightEntity_f] = carLights[5];
}
CreateCarLight(const Float:entityPosition[3], const String:targetName[], const String:parentName[], const String:renderColor[]) {
    new lightEntity = CreateEntityByName("env_sprite");
    if (lightEntity == -1) {
        return -1;
    }    
    
    DispatchKeyValue(lightEntity, "targetname", targetName);
    DispatchKeyValue(lightEntity, "spawnflags", "0");
    DispatchKeyValue(lightEntity, "scale", ".5");
    DispatchKeyValue(lightEntity, "rendermode", "9");
    DispatchKeyValue(lightEntity, "renderfx", "0");
    DispatchKeyValue(lightEntity, "rendercolor", renderColor);
    DispatchKeyValue(lightEntity, "renderamt", "255");
    DispatchKeyValue(lightEntity, "model", "sprites/glow.vmt");
    DispatchKeyValue(lightEntity, "HDRColorScale", "0.7");
    DispatchKeyValue(lightEntity, "GlowProxySize", "5");
    DispatchKeyValue(lightEntity, "framerate", "10.0");
    DispatchKeyValue(lightEntity, "fadescale", "1");
    DispatchKeyValue(lightEntity, "fademindist", "-1");
    DispatchKeyValue(lightEntity, "disablereceiveshadows", "0");
    
    TeleportEntity(lightEntity, entityPosition, NULL_VECTOR, NULL_VECTOR);
    DispatchSpawn(lightEntity);
    ActivateEntity(lightEntity);
    
    SetVariantString(parentName);
    AcceptEntityInput(lightEntity, "SetParent", lightEntity, lightEntity, 0);
    
    return lightEntity;
}

CreateCarHeadLight(const Float:entityPosition[3], const Float:entityAngles[3], const String:targetName[], const String:parentName[]) {
    new lightEntity = CreateEntityByName("beam_spotlight");
    if (lightEntity == -1) {
        return -1;
    }    
    
    DispatchKeyValue(lightEntity, "targetname", targetName);
    DispatchKeyValue(lightEntity, "spawnflags", "2");
    DispatchKeyValue(lightEntity, "spotlightwidth", "32");
    DispatchKeyValue(lightEntity, "spotlightlength", "256");
    DispatchKeyValue(lightEntity, "rendermode", "5");
    DispatchKeyValue(lightEntity, "rendercolor", COLOR_WHITELIGHT);
    DispatchKeyValue(lightEntity, "renderamt", "150");
    DispatchKeyValue(lightEntity, "maxspeed", "100");
    DispatchKeyValue(lightEntity, "HDRColorScale", ".5");
    DispatchKeyValue(lightEntity, "fadescale", "1");
    DispatchKeyValue(lightEntity, "fademindist", "-1");
    
    TeleportEntity(lightEntity, entityPosition, entityAngles, NULL_VECTOR);
    DispatchSpawn(lightEntity);
    ActivateEntity(lightEntity);
    
    SetVariantString(parentName);
    AcceptEntityInput(lightEntity, "SetParent", lightEntity, lightEntity, 0);
    
    return lightEntity;
}

public Action:Timer_CarMove(Handle:timer, any:carEntity) {
    if (IsValidEntity(carEntity)) SetEntityMoveType(carEntity, MOVETYPE_VPHYSICS);
}

stock KillEntity(const entity) {
    if (entity < 1) return;
    if (!IsValidEntity(entity)) return;
    if (AcceptEntityInput(entity, "Kill")) return;
    
    RemoveEdict(entity);
}

MoveVectorPosition3D(Float:position[3], const Float:constAngles[3], const Float:constDistance[3]) {
    decl Float:angle[3], Float:dirFw[3], Float:dirRi[3], Float:dirUp[3], Float:distance[3];
    CopyVector(constDistance, distance);
    
    angle[0] = DegToRad(constAngles[0]);
    angle[1] = DegToRad(constAngles[1]);
    angle[2] = DegToRad(constAngles[2]);    
    
    // roll (rotation over x)
    dirFw[0] = 1.0;
    dirFw[1] = 0.0;
    dirFw[2] = 0.0;
    dirRi[0] = 0.0;
    dirRi[1] = Cosine(angle[2]);
    dirRi[2] = Sine(angle[2])*-1;
    dirUp[0] = 0.0;
    dirUp[1] = Sine(angle[2]);
    dirUp[2] = Cosine(angle[2]);
    MatrixMulti(dirFw, dirRi, dirUp, distance);
    
    // pitch (rotation over y)
    dirFw[0] = Cosine(angle[0]);
    dirFw[1] = 0.0;
    dirFw[2] = Sine(angle[0]);
    dirRi[0] = 0.0;
    dirRi[1] = 1.0;
    dirRi[2] = 0.0;
    dirUp[0] = Sine(angle[0])*-1;
    dirUp[1] = 0.0;
    dirUp[2] = Cosine(angle[0]);
    MatrixMulti(dirFw, dirRi, dirUp, distance);

    // yaw (rotation over z)
    dirFw[0] = Cosine(angle[1]);
    dirFw[1] = Sine(angle[1])*-1;
    dirFw[2] = 0.0;
    dirRi[0] = Sine(angle[1]);
    dirRi[1] = Cosine(angle[1]);
    dirRi[2] = 0.0;
    dirUp[0] = 0.0;
    dirUp[1] = 0.0;
    dirUp[2] = 1.0;
    MatrixMulti(dirFw, dirRi, dirUp, distance);
    
    // addition
    for (new i = 0; i < 3; i++) position[i] += distance[i];
}

MatrixMulti(const Float:matA[3], const Float:matB[3], const Float:matC[3], Float:vec[3]) {
    new Float:res[3];
    for (new i = 0; i < 3; i++) res[0] += matA[i]*vec[i];
    for (new i = 0; i < 3; i++) res[1] += matB[i]*vec[i];
    for (new i = 0; i < 3; i++) res[2] += matC[i]*vec[i];    
    CopyVector(res, vec);
}

CopyVector(const Float:original[3], Float:copy[3]) {
    for (new i = 0; i < 3; i++) copy[i] = original[i];
}


DisableAlarmCarEffects(index) {
    g_strArHittableStorage[index][hitAlarmOff] = true;
    if (IsValidEntity(g_strArHittableStorage[index][hitGlassEntity]))   { AcceptEntityInput(g_strArHittableStorage[index][hitGlassEntity], "Kill"); }
    if (IsValidEntity(g_strArHittableStorage[index][hitLightEntity_a])) { AcceptEntityInput(g_strArHittableStorage[index][hitLightEntity_a], "Kill"); }
    if (IsValidEntity(g_strArHittableStorage[index][hitLightEntity_b])) { AcceptEntityInput(g_strArHittableStorage[index][hitLightEntity_b], "Kill"); }
    if (IsValidEntity(g_strArHittableStorage[index][hitLightEntity_c])) { AcceptEntityInput(g_strArHittableStorage[index][hitLightEntity_c], "Kill"); }
    if (IsValidEntity(g_strArHittableStorage[index][hitLightEntity_d])) { AcceptEntityInput(g_strArHittableStorage[index][hitLightEntity_d], "Kill"); }
    if (IsValidEntity(g_strArHittableStorage[index][hitLightEntity_e])) { AcceptEntityInput(g_strArHittableStorage[index][hitLightEntity_e], "Kill"); }
    if (IsValidEntity(g_strArHittableStorage[index][hitLightEntity_f])) { AcceptEntityInput(g_strArHittableStorage[index][hitLightEntity_f], "Kill"); }
}

/*  L4D2 Hats plugin
    -------------------------- */
RemoveHat(client) {
    new entity = g_iHatIndex[client];
    g_iHatIndex[client] = 0;
    if( IsValidEntRef(entity) ) { AcceptEntityInput(entity, "kill"); }
}
CreateHat(client, index = -1) {
    if( IsValidEntRef(g_iHatIndex[client]) == true || IsValidClient(client) == false ) { return false; }
    
    g_iType[client] = index + 1;

    new Float: vPos[3], Float: vAng[3], Float: fScale;
    
    switch (index)
    {
        case HAT_BABY: {
            // traffic cone
            //vPos[0] = -3.0; vPos[1] = 0.0; vPos[2] = 1.0;
            //vAng[0] = 0.0; vAng[1] = 60.0; vAng[2] = -40.0;
            // teddy bear
            vPos[0] = -10.0; vPos[1] = 0.0; vPos[2] = 8.0;
            vAng[0] = -10.0; vAng[1] = 0.0; vAng[2] = 0.0;
        }
        case HAT_KEYMASTER: {
            // construction light
            vPos[0] = -7.0; vPos[1] = 0.0; vPos[2] = 9.0;
            vAng[0] = -200.0; vAng[1] = 0.0; vAng[2] = 0.0;
        }
        case HAT_MEDIC: {
            vPos[0] = -4.0; vPos[1] = -2.75; vPos[2] = 10.0;
            vAng[0] = -1.0; vAng[1] = 180.0; vAng[2] = 90.0;
            fScale = 0.75;
        }
        case HAT_BOOMFLU: {
            vPos[0] = -3.0; vPos[1] = 0.0; vPos[2] = 10.0;
        }
    }
    
    new entity = CreateEntityByName("prop_dynamic_override");
    if (entity != -1)
    {
        SetEntityModel(entity, g_csHatModels[index]);
        /*
        DispatchKeyValue(entity, "glowcolor", "255 128 0");
        DispatchKeyValue(entity, "glowstate", "3");
        DispatchKeyValue(entity, "glowrange", "32000");
        */
        /*
        if (index == HAT_BOOMFLU)
        {
            // color / transparency
            SetEntityRenderColor(entity, 10, 230, 50, 210);
            SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
            //SetEntityRenderFx(entity, RENDERFX_GLOWSHELL);
        }
        */
        
        DispatchSpawn(entity);
        if (fScale != 0.0) {
            SetEntPropFloat(entity, Prop_Send, "m_flModelScale", fScale);
        }
        
        // this doesn't work (unless you force a different glowtype)
        //SetEntProp(entity, Prop_Send, "m_glowColorOverride", 0xFFFFFF);

        SetVariantString("!activator");
        AcceptEntityInput(entity, "SetParent", client);
        SetVariantString("eyes");
        AcceptEntityInput(entity, "SetParentAttachment");
        TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
        SetEntProp(entity, Prop_Data, "m_iEFlags", 0);

        /*if( g_iCvarOpaq )
        {
            SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
            SetEntityRenderColor(entity, 255, 255, 255, g_iCvarOpaq);
        }*/

        //g_iSelected[client] = index;
        g_iHatIndex[client] = EntIndexToEntRef(entity);
        
        SDKHook(entity, SDKHook_SetTransmit, Hat_Hook_SetTransmit);

        return true;
    }

    return false;
}

HatsRemoveAll() {   
    for (new i=1; i <= MaxClients; i++)
    {
        RemoveHat(i);
    }
}

bool:IsValidClient(client) {
    if( client && IsClientAndInGame(client) && GetClientTeam(client) == TEAM_SURVIVOR && IsPlayerAlive(client) )
        return true;
    return false;
}
bool:IsValidEntRef(entity) {
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}





/* car flying */
public LaunchCar(car)
{
	decl Float:vel[3];
	GetEntPropVector(car, Prop_Data, "m_vecVelocity", vel);
	vel[0]+= GetRandomFloat( 75.0, 400.0 );
	vel[1]+= GetRandomFloat( 75.0, 400.0 );
	vel[2]+= GetRandomFloat( EVENT_BAY_CARFLYLOW, EVENT_BAY_CARFLYHIGH );
	
	TeleportEntity(car, NULL_VECTOR, NULL_VECTOR, vel);
	CreateTimer(2.5, timerNormalVelocity, car, TIMER_FLAG_NO_MAPCHANGE);
    /*
	new Float:burnTime = GetConVarFloat(g_cvarBurnTimeout);
	if(burnTime > 0.0)
	{
		CreateTimer(burnTime, timerRemoveCarFire, car, TIMER_FLAG_NO_MAPCHANGE);
	}
    */
}

public Action:timerNormalVelocity(Handle:timer, any:car)
{
	if(IsValidEntity(car))
	{
		new Float:vel[3];
		SetEntPropVector(car, Prop_Data, "m_vecVelocity", vel);
		TeleportEntity(car, NULL_VECTOR, NULL_VECTOR, vel);
	}
}
/*  Explosions and fire
    ------------------- */
// create explosion (delayed)
public Action: Timer_CreateExplosion(Handle:timer, any:pack)
{
    new Float:targetPos[3];
    
    ResetPack(pack);
    new Float: power = ReadPackFloat(pack);
    targetPos[0] = ReadPackFloat(pack);
    targetPos[1] = ReadPackFloat(pack);
    targetPos[2] = ReadPackFloat(pack);
    new fire = ReadPackCell(pack);
    CloseHandle(pack);
    
    if ( power == -2.0 ) {
        power = g_RC_fExplosionPowerLow;
        CreateExplosion(targetPos, power, false, true );    // small explosion
    } else {
        CreateExplosion(targetPos, power, (fire) ? true : false );
    }
    
    
    return Plugin_Continue;
}
// create explosion
CreateExplosion(Float:carPos[3], Float:power, bool:fire = false, bool:small = false)
{
    decl String:sRadius[256];
    decl String:sPower[256];
    new bool: bJustForShow = false;
    new Float:flMxDistance = float(EXPLOSION_RADIUS);
    if (!power) { power = g_RC_fExplosionPowerLow; }
    
    if (power == -1.0) {
        bJustForShow = true;
        power = 5.0;
    }
    
    if ( small ) {
        // special case: just make one small explosion (propane tank exploding)
        
        new ent = CreateEntityByName("prop_physics");
        DispatchKeyValue(ent, "physdamagescale", "0.0");
        DispatchKeyValue(ent, "model", MODEL_PROPANE);
        DispatchSpawn(ent);
        if (IsValidEntity(ent)) {
            TeleportEntity(ent, carPos, NULL_VECTOR, NULL_VECTOR);
            SetEntityMoveType(ent, MOVETYPE_VPHYSICS);
            AcceptEntityInput(ent, "Break");
        }
        return;
    }
    
    IntToString(EXPLOSION_RADIUS, sRadius, sizeof(sRadius));
    IntToString(RoundFloat(power), sPower, sizeof(sPower));
    new exParticle2 = CreateEntityByName("info_particle_system");
    new exParticle3 = CreateEntityByName("info_particle_system");
    new exPhys = CreateEntityByName("env_physexplosion");
    new exTrace = 0;
    new exHurt = 0;
    if (!bJustForShow) {
        exHurt = CreateEntityByName("point_hurt");
    }
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
    if (!bJustForShow) {
        DispatchKeyValue(exHurt, "DamageRadius", sRadius);
        DispatchKeyValue(exHurt, "DamageDelay", "0.5");
        DispatchKeyValue(exHurt, "Damage", "5");
        DispatchKeyValue(exHurt, "DamageType", "8");
        DispatchSpawn(exHurt);
        TeleportEntity(exHurt, carPos, NULL_VECTOR, NULL_VECTOR);
    }
    
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
    
    // no fire/pain effects when it's just for show, and don't fling players
    if (!bJustForShow) {
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
        for (new i=1; i<=MaxClients; i++)
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


/*  Blindness
    --------- */

// amount = 0 = unblind
DoBlindSurvivor(target, amount, bool:slow=true)
{
    // if 0 amount, do fadeout
    if (amount == 0)
    {
        ScreenFade(target, 0, 0, 0, 0, 0, 1, (slow) ? 500 : 10);
    } 
    else
    {
        ScreenFade(target, 0, 0, 0, amount, 0, 0, (slow) ? 500 : 10);
    }
}

public Action:Timer_UnBlindSurvivor(Handle:timer, any:client)
{
    if (IsSurvivor(client)) {
        DoBlindSurvivor(client, 0);
    }
}

public ScreenFade(target, red, green, blue, alpha, duration, type, speed)
{
	new Handle:msg = StartMessageOne("Fade", target);
	BfWriteShort(msg, speed);
	BfWriteShort(msg, duration);
	if (type == 0)
		BfWriteShort(msg, (0x0002 | 0x0008));
	else
		BfWriteShort(msg, (0x0001 | 0x0010));
	BfWriteByte(msg, red);
	BfWriteByte(msg, green);
	BfWriteByte(msg, blue);
	BfWriteByte(msg, alpha);
	EndMessage();
}

/*  Vomiting
    -------- */

PlayerGetVomitedOn(client, attacker = -1)
{
    if (!IsClientAndInGame(client)) { return; }
    if (attacker == -1) { attacker = client; }
    
    if (GetClientTeam(client) == TEAM_SURVIVOR)
    {
        if (g_CallVomitSurvivor != INVALID_HANDLE) {
            SDKCall(g_CallVomitSurvivor, client, attacker, true);
        }
        else {
            PrintToChatAll("[r error] Couldn't do vomit effect due to missing VomitSurvivor SDKCall Handle. Act like you're boomed.");
        }
        
        if (!g_bAlreadyVomitedUpon[client])
        {
            g_bAlreadyVomitedUpon[client] = true;
            
            new Handle:pack = CreateDataPack();
            WritePackCell(pack, client);
            WritePackString(pack, "boomerreaction");
            CreateTimer(0.35, Timer_Vocalize_Random, pack, TIMER_FLAG_NO_MAPCHANGE);
            
            CreateTimer(5.0, Timer_VomitedUponTimeout, client, TIMER_FLAG_NO_MAPCHANGE);
        }
    }
    else if (GetClientTeam(client) == TEAM_INFECTED)
    {
        if (g_CallBileJarPlayer != INVALID_HANDLE) {
            SDKCall(g_CallBileJarPlayer, client, attacker, true);
        }
        else {
            PrintToChatAll("[r error] Couldn't do vomit effect (infected) due to missing VomitSurvivor SDKCall Handle. Act like you're boomed.");
        }
        
        
        if (!g_bAlreadyVomitedUpon[client])
        {
            g_bAlreadyVomitedUpon[client] = true;
            CreateTimer(5.0, Timer_VomitedUponTimeout, client, TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

PlayerDoVomit(client) {
    new Float:x[3];
    new Float:z[3];
    new Float:j[3];
    new String:tName[32];
    
    new particle = CreateEntityByName("info_particle_system");

    DispatchKeyValue(particle, "effect_name", VOMIT_PARTICLE);

    DispatchSpawn(particle);
    ActivateEntity(particle);
    AcceptEntityInput(particle, "Start");
    Format(tName, sizeof(tName), "part%d", client);
    DispatchKeyValue(client, "targetname", tName);
    SetVariantString(tName);
    AcceptEntityInput(particle, "SetParent", particle, particle, 0);
    SetVariantString("eyes");
    AcceptEntityInput(particle, "SetParentAttachment");
    
    //j[0] = j[0] - 30;
    //j[1] = j[1] + 12;
    //x[1] = x[1] + 3;
    
    j[0] -= 7.0;      // angled a bit upward
    //j[1] += 12;     // angled to the side.. ?
    
    x[0] += 10.0;       // moved forward
    x[1] += 2.0;        // moved a bit to the left
    x[2] += 6.0;       // moved down a bit
    
    TeleportEntity(particle, x, j, NULL_VECTOR);
    GetClientEyePosition(client, z);
    
    z[2] -= 2.0;
    
    // do a vomit sound (per survivor diff.)
    PlayerDoVomitSound(client, z);
    
    if (g_hVomitTraceAttack[client] == INVALID_HANDLE)
    {
        g_hVomitTraceAttack[client] = CreateTimer(0.1, Timer_VomitTraceAttack, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    }
    else
    {
        CloseHandle(g_hVomitTraceAttack[client]);
        g_hVomitTraceAttack[client] = INVALID_HANDLE;
        g_hVomitTraceAttack[client] = CreateTimer(0.1, Timer_VomitTraceAttack, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    }
    
    CreateTimer(5.0, Timer_VomitDeleteParticles, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
    CreateTimer(g_RC_fVomitStreamTime, Timer_VomitStopTimer, client, TIMER_FLAG_NO_MAPCHANGE);
    
    // change position of vomit particle so it looks better
    CreateTimer(0.25, Timer_VomitAdjustPosBA, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
    CreateTimer(0.35, Timer_VomitAdjustPosBB, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
    CreateTimer(0.45, Timer_VomitAdjustPosB, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
    
    CreateTimer(0.52, Timer_VomitAdjustPosCA, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
    CreateTimer(0.68, Timer_VomitAdjustPosCB, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
    CreateTimer(0.71, Timer_VomitAdjustPosC, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
    
    CreateTimer(0.73, Timer_VomitAdjustPosD, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
    CreateTimer(0.77, Timer_VomitAdjustPosE, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_VomitAdjustPosB(Handle:timer, any:vomit) {
    if (!IsValidEntity(vomit)) { return; }
    new Float: loc[3], Float: ang[3];
    GetEntPropVector(vomit, Prop_Send, "m_vecOrigin", loc);
    GetEntPropVector(vomit, Prop_Send, "m_angRotation", ang);
    
    loc[2] -= 4.0;
    
    TeleportEntity(vomit, loc, ang, NULL_VECTOR);
}
public Action:Timer_VomitAdjustPosBA(Handle:timer, any:vomit) {
    if (!IsValidEntity(vomit)) { return; }
    new Float: loc[3], Float: ang[3];
    GetEntPropVector(vomit, Prop_Send, "m_vecOrigin", loc);
    GetEntPropVector(vomit, Prop_Send, "m_angRotation", ang);
    
    loc[2] -= 2.0;
    
    TeleportEntity(vomit, loc, ang, NULL_VECTOR);
}
public Action:Timer_VomitAdjustPosBB(Handle:timer, any:vomit) {
    if (!IsValidEntity(vomit)) { return; }
    new Float: loc[3], Float: ang[3];
    GetEntPropVector(vomit, Prop_Send, "m_vecOrigin", loc);
    GetEntPropVector(vomit, Prop_Send, "m_angRotation", ang);
    
    loc[2] -= 3.0;
    
    TeleportEntity(vomit, loc, ang, NULL_VECTOR);
}


public Action:Timer_VomitAdjustPosC(Handle:timer, any:vomit) {
    if (!IsValidEntity(vomit)) { return; }
    new Float: loc[3], Float: ang[3];
    GetEntPropVector(vomit, Prop_Send, "m_vecOrigin", loc);
    GetEntPropVector(vomit, Prop_Send, "m_angRotation", ang);
    
    loc[2] += 3.0;
    
    TeleportEntity(vomit, loc, ang, NULL_VECTOR);
}
public Action:Timer_VomitAdjustPosCA(Handle:timer, any:vomit) {
    if (!IsValidEntity(vomit)) { return; }
    new Float: loc[3], Float: ang[3];
    GetEntPropVector(vomit, Prop_Send, "m_vecOrigin", loc);
    GetEntPropVector(vomit, Prop_Send, "m_angRotation", ang);
    
    loc[2] += 1.0;
    
    TeleportEntity(vomit, loc, ang, NULL_VECTOR);
}
public Action:Timer_VomitAdjustPosCB(Handle:timer, any:vomit) {
    if (!IsValidEntity(vomit)) { return; }
    new Float: loc[3], Float: ang[3];
    GetEntPropVector(vomit, Prop_Send, "m_vecOrigin", loc);
    GetEntPropVector(vomit, Prop_Send, "m_angRotation", ang);
    
    loc[2] += 3.0;
    
    TeleportEntity(vomit, loc, ang, NULL_VECTOR);
}

public Action:Timer_VomitAdjustPosD(Handle:timer, any:vomit) {
    if (!IsValidEntity(vomit)) { return; }
    new Float: loc[3], Float: ang[3];
    GetEntPropVector(vomit, Prop_Send, "m_vecOrigin", loc);
    GetEntPropVector(vomit, Prop_Send, "m_angRotation", ang);
    
    loc[2] -= 2.0;
    
    TeleportEntity(vomit, loc, ang, NULL_VECTOR);
}

public Action:Timer_VomitAdjustPosE(Handle:timer, any:vomit) {
    if (!IsValidEntity(vomit)) { return; }
    new Float: loc[3], Float: ang[3];
    GetEntPropVector(vomit, Prop_Send, "m_vecOrigin", loc);
    GetEntPropVector(vomit, Prop_Send, "m_angRotation", ang);
    
    loc[2] -= 3.0;
    
    TeleportEntity(vomit, loc, ang, NULL_VECTOR);
    

}

PlayerDoVomitSound(client, Float:location[3] ) {
    new String: vomitSound[64] = "player/boomer/vomit/attack/bv1.wav";
    
    // pick sound based on the character (you can just do a vocalize for l4d2 survivors, though)
    if (IsClientAndInGame(client))
    {
        EmitSoundToAll(vomitSound, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, location, NULL_VECTOR, false, 0.0);
    }
}

public Action: Timer_VomitTraceAttack(Handle:timer, any:client) {
	VomitTraceAttack(client, true);
}

public bool:ExcludeSelf_Filter(entity, contentsMask, any:client) {
	if( entity == client ) { return false; }
	return true;
}

VomitTraceAttack(client, bool:bHullTrace) {
	decl Float:vPos[3], Float:vAng[3], Float:vEnd[3];

	GetClientEyePosition(client, vPos);
	GetClientEyeAngles(client, vAng);

	new Handle:trace = TR_TraceRayFilterEx(vPos, vAng, MASK_SHOT, RayType_Infinite, ExcludeSelf_Filter, client);
	if ( TR_DidHit(trace) ) {
		TR_GetEndPosition(vEnd, trace);
	}
	else {
		CloseHandle(trace);
		return;
	}

	if ( bHullTrace ) {
		CloseHandle(trace);
		decl Float:vMins[3], Float:vMaxs[3];
		vMins = Float: { -15.0, -15.0, -15.0 };
		vMaxs = Float: { 15.0, 15.0, 15.0 };
		trace = TR_TraceHullFilterEx(vPos, vEnd, vMins, vMaxs, MASK_SHOT, ExcludeSelf_Filter, client);
		
		if ( !TR_DidHit(trace) ) {
			CloseHandle(trace);
			return;
		}
	}

	TR_GetEndPosition(vEnd, trace);
	if ( GetVectorDistance(vPos, vEnd) > g_RC_fVomitRange ) {
		CloseHandle(trace);
		return;
	}

	new entity = TR_GetEntityIndex(trace);
	CloseHandle(trace);

	if ( IsClientAndInGame(entity) && !g_bAlreadyVomitedUpon[entity])
    {
        if (GetClientTeam(entity) == TEAM_INFECTED && g_RC_iVomitOnType & VOMIT_TYPE_SI)
        {
            if (!IsPlayerGhost(entity) && IsPlayerAlive(entity)) {
                PlayerGetVomitedOn(entity, client);
            }
        }
        else if (GetClientTeam(entity) == TEAM_SURVIVOR && g_RC_iVomitOnType & VOMIT_TYPE_SUR)
        {
            if (IsPlayerAlive(entity)) {
                PlayerGetVomitedOn(entity, client);
            }
        }
	}
	else
    {
		if (IsValidEntity(entity) && g_RC_iVomitOnType & VOMIT_TYPE_CI)
        {
			decl String:classname[16];
			GetEdictClassname(entity, classname, sizeof(classname));
			if( strcmp(classname, "infected") == 0 || strcmp(classname, "witch") == 0 )
			{
				VomitEntity(entity);
			}
		}
	}
}

VomitEntity(entity) {
	decl i_InfoEnt, String:s_TargetName[32];
	i_InfoEnt = CreateEntityByName("info_goal_infected_chase");
	if (IsValidEdict(i_InfoEnt))
	{
		new Float:f_Origin[3];
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", f_Origin);
		f_Origin[2] += 20.0;
		DispatchKeyValueVector(i_InfoEnt, "origin", f_Origin);
		FormatEx(s_TargetName, sizeof(s_TargetName), "goal_infected%d", entity);
		DispatchKeyValue(i_InfoEnt, "targetname", s_TargetName);
		GetEntPropString(entity, Prop_Data, "m_iName", s_TargetName, sizeof(s_TargetName));
		DispatchKeyValue(i_InfoEnt, "parentname", s_TargetName);
		DispatchSpawn(i_InfoEnt);
		SetVariantString(s_TargetName);
		AcceptEntityInput(i_InfoEnt, "SetParent", i_InfoEnt, i_InfoEnt, 0);
		ActivateEntity(i_InfoEnt);
		AcceptEntityInput(i_InfoEnt, "Enable");
	}

	SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
	SetEntProp(entity, Prop_Send, "m_glowColorOverride", -4713783);
	SetEntProp(entity, Prop_Send, "m_glowColorOverride", -4713783);
	CreateTimer(15.0, Timer_VomitDisableGlow, entity);
	CreateTimer(5.0, Timer_VomitDisableChase, i_InfoEnt);
}

public Action:Timer_VomitDeleteParticles(Handle:timer, any:particle) {
	if (EntRefToEntIndex(particle) != INVALID_ENT_REFERENCE)
	{
		if (IsValidEntity(particle) || IsValidEdict(particle))
		{
			new String:classname[64];
			GetEdictClassname(particle, classname, sizeof(classname));
			if (StrEqual(classname, "info_particle_system", false))
			{
				AcceptEntityInput(particle, "stop");
				AcceptEntityInput(particle, "kill");
			}
		}
	}
}

public Action:Timer_VomitStopTimer(Handle:timer, any:client) {
	if (g_hVomitTraceAttack[client] != INVALID_HANDLE)
	{
		CloseHandle(g_hVomitTraceAttack[client]);
		g_hVomitTraceAttack[client] = INVALID_HANDLE;
	}
}

public Action:Timer_VomitedUponTimeout(Handle:timer, any:client) {
    g_bAlreadyVomitedUpon[client] = false;
}

public Action:Timer_VomitDisableGlow(Handle:h_Timer, any:i_Ent) {
	decl String:s_ModelName[64];
	
	if (!IsValidEdict(i_Ent) || !IsValidEntity(i_Ent))
	return Plugin_Handled;
	
	GetEntPropString(i_Ent, Prop_Data, "m_ModelName", s_ModelName, sizeof(s_ModelName));

	if (StrContains(s_ModelName, "infected") != -1)
	{
		SetEntProp(i_Ent, Prop_Send, "m_iGlowType", 0);
		SetEntProp(i_Ent, Prop_Send, "m_glowColorOverride", 0);
	}
	
	return Plugin_Continue;
}

public Action:Timer_VomitDisableChase(Handle:h_Timer, any:i_Ent) {
	if (IsValidEntity(i_Ent))
	{
		AcceptEntityInput(i_Ent, "kill");
	}
	return Plugin_Continue;
}

