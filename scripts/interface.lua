local utils = require("utils")
local vec2 = require("lib/vec2")
local zerpgui = require("lib/zerpgui")
local assets = require("scripts/assets")
local coreFuncs = require("scripts/coreFuncs")

local interface = {
    damageNums = {};
    hitmarkers = {};
    diffPreview = nil;
    diffPreviewTexts = {
        easy = "Enemies can't dash and shoots slower. Completely removes the fast-paced gameplay.";
        medium = "Enemies can dash, while shooting slightly faster than the player.";
        hard = "Enemies will probably tear you apart with dashing to you & shooting like it's a bullet hell.";
    };
    statElements = {};
    text = love.filesystem.read("string", "howtoplay.txt");
    trails = {};
    trailCooldown = 0;
}

-- Button events
function interface.playButtonClick()
    GameState = "diffSelect"
    interface.diffPreview = nil
end

function interface.aboutButtonClick()
    GameState = "about"
end

-- All those fucking color buttons and stuff
function interface.colorPButtonClick()
    Save.playerColorSlot = Save.playerColorSlot + 1
    if Save.playerColorSlot > #PlayerColors then
        Save.playerColorSlot = 1 end
end

function interface.colorDButtonClick()
    Save.playerColorSlot = Save.playerColorSlot - 1
    if Save.playerColorSlot < 1 then
        Save.playerColorSlot = #PlayerColors end
end

function interface.accPButtonClick()
    Save.playerAccSlot = Save.playerAccSlot + 1
    if Save.playerAccSlot > #assets.accessories then
        Save.playerAccSlot = 1 end
end

function interface.accDButtonClick()
    Save.playerAccSlot = Save.playerAccSlot - 1
    if Save.playerAccSlot < 1 then
        Save.playerAccSlot = #assets.accessories end
end

function interface.settingsButtonClick()
    GameState = "settings"
end

function interface.customizeButtonClick()
    GameState = "customize"
end

function interface:easyButtonClick()
    if interface.diffPreview == "easy" then
        Difficulty = 1
        GameLoad()
    else
        interface.diffPreview = "easy"
    end
end

function interface.mediumButtonClick()
    if interface.diffPreview == "medium" then
        Difficulty = 2
        GameLoad()
    else
        interface.diffPreview = "medium"
    end
end

function interface.hardButtonClick()
    if interface.diffPreview == "hard" then
        Difficulty = 3
        GameLoad()
    else
        interface.diffPreview = "hard"
    end
end

function interface.quitButtonClick()
    if interface.menu.quit.sure then
        SaveGame()
        love.event.quit()
    else
        interface.menu.quit.sure = true
    end
end

function interface.continueButtonClick()
    GamePaused = false
end

function interface.titleButtonClick()
    interface.pauseMenu.alpha = 0
    interface.deathMenu.alpha = 0
    GamePaused = false
    if GameState == "game" then
        EnemyManager.enemies = {}
    end
    GameState = "menu"
    interface.menu.quit.sure = false
    interface.trails = {}
    interface.trailCooldown = 0
    Difficulty = 3
    WaveManager.wave = 1
    SaveGame()
end

-- Call events
function interface:updateHitmarkers(delta)
    for i, v in ipairs(self.hitmarkers) do
        v.update(delta, i)
    end
end

function interface:drawHitmarkers()
    for _, v in ipairs(self.hitmarkers) do
        v.draw()
    end
end

function interface:updateDamageNums(delta)
    for i, v in ipairs(self.damageNums) do
        v.update(delta, i)
    end
end

function interface:drawDamageNums()
    for _, v in ipairs(self.damageNums) do
        v.draw()
    end
end

-- Canvas functions
function interface:setCanvasVisible()
    self.menu.enabled = GameState == "menu"
    self.diffSelect.enabled = GameState == "diffSelect"
    self.game.enabled = GameState == "game"
    self.pauseMenu.enabled = GameState == "game" and not CurrentShader and self.pauseMenu.alpha > 0.3
    self.deathMenu.enabled = GameState == "game" and self.deathMenu.alpha > 0.3
    self.about.enabled = GameState == "about"
    self.settings.enabled = GameState == "settings"
    self.customize.enabled = GameState == "customize"
    self.introMenu.enabled = GameState == "intro"
end

