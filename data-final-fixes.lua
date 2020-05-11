local rusty_locale = require '__rusty-locale__.locale'

local banned_types = {
    "loader-1x1",
    "loader-1x2",
    "splitter",
    "transport-belt",
    "underground-belt",
}

local banned_entities = {}

for _,type in ipairs(banned_types) do
    print("banning all: " .. type)
    local entities = data.raw[type]
    print("entities: " .. tostring(entities))
    if entities then
        for _,e in pairs(entities) do
            print("    banning: " .. e.name)
            banned_entities[e.name] = e
        end
    end
end

local items = data.raw.item

local is_item_banned = function(name)
    local item = items[name]
    if not item then return false end
    if item.place_result == nil then return false end
    return banned_entities[item.place_result] ~= nil
end

local recipes_for_proxies = {}
local proxies_required = {}

local proxify = function(str)
    return str .. "-dw-proxy"
end

local banned_icon_layer = {
    icon = "__Drone_World__/BANNED.png",
    icon_size = 64,
    tint = {r=1.0, a=.5},
}

for name,item in pairs(data.raw.item) do
    if is_item_banned(item.name) then
        local proxy = util.copy(item)
        if proxy.icons then
            proxy.icons[#proxy.icons+1] = banned_icon_layer
        elseif proxy.icon then
            proxy.icons = {
                {
                    icon = proxy.icon,
                    icon_size = proxy.icon_size,
                },
                banned_icon_layer
            }
        else
            assert(false)
        end
        proxy.name = proxify(proxy.name)
        item_loc = rusty_locale.of(item)
        proxy.localised_name = {"dw-proxy", item_loc.name}
        print("localised name: " .. serpent.line(item_loc))
        proxy.place_result = nil
        data:extend{proxy}
    end
end

local append_recipe = function(proxy, recipe)
    print("appending recipe for: " .. proxy)
    local arr = recipes_for_proxies[proxy]
    if not arr then
        arr = {}
        recipes_for_proxies[proxy] = arr
    end
    arr[#arr+1] = recipe
end

local handle_recipe = function(recipe)
    if not recipe then return false end
    local required = {}
    local banned = false
    if recipe.ingredients then
        for _,item in ipairs(recipe.ingredients) do
            if is_item_banned(item[1]) then
                item[1] = proxify(item[1])
                required[#required] = item[1]
            end
        end
    end
    if recipe.result then
        if is_item_banned(recipe.result) then
            recipe.result = proxify(recipe.result)
            banned = true
            append_recipe(recipe.result, recipe)
        end
    elseif recipe.results then
        for i,r in ipairs(recipe.results) do
            if is_item_banned(r[1]) then
                r[1] = proxify(r[1])
                banned = true
                append_recipe(r[1], recipe)
            end
        end
    end

    if not banned then
        for _,item in pairs(required) do
            print("force requiring proxy: ".. item)
            proxies_required[item] = true
        end
    end
    return banned
end

for name,recipe in pairs(data.raw.recipe) do
    -- log("checking recipe: " .. recipe.name)
    -- log(serpent.line(recipe))
    if name == "express-transport-belt" then
        print(serpent.block(recipe))
    end
    if not recipe.hidden then
        local banned_root = handle_recipe(recipe)
        local banned_normal = handle_recipe(recipe.normal ~= false and recipe.normal)
        local banned_hard = handle_recipe(recipe.expensive ~= false and recipe.expensive )

        local banned = banned_root or banned_normal or banned_hard
        recipe.hidden = banned

        if banned then
            print("banned: " .. recipe.name)
        end
    end
end

for req,_ in pairs(proxies_required) do
    print("requred proxy: " .. req)
    for _,recipe in pairs(recipes_for_proxies[req]) do
        recipe.hidden = false
    end
end

