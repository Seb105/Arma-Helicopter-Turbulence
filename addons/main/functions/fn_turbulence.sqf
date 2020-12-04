#include "script_component.hpp"
/*
 * Author: Seb
 * fn_turbulence adds dynamic turbulence based on weather (overcast and windstrenght) to any vehicle (although it is designed for air vehicles).
 * Units are in metric unless specified, ass addForce command seems to be in Newtons.
 *
 * Arguments:
 * 0: The vehicle to which turbulence effect should be applied <OBJECT, VEHICLE>
 *
 * Return Value:
 * NONE
 *
 * Example:
 * this call HT_fnc_turbulence;
 *
 * Public: No
 */
params ["_vehicle"];
// check not called twice
if (_vehicle getVariable ["TURBULENCE_INITIALSIED", false]) exitWith {};
_vehicle setVariable ["TURBULENCE_INITIALSIED", true];

// master function
private _FNC_master = {
	if !(TURBULENCE_ENABLE_MASTER) exitWith{};
	params ["_vehicle"];
	// init some vars that need to be interpolated from.
	_vehicle setVariable ["TURBULENCE_STAGE", 1];
	_vehicle setVariable ["TURBULENCE_OLD_FORCE", [0, 0, 0]];
	_vehicle setVariable ["TURBULENCE_OLD_CENTRE", [0, 0, 0]];

	// boundingBoxReal approximates the xyz dimensions of aircraft. Generally returns much larger than actual dimensions
	private _bbr = 2 boundingBoxReal _vehicle;
	private _p1 = _bbr select 0;
	private _p2 = _bbr select 1;
	private _maxWidth = 	abs ((_p2 select 0) - (_p1 select 0));
	private _maxLength = 	abs ((_p2 select 1) - (_p1 select 1));
	private _maxHeight = 	abs ((_p2 select 2) - (_p1 select 2));
	private _dimensions = [_maxWidth, _maxLength, _maxHeight];	

	// assume a spherical cow in a vacuum
	// Approximates aircraft surface area as a cylinder. Then divides by two, as only 1/2 of the face will ever be facing the wind vector. (2πrh+2πr2)/2
	private _surfaceArea = (2*pi*(_maxHeight/2)*_maxLength + 2*pi*(_maxHeight/2)^2)/2;

	private _FNC_turbulence = {
		params ["_vehicle", "_dimensions", "_surfaceArea"];
		if (_vehicle getVariable "TURBULENCE_STAGE" >= 1) then {
			_vehicle setVariable ["TURBULENCE_STAGE", 0];
			// if weather effect is enabled in settings, easeIn to windiness value so that lower windiness/gustiness values have less of an effect.
			private _windiness = [0, [0, 1, (windStr+overcast)/2] call BIS_fnc_easeIn] select TURBULENCE_ENABLE_WEATHEREFFECT;
			// 30 = 30m/s max windspeed at max rain and overcast
			private _maxWindSpeed = (_windiness*TURBULENCE_MAX_TURBULENCE);
			// easeIn is more likely to select a low value, so big gusts are rare
			private _gustSpeed = [TURBULENCE_MIN_TURBULENCE, _maxWindSpeed, random(1)] call BIS_fnc_easeIn;

			// as it gets windier, the minimum gust length decreases so you can get more short sharp jerks
			private _minGustLength = [0.6, 0.3, _windiness] call BIS_fnc_lerp;
			private _maxGustLength = [0.9, 0.4, _windiness] call BIS_fnc_lerp;
			// easeInOut is more likely to pick middling values, so big and small gusts are slightly less common.
			private _gustLength = [_minGustLength, _maxGustLength, random(1)] call BIS_fnc_easeInOut;

			// wind pressure per m^2 = (0.5*density of air*airVelocity^2)/2. This approximates air density as 1.2 when it does depend on the temp and altitude
			private _gustPressure = (0.5*1.2*(_gustSpeed*_gustSpeed))/2;
			// The gust force scalar is the force applied per second per unit surface area, divided by timestep.
			private _gustForceScalar = _gustPressure * 0.05 * _surfaceArea;
			// selects a point on the hull for force the force to be applied.
			private _turbulenceCentre  = _dimensions apply {(random(_x)-(_x/2))};
			// force direction. Pick random direction use gustforcescalar as magnitude.
			private _force = [_gustForceScalar, random(360), random(360)] call CBA_fnc_polar2Vect;
		
			// old forces used for interpolation
			private _oldForce = _vehicle getVariable "TURBULENCE_OLD_FORCE";
			private _oldCentre = _vehicle getVariable "TURBULENCE_OLD_CENTRE";

			// DEBUG
			if (isNull TURBULENCE_DEBUG_STARTED) then {
				TURBULENCE_DEBUG_ARRAY_ALL = [];
				TURBULENCE_DEBUG_STARTED = true;
				TURBULENCE_DEBUG_TIME = 0;
			};
			TURBULENCE_DEBUG_TIME = TURBULENCE_DEBUG_TIME + _gustLength;
			private _DebugArrayThisLoop = [TURBULENCE_DEBUG_TIME,_windiness,_force, _turbulenceCentre,_gustForceScalar];
			systemchat str _DebugArrayThisLoop;
			TURBULENCE_DEBUG_ARRAY_ALL pushback _DebugArrayThisLoop;
			copyToClipboard TURBULENCE_DEBUG_ARRAY_ALL;
			/**/
			// waitAndExecute queues all the physics updates based on t/gust length.
			for "_i" from 0 to _gustLength step 0.05 do {
				[{
					params ["_vehicle", "_force", "_turbulenceCentre", "_i", "_gustLength", "_oldForce", "_oldCentre"];
					private _progress = _i/_gustLength;
					//  private _forceN = [_oldForce, _force, _progress] call BIS_fnc_easeInOutVector;
					private _forceN = [_oldForce, _force, _progress] call BIS_fnc_easeInOutVector;
					private _turbulenceCentreN = [_oldCentre, _turbulenceCentre, _progress] call BIS_fnc_easeInOutVector;
					_vehicle addForce [
						(_vehicle vectorModelToWorld _forceN), 
						_turbulenceCentreN
					];
				},  [_vehicle, _force, _turbulenceCentre, _i, _gustLength, _oldForce, _oldCentre], _i] call CBA_fnc_waitAndExecute;
			};
			// set old forces for next interpolation loop
			_vehicle setVariable ["TURBULENCE_OLD_FORCE", _force];
			_vehicle setVariable ["TURBULENCE_OLD_CENTRE", _turbulenceCentre];
			// set turbulence stage to 1 after the turbulence is over for next loop
			[{
				params ["_vehicle"];
				_vehicle setVariable ["TURBULENCE_STAGE", 1];
			}, [_vehicle], _gustLength] call CBA_fnc_waitandExecute;
		};
	};

	[{
		_this#0 params ["_FNC_turbulence", "_vehicle", "_dimensions", "_surfaceArea"];
		// if player is no longer in vehicle, remove per frame event handler.
		if (vehicle player == _vehicle) then {
			// if player is the Pilot and  game is not paused and Rotorlib Advanced Flight Model is NOT enabled and vehicle engine is on, cause turbulence.
			if (driver _vehicle == player && !isGamePaused && !difficultyEnabledRTD && isEngineOn _vehicle) then {
				[_vehicle, _dimensions, _surfaceArea] call _FNC_turbulence;
			};

		} else {
			[_handle] call CBA_fnc_removePerFrameHandler;
		};

	},  
	0.05 //Physics update rate.
	, [_FNC_turbulence, _vehicle, _dimensions, _surfaceArea]] call CBA_fnc_addPerFrameHandler;
};
// add event handler for getting into a helicopter
[_vehicle,  "getIn",  {
	params ["_vehicle",  "_role",  "_unit",  "_turret"];
	private _FNC_master = _thisArgs;
	if (player == _unit) then {
		_vehicle call _FNC_master;
	}
}, _FNC_master] call CBA_fnc_addBISEventHandler;

// if the player starts mission in a helicopter, start turbulence.
if (_vehicle == vehicle player) then {
	_vehicle call _FNC_master;
};