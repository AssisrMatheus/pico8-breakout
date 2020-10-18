pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- Returns whether or not the ball hit a box
function hit_ballbox(bx,by,tx,ty,tw,th)
	if by-ball_r > ty+th then return false end
	if by+ball_r < ty then return false end
	if bx-ball_r > tx+tw then return false end
	if bx+ball_r < tx then return false end
	return true
end

-- calculate where to deflect the ball
-- horizontally or vertically when it hits a box
function deflx_ballbox(bx,by,bdx,bdy,tx,ty,tw,th)
	if bdx == 0 then
	 -- moving vertically
	 return false
	elseif bdy == 0 then
	 -- moving horizontally
	 return true
	else
	 -- moving diagonally
	 -- calculate slope
	 local slp = bdy / bdx
	 local cx, cy
	 -- check variants
	 if slp > 0 and bdx > 0 then
		-- moving down right
		cx = tx-bx
		cy = ty-by
		return cx > 0 and cy/cx < slp
	 elseif slp < 0 and bdx > 0 then
		-- moving up right
		cx = tx-bx
		cy = ty+th-by
		return cx > 0 and cy/cx >= slp
	 elseif slp > 0 and bdx < 0 then
		-- moving left up
		cx = tx+tw-bx
		cy = ty+th-by
		return cx < 0 and cy/cx <= slp
	 else
		-- moving left down
		cx = tx+tw-bx
		cy = ty-by
		return cx < 0 and cy/cx >= slp		
	 end
	end
	return false
end

-- creates the brick structure
function buildbricks()
	brick_x={}
	brick_y={}
	brick_v={}

	local i
	-- for each brick
	for i=1,66 do
		-- calculate its x position
		add(brick_x, 4+((i-1)%11)*(brick_w+2))

		-- calculate its y position
		add(brick_y, 20+flr((i-1)/11)*(brick_h+2))

		-- calculate its visibility
		add(brick_v, true)
	end
end

-- makes a new ball
function serveball() 
	--ball position
	ball_x=10
	ball_y=70
	
	-- ball speed
	ball_dx=1
	ball_dy=1
end

-- A function that starts/restarts the game
function startgame()
	mode="game"

	-- ball radius
	ball_r=2	
	-- ball radius speed?
	ball_dr=0.5

	-- color of the ball
	col=10

	-- color of the paddle
	paddle_col=7

	-- paddle values
	pad_x=52
	pad_y=120
	pad_w=24
	pad_h=3

	-- paddle current speed
	pad_dx=0

	-- paddle speed multiplier
	pad_speed=2.5

	-- the amount to be used as the pad weight for its slow down
	pad_weight=1.3

	-- declare the size of the bricks
	brick_w=9
	brick_h=4

	-- make the bricks
	buildbricks()

	-- declare the initial score
	lives=3
	points=0

	-- serves a ball
	serveball()
end

-- ends the game
function gameover()
	mode="gameover"
end

-- ############## UPDATES

function update_start()
	-- If the user press X, starts game
	if btn(❎) then
		startgame()
	end
end

function update_game()
	local button_press=false 
	
	--left
	if btn(⬅️) then
		pad_dx=-pad_speed
		button_press=true
		--pad_x-=pad_speed
	end

	--right
	if btn(➡️) then
		pad_dx=pad_speed
		button_press=true
		--pad_x+=pad_speed
	end
	
	-- if the user is not pressing the button, slows down the paddle
	if not button_press then
		pad_dx=pad_dx/pad_weight
	end
	
	-- then move the paddle
	pad_x+=pad_dx

	-- clamp the pad to the middle of screen
	pad_x=mid(0, pad_x, 127-pad_w)

	
	local next_x, next_y

	-- get the next position of the ball
	next_x = ball_x+ball_dx 
	next_y = ball_y+ball_dy

	-- if the next position is out of bounds in the sides
 if next_x > 124 or next_x < 3 then
	-- make sure it stays inbounds
	next_x = mid(0, next_x, 127)

	-- reflect the ball to the opposite side
 	ball_dx = -ball_dx
 	sfx(0)
 end

 -- if the next position is out of bounds in the top section
 if next_y < 10 then
	-- make sure it stays inbounds
	next_y = mid(10, next_y, 127)

	-- reflect the ball to the opposite side
 	ball_dy = -ball_dy
 	sfx(0)
 end

 -- If ball hit the pad
 if hit_ballbox(next_x, next_y, pad_x, pad_y, pad_w, pad_h) then
	points+=1
	if deflx_ballbox(ball_x, ball_y, ball_dx, ball_dy, pad_x, pad_y, pad_w, pad_h) then
		ball_dx = -ball_dx
		if ball_x < pad_x+(pad_w/2) then
			next_x = pad_x-ball_r
		else
			next_x = pad_x+pad_w+ball_r
		end
	else
		ball_dy = -ball_dy

		if ball_y > pad_y then
			next_y=pad_y+pad_h+ball_r
		else
			next_y=pad_y-ball_r
		end

	end
	sfx(1)
 end

 -- for each brick
 local brick_hit = false
 local i
 for i=1,#brick_x do
	-- check if ball hit brick
	if brick_v[i] and hit_ballbox(next_x, next_y, brick_x[i], brick_y[i], brick_w, brick_h) then
		if not brick_hit then
			sfx(3)
			brick_hit = true
			if deflx_ballbox(ball_x, ball_y, ball_dx, ball_dy, brick_x[i], brick_y[i], brick_w, brick_h) then
				ball_dx = -ball_dx
			else
				ball_dy = -ball_dy
			end
		end

		points+=10
		brick_v[i] = false
	 end
