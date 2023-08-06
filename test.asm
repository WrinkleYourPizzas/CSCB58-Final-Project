# Bitmap Display Configuration:
# - Unit width in pixels: 4
# - Unit height in pixels: 4
# - Display width in pixels: 256
# - Display height in pixels: 256

# - Base Address for Display: 0x10008000 ($gp)

# t2 - register for keyboard input

.data
string: .asciiz "\n A was pressed"
string1: .asciiz "initial stored input: "
bracket: .asciiz "("
bracket0: .asciiz ")"
comma: .asciiz ","
newline: .asciiz "\n"

red: .word 0xff0000
green: .word 0x00ff00
blue: .word 0x0000ff
black: .word 0x000000
white: .word 0xffffff
display: .word 0x10008000

player_x: .word 4
player_y: .word 5
player_width: .word 4
player_height: .word 5
player_delta_y: .word 0
x0: .word 0
y0: .word 0
player_orientation: .word 1
landed: .byte 1
air_time: .word 0
jump_counter: .word 0
taking_damage: .byte 0

base_stack_address: .word 0
platform_stack_size: .word 0
item_stack_size: .word 0
enemy_stack_size: .word 0
bullet_stack_size: .word 0

.globl main
#.eqv display 0x10008000
.text
main:
	# default values
	sw $sp, base_stack_address
	li $t0, 0
	sw $t0, player_x
	sw $t0, platform_stack_size
	sw $t0, item_stack_size
	sw $t0, enemy_stack_size
	sw $t0, bullet_stack_size
	li $t0, 50
	sw $t0, player_y
	li $t0, 0
	sw $t0, x0
	sw $t0, y0
	sw $t0, air_time
	sw $t0, player_delta_y
	li $t0, 1
	sw $t0, landed

	# $s2 stores key input
	li $s2, 0x000000
	
	# draw platform 1	
	lw $a0, green
	li $a1, 6
	li $a2, 55
	li $a3, 11
	jal draw_platform
	
	# draw platform 2	
	lw $a0, green
	li $a1, 15
	li $a2, 50
	li $a3, 20
	jal draw_platform
	
	# draw platform 3	
	lw $a0, green
	li $a1, 22
	li $a2, 45
	li $a3, 27
	jal draw_platform
	
	# init item 1
	lw $a0, blue
	li $a1, 23
	li $a2, 43
	jal draw_item
	
	# init item 2
	lw $a0, blue
	li $a1, 14
	li $a2, 48
	jal draw_item
	
	# init enemy 1
	lw $a0, red		# color
	li $a1, 20		# x
	li $a2, 58		# y
	li $a3, 1		# lower move bound
	li $v0, 40		# upper move bound
	li $v1, 1		# active/inactive
	li $s5, -1		# movement direction
	jal init_enemy

	b game_loop
	
game_loop:
	#player stuff
	lw $s0, player_x
	lw $s1, player_y	
	
	# draw player
	jal erase_player
	jal draw_player
	
	# store previous player location
	sw $s0, x0
	sw $s1, y0

	# keypress stuff
	li $v1, 1
	li $s7, 0xffff0000
	lw $t8, 0($s7)
	bne $t8, 1, after_keypress
	lw $t8, 4($s7)
	
	beq $t8, 0x77, key_W
	beq $t8, 0x61, key_A
	beq $t8, 0x73, key_S
	beq $t8, 0x64, key_D
	beq $t8, 0x70, key_P
	beq $t8, 0x65, key_E
	
	after_keypress:
	
	# gravity
	li $a0, 0
	lb $a1, landed
	beq $a0, $a1, player_gravity
	continue_after_player_gravity:
	
	jal player_hitbox
	
	# sleep
	li $v0, 32
	li $a0, 40
	syscall

	# repeat loop
	b game_loop

player_gravity:
	li $t4, 1
	lw $a1, air_time
	bgt $a1, $t4, skip_add_time
	
	addi $a1, $a1, 1
   	sw $a1, air_time
   	
   	skip_add_time:
   	
   	li $t4, 3
   	lw $a3, player_delta_y
   	bgt $a3, $t4, skip_add_speed
   	
   	add $a3, $a3, $a1
   	sw $a3, player_delta_y
   	
   	skip_add_speed:
   	
   	lw $a2, player_y
	add $a2, $a2, $a3 
   	sw $a2, player_y
   	
   	j continue_after_player_gravity

