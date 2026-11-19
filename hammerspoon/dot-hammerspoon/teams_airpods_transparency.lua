-- Switch AirPods to Transparency while in a Microsoft Teams call, so you hear your own voice,
-- and switch back to the previous listening mode when the call ends.
--
-- "In a call" means: Teams is running and the AirPods microphone is in use.
-- There is no API for the AirPods listening mode, so this clicks the Sound menu bar item
-- (System Settings > Control Center > Sound: "Always Show in Menu Bar") through Accessibility.
-- If a macOS update changes that menu, this is the part that breaks.

local module = {}

local TEAMS_BUNDLE_ID = "com.microsoft.teams2"
local CONTROL_CENTER_BUNDLE_ID = "com.apple.controlcenter"
local SOUND_MENU_IDENTIFIER = "com.apple.menuextra.sound"
local CALL_MODE = "Transparency"
local POLL_INTERVAL_SECONDS = 2
-- The microphone has to be in use (or free) for this many polls in a row before the mode changes,
-- so a short microphone check in Teams does not flip the mode back and forth.
local STABLE_POLLS_REQUIRED = 2

local inCall = false
local stablePolls = 0
local modeBeforeCall = nil

local function log(message)
  print("[teams-airpods] " .. message)
end

local function findAirPodsInputDevice()
  for _, device in ipairs(hs.audiodevice.allInputDevices()) do
    if (device:name() or ""):find("AirPods") then
      return device
    end
  end

  return nil
end

local function isTeamsRunning()
  return #hs.application.applicationsForBundleID(TEAMS_BUNDLE_ID) > 0
end

local function isInTeamsCall()
  local airPods = findAirPodsInputDevice()

  return airPods ~= nil and airPods:inUse() and isTeamsRunning()
end

local function controlCenterElement()
  local controlCenter = hs.application.applicationsForBundleID(CONTROL_CENTER_BUNDLE_ID)[1]

  return controlCenter and hs.axuielement.applicationElement(controlCenter) or nil
end

local function findSoundMenuItem(controlCenter)
  local menuBar = controlCenter:attributeValue("AXExtrasMenuBar")

  for _, item in ipairs(menuBar and menuBar:attributeValue("AXChildren") or {}) do
    if item:attributeValue("AXIdentifier") == SOUND_MENU_IDENTIFIER then
      return item
    end
  end

  return nil
end

local function collectAirPodsElements(element, found)
  local identifier = element:attributeValue("AXIdentifier") or ""

  if identifier:find("^sound%-device%-") and identifier:find("AirPods") then
    table.insert(found, element)
  end

  for _, child in ipairs(element:attributeValue("AXChildren") or {}) do
    collectAirPodsElements(child, found)
  end

  return found
end

local function waitFor(condition, timeoutSeconds)
  local deadline = hs.timer.secondsSinceEpoch() + timeoutSeconds

  while hs.timer.secondsSinceEpoch() < deadline do
    local result = condition()
    if result then
      return result
    end
    hs.timer.usleep(100000)
  end

  return nil
end

local LISTENING_MODES = { ["Transparency"] = true, ["Adaptive"] = true, ["Noise Cancellation"] = true, ["Off"] = true }

local function listeningModeCheckboxes(elements)
  local checkboxes = {}
  local inListeningMode = false

  for _, element in ipairs(elements) do
    local role = element:attributeValue("AXRole")
    local description = element:attributeValue("AXDescription")

    if role == "AXHeading" then
      inListeningMode = description == "Listening Mode"
    elseif inListeningMode and role == "AXCheckBox" and LISTENING_MODES[description] then
      checkboxes[description] = element
    end
  end

  return checkboxes
end

-- Opens the Sound menu, optionally selects a listening mode, and closes the menu again.
-- With onlyIfCurrentMode, the new mode is only selected while that mode is the current one.
-- Returns the listening mode that was selected before, or nil when the AirPods were not found.
local function withListeningMode(newMode, onlyIfCurrentMode)
  local controlCenter = controlCenterElement()
  local soundMenuItem = controlCenter and findSoundMenuItem(controlCenter)

  if not soundMenuItem then
    log("Sound menu bar item not found. Turn on Control Center > Sound > Always Show in Menu Bar.")
    return nil
  end

  soundMenuItem:performAction("AXPress")

  local window = waitFor(function()
    return (controlCenter:attributeValue("AXWindows") or {})[1]
  end, 2)

  local previousMode = nil

  if window then
    local elements = collectAirPodsElements(window, {})

    -- The listening modes are hidden until the AirPods row is expanded.
    for _, element in ipairs(elements) do
      if element:attributeValue("AXRole") == "AXDisclosureTriangle" and element:attributeValue("AXValue") == 0 then
        element:performAction("AXPress")
        elements = waitFor(function()
          local expanded = collectAirPodsElements(window, {})
          return next(listeningModeCheckboxes(expanded)) and expanded or nil
        end, 2) or elements
        break
      end
    end

    local checkboxes = listeningModeCheckboxes(elements)

    for mode, checkbox in pairs(checkboxes) do
      if checkbox:attributeValue("AXValue") == 1 then
        previousMode = mode
      end
    end

    if onlyIfCurrentMode and previousMode ~= onlyIfCurrentMode then
      log("Listening mode changed during the call (" .. tostring(previousMode) .. "), leaving it.")
    elseif newMode and checkboxes[newMode] and previousMode ~= newMode then
      checkboxes[newMode]:performAction("AXPress")
      log("Listening mode: " .. tostring(previousMode) .. " -> " .. newMode)
    elseif newMode and not checkboxes[newMode] then
      log("Listening mode '" .. newMode .. "' not found in the Sound menu.")
    end
  else
    log("The Sound menu did not open.")
  end

  -- Escape does not close this menu. Clicking the menu bar item again does.
  if (controlCenter:attributeValue("AXWindows") or {})[1] then
    soundMenuItem:performAction("AXPress")
  end

  return previousMode
end

local function onCallStarted()
  modeBeforeCall = withListeningMode(CALL_MODE)

  if modeBeforeCall and modeBeforeCall ~= CALL_MODE then
    hs.alert.show("Teams call: AirPods Transparency")
  end
end

local function onCallEnded()
  if modeBeforeCall and modeBeforeCall ~= CALL_MODE then
    -- Only restore when the mode is still the one this script chose, so a manual change during the call wins.
    if withListeningMode(modeBeforeCall, CALL_MODE) == CALL_MODE then
      hs.alert.show("Call ended: AirPods " .. modeBeforeCall)
    end
  end

  modeBeforeCall = nil
end

local function poll()
  local callNow = isInTeamsCall()

  if callNow == inCall then
    stablePolls = 0
    return
  end

  stablePolls = stablePolls + 1

  if stablePolls < STABLE_POLLS_REQUIRED then
    return
  end

  stablePolls = 0
  inCall = callNow

  if inCall then
    log("Teams call started")
    onCallStarted()
  else
    log("Teams call ended")
    onCallEnded()
  end
end

function module.start()
  if module.timer then
    module.timer:stop()
  end

  inCall = isInTeamsCall()
  module.timer = hs.timer.doEvery(POLL_INTERVAL_SECONDS, poll)
end

-- For testing from the command line: hs -c 'teams_airpods.setMode("Noise Cancellation")'
module.setMode = withListeningMode

return module
