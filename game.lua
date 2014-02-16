--- Game scene.

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
local abs = math.abs
local cos = math.cos
local ipairs = ipairs
local pi = math.pi
local pow = math.pow
local random = math.random
local sin = math.sin

-- Modules --
local energy = require("energy")

-- Corona globals --
local display = display
local timer = timer

-- Corona modules --
local storyboard = require("storyboard")

-- --
local Scene = storyboard.newScene()

-- Cache these...
local CX, CY = display.contentCenterX, display.contentCenterY

-- Mouth height --
local MouthY = .5 * CY

-- Update the shape and color of the body parts
local function UpdateBody (eyes, mouth, chest, count)
	local ecur = energy.GetEnergy()
	local r, b = ecur, 1 - ecur

	-- Update the eyes. 
	do
		local ys = .6 + .4 * ecur + sin(count / 10) * .3

		for _, eye in ipairs(eyes) do
			eye:setStrokeColor(r, 0, b)

			eye.yScale = ys
		end
	end

	-- Update the mouth.
	do
		local jitter = sin(count / 35)
		local a, da = 0, -pi / #mouth
		local scale = (1 - 2 * ecur) * 50

		for _, part in ipairs(mouth) do
			part:setFillColor(r, 0, b, .7)

			part.y = MouthY + sin(a) * scale + jitter * 10

			a = a + da
		end
	end

	-- Update the chest.
	do
		local a, da = 0, 2 * pi / #chest
		local n = (1.4 + sin(count / 10) * .45) / 2

		for _, part in ipairs(chest) do
			local ca = cos(a)
			local x, y = abs(ca), (1 - ca * ca)^n

			part.x = CX + (ca < 0 and -x or x) * 150
			part.y = CY + (a < pi and -y or y) * 200 + 120

			part:setFillColor(r, 0, b)

			a = a + da
		end
	end
end

--
function Scene:enterScene ()
	self.body = display.newGroup()

	-- Initalize thing's energy.
	energy.SetEnergy(1)

	-- Eye components --
	local eyes = {
		display.newCircle(self.body, CX * (1 - .35), .2 * CY, 45),
		display.newCircle(self.body, CX * (1 + .45), .2 * CY, 45)
	}

	for _, eye in ipairs(eyes) do
		eye:setFillColor(0, 0)

		eye.strokeWidth = 4
	end

	-- Mouth components --
	local mouth = {}

	for i = -10, 10 do
		mouth[#mouth + 1] = display.newCircle(self.body, CX * (1 + i / 40), MouthY, 20)
	end

	-- Chest components --
	local chest = {}

	for i = 1, 75 do
		chest[#chest + 1] = display.newCircle(self.body, 0, 0, 15)
	end

	-- Initialize the body parts and kick off updates.
	self.update_body = timer.performWithDelay(35, function(event)
		UpdateBody(eyes, mouth, chest, event.count)
	end, 0)

	UpdateBody(eyes, mouth, chest, 0)
end

Scene:addEventListener("enterScene")

--
function Scene:exitScene ()
	timer.cancel(self.update_body)

	self.body:removeSelf()
end

Scene:addEventListener("exitScene")

--
return Scene