erase_player:
	li $a0, 4
	lw $t0, display
	lw $t1, black
	lw $t6, x0
	lw $t7, y0
	
	mult $t6, $a0
	mflo $a1
	add $t0, $t0, $a1
	
	li $a0, 256
	mult $t7, $a0
	mflo $a1
	add $t0, $t0, $a1
	
	addi $t0, $t0, 4
	sw $t1, ($t0)
	addi $t0, $t0, 4
	sw $t1, ($t0)
	addi $t0, $t0, 248
	sw $t1, ($t0)
	addi $t0, $t0, 4
	sw $t1, ($t0)
	addi $t0, $t0, 4
	sw $t1, ($t0)
	addi $t0, $t0, 4
	sw $t1, ($t0)
	addi $t0, $t0, 248
	sw $t1, ($t0)
	addi $t0, $t0, 4
	sw $t1, ($t0)
	addi $t0, $t0, 252
	sw $t1, ($t0)
	addi $t0, $t0, 4
	sw $t1, ($t0)
	addi $t0, $t0, 252
	sw $t1, ($t0)
	addi $t0, $t0, 4
	sw $t1, ($t0)
	
	jr $ra

draw_player:	
	lw $s0, player_x
	lw $s1, player_y
	li $a0, 4
	lw $t0, display
	lw $t1, red
	lw $t2, white
	lw $t3, blue
	
	mult $s0, $a0
	mflo $a1
	add $t0, $t0, $a1
	
	li $a0, 256
	
	mult $s1, $a0
	mflo $a1
	add $t0, $t0, $a1
	
	li $t6, 0
	lb $t7, taking_damage
	bne $t6, $t7, player_damage_effect
	continue_after_player_damage_effect:
	
	addi $t0, $t0, 4
	sw $t2, ($t0)
	addi $t0, $t0, 4
	sw $t2, ($t0)
	addi $t0, $t0, 248
	sw $t2, ($t0)
	addi $t0, $t0, 4
	sw $t2, ($t0)
	addi $t0, $t0, 4
	sw $t2, ($t0)
	addi $t0, $t0, 4
	sw $t2, ($t0)
	addi $t0, $t0, 248
	sw $t2, ($t0)
	addi $t0, $t0, 4
	sw $t2, ($t0)
	addi $t0, $t0, 252
	sw $t2, ($t0)
	addi $t0, $t0, 4
	sw $t2, ($t0)
	addi $t0, $t0, 252
	sw $t2, ($t0)
	addi $t0, $t0, 4
	sw $t2, ($t0)
	
	jr $ra
	
	player_damage_effect:
	move $t2, $t1
	li $t6, 0
	sb $t6, taking_damage
	j continue_after_player_damage_effect
	
draw_platform:
	# go to stack location
	lw $sp, base_stack_address
	lw $t1, platform_stack_size
	li $t2, 12
	mult $t1, $t2
	mflo $t2
	sub $sp, $sp, $t2

	# push to stack
	addi $sp, $sp, -4
	sw $a1, 0($sp)
	addi $sp, $sp, -4
	sw $a2, 0($sp)
	addi $sp, $sp, -4
	sw $a3, 0($sp)

	addi $t1, $t1, 1
	sw $t1, platform_stack_size
	
	# draw	
	lw $t0, display
	li $t2, 4
	
	mult $a1, $t2
	mflo $t1
	add $t0, $t0, $t1
	
	li $t2, 256
	
	mult $a2, $t2
	mflo $a2
	add $t0, $t0, $a2
	
	platform_loop:
	sw $a0, ($t0)
	
	addi $t0, $t0, 4
	addi $a1, $a1, 1
	
	blt $a1, $a3, platform_loop
	
	jr $ra
	
draw_item:
	# go to stack location
	lw $sp, base_stack_address
	lw $t1, platform_stack_size
	li $t2, 12
	mult $t1, $t2
	mflo $t2
	sub $sp, $sp, $t2
	li $t2, 8
	lw $t1, item_stack_size
	mult $t1, $t2
	mflo $t2
	sub $sp, $sp, $t2

	# push to stack
	addi $sp, $sp, -4
	sw $a1, 0($sp)
	addi $sp, $sp, -4
	sw $a2, 0($sp)
	
	addi $t1, $t1, 1
	sw $t1, item_stack_size
	
	# find coord
	move $t9, $ra
	jal calculate_coords
	move $t1, $v0
	move $ra, $t9
	
	# draw
	sw $a0, ($t1)
	addi $t1, $t1, 4
	sw $a0, ($t1)
	addi $t1, $t1, 252
	sw $a0, ($t1)
	addi $t1, $t1, 4
	sw $a0, ($t1)

	jr $ra
	
