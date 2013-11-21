#pragma semicolon 1

const           DEBUG_MODE              = 0;

// Random global size config
// -------------------------

const           TEAM_SIZE               = 4;
const           MAX_CHARACTERS          = 4;
const           MAXROLES                = 20;
const           ENTITY_COUNT            = 2048;
const           HITTABLE_COUNT          = 128;          // just arbitrary
const           MELEE_CLASS_COUNT       = 32;
const           MELEE_CLASS_LENGTH      = 32;
const           STORED_MAX_COUNT        = 1024;         // just arbitrary, users shouldn't exceed this total
const           STORED_SURV_MAX_COUNT   = 256;          // just arbitrary, users shouldn't exceed this total
const           STORED_SI_MAX_COUNT     = 60;           // internal, so not even risky (max 10 per class)
const           STORED_GIFT_MAX_COUNT   = 128;          // just arbitrary, users shouldn't exceed this total
const           GNOME_MAX_COUNT         = 128;          // just arbitrary, users shouldn't exceed this total (because why make gnome heaven?)
const           MAX_REPORTLINES         = 15;
const           REPLINELENGTH           = 256;          // maximum length of a 'report line'
const Float:    MAX_RAYDIF              = 100.0;        // maximum z-difference for finding floors
const           MAX_DOORS               = 128;          // amount of doors to track
const           MAX_BOOBYTRAPS          = 128;          // amount of boobytraps to add maximally
const           MULTITANK_MAX           = 12;
const           MULTIWITCH_MAX          = 12;
const           EARLYDOOR_MAX           = 10;

const           STARTING_HORDE_TIMER    = 3600;         // this is set before round goes live

// String lengths
// --------------
const           STR_MAX_WPCLASSNAME     = 48;
const           STR_MAX_ITEMGIVEN       = 48;
const           STR_MAX_MODELNAME       = 64;
const           STR_MAX_MAPNAME         = 64;


// Random configuration
// --------------------
const Float:    TIMER_HUMANCHECK        = 2.0;          // interval for checking for humans after map load
const Float:    TIMER_STARTCHECK        = 0.25;         // interval for checking whether survivors have left saferoom (used if PlayersLeftStartArea while in readyup)
const Float:    DELAY_FIRSTMAPLOAD      = 5.0;          // how long to wait before doing round prep on the very first map loading
const Float:    DELAY_ROUNDPREP         = 1.0;          // how long between actual round prep and item handling etc
const Float:    DELAY_ROUNDPREP_COOP    = 6.5;          // coop 'transitions' items, so make sure we randomize after that happens (was 8)
const Float:    DELAY_SECONDHALF        = 1.0;          // how long to wait on secondroundhalf before restoring items
const Float:    DELAY_SECONDHALF_REP    = 1.25;         // how long to wait on secondroundhalf before doing the report
const Float:    DELAY_SURVSETUP         = 0.25;         // how long to wait after team switch/join to set survivor startup (for GetPlayerSlot check)
const Float:    DELAY_TEAMSWAP          = 0.1;          // how long to wait before applying changes after team swap..
const Float:    DELAY_FORCEROLE         = 0.2;          // how long to wait after teamswap to force the special event role
const Float:    TIMER_POUNCECHECK       = 0.1;          // interval to check for hunters being in-pounce
const Float:    DELAY_WELCOMEMSG        = 10.0;         // wait time between connect & message
const Float:    DELAY_PANELAFTERLIVE    = 2.5;          // wait time between OnRoundIsLive and drawn panel report
const           REPORT_PANEL_LIFETIME   = 20;           // how long to show the panel for
const Float:    DELAY_MAPRESTART        = 5.0;
const Float:    DELAY_T2_NERF_TIMEOUT   = 3.0;          // how many seconds between spam about t2 nerfs
const Float:    DELAY_SURVLOADEDCHECK   = 3.0;          // how long to wait after teamswap before checking the amount of survivors loaded in
const Float:    CAR_EXPLODE_DELAY       = 0.15;         // time between shooting car and it exploding
const Float:    DELAY_DEADSTOPGRACE     = 0.25;         // grace time between m2's for EVT_PEN_M2
const Float:    DELAY_MINITANKFREEZE    = 0.5;          // the time in which the distance is allowed to tick up between minitanks spawning

const           INCAP_DEFAULT           = 2;
const           INCAP_MINIMUM           = 1;
const           INCAP_MAXIMUM           = 3;
const           HEALTH_MAXIMUM          = 100;

const           COOP_MIN_STARTHEALTH    = 50;           // how much solid you should start with, at least

const Float:    ITEM_PICKUP_DISTANCE    = 64.0;         // how far can a survivor 'reach' for a gift box?
const Float:    ITEM_PICKUP_EYECHECKDST = 128.0;        // how far from gift maximally if we are to check eyes too?
const Float:    ITEM_PICKUP_EYEDISTANCE = 48.0;         //      measured from eyes
const Float:    AMMO_FIX_RANGE          = 256.0;        // if ammo is deployed further than this from player, position it on player's feet.
const Float:    ITEM_USE_DISTANCE       = 16.0;         // how far a survivor can move before aborting a use-progress-bar type action
const Float:    ITEM_USE_FREEZE_TIME    = 0.5;          // after how long of starting a progress-bar use type action you're frozen (while you hold USE)

const Float:    USING_TIME_DEFAULT      = 3.0;
const Float:    USING_TIME_GIFT         = 3.5;

const Float:    GIFT_EXPLODE_DELAY      = 0.25;         // time between opening gift and actual explosion
const Float:    GIFTUSE_TIMEOUT         = 0.25;         // how long after playerUse command to wait (avoid spamming use)
const Float:    GIFTREPORT_TIMEOUT      = 1.0;          // how long after playerUse command to wait (avoid spamming messages)

const Float:    DOUBLE_PASS_CHECK_TIME  = 8.0;          // fewer than this amount of seconds is considered a double pass
const Float:    TEAMSHUFFLE_TIMEOUT     = 5.0;          // can't reshuffle within this many seconds