function interface:updateGame()
    local delta = love.timer.getDelta()
    -- Wave text
    if WaveManager.preparation then
        self.game.wave.text = "PREPARE FOR WAVE " .. WaveManager.wave
    else
        self.game.wave.text = "WAVE " .. WaveManager.wave .. " - " .. #EnemyManager.enemies .. " ENEMIES LEFT"
    end
    -- Score texts
    self.game.scoreNum.text = Score
    self.game.scoreText.text = "SCORE | HIGH: " .. Save.highScore[Difficulty]
    -- Weapon UI
    local w = Player.weapons[Player.slot]
    if w then
        -- Mag ammo
        local len = #tostring(w.magAmmo)
        local t = w.magAmmo
        if Player.reloading then t = ". ." end
        self.game.magAmmo.text = t
        self.game.magAmmo.position.x = 545 - (len-1)*15
        self.game.ammoIcon.source = assets.ammoIconImg
        self.game.infAmmo.text = "∞"
        -- Slot line
        self.game.slotLine.color[4] = 1
        local temp = self.game.slotLine.size.x
        self.game.slotLine.size.x = temp + (assets.weapons[w.name .. "Img"]:getWidth()*3-temp) * (8.25 * delta)
        temp = self.game.slotLine.position.x
        self.game.slotLine.position.x = temp + (276+Player.slot*106-self.game.slotLine.size.x/2-temp) * (8.25 * delta)
    else
        self.game.weaponText.text = ""
        self.game.magAmmo.text = ""
        self.game.ammoIcon.source = nil
        self.game.infAmmo.text = ""
        self.game.slotLine.color[4] = 0
    end
    -- Quick switch UI
    if Player.oldSlot then
        self.game.qKey.source = assets.qKeyImg
        self.game.quickSwitchW.text = Player.weapons[Player.oldSlot].name
    else
        self.game.quickSwitchW.text = ""
        self.game.qKey.source = nil
    end
    -- Inventory slots (image)
    for i = 1, Player.slotCount do
        local element = self.game["slotW"..i]
        w = Player.weapons[i]
        if w then
            element.source = assets.weapons[w.name .. "Img"]
        else
            element.source = nil
        end
        local r = element.rotation
        local s = element.scale
        if i == Player.slot then
            element.rotation = r + (0-r) * (8.25 * delta)
        else
            element.rotation = r + (math.pi/10-r) * (8.25 * delta)
        end
    end
    -- Health text
    self.game.healthText.text = math.floor(Player.health)
    -- Dash indicator text
    if Player.dashCooldownTimer < 2.5 then
        self.game.dashText.text = "CHARGING"
        --self.game.dashIcon.position.x = 735
    else
        self.game.dashText.text = "READY"
        --self.game.dashIcon.position.x = 785
    end
    -- Dash instructor
    if CurrentShader then
        self.game.dashInstructor.text = "RELEASE RMB TO DASH"
        self.game.dashTimeBar.color[4] = 1
        self.game.dashTimeBar.size.x = (1.3-Player.dashDurationTimer)*235/1.3
        self.game.dashTimeBar.position.x = 380 - (self.game.dashTimeBar.size.x-235)/2
    else
        self.game.dashInstructor.text = ""
        self.game.dashTimeBar.color[4] = 0
    end
    -- Gamepad icon
    if ControlType == "keyboard" then
        self.game.gamepadIcon.source = nil
    else
        self.game.gamepadIcon.source = assets.gamepadIcon
    end
end

function interface:updateDiffSelect()
    if self.diffPreview then
        local t = "\nClick again to continue."
        self.diffSelect.preview.text = self.diffPreviewTexts[self.diffPreview] .. t
    else
        self.diffSelect.preview.text = ""
    end
end

function interface:updateDebug()
    if not self.debug.enabled then return end
    self.debug.versionData.text = "BlockDash " .. Version .. " (ZerpGUI " .. zerpgui.version .. ", LÖVE " .. love.getVersion() .. ")"
    self.debug.fps.text = "FPS: " .. love.timer.getFPS() .. " / " .. math.floor(1/love.timer.getAverageDelta())
    self.debug.enemyCount.text = "Enemy Count: " .. #EnemyManager.enemies
    self.debug.particleCount.text = "Particle Count: " .. #ParticleManager.particles
    self.debug.bulletCount.text = "Bullet Count: " .. #EnemyBullets + #Player.bullets
    self.debug.wave.text = "Wave: " .. WaveManager.wave
    -- Update logs
    self.debug.logs.text = ""
    local maxAmount = (SC_HEIGHT - 190)/20
    if #Logger.logList <= maxAmount then
        for i = #Logger.logList, 1, -1 do
            self.debug.logs.text = self.debug.logs.text .. Logger.logList[i] .. "\n"
        end
    else
        for i = #Logger.logList, #Logger.logList-maxAmount, -1 do
            self.debug.logs.text = self.debug.logs.text .. Logger.logList[i] .. "\n"
        end
    end
    
