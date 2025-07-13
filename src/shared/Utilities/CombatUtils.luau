--// Combat Utilities
-- Shared functions for combat-related operations

--// Get unique parent objects from a list of parts
-- This is useful for hit detection where we want to damage characters, not individual parts
local function getUniqueParentsFromParts(parts: { BasePart }): { Instance }
	local uniqueParents: { Instance } = {}
	local seenParents: { [Instance]: true } = {} -- Used as a set to track seen parents

	for _, part in ipairs(parts) do
		-- Ensure the part is valid and has a parent
		if part and part.Parent then
			local currentParent = part.Parent
			local finalParent = currentParent

			-- If the immediate parent is an Accessory, we want its parent (e.g., the Character Model)
			if currentParent:IsA("Accessory") and currentParent.Parent then
				finalParent = currentParent.Parent
			end

			-- Check if this final parent has already been added to our unique list
			if not seenParents[finalParent] then
				table.insert(uniqueParents, finalParent)
				seenParents[finalParent] = true -- Mark this parent as seen
			end
		end
	end

	return uniqueParents
end

return {
	getUniqueParentsFromParts = getUniqueParentsFromParts,
}
