pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
ball_x=124/2
ball_dx=1

ball_y=127/2
ball_dy=1

ball_r=2

col=0

function _init()
	cls()
end

function _update60()
 ball_x = ball_x + ball_dx
 ball_y = ball_y + ball_dy
 
 col = col + 1
 
 if ball_x > 127 or ball_x < 0 then
 	ball_dx=-ball_dx
 end

 if ball_y > 127 then
 	ball_dy=-1
 end

 if ball_y < 0 then
 	ball_dy=1 	
 end
 
end

function _draw()
--	cls()
	circfill(ball_x, ball_y, ball_r, col)
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
