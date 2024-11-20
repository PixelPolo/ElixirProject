// Canvas settings
let canvas = document.querySelector("canvas");
let canvasCtx = canvas.getContext("2d");
const TILE = 15;
const COLS = 16;
const ROWS = 14;
const WIDTH = TILE * COLS;
const HEIGHT = TILE * ROWS;
canvas.width = WIDTH;
canvas.height = HEIGHT;

// Game settings
let speed = 275;
let dx = 0;
let dy = 0;
let gameOver = true;

// Snake and food settings
let isEating = false;
let headColor = "white";
let snake;
let foodColor = "rgb(105, 241, 47)";
let food;

// Start button
let resetBtn = document.querySelector(".start");
resetBtn.addEventListener("click", reset);

function reset() {
  gameOver = false;
  snake = [{ x: randomX(), y: randomY() }];
  dx = TILE;
  dy = 0;
  food = undefined;
  resetBtn.blur();
}

// Controls buttons
let upBtn = document.querySelector(".up");
let leftBtn = document.querySelector(".left");
let rightBtn = document.querySelector(".right");
let downBtn = document.querySelector(".down");
let controlsButton = [upBtn, leftBtn, rightBtn, downBtn];

// Controls buttons moves
upBtn.addEventListener("click", () => {
  if (dy !== TILE) dy = -TILE;
  dx = 0;
});
leftBtn.addEventListener("click", () => {
  if (dx !== TILE) dx = -TILE;
  dy = 0;
});
rightBtn.addEventListener("click", () => {
  if (dx !== -TILE) dx = TILE;
  dy = 0;
});
downBtn.addEventListener("click", () => {
  if (dy !== -TILE) dy = TILE;
  dx = 0;
});

// Keyboard controls
document.addEventListener("keydown", (e) => {
  if ((e.key === "ArrowLeft" || e.key === "a") && dx !== TILE) {
    dx = -TILE;
    dy = 0;
  } else if ((e.key === "ArrowRight" || e.key === "d") && dx !== -TILE) {
    dx = TILE;
    dy = 0;
  } else if ((e.key === "ArrowUp" || e.key === "w") && dy !== TILE) {
    dy = -TILE;
    dx = 0;
  } else if ((e.key === "ArrowDown" || e.key === "s") && dy !== -TILE) {
    dy = TILE;
    dx = 0;
  }
});

// Swipe possibilities :
let touchStartX;
let touchStartY;
let touchEndX;
let touchEndY;
document.addEventListener("touchstart", function (event) {
  touchStartX = event.touches[0].clientX;
  touchStartY = event.touches[0].clientY;
});
document.addEventListener("touchmove", function (event) {
  touchEndX = event.changedTouches[0].clientX;
  touchEndY = event.changedTouches[0].clientY;
});
function getSwipeDirection(startX, startY, endX, endY) {
  let deltaX = endX - startX;
  let deltaY = endY - startY;
  let absDeltaX = Math.abs(deltaX);
  let absDeltaY = Math.abs(deltaY);
  if (absDeltaX > absDeltaY && (absDeltaX > 10 || absDeltaY || 10)) {
    return deltaX < 0 ? "left" : "right";
  } else {
    return deltaY < 0 ? "up" : "down";
  }
}

// Swipe Moves
function moveWithSwipes() {
  if (touchControls) {
    let direction = getSwipeDirection(
      touchStartX,
      touchStartY,
      touchEndX,
      touchEndY
    );
    if (direction === "left" && dx !== TILE) {
      dx = -TILE;
      dy = 0;
    } else if (direction === "right" && dx !== -TILE) {
      dx = TILE;
      dy = 0;
    } else if (direction === "up" && dy !== TILE) {
      dy = -TILE;
      dx = 0;
    } else if (direction === "down" && dy !== -TILE) {
      dy = TILE;
      dx = 0;
    }
  }
}

