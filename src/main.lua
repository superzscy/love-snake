local gridSize = 20
local gridWidth = 32
local gridHeight = 24
local hudHeight = 48
local hudPadding = 10

local snake = {}
local direction = "right"
local pendingDirection = "right"
local moveTimer = 0
local moveInterval = 0.5
local speedIncrement = 0.03
local minMoveInterval = 0.08
local gameOver = false
local wallColor = {0.9, 0.32, 0.36}
local foods = {}
local maxFood = 3
local foodRadius = 7
local foodSpawnTries = 200
local foodCount = 0
local startTime = 0

local function resetSnake()
  snake = {
    { x = 8, y = 8 },
    { x = 7, y = 8 },
    { x = 6, y = 8 },
  }
  direction = "right"
  pendingDirection = "right"
  moveTimer = 0
  gameOver = false
  moveInterval = 0.5
  foodCount = 0
  startTime = love.timer.getTime()
end

local function isOpposite(a, b)
  return (a == "left" and b == "right")
    or (a == "right" and b == "left")
    or (a == "up" and b == "down")
    or (a == "down" and b == "up")
end

local function isOnSnake(x, y)
  for i = 1, #snake do
    local s = snake[i]
    if s.x == x and s.y == y then
      return true
    end
  end
  return false
end

local function randomColor()
  return {
    0.35 + love.math.random() * 0.55,
    0.35 + love.math.random() * 0.55,
    0.35 + love.math.random() * 0.55,
  }
end

local function isOnFood(x, y)
  for i = 1, #foods do
    local f = foods[i]
    if f.x == x and f.y == y then
      return true
    end
  end
  return false
end

local function spawnOneFood()
  for _ = 1, foodSpawnTries do
    local x = love.math.random(1, gridWidth)
    local y = love.math.random(1, gridHeight)
    if not isOnSnake(x, y) and not isOnFood(x, y) then
      table.insert(foods, { x = x, y = y, color = randomColor() })
      return true
    end
  end
  return false
end

local function spawnFoods()
  while #foods < maxFood do
    if not spawnOneFood() then
      return
    end
  end
end

local function advanceSnake()
  direction = pendingDirection

  local head = snake[1]
  local nx, ny = head.x, head.y
  if direction == "left" then
    nx = nx - 1
  elseif direction == "right" then
    nx = nx + 1
  elseif direction == "up" then
    ny = ny - 1
  elseif direction == "down" then
    ny = ny + 1
  end

  if nx < 1 or nx > gridWidth or ny < 1 or ny > gridHeight then
    gameOver = true
    return
  end

  table.insert(snake, 1, { x = nx, y = ny })

  local ateIndex = nil
  for i = 1, #foods do
    if nx == foods[i].x and ny == foods[i].y then
      ateIndex = i
      break
    end
  end

  if ateIndex then
    table.remove(foods, ateIndex)
    spawnFoods()
    moveInterval = math.max(minMoveInterval, moveInterval - speedIncrement)
    foodCount = foodCount + 1
  else
    table.remove(snake)
  end
end

function love.load()
  love.window.setTitle("Snake Demo")
  love.window.setMode(gridWidth * gridSize, gridHeight * gridSize + hudHeight)
  love.math.setRandomSeed(os.time())
  resetSnake()
  foods = {}
  spawnFoods()
end

function love.update(dt)
  if gameOver then
    return
  end
  moveTimer = moveTimer + dt
  if moveTimer >= moveInterval then
    moveTimer = moveTimer - moveInterval
    advanceSnake()
  end
end

function love.keypressed(key)
  local nextDir = nil
  if key == "left" or key == "a" then
    nextDir = "left"
  elseif key == "right" or key == "d" then
    nextDir = "right"
  elseif key == "up" or key == "w" then
    nextDir = "up"
  elseif key == "down" or key == "s" then
    nextDir = "down"
  elseif key == "r" then
    resetSnake()
    foods = {}
    spawnFoods()
  end

  if nextDir and not isOpposite(direction, nextDir) then
    pendingDirection = nextDir
  end
end

function love.draw()
  love.graphics.clear(0.08, 0.09, 0.1)
  local fieldOffsetY = hudHeight

  love.graphics.setColor(0.12, 0.13, 0.15)
  love.graphics.rectangle("fill", 0, 0, gridWidth * gridSize, hudHeight)

  love.graphics.setColor(0.16, 0.18, 0.2)
  love.graphics.rectangle(
    "fill",
    0,
    fieldOffsetY,
    gridWidth * gridSize,
    gridHeight * gridSize
  )

  love.graphics.setColor(wallColor)
  love.graphics.setLineWidth(4)
  love.graphics.rectangle(
    "line",
    2,
    fieldOffsetY + 2,
    gridWidth * gridSize - 4,
    gridHeight * gridSize - 4
  )
  love.graphics.setLineWidth(1)

  love.graphics.setColor(0.1, 0.12, 0.14)
  for x = 1, gridWidth do
    love.graphics.line(
      x * gridSize,
      fieldOffsetY,
      x * gridSize,
      fieldOffsetY + gridHeight * gridSize
    )
  end
  for y = 1, gridHeight do
    love.graphics.line(
      0,
      fieldOffsetY + y * gridSize,
      gridWidth * gridSize,
      fieldOffsetY + y * gridSize
    )
  end

  for i = 1, #foods do
    local f = foods[i]
    love.graphics.setColor(f.color)
    love.graphics.circle(
      "fill",
      (f.x - 0.5) * gridSize,
      fieldOffsetY + (f.y - 0.5) * gridSize,
      foodRadius
    )
  end

  for i = 1, #snake do
    local segment = snake[i]
    if i == 1 then
      love.graphics.setColor(0.2, 0.8, 0.4)
    else
      love.graphics.setColor(0.15, 0.6, 0.35)
    end
    love.graphics.rectangle(
      "fill",
      (segment.x - 1) * gridSize + 2,
      fieldOffsetY + (segment.y - 1) * gridSize + 2,
      gridSize - 4,
      gridSize - 4,
      6,
      6
    )
  end

  local elapsed = math.floor(love.timer.getTime() - startTime)
  local speed = 1 / moveInterval
  local speedText = string.format("Speed: %.2f cells/s", speed)

  love.graphics.setColor(0.85, 0.88, 0.92)
  love.graphics.print(
    string.format("Time: %ds  Food: %d  %s", elapsed, foodCount, speedText),
    hudPadding,
    math.floor((hudHeight - 18) / 2)
  )

  love.graphics.setColor(0.8, 0.85, 0.9)
  love.graphics.print("WASD / Arrow keys to move. R to reset.", 10, fieldOffsetY + 10)
  if gameOver then
    love.graphics.setColor(0.95, 0.4, 0.35)
    love.graphics.print("Game Over", 10, fieldOffsetY + 30)
  end
end
