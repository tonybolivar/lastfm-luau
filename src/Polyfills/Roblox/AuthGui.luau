--!nocheck
-- AuthGui.Show(parent, url, opts?), displays the Last.fm approval URL in a
-- modal card with a read-only TextBox the user can select-and-copy.
-- Returns the created ScreenGui so callers can :Destroy() it after auth completes.

local AuthGui = {}

function AuthGui.Show(parent, url, opts)
	opts = opts or {}
	local title = opts.Title or "Approve Last.fm access"
	local subtitle = opts.Subtitle or "Open this URL in a browser, then click Allow."

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "LastFMAuth"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.IgnoreGuiInset = true

	local backdrop = Instance.new("Frame")
	backdrop.Name = "Backdrop"
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
	backdrop.BackgroundTransparency = 0.5
	backdrop.BorderSizePixel = 0
	backdrop.Parent = screenGui

	local card = Instance.new("Frame")
	card.Name = "Card"
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.Size = UDim2.new(0.7, 0, 0, 220)
	card.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
	card.BorderSizePixel = 0
	card.Parent = backdrop

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = card

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 20)
	padding.PaddingBottom = UDim.new(0, 20)
	padding.PaddingLeft = UDim.new(0, 20)
	padding.PaddingRight = UDim.new(0, 20)
	padding.Parent = card

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	layout.Padding = UDim.new(0, 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = card

	local titleLabel = Instance.new("TextLabel")
	titleLabel.LayoutOrder = 1
	titleLabel.Size = UDim2.new(1, 0, 0, 28)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 20
	titleLabel.TextXAlignment = Enum.TextXAlignment.Center
	titleLabel.Parent = card

	local subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.LayoutOrder = 2
	subtitleLabel.Size = UDim2.new(1, 0, 0, 40)
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Text = subtitle
	subtitleLabel.TextWrapped = true
	subtitleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	subtitleLabel.Font = Enum.Font.Gotham
	subtitleLabel.TextSize = 14
	subtitleLabel.TextXAlignment = Enum.TextXAlignment.Center
	subtitleLabel.Parent = card

	local urlBox = Instance.new("TextBox")
	urlBox.LayoutOrder = 3
	urlBox.Size = UDim2.new(1, 0, 0, 36)
	urlBox.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
	urlBox.BorderSizePixel = 0
	urlBox.Text = url
	urlBox.TextEditable = false
	urlBox.ClearTextOnFocus = false
	urlBox.TextColor3 = Color3.fromRGB(220, 220, 255)
	urlBox.Font = Enum.Font.RobotoMono
	urlBox.TextSize = 14
	urlBox.TextXAlignment = Enum.TextXAlignment.Left
	urlBox.TextTruncate = Enum.TextTruncate.AtEnd
	urlBox.Parent = card

	local urlCorner = Instance.new("UICorner")
	urlCorner.CornerRadius = UDim.new(0, 8)
	urlCorner.Parent = urlBox

	local urlPad = Instance.new("UIPadding")
	urlPad.PaddingLeft = UDim.new(0, 10)
	urlPad.PaddingRight = UDim.new(0, 10)
	urlPad.Parent = urlBox

	local hint = Instance.new("TextLabel")
	hint.LayoutOrder = 4
	hint.Size = UDim2.new(1, 0, 0, 16)
	hint.BackgroundTransparency = 1
	hint.Text = "Click the URL to select, then Ctrl+C / Cmd+C to copy."
	hint.TextColor3 = Color3.fromRGB(150, 150, 150)
	hint.Font = Enum.Font.Gotham
	hint.TextSize = 12
	hint.TextXAlignment = Enum.TextXAlignment.Center
	hint.Parent = card

	-- Best-effort: try the deprecated browser-open. Harmless if it no-ops.
	pcall(function()
		local GuiService = game:GetService("GuiService")
		if GuiService.OpenBrowserWindow then
			GuiService:OpenBrowserWindow(url)
		end
	end)

	screenGui.Parent = parent
	return screenGui
end

return AuthGui