end
 
 ball_x = next_x
 ball_y = next_y 

 -- if the next position is out of bounds in the bottom section
 if next_y > 127 then
	sfx(2)
	lives-=1
	if lives < 0 then
		gameover()
	else
		serveball()
	end	
	return
 end
end

function updade_over()
	if btn(❎) then
		startgame()
	end
end

-- ############## DRAWS

function draw_start()
	cls()
	print('pico hero breakout',30,40,7)
	print('press ❎ to start',32,80,11)
end

function draw_game()
	cls(1)
	
	-- draw the ball
	circfill(ball_x,ball_y,ball_r,col)

	-- draw the paddle	
	rectfill(pad_x,pad_y, pad_x+pad_w,pad_y+pad_h,paddle_col)

	local i
	for i=1,#brick_x do
		-- draw bricks
		if brick_v[i] then
			rectfill(brick_x[i],brick_y[i], brick_x[i]+brick_w,brick_y[i]+brick_h,14)
		end
	end

	rectfill(0,0,128,6,0)
	print("lives:"..lives,1,1,7)
	print("score:"..points,40,1,7)
end


function draw_over()
	rectfill(0,60,128,75,0)
	print("game over", 46,62,7)
	print("press ❎ to restart",27,68,6)
end

-- ############## NATIVE

function _init()
	cls()
	mode="start"
end

function _update60()
	if mode =="start" then
		update_start()
	elseif mode == "game" then
		update_game()
	elseif mode == "gameover" then
		updade_over()
	end
end