// multi/mini tanks and witches
const Float:    MULTITANK_EARLY         = 0.35;         // for 2-tank-rounds: where to spawn early tank
const Float:    MULTITANK_LATE          = 0.75;         //                         and the late one

const Float:    MULTIWITCH_FLOW_MIN     = 0.15;         // earliest a multiwitch can spawn
const Float:    MULTIWITCH_FLOW_MAX     = 0.85;
const Float:    MULTIWITCH_FLOW_BETWEEN = 0.075;        // minimum flow distance between two witches
const Float:    MULTIWITCH_FLOW_TANK    = 0.15;         // minimum distance a witch must be from tank spawn

const Float:    MINITANKS_FLOW_MIN      = 0.1;
const Float:    MINITANKS_FLOW_MAX      = 0.9;
const Float:    MINITANKS_FLOW_INT      = 0.1;
const Float:    MINITANKS_FLOW_VAR      = 0.025;        // tiny flow variation, for funzies
const Float:    MINITANKS_SCALE         = 0.67;         // scale the model by what?

const Float:    MIN_WITCH_TANK_DISTANCE = 0.2;          // how much distance between tank and witch minimally

const Float:    CSAW_TANK_DMG_FACTOR    = 0.33;         // factor by which to change chainsaws doing damage to tanks

// item balance
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

const           CISKIN_EXTRA_RATE       = 8;            // 1 in [#]+1 = extra common type
const           CISKIN_L4D1_LESSER_RATE = 2;            // 1 in [#]+1 = extra common type
const           CISKIN_L4D1_LEAST_RATE  = 2;            // 1 in [#]+1 = extra common type


// event config
const Float:    EVENT_ITEM_WEIGHT       = 0.2;          // EVT_ITEM         set weight of picked item type to this factor of total weight
const Float:    EVENT_BADSANTA_WEIGHT   = 0.125;        // EVT_BADSANTA     set weight of picked item type to this factor of total weight
const Float:    EVENT_UNCOMMON_CHANCE   = 0.5;          // EVT_UNCOMMON     half the common become uncommon
const Float:    EVENT_CLOWNS_CHANCE     = 0.7;          // EVT_CLOWNS       plenty of clowns
const Float:    EVENT_ABUND_JUNKWGHT    = 0.5;          // EVT_ABUNDANCE    by what factor to change junk amount
const Float:    EVENT_DEFIB_EXTRA       = 2.5;          // EVT_DEFIB        by what factor to change defib amount
const Float:    EVENT_DEFIB_PILLS       = 1.25;         // EVT_DEFIB        by what factor to change pills amount
const           EVENT_DEFIB_PEN         = 15;           // EVT_DEFIB
const Float:    EVENT_ADREN_EXTRA       = 4.25;         // EVT_ADREN        by what factor to change adren amount
const Float:    EVENT_ADREN_LESSER      = 0.5;          // EVT_ADREN        by what factor to change a bunch of other items (less useful in this mode)
const Float:    EVENT_ADREN_BONUS       = 0.5;          // EVT_ADREN        by what factor to change the damage bonus for adrenaline rush events
const           EVENT_NOHUD_MASK        = 64;           // EVT_NOHUD        bitmask for what to hide

const bool:     EVENT_PENALTY_CI        = false;        // EVT_PEN_M2       whether there are penalties for common-shoves
const           EVENT_PENALTY_M2_CI     = 2;            // EVT_PEN_M2       how many points to deduct for shoving
const Float:    EVENT_LOCKEDCHANCE      = 0.7;          // EVT_DOORS        most doors closed -- melees will be given on start
const           EVENT_DOORS_MINMELEE    = 2;            // EVT_DOORS        how many melees at least for locked doors event?
const Float:    EVENT_PROTECT_CIWEAK    = 1.5;
const Float:    EVENT_PROTECT_CISTRONG  = 0.5;
const Float:    EVENT_PROTECT_TANKSPIT  = 0.8333;       // EVT_PROTECT      modifier for damage done by tanks/spit on baby ( damage * 1.5 * 0.8333 = 1.25 )
const Float:    EVENT_BOOBYTRAP_CHANCE  = 0.1;          // EVT_BOOBYTRAP    odds that an item or door is boobytrapped
const           EVENT_BOOBYTRAP_MIN     = 5;            //                  minimum amount of traps on a level
const Float:    EVENT_FIREPOWER_AMMO    = 2.0;          // EVT_FIREPOWER    factor that ammo for T2 weapons is multiplied
const Float:    EVENT_AMMO_PACKTIME     = 3.0;          // EVT_AMMO         time it takes to repack ammo
const Float:    EVENT_WOMEN_LIMITTIME   = 7.5;          // EVT_WOMEN        how long per combo-step to keep increased common limit
const           EVENT_WOMEN_EXTRACOMMON = 5;            // EVT_WOMEN        how many extra common per combo (limit increase)
const           EVENT_WOMEN_CLAW        = 10;           //                  claw damage spitter/boomer
const           EVENT_WOMEN_BSPEED      = 220;          //                  speed of boomer/spitter
const           EVENT_WOMEN_BFORCE      = 2500;         //                  force of boomer explosion
const Float:    EVENT_WOMEN_BDELAY      = 10.0;         //                  how much time delay between booming scratches
const Float:    EVENT_WITCHES_RANGE     = 250000.0;     //                  range for glow removal/addition
const           EVENT_MEDIC_UNITS_BASE  = 9;            // EVT_MEDIC        how many mediunits to start with (default difficulty) (medkit, pills + 8)
const           EVENT_MEDIC_UNITS_MIN   = 6;            // EVT_MEDIC        minimum mediunits
const           EVENT_MEDIC_UNITS_MAX   = 12;           // EVT_MEDIC        maximum mediunits 
const           EVENT_MEDIC_DIFF_BASE   = 4;            // EVT_MEDIC        use this difficulty for the base value (and scale the rest)

