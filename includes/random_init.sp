#pragma semicolon 1
#include <sourcemod>


// note: these must also be defined in random_support
#define FIRE_PARTICLE           "gas_explosion_ground_fire"
#define EXPLOSION_PARTICLE      "FluidExplosion_fps"
#define EXPLOSION_PARTICLE2     "weapon_grenade_explosion"
#define EXPLOSION_PARTICLE3     "explosion_huge_b"
#define BURN_IGNITE_PARTICLE    "fire_small_01"


INIT_DefineCVars()
{
    // ConVars
    g_hCvarEqual = CreateConVar(                            "rand_equal",                  "2047",      "[Flags] What to keep equal between each team's survivor round (1: items; 2: doors; 4: glows; 8: event; 16: incaps; 32: horde; 64: item weighting; 128: starting health; 256: first attack; 512: tanks; 1024: scoring).", FCVAR_PLUGIN, true, 0.0, false);
    //g_hCvarDelay = CreateConVar(                            "rand_delay",                    "2.5",     "How many seconds after round start to wait before randomizing.", FCVAR_PLUGIN, true, 1.0, true, 50.0 );
    g_hCvarDoReport = CreateConVar(                         "rand_report",                   "1",       "Whether to do automatic reports at the start of a round.", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
    g_hCvarReportDelay = CreateConVar(                      "rand_report_delay",            "15",       "How many seconds after first survivor joins map to wait before reporting special event.", FCVAR_PLUGIN, true, 1.0, true, 120.0 );
    g_hCvarReportSackProt = CreateConVar(                   "rand_report_sackprotection",    "1",       "Whether sack-protection measures are reported to the relevant players.", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
    g_hCvarRandomSpawns = CreateConVar(                     "rand_random_si",                "1",       "Whether SI spawns are fully random (or Valve-ordered).", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
    g_hCvarSackProtection = CreateConVar(                   "rand_si_sackprotection",        "1",       "Whether SI spawn sacking is punished (keeping a charger hoping to get a multi-charger attack, for instance).", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
    g_hCvarForcePhysics = CreateConVar(                     "rand_force_physics",            "0",       "Force physics enabled on (some) items.", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
    g_hCvarM60Ammo = CreateConVar(                          "rand_m60_ammo",                "50",       "How much ammo an M60 spawns with.", FCVAR_PLUGIN, true, 0.0, false );
    g_hCvarClipFactorInc = CreateConVar(                    "rand_incendiary_ammo_factor",   "0.5",     "Incendiary ammo gives you a clip's normal size times this.", FCVAR_PLUGIN, true, 0.0, true, 2.0);
    g_hCvarClipFactorExp = CreateConVar(                    "rand_explosive_ammo_factor",    "0.25",    "Explosive ammo gives you a clip's normal size times this.", FCVAR_PLUGIN, true, 0.0, true, 2.0 );
    g_hCvarNoSupportSI = CreateConVar(                      "rand_only_cappers",             "0",       "If set, only allows cappers to spawn (useful for 2v2s 3v3s).", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarRestrictMelee = CreateConVar(                    "rand_restrict_melee",           "1",       "If set, only allows normal l4d2 melee weapons to spawn.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarRandomTank = CreateConVar(                       "rand_tank",                     "1",       "Whether player selection for tank is purely random.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarBoomedTime = CreateConVar(                       "rand_boomed_time",             "10.0",     "The time window in seconds that boomer team-ups are rewarded (2+ boomers getting booms on different survivors). 0 = boomer combos are not rewarded.", FCVAR_PLUGIN, true, 0.0, true, 20.0);
    g_hCvarGnomeBonus = CreateConVar(                       "rand_gnome_bonus",              "0.25",    "The bonus given for bringing a gnome from start to end saferoom. (lower than 10 = amount of times distance, greater = static bonus)", FCVAR_PLUGIN, true, 0.0);
    g_hCvarGnomeFinaleFactor = CreateConVar(                "rand_gnome_finale_factor",      "0.5",     "The gnome bonus is worth this factor on finales.", FCVAR_PLUGIN, true, 0.0);
    g_hCvarGnomeAllowRandom = CreateConVar(                 "rand_gnome_random",             "0",       "Whether gnomes can drop at random (from gifts, common drops etc)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    
    g_hCvarNoitemVariance = CreateConVar(                   "rand_noitem_variance",          "0.25",    "Variance of weight for 'no item' in item randomizer.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarSpecialEventChance = CreateConVar(               "rand_event_chance",             "0.65",    "Chances of any map going in 'special event' mode.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarPillsChance = CreateConVar(                      "rand_pills_chance",             "0.45",    "Chance that a survivor is given pills at start.", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
    g_hCvarExtraSecondaryChance = CreateConVar(             "rand_secondary_chance",         "0.5",     "Chance that a survivor is given a secondary weapon if given a primary at start.", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
    g_hCvarHealthChance = CreateConVar(                     "rand_health_chance",            "0.0",     "Chance that a survivor is given different starting health.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarHealthMin = CreateConVar(                        "rand_health_min",              "50",       "Minimum survivor starting health.", FCVAR_PLUGIN, true, 1.0, true, 100.0);
    g_hCvarOutlineChance = CreateConVar(                    "rand_outline_chance",           "0.85",    "Chances of there being survivor outlines this round.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarDoorLockedChance = CreateConVar(                 "rand_doorlocked_chance",        "0.1",     "Chances of any door being locked.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarStartSafeItem = CreateConVar(                    "rand_startsafe_item_chance",    "1.0",     "Chances that an item spawn in the start saferoom will be used.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarEndSafeItem = CreateConVar(                      "rand_endsafe_item_chance",      "0.0",     "Chances that an item spawn in the end saferoom will be used.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarUncommonChance = CreateConVar(                   "rand_uncommon_chance",          "0.05",    "Chances of any common spawning becoming an uncommon.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarFallenChance = CreateConVar(                     "rand_fallen_chance",            "0.05",    "Chances of any uncommon spawning becoming a Fallen Survivor.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarJimmyChance = CreateConVar(                      "rand_jimmy_chance",             "0.003",   "Chances of any uncommon spawning becoming Jimmy Gibbs.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarFirstQuadChance = CreateConVar(                  "rand_firstquad_chance",         "0.1",     "Chances of the first attack being a quad cap.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarAmmoVarianceMore = CreateConVar(                 "rand_ammo_more_variance",       "0.2",     "Variance of ammo in weapon pickups, positive direction.", FCVAR_PLUGIN, true, 0.0, false);
    g_hCvarAmmoVarianceLess = CreateConVar(                 "rand_ammo_less_variance",       "0.2",     "Variance of ammo in weapon pickups, negative direction.", FCVAR_PLUGIN, true, 0.0, false);
    g_hCvarDoubleTankChance = CreateConVar(                 "rand_doubletank_chance",        "0.0",     "Chances of double tanks spawning for a round that will have a tank.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarMultiWitchChance = CreateConVar(                 "rand_multiwitch_chance",        "0.4",     "Chances of multiple witches spawning for a round that will have a witch.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarTankFlowVariance = CreateConVar(                 "rand_tankflow_variance",        "0.1",     "Amount of variance allowed for multiple tank spawns (around 0.25 and 0.75).", FCVAR_PLUGIN, true, 0.0, true, 0.20);
    g_hCvarItemDropChance = CreateConVar(                   "rand_itemdrop_chance",          "0.01",    "Chances of common infected dropping an item.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarTankItemDropChance = CreateConVar(               "rand_tankitemdrop_chance",      "0.75",    "Chances of a (normal) tank dropping some items.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarGiftPositiveChance = CreateConVar(               "rand_giftgood_chance",          "0.66",    "Chances of opening a gift resulting in something positive.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarPipeDudChance = CreateConVar(                    "rand_pipedud_chance",           "0.35",    "Chances of a pipebomb being a dud.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarAvoidIncapsChance = CreateConVar(                "rand_moreincaps_chance",        "0.35",    "If the incap count is only 1 (33%), odds that it gets set to 2 anyway.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarFinaleAmmoChance = CreateConVar(                 "rand_finale_ammo",              "0.0",     "Chances of finale ammo piles being randomized.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    
    g_hCvarFinaleItemUseful =  CreateConVar(                "rand_item_finale_useful",       "0.25",    "Factor by which non-useful items are adjusted for finale maps (lower = easier map).", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarStartItemNoJunk =  CreateConVar(                 "rand_item_start_nojunk",        "0.25",    "Chances items in start saferoom will be converted to something useful.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarStartItemAmmo =  CreateConVar(                   "rand_item_start_ammo",          "0.5",     "Chances that there will be at least one ammo pile in the start saferoom (if non are generated there).", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarStartItemGnome =  CreateConVar(                  "rand_item_start_gnome",         "0.25",    "Chances that there will be at least one gnome in the start saferoom (if non are generated there).", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    
    g_hCvarRandDistance = CreateConVar(                     "rand_distance",                 "1",       "Distance mode: 0 = normal; 1 = variance from normal; 2 = full random.", FCVAR_PLUGIN, true, 0.0, true, 2.0);
    g_hCvarRandDistVar = CreateConVar(                      "rand_dist_var",                 "0.2",     "For distance variance: how much it can deviate from normal value.", FCVAR_PLUGIN, true, 0.1, true, 0.9);
    g_hCvarRandDistMin = CreateConVar(                      "rand_dist_min",               "200",       "For fully random distance: the minimum.", FCVAR_PLUGIN, true, 50.0, true, 900.0);
    g_hCvarRandDistMax = CreateConVar(                      "rand_dist_max",              "1000",       "For fully random distance: the maximum.", FCVAR_PLUGIN, true, 100.0, true, 2000.0);
    g_hCvarRandBonus = CreateConVar(                        "rand_bonus",                    "1",       "Bonus mode: 0 = base, no variation; 1 = variance from base; 2 = full random.", FCVAR_PLUGIN, true, 0.0, true, 2.0);
    g_hCvarRandBonusBase = CreateConVar(                    "rand_bonus_base",               "1.0",     "Bonus base value: 0.0 = static; anything else: scaled to X times distance.", FCVAR_PLUGIN, true, 0.0, true, 5.0);
    g_hCvarRandBonusStatic = CreateConVar(                  "rand_bonus_static",           "400",       "Bonus static value (used only if bonus_base is 0.0).", FCVAR_PLUGIN, true, 0.0, true, 1600.0);
    g_hCvarRandBonusVar = CreateConVar(                     "rand_bonus_var",                "0.2",     "For bonus variance: how much it can deviate from normal value.", FCVAR_PLUGIN, true, 0.1, true, 0.9);
    g_hCvarRandBonusMin = CreateConVar(                     "rand_bonus_min",               "200",      "For fully random bonus: the minimum.", FCVAR_PLUGIN, true, 50.0, true, 900.0);
    g_hCvarRandBonusMax = CreateConVar(                     "rand_bonus_max",               "800",      "For fully random bonus: the maximum.", FCVAR_PLUGIN, true, 100.0, true, 4000.0);
    
    g_hArCvarWeight[INDEX_NOITEM] = CreateConVar(           "rand_weight_nothing",          "25",       "Weight for picking item spawns.",          FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarWeight[INDEX_PISTOL] = CreateConVar(           "rand_weight_pistol",           "13",       "Weight for picking item spawns.",          FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarWeight[INDEX_T1SMG] = CreateConVar(            "rand_weight_t1smg",            "13",       "Weight for picking item spawns.",          FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarWeight[INDEX_T1SHOTGUN] = CreateConVar(        "rand_weight_t1shotgun",        "13",       "Weight for picking item spawns.",          FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarWeight[INDEX_T2RIFLE] = CreateConVar(          "rand_weight_t2rifle",           "5",       "Weight for picking item spawns.",          FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarWeight[INDEX_T2SHOTGUN] = CreateConVar(        "rand_weight_t2shotgun",         "5",       "Weight for picking item spawns.",          FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarWeight[INDEX_SNIPER] = CreateConVar(           "rand_weight_sniper",            "8",       "Weight for picking item spawns.",          FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarWeight[INDEX_MELEE] = CreateConVar(            "rand_weight_melee",            "13",       "Weight for picking item spawns.",          FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarWeight[INDEX_T3] = CreateConVar(               "rand_weight_t3",                "4",       "Weight for picking item spawns.",          FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarWeight[INDEX_CANISTER] = CreateConVar(         "rand_weight_canister",         "18",       "Weight for picking item spawns.",          FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarWeight[INDEX_PILL] = CreateConVar(             "rand_weight_pill",             "16",       "Weight for picking item spawns.",          FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarWeight[INDEX_THROWABLE] = CreateConVar(        "rand_weight_throwable",         "8",       "Weight for picking item spawns.",          FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarWeight[INDEX_KIT] = CreateConVar(              "rand_weight_kit",              "11",       "Weight for picking item spawns.",          FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarWeight[INDEX_UPGRADE] = CreateConVar(          "rand_weight_upgrade",           "5",       "Weight for picking item spawns.",          FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarWeight[INDEX_AMMO] = CreateConVar(             "rand_weight_ammo",              "5",       "Weight for picking item spawns.",          FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarWeight[INDEX_JUNK] = CreateConVar(             "rand_weight_junk",             "18",       "Weight for picking item spawns.",          FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarWeight[INDEX_SILLY] = CreateConVar(            "rand_weight_silly",             "4",       "Weight for picking item spawns.",          FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarWeight[INDEX_GIFT] = CreateConVar(             "rand_weight_gift",              "3",       "Weight for picking item spawns.",          FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    
    g_hArCvarSurvWeight[INDEX_SURV_NOTHING] = CreateConVar( "rand_weight_surv_nothing",      "5",       "Weight for picking survivor starting gear.", FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarSurvWeight[INDEX_SURV_PISTOL] = CreateConVar(  "rand_weight_surv_pistol",      "15",       "Weight for picking survivor starting gear.", FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarSurvWeight[INDEX_SURV_DUALS] = CreateConVar(   "rand_weight_surv_duals",       "20",       "Weight for picking survivor starting gear.", FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarSurvWeight[INDEX_SURV_MAGNUM] = CreateConVar(  "rand_weight_surv_magnum",      "10",       "Weight for picking survivor starting gear.", FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarSurvWeight[INDEX_SURV_T1SMG] = CreateConVar(   "rand_weight_surv_t1smg",       "40",       "Weight for picking survivor starting gear.", FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarSurvWeight[INDEX_SURV_T1SHOT] = CreateConVar(  "rand_weight_surv_t1shotgun",   "40",       "Weight for picking survivor starting gear.", FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarSurvWeight[INDEX_SURV_MELEE] = CreateConVar(   "rand_weight_surv_melee",       "10",       "Weight for picking survivor starting gear.", FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    
    g_hArCvarEvtWeight[EVT_ITEM] = CreateConVar(            "rand_weight_evt_item",          "1",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_HORDE_HUGE] = CreateConVar(      "rand_weight_evt_horde",         "2",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_HORDE_NONE] = CreateConVar(      "rand_weight_evt_nohorde",       "2",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_UNCOMMON] = CreateConVar(        "rand_weight_evt_uncommon",      "2",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_CLOWNS] = CreateConVar(          "rand_weight_evt_circus",        "1",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_DOORS] = CreateConVar(           "rand_weight_evt_doors",         "2",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_QUADS] = CreateConVar(           "rand_weight_evt_quads",         "2",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_WEATHER] = CreateConVar(         "rand_weight_evt_storm",         "2",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_FOG] = CreateConVar(             "rand_weight_evt_fog",           "2",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_ABUNDANCE] = CreateConVar(       "rand_weight_evt_abundance",     "1",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_SNIPER] = CreateConVar(          "rand_weight_evt_sniper",        "1",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_GIFTS] = CreateConVar(           "rand_weight_evt_gifts",         "3",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_DEFIB] = CreateConVar(           "rand_weight_evt_defib",         "2",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_ADREN] = CreateConVar(           "rand_weight_evt_adren",         "2",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_NOHUD] = CreateConVar(           "rand_weight_evt_nohud",         "2",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_L4D1] = CreateConVar(            "rand_weight_evt_l4d1",          "2",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_FF] = CreateConVar(              "rand_weight_evt_ff",            "1",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_SILENCE] = CreateConVar(         "rand_weight_evt_sound",         "2",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_PEN_ITEM] = CreateConVar(        "rand_weight_evt_penitem",       "1",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_PEN_HEALTH] = CreateConVar(      "rand_weight_evt_penhealth",     "1",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_PEN_M2] = CreateConVar(          "rand_weight_evt_penm2",         "1",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_GUNSWAP] = CreateConVar(         "rand_weight_evt_gunswap",       "2",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_MINITANKS] = CreateConVar(       "rand_weight_evt_minitanks",     "1",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_KEYMASTER] = CreateConVar(       "rand_weight_evt_keymaster",     "1",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_BADCOMBO] = CreateConVar(        "rand_weight_evt_badcombo",      "1",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_PROTECT] = CreateConVar(         "rand_weight_evt_protect",       "1",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_ENCUMBERED] = CreateConVar(      "rand_weight_evt_encumbered",    "1",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    
    // built in cvars (for tracking)
    g_hCvarReadyUp = FindConVar("l4d_ready_enabled");
}

INIT_CVarsGetDefault()
{
    // Store some default cvar values
    g_iDefSpawnTimeMin =        GetConVarInt(FindConVar("z_ghost_delay_min"));
    g_iDefSpawnTimeMax =        GetConVarInt(FindConVar("z_ghost_delay_max"));
    
    g_iDefCommonLimit =         GetConVarInt(FindConVar("z_common_limit"));
    g_iDefBackgroundLimit =     GetConVarInt(FindConVar("z_background_limit"));
    g_iDefHordeTimeMin =        GetConVarInt(FindConVar("z_mob_spawn_min_interval_normal"));
    g_iDefHordeTimeMax =        GetConVarInt(FindConVar("z_mob_spawn_max_interval_normal"));
    g_iDefHordeSizeMin =        GetConVarInt(FindConVar("z_mob_spawn_min_size"));
    g_iDefHordeSizeMax =        GetConVarInt(FindConVar("z_mob_spawn_max_size"));
    
    g_iDefDefibPenalty =        GetConVarInt(FindConVar("vs_defib_penalty"));
    g_iDefDefibDuration =       GetConVarInt(FindConVar("defibrillator_use_duration"));
    g_fDefPillDecayRate =       GetConVarFloat(FindConVar("pain_pills_decay_rate"));
    
    g_iTeamSize =               GetConVarInt(FindConVar("survivor_limit"));
    
    g_iDefSpitterLimit =        GetConVarInt(FindConVar("z_spitter_limit"));
    g_iDefJockeyLimit =         GetConVarInt(FindConVar("z_jockey_limit"));
    g_iDefChargerLimit =        GetConVarInt(FindConVar("z_charger_limit"));
    
    g_fDefFFFactor =            GetConVarFloat(FindConVar("survivor_friendly_fire_factor_normal"));
    
    g_iDefTankHealth =          GetConVarInt(FindConVar("z_tank_health"));
    g_iDefTankFrustTime =       GetConVarInt(FindConVar("z_frustration_lifetime"));
    g_iDefTankDamage =          GetConVarInt(FindConVar("vs_tank_damage"));
}

INIT_CVarsReset()
{
    // reset cvars that we changed here or with Stabby's plugin ([l4d2_]randomstats)
    SetConVarInt(FindConVar("sv_disable_glow_survivors"), 0);
    SetConVarInt(FindConVar("survivor_max_incapacitated_count"), INCAP_DEFAULT);
    
    // reset cvars for which we stored starting values (difficulty si/ci)
    EVENT_ResetDifficulty();
    EVENT_ResetOtherCvars();
}

INIT_FillTries()
{
    // Tries    
    g_hTrieEntityCreated = CreateTrie();                                                                                            // classname trie for checking OnEntityCreated()
    SetTrieValue(g_hTrieEntityCreated, "infected",                                  CREATED_INFECTED);
    SetTrieValue(g_hTrieEntityCreated, "pipe_bomb_projectile",                      CREATED_PIPEBOMB);
    SetTrieValue(g_hTrieEntityCreated, "physics_prop",                              CREATED_PROP_PHYSICS);
    
    g_hTrieRandomizableEntity = CreateTrie();                                                                                       // classname trie for finding randomizable items
    SetTrieValue(g_hTrieRandomizableEntity, "weapon_spawn",                         RANDOMIZABLE_ITEM);
    SetTrieValue(g_hTrieRandomizableEntity, "weapon_item_spawn",                    RANDOMIZABLE_ITEM);
    SetTrieValue(g_hTrieRandomizableEntity, "weapon_ammo_spawn",                    RANDOMIZABLE_ITEM_AMMO);
    SetTrieValue(g_hTrieRandomizableEntity, "weapon_melee_spawn",                   RANDOMIZABLE_ITEM);
    SetTrieValue(g_hTrieRandomizableEntity, "weapon_pistol_spawn",                  RANDOMIZABLE_ITEM);
    SetTrieValue(g_hTrieRandomizableEntity, "weapon_pistol_magnum_spawn",           RANDOMIZABLE_ITEM);
    SetTrieValue(g_hTrieRandomizableEntity, "weapon_smg_spawn",                     RANDOMIZABLE_ITEM);
    SetTrieValue(g_hTrieRandomizableEntity, "weapon_smg_silenced_spawn",            RANDOMIZABLE_ITEM);
    SetTrieValue(g_hTrieRandomizableEntity, "weapon_pumpshotgun_spawn",             RANDOMIZABLE_ITEM);
    SetTrieValue(g_hTrieRandomizableEntity, "weapon_shotgun_chrome_spawn",          RANDOMIZABLE_ITEM);
    SetTrieValue(g_hTrieRandomizableEntity, "weapon_hunting_rifle_spawn",           RANDOMIZABLE_ITEM);
    SetTrieValue(g_hTrieRandomizableEntity, "weapon_sniper_military_spawn",         RANDOMIZABLE_ITEM);
    SetTrieValue(g_hTrieRandomizableEntity, "weapon_rifle_spawn",                   RANDOMIZABLE_ITEM);
    SetTrieValue(g_hTrieRandomizableEntity, "weapon_rifle_ak47_spawn",              RANDOMIZABLE_ITEM);
    SetTrieValue(g_hTrieRandomizableEntity, "weapon_rifle_desert_spawn",            RANDOMIZABLE_ITEM);
    SetTrieValue(g_hTrieRandomizableEntity, "weapon_autoshotgun_spawn",             RANDOMIZABLE_ITEM);
    SetTrieValue(g_hTrieRandomizableEntity, "weapon_shotgun_spas_spawn",            RANDOMIZABLE_ITEM);
    SetTrieValue(g_hTrieRandomizableEntity, "weapon_rifle_m60_spawn",               RANDOMIZABLE_ITEM);
    SetTrieValue(g_hTrieRandomizableEntity, "weapon_grenade_launcher_spawn",        RANDOMIZABLE_ITEM);
    SetTrieValue(g_hTrieRandomizableEntity, "weapon_chainsaw_spawn",                RANDOMIZABLE_ITEM);
    SetTrieValue(g_hTrieRandomizableEntity, "weapon_first_aid_kit_spawn",           RANDOMIZABLE_ITEM);
    SetTrieValue(g_hTrieRandomizableEntity, "weapon_defibrillator_spawn",           RANDOMIZABLE_ITEM);
    SetTrieValue(g_hTrieRandomizableEntity, "weapon_pain_pills_spawn",              RANDOMIZABLE_ITEM);
    SetTrieValue(g_hTrieRandomizableEntity, "weapon_adrenaline_spawn",              RANDOMIZABLE_ITEM);
    SetTrieValue(g_hTrieRandomizableEntity, "weapon_pipe_bomb_spawn",               RANDOMIZABLE_ITEM);
    SetTrieValue(g_hTrieRandomizableEntity, "weapon_molotov_spawn",                 RANDOMIZABLE_ITEM);
    SetTrieValue(g_hTrieRandomizableEntity, "weapon_vomitjar_spawn",                RANDOMIZABLE_ITEM);
    SetTrieValue(g_hTrieRandomizableEntity, "weapon_gascan_spawn",                  RANDOMIZABLE_ITEM);
    SetTrieValue(g_hTrieRandomizableEntity, "upgrade_spawn",                        RANDOMIZABLE_ITEM);                             // lasersights? somehow not picked up by this...
    SetTrieValue(g_hTrieRandomizableEntity, "upgrade_laser_sight",                  RANDOMIZABLE_ITEM);
    SetTrieValue(g_hTrieRandomizableEntity, "weapon_upgradepack_explosive_spawn",   RANDOMIZABLE_ITEM);
    SetTrieValue(g_hTrieRandomizableEntity, "weapon_upgradepack_incendiary_spawn",  RANDOMIZABLE_ITEM);
    SetTrieValue(g_hTrieRandomizableEntity, "upgrade_ammo_incendiary",              RANDOMIZABLE_ITEM);                             // probably never appears
    SetTrieValue(g_hTrieRandomizableEntity, "upgrade_ammo_explosive",               RANDOMIZABLE_ITEM);                             // probably never appears
    
    SetTrieValue(g_hTrieRandomizableEntity, "prop_physics",                         RANDOMIZABLE_PHYSICS);
    g_hTrieRandomizablePropPhysicsModel = CreateTrie();                                                                             // cant go around turning EVERY prop_physics into crazy things
    SetTrieValue(g_hTrieRandomizablePropPhysicsModel, "models/props_junk/gascan001a.mdl",               RANDOMIZABLE_PHYSICS);
    SetTrieValue(g_hTrieRandomizablePropPhysicsModel, "models/props_junk/propanecanister001a.mdl",      RANDOMIZABLE_PHYSICS);
    SetTrieValue(g_hTrieRandomizablePropPhysicsModel, "models/props_equipment/oxygentank01.mdl",        RANDOMIZABLE_PHYSICS);
    SetTrieValue(g_hTrieRandomizablePropPhysicsModel, "models/props/cs_office/Fire_Extinguisher.mdl",   RANDOMIZABLE_PHYSICS);
    SetTrieValue(g_hTrieRandomizablePropPhysicsModel, "models/props_junk/gnome.mdl",                    RANDOMIZABLE_PHYSICS);
    SetTrieValue(g_hTrieRandomizablePropPhysicsModel, "models/props_junk/explosive_box001.mdl",         RANDOMIZABLE_PHYSICS);    
    
    g_hTrieMeleeType = CreateTrie();                                                                                                // classname trie for finding 'normal' melees
    SetTrieValue(g_hTrieMeleeType, "fireaxe",                   MELEE_NORMAL);
    SetTrieValue(g_hTrieMeleeType, "frying_pan",                MELEE_NORMAL);
    SetTrieValue(g_hTrieMeleeType, "machete",                   MELEE_NORMAL);
    SetTrieValue(g_hTrieMeleeType, "baseball_bat",              MELEE_NORMAL);
    SetTrieValue(g_hTrieMeleeType, "crowbar",                   MELEE_NORMAL);
    SetTrieValue(g_hTrieMeleeType, "cricket_bat",               MELEE_NORMAL);
    SetTrieValue(g_hTrieMeleeType, "tonfa",                     MELEE_NORMAL);
    SetTrieValue(g_hTrieMeleeType, "katana",                    MELEE_NORMAL);
    SetTrieValue(g_hTrieMeleeType, "electric_guitar",           MELEE_NORMAL);
    SetTrieValue(g_hTrieMeleeType, "golfclub",                  MELEE_NORMAL);
    SetTrieValue(g_hTrieMeleeType, "hunting_knife",             MELEE_WEIRD);
    
    g_hTrieMaps = CreateTrie();
    SetTrieValue(g_hTrieMaps, "c1m1_hotel",                     MAPS_INTRO);
    SetTrieValue(g_hTrieMaps, "c2m1_highway",                   MAPS_INTRO);
    SetTrieValue(g_hTrieMaps, "c3m1_plankcountry",              MAPS_INTRO);
    SetTrieValue(g_hTrieMaps, "c4m1_milltown_a",                MAPS_INTRO);
    SetTrieValue(g_hTrieMaps, "c5m1_waterfront",                MAPS_INTRO);
    SetTrieValue(g_hTrieMaps, "c6m1_riverbank",                 MAPS_INTRO);
    SetTrieValue(g_hTrieMaps, "c7m1_docks",                     MAPS_INTRO);
    SetTrieValue(g_hTrieMaps, "c8m1_apartment",                 MAPS_INTRO);
    SetTrieValue(g_hTrieMaps, "c9m1_alleys",                    MAPS_INTRO);
    SetTrieValue(g_hTrieMaps, "c10m1_caves",                    MAPS_INTRO);
    SetTrieValue(g_hTrieMaps, "c11m1_greenhouse",               MAPS_INTRO);
    SetTrieValue(g_hTrieMaps, "c12m1_hilltop",                  MAPS_INTRO);
    SetTrieValue(g_hTrieMaps, "c13m1_alpinecreek",              MAPS_INTRO);
    SetTrieValue(g_hTrieMaps, "c5m1_darkwaterfront",            MAPS_INTRO);
    SetTrieValue(g_hTrieMaps, "bloodtracks_01",                 MAPS_INTRO);
    SetTrieValue(g_hTrieMaps, "gasfever_1",                     MAPS_INTRO);
    SetTrieValue(g_hTrieMaps, "cdta_01detour",                  MAPS_INTRO);
    SetTrieValue(g_hTrieMaps, "l4d2_stadium1_apartment",        MAPS_INTRO);
    SetTrieValue(g_hTrieMaps, "l4d_ihm01_forest",               MAPS_INTRO);
    SetTrieValue(g_hTrieMaps, "l4d2_diescraper1_apartment_33",  MAPS_INTRO);
    SetTrieValue(g_hTrieMaps, "c1m2_streets",                   MAPS_NOCOLA);
    SetTrieValue(g_hTrieMaps, "c4m3_sugarmill_b",               MAPS_NOSTORM);
    SetTrieValue(g_hTrieMaps, "c4m4_milltown_b",                MAPS_NOSTORM);
    
    
    g_hTrieBlindable = CreateTrie();
    SetTrieValue(g_hTrieBlindable, "predicted_viewmodel",       ENTITY_NOT_BLINDABLE);
    SetTrieValue(g_hTrieBlindable, "instance_scripted_scene",   ENTITY_NOT_BLINDABLE);
    
    
    g_hTriePenaltyItems = CreateTrie();
    SetTrieValue(g_hTriePenaltyItems, "melee",                      ITEM_PICKUP_PENALTY_MELEE);
    SetTrieValue(g_hTriePenaltyItems, "pain_pills",                 ITEM_PICKUP_PENALTY);
    SetTrieValue(g_hTriePenaltyItems, "adrenaline",                 ITEM_PICKUP_PENALTY);
    SetTrieValue(g_hTriePenaltyItems, "first_aid_kit",              ITEM_PICKUP_PENALTY);
    SetTrieValue(g_hTriePenaltyItems, "defibrillator",              ITEM_PICKUP_PENALTY);
    SetTrieValue(g_hTriePenaltyItems, "upgradepack_explosive",      ITEM_PICKUP_PENALTY);
    SetTrieValue(g_hTriePenaltyItems, "upgradepack_incendiary",     ITEM_PICKUP_PENALTY);
    SetTrieValue(g_hTriePenaltyItems, "pipe_bomb",                  ITEM_PICKUP_PENALTY);
    SetTrieValue(g_hTriePenaltyItems, "molotov",                    ITEM_PICKUP_PENALTY);
    SetTrieValue(g_hTriePenaltyItems, "vomitjar",                   ITEM_PICKUP_PENALTY);
    SetTrieValue(g_hTriePenaltyItems, "chainsaw",                   ITEM_PICKUP_PENALTY);
    
    SetTrieValue(g_hTriePenaltyItems, "weapon_melee",               ITEM_PICKUP_PENALTY_MELEE);
    SetTrieValue(g_hTriePenaltyItems, "weapon_pistol",              ITEM_PICKUP_PENALTY_PISTOL);
    SetTrieValue(g_hTriePenaltyItems, "weapon_pistol_magnum",       ITEM_PICKUP_PENALTY_PISTOL);
    SetTrieValue(g_hTriePenaltyItems, "weapon_smg",                 ITEM_PICKUP_PENALTY_PRIMARY_T1);
    SetTrieValue(g_hTriePenaltyItems, "weapon_smg_silenced",        ITEM_PICKUP_PENALTY_PRIMARY_T1);
    SetTrieValue(g_hTriePenaltyItems, "weapon_pumpshotgun",         ITEM_PICKUP_PENALTY_PRIMARY_T1);
    SetTrieValue(g_hTriePenaltyItems, "weapon_shotgun_chrome",      ITEM_PICKUP_PENALTY_PRIMARY_T1);
    SetTrieValue(g_hTriePenaltyItems, "weapon_autoshotgun",         ITEM_PICKUP_PENALTY_PRIMARY_T2);
    SetTrieValue(g_hTriePenaltyItems, "weapon_shotgun_spas",        ITEM_PICKUP_PENALTY_PRIMARY_T2);
    SetTrieValue(g_hTriePenaltyItems, "weapon_rifle",               ITEM_PICKUP_PENALTY_PRIMARY_T2);
    SetTrieValue(g_hTriePenaltyItems, "weapon_rifle_desert",        ITEM_PICKUP_PENALTY_PRIMARY_T2);
    SetTrieValue(g_hTriePenaltyItems, "weapon_rifle_ak47",          ITEM_PICKUP_PENALTY_PRIMARY_T2);
    SetTrieValue(g_hTriePenaltyItems, "weapon_hunting_rifle",       ITEM_PICKUP_PENALTY_PRIMARY_T2);
    SetTrieValue(g_hTriePenaltyItems, "weapon_sniper_military",     ITEM_PICKUP_PENALTY_PRIMARY_T2);
    SetTrieValue(g_hTriePenaltyItems, "weapon_smg_mp5",             ITEM_PICKUP_PENALTY_PRIMARY_T1);
    SetTrieValue(g_hTriePenaltyItems, "weapon_rifle_sg552",         ITEM_PICKUP_PENALTY_PRIMARY_T2);
    SetTrieValue(g_hTriePenaltyItems, "weapon_sniper_awp",          ITEM_PICKUP_PENALTY_PRIMARY_T2);
    SetTrieValue(g_hTriePenaltyItems, "weapon_sniper_scout",        ITEM_PICKUP_PENALTY_PRIMARY_T1);
    SetTrieValue(g_hTriePenaltyItems, "weapon_grenade_launcher",    ITEM_PICKUP_PENALTY_PRIMARY_T3);
    SetTrieValue(g_hTriePenaltyItems, "weapon_rifle_m60",           ITEM_PICKUP_PENALTY_PRIMARY_T3);
    //SetTrieValue(g_hTriePenaltyItems, "fireworkcrate",          ITEM_PICKUP_CANISTER);
    //SetTrieValue(g_hTriePenaltyItems, "gascan",                 ITEM_PICKUP_CANISTER);
    //SetTrieValue(g_hTriePenaltyItems, "propanetank",            ITEM_PICKUP_CANISTER);
    //SetTrieValue(g_hTriePenaltyItems, "oxygentank",             ITEM_PICKUP_CANISTER);
    
    g_hTriePropItems = CreateTrie();
    SetTrieValue(g_hTriePropItems, "weapon_gnome",                  ITEM_PROP_GNOME);
    SetTrieValue(g_hTriePropItems, "weapon_colabottles",            ITEM_PROP_COLA);
    SetTrieValue(g_hTriePropItems, "weapon_gascan",                 ITEM_PROP_CANISTER);
    SetTrieValue(g_hTriePropItems, "weapon_fireworkcrate",          ITEM_PROP_CANISTER);
    SetTrieValue(g_hTriePropItems, "weapon_propanetank",            ITEM_PROP_CANISTER);
    SetTrieValue(g_hTriePropItems, "weapon_oxygentank",             ITEM_PROP_CANISTER);
}

// SDK Calls
INIT_PrepareAllSDKCalls()
{
    g_confRaw = LoadGameConfigFile("l4d2_random");
    if (g_confRaw == INVALID_HANDLE)
            ThrowError("Could not load gamedata/l4d2_random.txt");
    
    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(g_confRaw, SDKConf_Signature, "SetClass");
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    g_setClass = EndPrepSDKCall();

    if (g_setClass == INVALID_HANDLE)
            ThrowError("Unable to find SetClass signature.");
    
    StartPrepSDKCall(SDKCall_Static);
    PrepSDKCall_SetFromConf(g_confRaw, SDKConf_Signature, "CreateAbility");
    PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
    PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
    g_createAbility = EndPrepSDKCall();

    if (g_createAbility == INVALID_HANDLE)
            ThrowError("Unable to find CreateAbility signature.");

    g_oAbility = GameConfGetOffset(g_confRaw, "oAbility");

    
    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(g_confRaw, SDKConf_Signature, "CTerrorPlayer_Fling");
    PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
    PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
    g_CallPushPlayer = EndPrepSDKCall();
    
    if (g_CallPushPlayer == INVALID_HANDLE)
            ThrowError("Unable to find the \"CTerrorPlayer_Fling\" signature.");
    
    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(g_confRaw, SDKConf_Signature, "CTerrorPlayer_OnHitByVomitJar");
    PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
    g_CallBileJarPlayer = EndPrepSDKCall();
    
    if (g_CallBileJarPlayer == INVALID_HANDLE)
        ThrowError("Unable to find the \"CTerrorPlayer_OnHitByVomitJar\" signature.");
    
    /*
    // vomit tracking
    StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "CTerrorPlayer_OnVomitedUpon");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	g_CallVomitSurvivor = EndPrepSDKCall();
	if(g_CallVomitSurvivor == INVALID_HANDLE)
	{
		SetFailState("Unable to find the \"CTerrorPlayer_OnVomitedUpon\" signature, check the file version!");
	}
    */
    
    CloseHandle(g_confRaw);
}


// melee weapon classes
// melee stuff
INIT_GetMeleeClasses()
{
    new String:sMeleeWeap[MELEE_CLASS_LENGTH];
    new MeleeNormalOrWeird: tMeleeType;
    
    new MeleeStringTable = FindStringTable("MeleeWeapons");
    new total = GetStringTableNumStrings(MeleeStringTable);
    new restrict = GetConVarBool(g_hCvarRestrictMelee);
    g_iMeleeClassCount = 0;
    
    for( new i = 0; i < total; i++ )
    {
        ReadStringTable(MeleeStringTable, i, sMeleeWeap, MELEE_CLASS_LENGTH);
        if (!GetTrieValue(g_hTrieMeleeType, sMeleeWeap, tMeleeType)) { continue; }
        
        // only add melee weapons that are 'safe', if cvar is set
        if (!restrict || tMeleeType == MELEE_NORMAL) {
            
            g_sMeleeClass[g_iMeleeClassCount] = sMeleeWeap;
            g_iMeleeClassCount++;
        }
    }
    
    PrintDebug("[rand] Read %i melee classes.", g_iMeleeClassCount);
}

/*
    not used?

INIT_GetScriptName( const String:Class[MELEE_CLASS_LENGTH], String:ScriptName[MELEE_CLASS_LENGTH] )
{
    for(new i = 0; i < g_iMeleeClassCount; i++) {
        if(StrContains( g_sMeleeClass[i], Class, false ) == 0) {
            Format( ScriptName, MELEE_CLASS_LENGTH, "%s", g_sMeleeClass[i] );
            return;
        }
    }
    Format(ScriptName, MELEE_CLASS_LENGTH, "%s", g_sMeleeClass[0]);     // waarom dit?
}
*/


// Precaching
INIT_PrecacheModels(bool: noMapStarted = false)
{
    for (new i=0; i < sizeof(g_csPreCacheModels); i++)
    {
        if (!IsModelPrecached(g_csPreCacheModels[i])) {
            PrecacheModel(g_csPreCacheModels[i], true);
        }
    }
    
    // Melee weapon scripts
    PrecacheGeneric("scripts/melee/baseball_bat.txt", true);
    PrecacheGeneric("scripts/melee/cricket_bat.txt", true);
    PrecacheGeneric("scripts/melee/crowbar.txt", true);
    PrecacheGeneric("scripts/melee/electric_guitar.txt", true);
    PrecacheGeneric("scripts/melee/fireaxe.txt", true);
    PrecacheGeneric("scripts/melee/frying_pan.txt", true);
    PrecacheGeneric("scripts/melee/golfclub.txt", true);
    PrecacheGeneric("scripts/melee/katana.txt", true);
    PrecacheGeneric("scripts/melee/machete.txt", true);
    PrecacheGeneric("scripts/melee/tonfa.txt", true);
    
    // Uncommon
    for (new i=0; i < sizeof(g_csUncommonModels); i++)
    {
        if (!IsModelPrecached(g_csUncommonModels[i])) {
            PrecacheModel(g_csUncommonModels[i], true);
        }
    }
    
    // Junk
    for (new i=0; i < sizeof(g_csJunkModels); i++)
    {
        if (!IsModelPrecached(g_csJunkModels[i])) {
            PrecacheModel(g_csJunkModels[i], true);
        }
    }
    
    // CSS weapons
    if (!noMapStarted) {
        for (new i=0; i < sizeof(g_csCSSWeapons); i++)
        {
            new tmpEnt = CreateEntityByName(g_csCSSWeapons[i]);
            DispatchSpawn(tmpEnt);
            RemoveEdict(tmpEnt);
        }
    }
    
    // Sound
    PrefetchSound(DOOR_SOUND);
    PrecacheSound(DOOR_SOUND, true);
    PrefetchSound(EXPLOSION_SOUND);
    PrecacheSound(EXPLOSION_SOUND, true);
    PrefetchSound(EXPLOSION_SOUND2);
    PrecacheSound(EXPLOSION_SOUND2, true);
    PrefetchSound(EXPLOSION_SOUND3);
    PrecacheSound(EXPLOSION_SOUND3, true);
    PrefetchSound(EXPLOSION_DEBRIS);
    PrecacheSound(EXPLOSION_DEBRIS, true);
    PrefetchSound(BOOMGIFT_SOUND);
    PrecacheSound(BOOMGIFT_SOUND, true);
    PrefetchSound(PANICGIFT_SOUND);
    PrecacheSound(PANICGIFT_SOUND, true);
    
    
    g_bModelsPrecached = true;
}

INIT_PrecacheParticles()
{
    // Particles
    INIT_PrecacheParticle(FIRE_PARTICLE);
    INIT_PrecacheParticle(EXPLOSION_PARTICLE);
    INIT_PrecacheParticle(EXPLOSION_PARTICLE2);
    INIT_PrecacheParticle(EXPLOSION_PARTICLE3);
    INIT_PrecacheParticle(BURN_IGNITE_PARTICLE);
}

INIT_PrecacheParticle(String:ParticleName[])
{
    new Particle = CreateEntityByName("info_particle_system");
    if(IsValidEntity(Particle) && IsValidEdict(Particle))
    {
        DispatchKeyValue(Particle, "effect_name", ParticleName);
        DispatchSpawn(Particle);
        ActivateEntity(Particle);
        AcceptEntityInput(Particle, "start");
        CreateTimer(0.3, INIT_Timer_RemovePrecacheParticle, Particle, TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Action:INIT_Timer_RemovePrecacheParticle(Handle:timer, any:Particle)
{
    if(IsValidEntity(Particle) && IsValidEdict(Particle))
    {
        AcceptEntityInput(Particle, "Kill");
    }
}