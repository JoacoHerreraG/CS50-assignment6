Level = Class{}

function Level:init()
    self.world = love.physics.newWorld(0, 300)

    self.destroyedBodies = {}

    self.collisionOccured = false
    self.alienSplit = false

    function beginContact(a, b, coll)
        local types = {}
        types[a:getUserData()] = true
        types[b:getUserData()] = true

        -- if we collided between both an alien and an obstacle...
        if types['Obstacle'] and types['Player'] then

            -- destroy the obstacle if player's combined velocity is high enough
            if a:getUserData() == 'Obstacle' then
                local velX, velY = b:getBody():getLinearVelocity()
                local sumVel = math.abs(velX) + math.abs(velY)

                if sumVel > 20 then
                    table.insert(self.destroyedBodies, a:getBody())
                end
            else
                local velX, velY = a:getBody():getLinearVelocity()
                local sumVel = math.abs(velX) + math.abs(velY)

                if sumVel > 20 then
                    table.insert(self.destroyedBodies, b:getBody())
                end
            end
        end

        -- if we collided between an obstacle and an alien, as by debris falling...
        if types['Obstacle'] and types['Alien'] then

            -- destroy the alien if falling debris is falling fast enough
            if a:getUserData() == 'Obstacle' then
                local velX, velY = a:getBody():getLinearVelocity()
                local sumVel = math.abs(velX) + math.abs(velY)

                if sumVel > 20 then
                    table.insert(self.destroyedBodies, b:getBody())
                end
            else
                local velX, velY = b:getBody():getLinearVelocity()
                local sumVel = math.abs(velX) + math.abs(velY)

                if sumVel > 20 then
                    table.insert(self.destroyedBodies, a:getBody())
                end
            end
        end

        -- if we collided between the player and the alien...
        if types['Player'] and types['Alien'] then

            -- destroy the alien if player is traveling fast enough
            if a:getUserData() == 'Player' then
                local velX, velY = a:getBody():getLinearVelocity()
                local sumVel = math.abs(velX) + math.abs(velY)
                
                if sumVel > 20 then
                    table.insert(self.destroyedBodies, b:getBody())
                end
            else
                local velX, velY = b:getBody():getLinearVelocity()
                local sumVel = math.abs(velX) + math.abs(velY)

                if sumVel > 20 then
                    table.insert(self.destroyedBodies, a:getBody())
                end
            end
        end

        -- if we hit the ground, play a bounce sound
        if types['Player'] and types['Ground'] then
            gSounds['bounce']:stop()
            gSounds['bounce']:play()
        end
    end

    function endContact(a, b, coll)
        self.collisionOccured = true
    end

    self.world:setCallbacks(beginContact, endContact, preSolve, postSolve)

    self.launchMarker = {AlienLaunchMarker(self.world)}

    self.aliens = {}

    self.obstacles = {}

    self.edgeShape = love.physics.newEdgeShape(0, 0, VIRTUAL_WIDTH * 3, 0)

    table.insert(self.aliens, Alien(self.world, 'square', VIRTUAL_WIDTH - 80, VIRTUAL_HEIGHT - TILE_SIZE - ALIEN_SIZE / 2, 'Alien'))

    table.insert(self.obstacles, Obstacle(self.world, 'vertical',
        VIRTUAL_WIDTH - 120, VIRTUAL_HEIGHT - 35 - 110 / 2))
    table.insert(self.obstacles, Obstacle(self.world, 'vertical',
        VIRTUAL_WIDTH - 35, VIRTUAL_HEIGHT - 35 - 110 / 2))
    table.insert(self.obstacles, Obstacle(self.world, 'horizontal',
        VIRTUAL_WIDTH - 80, VIRTUAL_HEIGHT - 35 - 110 - 35 / 2))

    self.groundBody = love.physics.newBody(self.world, -VIRTUAL_WIDTH, VIRTUAL_HEIGHT - 35, 'static')
    self.groundFixture = love.physics.newFixture(self.groundBody, self.edgeShape)
    self.groundFixture:setFriction(0.5)
    self.groundFixture:setUserData('Ground')

    self.background = Background()
