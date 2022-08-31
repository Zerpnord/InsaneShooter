local utils = require("utils")
local vec2 = require("lib/vec2")
local uniform = require("lib/uniform")

local bullet = require("scripts/bullet")
local assets = require("scripts/assets")
local playerTrail = require("scripts/playerTrail")
local weaponData = require("scripts/weaponData")
local weaponSprite = require("scripts/weaponSprite")

local player = {}

function player.new()
    local p = {
        position = vec2.new();
        velocity = vec2.new();
	facing = "right";
	bullets = {};
	trails = {};
	weapons = {nil, nil, nil};
	slot = 1;
	shootCooldown = 1000;
	trailCooldown = 0;
	weaponSprite = weaponSprite.new();
	width = 1;
	moving = false;
	health = 100;
	reloading = false;
	reloadTimer = 0;
	slotKeys = {false, false, false};
	stamina = 100;
	oldSlot = nil;
	sprinting = false;
	sprintCooldown = 3131;
    }

    -- Trail related functions
    function p.updateTrail(delta)
	-- Draw existing trails
	for i, v in ipairs(p.trails) do
	    v.update(delta, i)
	end
	-- Add new trails
	p.trailCooldown = p.trailCooldown + delta
	if p.trailCooldown < 0.1 or not p.moving then return end
	-- Instance trail
	local newTrail = playerTrail.new()
	newTrail.position = vec2.new(p.position.x, p.position.y)
	-- Add instance to table
	p.trails[#p.trails+1] = newTrail
    end

    function p.drawTrail()
	for _, v in ipairs(p.trails) do
	    v.draw()
	end
    end

    -- Bullet related functions
    function p.updateBullets(delta)
	for i, v in ipairs(p.bullets) do
	    v.update(delta, i)
	end
    end

    function p.drawBullets()
	for _, v in ipairs(p.bullets) do
	    v.draw()
	end
    end

    -- Player related functions
    function p.setFacing(delta)
	-- Set facing value
	local m = utils.getMousePosition()
	if m.x > p.position.x then
	    p.facing = "right" else
	    p.facing = "left" end
	-- Change width
	local sm = 250 * delta
	if p.facing == "right" then
	    p.width = p.width + (1-p.width) / sm
	else
	    p.width = p.width + (-1-p.width) / sm
	end
    end

    function p.sprint(delta)
	-- Increment timer
	p.sprintCooldown = p.sprintCooldown + delta 
	-- Get key input
	if love.keyboard.isDown("lshift") and p.moving and p.sprintCooldown > 3.5 and p.stamina > 0 then
	    p.sprinting = true
	    p.stamina = p.stamina - (30 * delta)
	    -- Reset timer
	    if p.stamina < 0 then
		p.sprintCooldown = 0 
		p.sprinting = false
	    end
	else
	    p.sprinting = false
	    -- Increase stamina
	    p.stamina = p.stamina + (24 * delta)
	    if p.stamina > 100 then p.stamina = 100 end
	end
	-- Set camera zoom based on sprinting
	Camera.zoom = Camera.zoom + 0.005 
    end

    function p.switchSlot()
	if p.reloading then return end
	-- Switch slot
	for i = 1, 3 do
	    if not p.slotKeys[i] and love.keyboard.isDown(tostring(i)) then
		p.oldSlot = p.slot
		p.slot = i
	    end
	end
	-- Quick slot switch
	if not p.slotKeys[#p.slotKeys] and love.keyboard.isDown("q") and p.oldSlot then
	    local newSlot = p.oldSlot
	    p.oldSlot = p.slot
	    p.slot = newSlot
	end
	-- Get key input
	for i = 1, 3 do
	    p.slotKeys[i] = love.keyboard.isDown(tostring(i))
	end
	-- Get quick slot key input
	p.slotKeys[#p.slotKeys] = love.keyboard.isDown("q")
    end

    function p.shoot(delta)
	-- Return if player isn't holding a weapon / reloading / out of ammo
	local w = p.weapons[p.slot]
	if not w or p.reloading or w.magAmmo < 1 then return end
	-- Increment timer
	p.shootCooldown = p.shootCooldown + delta
	if not love.mouse.isDown(1) or p.shootCooldown < w.shootTime then
	    return end
	-- Instance bullet
	local newBullet = bullet.new()
	newBullet.position = vec2.new(p.weaponSprite.position.x, p.weaponSprite.position.y)
	newBullet.rotation = p.weaponSprite.rotation
	-- Check where the player is facing
	local t = 1
	if p.facing == "left" then
	    t = -1
	   newBullet.rotation = newBullet.rotation + 135
       end
	-- Offset the bullet
	newBullet.position.x = newBullet.position.x + math.cos(p.weaponSprite.rotation) * w.bulletOffset * t
	newBullet.position.y = newBullet.position.y + math.sin(p.weaponSprite.rotation) * w.bulletOffset * t
	-- Spread bullet
	newBullet.rotation = newBullet.rotation + uniform(-1, 1) * w.bulletSpread
	-- Reset timer
	p.shootCooldown = 0
	-- Decrease mag ammo
	w.magAmmo = w.magAmmo - 1
	-- Shoot event for UI
	Interface.playerShot()	
	-- Play sound
	assets.sounds.shoot:play()
	-- TODO special bullet attributes
	-- Add to table
	p.bullets[#p.bullets+1] = newBullet
    end

    function p.reload(delta)
	local w = p.weapons[p.slot]
	-- Increment timer
	if p.reloading then
	    p.reloadTimer = p.reloadTimer + delta
	    if p.reloadTimer > w.reloadTime then
		-- Reload current weapon
		p.reloading = false
		w.magAmmo = w.magSize
		-- Play reload sound
		assets.sounds.reload:play()
	    end
	else
	    -- Get input
	    if love.keyboard.isDown("r") then
		p.reloading = true
		p.reloadTimer = 0
	    end
	end
    end

    function p.movement(delta)
	local speed = 200
	p.velocity = vec2.new()
	-- Get key input
	if love.keyboard.isDown("right", "d") then
	    p.velocity.x = p.velocity.x + 1 end
	if love.keyboard.isDown("left", "a") then
	    p.velocity.x = p.velocity.x - 1 end
	if love.keyboard.isDown("up", "w") then
	    p.velocity.y = p.velocity.y - 1 end
	if love.keyboard.isDown("down", "s") then
	    p.velocity.y = p.velocity.y + 1 end
	-- Set p.moving
	p.moving = math.abs(p.velocity.x) > 0 or math.abs(p.velocity.y) > 0
	-- Normalize velocity
	if math.abs(p.velocity.x) == math.abs(p.velocity.y) then
	    p.velocity.x = p.velocity.x / 1.25
	    p.velocity.y = p.velocity.y / 1.25
	end
	-- Move by velocity
	p.position.x = p.position.x + speed * p.velocity.x * delta
	p.position.y = p.position.y + speed * p.velocity.y * delta
    end

    -- Event functions
    function p.load()
	-- Create inputKeys table
	for i = 1, #p.weapons do
	    p.slotKeys[i] = false
	end
	-- Quick slot switch
	p.slotKeys[#p.slotKeys+1] = false
	p.weapons[1] = weaponData.pistol
	p.weapons[1].magAmmo = 13 
	-- TODO find a way to copy objects from weaponData!!!!
    end

    function p.update(delta)
	if GamePaused then return end
	-- Functions
	p.switchSlot()
	p.shoot(delta)
	p.movement(delta)
	p.setFacing(delta)
	p.reload(delta)
	p.sprint(delta)
	p.updateTrail(delta)
	p.updateBullets(delta)
	p.weaponSprite.update(delta)
    end

    function p.draw()
	p.drawTrail()
	local width = assets.playerImg:getWidth()
	local height = assets.playerImg:getHeight()
	local x = (p.position.x - Camera.position.x) * Camera.zoom	
	local y = (p.position.y - Camera.position.y) * Camera.zoom
	love.graphics.draw(
	    assets.playerImg, x, y, p.rotation,
	    Camera.zoom * p.width, Camera.zoom, width/2, height/2
	)
	p.weaponSprite.draw()
	p.drawBullets()
    end

    return p
end

return player
