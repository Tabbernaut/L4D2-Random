#pragma semicolon 1
#include <sourcemod>


// note: these must also be defined in random_support
#define FIRE_PARTICLE           "gas_explosion_ground_fire"
#define EXPLOSION_PARTICLE      "FluidExplosion_fps"
#define EXPLOSION_PARTICLE2     "weapon_grenade_explosion"
#define EXPLOSION_PARTICLE3     "explosion_huge_b"
#define BURN_IGNITE_PARTICLE    "fire_small_01"

#define VOMIT_PARTICLE          "boomer_vomit"
#define FIRE_EXT_SPRAY          "extinguisher_spray"

INIT_DefineCVars()
{
    // ConVars
    
    g_hCvarDebug = CreateConVar(                            "rand_debug",                    "2",       "Random debug mode. (0: only error reporting, -1: disable all reports, 1+: set debug report level)", FCVAR_PLUGIN, true, -1.0, true, 5.0);
    g_hCvarConfogl = CreateConVar(                          "rand_confogl",                  "1",       "Whether random is loaded as a confogl matchmode (changes the way cvar defaults are read).", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarSimplePauseCheck = CreateConVar(                 "rand_simplepausecheck",         "1",       "Uses sv_pausable for a simple pause check.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarStripperMode = CreateConVar(                     "rand_stripper_mode",            "2",       "When using Stripper:Source: mode 0 = don't change dir; 1 = toggle standard and _alt (50%); 2 = standard + _alt (33%); 3 = same, but (25%).", FCVAR_PLUGIN, true, 0.0, true, 2.0);
    g_hCvarStripperPath = CreateConVar(                     "rand_stripper_path",            "addons/stripper", "The Stripper:Source directory random uses as its base.", FCVAR_PLUGIN);
    g_hCvarRIKeyValuesPath = CreateConVar(                  "rand_randominfo_path",          "configs/randommapinfo.txt", "The path to the randommap.txt with keyvalues for per-map random settings.", FCVAR_PLUGIN);
    g_hCvarRCKeyValuesPath = CreateConVar(                  "rand_randomconfig_path",        "configs/randomconfig.txt", "The path to the randomconfig.txt with keyvalues for its base settings.", FCVAR_PLUGIN);
    g_hCvarWelcomeMode = CreateConVar(                      "rand_welcome",                  "3",       "Whether to display welcome messages (1 = only in first round; 2 = always, 3 = each client only once).", FCVAR_PLUGIN, true, 0.0, true, 3.0);
    g_hCvarBlockL4D1Common = CreateConVar(                  "rand_no_l4d1_common",           "0",       "Whether to block L4D1 common. (2 = block all appearing l4d1 common; 3 = block only problematic skins)", FCVAR_PLUGIN, true, 0.0, true, 3.0);
    
    g_hCvarEqual = CreateConVar(                            "rand_equal",                 "2047",       "[Flags] What to keep equal between each team's survivor round (1: items; 2: doors; 4: glows; 8: event; 16: incaps; 32: horde; 64: item weighting; 128: starting health; 256: first attack; 512: tanks; 1024: scoring).", FCVAR_PLUGIN, true, 0.0, false);
    g_hCvarDoReport = CreateConVar(                         "rand_report",                   "1",       "Whether to do automatic reports at the start of a round.", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
    g_hCvarReportDelay = CreateConVar(                      "rand_report_delay",            "15",       "How many seconds after first survivor joins map to wait before reporting special event.", FCVAR_PLUGIN, true, 1.0, true, 120.0 );
    g_hCvarReportSackProt = CreateConVar(                   "rand_report_sackprotection",    "2",       "Whether sack-protection measures are reported to the relevant players (1: always; 2: only to offending player once)", FCVAR_PLUGIN, true, 0.0, true, 2.0 );
    g_hCvarRandomSpawns = CreateConVar(                     "rand_random_si",                "1",       "Whether SI spawns are fully random (or Valve-ordered).", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
    g_hCvarSackProtection = CreateConVar(                   "rand_si_sackprotection",        "1",       "Whether SI spawn sacking is punished (keeping a charger hoping to get a multi-charger attack, for instance).", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
    g_hCvarDeathOrderMode  = CreateConVar(                  "rand_si_deathorder",            "1",       "Death order mode: 0 = totally random; 1 = 3-spawn timeout with 60% repick rate; 2 = 4-spawn timeout with 100% repick rate.", FCVAR_PLUGIN, true, 0.0, true, 2.0 );
    g_hCvarDifficultyBalance = CreateConVar(                "rand_difficulty_balance",       "1",       "Whether round settings should be balanced according to estimated difficulty).", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
    g_hCvarM60Ammo = CreateConVar(                          "rand_m60_ammo",                "50",       "How much ammo an M60 spawns with.", FCVAR_PLUGIN, true, 0.0, false );
    g_hCvarClipFactorInc = CreateConVar(                    "rand_incendiary_ammo_factor",   "0.5",     "Incendiary ammo gives you a clip's normal size times this.", FCVAR_PLUGIN, true, 0.0, true, 2.0);
    g_hCvarClipFactorExp = CreateConVar(                    "rand_explosive_ammo_factor",    "0.25",    "Explosive ammo gives you a clip's normal size times this.", FCVAR_PLUGIN, true, 0.0, true, 2.0 );
    g_hCvarNoSupportSI = CreateConVar(                      "rand_only_cappers",             "0",       "If set, only allows cappers to spawn (useful for 2v2s 3v3s).", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarRestrictMelee = CreateConVar(                    "rand_restrict_melee",           "1",       "If set, only allows normal l4d2 melee weapons to spawn.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarRandomTank = CreateConVar(                       "rand_tank",                     "1",       "Whether player selection for tank is purely random.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarNoSpitterDuringTank = CreateConVar(              "rand_tank_nospitter",           "1",       "Block spitter while tank is up?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarBoomedTime = CreateConVar(                       "rand_boomed_time",             "10.0",     "The time window in seconds that boomer team-ups are rewarded (2+ boomers getting booms on different survivors). 0 = boomer combos are not rewarded.", FCVAR_PLUGIN, true, 0.0, true, 20.0);
    g_hCvarGnomeBonus = CreateConVar(                       "rand_gnome_bonus",              "0.25",    "The bonus given for bringing a gnome from start to end saferoom. (lower than 10 = amount of times distance, greater = static bonus)", FCVAR_PLUGIN, true, 0.0);
    g_hCvarGnomeFinaleFactor = CreateConVar(                "rand_gnome_finale_factor",      "0.5",     "The gnome bonus is worth this factor on finales.", FCVAR_PLUGIN, true, 0.0);
    g_hCvarGnomeAllowRandom = CreateConVar(                 "rand_gnome_random",             "0",       "Whether gnomes can drop at random (from gifts, common drops etc)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarSpecialEventTimeout = CreateConVar(              "rand_event_timeout",            "5",       "How many maps must be played before the same special event may be picked again.", FCVAR_PLUGIN, true, 0.0, false);
    g_hCvarBanTankFlows = CreateConVar(                     "rand_ban_tanks",                "1",       "Whether tank flow bans will be taken into account.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarRandomHittables = CreateConVar(                  "rand_hittables",                "1",       "Whether hittables should be randomized too.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarMiniTankHealth = CreateConVar(                   "rand_minitankhealth",        "1000",       "How much health minitanks have. This is two-thirds of its versus health (900 = 1350 in versus).", FCVAR_PLUGIN, true, 500.0, false);
    g_hCvarDoubleTankHealth = CreateConVar(                 "rand_doubletankhealth",      "3000",       "How much health each tank on a double-tank map has. (3000 = 4500 in versus).", FCVAR_PLUGIN, true, 1000.0, false);
    
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
    g_hCvarGiftPositiveChance = CreateConVar(               "rand_giftgood_chance",          "0.63",    "Chances of opening a gift resulting in something positive.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarPipeDudChance = CreateConVar(                    "rand_pipedud_chance",           "0.35",    "Chances of a pipebomb being a dud.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarAvoidIncapsChance = CreateConVar(                "rand_moreincaps_chance",        "0.35",    "If the incap count is only 1 (33%), odds that it gets set to 2 anyway.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarFinaleAmmoChance = CreateConVar(                 "rand_finale_ammo",              "0.0",     "Chances of finale ammo piles being randomized.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarAlarmedCarChance = CreateConVar(                 "rand_caralarm_chance",          "0.25",    "Chances of a car being alarmed.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarT2StartChance = CreateConVar(                    "rand_t2saferoom_chance",        "0.0",     "Chances of allowing tier 2 in start saferoom.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    
    g_hCvarFinaleItemUseful =  CreateConVar(                "rand_item_finale_useful",       "0.25",    "Factor by which non-useful items are adjusted for finale maps (lower = easier map).", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarStartItemNoJunk =  CreateConVar(                 "rand_item_start_nojunk",        "0.25",    "Chances items in start saferoom will be converted to something useful.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarStartItemAmmo =  CreateConVar(                   "rand_item_start_ammo",          "0.5",     "Chances that there will be at least one ammo pile in the start saferoom (if non are generated there).", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarStartItemGnome =  CreateConVar(                  "rand_item_start_gnome",         "0.25",    "Chances that there will be at least one gnome in the start saferoom (if non are generated there).", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarStartBalanceSurv = CreateConVar(                 "rand_item_start_balance_surv",  "1",       "If enabled, survivor handouts are adjusted based on the round's difficulty rating.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    
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
    
    g_hCvarAmmoAk = CreateConVar(                           "rand_ammo_ak",                 "250",      "Ammo for the AK47 in Random.", FCVAR_PLUGIN, true, 0.0, false);
    g_hCvarAmmoScout = CreateConVar(                        "rand_ammo_scout",              "150",      "Ammo for the Scout rifle in Random.", FCVAR_PLUGIN, true, 0.0, false);
    g_hCvarAmmoAWP = CreateConVar(                          "rand_ammo_awp",                 "90",      "Ammo for the AWP rifle in Random.", FCVAR_PLUGIN, true, 0.0, false);
    
    g_hArCvarWeight[INDEX_NOITEM] = CreateConVar(           "rand_weight_nothing",          "25",       "Weight for picking item spawns.",          FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarWeight[INDEX_PISTOL] = CreateConVar(           "rand_weight_pistol",           "13",       "Weight for picking item spawns.",          FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarWeight[INDEX_T1SMG] = CreateConVar(            "rand_weight_t1smg",            "16",       "Weight for picking item spawns.",          FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarWeight[INDEX_T1SHOTGUN] = CreateConVar(        "rand_weight_t1shotgun",        "16",       "Weight for picking item spawns.",          FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarWeight[INDEX_T2RIFLE] = CreateConVar(          "rand_weight_t2rifle",           "3",       "Weight for picking item spawns.",          FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarWeight[INDEX_T2SHOTGUN] = CreateConVar(        "rand_weight_t2shotgun",         "3",       "Weight for picking item spawns.",          FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarWeight[INDEX_SNIPER] = CreateConVar(           "rand_weight_sniper",            "6",       "Weight for picking item spawns.",          FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarWeight[INDEX_MELEE] = CreateConVar(            "rand_weight_melee",            "14",       "Weight for picking item spawns.",          FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarWeight[INDEX_T3] = CreateConVar(               "rand_weight_t3",                "3",       "Weight for picking item spawns.",          FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarWeight[INDEX_CANISTER] = CreateConVar(         "rand_weight_canister",         "18",       "Weight for picking item spawns.",          FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarWeight[INDEX_PILL] = CreateConVar(             "rand_weight_pill",             "16",       "Weight for picking item spawns.",          FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarWeight[INDEX_THROWABLE] = CreateConVar(        "rand_weight_throwable",         "8",       "Weight for picking item spawns.",          FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarWeight[INDEX_KIT] = CreateConVar(              "rand_weight_kit",              "11",       "Weight for picking item spawns.",          FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarWeight[INDEX_UPGRADE] = CreateConVar(          "rand_weight_upgrade",           "5",       "Weight for picking item spawns.",          FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarWeight[INDEX_AMMO] = CreateConVar(             "rand_weight_ammo",              "5",       "Weight for picking item spawns.",          FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarWeight[INDEX_JUNK] = CreateConVar(             "rand_weight_junk",             "18",       "Weight for picking item spawns.",          FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarWeight[INDEX_SILLY] = CreateConVar(            "rand_weight_silly",             "3",       "Weight for picking item spawns.",          FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarWeight[INDEX_GIFT] = CreateConVar(             "rand_weight_gift",              "3",       "Weight for picking item spawns.",          FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    
    g_hArCvarSurvWeight[INDEX_SURV_NOTHING] = CreateConVar( "rand_weight_surv_nothing",      "5",       "Weight for picking survivor starting gear.", FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarSurvWeight[INDEX_SURV_PISTOL] = CreateConVar(  "rand_weight_surv_pistol",      "15",       "Weight for picking survivor starting gear.", FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarSurvWeight[INDEX_SURV_DUALS] = CreateConVar(   "rand_weight_surv_duals",       "20",       "Weight for picking survivor starting gear.", FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarSurvWeight[INDEX_SURV_MAGNUM] = CreateConVar(  "rand_weight_surv_magnum",      "10",       "Weight for picking survivor starting gear.", FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarSurvWeight[INDEX_SURV_T1SMG] = CreateConVar(   "rand_weight_surv_t1smg",       "40",       "Weight for picking survivor starting gear.", FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarSurvWeight[INDEX_SURV_T1SHOT] = CreateConVar(  "rand_weight_surv_t1shotgun",   "40",       "Weight for picking survivor starting gear.", FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarSurvWeight[INDEX_SURV_MELEE] = CreateConVar(   "rand_weight_surv_melee",       "10",       "Weight for picking survivor starting gear.", FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    
    g_hArCvarEvtWeight[EVT_ITEM] = CreateConVar(            "rand_weight_evt_item",          "5",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_HORDE_HUGE] = CreateConVar(      "rand_weight_evt_horde",         "7",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_HORDE_NONE] = CreateConVar(      "rand_weight_evt_nohorde",       "7",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_UNCOMMON] = CreateConVar(        "rand_weight_evt_uncommon",      "4",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_CLOWNS] = CreateConVar(          "rand_weight_evt_circus",        "3",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_DOORS] = CreateConVar(           "rand_weight_evt_doors",         "6",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_QUADS] = CreateConVar(           "rand_weight_evt_quads",         "7",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_WEATHER] = CreateConVar(         "rand_weight_evt_storm",         "8",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_FOG] = CreateConVar(             "rand_weight_evt_fog",           "7",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_ABUNDANCE] = CreateConVar(       "rand_weight_evt_abundance",     "4",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_SNIPER] = CreateConVar(          "rand_weight_evt_sniper",        "5",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_GIFTS] = CreateConVar(           "rand_weight_evt_gifts",         "9",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_DEFIB] = CreateConVar(           "rand_weight_evt_defib",         "7",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_ADREN] = CreateConVar(           "rand_weight_evt_adren",         "7",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_NOHUD] = CreateConVar(           "rand_weight_evt_nohud",         "5",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_L4D1] = CreateConVar(            "rand_weight_evt_l4d1",          "6",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_FF] = CreateConVar(              "rand_weight_evt_ff",            "5",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_SILENCE] = CreateConVar(         "rand_weight_evt_sound",         "8",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_PEN_ITEM] = CreateConVar(        "rand_weight_evt_penitem",       "3",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_PEN_HEALTH] = CreateConVar(      "rand_weight_evt_penhealth",     "3",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_PEN_M2] = CreateConVar(          "rand_weight_evt_penm2",         "6",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_PEN_TIME] = CreateConVar(        "rand_weight_evt_pentime",       "3",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_MINITANKS] = CreateConVar(       "rand_weight_evt_minitanks",     "5",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_KEYMASTER] = CreateConVar(       "rand_weight_evt_keymaster",     "5",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_BADCOMBO] = CreateConVar(        "rand_weight_evt_badcombo",      "5",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_PROTECT] = CreateConVar(         "rand_weight_evt_protect",       "7",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_ENCUMBERED] = CreateConVar(      "rand_weight_evt_encumbered",    "5",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_BOOBYTRAP] = CreateConVar(       "rand_weight_evt_boobytrap",     "5",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_SKEET] = CreateConVar(           "rand_weight_evt_skeet",         "7",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_FIREPOWER] = CreateConVar(       "rand_weight_evt_firepower",     "5",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_AMMO] = CreateConVar(            "rand_weight_evt_ammo",          "5",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_WOMEN] = CreateConVar(           "rand_weight_evt_women",         "1",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_GUNSWAP] = CreateConVar(         "rand_weight_evt_gunswap",       "9",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_WITCHES] = CreateConVar(         "rand_weight_evt_witches",       "7",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_BADSANTA] = CreateConVar(        "rand_weight_evt_badgifts",      "4",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_MEDIC] = CreateConVar(           "rand_weight_evt_medic",         "7",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarEvtWeight[EVT_BOOMFLU] = CreateConVar(         "rand_weight_evt_boomerflu",     "6",       "Weight for picking special event.",        FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    
    g_hArCvarGiftWeight[GIFT_POS_HEALTH] = CreateConVar(    "rand_weight_gift_health",       "2",       "Weight for picking gift effects.",         FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarGiftWeight[GIFT_POS_HEALTH_T] = CreateConVar(  "rand_weight_gift_temphealth",   "2",       "Weight for picking gift effects.",         FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarGiftWeight[GIFT_POS_AMMO] = CreateConVar(      "rand_weight_gift_getammo",      "3",       "Weight for picking gift effects.",         FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarGiftWeight[GIFT_POS_ITEMS] = CreateConVar(     "rand_weight_gift_getitems",     "7",       "Weight for picking gift effects.",         FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarGiftWeight[GIFT_POS_LASER] = CreateConVar(     "rand_weight_gift_getlaser",     "2",       "Weight for picking gift effects.",         FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarGiftWeight[GIFT_POS_INSIGHT] = CreateConVar(   "rand_weight_gift_survinsight",  "3",       "Weight for picking gift effects.",         FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarGiftWeight[GIFT_NEG_VOMIT] = CreateConVar(     "rand_weight_gift_vomit",        "3",       "Weight for picking gift effects.",         FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarGiftWeight[GIFT_NEG_PANIC] = CreateConVar(     "rand_weight_gift_panic",        "3",       "Weight for picking gift effects.",         FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarGiftWeight[GIFT_NEG_ALLDROP] = CreateConVar(   "rand_weight_gift_alldrop",      "2",       "Weight for picking gift effects.",         FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarGiftWeight[GIFT_NEG_EXPLODE] = CreateConVar(   "rand_weight_gift_explode",      "3",       "Weight for picking gift effects.",         FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarGiftWeight[GIFT_NEG_FIRE] = CreateConVar(      "rand_weight_gift_fire",         "4",       "Weight for picking gift effects.",         FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    g_hArCvarGiftWeight[GIFT_NEG_INSIGHT] = CreateConVar(   "rand_weight_gift_infinsight",   "3",       "Weight for picking gift effects.",         FCVAR_PLUGIN, true, 0.0, true, 100.0 );
    
    
    // built in cvars (for tracking)
    g_hCvarReadyUp = FindConVar("l4d_ready_enabled");
    g_hCvarPausable = FindConVar("sv_pausable");
    
    // hook change of convar
    HookConVarChange(g_hCvarPausable, OnCvarPausableChanged);
}

INIT_CVarsGetDefault()
{
    if (g_bStripperPresent)
    {
        GetConVarString(FindConVar("stripper_cfg_path"), g_sStripperDir, sizeof(g_sStripperDir));
    }
    
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
    PrintDebug(3, "[rand] DEFIB PENALTY SAVED (= %i)", g_iDefDefibPenalty);
    //PBONUS_SetDefibPenalty(g_iDefDefibPenalty);
    
    g_iDefDefibDuration =       GetConVarInt(FindConVar("defibrillator_use_duration"));
    g_fDefPillDecayRate =       GetConVarFloat(FindConVar("pain_pills_decay_rate"));
    
    g_iTeamSize =               GetConVarInt(FindConVar("survivor_limit"));
    
    g_iDefSmokerLimit =         GetConVarInt(FindConVar("z_smoker_limit"));
    g_iDefBoomerLimit =         GetConVarInt(FindConVar("z_boomer_limit"));
    g_iDefHunterLimit =         GetConVarInt(FindConVar("z_hunter_limit"));
    g_iDefSpitterLimit =        GetConVarInt(FindConVar("z_spitter_limit"));
    g_iDefJockeyLimit =         GetConVarInt(FindConVar("z_jockey_limit"));
    g_iDefChargerLimit =        GetConVarInt(FindConVar("z_charger_limit"));
    
    g_iDefAmmoSmg =             GetConVarInt(FindConVar("ammo_smg_max"));
    g_iDefAmmoShotgun =         GetConVarInt(FindConVar("ammo_shotgun_max"));
    g_iDefAmmoHR =              GetConVarInt(FindConVar("ammo_huntingrifle_max"));
    g_iDefAmmoSniper =          GetConVarInt(FindConVar("ammo_sniperrifle_max"));
    g_iDefAmmoRifle =           GetConVarInt(FindConVar("ammo_assaultrifle_max"));
    g_iDefAmmoAutoShotgun =     GetConVarInt(FindConVar("ammo_autoshotgun_max"));
    
    g_fDefFFFactor =            GetConVarFloat(FindConVar("survivor_friendly_fire_factor_normal"));
    
    g_iDefTankHealth =          GetConVarInt(FindConVar("z_tank_health"));
    g_iDefTankFrustTime =       GetConVarInt(FindConVar("z_frustration_lifetime"));
    g_iDefTankDamage =          GetConVarInt(FindConVar("vs_tank_damage"));
    g_fDefTankFlowVariation =   GetConVarFloat(FindConVar("versus_tank_flow_team_variation"));
    
    g_iDefVomitInterval =       GetConVarInt(FindConVar("z_vomit_interval"));
    g_iDefSpitInterval =        GetConVarInt(FindConVar("z_spit_interval"));
    
    g_fDefCedaBileProb =        GetConVarFloat(FindConVar("sv_infected_ceda_vomitjar_probability"));
    g_fDefRiotTonfaProb =       GetConVarFloat(FindConVar("sv_infected_riot_control_tonfa_probability"));
    
    
    if (FindConVar("hc_car_standing_damage") != INVALID_HANDLE) {
        g_iDefTankHittableDamage =  GetConVarInt(FindConVar("hc_car_standing_damage"));
    }
}

INIT_CVarsReset()
{
    // reset cvars that we may have changed
    SetConVarInt(FindConVar("sv_force_time_of_day"), -1);
    SetConVarInt(FindConVar("sv_disable_glow_survivors"), 0);
    SetConVarInt(FindConVar("survivor_max_incapacitated_count"), INCAP_DEFAULT);
    
    // reset cvars for which we stored starting values (difficulty si/ci)
    EVENT_ResetDifficulty();
    EVENT_ResetOtherCvars();
    
    SetConVarString(FindConVar("stripper_cfg_path"), g_sStripperDir);
}

INIT_EventCycleTimeout()
{
    for (new i=0; i < EVT_TOTAL; i++)
    {
        if (g_iArEventTimeout[i] > 0)
        {
            g_iArEventTimeout[i]--;
        }
    }
}

INIT_StripperSwitch()
{
    // if we're randomly picking stripper directories
    //  called by onmapend every time
    new iStripperMode = GetConVarInt(g_hCvarStripperMode);
    
    if (!g_bStripperPresent || g_bCampaignMode) { return; }
    
    new String: sStripperDir[128] = "";
    GetConVarString(g_hCvarStripperPath, sStripperDir, sizeof(sStripperDir));
    
    switch (iStripperMode)
    {
        case 0: {   g_iStripperCurrentAlt = 0; }
        case 1: {   g_iStripperCurrentAlt = (GetRandomInt(0,1)) ? 0 : 1; }
        case 2: {   g_iStripperCurrentAlt = (GetRandomInt(0,2)) ? 0 : 1; }
        case 3: {   g_iStripperCurrentAlt = (GetRandomInt(0,3)) ? 0 : 1; }
    }
    
    Format(sStripperDir, sizeof(sStripperDir), "%s%s", sStripperDir, (g_iStripperCurrentAlt == 1) ? "_alt" : "");
    
    SetConVarString(FindConVar("stripper_cfg_path"), sStripperDir);
}


INIT_FillTries()
{
    // Tries
    g_hTrieCommands = CreateTrie();
    SetTrieValue(g_hTrieCommands, "!rand",          RANDOM_COMMAND);
    SetTrieValue(g_hTrieCommands, "!random",        RANDOM_COMMAND);
    //SetTrieValue(g_hTrieCommands, "!teamshuffle",   RANDOM_COMMAND);
    //SetTrieValue(g_hTrieCommands, "!randteams",     RANDOM_COMMAND);
    SetTrieValue(g_hTrieCommands, "!info",          RANDOM_COMMAND);
    SetTrieValue(g_hTrieCommands, "!drop",          RANDOM_COMMAND);
    SetTrieValue(g_hTrieCommands, "!bonus",         RANDOM_COMMAND);
    SetTrieValue(g_hTrieCommands, "!penalty",       RANDOM_COMMAND);
    SetTrieValue(g_hTrieCommands, "!spectate",      RANDOM_COMMAND_SPECTATE);
    
    g_hTrieEntityCreated = CreateTrie();                                                                                            // classname trie for checking OnEntityCreated()
    SetTrieValue(g_hTrieEntityCreated, "infected",                                  CREATED_INFECTED);
    SetTrieValue(g_hTrieEntityCreated, "pipe_bomb_projectile",                      CREATED_PIPEBOMB);
    SetTrieValue(g_hTrieEntityCreated, "physics_prop",                              CREATED_PROP_PHYSICS);
    SetTrieValue(g_hTrieEntityCreated, "upgrade_ammo_explosive",                    CREATED_AMMO_DEPLOYED);
    SetTrieValue(g_hTrieEntityCreated, "upgrade_ammo_incendiary",                   CREATED_AMMO_DEPLOYED);
    SetTrieValue(g_hTrieEntityCreated, "witch",                                     CREATED_WITCH);
    
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
    SetTrieValue(g_hTrieRandomizableEntity, "prop_fuel_barrel",                     RANDOMIZABLE_ITEM);
    
    SetTrieValue(g_hTrieRandomizableEntity, "prop_physics",                         RANDOMIZABLE_PHYSICS);
    
    g_hTrieRandomizablePropPhysicsModel = CreateTrie();                                                                             // cant go around turning EVERY prop_physics into crazy things
    SetTrieValue(g_hTrieRandomizablePropPhysicsModel, "models/props_junk/gascan001a.mdl",               RANDOMIZABLE_PHYSICS);
    SetTrieValue(g_hTrieRandomizablePropPhysicsModel, "models/props_junk/propanecanister001a.mdl",      RANDOMIZABLE_PHYSICS);
    SetTrieValue(g_hTrieRandomizablePropPhysicsModel, "models/props_equipment/oxygentank01.mdl",        RANDOMIZABLE_PHYSICS);
    SetTrieValue(g_hTrieRandomizablePropPhysicsModel, "models/props/cs_office/Fire_Extinguisher.mdl",   RANDOMIZABLE_PHYSICS);
    SetTrieValue(g_hTrieRandomizablePropPhysicsModel, "models/props_junk/gnome.mdl",                    RANDOMIZABLE_PHYSICS);
    SetTrieValue(g_hTrieRandomizablePropPhysicsModel, "models/props_junk/explosive_box001.mdl",         RANDOMIZABLE_PHYSICS);
    
    SetTrieValue(g_hTrieRandomizablePropPhysicsModel, "models/props_vehicles/cara_69sedan.mdl",             HITTABLE_PHYSICS_CAR);
    SetTrieValue(g_hTrieRandomizablePropPhysicsModel, "models/props_vehicles/cara_69sedan_glass.mdl",       HITTABLE_PHYSICS_ADDON);
    SetTrieValue(g_hTrieRandomizablePropPhysicsModel, "models/props_vehicles/cara_82hatchback.mdl",         HITTABLE_PHYSICS_CAR);
    SetTrieValue(g_hTrieRandomizablePropPhysicsModel, "models/props_vehicles/cara_82hatchback_glass.mdl",   HITTABLE_PHYSICS_ADDON);
    SetTrieValue(g_hTrieRandomizablePropPhysicsModel, "models/props_vehicles/cara_84sedan.mdl",             HITTABLE_PHYSICS_CAR);
    SetTrieValue(g_hTrieRandomizablePropPhysicsModel, "models/props_vehicles/cara_84sedan_glass.mdl",       HITTABLE_PHYSICS_ADDON);
    SetTrieValue(g_hTrieRandomizablePropPhysicsModel, "models/props_vehicles/cara_95sedan.mdl",             HITTABLE_PHYSICS_CAR);
    SetTrieValue(g_hTrieRandomizablePropPhysicsModel, "models/props_vehicles/cara_95sedan_glass.mdl",       HITTABLE_PHYSICS_ADDON);
    SetTrieValue(g_hTrieRandomizablePropPhysicsModel, "models/props_vehicles/cara_82hatchback_wrecked.mdl", HITTABLE_PHYSICS_CAR);
    SetTrieValue(g_hTrieRandomizablePropPhysicsModel, "models/props_vehicles/cara_95sedan_wrecked.mdl",     HITTABLE_PHYSICS_CAR);
    SetTrieValue(g_hTrieRandomizablePropPhysicsModel, "models/props_vehicles/police_car_city.mdl",          HITTABLE_PHYSICS_CAR_TURNED);  // share city_glass
    SetTrieValue(g_hTrieRandomizablePropPhysicsModel, "models/props_vehicles/police_car_rural.mdl",         HITTABLE_PHYSICS_CAR_TURNED);  // share city_glass
    SetTrieValue(g_hTrieRandomizablePropPhysicsModel, "models/props_vehicles/police_car_city_glass.mdl",    HITTABLE_PHYSICS_ADDON);
    SetTrieValue(g_hTrieRandomizablePropPhysicsModel, "models/props_vehicles/taxi_city.mdl",                HITTABLE_PHYSICS_CAR_TURNED);  // share city_glass
    SetTrieValue(g_hTrieRandomizablePropPhysicsModel, "models/props_vehicles/taxi_rural.mdl",               HITTABLE_PHYSICS_CAR_TURNED);  // share city_glass
    SetTrieValue(g_hTrieRandomizablePropPhysicsModel, "models/props_vehicles/taxi_city_glass.mdl",          HITTABLE_PHYSICS_ADDON);
    SetTrieValue(g_hTrieRandomizablePropPhysicsModel, "models/props/cs_assault/forklift.mdl",               HITTABLE_PHYSICS_TURNED);
    SetTrieValue(g_hTrieRandomizablePropPhysicsModel, "models/props_vehicles/airport_baggage_cart2.mdl",    HITTABLE_PHYSICS_TURNED);
    SetTrieValue(g_hTrieRandomizablePropPhysicsModel, "models/props_foliage/swamp_fallentree01_bare.mdl",   HITTABLE_PHYSICS_SMALL_TURNED);
    SetTrieValue(g_hTrieRandomizablePropPhysicsModel, "models/props_foliage/tree_trunk_fallen.mdl",         HITTABLE_PHYSICS_SMALL_TURNED);
    SetTrieValue(g_hTrieRandomizablePropPhysicsModel, "models/props_vehicles/generatortrailer01.mdl",       HITTABLE_PHYSICS_SMALL);
    SetTrieValue(g_hTrieRandomizablePropPhysicsModel, "models/props_junk/dumpster.mdl",                     HITTABLE_PHYSICS_SMALL_TURNED);
    SetTrieValue(g_hTrieRandomizablePropPhysicsModel, "models/props_junk/dumpster_2.mdl",                   HITTABLE_PHYSICS_SMALL_TURNED);
    SetTrieValue(g_hTrieRandomizablePropPhysicsModel, "models/props_fairgrounds/bumpercar.mdl",             HITTABLE_PHYSICS_SMALL);
    SetTrieValue(g_hTrieRandomizablePropPhysicsModel, "models/props_fairgrounds/bumpercar_pole.mdl",        HITTABLE_PHYSICS_ADDON);
    
    SetTrieValue(g_hTrieRandomizablePropPhysicsModel, "models/props_unique/haybails_single.mdl",            HITTABLE_PHYSICS_SMALL_TURNED);
    
    
    g_hTrieMeleeType = CreateTrie();                                                                                                // classname trie for finding 'normal' melees
    SetTrieValue(g_hTrieMeleeType, "fireaxe",                       MELEE_NORMAL);
    SetTrieValue(g_hTrieMeleeType, "frying_pan",                    MELEE_NORMAL);
    SetTrieValue(g_hTrieMeleeType, "machete",                       MELEE_NORMAL);
    SetTrieValue(g_hTrieMeleeType, "baseball_bat",                  MELEE_NORMAL);
    SetTrieValue(g_hTrieMeleeType, "crowbar",                       MELEE_NORMAL);
    SetTrieValue(g_hTrieMeleeType, "cricket_bat",                   MELEE_NORMAL);
    SetTrieValue(g_hTrieMeleeType, "tonfa",                         MELEE_NORMAL);
    SetTrieValue(g_hTrieMeleeType, "katana",                        MELEE_NORMAL);
    SetTrieValue(g_hTrieMeleeType, "electric_guitar",               MELEE_NORMAL);
    SetTrieValue(g_hTrieMeleeType, "golfclub",                      MELEE_NORMAL);
    SetTrieValue(g_hTrieMeleeType, "hunting_knife",                 MELEE_WEIRD);
    
    g_hTrieBlindable = CreateTrie();
    SetTrieValue(g_hTrieBlindable, "predicted_viewmodel",           ENTITY_NOT_BLINDABLE);
    SetTrieValue(g_hTrieBlindable, "instanced_scripted_scene",      ENTITY_NOT_BLINDABLE);
    SetTrieValue(g_hTrieBlindable, "func_occluder",                 ENTITY_NOT_BLINDABLE);
    SetTrieValue(g_hTrieBlindable, "ability_vomit",                 ENTITY_NOT_BLINDABLE);
    
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
    SetTrieValue(g_hTriePenaltyItems, "weapon_pistol_magnum",       ITEM_PICKUP_PENALTY_MAGNUM);
    SetTrieValue(g_hTriePenaltyItems, "weapon_chainsaw",            ITEM_PICKUP_PENALTY_SAW);
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
    //SetTrieValue(g_hTriePenaltyItems, "fireworkcrate",              ITEM_PICKUP_CANISTER);
    //SetTrieValue(g_hTriePenaltyItems, "gascan",                     ITEM_PICKUP_CANISTER);
    //SetTrieValue(g_hTriePenaltyItems, "propanetank",                ITEM_PICKUP_CANISTER);
    //SetTrieValue(g_hTriePenaltyItems, "oxygentank",                 ITEM_PICKUP_CANISTER);
    
    g_hTriePropItems = CreateTrie();
    SetTrieValue(g_hTriePropItems, "weapon_gnome",                  ITEM_PROP_GNOME);
    SetTrieValue(g_hTriePropItems, "weapon_cola_bottles",           ITEM_PROP_COLA);
    SetTrieValue(g_hTriePropItems, "weapon_gascan",                 ITEM_PROP_CANISTER);
    SetTrieValue(g_hTriePropItems, "weapon_fireworkcrate",          ITEM_PROP_CANISTER);
    SetTrieValue(g_hTriePropItems, "weapon_propanetank",            ITEM_PROP_CANISTER);
    SetTrieValue(g_hTriePropItems, "weapon_oxygentank",             ITEM_PROP_CANISTER);
    
    g_hTrieUseItems = CreateTrie();
    SetTrieValue(g_hTrieUseItems, "prop_door_rotating",             ITEM_USE_DOOR);
    SetTrieValue(g_hTrieUseItems, "weapon_cola_bottles",            ITEM_USE_COLA);
    SetTrieValue(g_hTrieUseItems, "prop_physics",                   ITEM_USE_PROP);
    SetTrieValue(g_hTrieUseItems, "weapon_ammo_spawn",              ITEM_USE_AMMO);
    
    g_hTrieDropItems = CreateTrie();
    SetTrieValue(g_hTrieDropItems, "cola_bottles",                  ITEM_DROP_COLA);
    SetTrieValue(g_hTrieDropItems, "pain_pills",                    ITEM_DROP_HEALTH);
    SetTrieValue(g_hTrieDropItems, "first_aid_kit",                 ITEM_DROP_HEALTH);
    SetTrieValue(g_hTrieDropItems, "weapon_pain_pills",             ITEM_DROP_WEAPPILLS);
    SetTrieValue(g_hTrieDropItems, "weapon_first_aid_kit",          ITEM_DROP_WEAPKIT);
    
    g_hTrieL4D1Common = CreateTrie();
    SetTrieValue(g_hTrieL4D1Common, "models/infected/common_male01.mdl",            COMMON_L4D1_PROBSKIN);
    SetTrieValue(g_hTrieL4D1Common, "models/infected/common_female01.mdl",          COMMON_L4D1_PROBSKIN);
    SetTrieValue(g_hTrieL4D1Common, "models/infected/common_male_rural01.mdl",      COMMON_L4D1_PROBSKIN);
    SetTrieValue(g_hTrieL4D1Common, "models/infected/common_female_rural01.mdl",    COMMON_L4D1_PROBSKIN);
    SetTrieValue(g_hTrieL4D1Common, "models/infected/common_male_suit.mdl",         COMMON_L4D1_PROBSKIN);
    SetTrieValue(g_hTrieL4D1Common, "models/infected/common_worker_male01.mdl",     COMMON_L4D1);
    SetTrieValue(g_hTrieL4D1Common, "models/infected/common_military_male01.mdl",   COMMON_L4D1);
    SetTrieValue(g_hTrieL4D1Common, "models/infected/common_police_male01.mdl",     COMMON_L4D1);
    SetTrieValue(g_hTrieL4D1Common, "models/infected/common_surgeon_male01.mdl",    COMMON_L4D1);
    SetTrieValue(g_hTrieL4D1Common, "models/infected/common_female_nurse01.mdl",    COMMON_L4D1);
    SetTrieValue(g_hTrieL4D1Common, "models/infected/common_male_pilot.mdl",        COMMON_L4D1);
    SetTrieValue(g_hTrieL4D1Common, "models/infected/common_male_baggagehandler_01.mdl", COMMON_L4D1);
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
    
    // vomit tracking
    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(g_confRaw, SDKConf_Signature, "CTerrorPlayer_OnVomitedUpon");
    PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    g_CallVomitSurvivor = EndPrepSDKCall();
    if (g_CallVomitSurvivor == INVALID_HANDLE)
            SetFailState("Unable to find the \"CTerrorPlayer_OnVomitedUpon\" signature.");
    
    
    new Handle: confRaw_b = LoadGameConfigFile("left4downtown.l4d2");
    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(confRaw_b, SDKConf_Signature, "SetHumanSpec");
    PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
    g_CallSHS = EndPrepSDKCall();
    
    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(confRaw_b, SDKConf_Signature, "TakeOverBot");
    PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
    g_CallTOB = EndPrepSDKCall();

    
    CloseHandle(g_confRaw);
    CloseHandle(confRaw_b);
}



// KeyValues for random's map properties
// -------------------------------------
RI_KV_Close()
{
    if (g_kRIData == INVALID_HANDLE) { return; }
    CloseHandle(g_kRIData);
    g_kRIData = INVALID_HANDLE;
}

RI_KV_Load()
{
    decl String:sNameBuff[PLATFORM_MAX_PATH];
    
    GetConVarString(g_hCvarRIKeyValuesPath, sNameBuff, sizeof(sNameBuff));
    
    g_kRIData = CreateKeyValues("RandomMap");
    BuildPath(Path_SM, sNameBuff, sizeof(sNameBuff), sNameBuff);
    
    if (!FileToKeyValues(g_kRIData, sNameBuff))
    {
        LogError("[RI] Couldn't load RandomMapInfo data!");
        RI_KV_Close();
        return;
    }
}

bool: RI_KV_UpdateRandomMapInfo()
{
    g_RI_bIsIntro = false;          // whether the map is the first of campaign
    g_RI_bIsFinale = false;         // whether map is finale of campaign
    g_RI_iDifficulty = 0;           // difficulty offset for map
    g_RI_iDoors = 1;                // normal doors amount (2 = many, 0 = no doors)
    g_RI_bNoTank = false;           // whether we should block tanks
    g_RI_bNoTankVar = false;        // whether we should set tank variation to 0
    g_RI_bNoWitch = false;          // whether we should block witches
    g_RI_iNoStorm = 0;              // whether there shouldn't be storms on the map
    g_RI_bNoRain = false;
    g_RI_bNoCola = false;           // whether we should block cola on the map
    g_RI_bWeakHittables = false;    // map works like c5m5
    g_RI_iDistance = 0;             // if > 0, the map's normal distance
    g_RI_iDistanceHard = 0;         // if > 0, the map's hard-path distance
    
    g_RI_iTankBanStart = -1;        // block some tank spawns
    g_RI_iTankBanEnd = -1;
    
    new String: mapname[64];
    GetCurrentMap(mapname, sizeof(mapname));
    
    if (L4D_IsMissionFinalMap()) { g_RI_bIsFinale = true; }
    
    // get keyvalues
    if (KvJumpToKey(g_kRIData, mapname))
    {
        g_RI_bIsIntro = bool: (KvGetNum(g_kRIData, "intro", 0));
        g_RI_iDifficulty = KvGetNum(g_kRIData, "difficulty", g_RI_iDifficulty);
        g_RI_iDoors = KvGetNum(g_kRIData, "doors", g_RI_iDoors);
        g_RI_bNoTank = bool: (KvGetNum(g_kRIData, "no_tank", 0));
        g_RI_bNoTankVar = bool: (KvGetNum(g_kRIData, "no_tank_var", 0));
        g_RI_bNoWitch = bool: (KvGetNum(g_kRIData, "no_witch", 0));
        g_RI_iNoStorm = KvGetNum(g_kRIData, "no_storm", g_RI_iNoStorm);
        g_RI_bNoRain = bool: (KvGetNum(g_kRIData, "no_rain", 0));
        g_RI_bNoCola = bool: (KvGetNum(g_kRIData, "no_cola", 0));
        g_RI_iTankBanStart = KvGetNum(g_kRIData, "tank_ban_start", -1);
        g_RI_iTankBanEnd = KvGetNum(g_kRIData, "tank_ban_end", -1);
        g_RI_bWeakHittables = bool: (KvGetNum(g_kRIData, "weak_hittables", 0));
        g_RI_iDistance = KvGetNum(g_kRIData, "distance", g_RI_iDistance);
        g_RI_iDistanceHard = KvGetNum(g_kRIData, "distance_hard", g_RI_iDistanceHard);
        
        if (KvGetNum(g_kRIData, "no_finale", 0)) { g_RI_bIsFinale = false; }
        
        PrintDebug(1, "[RI] Read data: intro: %i; difficulty: %i; doors; %i; nostorm: %i", g_RI_bIsIntro, g_RI_iDifficulty, g_RI_iDoors, g_RI_iNoStorm);
        
        return true;
    }
    
    // no keyvalue set found for map:
    LogMessage("[RI] RandomMapInfo for '%s' is missing.", mapname);
    
    // if no data found, set default stuff we should assume
    if (g_RI_bIsFinale)
    {
        g_RI_iDifficulty = 2;
        g_RI_iDoors = 0;
    }
    
    return false;
}


// KayValues for general random config
// -----------------------------------
RConfig_Read()
{
    decl String:sNameBuff[PLATFORM_MAX_PATH];
    
    GetConVarString(g_hCvarRCKeyValuesPath, sNameBuff, sizeof(sNameBuff));
    
    new Handle: kRCData = CreateKeyValues("RandomConfig");
    BuildPath(Path_SM, sNameBuff, sizeof(sNameBuff), sNameBuff);
    
    if (!FileToKeyValues(kRCData, sNameBuff))
    {
        LogError("[rand] Couldn't load RandomConfig data!");
        if (kRCData == INVALID_HANDLE) { return; }
        CloseHandle(kRCData);
        return;
    }
    
    // get keyvalues
    if (KvJumpToKey(kRCData, "settings"))
    {
        // read out all the values into global variables here
        // name format: g_RC_<normal>
        g_RC_fItemFactor2v2 = KvGetFloat(kRCData, "item_factor_2v2", g_RC_fItemFactor2v2);
        g_RC_fItemFactor3v3 = KvGetFloat(kRCData, "item_factor_3v3", g_RC_fItemFactor3v3);
        g_RC_iGiftMinItems = KvGetNum(kRCData, "gift_min_items", g_RC_iGiftMinItems);
        g_RC_iGiftMaxItems = KvGetNum(kRCData, "gift_max_items", g_RC_iGiftMaxItems);
        
        g_RC_iMultiwitchMin = KvGetNum(kRCData, "multiwitch_min", g_RC_iMultiwitchMin);
        g_RC_iMultiwitchMax = KvGetNum(kRCData, "multiwitch_max", g_RC_iMultiwitchMax);
        g_RC_bMultiwitchAllowTank = bool: (KvGetNum(kRCData, "multiwitch_allow_tank", 1));
        g_RC_iMinitanksNum = KvGetNum(kRCData, "minitanks_num", g_RC_iMinitanksNum);
        g_RC_fMinitankMeleeDmg = KvGetFloat(kRCData, "minitank_melee_damage", g_RC_fMinitankMeleeDmg);
        g_RC_iMinitankFrustTime = KvGetNum(kRCData, "minitank_frustration_time", g_RC_iMinitankFrustTime);
        g_RC_iMinitankDamage = KvGetNum(kRCData, "minitank_damage", g_RC_iMinitankDamage);
        g_RC_iMinitankHittableDmg = KvGetNum(kRCData, "minitank_hittable_damage", g_RC_iMinitankHittableDmg);
        g_RC_iWeakHittableDmg = KvGetNum(kRCData, "weak_hittable_damage", g_RC_iWeakHittableDmg);
        
        g_RC_iTankDropItemsMin = KvGetNum(kRCData, "tank_drop_items_min", g_RC_iTankDropItemsMin);
        g_RC_iTankDropItemsMax = KvGetNum(kRCData, "tank_drop_items_max", g_RC_iTankDropItemsMax);
        g_RC_fBoomComboDudChance = KvGetFloat(kRCData, "boomcombo_dud_chance", g_RC_fBoomComboDudChance);
        
        g_RC_fEventSITimeVeryHard = KvGetFloat(kRCData, "event_sitime_veryhard", g_RC_fEventSITimeVeryHard);
        g_RC_fEventSITimeHard = KvGetFloat(kRCData, "event_sitime_hard", g_RC_fEventSITimeHard);
        g_RC_fEventSITimeEasy = KvGetFloat(kRCData, "event_sitime_easy", g_RC_fEventSITimeEasy);
        g_RC_fEventSITimeVeryEasy = KvGetFloat(kRCData, "event_sitime_veryeasy", g_RC_fEventSITimeVeryEasy);
        
        g_RC_fEventCILimVeryHard = KvGetFloat(kRCData, "event_cilim_veryhard", g_RC_fEventCILimVeryHard);
        g_RC_fEventCILimHard = KvGetFloat(kRCData, "event_cilim_hard", g_RC_fEventCILimHard);
        g_RC_fEventCILimEasy = KvGetFloat(kRCData, "event_cilim_easy", g_RC_fEventCILimEasy);
        g_RC_fEventCILimVeryEasy = KvGetFloat(kRCData, "event_cilim_veryeasy", g_RC_fEventCILimVeryEasy);
        g_RC_fEventCILimSuperEasy = KvGetFloat(kRCData, "event_cilim_Supereasy", g_RC_fEventCILimSuperEasy);

        g_RC_iEventPenaltyItem = KvGetNum(kRCData, "event_penalty_item", g_RC_iEventPenaltyItem);
        g_RC_iEventPenaltyHealth = KvGetNum(kRCData, "event_penalty_health", g_RC_iEventPenaltyHealth);
        g_RC_iEventPenaltyM2SI = KvGetNum(kRCData, "event_penalty_m2si", g_RC_iEventPenaltyM2SI);
        g_RC_iEventPenaltyTime = KvGetNum(kRCData, "event_penalty_time", g_RC_iEventPenaltyTime);
        g_RC_iEventBonusSkeet = KvGetNum(kRCData, "event_bonus_skeet", g_RC_iEventBonusSkeet);
        g_RC_iEventBonusSkeetTeam = KvGetNum(kRCData, "event_bonus_skeet_team", g_RC_iEventBonusSkeetTeam);
        g_RC_iEventBonusWitch = KvGetNum(kRCData, "event_bonus_witch", g_RC_iEventBonusWitch);
        g_RC_iEventBonusBadSanta = KvGetNum(kRCData, "event_bonus_badsanta", g_RC_iEventBonusBadSanta);

        g_RC_fEventAdrenDecay = KvGetFloat(kRCData, "event_adren_decay", g_RC_fEventAdrenDecay);
        g_RC_fEventWomenMeleeDmg = KvGetFloat(kRCData, "event_women_melee_dmg", g_RC_fEventWomenMeleeDmg);
        g_RC_fEventWomenWitchDmg = KvGetFloat(kRCData, "event_women_witch_dmg", g_RC_fEventWomenWitchDmg);
        g_RC_fEventWitchesWitchDmg = KvGetFloat(kRCData, "event_witches_witch_dmg", g_RC_fEventWitchesWitchDmg);
        g_RC_fEventFFFactor = KvGetFloat(kRCData, "event_ff_factor", g_RC_fEventFFFactor);
        g_RC_iEventBadComboAmmo = KvGetNum(kRCData, "event_badcombo_ammo", g_RC_iEventBadComboAmmo);
        g_RC_fEventProtectWeak = KvGetFloat(kRCData, "event_protect_weak_factor", g_RC_fEventProtectWeak);
        g_RC_fEventProtectStrong = KvGetFloat(kRCData, "event_protect_strong_factor", g_RC_fEventProtectStrong);
        g_RC_fEventBoobyTrapChance = KvGetFloat(kRCData, "event_boobytrap_chance", g_RC_fEventBoobyTrapChance);
        g_RC_iEventBoobyTrapMin = KvGetNum(kRCData, "event_boobytrap_min", g_RC_iEventBoobyTrapMin);
        g_RC_fEventAmmoMaxFactor = KvGetFloat(kRCData, "event_ammo_factor_max", g_RC_fEventAmmoMaxFactor);
        g_RC_fEventAmmoFactor = KvGetFloat(kRCData, "event_ammo_factor", g_RC_fEventAmmoFactor);
        g_RC_fEventWitchesSpawnFreq = KvGetFloat(kRCData, "event_witches_spawntime", g_RC_fEventWitchesSpawnFreq);
        g_RC_iEventBoomFluMinInt = KvGetNum(kRCData, "event_boomflu_interval_min", g_RC_iEventBoomFluMinInt);
        g_RC_iEventBoomFluMaxInt = KvGetNum(kRCData, "event_boomflu_interval_max", g_RC_iEventBoomFluMaxInt);
        
        g_RC_iVomitOnType = KvGetNum(kRCData, "vomit_on_type", g_RC_iVomitOnType);
        g_RC_fVomitRange = KvGetFloat(kRCData, "vomit_range", g_RC_fVomitRange);
        g_RC_fVomitStreamTime = KvGetFloat(kRCData, "vomit_stream_time", g_RC_fVomitStreamTime);
        
        g_RC_fExplosionPowerHigh = KvGetFloat(kRCData, "explosion_power_high", g_RC_fExplosionPowerHigh);
        g_RC_fExplosionPowerLow = KvGetFloat(kRCData, "explosion_power_low", g_RC_fExplosionPowerLow);
        
        // extra options
        g_RC_bExtraCommonModels = bool: (KvGetNum(kRCData, "extra_common_models", 1));
        
        PrintDebug(2, "[rand] Read config data.");
        
        return;
    }
    
    // no keyvalue set found for map:
    LogMessage("[rand] RandomConfig data missing.");
    
    
    if (kRCData == INVALID_HANDLE) { return; }
    CloseHandle(kRCData);    
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
    
    PrintDebug(2, "[rand] Read %i melee classes.", g_iMeleeClassCount);
}

/*
    // not used?
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
    
    // Common
    for (new i=0; i < sizeof(g_csFemaleCommonModels); i++)
    {
        if (!IsModelPrecached(g_csFemaleCommonModels[i])) {
            PrecacheModel(g_csFemaleCommonModels[i], true);
        }
    }
    for (new i=0; i < sizeof(g_csL4D1CommonModels); i++)
    {
        if (!IsModelPrecached(g_csL4D1CommonModels[i])) {
            PrecacheModel(g_csL4D1CommonModels[i], true);
        }
    }
    
    // Hittables
    for (new i=0; i < sizeof(g_csHittableModels); i++)
    {
        if (!IsModelPrecached(g_csHittableModels[i])) {
            PrecacheModel(g_csHittableModels[i], true);
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
    
    // Alarmed cars
    if (!IsModelPrecached("sprites/glow.vmt")) PrecacheModel("sprites/glow.vmt", true);
    if (!IsModelPrecached("sprites/light_glow03.vmt")) PrecacheModel("sprites/light_glow03.vmt", true);
    if (!IsModelPrecached("sprites/glow_test02.vmt")) PrecacheModel("sprites/glow_test02.vmt", true);
    
    // Sound
    for (new i=0; i < sizeof(g_csPrefetchSounds); i++)
    {
        PrefetchSound(g_csPrefetchSounds[i]);
        PrecacheSound(g_csPrefetchSounds[i], true);
    }
    
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
    INIT_PrecacheParticle(VOMIT_PARTICLE);
    INIT_PrecacheParticle(FIRE_EXT_SPRAY);
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
