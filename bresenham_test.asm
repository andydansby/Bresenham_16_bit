start:
	call _bresenham_line

endless_loop:
	jp endless_loop

	                      ;  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	                      ;  variables
	                      ;  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
_line_x1:	defw 0      ;  0006 line start point X
_line_y1:	defw 5      ;  0008 line start point Y

_line_x2:	defw 5      ;  000A line end point X
_line_y2:	defw 0      ;  000C line end point Y

stepX:	defb 0                ;  000E
stepY:	defb 0                ;  000F
deltaX:	defw 0                ;  0010
deltaY:	defw 0                ;  0012

error1:	defw 0                ;  0014
error2:	defw 0                ;  0016

_gfx_x:	defb 00               ;  0018
_gfx_y:	defb 00               ;  0019


_gfx_xy:	defw 0
plot_x:	defb 00
plot_y:	defb 00
X_PositionBits:	defb 128,64,32,16,8,4,2,1




_bresenham_line:
	                      ;  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	                      ;  code written by Andrew Dansby
	                      ;  Based on the Wikipedia routine
	                      ;  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DX_step_start:
	ld HL,(_line_x2)      ;  load point X2
	ld DE,(_line_x1)      ;  load point X1
	xor A                 ;  clear flags
	sbc HL,DE             ;  x2 - x1 answer in HL

	jr c,negativeDX       ;  if carry flag is set, then X2 is larger
	                      ;  fall through if positive
	                      ;  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
positiveDX:
	ld A,1
	ld (stepX),A
	jr dx_abs_start       ;  12 t, 2 bytes
	                      ;  DX_step_end:
	                      ;  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
negativeDX:
	ld A,-1
	ld (stepX),A
	                      ;  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dx_abs_start:
	                      ;  ld HL,(_line_x2) ; load point X2
	                      ;  ld DE,(_line_x1) ; load point X1
	                      ;  xor A ; clear flags
	                      ;  sbc HL,DE ; x2 - x1 answer in HL

	                      ;  x2-x1 already in HL
	call absHL
	ld (deltaX),HL

DY_step_start:
	ld HL,(_line_y2)      ;  load point X2
	ld DE,(_line_y1)      ;  load point X1
	xor A                 ;  clear flags
	sbc HL,DE             ;  x2 - x1 answer in HL

	jr c,negativeDY       ;  if carry flag is set, then Y2 is larger

	                      ;  fall through if positive
	                      ;  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
positiveDY:
	ld A,1
	ld (stepY),A
	jr dy_abs_start
	                      ;  DY_step_end:
	                      ;  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
negativeDY:
	ld A,-1
	ld (stepY),A
	                      ;  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dy_abs_start:
	                      ;  ld HL,(_line_y2) ; load point Y2
	                      ;  ld DE,(_line_y1) ; load point Y1
	                      ;  xor A ; clear flags
	                      ;  sbc HL,DE ; y2 - y1 answer in HL

	                      ;  x2-x1 already in HL
	call absHL
	                      ;  ld (deltaY),HL
invert_deltaY:
	                      ;  number is already in HL
	ex DE,HL              ;  swap HL & DE
	ld HL,0
	sbc HL,DE
	ld (deltaY),HL


calculate_error1:
	ld DE,(deltaY)
	ld HL,(deltaX)

	add HL,DE             ;  dx + dy answer in HL
	ld (error1),HL

	                      ;  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	                      ;  lets start our loop
	                      ;  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	jp DXDY_loop

	                      ;  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	                      ;  routine is finished, RETURN
	                      ;  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
end_bresenham:
	ret
	                      ;  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	                      ;  from http://z80-heaven.wikidot.com/math#toc12
absHL:
	bit 7,H
	ret z

	xor A
	sub L
	ld L,A
	sbc A,A
	sub H
	ld H,A
	ret
	                      ;  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



