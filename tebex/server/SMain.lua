local ESX = {}



local giveway = {

    isEnabled = true,

    points = 500

} 

local function GetTime()

    local date = os.date('*t')

    if date.day < 10 then date.day = '0' .. tostring(date.day) end

    if date.month < 10 then date.month = '0' .. tostring(date.month) end

    if date.hour < 10 then date.hour = '0' .. tostring(date.hour) end

    if date.min < 10 then date.min = '0' .. tostring(date.min) end

    if date.sec < 10 then date.sec = '0' .. tostring(date.sec) end

    local date = date.day .. "/" .. date.month .. "/" .. date.year .. " - " .. date.hour .. " heures " .. date.min .. " minutes " .. date.sec .. " secondes"

    return date
    
end


local function GetHistory()

    local data = LoadResourceFile('tebex2', 'history.txt')

    return data and json.decode(data) or {}

end

oldHistory = {}



---@class STebex 

STebex = STebex or {};



---@class STebex.Cache

STebex.Cache = STebex.Cache or {}



---@class STebex.Cache.Case

STebex.Cache.Case = STebex.Cache.Case or {}



function STebex:HasValue(tab, val)

    for i = 1, #tab do

        if tab[i] == val then

            return true

        end

    end

    return false

end



TriggerEvent('::{xWayzen}::esx:getSharedObject', function(obj)

    ESX = obj

end)



Citizen.CreateThread(function()

    while ESX == nil do

        TriggerEvent('::{xWayzen}::esx:getSharedObject', function(obj)

            ESX = obj

        end)

        Citizen.Wait(0)

    end

end)



local characters = { "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z" }



local Server = {};



function Server:GetIdentifiers(source)

    if (source ~= nil) then

        local identifiers = {}

        local playerIdentifiers = GetPlayerIdentifiers(source)

        for _, v in pairs(playerIdentifiers) do

            local before, after = playerIdentifiers[_]:match("([^:]+):([^:]+)")

            identifiers[before] = playerIdentifiers[_]

        end

        return identifiers

    else

        error("source is nil")

    end

end



function Server:DiscordHook(message)

    local embeds = {

        {

            ['title'] = message,

            ['type'] = 'rich',

            ['color'] = '56108',

            ['footer'] = {

                ['text'] = 'Achats sur la boutique en jeux'

            }

        }

    }

    PerformHttpRequest("https://discord.com/api/webhooks/815318908365701141/zEQkOAIOoqgwJQOYnig6nUPx1IsqGLvP9ONLj-THRXhJObT6kF6BrObuM1guyPWGBvdY", function() end, 'POST', json.encode({ username = 'Le banquier', embeds = embeds }), { ['Content-Type'] = 'application/json' })

end