const           EVENT_BAY_CARDAMAGE     = 150;          // EVT_BAY          amount of damage done to a car before it explodes
const           EVENT_BAY_CARDMG_NORMAL = 500;          //                  same, but outside of the michael bay event
const Float:    EVENT_BAY_CARFLYLOW     = 75.0;
const Float:    EVENT_BAY_CARFLYHIGH    = 400.0;
const Float:    EVENT_BAY_SIEXPLODE     = 0.75;         // EVT_BAY          odds that SI explode
const Float:    EVENT_BAY_CIEXPLODE     = 0.05;         // EVT_BAY          odds that SI explode
const Float:    EVENT_BAY_ITEMFACTOR    = 1.35;         // EVT_BAY          to what to increase odds of exploding items
const Float:    EVENT_BAY_PIPEDAMAGE    = 5.0;          // EVT_BAY          how much damage small explosions do
const Float:    EVENT_BAY_JUNKWGHT      = 0.75;         // EVT_BAY          by what factor to change junk amount

const Float:    EVENT_ENC_W_T1          = 1.5;          // EVT_ENCUMBERED   for determining total player weight
const Float:    EVENT_ENC_W_SNIPER      = 2.5;
const Float:    EVENT_ENC_W_T2          = 3.0;
const Float:    EVENT_ENC_W_T3          = 4.0;
const Float:    EVENT_ENC_W_PISTOL      = 0.5;          // magnum weighs 2 pistols
const Float:    EVENT_ENC_W_MELEE       = 1.5;
const Float:    EVENT_ENC_W_THROWABLE   = 1.0;
const Float:    EVENT_ENC_W_KIT         = 2.0;
const Float:    EVENT_ENC_W_PILL        = 0.5;
const Float:    EVENT_ENC_W_PROP        = 2.5;          // propane tanks, gnome, cola, etc
const Float:    EVENT_ENC_W_THRESH      = 4.1;          // EVT_ENCUMBERED   weight threshold for slowing down
const Float:    EVENT_ENC_W_FAST_THRESH = 2.6;          //                  weight threshold for speeding up
const Float:    EVENT_ENC_W_RANGE       = 6.0;          //                  range on top of weight threshold (total weight can exceed 10.0)
const Float:    EVENT_ENC_FAST_MAX      = 0.5;          //                  max speed-up (1.0 + this value = speed factor)
const Float:    EVENT_ENC_SLOW_MAX      = 0.8;          //                  max slowdown (1.0 - this value = speed factor)

// misc
const Float:    GNOME_FINALE_DIST_FACTOR = 0.25;        // by how much to weight finale distance for gnome value

const           EARLY_DOORS_MINMELEE    = 1;            // how many melees at least for early locked doors
const           MANY_DOORS_EVENTFACTOR  = 3;            // how many times event weight for the doors events on many-doors-maps?

const           BOOMCOMBO_REWARD        = 6;            // amount of common to spawn extra for 2/3 boom combo's
const Float:    BOOMCOMBO_DUDTIME       = 10.0;         // how long after a boomer combo started will pipebombs have higher dud-chacne

const Float:    PIPEDUD_MINTIME         = 2.4;          // how much time minimally before dudding pipe
const Float:    PIPEDUD_ADDTIME         = 2.5;          // how much time to add maximally to mintime
const Float:    PIPEPRE_MINTIME         = 0.25;         // how much time minimally before preexploding pipe
const Float:    PIPEPRE_ADDTIME         = 2.5;          // how much time to add maximally to mintime

const Float:    SACKPROT_MARGIN         = 3.0;          // seconds margin: after this time, someone dying counts as the attack someone should join in to not be saving
const Float:    SACKPROT_OFFENCE_GRACE  = 5.0;          // seconds between offences before we add them up (for reporting after 3 strikes)

const           DIFF_RATING_GLOW_THRESH     = 3;        // how high the round difficulty rating must be before we're more likely to keep glows on
const           DIFF_RATING_INCAP_THRESH    = 3;        // how high before we keep minimum default incaps
const           DIFF_RATING_PILL_THRESH     = 5;        // how high before we guarantee pills
const           DIFF_RATING_2PRIM_THRESH    = 0;        // how high before we guarantee 2 primaries
const           DIFF_RATING_3PRIM_THRESH    = 2;        // how high before we guarantee 3 primaries
const           DIFF_RATING_4PRIM_THRESH    = 5;        // how high before we guarantee full load-out (primaries + secondaries)
const Float:    DIFF_RATING_NOITEM_LOW      = 0.5;      // what a low no-item value is (for very difficult rounds)
const Float:    DIFF_RATING_NOITEM_HIGH     = 1.5;      // what a high no-item value is (for very easy rounds)
const           DIFF_RATING_NOITEM_DIF_HIGH = 8;        // when to force towards the lowest noitem value
const           DIFF_RATING_NOITEM_DIF_LOW  = 0;        // when to force towards the highest noitem value

const Float:    HITTABLE_CAR_REPICK     = 0.5;          // the odds that a car will be repicked as a (different) car

const Float:    FIREEXT_POS_OFFSET      = 12.0;         // by how much to offset a fire-extinguisher replacement item from a wall
const Float:    FIREEXT_POS_OFFSET_Z    = 30.0;


// Random indexes
// --------------
const           WELCOME_NONE            = 0;
const           WELCOME_FIRSTMAP        = 1;
const           WELCOME_ALWAYS          = 2;
const           WELCOME_ONCE            = 3;

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
const           INDEX_SURV_MELEE        = 3;
const           INDEX_SURV_MAGNUM       = 4;
const           INDEX_SURV_T1SMG        = 5;
const           INDEX_SURV_T1SHOT       = 6;

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
const           EVT_PEN_TIME            = 21;
const           EVT_MINITANKS           = 22;
const           EVT_KEYMASTER           = 23;
const           EVT_BADCOMBO            = 24;
const           EVT_PROTECT             = 25;
const           EVT_ENCUMBERED          = 26;
const           EVT_BOOBYTRAP           = 27;
const           EVT_SKEET               = 28;
const           EVT_FIREPOWER           = 29;
const           EVT_AMMO                = 30;
const           EVT_WOMEN               = 31;
const           EVT_GUNSWAP             = 32;
const           EVT_WITCHES             = 33;
const           EVT_BADSANTA            = 34;
const           EVT_MEDIC               = 35;
const           EVT_BOOMFLU             = 36;
const           EVT_DOORCIRCUS          = 37;
const           EVT_BAY                 = 38;
const           EVT_PROHOPS             = 39;

