package main

Player_State :: enum u16 {
	Idle,
	Walk,
	Run,
	Crouch,
	Slide,
	Rise,
	Fall,
	Bonk,
	Dive,
	Long_Jump,
	Suck_Hip,
	Suck_Aim,
	Ground_Pound,
	Pull,
}

Player_Flag :: enum u16 {
	Grounded,
	Coyote,
	Jumped,
}
