-- title:  Tetrawall
-- author: Lowcase
-- desc:   Submission to https://itch.io/jam/olc-codejam-2019
-- script: lua
-- input:  mouse

maxX = 29
maxY = 15
maxXpix = (maxX + 1) * 8
maxYpix = (maxY + 1) * 8

function createTetrisShapes()
    local s = {}
    -- XXX
    --  X
    s[0] = {{x = 0, y = 0}, {x = 1, y = 0}, {x = 2, y = 0}, {x = 1, y = 1}}
    -- XX
    -- XX
    s[1] = {{x = 0, y = 0}, {x = 1, y = 0}, {x = 0, y = 1}, {x = 1, y = 1}}
    -- XXXX
    s[2] = {{x = -1, y = 0}, {x = 0, y = 0}, {x = 1, y = 0}, {x = 2, y = 0}}
    -- XX
    --  XX
    s[3] = {{x = -1, y = 0}, {x = 0, y = 0}, {x = 0, y = 1}, {x = 1, y = 1}}
    --  XX
    -- XX
    s[4] = {{x = -1, y = 0}, {x = 0, y = 0}, {x = 0, y = -1}, {x = 1, y = -1}}
    -- XXX
    --   X
    s[5] = {{x = -1, y = 0}, {x = 0, y = 0}, {x = 1, y = 0}, {x = 1, y = 1}}
    --   X
    -- XXX
    s[6] = {{x = -1, y = 0}, {x = 0, y = 0}, {x = 1, y = 0}, {x = 1, y = -1}}

    return s
end

tetrisShapes = createTetrisShapes()

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
        x = math.random((maxXpix / 4) * 3, maxXpix - 10),
        y = math.random(10, maxYpix - 10),
        speed = 1,
        velx = velocityx,
        vely = velocityy,
        update = function(self)
            self.x = self.x + (self.velx * self.speed)
            self.y = self.y + (self.vely * self.speed)

            if self.x <= 3 then self.velx = -self.velx end
            if self.y <= 3 then self.vely = -self.vely end
            if self.x >= maxXpix - 3 then self.velx = -self.velx end
            if self.y >= maxYpix - 3 then self.vely = -self.vely end

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
            spr(2, self.x-5, self.y-5, 0)
        end
    }
end

function createTarget(balls, map, score)
    local wallProgress = 80
    local wallTime = time()
    local ballProgress = 80
    local ballTime = time()
    local ready = true
    return {
        x = math.random(20, maxXpix / 4),
        y = math.random(20, maxYpix - 20),
        isReady = function(self)
            return wallProgress == 80
        end,
        start = function(self)
            wallProgress = 0
            wallTime = time()
        end,
        update = function(self)
            if ballProgress < 80 then
                ballProgress = math.min(math.floor(((time()-ballTime)/100)), 80)
            else
                ballProgress = 0
                ballTime = time()
                balls[#balls + 1] = createBall(map, score)
            end
            if wallProgress < 80 then
                wallProgress = math.min(math.floor(((time()-wallTime)/15)), 80)
            end
            for _,ball in pairs(balls) do
                -- TODO: Calculate distance properly and like these circular things are squares
                if ball.x > (self.x-6) and ball.y > (self.y-6) and ball.x < (self.x+6) and ball.y < (self.y+6) then
                    currentScene = createGameOverScene(score:getScore())
                end
            end
        end,
        draw = function(self)
            local i = 96 + (2 * (math.floor(time()/100) % 8))
            spr(i, self.x-7, self.y-7, 0, 1, 0, 0, 2, 2)

            rect(0, maxYpix, wallProgress, 8, 9)
            rectb(0, maxYpix, 80, 8, 3)
            print("NEXT WALL", 2, maxYpix + 1)

            rect(80, maxYpix, ballProgress, 8, 6)
            rectb(80, maxYpix, 80, 8, 3)
            print("NEXT BALL", 82, maxYpix + 1)
        end
    }
end

function createUser(map, tetrisShapes, target)
    local drawSquare = function(sprite, x, y)
        if x > maxX or x < 0 or y > maxY or y < 0 then return end
        if map[x][y] then
            spr(sprite - 1, x * 8, y * 8)
        else
            spr(sprite, x * 8, y * 8)
        end
    end

    local isSquareBlocked = function(x, y)
        return x > maxX or x < 0 or y > maxY or y < 0 or map[x][y]
    end

    local currentShape = 3;
    local canDraw = target:isReady()

    return {
        x = 0,
        y = 0,
        rotation = 0,
        out = true,
        prevRight = true,
        prevLeft = true,
        free = true,
        update = function(self)
            canDraw = target:isReady()
            local x, y, left, middle, right = mouse()
            self.out = (x > maxXpix) or (y > maxYpix)
            if self.out or not canDraw then return end

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
                    canDraw = false
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
            if self.out or not canDraw then return end
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

function createScore(balls)
    local score = 0
    return {
        getScore = function()
            return score
        end,
        add = function()
            score = score + #balls
        end,
        update = function()
        end,
        draw = function()
            local str = "Score: " .. score
            local w = print(str, 0, -20)
            print(str, maxXpix - w, maxYpix + 1)
        end
    }
end

function createGameScene()
    local map = {}

    for i=0,maxX do
        map[i] = {}
        for j=0,maxY do
        map[i][j] = false
        end
    end

    local balls = {}
    local score = createScore(balls)
    local target = createTarget(balls, map, score)
    local user = createUser(map, tetrisShapes, target)

    return {
        update = function()
            user:update()
            for _,b in pairs(balls)   do b:update() end
            target:update()
            score:update()
        end,
        draw = function()
            cls(0)
            rect(0, 0, maxXpix, maxYpix, 2)

            for i=0,maxX do
                for j=0,maxY do
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
            cls(2)
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
            cls(2)
            print("Tetrawall", 10, 10, 15, false, 4)
            print("Prevent the destruction of the atom", 10, 40, 15)
            print("destruction", 78, 40, 5)
            print("atom", 183, 40, 9)
            print("Left mouse click   - place the wall", 10, 70, 7)
            print("Right mouse click  - rotate the wall", 10, 80, 7)
            print("click to start", 140, 120, 15)
        end
    }
end

currentScene = createTitleScene()

function TIC()
    cls(0)
    currentScene:update()
    currentScene:draw()

    --show coordinates
    --c=string.format('(%f,%f) %i',velx,vely,math.floor((time()/1000)%5))
    --print(c,0,0,15)
end