const           EVT_TOTAL               = 40;

const           EVTMNU_INFO             = 1;
const           EVTMNU_PICK             = 2;
const           EVTMNU_PICKGAME         = 3;

const           EVTWOMEN_TYPE_AXE       = 1;            // axe effect
const           EVTWOMEN_TYPE_ROCK      = 2;            // rockstars
const           EVTWOMEN_TYPE_BEAT      = 3;            // fallback: any available

const           HITTAB_CAR69            = 0;            // cars
const           HITTAB_CAR84            = 1;
const           HITTAB_CAR82            = 2;
const           HITTAB_CAR95            = 3;
const           HITTAB_CARPOLICE        = 4;
const           HITTAB_CARTAXI          = 5;
const           HITTAB_CAR82WRECK       = 6;            // cars without addons
const           HITTAB_CAR95WRECK       = 7;
const           HITTAB_FORKLIFT         = 8;            //          turned
const           HITTAB_CART             = 9;
const           HITTAB_TREE             = 10;           //          turned
const           HITTAB_DUMPSTER         = 11;           // smaller  turned
const           HITTAB_DUMPSTER_ALT     = 12;           //          turned
const           HITTAB_GENERATOR        = 13;
const           HITTAB_TREETRUNK        = 14;           //          turned?
const           HITTAB_BUMPERCAR        = 15;
const           HITTAB_HAYBAIL          = 16;           //          turned
const           HITTAB_HANDTRUCK        = 17;
const           HITTAB_TABLE            = 18;

const           HITTAB_LASTADDON        = 7;
const           HITTAB_LASTCAR          = 7;
const           HITTAB_FIRSTSMALL       = 11;
const           HITTAB_TOTAL            = 19;

const           EQ_ITEMS                = (1<< 0);      // flags for rand_equal cvar
const           EQ_DOORS                = (1<< 1);
const           EQ_GLOWS                = (1<< 2);
const           EQ_EVENT                = (1<< 3);
const           EQ_INCAPS               = (1<< 4);
const           EQ_HORDE                = (1<< 5);
const           EQ_ITEM_WEIGHTS         = (1<< 6);      // redistribute weights for item randomization?
const           EQ_SURV_HEALTH          = (1<< 7);
const           EQ_FIRST_ATTACK         = (1<< 8);
const           EQ_TANKS                = (1<< 9);      // only for double-tank for a round, though
const           EQ_POINTS               = (1<< 10);     // for distance & bonus

const           EQ_EVERYTHING           = 2047;         // minimum value for which everything is equal

const           USING_TYPE_UNKNOWN      = 0;            // when using an item (entity), what type is it?
const           USING_TYPE_AMMO         = 1;
const           USING_TYPE_GIFT         = 2;

const           GIFT_POS_HEALTH         = 0;
const           GIFT_POS_HEALTH_T       = 1;
const           GIFT_POS_AMMO           = 2;
const           GIFT_POS_ALARMS         = 3;
const           GIFT_POS_ITEMS          = 4;
const           GIFT_POS_LASER          = 5;
const           GIFT_POS_INSIGHT        = 6;
const           GIFT_NEG_VOMIT          = 7;
const           GIFT_NEG_PANIC          = 8;
const           GIFT_NEG_BLIND          = 9;
const           GIFT_NEG_ALLDROP        = 10;
const           GIFT_NEG_EXPLODE        = 11;
const           GIFT_NEG_FIRE           = 12;
const           GIFT_NEG_INSIGHT        = 13;

const           GIFT_FIRST_POS_NSR      = 4;            // not-saferoom safe (before this)
const           GIFT_FIRST_NEG          = 7;
const           GIFT_FIRST_NEG_NSR      = 11;
const           GIFT_TOTAL              = 14;

const           DIFFICULTY_NOCHANGE     = 0;            // don't change it
const           DIFFICULTY_NORMAL       = 1;            // event difficulty
const           DIFFICULTY_VERYHARD     = 2;
const           DIFFICULTY_HARD         = 3;
const           DIFFICULTY_EASY         = 4;
const           DIFFICULTY_VERYEASY     = 5;
const           DIFFICULTY_SUPEREASY    = 6;

const           SILENCED_SURV           = 0;            // silent survivors
const           SILENCED_SI             = 1;
const           SILENCED_CI             = 2;            // not sure if I want to use this

const           HAT_BABY                = 0;            // g_csHatModels index
const           HAT_KEYMASTER           = 1;
const           HAT_MEDIC               = 2;
const           HAT_BOOMFLU             = 3;

const           NERFTYPE_NONE           = 0;
const           NERFTYPE_SNIPER         = 1;
const           NERFTYPE_T2             = 2;

const           DOORCIRC_MIN            = 3;            // min and max times for door state remaining unchanged
const           DOORCIRC_MAX            = 10;
const           DOORCIRC_MIN_OPEN       = 1;            // min and max times for door state remaining unchanged when open
const           DOORCIRC_MAX_OPEN       = 3;

// Third-party and mechanics configuration
// ---------------------------------------
const Float:    BLND_ENT_CHECK_INTERVAL = 1.0;          // for 'blind infected' adaptation
const Float:    BLND_TRACE_TOLERANCE    = 75.0;

const           EXPLOSION_RADIUS        = 200;
const Float:    EXPLOSION_DURATION      = 15.0;
const Float:    EXPLOSION_DURATION_MIN  = 1.0;

