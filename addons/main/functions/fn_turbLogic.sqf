/*
 * Author: Seb
 * Should not be called by itself. See HT_fnc_turbulence instead.

 * Example:
 * vehicle call HT_fnc_turbulence;
 *
 * Public: No
 */
params ["_vehicle", "_dimensions", "_surfaceArea"];
_vehicle setVariable ["TURBULENCE_READY", false];
// if weather effect is enabled in settings, easeIn to windiness value so that lower windiness/gustiness values have less of an effect.
private _windiness = [0, [0, 1, (windStr+overcast)/2] call BIS_fnc_easeIn] select TURBULENCE_ENABLE_WEATHEREFFECT;
// 30 = 30m/s max windspeed at max rain and overcast
private _maxWindSpeed = (_windiness*TURBULENCE_MAX_TURBULENCE)+TURBULENCE_MIN_TURBULENCE;
// easeIn is more likely to select a low value, so big gusts are rare
private _gustSpeed = [TURBULENCE_MIN_TURBULENCE, _maxWindSpeed, random(1)] call BIS_fnc_easeIn;

// as it gets windier, the minimum gust length decreases so you can get more short sharp jerks
private _minGustLength = [0.6, 0.4, _windiness] call BIS_fnc_lerp;
private _maxGustLength = [0.7, 0.6, _windiness] call BIS_fnc_lerp;
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

/*/ DEBUG
if (isNull TURBULENCE_DEBUG_STARTED) then {
    TURBULENCE_DEBUG_ARRAY_ALL = [];
    TURBULENCE_DEBUG_STARTED = true;
    TURBULENCE_DEBUG_TIME = 0;
};
TURBULENCE_DEBUG_TIME = TURBULENCE_DEBUG_TIME + _gustLength;
private _surfaceAreaToMassRatio = _surfaceArea/(getmass _vehicle);
private _DebugArrayThisLoop = [TURBULENCE_DEBUG_TIME, _gustLength, _surfaceAreaToMassRatio, _windiness, _force, _turbulenceCentre,_gustForceScalar];
systemchat str _DebugArrayThisLoop;
TURBULENCE_DEBUG_ARRAY_ALL pushback _DebugArrayThisLoop;
copyToClipboard str TURBULENCE_DEBUG_ARRAY_ALL;
/**/
// waitAndExecute queues all the physics updates based on t/gust length.
if (!isGamePaused && !difficultyEnabledRTD && isEngineOn _vehicle) then {    
        for "_i" from 0 to _gustLength step 0.05 do {
        [{
            params ["_vehicle", "_force", "_turbulenceCentre", "_i", "_gustLength", "_oldForce", "_oldCentre"];
            private _progress = _i/_gustLength;
            private _forceN = [_oldForce, _force, _progress] call BIS_fnc_easeInOutVector;
            private _turbulenceCentreN = [_oldCentre, _turbulenceCentre, _progress] call BIS_fnc_easeInOutVector;
            _vehicle addForce [
                (_vehicle vectorModelToWorld _forceN),
                _turbulenceCentreN
            ];
        },  [_vehicle, _force, _turbulenceCentre, _i, _gustLength, _oldForce, _oldCentre], _i] call CBA_fnc_waitAndExecute;
    };
};
// set old forces for next interpolation loop
_vehicle setVariable ["TURBULENCE_OLD_FORCE", _force];
_vehicle setVariable ["TURBULENCE_OLD_CENTRE", _turbulenceCentre];
// set turbulence stage to 1 after the turbulence is over for next loop
[{
    params ["_vehicle"];
    _vehicle setVariable ["TURBULENCE_READY", true];
}, [_vehicle], _gustLength] call CBA_fnc_waitandExecute;