/************************************
	DMS Dynamic Mission
	Called from DMS_selectMission
	Created By Heavy
*************************************/

diag_log text format["[DMS DYNAMIC] CRASHED M113 mission has started."];

private ["_num", "_group", "_pos", "_side", "_extraParams", "_OK", "_difficulty", "_AICount", "_type", "_launcher", "_crate1", "_rndDir", "_building", "_vehClass1", "_vehicle1", "_vehClass2", "_vehicle2", "_crate_loot_values1", "_missionAIUnits", "_missionObjs", "_msgStart", "_msgWIN", "_msgLOSE", "_missionName", "_markers", "_time", "_added", "_cleanup"];

// For logging purposes
_num = DMS_MissionCount;


// Set mission side (only "bandit" is supported for now)
_side = "bandit";


// This part is unnecessary, but exists just as an example to format the parameters for "DMS_fnc_MissionParams" if you want to explicitly define the calling parameters for DMS_fnc_FindSafePos.
// It also allows anybody to modify the default calling parameters easily.
if ((isNil "_this") || {_this isEqualTo [] || {(typeName _this)!="ARRAY"}}) then
{
	_this =
	[
		[10,DMS_WaterNearBlacklist,DMS_MinSurfaceNormal,DMS_SpawnZoneNearBlacklist,DMS_TraderZoneNearBlacklist,DMS_MissionNearBlacklist,DMS_PlayerNearBlacklist,DMS_TerritoryNearBlacklist,DMS_ThrottleBlacklists],
		[
			[]
		],
		_this
	];
};

// Check calling parameters for manually defined mission position.
// You can use _extraParams to define which vehicles to spawn. _vehClass1, [_vehClass1], or [_vehClass1,_vehClass2]
_OK = (_this call DMS_fnc_MissionParams) params
[
	["_pos",[],[[]],[3]],
	["_extraParams",[]]
];

if !(_OK) exitWith
{
	diag_log format ["DMS ERROR :: Called MISSION crashed_m113.sqf with invalid parameters: %1",_this];
};


// Set general mission difficulty
_difficulty = "moderate";


// Create AI
_AICount = 5 + (round (random 1));

_group =
[
	_pos,					// Position of AI
	_AICount,				// Number of AI
	"moderate",				// "random","hardcore","difficult","moderate", or "easy"
	"random", 				// "random","assault","MG","sniper" or "unarmed" OR [_type,_launcher]
	_side 					// "bandit","hero", etc.
] call DMS_fnc_SpawnAIGroup;


// Create Crates
_crate1 = ["Box_NATO_WpsSpecial_F",[(_pos select 0)+10,(_pos select 1)-10,0]] call DMS_fnc_SpawnCrate;

_rndDir = random 180;

_building = createVehicle ["Land_Cargo_Patrol_V1_F",[_pos,10+(random 5),_rndDir+90] call DMS_fnc_SelectOffsetPos,[], 0, "CAN_COLLIDE"];


_vehClass1 = "Exile_Car_Offroad_Repair_Civillian";
_vehClass2 = "Rhsusf_m113_usarmy_M240";

if !(_extraParams isEqualTo []) then
{
	if ((typeName _extraParams)=="STRING") then
	{
		_vehClass1 = _extraParams;
	}
	else
	{
		if (((typeName _extraParams)=="ARRAY") && {(typeName (_extraParams select 0))=="STRING"}) then
		{
			_vehClass1 = _extraParams select 0;

			if (((count _extraParams)>1) && {(typeName (_extraParams select 1))=="STRING"}) then
			{
				_vehClass2 = _extraParams select 1;
			};
		};
	};
};

_vehicle1 = [_vehClass1, [_pos,5+(random 3),_rndDir] call DMS_fnc_SelectOffsetPos] call DMS_fnc_SpawnNonPersistentVehicle;
//_vehicle1 setPosATL ([_pos,5+(random 3),_rndDir] call DMS_fnc_SelectOffsetPos);


_vehicle2 = [_vehClass2, [_pos,5+(random 3),_rndDir+180] call DMS_fnc_SelectOffsetPos] call DMS_fnc_SpawnNonPersistentVehicle;
//_vehicle2 setPosATL ([_pos,5+(random 3),_rndDir+180] call DMS_fnc_SelectOffsetPos);


// Set crate loot values
_crate_loot_values1 =
[
	10,		// Weapons
	15,		// Items
	1 		// Backpacks
];


// Define mission-spawned AI Units
_missionAIUnits =
[
	_group 		// We only spawned the single group for this mission
];

// Define mission-spawned objects and loot values
_missionObjs =
[
	[_building],
	[_vehicle1,_vehicle2],
	[[_crate1,_crate_loot_values1]]
];

// Define Mission Start message
_msgStart = ['#FFFF00',"Bandits have crashed their M113. Eliminate them and recover their vehicle."];

// Define Mission Win message
_msgWIN = ['#0080ff',"The M113 has been secured and the bandits eliminated."];

// Define Mission Lose message
_msgLOSE = ['#FF0000',"The bandits have repaired their M113 and moved on."];

// Define mission name (for map marker and logging)
_missionName = "Disabled M113";

// Create Markers
_markers =
[
	_pos,
	_missionName,
	_difficulty
] call DMS_fnc_CreateMarker;

// Record time here (for logging purposes, otherwise you could just put "diag_tickTime" into the "DMS_AddMissionToMonitor" parameters directly)
_time = diag_tickTime;

// Parse and add mission info to missions monitor
_added =
[
	_pos,
	[
		[
			"kill",
			_group
		],
		[
			"playerNear",
			[_pos,DMS_playerNearRadius]
		]
	],
	[
		_time,
		(DMS_MissionTimeOut select 0) + random((DMS_MissionTimeOut select 1) - (DMS_MissionTimeOut select 0))
	],
	_missionAIUnits,
	_missionObjs,
	[_missionName,_msgWIN,_msgLOSE],
	_markers,
	_side,
	_difficulty,
	[]
] call DMS_fnc_AddMissionToMonitor;

// Check to see if it was added correctly, otherwise delete the stuff
if !(_added) exitWith
{
	diag_log format ["DMS ERROR :: Attempt to set up mission %1 with invalid parameters for DMS_AddMissionToMonitor! Deleting mission objects and resetting DMS_MissionCount.",_missionName];

	// Delete AI units and the crate.
	_cleanup = [];
	{
		_cleanup pushBack _x;
	} forEach _missionAIUnits;

	_cleanup pushBack ((_missionObjs select 0)+(_missionObjs select 1));
	
	{
		_cleanup pushBack (_x select 0);
	} foreach (_missionObjs select 2);

	_cleanup call DMS_fnc_CleanUp;


	// Delete the markers directly
	{deleteMarker _x;} forEach _markers;


	// Reset the mission count
	DMS_MissionCount = DMS_MissionCount - 1;
};


// Notify players
[_missionName,_msgStart] call DMS_fnc_BroadcastMissionStatus;



if (DMS_DEBUG) then
{
	(format ["MISSION: (%1) :: Mission #%2 started at %3 with %4 AI units and %5 difficulty at time %6",_missionName,_num,_pos,_AICount,_difficulty,_time]) call DMS_fnc_DebugLog;
};
