local lib = {}

lib.on_init = function()
  if not remote.interfaces["freeplay"] then return end
  local created_items = remote.call("freeplay", "get_created_items")
  created_items["mining-depot"] = 1
  created_items["mining-drone"] = 1
  created_items["burner-mining-drill"] = nil
  remote.call("freeplay", "set_created_items", created_items)
end


local events = require("event_handler")
events.add_lib(lib)

