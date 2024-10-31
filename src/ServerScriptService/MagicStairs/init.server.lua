-- Copyright (©) 2024 Metatable Games
-- Written by vq9o

-- License: MIT
-- GitHub: https://github.com/RAMPAGELLC/magicstairs

local Selection = game:GetService("Selection")
local ChangeHistoryService = game:GetService("ChangeHistoryService")

local PLUGIN_ID = "MAGICSTAIRSBYMETA"
local PLUGIN_NAME = "Magic Stairs"
local PLUGIN_ICON = "rbxassetid://84893381139182"
local PLUGIN_SUMMARY = "Roblox Studio Quick Wedge-to-Stairs Tool"
local IS_LOCAL = (plugin.Name:find(".rbxm") ~= nil)

-- Init
local function getId(str)
	if IS_LOCAL then
		str ..= " (LOCAL)"
	end

	return str
end

local button
local pluginName = getId(PLUGIN_NAME)
local widgetName = getId(script.Name)

local Gui = script.Gui:Clone()
Gui.Name = widgetName;

if not _G.MetaToolbar then
	_G.MetaToolbar = plugin:CreateToolbar("Plugins by Meta")
end

local buttonId = getId(PLUGIN_ID)
button = _G[buttonId]

if not button then
	button = _G.MetaToolbar:CreateButton(pluginName, PLUGIN_SUMMARY, PLUGIN_ICON)
	_G[buttonId] = button
end

if game.CoreGui:FindFirstChild(Gui.Name) then
	game.CoreGui:FindFirstChild(Gui.Name):Destroy()
end

Gui.Enabled = false
Gui.Parent = game.CoreGui
require(script.Dragify)(Gui.Framework);

button.Click:Connect(function()
	Gui.Enabled = not Gui.Enabled
end)

Gui:GetPropertyChangedSignal("Enabled"):Connect(function()
	button:SetActive(Gui.Enabled)
end)

button:SetActive(Gui.Enabled)

-- Plugin
local default_config = {
	DeleteWedge = false;
	MatchAppearance = true;
	YStep = 10;
	CapinosW = 1;
	CapinosH = 1;
	CapinosEnabled = true;
}

local config = table.clone(default_config)

for i,v in pairs(Gui.Framework.Config:GetChildren()) do
	local label = v:FindFirstChildWhichIsA("TextLabel", true)
	
	if label then
		v.MouseEnter:Connect(function()
			label.Visible = true
		end)
		
		v.MouseLeave:Connect(function()
			label.Visible = false
		end)
	end
end

Gui.Framework.Config.Reset.Button.MouseButton1Down:Connect(function()
	config = table.clone(default_config)

	for i,v in pairs(config) do
		if typeof(v) == "boolean" then
			Gui.Framework.Config[i].Button.ImageLabel.Image = v and "rbxassetid://128204862114598" or "rbxassetid://129002410710566"
		else
			Gui.Framework.Config[i].TextBox.Text = v;
		end
	end
end)

for i,v in pairs(config) do
	if typeof(v) == "boolean" then
		Gui.Framework.Config[i].Button.ImageLabel.Image = v and "rbxassetid://128204862114598" or "rbxassetid://129002410710566"

		Gui.Framework.Config[i].Button.MouseButton1Down:Connect(function()
			v = not v;
			config[i] = v;
			Gui.Framework.Config[i].Button.ImageLabel.Image = v and "rbxassetid://128204862114598" or "rbxassetid://129002410710566"
		end)
	else
		Gui.Framework.Config[i].TextBox.Text = v;

		Gui.Framework.Config[i].TextBox.FocusLost:Connect(function(enterPressed)
			if not enterPressed then
				return
			end

			local newValue = Gui.Framework.Config[i].TextBox.Text;
			
			if newValue == "" then
				return
			end

			config[i] = newValue
		end)
	end
end

Selection.SelectionChanged:Connect(function()
	if not Gui.Enabled then
		return;
	end

	local parts = Selection:Get()
	local wedge = parts[#parts]

	if not wedge then
		return;
	end

	if not wedge:IsA("WedgePart") and not (wedge:IsA("Part") and wedge.Shape == Enum.PartType.Wedge) then
		warn("Selected instance must be a WedgePart!")
		return;
	end

	local number = math.floor(tonumber(config.YStep) or 10)

	if number < 1 then
		warn("Step count is below 1!")
		return
	end  

	local cf = wedge.CFrame
	local size = wedge.Size

	local recording = ChangeHistoryService:TryBeginRecording("ConvertWedge", "Converting Wedge")
	local count = 30

	if not recording then
		warn("Failed to record Change History Event for Convert Wedge!")
		return
	end

	local model = Instance.new("Model", wedge.Parent)
	model.Name = "Stairs"

	local sizeY = (size.Y / number)
	
	for i = 1, number do
		local part = Instance.new("Part")
		part.Name = `STAIR_{i}`

		local sizeZ = size.Z / number * i

		part.CFrame = cf * CFrame.new(
			0,
			(size.Y / number * (number - i)) - size.Y / 2 + sizeY / 2,
			size.Z / 2 - sizeZ / 2
		)

		part.Size = Vector3.new(size.X, sizeY, sizeZ)
		
		if config.MatchAppearance then
			part.Transparency = wedge.Transparency
			part.Reflectance = wedge.Reflectance
			part.Massless = wedge.Massless
			part.CanCollide = wedge.CanCollide
			part.MaterialVariant = wedge.MaterialVariant
			part.CastShadow = wedge.CastShadow
			part.BottomSurface = Enum.SurfaceType.Smooth
			part.TopSurface = Enum.SurfaceType.Smooth
			part.Anchored = wedge.Anchored
			part.Material = wedge.Material
			part.Color = wedge.Color
		end
		
		part.Parent = model

		if config.CapinosEnabled then
			local capinos = Instance.new("Part")
			capinos.Name = `CAPINOS_{i}`

			local width = math.max(0.03, tonumber(config.CapinosW) or 1)
			local height = math.max(0.03, tonumber(config.CapinosH) or 1)

			capinos.CFrame = part.CFrame * CFrame.new(
				0,
				part.Size.Y / 2 + height / 2,
				-width / 2
			)

			capinos.Size = Vector3.new(part.Size.X, height, part.Size.Z + width)
			capinos.BottomSurface = Enum.SurfaceType.Smooth
			capinos.TopSurface = Enum.SurfaceType.Smooth
			capinos.Anchored = true
			capinos.Parent = model
		end
	end

	Selection:Set({model})

	if config.DeleteWedge then
		local saveWedge = wedge
		
		task.defer(function()
			if saveWedge then
				saveWedge:Destroy()
			end
		end)
		
		Selection:Remove({wedge})
	end

	if recording then
		ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
	end
end)