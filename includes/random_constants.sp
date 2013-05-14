#pragma semicolon 1


const           DEBUG_MODE              = 1;

const           TEAM_SPECTATOR          = 1;
const           TEAM_SURVIVOR           = 2;
const           TEAM_INFECTED           = 3;
const           PLAYER_SLOT_SECONDARY   = 1;
const           PLAYER_SLOT_PRIMARY     = 0;    // 2?

const           ASSAULT_RIFLE_OFFSET_IAMMO      = 12;
const           SMG_OFFSET_IAMMO                = 20;
const           SHOTGUN_OFFSET_IAMMO            = 28;
const           AUTO_SHOTGUN_OFFSET_IAMMO       = 32;
const           SNIPER_OFFSET_IAMMO             = 36;
const           MILITARY_SNIPER_OFFSET_IAMMO    = 40;
const           GRENADE_LAUNCHER_OFFSET_IAMMO   = 68;

const           ZC_SMOKER               = 1;
const           ZC_BOOMER               = 2;
const           ZC_HUNTER               = 3;
const           ZC_SPITTER              = 4;
const           ZC_JOCKEY               = 5;
const           ZC_CHARGER              = 6;
const           ZC_WITCH                = 7;
const           ZC_TANK                 = 8;
const           ZC_NOTINFECTED          = 9;
const           ZC_TOTAL                = 7;

const Float:    ZC_TIMEROFFSET          = 0.5;
const Float:    ZC_TIMERDEATHCHECK      = 0.05;
const Float:    ZC_TIMERAFTERTANK       = 0.01;
const Float:    ZC_TIMERCHECKGHOST      = 0.05;         // was 0.1 for ZCS .. bit annoying though

const           WEPID_PILLS             = 15;           // for pickup checks
const           WEPID_ADREN             = 23;

const           INCAP_DEFAULT           = 2;
const           INCAP_MINIMUM           = 1;
const           INCAP_MAXIMUM           = 3;
const           HEALTH_MAXIMUM          = 100;

const           TEAM_SIZE               = 4;
const           ENTITY_COUNT            = 2048;
const           MELEE_CLASS_COUNT       = 32;
const           MELEE_CLASS_LENGTH      = 32;
const           STORED_MAX_COUNT        = 1024;         // just arbitrary, users shouldn't exceed this total
const           STORED_SURV_MAX_COUNT   = 256;          // just arbitrary, users shouldn't exceed this total
const           GNOME_MAX_COUNT         = 128;          // just arbitrary, users shouldn't exceed this total (because why make gnome heaven?)
const           MAX_REPORTLINES         = 15;
const           REPLINELENGTH           = 256;          // maximum length of a 'report line'
const Float:    TIMER_HUMANCHECK        = 2.0;          // interval for checking for humans after map load
const Float:    MAX_RAYDIF              = 100.0;        // maximum z-difference for finding floors
const           MAX_DOORS               = 128;          // amount of doors to track

const Float:    BLND_ENT_CHECK_INTERVAL = 1.0;          // for 'blind infected' adaptation
const Float:    BLND_TRACE_TOLERANCE    = 75.0;

const Float:    ITEM_PICKUP_DISTANCE    = 64.0;         // how far can a survivor 'reach' for a gift box?

const           STR_MAX_WPCLASSNAME     = 48;
const           STR_MAX_ITEMGIVEN       = 22;
const           STR_MAX_MODELNAME       = 48;
const           STR_MAX_MAPNAME         = 24;

const Float:    DELAY_ROUNDPREP         = 1.0;
const Float:    DELAY_SECONDHALF        = 1.0;          // how long to wait on secondroundhalf before restoring items
const Float:    DELAY_SECONDHALF_REP    = 1.25;         // how long to wait on secondroundhalf before doing the report
const Float:    DELAY_SURVSETUP         = 0.25;         // how long to wait after team switch/join to set survivor startup (for GetPlayerSlot check)
const Float:    DELAY_TEAMSWAP          = 0.1;          // how long to wait before applying changes after team swap..

