-- Merge stacks of drinks in the selected stockpile
local utils = require 'utils'

validArgs = validArgs or utils.invert({ 'max' })
local args = utils.processArgs({...}, validArgs)

local max = 30;
if args.max then max = tonumber(args.max) end

local function itemsCompatible(item0, item1)
	return item0:getType() == item1:getType() 
		and item0.mat_type == item1.mat_type 
		and item0.mat_index == item1.mat_index
end

local function getDrinks(items, drinks, index)
	for i,d in ipairs(items) do
		local foundDrink = nil

		-- Skip items currently tasked
		if #d.specific_refs == 0 then

			if d:getType() == 68 then 
				foundDrink = d 

			else
				print(d.id)
				local containedItems = dfhack.items.getContainedItems(d)
				-- Drink containers only contain one item
				if #containedItems == 1 then
					local possibleDrink = containedItems[1]

					if #possibleDrink.specific_refs == 0 and possibleDrink:getType() == 68 then
						foundDrink = possibleDrink
					end
				end
			end
		end

		if foundDrink ~= nil then
			drinks[index] = foundDrink
			index = index + 1
		end
	end

	return index
end

local building = dfhack.gui.getSelectedBuilding(true)
if building ~= nil and building:getType() ~= 29 then building = nil end

if building == nil then
	error("Select a stockpile")

else
	local rootItems = dfhack.buildings.getStockpileContents(building);

	if #rootItems == 0 then
		error("Stockpile is empty")

	else
		local drinks = { }
		local drinkCount = getDrinks(rootItems, drinks, 0)

		local removedDrinks = { }

		for i=0,(drinkCount-2) do
			local currentDrink = drinks[i]
			local itemsNeeded = max - currentDrink.stack_size

			if removedDrinks[currentDrink.id] == nil and itemsNeeded > 0 then
				for j=(i+1),(drinkCount-1) do
					local sourceDrink = drinks[j]

					if removedDrinks[sourceDrink.id] == nil and itemsCompatible(currentDrink, sourceDrink) then
						local amountToMove = math.min(itemsNeeded, sourceDrink.stack_size)
						itemsNeeded = itemsNeeded - amountToMove
						currentDrink.stack_size = currentDrink.stack_size + amountToMove

						if sourceDrink.stack_size == amountToMove then
							removedDrinks[sourceDrink.id] = true
							sourceDrink.stack_size = 1
						else
							sourceDrink.stack_size = sourceDrink.stack_size - amountToMove
						end
					end
				end
			end
		end

		for id,removed in pairs(removedDrinks) do
			if removed then
				local removedDrink = df.item.find(id)
				dfhack.items.remove(removedDrink)
			end
		end
	end
end