DXDY_loop:
while1:

	                      ;  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	                      ;  plot the pixel x1, y1
	                      ;  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	                      ;  loading a 16 bit variable into 8 bits
	                      ;  only because buffer will be 16 bits
	                      ;  for right now nothing over 191
	ld A,(_line_y1)
	ld (plot_y),A

	                      ;  loading a 16 bit variable into 8 bits
	                      ;  only because buffer will be 16 bits
	                      ;  for right now nothing over 191
	ld A,(_line_x1)
	ld (plot_x),A

	                      ;  call _joffa_pixel
	                      ;  was call, but since plot is only called once
	                      ;  switch to jump
	                      ;  jp _joffa_pixel
	                      ;  jp placeHolder

end_Plot:


	                      ;  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	                      ;  if (x1 == x2 && y1 == y2)
	                      ;  break
	                      ;  suggested by Clive Townsend
	                      ;  of the Z80 Assembly Programming On The
	                      ;  ZX Spectrum facebook group
	                      ;  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
compareX1X2:
	                      ;  if x1 == x2
	ld DE,(_line_x1)
	ld HL,(_line_x2)
	xor A                 ;  clear carry flag
	sbc HL,DE
	jp nz,X1X2_Y1Y2_no_match
	                      ;  if x1 & X2 match, fall through

	                      ;  if y1 == y2
	ld DE,(_line_y1)
	ld HL,(_line_y2)
	                      ;  No need to clear carry, as previous result was zero (so no carry)
	sbc HL,DE
	jp nz,X1X2_Y1Y2_no_match

X1X2_Y1Y2_match:
	                      ;  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	                      ;  Line is now complete
	                      ;  since both x1 & x2 and Y1 & y2 match
	                      ;  the line is now finished drawing
	                      ;  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	                      ;  ret
	jp end_bresenham

	                      ;  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
X1X2_Y1Y2_no_match:	      ;
	                      ;  if the two do not match, then we are not finished we need the next position

error2_calc:
	ld HL,(error1)
	add HL,HL             ;  multiply HL by 2
	ld (error2),HL

check_deltaY:
	ld HL,(error2)
	ld DE,(deltaY)
	                      ;  xor A ;clear flags
	sbc HL,DE

	                      ;  if sign flag is OFF, then error2 is larger
	jp p,deltaY_case      ;  sign flag is OFF

	                      ;  if Zero flag is ON, then error2 is equal to deltaY
	jp z,deltaY_case

check_deltaX:
	ld HL,(deltaX)
	ld DE,(error2)
	                      ;  xor A ;clear flags
	sbc HL,DE

	jp p,deltaX_case      ;  sign flag is OFF

	jp z,deltaX_case      ;  zero flag is on

finished_Delta_check:

	jp DXDY_loop

	                      ;  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
deltaX_case:

	ld HL,(error1)
	ld DE,(deltaX)
	add HL,DE
	ld (error1),HL
	ld A,(stepY)
	ld HL,(_line_y1)
	add A,L
	ld L,A
	ld (_line_y1),HL
	jp finished_Delta_check

	                      ;  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
deltaY_case:

	ld HL,(error1)
	ld DE,(deltaY)
	add HL,DE
	ld (error1),HL

	ld A,(stepX)
	ld HL,(_line_x1)
	add A,L
	ld L,A
	ld (_line_x1),HL
	jp check_deltaX


	                      ;  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_joffa_pixel:
	                      ;  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	                      ;  optimized by andy dansby
	                      ;  using DE/HL
	                      ;  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	                      ;  ld de, (_gfx_xy)
	ld A,(plot_x)
	ld E,A
	ld A,(plot_y)
	ld D,A

	rrca
	rrca
	rrca

	and 00011000b         ;  24 = 0x18
	or 01000000b          ;  64 = 0x40

	ld H,A
	ld A,D
	and 7
	or H
	ld H,A

	ld A,D
	add A,A
	add A,A
	and 11100000b
	ld L,A

	ld A,E
	rrca
	rrca
	rrca
	and 00011111b

	or L
	ld L,A                ;  HL = screen address.

	ld A,E
	and 7

	ld DE,X_PositionBits
	add A,E
	ld E,A
	ld A,(DE)

	                      ;  output to screen
	or (HL)
	ld (HL),A

	jp end_Plot           ;  was ret
	                      ;  replaced because the plot is only called once
endJoffa:
	                      ;  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

placeHolder:
	                      ;  nop
	jp end_Plot
	                      ;  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;