function _draw()
	if mode =="start" then
		draw_start()
	elseif mode == "game" then
		draw_game()
	elseif mode == "gameover" then
		draw_over()
	end
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888eeeeee888888888888888888888888888888888888888888888888888888888888888888888888ff8ff8888228822888222822888888822888888228888
8888ee888ee88888888888888888888888888888888888888888888888888888888888888888888888ff888ff888222222888222822888882282888888222888
888eee8e8ee88888e88888888888888888888888888888888888888888888888888888888888888888ff888ff888282282888222888888228882888888288888
888eee8e8ee8888eee8888888888888888888888888888888888888888888888888888888888888888ff888ff888222222888888222888228882888822288888
888eee8e8ee88888e88888888888888888888888888888888888888888888888888888888888888888ff888ff888822228888228222888882282888222288888
888eee888ee888888888888888888888888888888888888888888888888888888888888888888888888ff8ff8888828828888228222888888822888222888888
888eeeeeeee888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1e1e1ee111ee1eee1eee11ee1ee1111111111616166616611666166616661611166611711171111111111111111111111111111111111111111111111111
1e111e1e1e1e1e1111e111e11e1e1e1e111111111616161616161616116116111611161617111117111111111111111111111111111111111111111111111111
1ee11e1e1e1e1e1111e111e11e1e1e1e111111111616166616161666116116611666161617111117111111111111111111111111111111111111111111111111
1e111e1e1e1e1e1111e111e11e1e1e1e111111111616161116161616116116111616161617111117111111111111111111111111111111111111111111111111
1e1111ee1e1e11ee11e11eee1ee11e1e111116661166161116661616116116661666166611711171111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111666166616111611111116161111111111111666166616111611111116161111111111111666166616111611111116611616111111111111111111111111
11111616161616111611111116161111177711111616161616111611111116161111117111111616161616111611111116161616111111111111111111111111
11111661166616111611111111611111111111111661166616111611111111611111177711111661166616111611111116161161111111111111111111111111
11111616161616111611111116161111177711111616161616111611111116161111117111111616161616111611111116161616111111111111111111111111
11111666161616661666166616161111111111111666161616661666166616161111111111111666161616661666166616661616111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111666166616111611111116161111111111111666166616111611111116161111111111111666166616111611111116611616111111111111111111111111
11111616161616111611111116161111177711111616161616111611111116161111117111111616161616111611111116161616111111111111111111111111
11111661166616111611111116661111111111111661166616111611111116661111177711111661166616111611111116161666111111111111111111111111
11111616161616111611111111161111177711111616161616111611111111161111117111111616161616111611111116161116111111111111111111111111
11111666161616661666166616661111111111111666161616661666166616661111111111111666161616661666166616661666111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111eee1eee11111666166616111611111116161111171111111cc11ccc1ccc111111ee1eee11111666166616111611111116161111111711111ccc11111eee
111111e11e11111116161616161116111111161611111171111111c1111c111c11111e1e1e1e11111616161616111611111116161111117111111c1c111111e1
111111e11ee1111116611666161116111111116111111117111111c11ccc111c11111e1e1ee111111661166616111611111111611111171111111c1c111111e1
111111e11e11111116161616161116111111161611111171111111c11c11111c11111e1e1e1e11111616161616111611111116161111117111111c1c111111e1
11111eee1e1111111666161616661666166616161111171111111ccc1ccc111c11111ee11e1e11111666161616661666166616161111111711111ccc111111e1
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111166616661611161111111661161611111111111111111666166616111611111116611616111111111111111111111111111111111111111111111111
11111111161616161611161111111616161611111777111111111616161616111611111116161616111111111111111111111111111111111111111111111111
11111111166116661611161111111616116111111111111117771661166616111611111116161161111111111111111111111111111111111111111111111111
11111111161616161611161111111616161611111777111111111616161616111611111116161616111111111111111111111111111111111111111111111111
11111111166616161666166616661666161611111111111111111666161616661666166616661616111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111111bb1bbb1b1b11711ccc1171111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111b111b111b1b17111c1c1117111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111bbb1bb111b117111c1c1117111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111b1b111b1b17111c1c1117111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111bb11b111b1b11711ccc1171111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111eee1ee11ee11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111e111e1e1e1e1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111ee11e1e1e1e1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111e111e1e1e1e1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111eee1e1e1eee1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111117111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111117711111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111117771111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111117777111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111117711111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111171111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111eee1eee11111666166616111611111116161111171111111cc11ccc1ccc111111ee1eee11111666166616111611111116161111111711111ccc11111eee
111111e11e11111116161616161116111111161611111171111111c1111c111c11111e1e1e1e11111616161616111611111116161111117111111c1c111111e1
111111e11ee1111116611666161116111111166611111117111111c11ccc111c11111e1e1ee111111661166616111611111116661111171111111c1c111111e1
111111e11e11111116161616161116111111111611111171111111c11c11111c11111e1e1e1e11111616161616111611111111161111117111111c1c111111e1
11111eee1e1111111666161616661666166616661111171111111ccc1ccc111c11111ee11e1e11111666161616661666166616661111111711111ccc111111e1
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111166616661611161111111661161611111111111111111666166616111611111116611616111111111111111111111111111111111111111111111111
11111111161616161611161111111616161611111777111111111616161616111611111116161616111111111111111111111111111111111111111111111111
11111111166116661611161111111616166611111111111117771661166616111611111116161666111111111111111111111111111111111111111111111111
11111111161616161611161111111616111611111777111111111616161616111611111116161116111111111111111111111111111111111111111111111111
11111111166616161666166616661666166611111111111111111666161616661666166616661666111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111111bb1bbb1b1b11711ccc1171111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111b111b111b1b17111c1c1117111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111bbb1bb111b117111c1c1117111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111b1b111b1b17111c1c1117111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111bb11b111b1b11711ccc1171111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111eee1ee11ee11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111e111e1e1e1e1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111ee11e1e1e1e1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111e111e1e1e1e1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111eee1e1e1eee1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1ee11ee111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1ee11e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1e1e1eee11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1e1e1ee111ee1eee1eee11ee1ee1111111111661166616661616117111711111111111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e1e1111e111e11e1e1e1e111111111616161616161616171111171111111111111111111111111111111111111111111111111111111111111111
1ee11e1e1e1e1e1111e111e11e1e1e1e111111111616166116661616171111171111111111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e1e1111e111e11e1e1e1e111111111616161616161666171111171111111111111111111111111111111111111111111111111111111111111111
1e1111ee1e1e11ee11e11eee1ee11e1e111116661666161616161666117111711111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111bbb1bbb11bb1bbb1bbb1bbb1b111b1111711ccc11111ccc111111111cc11ccc1ccc111111111cc11ccc1ccc111111111cc1117111111111111111111111
11111b1b1b111b1111b11b1111b11b111b1117111c1c11111c1c1111111111c1111c111c1111111111c1111c111c1111111111c1111711111111111111111111
11111bb11bb11b1111b11bb111b11b111b1117111c1c11111c1c1111111111c11ccc111c1111111111c11ccc111c1111111111c1111711111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
82888222822882228888822882228882822282228888888888888888888888888888888888888888888888888888822282288882822282288222822288866688
82888828828282888888882882888828888282888888888888888888888888888888888888888888888888888888828288288828828288288282888288888888
82888828828282288888882882228828882282228888888888888888888888888888888888888888888888888888822288288828822288288222822288822288
82888828828282888888882888828828888288828888888888888888888888888888888888888888888888888888888288288828828288288882828888888888
82228222828282228888822282228288822282228888888888888888888888888888888888888888888888888888888282228288822282228882822288822288
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888

__sfx__
0001000012230132201422015220182101c210202102021004200032000120000200002000020000200002000020000200000000d2000b2000820007200062000420002200002000020003000020000000000000
0001000008750097500b7500c7500d7500e7500d7500a750000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200001b4501745014450124500f4500b4500a45009450063500535004340023400033000330003500035000350003500000000000000000000000000000000000000000000000000000000000000000000000
0003000004450034500345005450094100a4001a4001c400016000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
