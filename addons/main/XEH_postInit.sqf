#include "script_component.hpp"
[] spawn {
	if (!hasInterface) exitWith {};
	waitUntil {!isNull player};
	["Helicopter", "InitPost", {
		_this call HT_fnc_turbulence;
	},true,[],true] call CBA_fnc_addClassEventHandler;
};