const           INDEX_NOITEM            = 0;            // indices for picking random item replacement (must always be lowest!)
const           INDEX_PISTOL            = 1;
const           INDEX_T1SMG             = 2;
const           INDEX_T1SHOTGUN         = 3;
const           INDEX_T2RIFLE           = 4;
const           INDEX_T2SHOTGUN         = 5;
const           INDEX_SNIPER            = 6;
const           INDEX_MELEE             = 7;
const           INDEX_T3                = 8;
const           INDEX_CANISTER          = 9;
const           INDEX_PILL              = 10;
const           INDEX_THROWABLE         = 11;
const           INDEX_KIT               = 12;
const           INDEX_AMMO              = 13;
const           INDEX_UPGRADE           = 14;
const           INDEX_JUNK              = 15;
const           INDEX_SILLY             = 16;
const           INDEX_GIFT              = 17;

const           INDEX_TOTAL             = 18;
const           INDEX_LAST_USEFUL       = 14;

const           INDEX_SURV_NOTHING      = 0;            // indices for picking random starting setup for survivors
const           INDEX_SURV_PISTOL       = 1;
const           INDEX_SURV_DUALS        = 2;
const           INDEX_SURV_MAGNUM       = 3;
const           INDEX_SURV_T1SMG        = 4;
const           INDEX_SURV_T1SHOT       = 5;
const           INDEX_SURV_MELEE        = 6;
const           INDEX_SURV_TOTAL        = 7;


const           EVT_ITEM                = 0;
const           EVT_HORDE_HUGE          = 1;
const           EVT_HORDE_NONE          = 2;
const           EVT_UNCOMMON            = 3;
const           EVT_CLOWNS              = 4;
const           EVT_DOORS               = 5;
const           EVT_QUADS               = 6;
const           EVT_WEATHER             = 7;
const           EVT_FOG                 = 8;
const           EVT_ABUNDANCE           = 9;
const           EVT_SNIPER              = 10;
const           EVT_GIFTS               = 11;
const           EVT_DEFIB               = 12;
const           EVT_ADREN               = 13;
const           EVT_NOHUD               = 14;
const           EVT_L4D1                = 15;
const           EVT_FF                  = 16;
const           EVT_SILENCE             = 17;
const           EVT_PEN_ITEM            = 18;
const           EVT_PEN_HEALTH          = 19;
const           EVT_PEN_M2              = 20;
const           EVT_GUNSWAP             = 21;
const           EVT_MINITANKS           = 22;
const           EVT_KEYMASTER           = 23;
//const           EVT_PEN_TIME            = ;
//const           EVT_WITCHHUNT           = ;

const           EVT_TOTAL               = 24;
    
const           EQ_ITEMS                = 1;            // flags for rand_equal cvar
const           EQ_DOORS                = 2;
const           EQ_GLOWS                = 4;
const           EQ_EVENT                = 8;
const           EQ_INCAPS               = 16;
const           EQ_HORDE                = 32;
const           EQ_ITEM_WEIGHTS         = 64;           // redistribute weights for item randomization?
const           EQ_SURV_HEALTH          = 128;
const           EQ_FIRST_ATTACK         = 256;
const           EQ_TANKS                = 512;          // only for double-tank for a round, though
const           EQ_POINTS               = 1024;         // for distance & bonus

const           EQ_EVERYTHING           = 2047;         // minimum value for which everything is equal

const Float:    MULTITANK_EARLY         = 0.25;         // for 2-tank-rounds: where to spawn early tank
const Float:    MULTITANK_LATE          = 0.75;         //                         and the late one
const Float:    MULTITANK_HEALTHITEMS   = 1.5;          // factor by which to change health item weight for double-tanked map

