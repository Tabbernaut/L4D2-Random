/** Double-include prevention */
#if defined _randombonus_included_
  #endinput
#endif
#define _randombonus_included_
 
// get/set bonus (base, solid health worth factor, static survival bonus, dist/base scale mode)
native RNDBNS_GetBonus();
native Float:RNDBNS_GetSolidFactor();
native RNDBNS_GetStatic();
native RNDBNS_GetScaleMode();

native RNDBNS_SetBonus(value);
native Float:RNDBNS_SetSolidFactor(Float:value);
native RNDBNS_SetStatic(value);
native RNDBNS_SetScaleMode(value);

// set gnome bonus
native RNDBNS_SetExtra(value);

// adjust starting health by checking each survivor
// sets the portion of solid health in the max damage value
native RNDBNS_CheckStartHealth();