end

function interface:updateMenu()
    if self.menu.quit.sure then
        self.menu.quit.text = "you sure?"
    else
        self.menu.quit.text = "quit"
    end
end

function interface:updateSettingsMenu()
    for i = 1, #SettingNames do
        Save.settings[i] = self.settings["checkbox"..i].value
    end
end

function interface:updateCustomizeMenu(delta)
    local color = PlayerColors[Save.playerColorSlot]
    self.customize.player.color[1] = color[1]
    self.customize.player.color[2] = color[2]
    self.customize.player.color[3] = color[3]
    self.customize.accPreview.source = assets.accessories[Save.playerAccSlot]

    -- Update existing trails
    for i, v in ipairs(self.trails) do
        v.update(delta, i)
    end

    -- Trail creation
    self.trailCooldown = self.trailCooldown + delta
    if self.trailCooldown < 0.05 then return end
    self.trailCooldown = 0

    local particle = ParticleManager.new(
        vec2.new(SC_WIDTH/2+Camera.position.x, SC_HEIGHT/2-13+Camera.position.y),
        vec2.new(67.2, 67.2),
        0.315, color, coreFuncs.trailParticleTick
    )
    particle.velocity = vec2.new(-500, 0)
end

function interface:updatePauseMenu()
    local delta = love.timer.getDelta()
    local a = self.pauseMenu.alpha
    if GamePaused then
    	self.pauseMenu.alpha = a+(1-a) * (8.25 * delta)
    else
        self.pauseMenu.alpha = a+(0-a) * (8.25 * delta)
    end
    self.pauseMenu.background.color[4] = self.pauseMenu.alpha-0.35
    self.pauseMenu.background.size = vec2.new(SC_WIDTH, SC_HEIGHT)
end

function interface:updateDeathMenu()
    local a = self.deathMenu.alpha
    local delta = love.timer.getDelta()
    if Player.dead and Player.deathTimer > 1.5 then
    	self.deathMenu.alpha = a+(1-a) * (8.25 * delta)
    else
        self.deathMenu.alpha = a+(0-a) * (8.25 * delta)
    end
    self.deathMenu.background.color[4] = self.deathMenu.alpha-0.35
    self.deathMenu.background.size = vec2.new(SC_WIDTH, SC_HEIGHT)
    -- Update statistics
    for _, v in ipairs(self.statElements) do
        v.text = Stats[v.statName]
    end
end

function interface:updateIntroMenu(delta)
    local intro = self.introMenu
    intro.background.size = vec2.new(SC_WIDTH, SC_HEIGHT)
    intro.timer = self.introMenu.timer + delta
    -- Sound
    if intro.titleAlpha > 0.6 then
        if Save.settings[utils.indexOf(SettingNames, "Sounds")] and not intro.soundPlayed then
            assets.sounds.intro:play()
            intro.soundPlayed = true
        end
    end
    -- Show
    if intro.timer > 1 and intro.timer < 3 then
        intro.titleAlpha = intro.titleAlpha + delta*4
        if intro.titleAlpha > 0.6 then intro.titleAlpha = 1 end
    end
    -- Hide
    if intro.timer > 3 then
        intro.titleAlpha = intro.titleAlpha - delta*4
        intro.background.color[4] = intro.background.color[4] - delta*4
        -- Launch menu
        if intro.timer > 3.7 then
            GameState = "menu"
            MotionSpeed = 1
        end
    end
    intro.title.color[4] = intro.titleAlpha
    intro.titleNord.color[4] = intro.titleAlpha
    intro.zerpie.color[4] = intro.titleAlpha
end

