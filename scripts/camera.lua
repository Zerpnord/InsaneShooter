local vec2 = require("lib/vec2")
local uniform = require("lib/uniform")

local camera = {}

function camera.new()
    local c = {
    	position = vec2.new();
		shakePos = vec2.new();
    	zoom = 1;
    	lockedTarget = nil;
    	smoothness = 5.75;
    }

	function c.fireShake(direction, intensity)
		c.shakePos.x = c.shakePos.x + math.cos(direction) * intensity--uniform(-intensity, intensity)
		c.shakePos.y = c.shakePos.y + math.sin(direction) * intensity--uniform(-intensity, intensity)
	end

	function c.damageShake(intensity)
		c.shakePos.x = c.shakePos.x + uniform(-intensity, intensity)
		c.shakePos.y = c.shakePos.y + uniform(-intensity, intensity)
	end

    function c.update(delta)
    	if GamePaused then return end
		-- Camera shake returns to normal
		c.shakePos.x = c.shakePos.x + -c.shakePos.x * 28 * delta / MotionSpeed
		c.shakePos.y = c.shakePos.y + -c.shakePos.y * 28 * delta / MotionSpeed
        -- Camera following
    	if not c.lockedTarget then return end
		c.position.x = c.position.x + c.shakePos.x + (c.lockedTarget.position.x - c.position.x-(SC_WIDTH/2)) * (c.smoothness * delta) / MotionSpeed
		c.position.y = c.position.y + c.shakePos.y + (c.lockedTarget.position.y - c.position.y-(SC_HEIGHT/2)) * (c.smoothness * delta) / MotionSpeed
    end

    return c
end

return camera