init_enemy:	
	# go to stack location
	lw $sp, base_stack_address
	lw $t1, platform_stack_size
	li $t2, 12
	mult $t1, $t2
	mflo $t2
	sub $sp, $sp, $t2
	li $t2, 8
	lw $t1, item_stack_size
	mult $t1, $t2
	mflo $t2
	sub $sp, $sp, $t2
	lw $t1, enemy_stack_size
	li $t2, 24
	mult $t1, $t2
	mflo $t2
	sub $sp, $sp, $t2
	
	# push to stack
	addi $sp, $sp, -4
	sw $a1, 0($sp)
	addi $sp, $sp, -4
	sw $a2, 0($sp)
	addi $sp, $sp, -4
	sw $a3, 0($sp)
	addi $sp, $sp, -4
	sw $v0, 0($sp)
	addi $sp, $sp, -4
	sw $v1, 0($sp)
	addi $sp, $sp, -4
	sw $s5, 0($sp)
	
	addi $t1, $t1, 1
	sw $t1, enemy_stack_size
	
	move $t9, $ra
	jal draw_enemy
	move $ra, $t9
	
	jr $ra
	
draw_enemy:
	# find coord
	move $t8, $ra
	jal calculate_coords
	move $t0, $v0
	move $ra, $t8
	
	# draw
	addi $t0, $t0, 4
	sw $a0, ($t0)
	addi $t0, $t0, 4
	sw $a0, ($t0)
	addi $t0, $t0, 248
	sw $a0, ($t0)
	addi $t0, $t0, 4
	sw $a0, ($t0)
	addi $t0, $t0, 4
	sw $a0, ($t0)
	addi $t0, $t0, 4
	sw $a0, ($t0)
	addi $t0, $t0, 248
	sw $a0, ($t0)
	addi $t0, $t0, 4
	sw $a0, ($t0)
	addi $t0, $t0, 252
	sw $a0, ($t0)
	addi $t0, $t0, 4
	sw $a0, ($t0)
	addi $t0, $t0, 252
	sw $a0, ($t0)
	addi $t0, $t0, 4
	sw $a0, ($t0)
	
	jr $ra
	
init_bullet:
	# go to stack location
	lw $sp, base_stack_address
	lw $t1, platform_stack_size
	li $t2, 12
	mult $t1, $t2
	mflo $t2
	sub $sp, $sp, $t2
	li $t2, 8
	lw $t1, item_stack_size
	mult $t1, $t2
	mflo $t2
	sub $sp, $sp, $t2
	lw $t1, enemy_stack_size
	li $t2, 24
	mult $t1, $t2
	mflo $t2
	sub $sp, $sp, $t2
	lw $t1, bullet_stack_size
	li $t2, 28
	mult $t1, $t2
	mflo $t2
	sub $sp, $sp, $t2
	
	# push to stack
	addi $sp, $sp, -4
	sw $a1, 0($sp)			# x
	addi $sp, $sp, -4
	sw $a2, 0($sp)			# y
	addi $sp, $sp, -4
	sw $a3, 0($sp)			# speed
	addi $sp, $sp, -4
	sw $k0, 0($sp)			# range
	addi $sp, $sp, -4
	sw $a0, 0($sp)			# colour
	addi $sp, $sp, -4
	sw $k1, 0($sp)			# active/inactive
	addi $sp, $sp, -4
	sw $v1, 0($sp)			# type
	
	addi $t1, $t1, 1
	sw $t1, bullet_stack_size
	
	move $t9, $ra
	jal draw_bullet
	move $ra, $t9
	
	jr $ra
	
draw_bullet:
	# find coord
	move $t8, $ra
	jal calculate_coords
	move $t0, $v0
	move $ra, $t8
	
	sw $a0, 0($t0)
	
	jr $ra
	