-- Event functions
function interface:load()
    -- Main menu -------------------------------------------------------------------------------------------------
    self.menu = zerpgui:newCanvas()
    self.menu:newTextLabel(
        "title", vec2.new(0, 120), "Block Dash", 48, "00", "center"
    )
    self.menu:newButton(
        "play", vec2.new(275, 260), vec2.new(200, 70), 2, "play", 24, nil, self.playButtonClick, "00"
    )
    self.menu:newButton(
        "about", vec2.new(485, 260), vec2.new(200, 70), 2, "help", 24, nil, self.aboutButtonClick, "00"
    )
    self.menu:newButton(
        "settings", vec2.new(485, 340), vec2.new(200, 70), 2, "settings", 24, nil, self.settingsButtonClick, "00"
    )
    self.menu:newButton(
        "customize", vec2.new(275, 340), vec2.new(200, 70), 2, "customize", 24, nil, self.customizeButtonClick, "00"
    )
    self.menu:newButton(
        "quit", vec2.new(380, 420), vec2.new(200, 70), 2, "quit", 24, nil, self.quitButtonClick, "00"
    )
    self.menu.quit.sure = false
    self.menu:newTextLabel(
        "versionInfo", vec2.new(5, 516), "v" .. Version .. " - Made by polaritynord", 14, "x+", "left"
    )
    -- About menu ----------------------------------------------------------------------------------------------
    self.about = zerpgui:newCanvas()
    self.about:newTextLabel(
        "title", vec2.new(0, 120), "How to Play", 48, "00", "center"
    )
    self.about:newTextLabel(
        "keyControls", vec2.new(180, 220), self.text, 16, "00", "left"
    )
    self.about:newButton(
        "return", vec2.new(380, 420), vec2.new(200, 70), 2, "return", 24, nil, self.titleButtonClick, "00"
    )
    -- Customize menu ------------------------------------------------------------------------------------------
    self.customize = zerpgui:newCanvas()
    self.customize:newTextLabel(
        "title", vec2.new(0, 120), "Customize", 48, "00", "center"
    )
    self.customize:newImage(
        "player", vec2.new(480, 250), 0, assets.playerImg, 3, {0, 0, 0, 1}, "00"
    )
    -- Color changing buttons
    self.customize:newTextLabel(
        "colorText", vec2.new(620, 240), "Color", 14, "00", "left"
    )
    self.customize:newButton(
        "colorPlus", vec2.new(560, 235), vec2.new(25, 25), 2, "", 24, nil, self.colorPButtonClick, "00"
    )
    self.customize:newButton(
        "colorNeg", vec2.new(380, 235), vec2.new(25, 25), 2, "", 24, nil, self.colorDButtonClick, "00"
    )
    -- Accessory changing buttons
    self.customize:newTextLabel(
        "accText", vec2.new(620, 200), "Accessory", 14, "00", "left"
    )
    self.customize:newButton(
        "accPlus", vec2.new(560, 200), vec2.new(25, 25), 2, "", 24, nil, self.accPButtonClick, "00"
    )
    self.customize:newButton(
        "accNeg", vec2.new(380, 200), vec2.new(25, 25), 2, "", 24, nil, self.accDButtonClick, "00"
    )
    self.customize:newImage(
        "accPreview", vec2.new(480, 250), 0, assets.accessories[Save.playerAccSlot], 3, {1,1,1,1}, "00"
    )

    self.customize:newButton(
        "return", vec2.new(380, 420), vec2.new(200, 70), 2, "return", 24, nil, self.titleButtonClick, "00"
    )
    -- Difficulty selection ------------------------------------------------------------------------------------
    self.diffSelect = zerpgui:newCanvas()
    self.diffSelect:newTextLabel(
        "title", vec2.new(0, 120), "Difficulty Select", 48, "00", "center"
    )
    -- Buttons
    self.diffSelect:newButton(
        "easy", vec2.new(380, 260), vec2.new(200, 70), 2, "easy", 24, nil, self.easyButtonClick, "00"
    )
    self.diffSelect:newButton(
        "medium", vec2.new(380, 340), vec2.new(200, 70), 2, "normal", 24, nil, self.mediumButtonClick, "00"
    )
    self.diffSelect:newButton(
        "hard", vec2.new(380, 420), vec2.new(200, 70), 2, "hard", 24, nil, self.hardButtonClick, "00"
    )
    -- Preview text
    self.diffSelect:newTextLabel(
        "preview", vec2.new(0, 15), "", 14, "00", "center"
    )
    -- Settings menu ------------------------------------------------------------------------------------------
    self.settings = zerpgui:newCanvas()
    self.settings:newTextLabel(
        "title", vec2.new(0, 120), "Settings", 48, "00", "center"
    )
    self.settings:newButton(
        "return", vec2.new(380, 420), vec2.new(200, 70), 2, "return", 24, nil, self.titleButtonClick, "00"
    )
    -- Create setting names
    local x = 300 ; local y = 220
    for i = 1, #SettingNames do
        self.settings:newTextLabel("setting"..i, vec2.new(x, y), SettingNames[i], 24, "00", "left")
        y = y + 30
    end
    -- Create setting checboxes
    x = 250 ; y = 236
    for i = 1, #SettingNames do
        self.settings:newCheckbox(
            "checkbox"..i, vec2.new(x, y), 20, Save.settings[i], "00"
        )
        y = y + 30
    end
    -- Game ---------------------------------------------------------------------------------------------------
    self.game = zerpgui:newCanvas()
    -- Wave text
    self.game:newTextLabel(
        "wave", vec2.new(0, 20), "WAVE 1", 24, "0x", "center"
    )
    -- ***WEAPON UI***
    -- Magazine ammo
    self.game:newTextLabel(
        "magAmmo", vec2.new(558, 466), 0, 20, "0+", "left"
    )
    -- Ammo icon
    self.game:newImage(
        "ammoIcon", vec2.new(588, 479.5), 0, nil, 1, {1, 1, 1, 1}, "0+"
    )
    -- "Infinite" symbol
    self.game:newTextLabel(
        "infAmmo", vec2.new(604, 466), "∞", 20, "0+", "left"
    )
    -- Quick slot key img
    self.game:newImage(
        "qKey", vec2.new(368, 480), 0, assets.qKeyImg, 2, {1, 1, 1, 1}, "0+"
    )
    -- Previous weapon text
    self.game:newTextLabel(
        "quickSwitchW", vec2.new(381.5, 471.5), "", 12, "0+", "left"
    )
    -- Current slot line
    self.game:newRectangle(
        "slotLine", vec2.new(329, 427), vec2.new(106, 3.25), "fill", {1, 1, 1, 1}, 0, "0+"
    )
    -- Gamepad usage symbol
    self.game:newImage(
        "gamepadIcon", vec2.new(488.5, 510), 0, nil, 2, {1, 1, 1, 1}, "0+"
    )
    -- ***HEALTH AND INV UI***
    -- Slot weapons
    x = 594 ; y = 450
    local j = Player.slotCount
    for _ = 1, Player.slotCount do
        self.game:newImage("slotW"..j, vec2.new(x, y), 0, nil, 2.5, {1, 1, 1, 1}, "0+")
        j = j - 1
        x = x - 106
    end
    -- Health icon & text
    self.game:newImage("healthIcon", vec2.new(625, 407), 0, assets.healthIconImg, 4, {1, 1, 1, 1}, "0+")
    self.game:newTextLabel("healthText", vec2.new(-400, 393), "100", 24, "0+", "right")
    -- Dash indicator text
    self.game:newTextLabel("dashText", vec2.new(380, 392), "READY", 24, "0+", "left")
    -- Dash indicator icon
    self.game:newImage("dashIcon", vec2.new(368, 407), 0, assets.dashIconImg, 1.3, {1, 1, 1, 1}, "0+")
    
    -- Dash text
    self.game:newTextLabel("dashInstructor", vec2.new(0, 440), "", 24, "00", "center")
    -- Dash time bar
    self.game:newRectangle("dashTimeBar", vec2.new(380, 70), vec2.new(235, 15), "fill", {1, 1, 1, 1}, 0, "0x")
    -- **SCORE UI**
    self.game:newTextLabel("scoreNum", vec2.new(15, 0), "0", 48, "xx", "left")
    self.game:newTextLabel("scoreText", vec2.new(15, 64), "SCORE (RECORD: 0)", 16, "xx", "left")

    -- Debug menu (game) ---------------------------------------------------------------------------------------
    self.debug = zerpgui:newCanvas()
    self.debug:newTextLabel("versionData", vec2.new(15, 100), "", 14, "xx", "left", "JetBrainsMono")
    self.debug:newTextLabel("fps", vec2.new(15, 115), "", 14, "xx", "left", "JetBrainsMono")
    self.debug:newTextLabel("enemyCount", vec2.new(15, 130), "", 14, "xx", "left", "JetBrainsMono")
    self.debug:newTextLabel("particleCount", vec2.new(15, 145), "", 14, "xx", "left", "JetBrainsMono")
    self.debug:newTextLabel("bulletCount", vec2.new(15, 160), "", 14, "xx", "left", "JetBrainsMono")
    self.debug:newTextLabel("wave", vec2.new(15, 175), "", 14, "xx", "left", "JetBrainsMono")
    self.debug:newTextLabel("logs", vec2.new(15, 190), "", 14, "xx", "left", "JetBrainsMono", {0, 1, 0, 0.7})

    -- Pause menu (game) ---------------------------------------------------------------------------------------
    self.pauseMenu = zerpgui:newCanvas()
    self.pauseMenu:newRectangle(
        "background", vec2.new(), vec2.new(SC_WIDTH, SC_HEIGHT), "fill", {0, 0, 0, 1}, 0, "xx"
    )
    self.pauseMenu:newTextLabel(
        "title", vec2.new(0, 120), "Game Paused", 48, "00", "center"
    )
    self.pauseMenu:newButton(
        "continue", vec2.new(380, 260), vec2.new(200, 70), 2, "continue", 24, nil, self.continueButtonClick, "00"
    )
    self.pauseMenu:newButton(
        "quit", vec2.new(380, 340), vec2.new(200, 70), 2, "title menu", 24, nil, self.titleButtonClick, "00"
    )
    self.pauseMenu.alpha = 0
    -- Death menu (game) ---------------------------------------------------------------------------------------
    self.deathMenu = zerpgui:newCanvas()
    self.deathMenu:newRectangle(
        "background", vec2.new(), vec2.new(SC_WIDTH, SC_HEIGHT), "fill", {0, 0, 0, 1}, 0, "xx"
    )
    self.deathMenu:newTextLabel(
        "title", vec2.new(0, 120), "Eliminated", 48, "00", "center"
    )
    self.deathMenu:newButton(
        "return", vec2.new(380, 420), vec2.new(200, 70), 2, "title menu", 24, nil, self.titleButtonClick, "00"
    )
    self.deathMenu:newTextLabel(
        "statsTitle", vec2.new(0, 200), "Statistics:", 20, "00", "center"
    )
    -- Intro ---------------------------------------------------------------------------------------------------
    self.introMenu = zerpgui:newCanvas()
    self.introMenu:newRectangle("background", vec2.new(), vec2.new(SC_WIDTH, SC_HEIGHT), "fill", {0, 0, 0, 0.8}, 0, "xx")
    self.introMenu:newTextLabel("title", vec2.new(415, 220), "Made by\nPolarity", 36, "00", "left", "Minecraftia", {1,1,1,0})
    self.introMenu:newTextLabel("titleNord", vec2.new(595, 270), "nord", 24, "00", "left", "Minecraftia", {1,1,1,0})
    self.introMenu:newImage("zerpie", vec2.new(350, 270), 0, assets.profileImg, 0.3, {1,1,1,0}, "00")
    self.introMenu.titleAlpha = 0
    self.introMenu.timer = 0
    self.introMenu.soundPlayed = false

    -- Stat numbers
    local r = 3
    local pos = vec2.new(-700, 230)
    for i in pairs(Stats) do
        if r < 1 then
            r = 3
            pos.x = pos.x + 270
            pos.y = 230
        end
        self.deathMenu:newTextLabel(
            "stat"..i, vec2.new(pos.x, pos.y), "0", 40, "00", "right"
        )
        self.deathMenu["stat"..i].statName = i
        self.statElements[#self.statElements+1] = self.deathMenu["stat"..i]
        pos.y = pos.y + 48
        r = r - 1
    end
    -- Stat names
    r = 3
    pos = vec2.new(305.5, 240)
    for i in pairs(StatNames) do
        if r < 1 then
            r = 3
            pos.x = pos.x + 270
            pos.y = 240
        end
        self.deathMenu:newTextLabel(
            "statN"..i, vec2.new(pos.x, pos.y), StatNames[i], 20, "00", "left"
        )
        pos.y = pos.y + 52
        r = r - 1
    end
    self.deathMenu.alpha = 0
end

function interface:update(delta)
    -- Change canvas based on GameState
    self:setCanvasVisible()
    -- Difficulty selection menu
    if GameState == "diffSelect" then
        self:updateDiffSelect()
    end
    -- Game
    if GameState == "game" then
        self:updateGame()
        self:updateDebug()
        self:updatePauseMenu()
        self:updateDeathMenu()
        self:updateHitmarkers(delta)
        self:updateDamageNums(delta)
    end
    -- Menu
    if GameState == "menu" then
        self:updateMenu()
    end
    if GameState == "settings" then
        self:updateSettingsMenu()
    end
    if GameState == "customize" then
        self:updateCustomizeMenu(delta)
    end
    if GameState == "intro" then
        self:updateIntroMenu(delta)
    end
    -- Zerpgui updating
    zerpgui:update(delta)
end

function interface:draw()
    if GameState == "customize" then
        for _, v in ipairs(self.trails) do
    	    v.draw()
    	end
    end
    zerpgui:draw()
    self:drawHitmarkers()
    self:drawDamageNums()
end

return interface