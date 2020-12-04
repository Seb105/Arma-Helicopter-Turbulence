#include "script_component.hpp"
0 spawn {
	if (!hasInterface) exitWith {};
	waitUntil {!isNull player};
	// checks if experimental plane feature is enabled. Adds for all Air if true, just helos and VTOLs if false.
	if (TURBULENCE_ENABLE_PLANES) then {
		["Air", "InitPost", {
			_this call HT_fnc_turbulence;
		},true,[],true] call CBA_fnc_addClassEventHandler;

	} else {

		["Helicopter", "InitPost", {
			_this call HT_fnc_turbulence;
		},true,[],true] call CBA_fnc_addClassEventHandler;

		["VTOL_Base_F ", "InitPost", {
			_this call HT_fnc_turbulence;
		},true,[],true] call CBA_fnc_addClassEventHandler;

	};
};