key_W:
	lw $t1, jump_counter
	li $t2, 1
	beq $t1, $t2, after_keypress
	
	sw $t2, jump_counter

   	li $a1, 0
   	sw $a1, landed
   	
   	li $a1, -8
   	sw $a1, player_delta_y
   	
	b after_keypress

key_A:
	lw $a1, player_x
	subi $a1, $a1, 2
   	sw $a1, player_x
   	
   	li $a1, -1
   	sw $a1, player_orientation
	
	b after_keypress

key_S:
	lw $a1, player_y
	addi $a1, $a1, 2 
   	sw $a1, player_y

	b after_keypress

key_D:	
	lw $a1, player_x
	addi $a1, $a1, 2
   	sw $a1, player_x
   	
   	li $a1, 1
   	sw $a1, player_orientation
   	
	b after_keypress
	
key_P:
	jal clear_screen
	
	b main
	
key_E:
	lw $a1, player_x
	lw $a2, player_y
	li $a3, 2
	li $k0, 30
	lw $a0, red
	li $k1, 1
	li $v1, 0
	jal init_bullet
	
	b after_keypress
	
player_hitbox:
	# check screen borders
	li $a0, 0
	li $a1, 63
	lw $s0, player_x
	lw $s1, player_y
	
	lw $t7, player_height
	lw $t6, player_width
	sub $t6, $a1, $t6
	sub $a1, $a1, $t7
	
	blt $s0, 0, player_x_nb
	continue_after_player_x_nb:
	bgt $s0, $t6, player_x_pb
	continue_after_player_x_pb:
	blt $s1, 0, player_y_nb
	continue_after_player_y_nb:
	bgt $s1, $a1, player_y_pb	
	continue_after_player_y_pb:
	
	# check entity stacks
	move $t9, $ra
	jal check_platform_stack
	jal check_enemy_stack
	jal check_bullet_stack
	move $ra, $t9
	
	jr $ra

player_x_nb:
	sw $a0, player_x
	j continue_after_player_x_nb
	
player_x_pb:
	sw $t6, player_x
	j continue_after_player_x_pb
	
player_y_nb:
	sw $a0, player_y
	j continue_after_player_y_nb
	
player_y_pb:
	sw $a1, player_y
	
	li $a2, 1
	lw $a3, air_time
	blt $a3, $a2, continue_after_player_y_pb
	
	li $t6, 0
   	sw $t6, air_time
   	sw $t6, player_delta_y
   	sw $t6, jump_counter
   	
   	li $t6, 1
   	sb $t6, landed
	
	j continue_after_player_y_pb

check_platform_stack:
	# go to stack location
	lw $sp, base_stack_address
	lw $t1, platform_stack_size
	li $t2, 12
	mult $t1, $t2
	mflo $t2
	sub $sp, $sp, $t2
	
	# load player variables
	lw $s0, player_x
	lw $s1, player_y
	lw $t4, platform_stack_size
	li $t5, 0
	lw $t2, player_width
	lw $t3, player_height
	move $s4, $sp
	
	lw $t6, player_delta_y
	blt $t6, $t5, skip_platform_check

	check_stack_loop:
	lw $a3, 0($s4)
	addi $s4, $s4, 4
	lw $a2, 0($s4)
	addi $s4, $s4, 4
	lw $a1, 0($s4)
	addi $s4, $s4, 4
	
	subi $t4, $t4, 1
	
	add $t6, $s1, $t3
	blt $t6, $a2, skip_all_conditions
	bgt $s1, $a2, skip_all_conditions
	add $t6, $s0, $t2	
	blt $t6, $a1, skip_all_conditions
	ble $s0, $a3, stand_on_platform
	
	skip_all_conditions:
	bgt $t4, $t5, check_stack_loop
	
	b no_longer_standing_on_platform
	skip_platform_check:
	jr $ra
	
stand_on_platform:		
	sub $s4, $a2, $t3
	sw $s4, player_y
	
	li $t1, 0
   	sw $t1, air_time
   	sw $t1, player_delta_y
   	sw $t1, jump_counter
   	
   	li $t1, 1
   	sb $t1, landed
	
	jr $ra
	
no_longer_standing_on_platform:
	li $t1, 63
	lw $t2, player_y
	beq $t1, $t2, skip_stop_standing_on_platform
	
	li $t1, 0
	sw $t1, landed
	
	skip_stop_standing_on_platform:
	jr $ra
	