const           MULTIWITCH_MIN          = 3;            // amount of witches in multi-witch mode
const           MULTIWITCH_MAX          = 7;
const Float:    MULTIWITCH_FLOW_MIN     = 0.1;          // earliest a multiwitch can spawn
const Float:    MULTIWITCH_FLOW_MAX     = 0.9;
const Float:    MULTIWITCH_FLOW_BETWEEN = 0.1;          // minimum flow distance between two witches
const Float:    MULTIWITCH_FLOW_TANK    = 0.15;         // minimum distance a witch must be from tank spawn
const bool:     MULTIWITCH_ALLOW_TANK   = true;         // multiwitches possible when there's a tank?

const           MULTITANK_MAX           = 9;
const           MINITANKS_NUM           = 9;            // 9 tanks, 1250 health each
const           MINITANKS_HEALTH        = 900;
const Float:    MINITANKS_FLOW_MIN      = 0.1;
const Float:    MINITANKS_FLOW_MAX      = 0.9;
const Float:    MINITANKS_FLOW_INT      = 0.1;
const Float:    MINITANKS_FLOW_VAR      = 0.025;        // tiny flow variation, for funzies
const Float:    MINITANKS_SCALE         = 0.67;         // scale the model by what?
const Float:    MINITANK_MELEE_DMG      = 200.0;        // damage minitanks take from melee weapons
const           MINITANK_FRUST_TIME     = 10;           // half normal frustration time

const Float:    ITEM_FACTOR_2V2         = 0.5;          // how many of the items available in #v# game
const Float:    ITEM_FACTOR_3V3         = 0.75;

const           RATE_MAGNUM             = 10;           // 1 in [#] = magnum (vs normal pistol)
const           RATE_SMG                = 2;            // 1 in [#] = normal smg (vs silenced)
const           RATE_PUMPSHOT           = 2;            // 1 in [#] = pumpshotgun/auto (vs chrome/spas)
const           RATE_CSS                = 6;            // 1 in [#] = css weapon (vs l4d2 native)
const           RATE_CSS_SNIPER         = 2;            // 1 in [#] = css sniper (vs l4d2 native sniper)
const           RATE_DEFIB              = 6;            // 1 in [#] = defib (vs medkit)
const           RATE_ADREN              = 4;            // 1 in [#] = adrenaline (vs pills)
const           RATE_CAN_BARREL         = 6;            // 1 in [#] = explosive barrel (vs normal canisters)
const           RATE_CAN_GAS            = 4;            // 1 in [#] = gas can (vs explosive canisters)
const           RATE_UPG_LASER          = 5;            // 1 in [#] = lasersights (vs incendiary/explosives)
const           RATE_UPG_EXPLOSIVE      = 10;           // 1 in [#] = explosives (vs incendiary)

const           DIFFICULTY_NOCHANGE     = 0;            // don't change it
const           DIFFICULTY_NORMAL       = 1;            // event difficulty
const           DIFFICULTY_VERYHARD     = 2;
const           DIFFICULTY_HARD         = 3;
const           DIFFICULTY_EASY         = 4;
const           DIFFICULTY_VERYEASY     = 5;
const           DIFFICULTY_SUPEREASY    = 6;

const Float:    EVENT_VERYHARD_SITIME   = 0.5;          // more difficult, SI-wise
const Float:    EVENT_HARD_SITIME       = 0.75;
const Float:    EVENT_EASY_SITIME       = 1.25;
const Float:    EVENT_VERYEASY_SITIME   = 1.5; 

const Float:    EVENT_SUPEREASY_CILIM   = 0.25;         // super easy, common-wise
const Float:    EVENT_VERYEASY_CILIM    = 0.5; 
const Float:    EVENT_EASY_CILIM        = 0.75;
const Float:    EVENT_HARD_CILIM        = 1.25;
const Float:    EVENT_VERYHARD_CILIM    = 1.5;

