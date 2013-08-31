/* 
AMBIENT CIVILIAN SCRIPT - MP COMPATIBLE
tpw 20130829

    - This script will gradually spawn civilians into houses within a specified radius of the player.
    - Civilian density (how many houses per civilian) can be specified.
    - Civilian density will halve at night.
    - Civilians will then wander from house to house, with a specified number of waypoints
    - If a civilian is killed another will spawn 
    - Civs are removed if more than the specified radius from the player

Disclaimer: Feel free to use and modify this code, on the proviso that you post back changes and improvements so that everyone can benefit from them, and acknowledge the original author (tpw) in any derivative works.     

To use: 
1 - Save this script into your mission directory as eg tpw_civ.sqf
2 - Call it with 0 = [200,15,10] execvm "tpw_civ.sqf", where 200 = radius, 5 = number of waypoints, 10 = how many houses per civilian
*/

if (isDedicated) exitWith {};

private ["_civlist","_sqname","_centree","_centrew","_centrec","_centrer"];

// READ IN VARIABLES
tpw_civ_radius = _this select 0;
tpw_civ_waypoints = _this select 1;
tpw_civ_density = _this select 2;

// VARIABLES
_civlist = ["Civilian_F","C_man_1","C_man_1_1_F","C_man_1_2_F","C_man_1_3_F","C_man_polo_1_F","C_man_polo_2_F","C_man_polo_3_F","C_man_polo_4_F","C_man_polo_5_F","C_man_polo_6_F"];

tpw_civ_civarray = []; // array holding spawned civs
tpw_civ_civnum = 0; // number of civs to spawn

// CREATE AI CENTRES SO SPAWNED UNITS KNOW WHO'S AN ENEMY
_centerC = createCenter civilian;
west setFriend [east, 0];
east setFriend [west, 0];
east setFriend [resistance, 0];
east setFriend [civilian, 0];
civilian setFriend [east, 0];
resistance setFriend [east, 0];

// CREATE ARRAY OF EMPTY SQUADS TO SPAWN CIVS INTO
tpw_civ_civsquadarray = [];
for "_z" from 1 to 100 do
    {
    _sqname = creategroup civilian;
    tpw_civ_civsquadarray set [count tpw_civ_civsquadarray,_sqname];    
    };

// WAYPOINTS AT DIFFERENT HOUSES
tpw_civ_fnc_waypoint = 
    {
    private ["_grp","_house","_m","_pos","_wp"];
    //Pick random position within random house
    _grp = _this select 0;
    _house = tpw_civ_houses select (floor (random (count tpw_civ_houses)));
    _wp = getposasl _house;
    _grp addWaypoint [_wp, 0];
    [_grp, (tpw_civ_waypoints - 1)] setWaypointType "CYCLE";    
    };

// SPAWN CIV INTO EMPTY GROUP
tpw_civ_fnc_civspawn =
    {
    private ["_civ","_spawnpos","_i","_ct","_sqname"];
    // Pick a random house for civ to spawn into
    _spawnpos = getposasl (tpw_civ_houses select (floor (random (count tpw_civ_houses))));
    _civ = _civlist select (floor (random (count _civlist)));

    //Find the first empty civ squad to spawn into
    for "_i" from 1 to (count tpw_civ_civsquadarray) do
        {
        _ct = _i - 1;        
        _sqname = tpw_civ_civsquadarray select _ct;
        if (count units _sqname == 0) exitwith 
            {
            //Spawn civ into empty group
            _civ createUnit [_spawnpos, _sqname];
            
            //Mark it as owned by this player
            (leader _sqname) setvariable ["tpw_civ_owner", [player],true];
            
            //Add it to the array of civs for this player
            tpw_civ_civarray set [count tpw_civ_civarray,leader _sqname];

            //Speed and behaviour
            _sqname setspeedmode "LIMITED";
            _sqname setBehaviour "SAFE";

            //Assign waypoints
            for "_i" from 1 to tpw_civ_waypoints do
                {
                0 = [_sqname] call tpw_civ_fnc_waypoint; 
                };
            [_sqname, (tpw_civ_waypoints - 1)] setWaypointType "CYCLE";
            };
        };
    };
    
