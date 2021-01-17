::RandCoop <- {
    // values for looking up convars
    RCTP_MIN            = 1
    RCTP_MAX            = 2
    RCTP_HUNTER         = 1
    RCTP_JOCKEY         = 2
    RCTP_CHARGER        = 3
    RCTP_SUPPORT        = 4

    RCTP_SPAWNING_TIMEOUT   = 5
    RCTP_ENCOUNTER_TIMEOUT  = 6
    RCTP_BUILDUP            = 7
    RCTP_GRACETIME          = 8
    RCTP_GRACETIME_LONG     = 9

    RCTP_NORMAL_ENC_INTERVAL     = 10
    RCTP_NORMAL_JOCKEY_INTERVAL  = 11

    RCTP_CHARGESPIT_TOTAL        = 12
    RCTP_CHARGESPIT_DOMINATOR    = 13
    RCTP_CHARGESPIT_CHARGER      = 14
    RCTP_CHARGESPIT_SPITTER      = 15

    RCTP_BIGATTACK_TOTAL         = 16
    RCTP_BIGATTACK_DOMINATOR     = 17
    RCTP_BIGATTACK_BOOMER        = 18
    RCTP_BIGATTACK_SMOKER        = 19
    RCTP_BIGATTACK_SPITTER       = 20
    RCTP_BIGATTACK_JOCKEY        = 21
}

function RandCoop::GetSpecialMinMaxConvarValue ( type, subType )
{
    switch (type) {
        case RandCoop.RCTP_HUNTER:
            if (subType == RandCoop.RCTP_MIN) {
                return Convars.GetFloat("rand_vscript_hunter_min");
            } else {
                return Convars.GetFloat("rand_vscript_hunter_max");
            }

        case RandCoop.RCTP_CHARGER:
            if (subType == RandCoop.RCTP_MIN) {
                return Convars.GetFloat("rand_vscript_charger_min");
            } else {
                return Convars.GetFloat("rand_vscript_charger_max");
            }

        case RandCoop.RCTP_JOCKEY:
            if (subType == RandCoop.RCTP_MIN) {
                return Convars.GetFloat("rand_vscript_jockey_min");
            } else {
                return Convars.GetFloat("rand_vscript_jockey_max");
            }

        case RandCoop.RCTP_SUPPORT:
            if (subType == RandCoop.RCTP_MIN) {
                return Convars.GetFloat("rand_vscript_support_min");
            } else {
                return Convars.GetFloat("rand_vscript_support_max");
            }
    }
}

function RandCoop::GetSpecialConvarValue ( type )
{
    switch (type) {
        case RandCoop.RCTP_SPAWNING_TIMEOUT:
            return Convars.GetFloat("rand_vscript_spawning_timeout");

        case RandCoop.RCTP_ENCOUNTER_TIMEOUT:
            return Convars.GetFloat("rand_vscript_encounter_timeout");

        case RandCoop.RCTP_BUILDUP:
            return Convars.GetFloat("rand_vscript_buildup");

        case RandCoop.RCTP_GRACETIME:
            return Convars.GetFloat("rand_vscript_gracetime");

        case RandCoop.RCTP_GRACETIME_LONG:
            return Convars.GetFloat("rand_vscript_gracetime_long");

        case RandCoop.RCTP_NORMAL_ENC_INTERVAL:
            return Convars.GetFloat("rand_vscript_normal_enc_interval");

        case RandCoop.RCTP_NORMAL_JOCKEY_INTERVAL:
            return Convars.GetFloat("rand_vscript_normal_jockey_interval");

        case RandCoop.RCTP_CHARGESPIT_TOTAL:
            return Convars.GetFloat("rand_vscript_chargespit_total");

        case RandCoop.RCTP_CHARGESPIT_DOMINATOR:
            return Convars.GetFloat("rand_vscript_chargespit_dom");

        case RandCoop.RCTP_CHARGESPIT_CHARGER:
            return Convars.GetFloat("rand_vscript_chargespit_charger");

        case RandCoop.RCTP_CHARGESPIT_SPITTER:
            return Convars.GetFloat("rand_vscript_chargespit_spitter");

        case RandCoop.RCTP_BIGATTACK_TOTAL:
            return Convars.GetFloat("rand_vscript_bigattack_total");

        case RandCoop.RCTP_BIGATTACK_DOMINATOR:
            return Convars.GetFloat("rand_vscript_bigattack_dom");

        case RandCoop.RCTP_BIGATTACK_BOOMER:
            return Convars.GetFloat("rand_vscript_bigattack_boomer");

        case RandCoop.RCTP_BIGATTACK_SMOKER:
            return Convars.GetFloat("rand_vscript_bigattack_smoker");

        case RandCoop.RCTP_BIGATTACK_SPITTER:
            return Convars.GetFloat("rand_vscript_bigattack_spitter");

        case RandCoop.RCTP_BIGATTACK_JOCKEY:
            return Convars.GetFloat("rand_vscript_bigattack_jockey");

    }
}