const Float:    EVENT_ITEM_WEIGHT       = 0.2;          // EVT_ITEM         set weight of picked item type to this factor of total weight
const Float:    EVENT_UNCOMMON_CHANCE   = 0.5;          // EVT_UNCOMMON     half the common become uncommon
const Float:    EVENT_CLOWNS_CHANCE     = 0.7;          // EVT_CLOWNS       plenty of clowns
const Float:    EVENT_ABUND_JUNKWGHT    = 0.5;          // EVT_ABUNDANCE    by what factor to change junk amount
const Float:    EVENT_DEFIB_EXTRA       = 2.5;          // EVT_DEFIB        by what factor to change defib amount
const Float:    EVENT_DEFIB_PILLS       = 1.5;          // EVT_DEFIB        by what factor to change pills amount
const Float:    EVENT_ADREN_EXTRA       = 3.5;          // EVT_ADREN        by what factor to change adren amount
const Float:    EVENT_ADREN_LESSER      = 0.5;          // EVT_ADREN        by what factor to change a bunch of other items (less useful in this mode)
const Float:    EVENT_ADREN_DECAY       = 1.5;          // EVT_ADREN        by what factor to change pill decay rate
const           EVENT_NOHUD_MASK        = 64;           // EVT_NOHUD        bitmask for what to hide
const           EVENT_PENALTY_ITEM      = 5;            // EVT_PEN_ITEM     how many points to deduct
const           EVENT_PENALTY_HEALTH    = 15;           // EVT_PEN_HEALTH   how many points to deduct
const bool:     EVENT_PENALTY_CI        = false;        // EVT_PEN_M2       whether there are penalties for common-shoves
const           EVENT_PENALTY_M2_CI     = 2;            // EVT_PEN_M2       how many points to deduct for shoving
const           EVENT_PENALTY_M2_SI     = 15;           // EVT_PEN_M2       how many points to deduct for shoving
const Float:    EVENT_FF_FACTOR         = 0.3;          // EVT_NOHUD        bitmask for what to hide
const Float:    EVENT_LOCKEDCHANCE      = 0.7;          // EVT_DOORS        most doors closed -- melees will be given on start
const           EVENT_DOORS_MINMELEE    = 2;            // EVT_DOORS        how many melees at least for locked doors event?

const           EARLY_DOORS_MINMELEE    = 1;            // how many melees at least for early locked doors

const           TANK_DROP_ITEMS_MIN     = 2;            // how many items a tank can drop minimally
const           TANK_DROP_ITEMS_MAX     = 5;

const           GIFT_MIN_ITEMS          = 2;            // amount of items to minimally spawn out of a gift box
const           GIFT_MAX_ITEMS          = 6;            
const Float:    GIFTUSE_TIMEOUT         = 0.25;         // how long after playerUse command to wait (avoid spamming use)
const Float:    GIFTREPORT_TIMEOUT      = 1.0;          // how long after playerUse command to wait (avoid spamming messages)

const           SILENCED_SURV           = 0;            // silent survivors
const           SILENCED_SI             = 1;
const           SILENCED_CI             = 2;            // not sure if I want to use this

new const String: DOOR_SOUND[]              = "doors/latchlocked2.wav";
new const String: EXPLOSION_SOUND[]         = "ambient/explosions/explode_1.wav";
new const String: EXPLOSION_SOUND2[]        = "ambient/explosions/explode_2.wav";
new const String: EXPLOSION_SOUND3[]        = "ambient/explosions/explode_3.wav";
new const String: EXPLOSION_DEBRIS[]        = "animation/van_inside_debris.wav";
new const String: BOOMGIFT_SOUND[]          = "player/boomer/voice/vomit/male_boomer_vomit_03.wav";
new const String: PANICGIFT_SOUND[]         = "ambient/alarms/klaxon1.wav";

//new const String: MODEL_W_MOLOTOV[]         = "models/w_models/weapons/w_eq_molotov.mdl";
new const String: MODEL_GASCAN[]            = "models/props_junk/gascan001a.mdl";
new const String: MODEL_FIREWORKS[]         = "models/props_junk/explosive_box001.mdl";
new const String: MODEL_L4D1AMMO[]          = "models/props_unique/spawn_apartment/coffeeammo.mdl";

