//ARMA3Alpha function LV_fnc_removeGroup v0.1 - by SPUn / lostvar
//removes fillHouse or militarize units 
//Syntax: nul = [LVgroup*] execVM "LV_functions\LV_fnc_removeGroup.sqf";
// * = id number (which is defined in fillHouse or militarize, so if ID is 10 = LVgroup10)
private["_grp"];

_grp = _this select 0;
{
	if(vehicle _x != _x)then{deleteVehicle (vehicle _x);};
	deleteVehicle _x;
}forEach units _grp;