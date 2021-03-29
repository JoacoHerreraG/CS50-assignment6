AlienLaunchMarker = Class{}

function AlienLaunchMarker:init(world)
    self.world = world

    self.baseX = 90
    self.baseY = VIRTUAL_HEIGHT - 100

    self.shiftedX = self.baseX
    self.shiftedY = self.baseY

    self.rotation = 0

    self.aiming = false

    self.launched = false

    self.alien = nil
end

function AlienLaunchMarker:update(dt)
    
    if not self.launched then

        local x, y = push:toGame(love.mouse.getPosition())
        
        if love.mouse.wasPressed(1) and not self.launched then
            self.aiming = true

        elseif love.mouse.wasReleased(1) and self.aiming then
            self.launched = true

            self.alien = Alien(self.world, 'round', self.shiftedX, self.shiftedY, 'Player')

            self.alien.body:setLinearVelocity((self.baseX - self.shiftedX) * 10, (self.baseY - self.shiftedY) * 10)

            self.alien.fixture:setRestitution(0.4)
            self.alien.body:setAngularDamping(1)

            self.aiming = false

        elseif self.aiming then
            self.rotation = self.baseY - self.shiftedY * 0.9
            self.shiftedX = math.min(self.baseX + 30, math.max(x, self.baseX - 30))
            self.shiftedY = math.min(self.baseY + 30, math.max(y, self.baseY - 30))
        end
    end
end

function AlienLaunchMarker:render()
    if not self.launched then
        
        love.graphics.draw(gTextures['aliens'], gFrames['aliens'][9], 
            self.shiftedX - 17.5, self.shiftedY - 17.5)

        if self.aiming then
            
            local impulseX = (self.baseX - self.shiftedX) * 10
            local impulseY = (self.baseY - self.shiftedY) * 10

            local trajX, trajY = self.shiftedX, self.shiftedY
            local gravX, gravY = self.world:getGravity()

            for i = 1, 90 do
                
                love.graphics.setColor(255, 80, 255, (255 / 12) * i)
                
                trajX = self.shiftedX + i * 1/60 * impulseX
                trajY = self.shiftedY + i * 1/60 * impulseY + 0.5 * (i * i + i) * gravY * 1/60 * 1/60

                if i % 5 == 0 then
                    love.graphics.circle('fill', trajX, trajY, 3)
                end
            end
        end
        
        love.graphics.setColor(255, 255, 255, 255)
    else
        self.alien:render()
    end
end