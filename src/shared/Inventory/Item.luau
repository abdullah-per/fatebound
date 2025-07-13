--[[
	Item Class
	==========
	
	Represents a single item in the inventory system with comprehensive properties
	and functionality for game items like weapons, consumables, materials, etc.
	
	Features:
	- Complete item information (name, description, image, model)
	- Rarity system with color coding
	- Durability system for equipment
	- Stacking support with configurable limits
	- Combat properties (damage, effects)
	- Crafting recipe support
	- Custom properties for extensibility
	
	Usage:
		local Item = require(game.ReplicatedStorage.Inventory.Item)
		local sword = Item.new({
			id = "iron_sword",
			name = "Iron Sword",
			description = "A sharp iron sword",
			itemType = "Weapon",
			rarity = "Uncommon",
			maxStackSize = 1,
			damage = 25
		})
	
	@author Fatebound Team
	@version 1.0.0
--]]

local Item = {}
Item.__index = Item

--// Item Types
export type ItemType = "Weapon" | "Consumable" | "Material" | "Equipment" | "Quest" | "Currency"

--// Item Rarity
export type ItemRarity = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Mythic"

--// Item Properties
export type ItemProperties = {
	-- Basic Information
	id: string,
	name: string,
	description: string,

	-- Visual Information
	imageId: string?, -- Decal ID for item image
	modelPath: string?, -- Path to model in ReplicatedStorage

	-- Classification
	itemType: ItemType,
	rarity: ItemRarity,

	-- Stacking
	maxStackSize: number,

	-- Trade/Use Properties
	tradeable: boolean,
	usable: boolean,
	consumable: boolean,

	-- Combat Properties (for weapons/equipment)
	damage: number?,
	durability: number?,
	maxDurability: number?,

	-- Effects (for consumables/equipment)
	effects: { [string]: any }?,

	-- Crafting
	craftable: boolean?,
	recipe: { [string]: number }?, -- Item ID -> Quantity required

	-- Metadata
	tags: { string }?,
	levelRequirement: number?,

	-- Custom Properties
	customProperties: { [string]: any }?,
}

--// Constructor
function Item.new(properties: ItemProperties): Item
	local self = setmetatable({}, Item)

	-- Validate required properties
	assert(properties.id, "Item ID is required")
	assert(properties.name, "Item name is required")
	assert(properties.description, "Item description is required")
	assert(properties.itemType, "Item type is required")
	assert(properties.rarity, "Item rarity is required")
	assert(properties.maxStackSize, "Max stack size is required")

	-- Set properties
	self.id = properties.id
	self.name = properties.name
	self.description = properties.description
	self.imageId = properties.imageId
	self.modelPath = properties.modelPath
	self.itemType = properties.itemType
	self.rarity = properties.rarity
	self.maxStackSize = properties.maxStackSize
	self.tradeable = properties.tradeable or false
	self.usable = properties.usable or false
	self.consumable = properties.consumable or false
	self.damage = properties.damage
	self.durability = properties.durability
	self.maxDurability = properties.maxDurability
	self.effects = properties.effects or {}
	self.craftable = properties.craftable or false
	self.recipe = properties.recipe or {}
	self.tags = properties.tags or {}
	self.levelRequirement = properties.levelRequirement or 0
	self.customProperties = properties.customProperties or {}

	return self
end

--// Get item display name with rarity color
function Item:GetDisplayName(): string
	return self.name
end

--// Get item description
function Item:GetDescription(): string
	return self.description
end

--// Check if item can be stacked
function Item:CanStack(): boolean
	return self.maxStackSize > 1
end

--// Check if item is at max durability
function Item:IsAtMaxDurability(): boolean
	if not self.maxDurability then
		return true
	end
	return self.durability and self.durability >= self.maxDurability
end

--// Check if item is broken (durability <= 0)
function Item:IsBroken(): boolean
	if not self.durability then
		return false
	end
	return self.durability <= 0
end

--// Get durability percentage
function Item:GetDurabilityPercentage(): number
	if not self.maxDurability or not self.durability then
		return 100
	end
	return math.floor((self.durability / self.maxDurability) * 100)
end

--// Check if item can be used
function Item:CanUse(): boolean
	return self.usable and not self:IsBroken()
end

--// Check if item can be traded
function Item:CanTrade(): boolean
	return self.tradeable and not self:IsBroken()
end

--// Get rarity color (for UI)
function Item:GetRarityColor(): Color3
	local rarityColors = {
		Common = Color3.fromRGB(200, 200, 200),
		Uncommon = Color3.fromRGB(0, 255, 0),
		Rare = Color3.fromRGB(0, 100, 255),
		Epic = Color3.fromRGB(200, 0, 255),
		Legendary = Color3.fromRGB(255, 165, 0),
		Mythic = Color3.fromRGB(255, 0, 0),
	}

	return rarityColors[self.rarity] or Color3.fromRGB(200, 200, 200)
end

--// Clone item
function Item:Clone(): Item
	local clonedProperties = {
		id = self.id,
		name = self.name,
		description = self.description,
		imageId = self.imageId,
		modelPath = self.modelPath,
		itemType = self.itemType,
		rarity = self.rarity,
		maxStackSize = self.maxStackSize,
		tradeable = self.tradeable,
		usable = self.usable,
		consumable = self.consumable,
		damage = self.damage,
		durability = self.durability,
		maxDurability = self.maxDurability,
		effects = self.effects,
		craftable = self.craftable,
		recipe = self.recipe,
		tags = self.tags,
		levelRequirement = self.levelRequirement,
		customProperties = self.customProperties,
	}

	return Item.new(clonedProperties)
end

--// Convert to table for serialization
function Item:ToTable(): { [string]: any }
	return {
		id = self.id,
		name = self.name,
		description = self.description,
		imageId = self.imageId,
		modelPath = self.modelPath,
		itemType = self.itemType,
		rarity = self.rarity,
		maxStackSize = self.maxStackSize,
		tradeable = self.tradeable,
		usable = self.usable,
		consumable = self.consumable,
		damage = self.damage,
		durability = self.durability,
		maxDurability = self.maxDurability,
		effects = self.effects,
		craftable = self.craftable,
		recipe = self.recipe,
		tags = self.tags,
		levelRequirement = self.levelRequirement,
		customProperties = self.customProperties,
	}
end

return Item
