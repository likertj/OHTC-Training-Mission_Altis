// Written by Weasel [PXS] - andy@andymoore.ca

// This script rearms, refuels, and repairs vehicles.
// Vehicles must be less than height 2 (typically landed, if air vehicles) and must remain in the
// trigger area for 3 seconds. It then drains all fuel, repairs, rearms, and refuels.
//
// Setup a trigger area to activate this (F3 in map editor) with the following settings:
//
// Trigger REPEATEDLY, BLUFOR, PRESENT
// Name: Rearmlist
// Condition: this;
// Activation: {[_x] execVM "vrearm\vresupply.sqf"} foreach thislist;
// 
// Warning: If this trigger area overlaps another trigger area (such as ammo-transport Scripts), sometimes
// things don't work as planned. Keep this seperate if you can.

_unit = _this select 0;

// Don't start the script until the unit is below a height of 2, and make sure they hold that 
// height for at least 3 seconds.
WaitUntil{(getPos _unit select 2)<2}; 
sleep 3;
if((getPos _unit select 2)>2) exitWith{};
WaitUntil{speed _unit < 2};
sleep 3;
if(speed _unit > 5) exitWith{};

// Make sure unit is inside one of these lists (trigger areas)
if( not (_unit in list rearmlist1) and  not (_unit in list rearmlist2) and not (_unit in list rearmlist3) and not (_unit in list rearmlist4)) exitWith{};

	

_unit setFuel 0;
_unit VehicleChat "Repairing...";
sleep 15;
_unit setDammage 0;
_unit VehicleChat "Rearming...";
sleep 10;
_unit setVehicleAmmo 1;
_unit VehicleChat "Refueling...";
sleep 5;
_unit setFuel 1;
_unit VehicleChat "Finished.";

if(true) exitWith{};