check_enemy_stack:
	# go to stack location
	lw $sp, base_stack_address
	lw $t1, platform_stack_size
	li $t2, 12
	mult $t1, $t2
	mflo $t2
	sub $sp, $sp, $t2
	li $t2, 8
	lw $t1, item_stack_size
	mult $t1, $t2
	mflo $t2
	sub $sp, $sp, $t2
	lw $t1, enemy_stack_size
	li $t2, 24
	mult $t1, $t2
	mflo $t2
	sub $sp, $sp, $t2
	
	# load player variables
	lw $s0, player_x
	lw $s1, player_y
	lw $t4, enemy_stack_size
	li $t5, 0
	lw $t2, player_width
	lw $t3, player_height
	
	# loop
	check_enemy_stack_loop:
	lw $s5, 0($sp)		# direction
	move $fp, $sp
	addi $sp, $sp, 4
	lw $k1, 0($sp)		# active/inactive
	addi $sp, $sp, 4
	lw $k0, 0($sp)		# upper move limit
	addi $sp, $sp, 4
	lw $a3, 0($sp)		# lower move limit
	addi $sp, $sp, 4
	lw $a2, 0($sp)		# y
	addi $sp, $sp, 4
	lw $a1, 0($sp)		# x
	move $v1, $sp
	addi $sp, $sp, 4
	
	beq $k1, $t5, skip_inactive_enemy
	
	subi $t4, $t4, 1
	
	beq $a3, $t5, skip_all_enemy_conditions

	# check for collision with player
	add $t6, $s1, $t3
	blt $t6, $a2, skip_all_enemy_conditions
	add $t6, $a2, $t3
	bgt $s1, $t6, skip_all_enemy_conditions
	add $t6, $s0, $t2
	blt $t6, $a1, skip_all_enemy_conditions
	add $t6, $a1, $t2
	ble $s0, $t6, enemy_collision
	
	skip_all_enemy_conditions:
	
	# move enemy
	move $t7, $ra
	jal move_enemy
	move $ra, $t7
	
	skip_inactive_enemy:
	
	bgt $t4, $t5, check_enemy_stack_loop
	
	jr $ra
	
check_bullet_stack:
	# load player variables
	lw $s0, player_x
	lw $s1, player_y
	lw $t4, bullet_stack_size
	li $t5, 0
	li $s3, 64
	lw $t2, player_width
	lw $t3, player_height
	
	beq $t4, $t5, empty_bullet_stack
	
	# go to stack location
	lw $sp, base_stack_address
	lw $t1, platform_stack_size
	li $t2, 12
	mult $t1, $t2
	mflo $t2
	sub $sp, $sp, $t2
	li $t2, 8
	lw $t1, item_stack_size
	mult $t1, $t2
	mflo $t2
	sub $sp, $sp, $t2
	lw $t1, enemy_stack_size
	li $t2, 24
	mult $t1, $t2
	mflo $t2
	sub $sp, $sp, $t2
	lw $t1, bullet_stack_size
	li $t2, 28
	mult $t1, $t2
	mflo $t2
	sub $sp, $sp, $t2
	
	# loop
	check_bullet_stack_loop:
	lw $s5, 0($sp)		# type
	addi $sp, $sp, 4
	lw $k1, 0($sp)		# active/inactive
	addi $sp, $sp, 4
	lw $a0, 0($sp)		# colour
	addi $sp, $sp, 4
	lw $k0, 0($sp)		# range
	move $fp, $sp
	addi $sp, $sp, 4
	lw $a3, 0($sp)		# speed
	addi $sp, $sp, 4
	lw $a2, 0($sp)		# y
	addi $sp, $sp, 4
	lw $a1, 0($sp)		# x
	move $v1, $sp
	addi $sp, $sp, 4
	
	subi $t4, $t4, 1
	
	beq $a1, $t5, set_bullet_to_inactive
	beq $a1, $s3, set_bullet_to_inactive
	beq $k0, $t5, set_bullet_to_inactive
	beq $k1, $t5, skip_inactive_bullet
	
	# check for collision with player
	add $t6, $s1, $t3
	blt $t6, $a2, check_enemy_collision
	add $t6, $a2, $t3
	bgt $s1, $t6, check_enemy_collision
	add $t6, $s0, $t2
	blt $t6, $a1, check_enemy_collision
	add $t6, $a1, $t2
	#ble $s0, $t6, take_damage
	
	check_enemy_collision:
	# check for collision with player
	
	# move bullet
	move $t7, $ra
	jal move_bullet
	move $ra, $t7	
	
	skip_inactive_bullet:
	
	bgt $t4, $t5, check_bullet_stack_loop
	
	empty_bullet_stack:
	
	jr $ra
	
	set_bullet_to_inactive:
		move $t7, $ra
		
		sw $t5, 0($fp)
		lw $a0, black
		jal draw_bullet
		
		move $ra, $t7	
		j skip_inactive_bullet
	