const Float:    TESTENTITY_TIMER        = 2.5;          // when to check for entity Z location
const Float:    TESTENTITY_UPSHIFT      = 35.0;         // by how much to teleport the entity above its origin if it dropped too far
const Float:    TESTENTITY_THRESH       = 50.0;         // threshold for detecting entity's that 'fell through the floor'

const Float:    TIMER_PICKUPCHECK       = 0.05;         // super brief delay to check whether an item was really picked up, or actually given
const Float:    SHOTGUN_BLAST_TIME      = 0.1;          // shotgun blast max time for tracking pellets (anything but 0, while super small, really)
const Float:    TIMER_POUNCE            = 0.1;          // repeat timer to check when hunter has landed (for skeet tracking)

const Float:    MULTIWITCH_EXTRA_FLOW   = 3000.0;
const Float:    MULTIWITCH_RESPAWN_FREQ = 5.0;

const           VOMIT_TYPE_SUR          = 1;
const           VOMIT_TYPE_SI           = 2;
const           VOMIT_TYPE_CI           = 4;

const           BLIND_AMOUNT            = 254;          // super blind

// Resources
// ---------
new const String: DOOR_SOUND[]          = "doors/latchlocked2.wav";
new const String: EXPLOSION_SOUND[]     = "ambient/explosions/explode_1.wav";
new const String: EXPLOSION_SOUND2[]    = "ambient/explosions/explode_2.wav";
new const String: EXPLOSION_SOUND3[]    = "ambient/explosions/explode_3.wav";
new const String: EXPLOSION_DEBRIS[]    = "animation/van_inside_debris.wav";
new const String: BOOMGIFT_SOUND[]      = "player/boomer/voice/vomit/male_boomer_vomit_03.wav";
new const String: PANICGIFT_SOUND[]     = "ambient/alarms/klaxon1.wav";
new const String: GIFTUNWRAP_SOUND[]    = "player/ammo_pack_use.wav";

//new const String: MODEL_W_MOLOTOV[]     = "models/w_models/weapons/w_eq_molotov.mdl";
new const String: MODEL_GASCAN[]        = "models/props_junk/gascan001a.mdl";
new const String: MODEL_FIREWORKS[]     = "models/props_junk/explosive_box001.mdl";
new const String: MODEL_L4D1AMMO[]      = "models/props_unique/spawn_apartment/coffeeammo.mdl";
new const String: MODEL_PROPANE[]       = "models/props_junk/propanecanister001a.mdl";

new const String: MODEL_BOOMETTE[]      = "models/infected/boomette.mdl";


// Game built in values
// --------------------
const           TEAM_SPECTATOR          = 1;
const           TEAM_SURVIVOR           = 2;
const           TEAM_INFECTED           = 3;

const           HITGROUP_HEAD           = 1;

const           PLAYER_SLOT_PRIMARY     = 0;
const           PLAYER_SLOT_SECONDARY   = 1;
const           PLAYER_SLOT_THROWABLE   = 2;
const           PLAYER_SLOT_KIT         = 3;
const           PLAYER_SLOT_PILL        = 4;

const           ASSAULT_RIFLE_OFFSET_IAMMO      = 12;
const           SMG_OFFSET_IAMMO                = 20;
const           SHOTGUN_OFFSET_IAMMO            = 28;
const           AUTO_SHOTGUN_OFFSET_IAMMO       = 32;
const           SNIPER_OFFSET_IAMMO             = 36;
const           MILITARY_SNIPER_OFFSET_IAMMO    = 40;
const           GRENADE_LAUNCHER_OFFSET_IAMMO   = 68;

const           ANIM_EVENT_BACK_TO_IDLE = 20;               // for l4d2_direct's doanimationevent
const           ANIM_EVENT_HEAL_OTHER   = 43;
const           ANIM_EVENT_INCAP_PICKUP = 44;
const           ANIM_EVENT_PLACE_THING  = 50;
const           ANIM_EVENT_DEPLOY_FLOOR = 52;
const           ANIM_EVENT_COLA_DELIVER = 55;

//const           ANIM_EVENT_KICKDOWN     = 37;               // zombie-like kick downwards
//const           ANIM_EVENT_PUSHBUTTON   = 64;               // simple quick button push

/*
const           ANIM_NICK_HEAL_OTHER    = 569;              // healing animation when using medkit on someone else
const           ANIM_COACH_HEAL_OTHER   = 570;
const           ANIM_ELLIS_HEAL_OTHER   = 574;
const           ANIM_ROCH_HEAL_OTHER    = 578;
const           ANIM_BILL_HEAL_OTHER    = 484;
const           ANIM_LOUIS_HEAL_OTHER   = 484;
const           ANIM_FRANCIS_HEAL_OTHER = 487;
const           ANIM_ZOEY_HEAL_OTHER    = 487;
*/

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

//const           SC_NICK_BILL            = 0;            // m_survivorCharacter
//const           SC_ROCHELLE_ZOEY        = 1;
//const           SC_COACH_LOUIS          = 2;
//const           SC_ELLIS_FRANCIS        = 3;

const           WITCHES_NIGHT           = 0;            // sv_force_time_of_day value
const           WITCHES_DAY             = 3;

const           DMGTYPE_CHAINSAW        = (1<<26);

const           Z_EXPL_SPEED            = 175;
const           Z_EXPL_CLAW             = 4;
const           Z_SPIT_SPEED            = 210;
const           Z_EXPL_FORCE            = 5000;     //z_exploding_force
const           Z_EXPL_RADIUS_IN        = 130;      //z_exploding_inner_radius
const           Z_EXPL_RADIUS_OUT       = 200;
const           Z_EXPL_SHOVE_MIN        = 4;
const           Z_EXPL_SHOVE_MAX        = 5;

// structs, enums
// --------------

// witch array entries (maxplayers+index)
enum _:strPlayDisco
{
    DISC_PAUSE,
    DISC_CLASS
};