end

function Level:update(dt)
    for i, player in pairs(self.launchMarker) do
        player:update(dt)
    end

    self.world:update(dt)

    for k, body in pairs(self.destroyedBodies) do
        if not body:isDestroyed() then 
            body:destroy()
        end
    end

    self.destroyedBodies = {}

    for i = #self.obstacles, 1, -1 do
        if self.obstacles[i].body:isDestroyed() then
            table.remove(self.obstacles, i)

            local soundNum = math.random(5)
            gSounds['break' .. tostring(soundNum)]:stop()
            gSounds['break' .. tostring(soundNum)]:play()
        end
    end

    for i = #self.aliens, 1, -1 do
        if self.aliens[i].body:isDestroyed() then
            table.remove(self.aliens, i)
            gSounds['kill']:stop()
            gSounds['kill']:play()
        end
    end

    for i, player in pairs(self.launchMarker) do
        if player.launched then
            local xPos, yPos = player.alien.body:getPosition()
            local xVel, yVel = player.alien.body:getLinearVelocity()
            
            if xPos < 0 or (math.abs(xVel) + math.abs(yVel) < 2) then
                player.alien.body:destroy()
                table.remove(self.launchMarker, i)
                if #self.launchMarker == 0 then 
                    self.launchMarker = {AlienLaunchMarker(self.world)}
                    self.collisionOccured = false
                    self.alienSplit = false
                end

                if #self.aliens == 0 then
                    gStateMachine:change('start')
                end
            end
        end
    end

    if love.keyboard.wasPressed('space') and not self.collisionOccured and not self.alienSplit then
        if self.launchMarker[1].launched then 
            self.alienSplit = true
            local xPos, yPos = self.launchMarker[1].alien.body:getPosition()
            local xVel, yVel = self.launchMarker[1].alien.body:getLinearVelocity()
            table.insert(self.launchMarker, AlienLaunchMarker(self.world))
            self.launchMarker[2].launched = true
            self.launchMarker[2].alien = Alien(self.world, 'round', xPos, yPos + 35, 'Player')
            self.launchMarker[2].alien.body:setLinearVelocity(xVel-30, yVel+30)

            table.insert(self.launchMarker, AlienLaunchMarker(self.world))
            self.launchMarker[3].launched = true
            self.launchMarker[3].alien = Alien(self.world, 'round', xPos, yPos - 35, 'Player')
            self.launchMarker[3].alien.body:setLinearVelocity(xVel+30, yVel-30)
        end
    end

end

function Level:render()
    for x = -VIRTUAL_WIDTH, VIRTUAL_WIDTH * 2, 35 do
        love.graphics.draw(gTextures['tiles'], gFrames['tiles'][12], x, VIRTUAL_HEIGHT - 35)
    end

    for i, player in pairs(self.launchMarker) do
        player:render()
    end

    for k, alien in pairs(self.aliens) do
        alien:render()
    end

    for k, obstacle in pairs(self.obstacles) do
        obstacle:render()
    end

    for i, player in pairs(self.launchMarker) do
        if not player.launched then
            love.graphics.setFont(gFonts['medium'])
            love.graphics.setColor(0, 0, 0, 255)
            love.graphics.printf('Click and drag circular alien to shoot!',
                0, 64, VIRTUAL_WIDTH, 'center')
            love.graphics.setColor(255, 255, 255, 255)
        end
    end

    if #self.aliens == 0 then
        love.graphics.setFont(gFonts['huge'])
        love.graphics.setColor(0, 0, 0, 255)
        love.graphics.printf('VICTORY', 0, VIRTUAL_HEIGHT / 2 - 32, VIRTUAL_WIDTH, 'center')
        love.graphics.setColor(255, 255, 255, 255)
    end
end