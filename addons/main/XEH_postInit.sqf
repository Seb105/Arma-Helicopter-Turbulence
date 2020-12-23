#include "script_component.hpp"
0 spawn {
	if (!hasInterface) exitWith {};
	waitUntil {!isNull player};
	// checks if experimental plane feature is enabled. Adds for all Air if true, just Helos and VTOLs if false.
	if (TURBULENCE_ENABLE_PLANES) then {

		// if controlled vehicle changes
		["vehicle", {
			params ["_unit", "_newVehicle", "_oldVehicle"];
			if (_newVehicle isKindOf "Air") then {
				_newVehicle call HT_fnc_turbulence;
			};
		}] call CBA_fnc_addPlayerEventHandler;

		// if player starts in vehicle
		if ((vehicle player) isKindof "Air") then {
			(vehicle player) call HT_fnc_turbulence;
		};

	} else {

		// if controlled vehicle changes
		["vehicle", {
			params ["_unit", "_newVehicle", "_oldVehicle"];
			if (_newVehicle isKindOf "VTOL_Base_F" OR _newVehicle isKindOf "Helicopter") then {
				_newVehicle call HT_fnc_turbulence;
			};
		}] call CBA_fnc_addPlayerEventHandler;

		// if player starts in vehicle
		if ((vehicle player) isKindof "VTOL_Base_F" OR (vehicle player) isKindof "Helicopter") then {
			(vehicle player) call HT_fnc_turbulence;
		};

	};
};