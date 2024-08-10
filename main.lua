--[[
This project was based on CS50's playlist:
https://www.youtube.com/playlist?list=PLhQjrBD2T382mHvZB-hSYWvoLzYQzT_Pb

I made the AI myself
]]
Class = require 'class'
push = require 'push'
require 'Ball'
require 'Paddle'

WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

PADDLE_SPPED = 150

--[[
    Runs when the game first starts up, only once; used to initialize the game.
]]
function love.load()
    math.randomseed(os.time())
    love.window.setTitle('Pong')
    love.graphics.setDefaultFilter('nearest', 'nearest')
    smallFont = love.graphics.newFont('font.ttf', 8)
    scoreFont = love.graphics.newFont('font.ttf', 32)
    victoryFont = love.graphics.newFont('font.ttf', 24)

    sounds = {
        ['paddle_hit'] = love.audio.newSource('paddle_hit.wav', 'static'),
        ['point_scored'] = love.audio.newSource('pong_lose.wav', 'static'),
        ['wall_hit'] = love.audio.newSource('pong_wall_hit.wav', 'static')
    }

    player1Score = 0
    player2Score = 0
    servingPlayer = math.random(2) == 1 and 1 or 2
    winPlayer = 0
    ai_play = false

    paddle1 = Paddle(5, 20, 5, 20)
    paddle2 = Paddle(VIRTUAL_WIDTH - 10, VIRTUAL_HEIGHT - 30, 5, 20)
    ball = Ball(VIRTUAL_WIDTH / 2 - 2, VIRTUAL_HEIGHT / 2 - 2, 4, 4)
    gameState = 'start'

    -- Sets initial ball velocity
    if servingPlayer == 1 then
        ball.dx = -100
    else
        ball.dx = 100
    end

    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = true,
        vsync = true
    })
end

function love.resize(w, h)
    push:resize(w, h)
end

function love.update(dt)
    -- ball paddle collision
    if ball:collides(paddle1) then
        -- deflect ball to the right
        ball.dx = -ball.dx
        sounds['paddle_hit']:play()
    end
    if ball:collides(paddle2) then
        -- deflect ball to left
        ball.dx = -ball.dx
        sounds['paddle_hit']:play()
    end

    -- ball hit top / bottom edge of screen
    if ball.y <= 0 then
        -- deflect ball down
        ball.dy = -ball.dy
        ball.y = 0
        sounds['wall_hit']:play()
    end
    if ball.y >= VIRTUAL_HEIGHT - 4 then
        ball.dy = -ball.dy
        ball.y = VIRTUAL_HEIGHT - 4
        sounds['wall_hit']:play()
    end

    -- Left paddle movement
    if love.keyboard.isDown('w') then
        paddle1.dy = -PADDLE_SPPED
    elseif love.keyboard.isDown('s') then
        paddle1.dy = PADDLE_SPPED
    else
        paddle1.dy = 0
    end

    -- Right paddle movement
    if not ai_play then
        if love.keyboard.isDown('up') then
            paddle2.dy = -PADDLE_SPPED
        elseif love.keyboard.isDown('down') then
            paddle2.dy = PADDLE_SPPED
        else
            paddle2.dy = 0
        end
    else
        update_ai()
    end

    if gameState == 'play' then
        ball:update(dt)

        if ball.x <= 0 then
            player2Score = player2Score + 1
            ball:reset()
            ball.dx = -100
            servingPlayer = 1
            sounds['point_scored']:play()

            if player2Score >= 10 then
                gameState = 'victory'
                winPlayer = 2
                ai_play = false
            else
                gameState = 'serve'
            end
        elseif ball.x >= VIRTUAL_WIDTH - 4 then
            player1Score = player1Score + 1
            ball:reset()
            ball.dx = 100
            servingPlayer = 2
            sounds['point_scored']:play()

            if player1Score >= 10 then
                gameState = 'victory'
                winPlayer = 1
                ai_play = false
            else
                gameState = 'serve'
            end
        end
    end

    paddle1:update(dt)
    paddle2:update(dt)
end

function update_ai()
    if ball.y + ball.height / 2 > paddle2.y + 9 * paddle2.height / 10 and ball.dx > 0 and ball.x > VIRTUAL_WIDTH / 2 then -- ball below paddle
        dist = ball.y - paddle2.y - paddle2.height / 2

        if 1000 < PADDLE_SPPED then
            paddle2.dy = dist
        else
            paddle2.dy = PADDLE_SPPED
        end
    elseif ball.y + ball.height / 2 < paddle2.y + paddle2.height / 10 and ball.dx > 0  and ball.x > VIRTUAL_WIDTH / 2 then -- ball above paddle
        dist = paddle2.y + paddle2.height / 2 - ball.y - ball.height / 2

        if 1000 < PADDLE_SPPED then
            paddle2.dy = -dist
        else
            paddle2.dy = -PADDLE_SPPED
        end
    else
        paddle2.dy = 0
    end
end

function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
    elseif key == 'enter' or key == 'return' then
        if gameState == 'start' then
            gameState = 'serve'
        elseif gameState == 'serve' then
            gameState = 'play'
        elseif gameState == 'victory' then
            gameState = 'start'
            player1Score = 0
            player2Score = 0
        end
    elseif key == 'space' and not ai_play then
        if gameState == 'start'then
            gameState = 'serve'
            ai_play = true
        end
    end
end

--[[
    Called after update by LÖVE2D, used to draw anything to the screen, updated or otherwise.
]]
function love.draw()
    push:apply('start')

    love.graphics.clear(40 / 255, 45 / 255, 52 / 255, 255 / 255) -- Sets background colour

    love.graphics.setFont(smallFont)

    if gameState == 'start' then
        love.graphics.printf("Welcome to Pong!", 0, 20, VIRTUAL_WIDTH, "center")
        love.graphics.printf("Press Enter For Two People to Play!", 0, 32, VIRTUAL_WIDTH, "center")
        love.graphics.printf("Press Space to Play Against an AI!", 0, 44, VIRTUAL_WIDTH, "center")
    elseif gameState == 'serve' then
        love.graphics.printf("Player " .. tostring(servingPlayer) .. "'s turn!", 0, 20, VIRTUAL_WIDTH, "center")
        love.graphics.printf("Press Enter to Serve!", 0, 32, VIRTUAL_WIDTH, "center")
    elseif gameState == 'victory' then
        love.graphics.setFont(victoryFont)
        love.graphics.printf("Player " .. tostring(winPlayer) .. " Wins!", 0, 10, VIRTUAL_WIDTH, "center")
        love.graphics.setFont(smallFont)
        love.graphics.printf("Press Enter to Restart!", 0, 42, VIRTUAL_WIDTH, "center")
    end
   
    -- Draw ball and paddles
    ball:render()
    paddle1:render()
    paddle2:render()

    displayFPS()
    displayScore()

    push:apply('end')
end

function displayFPS()
    love.graphics.setColor(0, 1, 0, 1)
    love.graphics.setFont(smallFont)
    love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 40, 20)
    love.graphics.setColor(1, 1, 1, 1)
end

function displayScore()
    love.graphics.setFont(scoreFont)
    love.graphics.print(player1Score, VIRTUAL_WIDTH /2 - 50, VIRTUAL_HEIGHT / 3)
    love.graphics.print(player2Score, VIRTUAL_WIDTH /2 + 30, VIRTUAL_HEIGHT / 3)
end