// SEE IF ANY CIVS OWNED BY OTHER PLAYERS ARE WITHIN RANGE, WHICH CAN BE USED INSTEAD OF SPAWNING A NEW CIV
tpw_civ_fnc_nearciv =
    {
    private ["_owner"];
        {
        if (isMultiplayer) then 
            {
            // Live units within range
            if (_x distance vehicle player < tpw_civ_radius && alive _x) then 
                {
                _owner = _x getvariable ["tpw_civ_owner",[]];
                
                //Units with owners, but not this player
                if ((count _owner > 0) && !(player in _owner)) exitwith
                    {
                    _owner set [count _owner,player]; // add player as another owner of this civ
                    _x setvariable ["tpw_civ_owner",_owner,true]; // update ownership
                    tpw_civ_civarray set [count tpw_civ_civarray,_x]; // add this civ to the array of civs for this player
                    };
                };
            } foreach allunits;
        };    
    
    //Otherwise, spawn a new civ
    [] call tpw_civ_fnc_civspawn;    
    };    

// PERIODICALLY UPDATE POOL OF ENTERABLE HOUSES NEAR PLAYER, DETERMINE MAX CIVILIAN NUMBER, DISOWN CIVS FROM DEAD PLAYERS IN MP
0 = [] spawn 
    {
    while {true} do
        { 
        private ["_allhouses","_civarray","_deadplayer"];
        _allhouses = nearestObjects [position vehicle player,["House"],tpw_civ_radius]; 
        tpw_civ_houses = []; 
            {
            if (((_x buildingpos 0) select 0) != 0) then 
                {
                tpw_civ_houses  set [count tpw_civ_houses,_x];
                }
            } foreach _allhouses;
        tpw_civ_civnum = floor ((count tpw_civ_houses) / tpw_civ_density);
        
        // Fewer civs at night
        if (daytime < 5 || daytime > 20) then 
            {
            tpw_civ_civnum = floor (tpw_civ_civnum / 2);
            };
            
        // Check if any players have been killed and disown their civs
            if (isMultiplayer) then 
            {
                {
                if ((isplayer _x) && !(alive _x)) then
                    {
                    _deadplayer = _x;
                    _civarray = _x getvariable ["tpw_civarray"];
                        {
                        _x setvariable ["tpw_civ_owner",(_x getvariable "tpw_civ_owner") - [_deadplayer],true];
                        } foreach _civarray;
                    };
                } foreach allunits;    
            };
        sleep 10;
        };
    };
    
// MAIN LOOP - ADD AND REMOVE CIVS AS NECESSARY
while {true} do 
    {
    tpw_civ_removearray = [];
    //hintsilent format ["%1 of %2",count tpw_civ_civarray,tpw_civ_civnum];
    // Add civs if there are less than the calculated civilian density for the player's current location 
    if (count tpw_civ_civarray < tpw_civ_civnum) then
        {
        [] call tpw_civ_fnc_nearciv;
        };
        
        {
        // Remove dead civ from players array (but leave body)
        if !(alive _x) then 
            {
            tpw_civ_removearray set [count tpw_civ_removearray,_x];    
            }
            else
            {    
            // Check if civ is out of range and not visible to player. If so, disown it and remove it from players civ array    
            if (_x distance vehicle player > tpw_civ_radius && ((lineintersects [eyepos player,getposasl _x]) || (terrainintersectasl [eyepos player,getposasl _x]))) then
                {
                _x setvariable ["tpw_civ_owner", (_x getvariable "tpw_civ_owner") - [player],true];            
                tpw_civ_removearray set [count tpw_civ_removearray,_x];    
                };
            
            // Delete the live civ and its waypoints if it's not owned by anyone    
            if (count (_x getvariable ["tpw_civ_owner",[]]) == 0) then
                {
                while {(count (waypoints( group _x))) > 0} do
                    {
                     deleteWaypoint ((waypoints (group _x)) select 0);
                    };
                deletevehicle _x;
                };    
            };    
        } foreach tpw_civ_civarray;
    
    //Update players civ array    
    tpw_civ_civarray =     tpw_civ_civarray - tpw_civ_removearray;
    player setvariable ["tpw_civarray",tpw_civ_civarray,true];    
    sleep random 10;    
    };  