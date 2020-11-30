#include "script_component.hpp"
ADDON = false;
#include "XEH_PREP.hpp"
[
	"TURBULENCE_ENABLE_MASTER",
	"CHECKBOX",
	["Enable Turbulence","Default: Enabled. Enables turbulence system. Requires getting in & out of aircraft for change to take effect."],
	"Helicopter Turbulence",
	true,
	1
] call CBA_fnc_addSetting;
[
	"TURBULENCE_ENABLE_WEATHEREFFECT",
	"CHECKBOX",
	["Enable Weather Effects","Default: Enabled. Enables or disables whether weather has an effect on turbulence. When disabled, the minimum turbulence value is used."],
	"Helicopter Turbulence",
	true,
	1
] call CBA_fnc_addSetting;
[
	"TURBULENCE_MIN_TURBULENCE",
	"SLIDER",
	["Minimum Turbulence","Default: 7.5. Set the minimum turbulence during calm weather. Setting this to be above the max turbulence causes strange behaviour."],
	"Helicopter Turbulence",
	[0,30,7.5,1],
	1
] call CBA_fnc_addSetting;
[
	"TURBULENCE_MAX_TURBULENCE",
	"SLIDER",
	["Maximum Turbulence","Default: 30. Set the max turbulence during the most severe weather. Setting this to be below the minimum turbulence causes strange behaviour."],
	"Helicopter Turbulence",
	[0,60,30,1],
	1
] call CBA_fnc_addSetting;
ADDON = true;