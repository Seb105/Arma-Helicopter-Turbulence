#include "script_component.hpp"

params ["_vehicle"];
private _FNC_master = {
	params ["_vehicle"];
	// init some vars that need to be interpolated from.
	_vehicle setVariable ["TURBULENCE_STAGE",1];
	_vehicle setVariable ["TURBULENCE_OLD_FORCE",[0,0,0]];
	_vehicle setVariable ["TURBULENCE_OLD_CENTRE",[0,0,0]];

	// getMass seems to return something that is approximately equal to mass in lbs, this converts to kg as addForce does appear to be in Newtons
	// private _massKg = (getMass _vehicle) * 0.453;

	// boundingBoxReal approximates the xyz dimensions of aircraft. Generally returns much larger than actual dimensions
	private _bbr = 2 boundingBoxReal _vehicle;
	private _p1 = _bbr select 0;
	private _p2 = _bbr select 1;
	private _maxWidth = 	abs ((_p2 select 0) - (_p1 select 0));
	private _maxLength = 	abs ((_p2 select 1) - (_p1 select 1));
	private _maxHeight = 	abs ((_p2 select 2) - (_p1 select 2));
	private _dimensions = [_maxWidth,_maxLength,_maxHeight];	

	// calculate 3 surface areas: each side, front and back, and top and bottom.
	private _LRsideFaceArea = 		_maxLength * _maxHeight;
	private _frontBackFaceArea = 	_maxWidth * _maxHeight;
	private _topBottomFaceArea = 	_maxWidth * _maxLength;
	// assume a spherical cow in a vacuum
	// average surface area of the aircraft facing wind, then also divided by 2 as boundingBoxReal returns values generally much larger than actual dimensions of the aircraft.
	private _surfaceArea = (_LRsideFaceArea + _frontBackFaceArea +_topBottomFaceArea)/(3*3);

	private _FNC_turbulence = {
		params ["_vehicle","_dimensions","_surfaceArea"];
		if (_vehicle getVariable "TURBULENCE_STAGE" >= 1) then {
			_vehicle setVariable ["TURBULENCE_STAGE",0];
			
			private _windiness = (windStr+overcast)/2;
			// 20 = 20m/s max windspeed at max rain and overcast
			private _maxWindSpeed = (_windiness*20);
			// easeIn is more likely to select a low value, so big gusts are rare
			private _gustSpeed = [3,_maxWindSpeed,random(1)] call BIS_fnc_easeIn;
			// as it gets windier, the minimum gust length decreases so you can get more short jerks
			private _minGustLength = [0.5,0.1,_windiness] call BIS_fnc_lerp;
			// easeInOut is more likely to pick middling values, so big and small gusts are slightly less common.
			private _gustLength = [_minGustLength,1,random(1)] call BIS_fnc_easeInOut;

			// wind pressure per m^2 = (0.5*density of air*airVelocity^2)/2. This approximates air density as 1.2 when it does depend on the temp and altitude
			private _gustPressure = (0.5*1.2*(_gustSpeed*_gustSpeed))/2;
			// as force is applied every 0.05s, and above is a force, impulse = t*f.
			private _gustForceScalar = _gustPressure * 0.05 * _surfaceArea;
			// selects a point on the hull for force the force to be applied.
			private _turbulenceCentre  = _dimensions apply {(random(_x)-(_x/2))};
			// force direction. Pick random direction use gustforcescalar as magnitude.
			private _force = _vehicle vectorModelToWorld ([_gustForceScalar,random(360),random(360)] call CBA_fnc_polar2Vect);
		
			// old forces used for interpolation
			private _oldForce = _vehicle getVariable "TURBULENCE_OLD_FORCE";
			private _oldCentre = _vehicle getVariable "TURBULENCE_OLD_CENTRE";
			// waitAndExecute queues all the physics updates based on t/gust length.
			for "_i" from 0 to _gustLength step 0.05 do {
				[{
					params ["_vehicle","_force","_turbulenceCentre","_i","_gustLength","_oldForce","_oldCentre"];
					private _progress = _i/_gustLength;
					private _forceN = [_oldForce,_force,_progress] call BIS_fnc_easeInOutVector;
					private _turbulenceCentreN = [_oldCentre,_turbulenceCentre,_progress] call BIS_fnc_easeInOutVector;
					_vehicle addForce [
						_forceN,
						_turbulenceCentre
					];
				}, [_vehicle,_force,_turbulenceCentre,_i,_gustLength,_oldForce,_oldCentre],_i] call CBA_fnc_waitAndExecute;
			};
			// set old forces for next interpolation loop
			_vehicle setVariable ["TURBULENCE_OLD_FORCE",_force];
			_vehicle setVariable ["TURBULENCE_OLD_CENTRE",_turbulenceCentre];
			// set turbulence stage to 1 after the turbulence is over for next loop
			[{
				params ["_vehicle"];
				_vehicle setVariable ["TURBULENCE_STAGE",1];
			},[_vehicle],_gustLength] call CBA_fnc_waitandExecute;
		};
	};

	[{
		_this#0 params ["_FNC_turbulence","_vehicle","_dimensions","_surfaceArea"];
		// if player is no longer in vehicle, remove per frame event handler.
		if (vehicle player == _vehicle) then {
			// if player is the Pilot and  game is not paused and Rotorlib Advanced Flight Model is NOT enabled and vehicle engine is on, cause turbulence.
			if (driver _vehicle == player && !isGamePaused && !difficultyEnabledRTD && isEngineOn _vehicle) then {
				[_vehicle,_dimensions,_surfaceArea] call _FNC_turbulence;
			};

		} else {
			[_handle] call CBA_fnc_removePerFrameHandler;
		};

	}, 
	0.05 //Physics update rate.
	,[_FNC_turbulence,_vehicle,_dimensions,_surfaceArea]] call CBA_fnc_addPerFrameHandler;
};
// add event handler for getting into a helicopter
[_vehicle, "getIn", {
	params ["_vehicle", "_role", "_unit", "_turret"];
	private _FNC_master = _thisArgs;
	if (player == _unit) then {
		_vehicle call _FNC_master;
	}
},_FNC_master] call CBA_fnc_addBISEventHandler;

// if the player starts mission in a helicopter, start turbulence.
if (_vehicle == vehicle player) then {
	_vehicle call _FNC_master;
};