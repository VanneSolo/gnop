--VITESSE DU CANARD
ENTITY_SPEED = 20

--INIT DES ASSETS DU JEU
player_1 = {}               -- le canard qu'on contrôle
bezier_control_point = {}   -- point de contrôle de la trajectoire de la chiasse du canard
bullet = {}                 -- chiasse du canard
explosion = {}              -- explosion de la chiasse du canard si contact avec une voiture
boom = {}                   -- sert à récupérer les coordonnées du clic gauche souris pour tirer
vehicules = {}

--DETECTION DE COLLISION
function Collide(px, py, rx, ry, rw, rh)
  if px > rx and px < rx+rw and py > ry and py < ry+rh then
    return true
  end
  return false
end

--FONCTION DE CREATION DES VOITURES
function Create_Car(x, y, img, img_wheel, wheel_1_off_x, wheel_1_off_y, wheel_2_off_x, wheel_2_off_y, wheel_rotation_speed, car_speed)
  local car = {}
  car.img = love.graphics.newImage(img)
  car.is_alive = true
  car.x = x
  car.y = y
  car.w = car.img:getWidth()
  car.h = car.img:getHeight()
  car.wheel_rotation = 0
  car.wheel_1 = {}
  car.wheel_1.x = car.x+wheel_1_off_x
  car.wheel_1.y = car.y+wheel_1_off_y
  car.wheel_1.r = 0
  car.wheel_1.img = img_wheel
  car.wheel_2 = {}
  car.wheel_2.x = car.x+wheel_2_off_x
  car.wheel_2.y = car.y+wheel_2_off_y
  car.wheel_2.r = 0
  car.wheel_2.img = img_wheel
  ----------------------------------------------------------------------
  car.Update = function(dt)
    car.x = car.x - car_speed
    car.wheel_rotation = car.wheel_rotation - wheel_rotation_speed
    car.wheel_1.r = car.wheel_rotation
    car.wheel_1.x = car.x+wheel_1_off_x
    car.wheel_1.y = car.y+wheel_1_off_y
    car.wheel_2.r = car.wheel_rotation
    car.wheel_2.x = car.x+wheel_2_off_x
    car.wheel_2.y = car.y+wheel_2_off_y
  end
  ----------------------------------------------------------------------
  car.Draw = function()
    love.graphics.draw(car.img, car.x, car.y)
    love.graphics.draw(car.wheel_1.img, car.wheel_1.x, car.wheel_1.y, car.wheel_1.r, 1, 1, car.wheel_1.img:getWidth()/2, car.wheel_1.img:getHeight()/2)
    love.graphics.draw(car.wheel_2.img, car.wheel_2.x, car.wheel_2.y, car.wheel_2.r, 1, 1, car.wheel_2.img:getWidth()/2, car.wheel_2.img:getHeight()/2)
  end
  return car
end

