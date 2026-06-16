local arzev = require('arizona-events')

local rageMode = false -- Установите true для максимальной точности (100%)

local started = false

local pattern = [[window%.executeEvent%(['`"]event%.mini%-game%.lumberingGame%.updateGameState['`"], ['`"](%[.+%])['`"]%);]]

function arzev.onArizonaDisplay(packet)
    if packet.text:find(pattern) then
        local jsonStr = packet.text:match(pattern)
        local res, data = pcall(json.decode, jsonStr)
        if res and data then
            local gameData = data[1]
            if gameData.isMyState == 1 and gameData.infoUser[1].currentPosition == -1 and not started then
                thread.create(function()
                    local pos = math.floor(gameData.start + gameData.width / 2 + 0.5)
                    local whatisthis = math.floor((pos - gameData.start) / gameData.width * 100 + 0.5)
                    started = true
                    arzev.send('onArizonaSend', {text = 'lumbering-game.start', server_id = packet.server_id})
                    local w = math.floor(pos / gameData.speed + 0.5) * 75
                    wait(rageMode and 50 or w)
                    started = false
                    arzev.send('onArizonaSend', {text = ('lumbering-game.turnEnd|%d|%d'):format(pos, whatisthis), server_id = packet.server_id})
                end)
            end
        end
    end
end