function Server:CreateRandomPlateText()

    local plate = ""

    math.randomseed(GetGameTimer())

    for i = 1, 4 do

        plate = plate .. characters[math.random(1, #characters)]

    end

    plate = plate .. ""

    for i = 1, 3 do

        plate = plate .. math.random(1, 9)

    end

    return plate

end


function Server:OnProcessCheckout(source, price, transaction, onAccepted, onRefused)

    local identifier = Server:GetIdentifiers(source);

    if (identifier['fivem']) then

        local before, after = identifier['fivem']:match("([^:]+):([^:]+)")

        MySQL.Async.fetchAll("SELECT SUM(points) FROM tebex_players_wallet WHERE identifiers = @identifiers", {

            ['@identifiers'] = after

        }, function(result)

            local current = tonumber(result[1]["SUM(points)"]);

            if (current ~= nil) then

                if (current >= price) then

                    LiteMySQL:Insert('tebex_players_wallet', {

                        identifiers = after,

                        transaction = transaction,

                        price = '0',

                        currency = 'Points',

                        points = -price,

                    });

                    onAccepted();

                else

                    onRefused();

                    xPlayer.showNotification('Mince Vous ne posséder pas les points nécessaires pour votre achat visité notre boutique.')

                end

            else

                onRefused();

                print('[Info] retrieve points nil')

            end

        end);

    else

        onRefused();

        --print('[Exeception] Failed to retrieve fivem identifier')

    end

end



function Server:Giving(xPlayer, identifier, item)

    local content = json.decode(item.action);



    if (content.vehicles) then

        for key, value in pairs(content.vehicles) do

            local plate = Server:CreateRandomPlateText();



            LiteMySQL:Insert('owned_vehicles', {

                owner = identifier['license'],

                plate = plate,

                vehicle = json.encode({ model = value.name, plate = plate }),

                type = value.type,

                state = 1,

            })

            LiteMySQL:Insert('open_car', {

                owner = identifier['license'],

                plate = plate

            });



        end

    end



    if (content.weapons) then

        for key, value in pairs(content.weapons) do

            if (value.name ~= "weapon_custom") then

                print(value.name)

                xPlayer.addWeapon(value.name, value.ammo)

            end

        end

    end



    if (content.items) then

        for key, value in pairs(content.items) do

            xPlayer.addInventoryItem(value.name, value.count)

        end

    end



    if (content.items) then

        for key, value in pairs(content.items) do

            xPlayer.addInventoryItem(value.name, value.count)

        end

    end



    if (content.bank) then

        for key, value in pairs(content.bank) do

            xPlayer.addAccountMoney('bank', value.count)

        end

    end

end



function Server:onGiveaway(source)

    if (giveway.isEnabled) then

        local identifier = Server:GetIdentifiers(source);

        if (identifier['fivem']) then

            local before, after = identifier['fivem']:match("([^:]+):([^:]+)")

            local count, value = LiteMySQL:Select('tebex_players_wallet_gift'):Where('identifiers', '=', after):Get()

            if (count == 0) then

                LiteMySQL:Insert('tebex_players_wallet_gift', {

                    identifiers = after,

                    have_receive = true,

                    points = giveway.points

                })

                LiteMySQL:Insert('tebex_players_wallet', {

                    identifiers = after,

                    transaction = 'Automatics Gift',

                    price = 0,

                    currency = 'EUR',

                    points = giveway.points

                })

                TriggerClientEvent('::{xWayzen}::esx:showNotification', source, "~g~Pour vous excuser de ce désagrément, nous vous avons donné " .. giveway.points .. " points boutique (F1).")

            else

                TriggerClientEvent('::{xWayzen}::esx:showNotification', source, "~g~Vous avez déjà reçu votre récompense.")

            end

        else

            TriggerClientEvent('::{xWayzen}::esx:showNotification', source, "~b~Vous ne pouvez pas bénéficier des " .. giveway.points .. " points gratuits car votre compte de FiveM n'est pas lié.")

        end

    end

end


RegisterServerEvent('tebex:on-process-checkout-case')

AddEventHandler('tebex:on-process-checkout-case', function()

    local source = source;

    if (source) then

        local identifier = Server:GetIdentifiers(source);

        local xPlayer = ESX.GetPlayerFromId(source)

            Server:OnProcessCheckout(source, 1000, "Caisse Impulsion", function()

                local plate = Server:CreateRandomPlateText();

                local bite = math.random(2,17)

                if bite == 1 then
                    xPlayer.addWeapon('weapon_pistol', 250)
                        TriggerClientEvent('::{xWayzen}::esx:showAdvancedNotification', source, 'Boutique', 'Informations', 'Vous avez reçus un pistolet', 'CHAR_WENDY', 6, 2)
                    end
                    if bite == 2 then
                        xPlayer.addWeapon('weapon_snowball', 1)
                            TriggerClientEvent('::{xWayzen}::esx:showAdvancedNotification', source, 'Boutique', 'Informations', 'Vous avez reçus une boule de neige', 'CHAR_WENDY', 6, 2)
                        end
                        if bite == 3 then
                            xPlayer.addAccountMoney('cash', 1000000)
                               TriggerClientEvent('::{xWayzen}::esx:showAdvancedNotification', source, 'Boutique', 'Informations', 'Vous avez reçus 1,000,000$ en liquide', 'CHAR_WENDY', 6, 2)
                            end
                           if bite == 4 then
                            LiteMySQL:Insert('owned_vehicles', {

                                owner = identifier['license'],
                
                                plate = plate,
                
                                vehicle = json.encode({ model = "rmodsianr", plate = plate }),
                
                                type = 'car',
                
                                state = 1,
                
                            })
                            LiteMySQL:Insert('open_car', {

                                owner = identifier['license'],
                
                                plate = plate
                
                            });
                            TriggerClientEvent('::{xWayzen}::esx:showAdvancedNotification', source, 'Boutique', 'Informations', 'Vous avez reçus une Lamborghini Sianr', 'CHAR_WENDY', 6, 2)
                               end
                               if bite == 5 then
                                   xPlayer.addWeapon('weapon_musket', 250)
                                       TriggerClientEvent('::{xWayzen}::esx:showAdvancedNotification', source, 'Boutique', 'Informations', 'Vous avez reçus un mousquet', 'CHAR_WENDY', 6, 2)
                               end
                               if bite == 6 then
                                   xPlayer.addWeapon('weapon_stone_hatchet', 250)
                                       TriggerClientEvent('::{xWayzen}::esx:showAdvancedNotification', source, 'Boutique', 'Informations', 'Vous avez reçus une hache en pierre', 'CHAR_WENDY', 6, 2)
                               end
                               if bite == 7 then
                                xPlayer.addWeapon('weapon_hatchet', 250)
                                    TriggerClientEvent('::{xWayzen}::esx:showAdvancedNotification', source, 'Boutique', 'Informations', 'Vous avez reçus un sabre laser', 'CHAR_WENDY', 6, 2)
                                end
                                    if bite == 9 then
                                        LiteMySQL:Insert('owned_vehicles', {

                                            owner = identifier['license'],
                            
                                            plate = plate,
                            
                                            vehicle = json.encode({ model = "rmodrs6", plate = plate }),
                            
                                            type = 'car',
                            
                                            state = 1,
                            
                                        })
                                        LiteMySQL:Insert('open_car', {

                                            owner = identifier['license'],
                            
                                            plate = plate
                            
                                        });
                                        TriggerClientEvent('::{xWayzen}::esx:showAdvancedNotification', source, 'Boutique', 'Informations', 'Vous avez reçus une rs6', 'CHAR_WENDY', 6, 2)
                                    end
                                       if bite == 10 then
                                           xPlayer.addWeapon('weapon_combatmg', 250)
                                               TriggerClientEvent('::{xWayzen}::esx:showAdvancedNotification', source, 'Boutique', 'Informations', 'Vous avez reçus une batteuse', 'CHAR_WENDY', 6, 2)
                                           end
                                           if bite == 11 then
                                               xPlayer.addWeapon('weapon_pistol50', 250)
                                                   TriggerClientEvent('::{xWayzen}::esx:showAdvancedNotification', source, 'Boutique', 'Informations', 'Vous avez reçus un pistol.cal50', 'CHAR_WENDY', 6, 2)
                                           end
                                           if bite == 12 then
                                            LiteMySQL:Insert('owned_vehicles', {

                                                owner = identifier['license'],
                                
                                                plate = plate,
                                
                                                vehicle = json.encode({ model = "sultanrs", plate = plate }),
                                
                                                type = 'car',
                                
                                                state = 1,
                                
                                            })
                                            LiteMySQL:Insert('open_car', {
    
                                                owner = identifier['license'],
                                
                                                plate = plate
                                
                                            });
                                            TriggerClientEvent('::{xWayzen}::esx:showAdvancedNotification', source, 'Boutique', 'Informations', 'Vous avez reçus une sultanrs', 'CHAR_WENDY', 6, 2)
                                           end
                                           if bite == 13 then
                                            xPlayer.addWeapon('weapon_knuckle', 250)
                                                TriggerClientEvent('::{xWayzen}::esx:showAdvancedNotification', source, 'Boutique', 'Informations', 'Vous avez reçus un poing américain', 'CHAR_WENDY', 6, 2)
                                            end
                                            if bite == 14 then
                                                xPlayer.addWeapon('weapon_snowball', 1)
                                                    TriggerClientEvent('::{xWayzen}::esx:showAdvancedNotification', source, 'Boutique', 'Informations', 'Vous avez reçus une boule de neige', 'CHAR_WENDY', 6, 2)
                                                end
                                                if bite == 15 then
                                                    xPlayer.addAccountMoney('bank', 500000)
                                                       TriggerClientEvent('::{xWayzen}::esx:showAdvancedNotification', source, 'Boutique', 'Informations', 'Vous avez reçus 500,000$ en liquide', 'CHAR_WENDY', 6, 2)
                                                    end
                                                   if bite == 16 then
                                                    LiteMySQL:Insert('owned_vehicles', {

                                                        owner = identifier['license'],
                                        
                                                        plate = plate,
                                        
                                                        vehicle = json.encode({ model = "rmodlego3", plate = plate }),
                                        
                                                        type = 'car',
                                        
                                                        state = 1,
                                        
                                                    })
                                                    LiteMySQL:Insert('open_car', {
            
                                                        owner = identifier['license'],
                                        
                                                        plate = plate
                                        
                                                    });
                                                    TriggerClientEvent('::{xWayzen}::esx:showAdvancedNotification', source, 'Boutique', 'Informations', 'Vous avez reçus une lego', 'CHAR_WENDY', 6, 2)
                                                       end
                                                       if bite == 17 then
                                                           xPlayer.addWeapon('weapon_dbshotgun', 250)
                                                               TriggerClientEvent('::{xWayzen}::esx:showAdvancedNotification', source, 'Boutique', 'Informations', 'Vous avez reçus un canon scié', 'CHAR_WENDY', 6, 2)
                                                       end
                                                       if bite == 18 then
                                                        LiteMySQL:Insert('owned_vehicles', {
    
                                                            owner = identifier['license'],
                                            
                                                            plate = plate,
                                            
                                                            vehicle = json.encode({ model = "kx450f", plate = plate }),
                                            
                                                            type = 'car',
                                            
                                                            state = 1,
                                            
                                                        })
                                                        LiteMySQL:Insert('open_car', {
                
                                                            owner = identifier['license'],
                                            
                                                            plate = plate
                                            
                                                        });
                                                        TriggerClientEvent('::{xWayzen}::esx:showAdvancedNotification', source, 'Boutique', 'Informations', 'Vous avez reçus un kx450', 'CHAR_WENDY', 6, 2)
                                                           end
                                                       if bite == 19 then
                                                           xPlayer.addWeapon('weapon_revolver', 250)
                                                               TriggerClientEvent('::{xWayzen}::esx:showAdvancedNotification', source, 'Boutique', 'Informations', 'Vous avez reçus un revolver', 'CHAR_WENDY', 6, 2)
                                                       end
                    end)

                end

            end)


RegisterServerEvent('tebex:on-process-checkout')

AddEventHandler('tebex:on-process-checkout', function(itemId)

    local source = source;

    if (source) then

        local identifier = Server:GetIdentifiers(source);

        local xPlayer = ESX.GetPlayerFromId(source)

        if (xPlayer) then

            local count, content = LiteMySQL:Select('tebex_boutique'):Where('id', '=', itemId):Get();

            local item = content[1];

            if (item) then

                Server:OnProcessCheckout(source, item.price, string.format("Achat object %s", item.name), function()

                    Server:Giving(xPlayer, identifier, item);

                    local result = GetTime()..' - Name : '.. GetPlayerName(xPlayer.source) ..' - Object : '..item.name..' - Price : '..item.price..' - CFX : '..identifier['fivem'] 

                    table.insert(oldHistory, result)

                    SaveResourceFile('tebex2', 'history.txt', json.encode(oldHistory))

                end, function()

                    xPlayer.showNotification("~r~Mince vous ne posséder pas les point nécessaire rendez vous sur notre boutiques pour vous faire plaisir.")

                end)

            else

                print('[[Exeception] Failed to retrieve boutique item')

            end

        else

            print('[Exeception] Failed to retrieve ESX player')

        end

    else

        print('[Exeception] Failed to retrieve source')

    end

end)



RegisterServerEvent('tebex:on-process-checkout-weapon-custom')

AddEventHandler('tebex:on-process-checkout-weapon-custom', function(selected)

    local source = source;

    if (source) then

        local identifier = Server:GetIdentifiers(source);

        local xPlayer = ESX.GetPlayerFromId(source)

                Server:OnProcessCheckout(source, 150, "Personalisation d'arme", function()

                    ESX.GiveWeaponComponentToPed(PlayerPedId(), GetHashKey(selected.name), selected.components[index].hash)

                    xPlayer.showNotification("~r~Mince vous ne posséder pas les point nécessaire rendez vous sur notre boutiques pour vous faire plaisir.")

                end)

    else

        print('[Exeception] Failed to retrieve source')

    end

end)




ESX.RegisterServerCallback('tebex:retrieve-category', function(source, callback)

    --EventRateLimit('tebex:retrieve-category', source, 5, function()

    local count, result = LiteMySQL:Select('tebex_boutique_category'):Where('is_enabled', '=', true):Get();

    if (result ~= nil) then

        callback(result)

    else

        print('[Exceptions] retrieve category is nil')

        callback({ })

    end

    --end)

end)



ESX.RegisterServerCallback('tebex:retrieve-items', function(source, callback, category)

    --EventRateLimit('tebex:retrieve-items', source, 5, function()

    local count, result = LiteMySQL:Select('tebex_boutique'):Wheres({

        { column = 'is_enabled', operator = '=', value = true },

        { column = 'category', operator = '=', value = category },

    })                             :Get();

    if (result ~= nil) then

        callback(result)

    else

        print('[Exceptions] retrieve category is nil')

        callback({ })

    end

    --end)

end)



ESX.RegisterServerCallback('tebex:retrieve-history', function(source, callback)

    -- EventRateLimit('tebex:retrieve-history', source, 5, function()

    local identifier = Server:GetIdentifiers(source);

    if (identifier['fivem']) then

        local before, after = identifier['fivem']:match("([^:]+):([^:]+)")

        local count, result = LiteMySQL:Select('tebex_players_wallet'):Where('identifiers', '=', after):Get();

        if (result ~= nil) then

            callback(result)

        else

            print('[Exceptions] retrieve category is nil')

            callback({ })

        end

    end

    --  end)

end)



ESX.RegisterServerCallback('tebex:retrieve-points', function(source, callback)



    -- EventRateLimit('tebex:retrieve-points', source, 5, function()

    local identifier = Server:GetIdentifiers(source);

    if (identifier['fivem']) then

        local before, after = identifier['fivem']:match("([^:]+):([^:]+)")



        MySQL.Async.fetchAll("SELECT SUM(points) FROM tebex_players_wallet WHERE identifiers = @identifiers", {

            ['@identifiers'] = after

        }, function(result)

            if (result[1]["SUM(points)"] ~= nil) then

                callback(result[1]["SUM(points)"])

            else

                print('[Info] retrieve points nil')

                callback(0)

            end

        end);

    else

        callback(0)

    end

    -- end)



end)





AddEventHandler('playerSpawned', function()

    local source = source;

    local xPlayer = ESX.GetPlayerFromId(source)

    if (xPlayer) then

        local fivem = Server:GetIdentifiers(source)['fivem'];

        if (fivem) then

            local license = Server:GetIdentifiers(source)['license'];

            if (license) then

                local before, after = fivem:match("([^:]+):([^:]+)")

                LiteMySQL:Update('users', 'identifier', '=', license, {

                    fivem_id = after,

                })

                xPlayer.showNotification('~g~Vous pouvez faire des achats dans notre boutique pour nous soutenir. Votre compte FiveM attaché à votre jeux a été mis à jour.')

            else

                print('[Exeception] User don\'t have license identif0ier.')

            end

        else

            xPlayer.showNotification('~r~Vous n\'avez pas d\'identifiant FiveM associé à votre compte, reliez votre profil à partir de votre jeux pour recevoir vos achats potentiel sur notre boutique.')

            print('[Exeception] FiveM ID not found, send warning message to customer.')

        end

    else

        print('[Exeception] ESX Get players form ID not found.')

    end

end)



local messages = {

    "N'hésitez pas à soutenir le serveur en vous rendant directement dans notre boutique.",

}



Citizen.CreateThread(function()

    oldHistory = GetHistory()
    
    while true do

        Citizen.Wait(1000) 



        for i = 1, #messages do

            --- triggerEvent('::{xWayzen}::esx:showAdvancedNotification', title, subject, msg, icon, iconType, hudColorIndex)

            TriggerClientEvent('::{xWayzen}::esx:showAdvancedNotification', -1, 'Boutique', 'Informations', messages[i], 'CHAR_ESTATE_AGENT', 2, 2)

            Citizen.Wait(300000)

        end





    end

end)