// Controls selection
let touchControls = false;
let controlSelectorBtn = document.querySelector(".controlSelector");
let controlDiv = document.querySelector(".controls");
controlSelectorBtn.addEventListener("click", () => {
  reset();
  touchControls = !touchControls;
  controlsButton.forEach((btn) => {
    btn.disabled = !btn.disabled;
  });
  if (touchControls) {
    controlsButton.forEach((btn) => {
      btn.style.backgroundColor = "rgba(255, 255, 255, 0)";
      btn.style.color = "rgba(255, 255, 255, 0)";
      controlDiv.style.backgroundColor = "rgba(255, 255, 255, 0.5)";
    });
  } else {
    controlsButton.forEach((btn) => {
      btn.style.backgroundColor = "rgba(255, 255, 255, 0.75)";
      btn.style.color = "green";
      btn.style.borderColor = "rgba(255, 255, 255, 0)";
      controlDiv.style.backgroundColor = "rgba(255, 255, 255, 0)";
    });
  }
});

// Game loop
let lastTime = 0;
function main(time) {
  let elapsedTime = time - lastTime;
  if (elapsedTime > speed && !gameOver) {
    canvasCtx.clearRect(0, 0, WIDTH, HEIGHT);
    drawScore();
    updateSpeed();
    generateFood();
    drawFood();
    snakeMove();
    moveWithSwipes();
    drawSnake();
    checkFoodCollides();
    checkGameOver();
    lastTime = time;
  }
  requestAnimationFrame(main);
  /* 
        The callback function (main here) receives one single argument, 
        a DOMHighResTimeStamp similar to the one returned by performance.now(), 
        indicating the point in time when requestAnimationFrame() 
        starts to execute callback functions.
    */
}
main(performance.now());

// Game functions

function randomX() {
  return Math.floor(Math.random() * COLS) * TILE;
}

function randomY() {
  return Math.floor(Math.random() * ROWS) * TILE;
}

function drawSnake() {
  for (let i = 1; i < snake.length; i++) {
    canvasCtx.fillStyle = foodColor;
    canvasCtx.fillRect(snake[i].x, snake[i].y, TILE, TILE);
    canvasCtx.strokeStyle = "black";
    canvasCtx.strokeRect(snake[i].x, snake[i].y, TILE, TILE);
  }
  canvasCtx.fillStyle = headColor;
  canvasCtx.fillRect(snake[0].x, snake[0].y, TILE, TILE);
}

function snakeMove() {
  let head = { x: snake[0].x + dx, y: snake[0].y + dy };
  if (head.x === WIDTH) head.x = 0;
  else if (head.x < 0) head.x = WIDTH - TILE;
  else if (head.y === HEIGHT) head.y = 0;
  else if (head.y < 0) head.y = HEIGHT - TILE;
  snake.unshift(head); // add at the first pos
  snake.pop(); // remove last
}

function generateFood() {
  if (food === undefined) food = { x: randomX(), y: randomY() };
  isEating = false;
}

function drawFood() {
  canvasCtx.fillStyle = foodColor;
  canvasCtx.fillRect(food.x, food.y, TILE, TILE);
  canvasCtx.strokeStyle = "black";
  canvasCtx.strokeRect(food.x, food.y, TILE, TILE);
}

function checkFoodCollides() {
  if (snake[0].x === food.x && snake[0].y === food.y) {
    snake.push(food); // add at the end pos
    food = undefined;
    isEating = true;
  }
}

let bestScore = 0;
let bestScoreParagraph = document.querySelector(".bestScore");
function checkGameOver() {
  let head = { x: snake[0].x, y: snake[0].y };
  for (let i = 1; i < snake.length; i++) {
    if (head.x === snake[i].x && head.y === snake[i].y && !isEating) {
      gameOver = true;
      if (snake.length - 1 >= bestScore) {
        bestScore = snake.length - 1;
        bestScoreParagraph.textContent = bestScore.toString();
      }
    }
  }
}

function drawScore() {
  document.querySelector(".score").textContent = (snake.length - 1).toString();
}

function updateSpeed() {
  if (snake.length <= 3) speed = 250;
  else if (snake.length === 5) speed = 225;
  else if (snake.length === 7) speed = 200;
  else if (snake.length === 9) speed = 175;
  else if (snake.length === 11) speed = 150;
  else if (snake.length === 13) speed = 125;
  else if (snake.length === 15) speed = 100;
}
