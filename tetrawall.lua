-- title:  Tetrawall
-- author: Lowcase
-- desc:   Submission to https://itch.io/jam/olc-codejam-2019
-- script: lua
-- input:  mouse

function rand_v_dir()
    vx = math.random()
    vy = math.random()

    norm = math.sqrt(vx * vx + vy * vy)
    vx = vx / norm
    vy = vy / norm

    if math.random(0, 1) == 0 then
        vx = -vx
    end

    if math.random(0, 1) == 0 then
        vy = -vy
    end

    return vx, vy
end

function createBall(map, score)
    local velocityx, velocityy = rand_v_dir()

    return {
        x = math.random(180,230),
        y = math.random(10,126),
        speed = 1,
        velx = velocityx,
        vely = velocityy,
        update = function(self)
            self.x = self.x + (self.velx * self.speed)
            self.y = self.y + (self.vely * self.speed)

            if self.x <= 3 then self.velx = -self.velx end
            if self.y <= 3 then self.vely = -self.vely end
            if self.x >= 240 - 3 then self.velx = -self.velx end
            if self.y >= 136 - 3 then self.vely = -self.vely end

            if map[self.x // 8][self.y // 8] then
                score:add()
                map[self.x // 8][self.y // 8] = false
                if self.x - (self.velx * self.speed) <= (self.x // 8) * 8 then self.velx = -self.velx end
                if self.y - (self.vely * self.speed) <= (self.y // 8) * 8 then self.vely = -self.vely end
                if self.x - (self.velx * self.speed) >= ((self.x // 8) + 1) * 8 then self.velx = -self.velx end
                if self.y - (self.vely * self.speed) >= ((self.y // 8) + 1) * 8 then self.vely = -self.vely end
            end
        end,
        draw = function(self)
            circ(self.x, self.y, 2, 14)
        end
    }
end

function createTarget(balls, score) -- I am not sure if this is passed by reference or value
    local radius = 5
    local startTime = time()
    local ready = true
    return {
        x = math.random(20,50),
        y = math.random(20,116),
        isReady = function(self)
            return radius == 5
        end,
        start = function(self)
            radius = 0
            startTime = time()
        end,
        update = function(self)
            if radius < 5 then
                radius = math.floor(((time()-startTime)/300)%6)
            end
            for _,ball in pairs(balls) do
                -- TODO: Calculate distance properly and like these circular things are squares
                if ball.x > (self.x-6) and ball.y > (self.y-6) and ball.x < (self.x+6) and ball.y < (self.y+6) then
                    currentScene = createGameOverScene(score:getScore())
                end
            end
        end,
        draw = function(self)
            circb(self.x, self.y, 5, 14)
            circ(self.x, self.y, radius, 14)
        end
    }
end

function createUser(map, tetrisShapes, target)
    local drawSquare = function(sprite, x, y)
        if x > 29 or x < 0 or y > 16 or y < 0 then return end
        if map[x][y] then
            spr(sprite - 1, x * 8, y * 8)
        else
            spr(sprite, x * 8, y * 8)
        end
    end

    local isSquareBlocked = function(x, y)
        return x > 29 or x < 0 or y > 16 or y < 0 or map[x][y]
    end

    local currentShape = 3;

    return {
        x = 0,
        y = 0,
        rotation = 0,
        out = true,
        prevRight = true,
        prevLeft = true,
        free = true,
        update = function(self)
            local x, y, left, middle, right = mouse()
            self.out = (x > 240) or (y > 136)
            if self.out or not target:isReady() then return end

            self.x = (x // 8)
            self.y = (y // 8)
            self.free = true

            for _, square in pairs(tetrisShapes[currentShape]) do
                if self.rotation == 0 then
                    self.free = self.free and not isSquareBlocked(self.x + square.x, self.y + square.y)
                elseif self.rotation == 1 then
                    self.free = self.free and not isSquareBlocked(self.x - square.y, self.y + square.x)
                elseif self.rotation == 2 then
                    self.free = self.free and not isSquareBlocked(self.x - square.x, self.y - square.y)
                elseif self.rotation == 3 then
                    self.free = self.free and not isSquareBlocked(self.x + square.y, self.y - square.x)
                end
            end

            if left and self.free then
                if not self.prevLeft then
                    self.prevLeft = true
                    target:start()
                    for _, square in pairs(tetrisShapes[currentShape]) do
                        if self.rotation == 0 then
                            map[(self.x + square.x)][(self.y + square.y)] = true
                        elseif self.rotation == 1 then
                            map[(self.x - square.y)][(self.y + square.x)] = true
                        elseif self.rotation == 2 then
                            map[(self.x - square.x)][(self.y - square.y)] = true
                        elseif self.rotation == 3 then
                            map[(self.x + square.y)][(self.y - square.x)] = true
                        end
                    end
                    currentShape = math.random(0, #tetrisShapes)
                end
            else
                self.prevLeft = false
            end

            if right then
                if not self.prevRight then
                    self.prevRight = true
                    self.rotation = (self.rotation + 1) % 4;
                end
            else
                self.prevRight = false
            end
        end,
        draw = function(self)
            if self.out or not target:isReady() then return end
            local index = 1
            if not self.free then index = index + 16 end
            for _, square in pairs(tetrisShapes[currentShape]) do
                if self.rotation == 0 then
                    drawSquare(index, self.x + square.x, self.y + square.y)
                elseif self.rotation == 1 then
                    drawSquare(index, self.x - square.y, self.y + square.x)
                elseif self.rotation == 2 then
                    drawSquare(index, self.x - square.x, self.y - square.y)
                elseif self.rotation == 3 then
                    drawSquare(index, self.x + square.y, self.y - square.x)
                end
            end
        end
    }
end

function createScore()
    local score = 0
    return {
        getScore = function()
            return score
        end,
        add = function()
            score = score + 1
        end,
        update = function()
        end,
        draw = function()
            print("Score: " .. score, 0, 0, 15)
        end
    }
end

function createGameScene()
    local tetrisShapes = {}
    tetrisShapes[0] = {{x = 0, y = 0}, {x = 1, y = 0}, {x = 2, y = 0}, {x = 1, y = 1}}
    tetrisShapes[1] = {{x = 0, y = 0}, {x = 1, y = 0}, {x = 0, y = 1}, {x = 1, y = 1}}
    tetrisShapes[2] = {{x = -1, y = 0}, {x = 0, y = 0}, {x = 1, y = 0}, {x = 2, y = 0}}
    tetrisShapes[3] = {{x = -1, y = 0}, {x = 0, y = 0}, {x = 0, y = 1}, {x = 1, y = 1}}

    local map = {}

    for i=0,29 do
        map[i] = {}
        for j=0,16 do
        map[i][j] = false
        end
    end

    local score = createScore()
    local balls = {createBall(map, score), createBall(map, score)}
    local target = createTarget(balls, score)
    local user = createUser(map, tetrisShapes, target)

    return {
        update = function()
            user:update()
            for _,b in pairs(balls)   do b:update() end
            target:update()
            score:update()
        end,
        draw = function()
            for i=0,29 do
                for j=0,16 do
                    if map[i][j] then spr(0, i * 8, j * 8) end
                end
            end

            user:draw()

            for _,b in pairs(balls)   do b:draw() end
            target:draw()
            score:draw()
        end
    }
end

function createGameOverScene(score)
    local prevLeft = true
    local prevRight = true
    local goToGameScene = function()
        currentScene = createGameScene()
    end
    return {
        update = function()
            if btnp() ~= 0 then goToGameScene() end
            local x, y, left, middle, right = mouse()
            if left then
                if not prevLeft then
                    prevLeft = true
                    goToGameScene()
                end
            else
                prevLeft = false
            end
            if right then
                if not prevRight then
                    prevRight = true
                    goToGameScene()
                end
            else
                prevRight = false
            end
        end,
        draw = function()
            print("Your score: " .. score, 10, 10, 15)
            print("Game Over", 10, 40, 15, false, 4)
            print("click to restart", 140, 120, 15)
        end
    }
end

function createTitleScene()
    local prevLeft = true
    local prevRight = true
    local goToGameScene = function()
        currentScene = createGameScene()
    end
    return {
        update = function()
            if btnp() ~= 0 then goToGameScene() end
            local x, y, left, middle, right = mouse()
            if left then
                if not prevLeft then
                    prevLeft = true
                    goToGameScene()
                end
            else
                prevLeft = false
            end
            if right then
                if not prevRight then
                    prevRight = true
                    goToGameScene()
                end
            else
                prevRight = false
            end
        end,
        draw = function()
            print("Tetrawall", 10, 10, 15, false, 4)
            print("Prevent the destruction of the core", 10, 40, 15)
            print("(the big yellow circle)", 90, 50, 15)
            print("Left mouse click   - place the wall", 10, 70, 15)
            print("Right mouse click  - rotate the wall", 10, 80, 15)
            print("click to start", 140, 120, 15)
        end
    }
end

currentScene = createTitleScene()

function TIC()
    cls(2)
    currentScene:update()
    currentScene:draw()

    --show coordinates
    --c=string.format('(%f,%f) %i',velx,vely,math.floor((time()/1000)%5))
    --print(c,0,0,15)
end