--LOAD
function love.load()
  road = love.graphics.newImage("road.png")
  wheel = love.graphics.newImage("wheel.png")
  
  love.window.setFullscreen(true)
  largeur = love.graphics.getWidth()
  hauteur = love.graphics.getHeight()
  player_is_shooting = false      -- bool qui contrôle si un tir est en cours
  nuke = false                    -- bool qui contrôle si une explosion est en cours
  in_shoot_zone = false           -- bool qui contrôle si le curseur est dans la zone pour tirer
  
  road_offset = 0
  road_offset_2 = largeur
  wheel_spin = 0
  
  green_car = Create_Car(1500, 900, "green_car.png", wheel, 45, 80, 147, 80, 0.2, 5)
  pick_up_truck = Create_Car(1000, 800, "pick_up_truck.png", wheel, 29, 85, 166, 85, 0.1, 2)
  sport_car = Create_Car(1200, 970, "sport_car.png", wheel, 50, 80, 156, 80, 0.5, 15)
  
  vehicules[1] = green_car
  vehicules[2] = pick_up_truck
  vehicules[3] = sport_car
  --print(vehicules, #vehicules, vehicules[1].Update)
  
  explosion.current_image = 1
  explosion.sprites = {}
  for i=1,8 do
    local frame = love.graphics.newImage("nuke_"..i..".png")
    table.insert(explosion.sprites, frame)
  end
  
  souris_x = love.graphics.getWidth()/2
  souris_y = love.graphics.getHeight()/2
  
  player_1.sprites = {}
  for i=1,7 do
    local frame = love.graphics.newImage("canard_"..i..".png")
    table.insert(player_1.sprites, frame)
  end
  player_1.current_image = 1
  player_1.anim_speed = 24
  player_1.w = player_1.sprites[1]:getWidth()
  player_1.h = player_1.sprites[1]:getHeight()
  player_1.x = largeur/2-player_1.w/2
  player_1.y = hauteur/2 - player_1.h/2
  player_1.mid_x = player_1.x + player_1.w/2
  player_1.mid_y = player_1.y + player_1.h/2
  
  time = 0 -- init de la variable qui sert à contrôler la chiasse le long de sa trajectoire
end

--UPDATE
function love.update(dt)
  souris_x, souris_y = love.mouse.getPosition()
  
  road_offset = road_offset - 2
  road_offset_2 = road_offset_2 - 2
  
  for i=1,#vehicules do
    vehicules[i].Update(dt)
    if vehicules[i].x < -vehicules[i].img:getWidth() then
      vehicules[i].x = largeur
    end
  end
  
  if road_offset <= -largeur then
    road_offset = largeur
  end
  if road_offset_2 <= -largeur then
    road_offset_2 = largeur
  end
  
  if love.keyboard.isDown("up") and player_1.y > 150 then
    player_1.y = player_1.y-ENTITY_SPEED
  end
  if love.keyboard.isDown("down") and player_1.y < hauteur/2 then
    player_1.y = player_1.y+ENTITY_SPEED
  end
  if love.keyboard.isDown("right") and player_1.x < 1120 then
    player_1.x = player_1.x+ENTITY_SPEED
  end
  if love.keyboard.isDown("left") and player_1.x > 700 then
    player_1.x = player_1.x-ENTITY_SPEED
  end
  
  player_1.mid_x = player_1.x + player_1.w/2
  player_1.mid_y = player_1.y + player_1.h/2
  
  if player_is_shooting then
    time = time+0.06
    bezier_control_point.x = (boom.x+player_1.mid_x)/2
    bezier_control_point.y = player_1.mid_y
    target_bezier = love.math.newBezierCurve(player_1.mid_x, player_1.mid_y+player_1.h/4, bezier_control_point.x, bezier_control_point.y, boom.x, boom.y)
    if time < 1 then
      bullet.x, bullet.y = target_bezier:evaluate(time)
    end
  end
  if time >= 0.995 then
    for i=1,#vehicules do
      if Collide(boom.x, boom.y, vehicules[i].x, vehicules[i].y, vehicules[i].w, vehicules[i].h) then
        time = 0
        nuke = true
        player_is_shooting = false
        vehicules[i].is_alive = false
      else
        time = 0
        player_is_shooting = false
        in_shoot_zone = false
      end
    end
  end
  
  if nuke then
    explosion.current_image = explosion.current_image + 12*dt
    if explosion.current_image > #explosion.sprites+1 then
      nuke = false
      explosion.current_image = 1
      in_shoot_zone = false
    end
  end
  
  player_1.current_image = player_1.current_image + player_1.anim_speed*dt
  if player_1.current_image <= 1 then
    player_1.current_image = 1
  elseif player_1.current_image > #player_1.sprites+0.9 then
    player_1.current_image = #player_1.sprites+0.9
  end
  if player_1.current_image == 1 or player_1.current_image == #player_1.sprites+0.9 then
    player_1.anim_speed = -player_1.anim_speed
  end
end

--DRAW
function love.draw()
  --route
  love.graphics.draw(road, road_offset, hauteur-road:getHeight())
  love.graphics.draw(road, road_offset_2, hauteur-road:getHeight())
  
  --affichage des véhicules
  for i=1,#vehicules do
    if vehicules[i].is_alive then
      vehicules[i].Draw()
    end
  end
  
  --explosion
  if nuke then
    local id_sprite = math.floor(explosion.current_image)
    love.graphics.draw(explosion.sprites[id_sprite], boom.x-explosion.sprites[1]:getWidth()/2-explosion.sprites[1]:getWidth()/4,
                                                     boom.y-explosion.sprites[1]:getHeight()-explosion.sprites[1]:getHeight()/2+50,
                                                     0, 1.5, 1.5)
  end
  
  if player_is_shooting then
    love.graphics.setColor(1, 1, 0, 1)
    love.graphics.circle("fill", bullet.x, bullet.y, 10)
    love.graphics.setColor(1, 1, 1, 1)
  end
  
  local canard_sprite = math.floor(player_1.current_image)
  love.graphics.draw(player_1.sprites[canard_sprite], player_1.x, player_1.y)
  
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print("nuke: "..tostring(nuke), 5, 5)
  love.graphics.print("in shoot zone: "..tostring(in_shoot_zone), 5, 5+16)
end

--KEYPRESSED
function love.keypressed(key)
  if key == "escape" then
    love.event.quit()
  end
end

--MOUSEPRESSED
function love.mousepressed(x, y, button)
  if button == 1 and player_is_shooting == false and nuke == false then
    if x < player_1.x-100 and y > hauteur-road:getHeight() then
      in_shoot_zone = true
    end
    if in_shoot_zone then
      player_is_shooting = true
      boom.x = x
      boom.y = y
    end
  end
end