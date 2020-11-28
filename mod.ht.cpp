name = "{{name}}";
dir = "@{{prefix}}";
author = "{{author}}";
["Helicopter", "InitPost", 
{
	_this call HT_fnc_turbulence;
}
,true,[],true] call CBA_fnc_addClassEventHandler;