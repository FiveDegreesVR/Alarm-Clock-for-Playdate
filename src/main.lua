-- TO DO:
-- 1.1 Release
	-- Better snooze 
	-- add blinking to center : in time (use timer?)
	-- am/pm option for display time 
	-- save current alarm between program instances (https://sdk.play.date/inside-playdate/#saving-state)
-- 1.2 Release
	-- Multiple alarm sounds

-- imports
import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/ui"

-- var declaration 
local gfx <const> = playdate.graphics

local hourNum = nil
local minNum = nil

local clockActive = true

local slot = 0

local alarmHour = 0
local alarmMin = 0
local alarmInterval = 1
local alarmIntervalLength = 1

local currentAlarmHour = 0
local currentAlarmMin = 0
local currentAlarmInterval = 1
local currentAlarmIntervalLength = 1

local alarmActivateMenuItem = nil
local hintsActiveMenuItem = nil
local menu = nil

local alarmSFX = nil
local alarmImage = nil
local intervalImage = nil
local timeIntervalImage = nil
local slotImage = nil

local checkTimeTimer = nil

-- plays alarm when called if alarm is not already playing
function playAlarm(alarmSFX)
    if not alarmSFX:isPlaying() then
        alarmSFX:play(0)
    end
end

-- when called checks active alarm time for all intervals against current time 
function checkTime(hour, min, interval, intervalAmount)
    intervalIncrease = 0

    -- var declaration 
    localHour = hour
    localMin = min
    localInterval = interval
    localIntervalAmount = intervalAmount

    --for loop checks alarm at each interval offset, if time matches getTime alarm plays 
    for x=0,localInterval do
        if localMin + localIntervalAmount >= 60 then
            localMin = (localMin + localIntervalAmount) - 60
            localHour = localHour + 1

            if localHour >= 24 then
                localHour = 00
            end
        end

        if playdate.getTime().hour == localHour and playdate.getTime().minute == (localMin+intervalIncrease) then
            alarmActive = true
            playAlarm(alarmSFX)
        else
            alarmActive = false
        end

        intervalIncrease = intervalIncrease + localIntervalAmount
    end
end

-- parse 2 place int val into 2 indivdiual ints
-- ex: 23 becomes 2,3
function parseIntVals(numToParse)
    numToParse1 = 0 
    numToParse2 = numToParse

    while numToParse >= 10 do
        numToParse1 += 1
        numToParse2 -=10
        numToParse -= 10
    end

    return numToParse1,numToParse2
end

-- rasies or lowers a value based on what direction dpad is presseded
-- fed a upper and lower limit to insure value stays in range
function checkInputEtc(valToCheck, upDpad, downDpad, upperLimit, lowerLimit)
    if upDpad then
        valToCheck += 1
    elseif downDpad then
        valToCheck -= 1
    end

    if valToCheck > upperLimit then
        valToCheck = lowerLimit;
    elseif valToCheck < lowerLimit then 
        valToCheck = upperLimit
    end

    return valToCheck
end

-- rasies or lowers a value based on what direction dpad is presseded
-- fed amount to raise or lower value by
function checkInput(valToCheck, upDpad, downDpad, amountToChangeBy)
    -- up on dpad
    if upDpad then
        valToCheck+=amountToChangeBy
    end

    -- down on dpad
    if downDpad then
        valToCheck-=amountToChangeBy
    end

    return valToCheck
end

-- draws clock in center of screen based on 2 alarm vals and 2 min vals
-- ex: 23:14 fed in as 2,3,1,4
function drawCenterClock(hourVal1,hourVal2, minVal1, minVal2)
    clockImageTable:getImage(hourVal1+2):draw(56,60)
    clockImageTable:getImage(hourVal2+2):draw(121,60)
    clockImageTable:getImage(12):draw(191,60)
    clockImageTable:getImage(minVal1+2):draw(221,60)
    clockImageTable:getImage(minVal2+2):draw(286,60)
end

-- draws current time and alarm details if alarm is active 
function updateDisplayClock()
    -- var declaration 
    hourVal1 = nil
    hourVal2 = nil
    minVal1 = nil
    minVal2 = nil

    offset = 0

    currentHourTime = playdate.getTime().hour
    currentMinTime = playdate.getTime().minute

    --calculate hourNums
    hourVal1, hourVal2 = parseIntVals(currentHourTime)

    --calculate minNums
    minVal1, minVal2 = parseIntVals(currentMinTime)

    --draws clock and hint if needed
    drawCenterClock(hourVal1,hourVal2, minVal1, minVal2)
    if hintsActiveMenuItem:getValue() then
        playdate.graphics.drawTextAligned("Ⓐ Set an Alarm", 200, 215, kTextAlignment.center)
    end

    -- sets offset for drawing alarm details
    if currentAlarmHour > 9 then
        offset = 7
    end

    -- if alarm active draw alarm details
    if alarmActivateMenuItem:getValue() == true then
        -- alarm text
        playdate.graphics.drawText("Alarm: " .. currentAlarmHour .. ":" .. string.format("%02d",currentAlarmMin), 35, 10)

        -- alarm image
        alarmImage:draw(5,5)

        -- alarm interval image + text
        intervalImage:draw(122+offset,5)
        playdate.graphics.drawText(currentAlarmInterval, 150+offset, 10)

        -- alarm interval length image + text
        timeIntervalImage:draw(165+offset,5)
        playdate.graphics.drawText(currentAlarmIntervalLength, 194+offset, 10)
    end
end

-- function for setting alarm clock
function alarmClockSetting()
    -- var declaration
    leftDPad = playdate.buttonJustReleased(playdate.kButtonLeft)
    rightDPad = playdate.buttonJustReleased(playdate.kButtonRight)
    upDPad = playdate.buttonJustReleased(playdate.kButtonUp)
    downDPad = playdate.buttonJustReleased(playdate.kButtonDown)

    -- detirmine what "slot" the user is modifing
    slot = checkInput(slot, rightDPad, leftDPad, 1)
    if slot < 0 then
        slot = 5
    elseif slot > 5 then
        slot = 0
    end

    --sudo switch case for changing what up and down dpad do in diffrent slots of menu
    if slot == 0 then
        --setting alarm hour val 1
        --incrementing alarm hour by 10
        alarmHour = checkInput(alarmHour,upDPad,downDPad,10)

        -- restriction to make sure hour is never > 23
        if alarmHour >= 30 then 
            alarmHour -= 10
        end

        -- draw slot image in appropriate location 
        slotImage:draw(54,160)

    elseif slot == 1 then
        --setting alarm hour val 2
        --incrementing alarm hour by 1
        alarmHour = checkInput(alarmHour,upDPad,downDPad,1)

        -- draw slot image in appropriate location 
        slotImage:draw(119,160)

    elseif slot == 2 then
        --setting alarm min val 1
        --incrementing alarm min by 10
        alarmMin = checkInput(alarmMin,upDPad,downDPad,10)

        -- restriction to make sure min is never < 00
        if alarmMin < 0 then
            alarmMin += 10
        end

        -- draw slot image in appropriate location 
        slotImage:draw(219,160)

    elseif slot == 3 then
        --setting alarm min val 1
        --incrementing alarm min by 1
        alarmMin = checkInput(alarmMin,upDPad,downDPad,1)

        -- restriction to make num loop if go under 00 or above 59
        if alarmMin < 00 then 
            alarmMin = 59
        elseif alarmMin > 59 then
            alarmMin = 00
        end

        -- draw slot image in appropriate location 
        slotImage:draw(284,160)

    elseif slot == 4 then
        --setting alarm interval val 1
        --incrementing alarm interval by 1
        -- max val is 10, min val is 1
        alarmInterval = checkInputEtc(alarmInterval, upDPad, downDPad, 10, 1)

        -- draw slot image in appropriate location 
        slotImage:draw(168,181)

    elseif slot == 5 then
        --setting alarm interval length val 1
        --incrementing alarm interval length by 1
        -- max val is 60, min val is 1
        alarmIntervalLength = checkInputEtc(alarmIntervalLength, upDPad, downDPad, 60, 1)

        -- draw slot image in appropriate location 
        slotImage:draw(168,201)

    end

    -- limit alarm min to max 59 and min 00
    if alarmMin > 59 then 
        alarmMin -= 10
    elseif alarmMin < 00 then 
        alarmMin = 00
    end

    -- limit alarm hour to max 23 and min 00
    if alarmHour > 23 then
        alarmHour = 23
    elseif alarmHour < 00 then 
        alarmHour = 00
    end

    --draw current time, interval, and interval length 
    playdate.graphics.drawText("Current Time: " .. currentTime, 5, 5)
    playdate.graphics.drawTextAligned("Intervals: " .. alarmInterval, 200, 165, kTextAlignment.center)
    playdate.graphics.drawTextAligned("Time between intervals: " .. alarmIntervalLength, 200, 185, kTextAlignment.center)

    -- draw hint if needed
    if hintsActiveMenuItem:getValue() then
        playdate.graphics.drawTextAligned("Ⓐ Set an Alarm, Ⓑ Cancel an Alarm", 200, 215, kTextAlignment.center)
    end
    
    --parse hour and min vals to call draw clock function 
    alarmHourVal1, alarmHourVal2 = parseIntVals(alarmHour)
    alarmMinVal1, alarmMinVal2 = parseIntVals(alarmMin)
    drawCenterClock(alarmHourVal1,alarmHourVal2, alarmMinVal1, alarmMinVal2)
end

-- stop SFX if called
 function snooze()
    --checkTimeTimer:reset()
    alarmSFX:stop()
end

-- manage A and B button commands based on what menu is active
 function ABButtonManager()
    if clockActive then
        -- if A used while clock active go to alarm screen
        -- if B used while clock active snooze alarm
        if playdate.buttonJustReleased(playdate.kButtonA) then 
            clockActive = false
        elseif playdate.buttonJustReleased(playdate.kButtonB) then 
            snooze()
        end

    else
        -- if A used while clock not active set active alarm to the one stored on alarm screen and enable alarm
        -- if B used while clock not active set alarm values back to previous values and disable alarm
        if playdate.buttonJustReleased(playdate.kButtonA) then 
            clockActive = true
            currentAlarmHour = alarmHour
            currentAlarmMin = alarmMin
            currentAlarmInterval= alarmInterval
            currentAlarmIntervalLength = alarmIntervalLength

            alarmActivateMenuItem:setValue(true)
        elseif playdate.buttonJustReleased(playdate.kButtonB) then 
            clockActive = true
            alarmHour = currentAlarmHour
            alarmMin = currentAlarmMin
            alarmInterval = currentAlarmInterval
            alarmIntervalLength = currentAlarmIntervalLength

            alarmActivateMenuItem:setValue(false)
        end

    end
end

-- called when app first started 
function initialize()
    -- if batter over 30% or playdate is being charged, disable the auto power down feature for input idle
    if playdate.getBatteryPercentage()>30 or playdate.getPowerStatus().changing then 
        playdate.setAutoLockDisabled(true)
    end
    
    -- lower refresh rate to 10 to help battery life
    playdate.display.setRefreshRate(10)

    --set menu item for turning on/off the alarm
    menu = playdate.getSystemMenu()
    alarmActivateMenuItem = menu:addCheckmarkMenuItem("Alarm Active", false, function (value)
        print("Checkmark menu item value changed to: ", value)
    end)
    --set menu item for turning on/off hints in main clock and alarm setting screen
    hintsActiveMenuItem = menu:addCheckmarkMenuItem("Hints Active", true, function (value)
        print("Hints menu item value changed to: ", value)
    end)
    --set menu item for enabling night mode (invert display colors)
    invertDisplayActiveMenuItem = menu:addCheckmarkMenuItem("Night Mode", false, function (value)
        playdate.display.setInverted(value)
    end)

    -- grab all required images from image folder
    clockImageTable = gfx.imagetable.new("images/Mikodacs-Clock")
    alarmImage = gfx.image.new("images/alarm")
    intervalImage = gfx.image.new("images/interval")
    timeIntervalImage = gfx.image.new("images/timeBetweenIntervals")
    slotImage = gfx.image.new("images/slot")

    -- grab all required sounds from sound folder, max volume
    alarmSFX = playdate.sound.sampleplayer.new("sounds/Alarm_SFX")
    alarmSFX:setVolume(1)

    --set backgroud for both scenes
    local backroundImage = gfx.image.new("images/background")
    gfx.sprite.setBackgroundDrawingCallback(
        function (x,y, width, height)
            gfx.setClipRect(x,y, width, height)
            backroundImage:draw(0, 0)
            gfx.clearClipRect()
        end
    )

    -- create timer function for calling checkTime once every minuite 
    -- set to auto calibrate once every minute to insure accurracy
    checkTimeTimer = playdate.timer.new(60000 - (playdate.getTime().second*1000))
    checkTimeTimer.repeats = true
    checkTimeTimer.reverses = false
    checkTimeTimer.timerEndedCallback = function (timer)
        if alarmActivateMenuItem:getValue() then
            checkTime(currentAlarmHour,currentAlarmMin,currentAlarmInterval,currentAlarmIntervalLength)
        end

        timer.duration = (60000 - (playdate.getTime().second*1000))
        timer:reset()
    end
    
end

initialize() -- call intial function

-- fucntion called each frame
function playdate.update()
    -- update checkTime timer
    playdate.timer.updateTimers()
    -- update sprites
    gfx.sprite.update()

    --find current time from playdate clock
    hourNum = playdate.getTime().hour
    minNum = playdate.getTime().minute

    --create string based on current time
    currentTime = tostring(hourNum) .. ":" .. string.format("%02d",minNum)

    -- call button input manager for A and B
    ABButtonManager()
    
    -- clock active = main scene active
    if clockActive then
        -- refresh for clock screen
        updateDisplayClock()
    else
        --refresh for alarm set screen
        alarmClockSetting()
    end

    -- reset timer if it reaches 0
    -- this is a fail safe
    if checkTimeTimer.currentTime < 0 then
        checkTimeTimer:reset()
    end

    -- enable idle lock if battery falls bellow 30 and playdate is not being charged 
    if playdate.getBatteryPercentage()>30 and not playdate.getPowerStatus().changing then 
        playdate.setAutoLockDisabled(true)
    else
        playdate.setAutoLockDisabled(false)
    end
end

