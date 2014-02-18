--- Title scene.

--
-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:
--
-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
-- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
-- CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
-- TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
-- SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--
-- [ MIT license: http://www.opensource.org/licenses/mit-license.php ]
--

-- Standard library imports --
local floor = math.floor

-- Modules --
local energy = require("energy")

-- Corona globals --
local display = display
local native = native
local system = system

-- Corona modules --
local storyboard = require("storyboard")
local widget = require("widget")

-- --
local Scene = storyboard.newScene()

--
function Scene:createScene ()
	if system.getInfo("environment") == "simulator" then
		widget.setTheme("widget_theme_ios")
	end

	self.view:insert(widget.newButton{
		x = display.contentCenterX, y = display.contentHeight - 50, label = "Begin!",

		onRelease = function()
			storyboard.gotoScene("game")
		end
	})

	self.view:insert(display.newText{
		text = [[Oh no! The THING has too much energy!

				Drag the globes into the slots to calm it down, and hold it off for 30 seconds!

				Pop the blobs to keep them away!]],
		x = display.contentCenterX, y = display.contentCenterY,
		width = floor(.75 * display.contentWidth), font = native.systemFont, fontSize = 32
	})
end

Scene:addEventListener("createScene")

--
function Scene:enterScene ()
	energy.SetEnergy(nil)
end

Scene:addEventListener("enterScene")

--
return Scene