const           EXPLOSION_RADIUS        = 200;
const Float:    EXPLOSION_POWER_HIGH    = 50.0;
const Float:    EXPLOSION_POWER_LOW     = 25.0;
const Float:    EXPLOSION_DURATION      = 15.0;
const Float:    EXPLOSION_DURATION_MIN  = 1.0;

const Float:    PIPEDUD_MINTIME         = 2.4;          // how much time minimally before dudding pipe
const Float:    PIPEDUD_ADDTIME         = 2.5;          // how much time to add maximally to mintime

const           BOOMCOMBO_REWARD        = 6;            // amount of common to spawn extra for 2/3 boom combo's

const Float:    TESTENTITY_TIMER        = 2.5;          // when to check for entity Z location
const Float:    TESTENTITY_UPSHIFT      = 35.0;         // by how much to teleport the entity above its origin if it dropped too far
const Float:    TESTENTITY_THRESH       = 50.0;         // threshold for detecting entity's that 'fell through the floor'

const Float:    GNOME_FINALE_DIST_FACTOR = 0.25;        // by how much to weight finale distance for gnome value

const Float:    TIMER_PICKUPCHECK       = 0.05;         // super brief delay to check whether an item was really picked up, or actually given

const           WITCHES_NIGHT           = 0;            // sv_force_time_of_day value
const           WITCHES_DAY             = 3;
/*
const           WITCH_SEQUENCE_STANDING     = 2;        // m_nSequence
const           WITCH_SEQUENCE_SITTING      = 4;
*/

const           DIFF_RATING_GLOW_THRESH     = 3;        // how high the round difficulty rating must be before we're more likely to keep glows on
const           DIFF_RATING_INCAP_THRESH    = 4;        // how high before we keep minimum default incaps
const           DIFF_RATING_PILL_THRESH     = 5;        // how high before we guarantee pills

const Float:    SACKPROT_MARGIN         = 0.1;          // seconds margin to remove from spawn timer to check for sack-actions (not really required)

// structs, enums

enum entityBlindable            // for use with tries to check if an entity causes problems with the blind-infected approach
{
    ENTITY_BLINDABLE,
    ENTITY_NOT_BLINDABLE
}

enum itemPickupPenalty          // for use with tries to check if an item should carry a penalty
{
    ITEM_PICKUP_PENALTY,
    ITEM_PICKUP_PENALTY_PRIMARY
}

enum mapsType                   // for use with tries to check map type (intro or not)
{
    MAPS_NORMAL,
    MAPS_INTRO,
    MAPS_FINALE,
    MAPS_NOCOLA
}

enum CreatedEntityType          // for use with tries to determine whether to handle onEntityCreated
{
    CREATED_INFECTED,
    CREATED_PIPEBOMB,
    CREATED_PROP_PHYSICS
}

enum RandomizableOrNot          // for use with tries to determine ent's random-replaceableness
{
    RANDOMIZABLE_ITEM,
    RANDOMIZABLE_PHYSICS,
    RANDOMIZABLE_ITEM_AMMO
}

enum pickType                   // which option was randomly picked? data recreated on this basis
{
    PCK_NOITEM,
    PCK_PISTOL,             PCK_PISTOL_MAGNUM,      PCK_SMG_MP5,            PCK_SMG,            PCK_SMG_SILENCED,       PCK_PUMPSHOTGUN,        PCK_SHOTGUN_CHROME,     PCK_RIFLE_SG552,
    PCK_RIFLE,              PCK_RIFLE_AK47,         PCK_RIFLE_DESERT,       PCK_AUTOSHOTGUN,    PCK_SHOTGUN_SPAS,       PCK_HUNTING_RIFLE,      PCK_SNIPER_MILITARY,    PCK_SNIPER_AWP,
    PCK_SNIPER_SCOUT,       PCK_MELEE,
    PCK_CHAINSAW,           PCK_GRENADE_LAUNCHER,   PCK_RIFLE_M60,          PCK_EXPLOSIVE_BARREL,                       PCK_FIREWORKCRATE,      PCK_PROPANETANK,        PCK_OXYGENTANK,
    PCK_GASCAN,             PCK_PAIN_PILLS,         PCK_ADRENALINE,         PCK_MOLOTOV,         PCK_PIPEBOMB,          PCK_VOMITJAR,           PCK_FIRST_AID_KIT,      PCK_DEFIBRILLATOR,
    PCK_AMMO,               PCK_UPG_LASER,          PCK_UPG_EXPLOSIVE,      PCK_UPG_INCENDIARY,  PCK_SILLY_COLA,        PCK_SILLY_GNOME,        PCK_SILLY_GIFT,         PCK_JUNK,
    PCK_DUALS
    // PCK_MELEE [18] remember, class will be stored separately
    // PCK_DUALS = only for survivor start setups
}