enum randomCommands             // for use with tries to check if a command was typed in chat
{
    RANDOM_COMMAND,
    RANDOM_COMMAND_SPECTATE
}

enum itemPickupPenalty          // for use with tries to check if an item should carry a penalty (also other detection comparison for events)
{
    ITEM_PICKUP_PENALTY,
    ITEM_PICKUP_PENALTY_MELEE,
    ITEM_PICKUP_PENALTY_PISTOL,
    ITEM_PICKUP_PENALTY_MAGNUM,
    ITEM_PICKUP_PENALTY_SAW,
    ITEM_PICKUP_PENALTY_PRIMARY_T1,
    ITEM_PICKUP_PENALTY_PRIMARY_SNIPER,
    ITEM_PICKUP_PENALTY_PRIMARY_T2,
    ITEM_PICKUP_PENALTY_PRIMARY_T3
}

enum itemPropType               // for use with tries to check if an item is a carryable prop
{
    ITEM_PROP_GNOME,
    ITEM_PROP_COLA,
    ITEM_PROP_CANISTER
}

enum itemUseType                // for use with tries to check if an item is something we check for using
{
    ITEM_USE_DOOR,
    ITEM_USE_COLA,
    ITEM_USE_PROP,
    ITEM_USE_AMMO
}

enum itemDropType               // for use with tries
{
    ITEM_DROP_COLA,
    ITEM_DROP_HEALTH,
    ITEM_DROP_WEAPKIT,
    ITEM_DROP_WEAPPILLS
}

enum commonL4D1Type             // for detecting l4d1 commons
{
    COMMON_L4D1,
    COMMON_L4D1_PROBSKIN
}

enum CreatedEntityType          // for use with tries to determine whether to handle onEntityCreated
{
    CREATED_INFECTED,
    CREATED_PIPEBOMB,
    CREATED_PROP_PHYSICS,
    CREATED_AMMO_DEPLOYED,      // explosive/incendiary
    CREATED_WITCH,
    CREATED_TANKROCK,
    CREATED_ABILITYVOMIT
}

enum RandomizableOrNot          // for use with tries to determine ent's random-replaceableness
{
    RANDOMIZABLE_ITEM,
    RANDOMIZABLE_PHYSICS,
    RANDOMIZABLE_ITEM_AMMO,
    HITTABLE_PHYSICS,
    HITTABLE_PHYSICS_TURNED,        // all _TURNED are 90 degree turned from 'normal' car position
    HITTABLE_PHYSICS_SMALL,         // dumpsters and smaller
    HITTABLE_PHYSICS_SMALL_TURNED,
    HITTABLE_PHYSICS_CAR,           // only cars
    HITTABLE_PHYSICS_CAR_TURNED,
    HITTABLE_PHYSICS_ADDON          // the glass on cars
}

enum _:pickType                   // which option was randomly picked? data recreated on this basis
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

enum _:strEntityData                // everything required to recreate the entity
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

enum _:strHittableData              // everything required to recreate the hittable
{
            hitNumber,              // what is the actual entity number?
            hitNumberAddonA,        // entnumber for glass bit (which is parented to it) 0 for none
            hitPickedType,
    Float:  hitOrigin_a,
    Float:  hitOrigin_b,
    Float:  hitOrigin_c,
    Float:  hitAngles_a,
    Float:  hitAngles_b,
    Float:  hitAngles_c,
    bool:   hitIsCar,
    bool:   hitIsColored,               // if true, it also has rendercolors
    bool:   hitIsAlarmed,
    bool:   hitAlarmOff,                // if true, alarm has already been disabled
            hitDamageRcvd,
    bool:   hitBlownUp,                 // if true, car has been blown up
            hitGlassEntity,             // all parts of the alarm car
            hitGlassOffEntity,
            hitLightEntity_a,
            hitLightEntity_b,
            hitLightEntity_c,
            hitLightEntity_d,
            hitLightEntity_e,
            hitLightEntity_f,
            hitColor_r,
            hitColor_g,
            hitColor_b
}

enum _:EntInfo                      // for blind_infected adaptation
{
            iEntity,
    bool:   hasBeenSeen
}

enum _:strGnomeData
{
    bool:   gnomebIsCola,           // whether the gnome is really cola (don't ask)
    bool:   gnomebWorthPoints,      // whether the gnome is worth points at all
    bool:   gnomebHeldByPlayer,     // whether a player is currently holding the gnome
            gnomeiHoldingClient,    // who is holding it
    bool:   gnomebFirstPickup,      // whether it has been picked up at all
    Float:  gnomefFirstPickup,      // where (in fractional distance) the gnome was first picked up
            gnomeEntity,            // if not held, what phys prop entity is the gnome?
    bool:   gnomebAccountedFor      // if gnome is considered accounted for at this time
}

new const g_ciSpawnClassWeight[] =
{
    0,
    7,  // smoker
    6,  // boomer
    7,  // hunter
    6,  // spitter
    7,  // jockey
    6   // charger
};

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
    "\x04Item Redundancy\x01 - Higher chance of finding ",                           // will be concat'd with an item (type) name
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
    "\x04Friendly Fire\x01 - Be careful where you shoot...",
    "\x04Hush\x01 - silent ",
    "\x04Pickup Penalty\x01 - Any item pickup costs \x045\x01 points.",
    "\x04Health Penalty\x01 - Using any health item costs \x0420\x01 points.",
    "\x04Shove Penalty\x01 - Using m2 on special infected costs \x0410\x01 points.",
    "\x04Time Penalty\x01 - Every minute spent costs \x0425\x01 points.",
    "\x04Mini-Tanks\x01 - Many small tanks will spawn.",
    "\x04Keymaster\x01 - Only one player can use doors.",
    "\x04Bad Combo\x01 - Start with GL and Chainsaw.",
    "\x04Babysitting\x01 - The 'baby' takes double damage from SI (the others 3/4th).",
    "\x04Encumbered\x01 - Carrying more stuff makes you slower. (try '!drop')",
    "\x04Booby Traps\x01 - Doors and items may be wired with explosives.",
    "\x04Skeet Shoot\x01 - Skeet hunters for \x0415\x01 bonus points. Only shotguns and sniper headshots count.",
    "\x04Firepower\x01 - Tier 2 weapons everywhere.",
    "\x04Ammo Shortage\x01 - Deploy and repack your team's ammo.",
    "[women event]",                                                                            // two variants: Axe Effect and Rock Stars, replace name in report (plus backup variant)
    "\x04Magic Gun Swap\x01 - Empty your clip to get a new weapon.",
    "\x04Witch Hunt\x01 - Kill witches for \x0425\x01 bonus points. No bonus if they hurt you.",
    "\x04Lousy Gifts\x01 - All gifts are bad! \x0415\x01 bonus for unwrapping anyway.",
    "\x04MEDIC!\x01 - There is one medic with a limited supply of healing items.",
    "\x04Boomer Flu\x01 - One survivor caught the boomer flu and is prone to vomit.",
    "\x04Haunted Doors\x01 - Evil spirits randomly open and close the doors on this map.",
    "\x04Directed by Michael Bay\x01 - Explosions everywhere.",
    "\x04Bunnyhop Pros\x01 - Hold JUMP for automatic perfect bunnyhops."
};

