#include "script_component.hpp"
0 spawn {
	if (!hasInterface) exitWith {};
	waitUntil {!isNull player};
	// if controlled vehicle changes
	["vehicle", {
		params ["_unit", "_newVehicle", "_oldVehicle"];
		if (_newVehicle isKindOf "Helicopter") then {
			_newVehicle call Helicopter_Turbulence_fnc_turbulence;
		};
	}] call CBA_fnc_addPlayerEventHandler;

	// if player starts in vehicle
	private _currentUnit = call CBA_fnc_currentUnit;
	private _controlledVehicle = vehicle _currentUnit;
	if (_controlledVehicle isKindof "Helicopter") then {
		_controlledVehicle call Helicopter_Turbulence_fnc_turbulence;
	};
};