move_enemy:
	beq $a1, $k0, flip
	beq $a1, $a3, flip
	continue_after_flip:

	move $s7, $ra
	
	lw $a0, black
	jal draw_enemy
	
	add $a1, $a1, $s5
	
	lw $a0, red
	jal draw_enemy
	sw $a1, 0($v1)
	
	move $ra, $s7
	
	skip_move_enemy:
	jr $ra
	
	flip:	
	li $s6, -1
	mult $s6, $s5
	mflo $s5
	sw $s5, 0($fp)
	j continue_after_flip
	
move_bullet:	
	move $s7, $ra
	
	lw $a0, black
	jal draw_bullet
	
	add $a1, $a1, $a3
	
	b print
	continue_after_print:
	
	lw $a0, red
	jal draw_bullet
	sw $a1, 0($v1)
	
	move $ra, $s7
	
	jr $ra
	
enemy_collision:	
	#b print_stack
	continue_after_print_stack:
	
	li $t1, 1
	sb $t1, taking_damage

	lw $t1, x0
	lw $t2, y0
	sw $t1, player_x
	sw $t2, player_y
	
	jr $ra
	
enemy_death:
	lw $a0, black
	jal draw_enemy
	
	jr $ra
	
clear_screen:
	lw $t1, display
	lw $t2, black
	li $t3, 4096
	li $t4, 0
	
	change_to_black:
		sw $t2, ($t1)
		addi $t1, $t1, 4
		subi $t3, $t3, 1
		bgt $t3, $t4, change_to_black
	jr $ra
	
calculate_coords:
	lw $t0, display
	li $t2, 4
	
	mult $a1, $t2
	mflo $t1
	add $t0, $t0, $t1
	
	li $t2, 256
	
	mult $a2, $t2
	mflo $v0
	add $v0, $t0, $v0
	
	jr $ra
	
print:
	li $v0, 4
 	la $a0, bracket
 	syscall
 	
	li $v0, 1
   	lw $a0, x0
 	syscall
 	
 	li $v0, 4
 	la $a0, comma
 	syscall
	
	li $v0, 1
   	lw $a0, y0
 	syscall
 	
 	li $v0, 4
 	la $a0, comma
 	syscall
 	
 	li $v0, 1
   	lw $a0, player_x
 	syscall
 	
 	li $v0, 4
 	la $a0, comma
 	syscall
 	
 	li $v0, 1
   	lw $a0, player_y
 	syscall
 	
 	li $v0, 4
 	la $a0, bracket0
 	syscall
 	
 	li $v0, 4
 	la $a0, comma
 	syscall
 	
 	li $v0, 1
   	move $a0, $a1
 	syscall
 	
 	li $v0, 4
 	la $a0, comma
 	syscall
 	
 	li $v0, 1
   	move $a0, $a2
 	syscall
 	
 	li $v0, 4
 	la $a0, comma
 	syscall
 	
 	li $v0, 1
   	move $a0, $a3
 	syscall
  	
 	li $v0, 4
 	la $a0, newline
 	syscall
 
 	j continue_after_print	
# 	jr $ra
 	
print_stack:
	li $v0, 1
   	move $a0, $sp
 	syscall

	li $v0, 4
 	la $a0, comma
 	syscall

 	li $v0, 1
   	move $a0, $a1
 	syscall
 	
 	li $v0, 4
 	la $a0, comma
 	syscall
 	
 	li $v0, 1
   	move $a0, $a2
 	syscall
 	
 	li $v0, 4
 	la $a0, comma
 	syscall
 	
 	li $v0, 1
   	move $a0, $a3
 	syscall
 	
 	li $v0, 4
 	la $a0, newline
 	syscall
 	
# 	jr $ra
	j continue_after_print_stack

exit:
	li $v0, 10 
	syscall
