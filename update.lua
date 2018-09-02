--I do not play alliance, so i have no alliance data.

local oldGetTaxiMapID = GetTaxiMapID

local inflight,conversion,data,extra, dataFaction


local playerfaction

local L_destparse = ", (.+)"  -- removes main zone name, leaving only subzone
function ShortenName(name)  -- shorten name to lighten saved vars and display
	return gsub(name, L_destparse, "")
end

local paths = {}

local function shrink(value)
	--shrink the values, just enough.
	return tonumber(string.format("%.4f", value)) * 10000
end

local function GetTaxiPositionID(i)
	local x, y = TaxiNodePosition(i)
	--by replacing all saved
	--variable names with this ID,
	--you can do away with all 
	--language specific localization
	--**all Horde data has been converted
	return tonumber(shrink(x) .. shrink(y))
end

local names = {}
--these lists are populated, as you visit each continent.
local ids = {}

local function GetNameFromPositionID(id)
	return names[id]
end

local function GetPositionIDFromName(name)
	return ids[name]
end
--previous 2 functions 
--are quick reference 
--to help convert names
--into ids

local once


local function ReversFill()
	-- most paths take the same 
	--amount of time going both
	--ways, so this bit will
	--reverse fill in the data
	--created by the second section below

	--note to self: if all paths
	--take same amount of time 
	--going both ways, could  allow
	--for less stored data, if 
	--all calls are weighted 
	--the right way...


	local Flight = dataFaction

	if not Flight then
	--	return
	end
	
	local count = 0
	
	for continent, paths in pairs(Flight) do
		for start, destinations in pairs(paths) do
			for destination, _time in pairs(destinations) do
				if _time ~= 0 then
					local _reverse = paths[destination]
					if _reverse[start] and _reverse[start] == 0 then
						_reverse[start] = _time
						count = count + 1
					end
				end
			end
		end
	end
	extra[playerfaction] = Flight
	if count ~= 0 then
		print(count) --neat to know how many times were reverse filled
	end
end

function GenerateConversionList()
	--makes full id to name list
	--for conversion of user
	--submitted data.

	conversion = conversion or {}
	conversion[playerfaction] = conversion[playerfaction] or {}
	local playerfaction = conversion[playerfaction] 
	
	local id = oldGetTaxiMapID()
	--allows you to store data
	--on a per continent basis
	
	if playerfaction[id]  then
		return id 
	end

	playerfaction[id] = playerfaction[id] or {}

	local paths = playerfaction[id]
	
	local num = NumTaxiNodes()

	for i = 1, num, 1 do
		local name, useable = ShortenName(TaxiNodeName(i))
		if useable == 1 then
			local id = GetTaxiPositionID(i)
			paths[name] = id
		end
	end
	return id
end


local internalCall

--as you visit a flight master
--on each continent, this function
--will convert all name based
--variables into IDs, automatically
function GetStuff()

	playerfaction = UnitFactionGroup("player")


	if not InFlightVars then
		return GetStuff()
	end

	inflight = InFlightVars
	
	IFU_Conversion = IFU_Conversion or {}
	conversion = IFU_Conversion
	
	IFU_Data = IFU_Data or {}
	data = IFU_Data
	
	IFU_Extra = IFU_Extra or {}
	extra = IFU_Extra

	data[playerfaction] = data[playerfaction] or {}
	dataFaction = data[playerfaction] 

	GenerateConversionList()
	ReversFill()

	  --i'm good at making spaghetti code...
	if internalCall then
		return --hate this, but simple
	end

	local faction = dataFaction
	
	local id = oldGetTaxiMapID()
	--allows you to store data
	--on a per continent basis
	
	if faction[id]  then
	--	return id --if we've already collected data for this continent, don't do it again.
	end
	faction[id] = faction[id] or {}

	local paths = faction[id]
	
	internalCall = true --prevents looped function calling, don't like it, but simple enough
	local num = NumTaxiNodes()
	internalCall = nil

	for i = 1, num, 1 do
		local name, useable = ShortenName(TaxiNodeName(i))
		if useable == 1 then
			local id = GetTaxiPositionID(i)

			names[id] = name
			--this fills in the data
			--for the two above functions
			--that let us convert from 
			--names to id, and back.
			ids[name] = id

			paths[id] = {} -- path time list
		end
	end

	
	--fill in all possible destinations for each path
	for source, destinationList in pairs(paths) do
		for i, b in pairs(paths) do
			if i ~= source then
				destinationList[i] = 0
			end
		end
	end

	local Flight = inflight[playerfaction]
	--fill in known times from name based saved variables
	for source, destinationList in pairs(paths) do
		sourceName = GetNameFromPositionID(source)
		if Flight[sourceName] then
			for destination, _time in pairs(Flight[sourceName]) do
				destinationID = GetPositionIDFromName(destination)
				if destinationList[destinationID] then
					destinationList[destinationID] = _time
				end
			end
		end
	end

	return id
	--]]
end



GetTaxiMapID = GetStuff
--one function fires for the FlightMap, and the other for the TaxiRouteMap
hooksecurefunc("NumTaxiNodes", GetStuff)