new const String: g_csEventTextShort[][] =
{
    "Item Redundancy",
    "Rush Hour",
    "Common Holiday",
    "Freakshow",
    "Circus",
    "Sorry, we're closed",
    "Quadtastic",
    "Bad Weather Day",
    "Fog of War",
    "Land of Plenty",
    "Marksmen",
    "It's Christmas",
    "Sudden Death",
    "Adrenaline Rush",
    "No Heads-Up",
    "Old School",
    "Friendly Fire",
    "Hush",
    "Pickup Penalty",
    "Health Penalty",
    "Shove Penalty",
    "Time Penalty",
    "Mini-Tanks",
    "Keymaster",
    "Bad Combo",
    "Babysitting",
    "Encumbered",
    "Booby Traps",
    "Skeet Shoot",
    "Firepower",
    "Ammo Shortage",
    "Lots of Women",
    "Magic Gun Swap",
    "Witch Hunt",
    "Lousy Gifts",
    "MEDIC!",
    "Boomer Flu",
    "Haunted Doors",
    "Directed by Michael Bay",
    "Bunnyhop Pros"
};

new const JUNK_FIRSTNONSOLID = 4;
//new const JUNK_FIREEXT = 7;
new const String: g_csJunkModels[][] =
{
    "models/props_furniture/cafe_barstool1.mdl",
    "models/props_urban/shopping_cart001.mdl",
    "models/props_interiors/tv.mdl",
    "models/props_urban/plastic_chair001.mdl",
    "models/props_junk/metalbucket01a.mdl",                         // first nonsolid
    "models/props_fortifications/orange_cone001_reference.mdl",
    "models/props_urban/tire001.mdl",
    "models/props/cs_office/Fire_Extinguisher.mdl"
};

new const String: g_csHittableModels[][] =
{
    "models/props_vehicles/cara_69sedan.mdl",
    "models/props_vehicles/cara_84sedan.mdl",
    "models/props_vehicles/cara_82hatchback.mdl",
    "models/props_vehicles/cara_95sedan.mdl",
    "models/props_vehicles/police_car_rural.mdl",
    "models/props_vehicles/taxi_city.mdl",
    "models/props_vehicles/cara_82hatchback_wrecked.mdl",
    "models/props_vehicles/cara_95sedan_wrecked.mdl",
    "models/props/cs_assault/forklift.mdl",
    "models/props_vehicles/airport_baggage_cart2.mdl",
    "models/props_foliage/swamp_fallentree01_bare.mdl",
    "models/props_junk/dumpster.mdl",
    "models/props_junk/dumpster_2.mdl",
    "models/props_vehicles/generatortrailer01.mdl",
    "models/props_foliage/tree_trunk_fallen.mdl",
    "models/props_fairgrounds/bumpercar.mdl",               // "props_fairgrounds/bumper_car01.mdl" ?
    "models/props_unique/haybails_single.mdl",
    "models/props/cs_assault/handtruck.mdl",
    "models/props_urban/round_table001.mdl",
    "models/props_vehicles/cara_69sedan_glass.mdl",         // index + totalchoices = glas for index
    "models/props_vehicles/cara_84sedan_glass.mdl",
    "models/props_vehicles/cara_82hatchback_glass.mdl",
    "models/props_vehicles/cara_95sedan_glass.mdl",
    "models/props_vehicles/police_car_city_glass.mdl",
    "models/props_vehicles/taxi_city_glass.mdl",
    "models/props_vehicles/cara_82hatchback_wrecked_glass.mdl",
    "models/props_vehicles/cara_95sedan_wrecked_glass.mdl",
    "models/props_vehicles/cara_95sedan_glass_alarm.mdl"    // alarmed sedan only
};

// whether a hittable is turned 90 degrees as opposed to a car's normal positioning
new const bool: g_cbHittableTurned[] =
{
    false,
    false,
    false,
    false,
    true,       // police
    true,       // taxi
    false,
    false,
    true,       // forklift
    true,       // baggage cart
    true,       // tree
    true,       // dumpster
    true,       // dumpster alt
    false,
    true,       // trunk
    false,
    true,       // haybail
    false,
    false
};

new const String: g_csUncommonModels[][] =
{
    "models/infected/common_male_riot.mdl",
    "models/infected/common_male_ceda.mdl",
    "models/infected/common_male_clown.mdl",
    "models/infected/common_male_mud.mdl",
    "models/infected/common_male_roadcrew.mdl"
};

new const String: g_csMaleCommonModels[][] =
{
    "models/infected/common_male_dressshirt_jeans.mdl",
    "models/infected/common_male_polo_jeans.mdl",
    "models/infected/common_male_tanktop_jeans.mdl",
    //"models/infected/common_male_tanktop_jeans_rain.mdl",
    "models/infected/common_male_tanktop_jeans_swamp.mdl",
    "models/infected/common_male_tanktop_overalls.mdl",
    "models/infected/common_male_tshirt_cargos.mdl",
    "models/infected/common_male_tshirt_cargos_swamp.mdl"
};