enum strEntityData                  // everything required to recreate the entity
{
            entNumber,              // what is the actual entity number?
    bool:   entPickedUp,            // picked up by current team
    bool:   entInStartSaferoom,     // using l4d2_saferoom_detect
    bool:   entInEndSaferoom,
            entPickedType,
    String: entMeleeClass[32],      // for PCK_MELEE only
    bool:   entSpawnPhysics,        // whether to set spawnflags 1
    Float:  entOrigin_a,
    Float:  entOrigin_b,
    Float:  entOrigin_c,
    Float:  entAngles_a,
    Float:  entAngles_b,
    Float:  entAngles_c,
            entAmmoMax,             // for weapons: to fill to max ammo
    bool:   entCheckOrigin,         // if enabled, CreateEntity checks origin for wall/floor stuckness
            entJunkType             // index of junkModels array
}

enum EntInfo                        // for blind_infected adaptation
{
            iEntity,
    bool:   hasBeenSeen
}
enum strGnomeData
{
    bool:   gnomebIsCola,           // whether the gnome is really cola (don't ask)
    bool:   gnomebWorthPoints,      // whether the gnome is worth points at all
    bool:   gnomebHeldByPlayer,     // whether a player is currently holding the gnome
            gnomeiHoldingClient,    // who is holding it
    bool:   gnomebFirstPickup,      // whether it has been picked up at all
    Float:  gnomefFirstPickup,      // where (in fractional distance) the gnome was first picked up
            gnomeEntity             // if not held, what phys prop entity is the gnome?
}

enum MeleeNormalOrWeird
{
    MELEE_NORMAL,
    MELEE_WEIRD
}

new const String: g_csItemTypeText[][] =
{
    "", // will be concat'd with an item (type) name
    "pistols",
    "smgs",
    "t1 shotguns",
    "rifles",
    "t2 shotguns",
    "snipers",
    "melee weapons",
    "t3 weapons",
    "canisters",
    "pills/adrenaline",
    "throwables",
    "medkits/defibs",
    "ammo piles",
    "upgrades",
    "junk",
    "silly items",
    "random gifts"
};

new const String: g_csItemPickName[][] =
{
    "no item",
    "pistol", "magnum",
    "mp5", "smg", "silenced smg",
    "pumpshotgun", "chrome shotgun",
    "sg552", "m16", "ak47", "scar",
    "autoshotgun", "spas",
    "hunting rifle", "military sniper", "AWP", "scout",
    "melee",
    "chainsaw", "grenade launcher", "m60",
    "explosive barrel", "fireworks", "propane tank", "oxygen tank", "gas can",
    "pills", "adrenaline",
    "molotov", "pipe bomb", "bile bomb",
    "medkit", "defib",
    "ammo pile",
    "laser sights", "explosive ammo", "incendiary ammo",
    "cola pack", "gnome", "random gift",
    "junk item",
    "dual pistols"
};

