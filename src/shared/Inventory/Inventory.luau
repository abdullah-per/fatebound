--[[
	Inventory Class
	==============
	
	Manages item storage and inventory operations with a slot-based system.
	Provides comprehensive functionality for adding, removing, moving, and
	stacking items with full type safety and error handling.
	
	Features:
	- Slot-based inventory system
	- Automatic item stacking
	- Move items between slots
	- Item quantity tracking
	- Full serialization support
	- Comprehensive error handling
	- Type safety with Luau typing
	
	Usage:
		local Inventory = require(game.ReplicatedStorage.Inventory.Inventory)
		local inventory = Inventory.new({
			maxSlots = 20,
			owner = player
		})
		
		-- Add items
		inventory:AddItem(sword, 1)
		
		-- Move items
		inventory:MoveItem(1, 2, 1)
		
		-- Check inventory
		if inventory:HasItem("iron_sword", 1) then
			print("Player has iron sword!")
		end
	
	@author Fatebound Team
	@version 1.0.0
--]]

local Item = require(script.Parent.Item)

local Inventory = {}
Inventory.__index = Inventory

--// Inventory Slot
export type InventorySlot = {
	item: Item?,
	quantity: number,
	slotId: number,
}

--// Inventory Properties
export type InventoryProperties = {
	maxSlots: number,
	owner: Player?,
	inventoryId: string?,
}

--// Constructor
function Inventory.new(properties: InventoryProperties): Inventory
	local self = setmetatable({}, Inventory)

	-- Validate required properties
	assert(properties.maxSlots, "Max slots is required")
	assert(properties.maxSlots > 0, "Max slots must be greater than 0")

	-- Set properties
	self.maxSlots = properties.maxSlots
	self.owner = properties.owner
	self.inventoryId = properties.inventoryId or "default"

	-- Initialize slots
	self.slots = {}
	for i = 1, self.maxSlots do
		self.slots[i] = {
			item = nil,
			quantity = 0,
			slotId = i,
		}
	end

	-- Track total items
	self.totalItems = 0
	self.uniqueItems = 0

	return self
end

--// Get inventory size
function Inventory:GetSize(): number
	return self.maxSlots
end

--// Get total items in inventory
function Inventory:GetTotalItems(): number
	return self.totalItems
end

--// Get unique items count
function Inventory:GetUniqueItems(): number
	return self.uniqueItems
end

--// Check if inventory is full
function Inventory:IsFull(): boolean
	return self.uniqueItems >= self.maxSlots
end

--// Check if inventory is empty
function Inventory:IsEmpty(): boolean
	return self.totalItems == 0
end

--// Get slot by ID
function Inventory:GetSlot(slotId: number): InventorySlot?
	if slotId < 1 or slotId > self.maxSlots then
		return nil
	end
	return self.slots[slotId]
end

--// Get all slots
function Inventory:GetAllSlots(): { InventorySlot }
	return self.slots
end

--// Find slot containing item by ID
function Inventory:FindItemSlot(itemId: string): number?
	for slotId, slot in ipairs(self.slots) do
		if slot.item and slot.item.id == itemId then
			return slotId
		end
	end
	return nil
end

--// Find empty slot
function Inventory:FindEmptySlot(): number?
	for slotId, slot in ipairs(self.slots) do
		if not slot.item then
			return slotId
		end
	end
	return nil
end

--// Find slot that can stack with given item
function Inventory:FindStackableSlot(item: Item): number?
	if not item:CanStack() then
		return nil
	end

	for slotId, slot in ipairs(self.slots) do
		if slot.item and slot.item.id == item.id and slot.quantity < slot.item.maxStackSize then
			return slotId
		end
	end
	return nil
end

--// Add item to inventory
function Inventory:AddItem(item: Item, quantity: number): (boolean, string?)
	quantity = quantity or 1

	if quantity <= 0 then
		return false, "Invalid quantity"
	end

	-- Check if item can be stacked
	if item:CanStack() then
		-- Try to find existing stack
		local stackableSlot = self:FindStackableSlot(item)
		if stackableSlot then
			local slot = self.slots[stackableSlot]
			local spaceInStack = slot.item.maxStackSize - slot.quantity
			local amountToAdd = math.min(quantity, spaceInStack)

			slot.quantity += amountToAdd
			self.totalItems += amountToAdd

			-- If there's still quantity to add, try to find another slot
			if amountToAdd < quantity then
				local remainingQuantity = quantity - amountToAdd
				return self:AddItem(item, remainingQuantity)
			end

			return true, "Item added to existing stack"
		end
	end

	-- Find empty slot
	local emptySlot = self:FindEmptySlot()
	if not emptySlot then
		return false, "Inventory is full"
	end

	-- Add to empty slot
	local slot = self.slots[emptySlot]
	slot.item = item:Clone()
	slot.quantity = math.min(quantity, item.maxStackSize)
	self.totalItems += slot.quantity
	self.uniqueItems += 1

	-- If there's still quantity to add, try to add more
	if slot.quantity < quantity then
		local remainingQuantity = quantity - slot.quantity
		return self:AddItem(item, remainingQuantity)
	end

	return true, "Item added to new slot"
end

