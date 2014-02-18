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
local floor = math.floor
local ipairs = ipairs
local pi = math.pi
local pow = math.pow
local random = math.random
local sin = math.sin

-- Modules --
local energy = require("energy")

-- Corona globals --
local display = display
local easing = easing
local native = native
local timer = timer
local transition = transition

-- Corona modules --
local storyboard = require("storyboard")

-- --
local Scene = storyboard.newScene()

-- Cache these...
local CX, CY = display.contentCenterX, display.contentCenterY

-- Body part positions --
local ChestDY, MouthY = 120, .5 * CY

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
			part.y = CY + (a < pi and -y or y) * 200 + ChestDY

			part:setFillColor(r, 0, b)

			a = a + da
		end
	end
end

--
local function AddBody (scene)
	-- Eye components --
	local eyes = {
		display.newCircle(scene.body, CX * (1 - .35), .2 * CY, 45),
		display.newCircle(scene.body, CX * (1 + .45), .2 * CY, 45)
	}

	for _, eye in ipairs(eyes) do
		eye:setFillColor(0, 0)

		eye.strokeWidth = 4
	end

	-- Mouth components --
	local mouth = {}

	for i = -10, 10 do
		mouth[#mouth + 1] = display.newCircle(scene.body, CX * (1 + i / 40), MouthY, 20)
	end

	-- Chest components --
	local chest = {}

	for i = 1, 75 do
		chest[#chest + 1] = display.newCircle(scene.body, 0, 0, 15)
	end

	-- Initialize the body parts and kick off updates.
	scene.update_body = timer.performWithDelay(35, function(event)
		UpdateBody(eyes, mouth, chest, event.count)
	end, 0)

	UpdateBody(eyes, mouth, chest, 0)
end

-- --
local SlotRows = 3

--
local function AddSlots (scene)
	scene.slots = display.newGroup()

	for row = 1, SlotRows do
		local y = floor((row - .5) * display.contentHeight / SlotRows)

		for col = 1, 2 do
			local x = floor(display.contentWidth * (col == 1 and .15 or .85))
			local slot = display.newCircle(scene.slots, x, y, 35)

			slot:setFillColor(0, 0)
			slot:setStrokeColor(0, 0, 1)

			slot.strokeWidth = 3
		end
	end
end

--
local function AddGlobes (scene)
	scene.globes = display.newGroup()

	scene.home, scene.away = {}, {}

	local n = SlotRows * 2

	for i = 1, n do
		local angle = 2 * pi * i / n
		local x = CX + 30 * cos(angle)
		local y = CY + 30 * sin(angle) + ChestDY
		local globe = display.newCircle(scene.globes, x, y, 20)

		globe:setFillColor(.6, .3, .2)
		globe:setStrokeColor(0, 1, 0)

		globe.strokeWidth = 2
	end
end

--
local function AddBlobs (scene)
	scene.blobs = display.newGroup()

	local pos = {
		.1, .1,
		.9, .1,
		.1, .9,
		.9, .9
	}

	for  i = 1, #pos, 2 do
		local blob = display.newCircle(scene.blobs, pos[i] * display.contentWidth, pos[i + 1] * display.contentHeight, 20)

		blob:setFillColor(.2, .1, 1)
		blob:setStrokeColor(1, .1, .1)

		blob.strokeWidth = 3
	end
end

-- --
local Seconds = 60

--
local function UpdateClock (scene, count)
	scene.clock.text = ("%i"):format(Seconds - count)

	if count == Seconds then
		local win = #scene.home == 10

		for _, globe in ipairs(scene.away) do
			win = win and globe.in_slot
		end

		local message = display.newText("You " .. (win and "Win!" or "Lose"), CX, CY, native.systemFontBold, 40)

		transition.to(message, { xScale = 3, yScale = 3, time = 800, transition = easing.inOutExpo,
				
			onComplete = function(object)
				object:removeSelf()

				storyboard.gotoScene("title")
			end
		})
	end
end

--
function Scene:enterScene ()
	self.body = display.newGroup()

	-- Initalize thing's energy.
	energy.SetEnergy(1)

	--
	AddBody(self)
	AddBlobs(self)
	AddGlobes(self)
	AddSlots(self)

	--
	self.clock = display.newText(self.view, "", CX, 30, native.systemFont, 30)

	timer.performWithDelay(1000, function(event)
		UpdateClock(self, event.count)
	end, Seconds)

	UpdateClock(self, 0)
end

Scene:addEventListener("enterScene")

--
function Scene:exitScene ()
	timer.cancel(self.update_body)

	self.blobs:removeSelf()
	self.body:removeSelf()
	self.globes:removeSelf()
	self.slots:removeSelf()
	self.clock:removeSelf()

	self.home, self.away = nil
end

Scene:addEventListener("exitScene")

--
return Scene
