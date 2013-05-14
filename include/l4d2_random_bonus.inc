/** Double-include prevention */
#if defined _randombonus_included_
  #endinput
#endif
#define _randombonus_included_
 
 
native RNDBNS_GetBonus();
native Float:RNDBNS_GetBonusMulti();
native RNDBNS_GetStatic();
native RNDBNS_GetDistance();

native RNDBNS_SetBonus(value);
native Float:RNDBNS_SetBonusMulti(Float:value);
native RNDBNS_SetStatic(value);
native RNDBNS_SetDistance(value);

native RNDBNS_SetExtra(value);