--// Remove item from inventory
function Inventory:RemoveItem(itemId: string, quantity: number): (boolean, string?)
	quantity = quantity or 1

	if quantity <= 0 then
		return false, "Invalid quantity"
	end

	local slotId = self:FindItemSlot(itemId)
	if not slotId then
		return false, "Item not found in inventory"
	end

	local slot = self.slots[slotId]
	local currentQuantity = slot.quantity

	if currentQuantity < quantity then
		return false, "Not enough items to remove"
	end

	slot.quantity -= quantity
	self.totalItems -= quantity

	-- If slot is empty, clear it
	if slot.quantity <= 0 then
		slot.item = nil
		slot.quantity = 0
		self.uniqueItems -= 1
	end

	return true, "Item removed successfully"
end

--// Remove item from specific slot
function Inventory:RemoveItemFromSlot(slotId: number, quantity: number): (boolean, string?)
	quantity = quantity or 1

	if slotId < 1 or slotId > self.maxSlots then
		return false, "Invalid slot ID"
	end

	local slot = self.slots[slotId]
	if not slot.item then
		return false, "Slot is empty"
	end

	if slot.quantity < quantity then
		return false, "Not enough items in slot"
	end

	slot.quantity -= quantity
	self.totalItems -= quantity

	-- If slot is empty, clear it
	if slot.quantity <= 0 then
		slot.item = nil
		slot.quantity = 0
		self.uniqueItems -= 1
	end

	return true, "Item removed from slot"
end

--// Move item between slots
function Inventory:MoveItem(fromSlotId: number, toSlotId: number, quantity: number): (boolean, string?)
	quantity = quantity or 1

	if fromSlotId < 1 or fromSlotId > self.maxSlots or toSlotId < 1 or toSlotId > self.maxSlots then
		return false, "Invalid slot ID"
	end

	if fromSlotId == toSlotId then
		return false, "Cannot move to same slot"
	end

	local fromSlot = self.slots[fromSlotId]
	local toSlot = self.slots[toSlotId]

	if not fromSlot.item then
		return false, "Source slot is empty"
	end

	if fromSlot.quantity < quantity then
		return false, "Not enough items in source slot"
	end

	-- If destination slot is empty
	if not toSlot.item then
		toSlot.item = fromSlot.item:Clone()
		toSlot.quantity = quantity
		fromSlot.quantity -= quantity
		self.uniqueItems += 1

		-- Clear source slot if empty
		if fromSlot.quantity <= 0 then
			fromSlot.item = nil
			fromSlot.quantity = 0
			self.uniqueItems -= 1
		end

		return true, "Item moved to empty slot"
	end

	-- If destination slot has same item and can stack
	if toSlot.item.id == fromSlot.item.id and toSlot.item:CanStack() then
		local spaceInStack = toSlot.item.maxStackSize - toSlot.quantity
		local amountToMove = math.min(quantity, spaceInStack)

		if amountToMove <= 0 then
			return false, "Destination slot is full"
		end

		toSlot.quantity += amountToMove
		fromSlot.quantity -= amountToMove

		-- Clear source slot if empty
		if fromSlot.quantity <= 0 then
			fromSlot.item = nil
			fromSlot.quantity = 0
			self.uniqueItems -= 1
		end

		return true, "Item stacked in destination slot"
	end

	-- Swap items
	local tempItem = toSlot.item
	local tempQuantity = toSlot.quantity

	toSlot.item = fromSlot.item:Clone()
	toSlot.quantity = quantity
	fromSlot.item = tempItem
	fromSlot.quantity = tempQuantity

	return true, "Items swapped"
end

--// Check if inventory has item
function Inventory:HasItem(itemId: string, quantity: number): boolean
	quantity = quantity or 1

	local totalQuantity = 0
	for _, slot in ipairs(self.slots) do
		if slot.item and slot.item.id == itemId then
			totalQuantity += slot.quantity
			if totalQuantity >= quantity then
				return true
			end
		end
	end

	return false
end

--// Get item count
function Inventory:GetItemCount(itemId: string): number
	local count = 0
	for _, slot in ipairs(self.slots) do
		if slot.item and slot.item.id == itemId then
			count += slot.quantity
		end
	end
	return count
end

--// Get all items (for serialization)
function Inventory:GetAllItems(): { [string]: number }
	local items = {}
	for _, slot in ipairs(self.slots) do
		if slot.item then
			items[slot.item.id] = (items[slot.item.id] or 0) + slot.quantity
		end
	end
	return items
end

--// Clear inventory
function Inventory:Clear(): ()
	for _, slot in ipairs(self.slots) do
		slot.item = nil
		slot.quantity = 0
	end
	self.totalItems = 0
	self.uniqueItems = 0
end

--// Convert to table for serialization
function Inventory:ToTable(): { [string]: any }
	local slotsData = {}
	for i, slot in ipairs(self.slots) do
		slotsData[i] = {
			item = slot.item and slot.item:ToTable() or nil,
			quantity = slot.quantity,
			slotId = slot.slotId,
		}
	end

	return {
		maxSlots = self.maxSlots,
		owner = self.owner,
		inventoryId = self.inventoryId,
		slots = slotsData,
		totalItems = self.totalItems,
		uniqueItems = self.uniqueItems,
	}
end

--// Load from table
function Inventory:LoadFromTable(data: { [string]: any }): ()
	self:Clear()

	if data.slots then
		for i, slotData in ipairs(data.slots) do
			if i <= self.maxSlots and slotData.item then
				self.slots[i].item = Item.new(slotData.item)
				self.slots[i].quantity = slotData.quantity or 0
				self.slots[i].slotId = slotData.slotId or i

				if self.slots[i].item then
					self.totalItems += self.slots[i].quantity
					self.uniqueItems += 1
				end
			end
		end
	end
end

return Inventory
