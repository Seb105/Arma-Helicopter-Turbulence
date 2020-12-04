#include "script_component.hpp"
ADDON = false;
#include "XEH_PREP.hpp"
[
	"TURBULENCE_ENABLE_MASTER",
	"CHECKBOX",
	["Enable Turbulence","Enables turbulence system. Requires getting in & out of aircraft for change to take effect."],
	"Helicopter Turbulence",
	true,
	0
] call CBA_fnc_addSetting;
[
	"TURBULENCE_ENABLE_WEATHEREFFECT",
	"CHECKBOX",
	["Enable Weather Effects","Enables or disables whether weather has an effect on turbulence. When disabled, the minimum turbulence value is used."],
	"Helicopter Turbulence",
	true,
	0
] call CBA_fnc_addSetting;
[
	"TURBULENCE_MIN_TURBULENCE",
	"SLIDER",
	["Minimum Turbulence","Set the minimum turbulence during calm weather. This number is also ADDED to the maximum turbulence"],
	"Helicopter Turbulence",
	[0,10,3,1],
	0
] call CBA_fnc_addSetting;
[
	"TURBULENCE_MAX_TURBULENCE",
	"SLIDER",
	["Maximum Turbulence","Set the max turbulence during the most severe weather. The minimum turbulence value is also ADDED to this number."],
	"Helicopter Turbulence",
	[0,40,15,1],
	0
] call CBA_fnc_addSetting;
[
	"TURBULENCE_ENABLE_PLANES",
	"CHECKBOX",
	["Enable Plane Turbulence","Enables turbulence system for planes. Requires mission restart."],
	["Helicopter Turbulence","Experimental"],
	false,
	0,
	{},
	true
] call CBA_fnc_addSetting;
ADDON = true;