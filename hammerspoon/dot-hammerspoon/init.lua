hs.window.animationDuration = 0

local left_alt_keycode = 58
local workspace_switch_keycodes = {
  [18] = "1",
  [19] = "2",
  [20] = "3",
  [21] = "4",
  [23] = "5",
  [22] = "6",
  [26] = "7",
  [28] = "8",
  [25] = "9",
  [29] = "0",
  [48] = "tab",
}

local workspace_move_keycodes = {
  [18] = "1",
  [19] = "2",
  [20] = "3",
  [21] = "4",
  [23] = "5",
  [22] = "6",
  [26] = "7",
  [28] = "8",
  [25] = "9",
  [29] = "0",
}

local left_alt_active = false
local left_alt_down = false

local function has_extra_modifiers(flags)
  return flags.cmd or flags.ctrl or flags.shift or flags.fn
end

local function has_move_extra_modifiers(flags)
  return flags.cmd or flags.ctrl or flags.fn
end

local left_alt_tap = hs.eventtap.new({ hs.eventtap.event.types.flagsChanged }, function(event)
  if event:getKeyCode() ~= left_alt_keycode then
    return false
  end

  local flags = event:getFlags()
  left_alt_down = flags.alt
  left_alt_active = left_alt_down and not has_extra_modifiers(flags)

  return false
end)

local workspace_switch_tap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
  local flags = event:getFlags()

  if left_alt_down and flags.alt and flags.shift and not has_move_extra_modifiers(flags) then
    local key = workspace_move_keycodes[event:getKeyCode()]
    if key then
      hs.eventtap.keyStroke({ "cmd", "alt", "shift" }, key, 0)
      return true
    end
  end

  if not left_alt_active then
    return false
  end

  if not flags.alt or has_extra_modifiers(flags) then
    return false
  end

  local key = workspace_switch_keycodes[event:getKeyCode()]
  if not key then
    return false
  end

  hs.eventtap.keyStroke({ "ctrl", "alt", "shift" }, key, 0)
  return true
end)

local config_watcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", function(files)
  local should_reload = false

  for _, file in ipairs(files) do
    if file:sub(-4) == ".lua" then
      should_reload = true
      break
    end
  end

  if should_reload then
    hs.reload()
  end
end)

left_alt_tap:start()
workspace_switch_tap:start()
config_watcher:start()
hs.alert.show("Hammerspoon loaded")