new const String: g_csEventText[][] =
{
    "\x04Item Redundancy\x01 - Higher chances of finding ",                           // will be concat'd with an item (type) name
    "\x04Rush Hour\x01 - This area is crowded with commons.",
    "\x04Common Holiday\x01 - Very few common infected here...",
    "\x04Freakshow\x01 - Common uncommon.",
    "\x04Circus\x01 - I hope you like clowns...",
    "\x04Sorry, we're closed\x01 - Someone's been locking the doors.",
    "\x04Quadtastic\x01 - Only cappers will spawn.",
    "\x04Bad Weather Day\x01",
    "\x04Fog of War\x01",
    "\x04Land of Plenty\x01 - Useful stuff everywhere.",
    "\x04Marksmen\x01 - CSS snipers only.",
    "\x04It's Christmas\x01 - Gifts for everyone!",
    "\x04Sudden Death\x01 - No incaps, just instant death",
    "\x04Adrenaline Rush\x01",
    "\x04No Heads-Up\x01 - Survivors are HUD-less.",
    "\x04Old School\x01 - Back to L4D1...",
    "\x04Friendly Fire\x01 - Hey! Watch where you shoot.",
    "\x04Hush\x01 - silent ",
    "\x04Pickup Penalty\x01 - Any item pickup costs \x045\x01 points.",
    "\x04Health Penalty\x01 - Using any health item costs \x0415\x01 points.",
    "\x04Shove Penalty\x01 - Using m2 on special infected costs \x0415\x01 points.",
    "\x04Magic Gun Swap\x01",
    "\x04Mini-Tanks\x01 - Many small tanks will spawn.",
    "\x04Keymaster\x01 - Only one player can use doors."
};

new const String: g_csJunkModels[][] =
{
    "models/props_furniture/cafe_barstool1.mdl",
    "models/props/cs_office/Fire_Extinguisher.mdl",
    "models/props_fortifications/orange_cone001_reference.mdl",
    "models/props_junk/metalbucket01a.mdl",
    "models/props_urban/plastic_chair001.mdl",
    "models/props_interiors/tv.mdl",
    "models/props_urban/shopping_cart001.mdl",
    "models/props_urban/tire001.mdl"
};

new const String: g_csUncommonModels[][] =
{
    "models/infected/common_male_riot.mdl",
    "models/infected/common_male_ceda.mdl",
    "models/infected/common_male_clown.mdl",
    "models/infected/common_male_mud.mdl",
    "models/infected/common_male_roadcrew.mdl"
};

new const String: g_csPreCacheModels[][] =
{
    // Weapons / spawnables
    "models/w_models/weapons/w_rifle_sg552.mdl",
    "models/w_models/weapons/w_sniper_awp.mdl",
    "models/w_models/weapons/w_sniper_scout.mdl",
    "models/w_models/weapons/w_smg_mp5.mdl",
    "models/w_models/weapons/w_m60.mdl",
    "models/v_models/v_rif_sg552.mdl",
    "models/v_models/v_snip_awp.mdl",
    "models/v_models/v_snip_scout.mdl",
    "models/v_models/v_smg_mp5.mdl",
    "models/w_models/v_rif_m60.mdl",
    "models/v_models/v_m60.mdl",
    
    "models/props_industrial/barrel_fuel.mdl",
    "models/props_industrial/barrel_fuel_partb.mdl",
    "models/props_industrial/barrel_fuel_parta.mdl",
    
    // Special
    "models/props_unique/spawn_apartment/coffeeammo.mdl",
    "models/props_junk/gnome.mdl",
    "models/w_models/weapons/w_cola.mdl",
    "models/infected/common_male_jimmy.mdl",
    "models/infected/common_male_fallen_survivor.mdl",
    "models/items/l4d_gift.mdl",
    
    // Melee Weapons
    "models/weapons/melee/v_bat.mdl",
    "models/weapons/melee/v_cricket_bat.mdl",
    "models/weapons/melee/v_crowbar.mdl",
    "models/weapons/melee/v_electric_guitar.mdl",
    "models/weapons/melee/v_fireaxe.mdl",
    "models/weapons/melee/v_frying_pan.mdl",
    "models/weapons/melee/v_golfclub.mdl",
    "models/weapons/melee/v_katana.mdl",
    "models/weapons/melee/v_machete.mdl",
    "models/weapons/melee/v_tonfa.mdl",    
    "models/weapons/melee/w_bat.mdl",
    "models/weapons/melee/w_cricket_bat.mdl",
    "models/weapons/melee/w_crowbar.mdl",
    "models/weapons/melee/w_electric_guitar.mdl",
    "models/weapons/melee/w_fireaxe.mdl",
    "models/weapons/melee/w_frying_pan.mdl",
    "models/weapons/melee/w_golfclub.mdl",
    "models/weapons/melee/w_katana.mdl",
    "models/weapons/melee/w_machete.mdl",
    "models/weapons/melee/w_tonfa.mdl"
    
    //"models/w_models/weapons/w_minigun.mdl",
    //"models/w_models/weapons/50cal.mdl",
};