new const String: g_csFemaleCommonModels[][] =
{
    "models/infected/common_female_tanktop_jeans.mdl",
    //"models/infected/common_female_tanktop_jeans_rain.mdl",
    //"models/infected/common_female_tanktop_jeans_swamp.mdl",
    "models/infected/common_female_tshirt_skirt.mdl",
    "models/infected/common_female_tshirt_skirt_swamp.mdl",
    "models/infected/common_female_formal.mdl"
};

new const L4D1_CI_FIRSTLOWERCHANCE = 4;     // less common
new const L4D1_CI_FIRSTLOWESTCHANCE = 8;    // even less common
new const String: g_csL4D1CommonModels[][] =
{
    "models/infected/common_male01.mdl",
    "models/infected/common_female01.mdl",
    "models/infected/common_male_rural01.mdl",
    "models/infected/common_female_rural01.mdl",
    "models/infected/common_male_suit.mdl",
    "models/infected/common_worker_male01.mdl",
    "models/infected/common_military_male01.mdl",
    "models/infected/common_police_male01.mdl",
    "models/infected/common_surgeon_male01.mdl",
    "models/infected/common_female_nurse01.mdl",
    "models/infected/common_male_pilot.mdl",
    "models/infected/common_male_baggagehandler_01.mdl",
    "models/infected/common_patient_male01_l4d2.mdl"
};

new const String: g_csExtraCommonModels[][] =
{
    "models/infected/common_male_formal.mdl",
    "models/infected/common_female_formal.mdl",
    "models/infected/common_male_biker.mdl"
};

new const String: g_csHatModels[][] =
{
    "models/props_interiors/teddy_bear.mdl",
    "models/props_lighting/light_construction02.mdl",
    "models/w_models/weapons/w_eq_medkit.mdl",
    "models/infected/limbs/exploded_boomer_head.mdl",
    "models/props_fortifications/orange_cone001_clientside.mdl"
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
    
    // commons
    "models/infected/common_female_tanktop_jeans.mdl",
    "models/infected/common_female_tanktop_jeans_rain.mdl",
    //"models/infected/common_female_tanktop_jeans_swamp.mdl",
    "models/infected/common_female_tshirt_skirt.mdl",
    "models/infected/common_female_tshirt_skirt_swamp.mdl",
    "models/infected/common_male_dressshirt_jeans.mdl",
    "models/infected/common_male_polo_jeans.mdl",
    "models/infected/common_male_tanktop_jeans.mdl",
    "models/infected/common_male_tanktop_jeans_swamp.mdl",
    "models/infected/common_male_tanktop_overalls.mdl",
    "models/infected/common_male_tshirt_cargos.mdl",
    "models/infected/common_male_tshirt_cargos_swamp.mdl",
    "models/infected/common_male_formal.mdl",
    "models/infected/common_female_formal.mdl",
    "models/infected/common_male_biker.mdl",
    
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
    "models/weapons/melee/w_tonfa.mdl",
    
    //"models/w_models/weapons/w_minigun.mdl",
    //"models/w_models/weapons/50cal.mdl",
    
    // hats
    "models/props_interiors/teddy_bear.mdl",
    "models/props_lighting/light_construction02.mdl",
    "models/w_models/weapons/w_eq_medkit.mdl",
    "models/infected/limbs/exploded_boomer_head.mdl",
    "models/props_fortifications/orange_cone001_clientside.mdl",    // not used, but precache for now anyway
    
    // boomette
    "models/infected/boomette.mdl",
    "models/infected/limbs/exploded_boomette.mdl"
};

new const String: g_csPrefetchSounds[][] =
{
    "doors/latchlocked2.wav",
    "player/ammo_pack_use.wav",
    "ambient/explosions/explode_1.wav",
    "ambient/explosions/explode_2.wav",
    "ambient/explosions/explode_3.wav",
    "animation/van_inside_debris.wav",
    "player/boomer/voice/vomit/male_boomer_vomit_03.wav",
    "player/boomer/vomit/attack/bv1.wav",
    "player/boomer/voice/pain/male_boomer_painshort_05.wav",
    "player/boomer/voice/pain/male_boomer_painshort_06.wav",
    "player/boomer/voice/pain/male_boomer_painshort_07.wav",
    "player/boomer/voice/alert/male_boomer_alert_04.wav",
    "player/boomer/voice/alert/male_boomer_alert_07.wav",
    "ambient/alarms/klaxon1.wav"
    /*
    // gift lines
    "player/mechanic/worldc2m3b13.wav",
    "player/mechanic/worldc2m3b14.wav",
    "player/mechanic/worldc2m3b15.wav",
    "player/mechanic/worldc2m3b16.wav"
    */
};

new const VOMIT_SOUND_FIRSTIMMINENT = 3;
new const String: g_csPreVomitSounds[][] =
{
    "player/boomer/voice/pain/male_boomer_painshort_05.wav",
    "player/boomer/voice/pain/male_boomer_painshort_06.wav",
    "player/boomer/voice/pain/male_boomer_painshort_07.wav",
    "player/boomer/voice/alert/male_boomer_alert_04.wav",
    "player/boomer/voice/alert/male_boomer_alert_07.wav"
};

new const String: g_csCSSWeapons[][] =
{
    "weapon_smg_mp5",
    "weapon_rifle_sg552",
    "weapon_sniper_awp",
    "weapon_sniper_scout"
    //"weapon_rifle_m60"
};

// friendly names for ZC_<CLASS> values
new const String: g_csSIClassName[][] =
{
    "",
    "smoker",
    "boomer",
    "hunter",
    "spitter",
    "jockey",
    "charger",
    "witch",
    "tank"
};

enum _:WeaponId
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