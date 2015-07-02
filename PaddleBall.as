package {
	import flash.display.*;
	import flash.events.*;
	import flash.utils.getTimer;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	
	public class PaddleBall extends MovieClip {
		// environment constants 
		private const ballRadius:Number = 9;
		private const wallTop:Number = 18;
		private const wallLeft:Number = 18;
		private const wallRight:Number = 532;
		private const paddleY:Number = 380;
		private const paddleWidth:Number = 90;
		private const ballSpeed:Number = .2;
		private const paddleCurve:Number = .005;
		private const paddleHeight:Number = 18;
		
		// key objects
		private var paddle:Paddle;
		private var ball:Ball;
		
		// bricks
		private var bricks:Array;
		
		// ball velocity
		private var ballDX:Number;
		private var ballDY:Number;
		
		// animation timer
		private var lastTime:uint;
		
		// number of balls left
		private var balls:Number;
		
		public function startPaddleBall() {
			
			// create paddle
			paddle = new Paddle();
			paddle.y = paddleY;
			addChild(paddle);
						
			// create bricks
			makeBricks();
			
			balls = 3;
			gameMessage.text = "Click To Start";
			
			// set up animation
			lastTime = 0;
			addEventListener(Event.ENTER_FRAME,moveObjects);
			stage.addEventListener(MouseEvent.CLICK,newBall);
		}
		
		// make collection of bricks
		public function makeBricks() {
			bricks = new Array();
			
			// create a grid of bricks, 5 vertical by 8 horizontal
			for(var y:uint=0;y<5;y++) {
				for(var x:uint=0;x<8;x++) {
					var newBrick:Brick = new Brick();
					// space them nicely
					newBrick.x = 60*x+65;
					newBrick.y = 20*y+50;
					addChild(newBrick);
					bricks.push(newBrick);
				}
			}
		}
		
		public function newBall(event:Event) {
			// don't go here if there is already a ball
			if (ball != null) return;
			
			gameMessage.text = "";

			// create ball, center it
			ball = new Ball();
			ball.x = (wallRight-wallLeft)/2+wallLeft;
			ball.y = 200;//(paddleY-wallTop)/2+wallTop;
			addChild(ball);
			
			// ball velocity
			ballDX = 0;
			ballDY = ballSpeed;
			
			// use up a ball
			balls--;
			ballsLeft.text = "Balls: "+balls;
			
			// reset animation
			lastTime = 0;
		}
		
		public function moveObjects(event:Event) {
			movePaddle();
			moveBall();
		}
		
		public function movePaddle() {
			// match horizontal value with the mouse
			var newX:Number = Math.min(wallRight-paddleWidth/2,
				Math.max(wallLeft+paddleWidth/2,
					mouseX));
			paddle.x = newX;
		}
		
		public function moveBall() {
			// don't go here if in between balls
			if (ball == null) return;

			// get new location for ball
			if (lastTime == 0) lastTime = getTimer();
			var timePassed:int = getTimer()-lastTime;
			lastTime += timePassed;
			var newBallX = ball.x + ballDX*timePassed;
			var newBallY = ball.y + ballDY*timePassed;
			var oldBallRect = new Rectangle(ball.x-ballRadius, ball.y-ballRadius, ballRadius*2, ballRadius*2);
			var newBallRect = new Rectangle(newBallX-ballRadius, newBallY-ballRadius, ballRadius*2, ballRadius*2);
			var paddleRect = new Rectangle(paddle.x-paddleWidth/2, paddle.y-paddleHeight/2, paddleWidth, paddleHeight);
			
			// collision with paddle
			if (newBallRect.bottom >= paddleRect.top) {
				if (oldBallRect.bottom < paddleRect.top) {
					if (newBallRect.right > paddleRect.left) {
						if (newBallRect.left < paddleRect.right) {
							// bounce back
							newBallY -= 2*(newBallRect.bottom - paddleRect.top);
							ballDY *= -1;
							// decide new angle
							ballDX = (newBallX-paddle.x)*paddleCurve;
						}
					}
				} else if (newBallRect.top > 400) {
					removeChild(ball);
					ball = null;
					if (balls > 0) {
						gameMessage.text = "Click For Next Ball";
					} else {
						endGame();
					}
					return;
				}

			}
			
			// collision with top wall
			if (newBallRect.top < wallTop) {
				newBallY += 2*(wallTop - newBallRect.top);
				ballDY *= -1;
			}
			
			// collision with left wall
			if (newBallRect.left < wallLeft) {
				newBallX += 2*(wallLeft - newBallRect.left);
				ballDX *= -1;
			}
			
			// collision with right wall
			if (newBallRect.right > wallRight) {
				newBallX += 2*(wallRight - newBallRect.right);
				ballDX *= -1;
			}
			
			// collision with bricks
			for(var i:int=bricks.length-1;i>=0;i--) {
				
				// get brick rectangle
				var brickRect:Rectangle = bricks[i].getRect(this);
				
				// is there a brick collision
				if (brickRect.intersects(newBallRect)) {
					
					// ball hitting left or right side
					if (oldBallRect.right < brickRect.left) {
						newBallX += 2*(brickRect.left - oldBallRect.right);
						ballDX *= -1;
					} else if (oldBallRect.left > brickRect.right) {
						newBallX += 2*(brickRect.right - oldBallRect.left);
						ballDX *= -1;
					}
					
					// ball hitting top or bottom
					if (oldBallRect.top > brickRect.bottom) {
						ballDY *= -1;
						newBallY += 2*(brickRect.bottom-newBallRect.top);
					} else if (oldBallRect.bottom < brickRect.top) {
						ballDY *= -1;
						newBallY += 2*(brickRect.top - newBallRect.bottom);
					}

					// remove the brick
					removeChild(bricks[i]);
					bricks.splice(i,1);
					if (bricks.length < 1) {
						endGame();
						return;
					}
					
					// one collision is enough
					break;
				}
			}
			
			// set new position
			ball.x = newBallX;
			ball.y = newBallY;
		}
		
		function endGame() {
			// remove paddle and bricks
			removeChild(paddle);
			for(var i:int=bricks.length-1;i>=0;i--) {
				removeChild(bricks[i]);
			}
			paddle = null;
			bricks = null;
			
			// remove ball
			if (ball != null) {
				removeChild(ball);
				ball = null;
			}
			
			
			// remove listeners
			removeEventListener(Event.ENTER_FRAME,moveObjects);
			stage.removeEventListener(MouseEvent.CLICK,newBall);
			
			gotoAndStop("gameover");
		}
	}
}
