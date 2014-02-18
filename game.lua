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
local sqrt = math.sqrt

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
local function GlobeTouch (event)
	local globe, phase = event.target, event.phase

	if phase == "began" then
		display.getCurrentStage():setFocus(globe)

		globe.m_claimed = true

	elseif phase == "moved" then
		globe.x, globe.y = event.x, event.y

	elseif phase == "ended" or phase == "cancelled" then
		display.getCurrentStage():setFocus(nil)

		for i = 1, Scene.slots.numChildren do
			local slot = Scene.slots[i]
			local dx, dy = slot.x - globe.x, slot.y - globe.y

			if not slot.m_occupied and dx * dx + dy * dy < 150 then
				globe:removeEventListener("touch", GlobeTouch)

				globe.x, globe.y = slot.x, slot.y
				globe.alpha = .3

				globe.m_slot_index = i
				slot.m_occupied = true

				energy.UpdateEnergy(-1 / (SlotRows * 2))

				break
			end
		end

		globe.m_claimed = false
	end

	return true
end

--
local function AddGlobes (scene)
	scene.globes = display.newGroup()

	local n = SlotRows * 2

	for i = 1, n do
		local angle = 2 * pi * i / n
		local x = CX + 30 * cos(angle)
		local y = CY + 30 * sin(angle) + ChestDY
		local globe = display.newCircle(scene.globes, x, y, 20)

		globe:addEventListener("touch", GlobeTouch)
		globe:setStrokeColor(0, 1, 0)

		globe.strokeWidth = 2

		globe.m_x, globe.m_y = x, y
	end

	scene.update_globes = timer.performWithDelay(20, function(event)
		local g = .3 + sin(event.count / 2.5) * .2

		for i = 1, scene.globes.numChildren do
			scene.globes[i]:setFillColor(.6, g, .2)
		end
	end, 0)
end

--
local RespawnParams = {
	transition = 2000,

	onComplete = function(object)
		object.m_respawning = false
	end
}

--
local function DropGlobe (globe, blob)
	globe:addEventListener("touch", GlobeTouch)

	globe.alpha = 1

	blob.m_globe_index = nil
	globe.m_claimed = false
end

--
local function BlobTouch (event)
	if event.phase == "began" then
		local blob = event.target

		blob:removeEventListener("touch", BlobTouch)

		local gi = blob.m_globe_index
		local globe = gi and Scene.globes[gi]

		if globe then
			DropGlobe(globe, blob)
		end

		blob.m_respawning = true


		RespawnParams.x = blob.m_x
		RespawnParams.y = blob.m_y

		transition.to(blob, RespawnParams)

		return true
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
		local x, y = pos[i] * display.contentWidth, pos[i + 1] * display.contentHeight
		local blob = display.newCircle(scene.blobs, x, y, 20)

		blob:setStrokeColor(1, .1, .1)

		blob.strokeWidth = 3

		blob.m_x, blob.m_y = x, y
	end

	scene.update_blobs = timer.performWithDelay(20, function(event)
		local ecur = energy.GetEnergy()

		for i = 1, scene.blobs.numChildren do
			local blob = scene.blobs[i]

			if blob.m_respawning then
				blob:setFillColor(0)
			else
				blob:setFillColor(.2 * ecur, .1, .5 + ecur * .5)
			end

			local gi = blob.m_globe_index
			local globe, dx, dy, sqr = gi and scene.globes[gi]

			--
			if globe then
				dx, dy = globe.m_x - blob.x, globe.m_y - blob.y
				sqr = dx * dx + dy * dy

				if sqr < 150 then
					DropGlobe(globe, blob)
				else
					globe.x, globe.y = blob.x + 20, blob.y + 20
				end

			--
			else
				for i = 1, scene.globes.numChildren do
					local globe = scene.globes[i]

					if not globe.m_claimed then
						dx, dy = globe.m_x - blob.x, globe.m_y - blob.y
						sqr = dx * dx + dy * dy

						if sqr < 150 then
							blob.m_globe_index = i
							globe.m_claimed = true

							local si = globe.m_slot_index

							if si then
								globe.m_slot_index = nil
								scene.slots[i].m_occupied = false

								energy.UpdateEnergy(1 / (SlotRows * 2))
							end

							break
						end
					end
				end

				if not blob.m_globe_index then
					for i = 1, scene.globes.numChildren do
						local globe = scene.globes[i]

						if not globe.m_claimed then
							dx, dy = globe.m_x - blob.x, globe.m_y - blob.y
							sqr = dx * dx + dy * dy

							break
						end
					end
				end
			end

			local speed = (2 - ecur) * 5 / sqrt(sqr)

			blob.x, blob.y = blob.x + speed * dx, blob.y + speed * dy
		end
	end, 0)
end

-- --
local Seconds

--
local function UpdateClock (scene, count)
	scene.clock.text = ("%i"):format(Seconds - count)

	if count == Seconds then
		local win = true

		for i = 1, scene.globes.numChildren do
			win = win and scene.globes[i].m_slot_index
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
function Scene:enterScene (info)
	self.body = display.newGroup()

	--
	Seconds = info.params

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
	timer.cancel(self.update_blobs)
	timer.cancel(self.update_body)
	timer.cancel(self.update_globes)

	self.blobs:removeSelf()
	self.body:removeSelf()
	self.globes:removeSelf()
	self.slots:removeSelf()
	self.clock:removeSelf()
end

Scene:addEventListener("exitScene")

--
return Scene