new const String: g_csCSSWeapons[][] =
{
    "weapon_smg_mp5",
    "weapon_rifle_sg552",
    "weapon_sniper_awp",
    "weapon_sniper_scout"
};

enum WeaponId
{
	WEPID_NONE,				// 0
	WEPID_PISTOL,			// 1
	WEPID_SMG,				// 2
	WEPID_PUMPSHOTGUN,		// 3
	WEPID_AUTOSHOTGUN,		// 4
	WEPID_RIFLE,			// 5
	WEPID_HUNTING_RIFLE,	// 6
	WEPID_SMG_SILENCED,		// 7
	WEPID_SHOTGUN_CHROME, 	// 8
	WEPID_RIFLE_DESERT,		// 9
	WEPID_SNIPER_MILITARY,	// 10
	WEPID_SHOTGUN_SPAS, 	// 11
	WEPID_FIRST_AID_KIT, 	// 12
	WEPID_MOLOTOV, 			// 13
	WEPID_PIPE_BOMB, 		// 14
	WEPID_PAIN_PILLS, 		// 15
	WEPID_GASCAN,			// 16
	WEPID_PROPANE_TANK,		// 17
	WEPID_OXYGEN_TANK,		// 18
	WEPID_MELEE,			// 19
	WEPID_CHAINSAW,			// 20	
	WEPID_GRENADE_LAUNCHER,	// 21
	WEPID_AMMO_PACK,		// 22
	WEPID_ADRENALINE,		// 23
	WEPID_DEFIBRILLATOR,	// 24
	WEPID_VOMITJAR,			// 25 
	WEPID_RIFLE_AK47, 		// 26
	WEPID_GNOME_CHOMPSKI,	// 27
	WEPID_COLA_BOTTLES,		// 28
	WEPID_FIREWORKS_BOX,	// 29
	WEPID_INCENDIARY_AMMO,	// 30
	WEPID_FRAG_AMMO,		// 31
	WEPID_PISTOL_MAGNUM,	// 32
	WEPID_SMG_MP5, 			// 33
	WEPID_RIFLE_SG552, 		// 34
	WEPID_SNIPER_AWP, 		// 35
	WEPID_SNIPER_SCOUT, 	// 36
	WEPID_RIFLE_M60,		// 37
	WEPID_TANK_CLAW,		// 38
	WEPID_HUNTER_CLAW,		// 39
	WEPID_CHARGER_CLAW,		// 40
	WEPID_BOOMER_CLAW,		// 41
	WEPID_SMOKER_CLAW,		// 42
	WEPID_SPITTER_CLAW,		// 43
	WEPID_JOCKEY_CLAW,		// 44
	WEPID_MACHINEGUN,		// 45
	WEPID_FATAL_VOMIT,		// 46
	WEPID_EXPLODING_SPLAT,	// 47
	WEPID_LUNGE_POUNCE,		// 48
	WEPID_LOUNGE,			// 49
	WEPID_FULLPULL,			// 50
	WEPID_CHOKE,			// 51
	WEPID_THROWING_ROCK,	// 52
	WEPID_TURBO_PHYSICS,	// 53 what is this
	WEPID_AMMO,				// 54
	WEPID_UPGRADE_ITEM		// 55
};