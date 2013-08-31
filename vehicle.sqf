/////////////////////////////////////
//  Simple Vehicle Respawn Script v1.81 for Arma 3
//  by Tophe of Östgöta Ops [OOPS]  
  
if (!isServer) exitWith {};

// Define variables
_unit = _this select 0;
_delay = if (count _this > 1) then {_this select 1} else {60};
_deserted = if (count _this > 2) then {_this select 2} else {300};
_respawns = if (count _this > 3) then {_this select 3} else {0};
_explode = if (count _this > 4) then {_this select 4} else {false};
_dynamic = if (count _this > 5) then {_this select 5} else {false};
_unitinit = if (count _this > 6) then {_this select 6} else {};
_haveinit = if (count _this > 6) then {true} else {false};

_hasname = false;
_unitname = vehicleVarName _unit;
if (isNil _unitname) then {_hasname = false;} else {_hasname = true;};
_noend = true;
_run = true;
_rounds = 0;

if (_delay < 0) then {_delay = 0};
if (_deserted < 0) then {_deserted = 0};
if (_respawns <= 0) then {_respawns= 0; _noend = true;};
if (_respawns > 0) then {_noend = false};

_dir = getDir _unit;
_position = getPosASL _unit;
_type = typeOf _unit;
_dead = false;
_nodelay = false;

/////////////////////////////////////
// Added by naong
if (isNil "FNC_setVehicleInit") then {
    FNC_setVehicleInit = {
        private ["_netID","_unit","_unitinit"];
        
        _netID = _this select 0;
        _unit = objectFromNetID _netID;
        _unitinit = _this select 1;
        
        _unit call compile format ["%1",_unitinit];
    };
};
if (isNil "FNC_setVehicleVarName") then {
    FNC_setVehicleVarName = {
        private ["_netID","_unit","_unitname"];
        
        _netID = _this select 0;
        _unit = objectFromNetID _netID;
        _unitname = _this select 1;
        
        _unit setVehicleVarName _unitname;
        _unit call compile format ["%1=_This; PublicVariable ""%1""",_unitname];
    };
};
/////////////////////////////////////

// Start monitoring the vehicle
while {_run} do 
{    
    sleep (2 + random 10);
      if ((getDammage _unit > 0.8) and ({alive _x} count crew _unit == 0)) then {_dead = true};

    // Check if the vehicle is deserted.
    if (_deserted > 0) then
    {
        if ((getPosASL _unit distance _position > 10) and ({alive _x} count crew _unit == 0) and (getDammage _unit < 0.8)) then 
        {
            _timeout = time + _deserted;
            sleep 0.1;
             waitUntil {_timeout < time or !alive _unit or {alive _x} count crew _unit > 0};
            if ({alive _x} count crew _unit > 0) then {_dead = false}; 
            if ({alive _x} count crew _unit == 0) then {_dead = true; _nodelay =true}; 
            if !(alive _unit) then {_dead = true; _nodelay = false}; 
        };
    };

    // Respawn vehicle
      if (_dead) then 
    {    
        if (_nodelay) then {sleep 0.1; _nodelay = false;} else {sleep _delay;};
        if (_dynamic) then {_position = getPosASL _unit; _dir = getDir _unit;};
        if (_explode) then {_effect = "M_AT" createVehicle getPosASL _unit; _effect setPosASL getPosASL _unit;};
        sleep 0.1;

        deleteVehicle _unit;
        sleep 2;
        _unit = _type createVehicle _position;
        _unit setPosASL _position;
        _unit setDir _dir;
        
        // Modified by naong
        if (_haveinit) then {
            //_unit setVehicleInit format ["%1;", _unitinit];
            //processInitCommands;
            
            [[netID _unit, _unitinit], "FNC_setVehicleInit", true, true] spawn BIS_fnc_MP;
        };
        if (_hasname) then {
            //_unit setVehicleInit format ["%1 = this; this setVehicleVarName ""%1""",_unitname];
            //processInitCommands;
            
            [[netID _unit, _unitname], "FNC_setVehicleVarName", true, true] spawn BIS_fnc_MP;
        };
        _dead = false;
        //////////////////// 
        
        // Check respawn amount
        if !(_noend) then {_rounds = _rounds + 1};
        if ((_rounds == _respawns) and !(_noend)) then {_run = false;};
    };
};  