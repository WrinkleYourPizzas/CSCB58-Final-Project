.data
bracket: .asciiz "("
bracket0: .asciiz ")"
comma: .asciiz ","
newline: .asciiz "\n"

red: .word 0xff0000
green: .word 0x00ff00
blue: .word 0x0000ff
black: .word 0x000000
brown: .word 0x964b00
white: .word 0xffffff
yellow: .word 0xffff00
gray: .word 0x808080
purple: .word 0x800080

display: .word 0x10008000

player_health: .word 50
player_targettable: .byte 1
player_x: .word 4
player_y: .word 5
player_speed: .word 2
player_width: .word 4
player_height: .word 5
player_delta_y: .word 0
x0: .word 0
y0: .word 0
player_orientation: .word 1
landed: .byte 1
air_time: .word 0
jump_counter: .word 0
jump_force: .word -7
taking_damage: .byte 0
player_shooting: .word 0

end_x: .word 54
end_y: .word 5

base_stack_address: .word 0
current_stack_address: .word 0
platform_stack_size: .word 0
item_stack_size: .word 0
enemy_stack_size: .word 0
bullet_stack_size: .word 0

.globl main
.text

main:
	# default values
	sw $sp, base_stack_address
	sw $zero, player_x
	li $t0, 50
	sw $t0, player_y
	li $t0, 30
	sw $t0, player_health
	sw $zero, platform_stack_size
	sw $zero, item_stack_size
	sw $zero, enemy_stack_size
	sw $zero, bullet_stack_size
	sw $zero, x0
	sw $zero, y0
	sw $zero, air_time
	sw $zero, player_delta_y
	li $t0, 1
	sw $t0, landed
	li $t0, 2
	sw $t0, player_speed
	li $t0, -7
	sw $t0, jump_force

	# $s2 stores key input
	li $s2, 0x000000
	
	# draw end door
	lw $a0, brown
	lw $a1, end_x
	lw $a2, end_y
	jal draw_door
	
	# draw platform 1	
	lw $a0, green			# color
	li $a1, 6			# start x
	li $a2, 55			# y
	li $a3, 30			# end x
	jal draw_platform
	
	# draw platform 2	
	lw $a0, green
	li $a1, 30
	li $a2, 45
	li $a3, 60
	jal draw_platform
	
	# draw platform 3	
	lw $a0, green
	li $a1, 10
	li $a2, 35
	li $a3, 27
	jal draw_platform
	
	# draw platform 4
	lw $a0, green
	li $a1, 0
	li $a2, 30
	li $a3, 15
	jal draw_platform
	
	# draw platform 5
	lw $a0, green
	li $a1, 20
	li $a2, 10
	li $a3, 60
	jal draw_platform
	
	# init item 1
	lw $a0, gray		# color
	li $a1, 54		# x
	li $a2, 43		# y
	li $a3, 1		# active/inactive
	jal draw_item
	
	# init item 2
	lw $a0, blue
	li $a1, 20
	li $a2, 53
	li $a3, 1		
	jal draw_item
	
	# init item 3
	lw $a0, purple
	li $a1, 4
	li $a2, 28
	li $a3, 1		
	jal draw_item
	
	# init enemy 1
	lw $a0, red		# color
	li $a1, 20		# x
	li $a2, 58		# y
	li $a3, 1		# lower move bound
	li $v0, 40		# upper move bound
	li $v1, 1		# active/inactive
	li $s5, -1		# movement direction
	li $s6, 30		# shoot cooldown
	jal init_enemy
	
	# init enemy 2
	lw $a0, red		# color
	li $a1, 40		# x
	li $a2, 40		# y
	li $a3, 35		# lower move bound
	li $v0, 50		# upper move bound
	li $v1, 1		# active/inactive
	li $s5, -1		# movement direction
	li $s6, 30		# shoot cooldown
	jal init_enemy
	
	# init enemy 3
	lw $a0, red		# color
	li $a1, 45		# x
	li $a2, 5		# y
	li $a3, 35		# lower move bound
	li $v0, 55		# upper move bound
	li $v1, 1		# active/inactive
	li $s5, -1		# movement direction
	li $s6, 30		# shoot cooldown
	jal init_enemy

	b game_loop
	
game_loop:
	# draw end door
	lw $a0, brown
	lw $a1, end_x
	lw $a2, end_y
	jal draw_door

	# draw player
	jal erase_player
	
	lb $s0, player_targettable
	beq $zero, $s0, skip_draw_player
	
	jal draw_player
	
	skip_draw_player:
	
	# store previous player location
	sw $s0, x0
	sw $s1, y0

	# keypress stuff
	lw $k0, player_shooting
	bgt $k0, $zero, increment_player_shooting
	
	li $v1, 1
	li $s7, 0xffff0000
	lw $t8, 0($s7)
	bne $t8, 1, after_keypress
	lw $t8, 4($s7)
	
	beq $t8, 0x77, key_W
	beq $t8, 0x61, key_A
	beq $t8, 0x64, key_D
	beq $t8, 0x70, key_P
	beq $t8, 0x65, key_E
	beq $t8, 0x71, key_Q
	
	after_keypress:
	
	# gravity
	li $a0, 0
	lb $a1, landed
	beq $a0, $a1, player_gravity
	continue_after_player_gravity:
	
	j player_hitbox
	continue_after_player_hitbox:
	
	# player shooting effects
	lw $s1, player_shooting
	li $s2, 2
	beq $s1, $s2, draw_player_bullet
	continue_after_draw_player_bullet:
	
	li $s2, 5
	beq $s1, $s2, erase_player_bullet
	continue_after_erase_player_bullet:
	
	# sleep
	li $v0, 32
	li $a0, 40
	syscall

	# repeat loop
	b game_loop

increment_player_shooting:
	addi $k0, $k0, 1
	sw $k0, player_shooting
	j after_keypress

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
	lw $t1, green
	lw $t2, black
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
	lw $k0, ($t0)
	beq $k0, $t1, player_erase_1
	sw $t2, ($t0)
	addi $t0, $t0, 4
	player_erase_1:
	lw $k0, ($t0)
	beq $k0, $t1, player_erase_2
	sw $t2, ($t0)
	addi $t0, $t0, 248
	player_erase_2:
	lw $k0, ($t0)
	beq $k0, $t1, player_erase_3
	sw $t2, ($t0)
	addi $t0, $t0, 4
	player_erase_3:
	lw $k0, ($t0)
	beq $k0, $t1, player_erase_4
	sw $t2, ($t0)
	addi $t0, $t0, 4
	player_erase_4:
	lw $k0, ($t0)
	beq $k0, $t1, player_erase_5
	sw $t2, ($t0)
	addi $t0, $t0, 4
	player_erase_5:
	lw $k0, ($t0)
	beq $k0, $t1, player_erase_6
	sw $t2, ($t0)
	addi $t0, $t0, 248
	player_erase_6:
	lw $k0, ($t0)
	beq $k0, $t1, player_erase_7
	sw $t2, ($t0)
	addi $t0, $t0, 4
	player_erase_7:
	lw $k0, ($t0)
	beq $k0, $t1, player_erase_8
	sw $t2, ($t0)
	addi $t0, $t0, 252
	player_erase_8:
	lw $k0, ($t0)
	beq $k0, $t1, player_erase_9
	sw $t2, ($t0)
	addi $t0, $t0, 4
	player_erase_9:
	lw $k0, ($t0)
	beq $k0, $t1, player_erase_10
	sw $t2, ($t0)
	addi $t0, $t0, 252
	player_erase_10:
	lw $k0, ($t0)
	beq $k0, $t1, player_erase_11
	sw $t2, ($t0)
	addi $t0, $t0, 4
	player_erase_11:
	lw $k0, ($t0)
	beq $k0, $t1, player_erase_12
	sw $t2, ($t0)
	player_erase_12:
	
	jr $ra

draw_player:	
	lw $s0, player_x
	lw $s1, player_y
	li $a0, 4
	lw $t0, display
	lw $t1, green
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
	lw $k0, ($t0)
	beq $k0, $t1, player_draw_1
	sw $t2, ($t0)
	addi $t0, $t0, 4
	player_draw_1:
	lw $k0, ($t0)
	beq $k0, $t1, player_draw_2
	sw $t2, ($t0)
	addi $t0, $t0, 248
	player_draw_2:
	lw $k0, ($t0)
	beq $k0, $t1, player_draw_3
	sw $t2, ($t0)
	addi $t0, $t0, 4
	player_draw_3:
	lw $k0, ($t0)
	beq $k0, $t1, player_draw_4
	sw $t2, ($t0)
	addi $t0, $t0, 4
	player_draw_4:
	lw $k0, ($t0)
	beq $k0, $t1, player_draw_5
	sw $t2, ($t0)
	addi $t0, $t0, 4
	player_draw_5:
	lw $k0, ($t0)
	beq $k0, $t1, player_draw_6
	sw $t2, ($t0)
	addi $t0, $t0, 248
	player_draw_6:
	lw $k0, ($t0)
	beq $k0, $t1, player_draw_7
	sw $t2, ($t0)
	addi $t0, $t0, 4
	player_draw_7:
	lw $k0, ($t0)
	beq $k0, $t1, player_draw_8
	sw $t2, ($t0)
	addi $t0, $t0, 252
	player_draw_8:
	lw $k0, ($t0)
	beq $k0, $t1, player_draw_9
	sw $t2, ($t0)
	addi $t0, $t0, 4
	player_draw_9:
	lw $k0, ($t0)
	beq $k0, $t1, player_draw_10
	sw $t2, ($t0)
	addi $t0, $t0, 252
	player_draw_10:
	lw $k0, ($t0)
	beq $k0, $t1, player_draw_11
	sw $t2, ($t0)
	addi $t0, $t0, 4
	player_draw_11:
	lw $k0, ($t0)
	beq $k0, $t1, player_draw_12
	sw $t2, ($t0)
	player_draw_12:
	
	jr $ra
	
	player_damage_effect:
		lw $t2, red
		sb $zero, taking_damage
	
		lw $t6, player_health
		subi $t6, $t6, 10
		sw $t6, player_health
		
		ble $t6, $zero, exit
	
		j continue_after_player_damage_effect
		
draw_door:
	move $t9, $ra
	jal calculate_coords
	move $ra, $t9
	
	addi $v0, $v0, 4
	sw $a0, 0($v0)
	addi $v0, $v0, 4
	sw $a0, 0($v0)
	addi $v0, $v0, 248
	sw $a0, 0($v0)
	addi $v0, $v0, 4
	sw $a0, 0($v0)
	addi $v0, $v0, 4
	sw $a0, 0($v0)
	addi $v0, $v0, 4
	sw $a0, 0($v0)
	addi $v0, $v0, 244
	sw $a0, 0($v0)
	addi $v0, $v0, 4
	sw $a0, 0($v0)
	addi $v0, $v0, 4
	sw $a0, 0($v0)
	addi $v0, $v0, 4
	sw $a0, 0($v0)
	addi $v0, $v0, 244
	sw $a0, 0($v0)
	addi $v0, $v0, 4
	sw $a0, 0($v0)
	addi $v0, $v0, 4
	sw $a0, 0($v0)
	addi $v0, $v0, 4
	sw $a0, 0($v0)
	addi $v0, $v0, 244
	sw $a0, 0($v0)
	addi $v0, $v0, 4
	sw $a0, 0($v0)
	addi $v0, $v0, 4
	sw $a0, 0($v0)
	addi $v0, $v0, 4
	sw $a0, 0($v0)
	
	jr $ra
	
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
	li $t2, 16
	lw $t1, item_stack_size
	mult $t1, $t2
	mflo $t2
	sub $sp, $sp, $t2

	# push to stack
	addi $sp, $sp, -4
	sw $a0, 0($sp)
	addi $sp, $sp, -4
	sw $a1, 0($sp)
	addi $sp, $sp, -4
	sw $a2, 0($sp)
	addi $sp, $sp, -4
	sw $a3, 0($sp)
	
	addi $t1, $t1, 1
	sw $t1, item_stack_size
	
	# find coord
	move $t9, $ra
	jal calculate_coords
	move $ra, $t9
	
	# draw
	sw $a0, ($v0)
	addi $v0, $v0, 4
	sw $a0, ($v0)
	addi $v0, $v0, 252
	sw $a0, ($v0)
	addi $v0, $v0, 4
	sw $a0, ($v0)

	jr $ra
	
init_enemy:
	# go to stack location
	lw $sp, base_stack_address
	lw $t1, platform_stack_size
	li $t2, 12
	mult $t1, $t2
	mflo $t2
	sub $sp, $sp, $t2
	li $t2, 16
	lw $t1, item_stack_size
	mult $t1, $t2
	mflo $t2
	sub $sp, $sp, $t2
	lw $t1, enemy_stack_size
	li $t2, 28
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
	
draw_player_bullet:
	lw $a1, player_x
	lw $a2, player_y
	lw $t3, yellow
	lw $t5, green
	li $t4, 63
	lw $t6, player_orientation
	
	draw_player_bullet_loop:
		jal calculate_coords
		lw $k0, 0($v0)
		beq $k0, $t5, skip_draw_player_bullet
		sw $t3, 0($v0)
		
		skip_draw_player_bullet:
		add $a1, $a1, $t6
		bge $a1, $t4, continue_after_draw_player_bullet
		ble $a1, $zero, continue_after_draw_player_bullet
		
		li $v0, 32
		li $a0, 1
		syscall
		
		j draw_player_bullet_loop
		
erase_player_bullet:
	lw $a1, player_x
	lw $a2, player_y
	lw $t3, black
	lw $t5, green
	li $t4, 63
	lw $t6, player_orientation
	
	erase_player_bullet_loop:
		jal calculate_coords
		lw $k0, 0($v0)
		beq $k0, $t5, skip_erase_player_bullet
		sw $t3, 0($v0)
		
		skip_erase_player_bullet:
		add $a1, $a1, $t6
		bge $a1, $t4, continue_after_erase_player_bullet
		ble $a1, $zero, continue_after_erase_player_bullet
		sw $zero, player_shooting
		
		li $v0, 32
		li $a0, 1
		syscall
		
		j erase_player_bullet_loop
	
init_bullet:
	# go to stack location
	lw $sp, base_stack_address
	lw $t1, platform_stack_size
	li $t2, 12
	mult $t1, $t2
	mflo $t2
	sub $sp, $sp, $t2
	li $t2, 16
	lw $t1, item_stack_size
	mult $t1, $t2
	mflo $t2
	sub $sp, $sp, $t2
	lw $t1, enemy_stack_size
	li $t2, 28
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
	move $ra, $t8
	
	lw $t0, green
	lw $s0, 0($v0)
	beq $t0, $s0, skip_draw_bullet
	lw $t0, yellow
	beq $t0, $s0, skip_draw_bullet
	
	sw $a0, 0($v0)
	
	skip_draw_bullet:
	jr $ra
	
key_W:
	lb $a1, player_targettable
	beq $zero, $a1, after_keypress
	
	lw $t1, jump_counter
	li $t2, 1
	bgt $t1, $t2, after_keypress
	addi $t1, $t1, 1
	sw $t1, jump_counter

   	li $a1, 0
   	sw $a1, landed
   	
   	lw $a1, jump_force
   	sw $a1, player_delta_y
   	
	b after_keypress

key_A:
	lb $a1, player_targettable
	beq $zero, $a1, after_keypress
	
	lw $a1, player_x
	lw $a2, player_speed
	sub $a1, $a1, $a2
#	subi $a1, $a1, 2
   	sw $a1, player_x
   	
   	li $a1, -1
   	sw $a1, player_orientation
	
	b after_keypress

key_D:
	lb $a1, player_targettable
	beq $zero, $a1, after_keypress
	
	lw $a1, player_x
	lw $a2, player_speed
	add $a1, $a1, $a2
#	addi $a1, $a1, 2
   	sw $a1, player_x
   	
   	li $a1, 1
   	sw $a1, player_orientation
   	
	b after_keypress
	
key_P:
	jal clear_screen
	
	b main
	
key_E:
	lb $a2, landed
	beq $a2, $zero, after_keypress

	lb $a1, player_targettable
	beq $zero, $a1, after_keypress
	
	li $a2, 1
	sw $a2, player_shooting
	
	b after_keypress
	
key_Q:
	lb $a1, player_targettable
	beq $a1, $zero, set_to_one
	
	sb $zero, player_targettable
	
	b after_keypress
	
	set_to_one:
	li $a2, 1
	sb $a2, player_targettable
	
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
	jal check_platform_stack
	jal check_item_stack
	jal check_enemy_stack
	jal check_bullet_stack
	
	j continue_after_player_hitbox

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
   	sb $a2, landed
	blt $a3, $a2, continue_after_player_y_pb
	
   	sw $zero, air_time
   	sw $zero, player_delta_y
   	sw $zero, jump_counter
	
	j continue_after_player_y_pb

check_platform_stack:
	# go to stack location
	lw $sp, base_stack_address
	lw $t1, platform_stack_size
	li $t2, 12
	mult $t1, $t2
	mflo $t2
	sub $sp, $sp, $t2
	sw $sp, current_stack_address
	
	# load player variables
	lw $s0, player_x
	lw $s1, player_y
	lw $t4, platform_stack_size
	lw $t2, player_width
	lw $t3, player_height
	move $s4, $sp
	
	li $t6, 58
	bge $s1, $t6, skip_platform_check
	
	lw $t6, player_delta_y
	blt $t6, $zero, skip_platform_check

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
	bgt $t4, $zero, check_stack_loop
	
	b no_longer_standing_on_platform
	
	skip_platform_check:
	jr $ra
	
stand_on_platform:		
	sub $s4, $a2, $t3
	sw $s4, player_y
	
   	sw $zero, air_time
   	sw $zero, player_delta_y
   	sw $zero, jump_counter
   	
   	li $t1, 1
   	sb $t1, landed
	
	jr $ra
	
no_longer_standing_on_platform:
	li $t1, 63
	lw $t2, player_y
	beq $t1, $t2, skip_stop_standing_on_platform
	
	sw $zero, landed
	
	skip_stop_standing_on_platform:
	jr $ra
	
check_item_stack:	
	# go to stack location
	lw $sp, current_stack_address
	li $t2, 16
	lw $t1, item_stack_size
	mult $t1, $t2
	mflo $t2
	sub $sp, $sp, $t2
	sw $sp, current_stack_address
	
	lw $s2, purple
	lw $s3, gray
	lw $s4, blue
	
	# loop
	check_item_stack_loop:
	lw $a3, 0($sp) 		# active/inactive
	move $t5, $sp
	addi $sp, $sp, 4
	lw $a2, 0($sp) 		# y
	addi $sp, $sp, 4
	lw $a1, 0($sp) 		# x
	addi $sp, $sp, 4
	lw $a0, 0($sp) 		# color
	addi $sp, $sp, 4
	
	subi $t1, $t1, 1
	
	beq $a3, $zero, skip_item_conditions
	
	# load player coords
	lw $s0, player_x
	lw $s1, player_y
	addi $s1, $s1, 3
	
	bne $a1, $s0, skip_item_conditions
	bne $a2, $s1, skip_item_conditions
	
	sw $zero, 0($t5)
	
#	b print
	continue_after_print:
	
	beq $a0, $s2, purple_item
	beq $a0, $s3, gray_item
	beq $a0, $s4, blue_item
	
	skip_item_conditions:
	bgt $t1, $zero, check_item_stack_loop
	
	jr $ra
	
	purple_item:
		lw $t4, jump_force
		subi $t4, $t4, 2
		sw $t4, jump_force
		j skip_item_conditions
		
	gray_item:
		li $t4, 30
		sw $t4, player_health
		j skip_item_conditions
		
	blue_item:
		lw $t4, player_speed
		addi $t4, $t4, 2
		sw $t4, player_speed
		j skip_item_conditions
	
check_enemy_stack:
	# go to stack location
	lw $sp, current_stack_address
	lw $t4, enemy_stack_size
	li $t2, 28
	mult $t4, $t2
	mflo $t2
	sub $sp, $sp, $t2
	sw $sp, current_stack_address
	
	# loop
	check_enemy_stack_loop:
	lw $s6, 0($sp)		# shoot_cd
	move $t5, $sp
	addi $sp, $sp, 4
	lw $s5, 0($sp)		# direction
	move $fp, $sp
	addi $sp, $sp, 4
	lw $k1, 0($sp)		# active/inactive
	move $s0, $sp
	addi $sp, $sp, 4
	lw $k0, 0($sp)		# upper move limit
	addi $sp, $sp, 4
	lw $a3, 0($sp)		# lower move limit
	addi $sp, $sp, 4
	lw $a2, 0($sp)		# y
	addi $sp, $sp, 4
	lw $a1, 0($sp)		# x
	addi $sp, $sp, 4
	
	subi $t4, $t4, 1
	
	beq $a3, $zero, skip_all_enemy_conditions
	beq $k1, $zero, skip_inactive_enemy

	# check if player has shot enemy	
	lw $t3, player_shooting
	li $t2, 3
	bne $t3, $t2, skip_shot_check
	blt $s1, $a2, skip_shot_check
	lw $t3, player_height
	add $t3, $t3, $a2
	bgt $s1, $t3, skip_shot_check
	
	lw $t3, player_orientation
	bgt $t3, $zero, player_shot_right
	b player_shot_left
	
	skip_shot_check:

	# check for collision with player
	lw $s0, player_x
	lw $s1, player_y
	lw $t2, player_width
	lw $t3, player_height
	
	add $t6, $s1, $t3
	blt $t6, $a2, skip_all_enemy_conditions
	add $t6, $a2, $t3
	bgt $s1, $t6, skip_all_enemy_conditions
	add $t6, $s0, $t2
	blt $t6, $a1, skip_all_enemy_conditions
	add $t6, $a1, $t2
	ble $s0, $t6, enemy_collision
	
	skip_all_enemy_conditions:
	
	# shoot at player if on same y plane and player is targettable
	bgt $s6, $zero, decrease_shoot_cd
	bne $a2, $s1, skip_shoot_at_player
	lb $t6, player_targettable
	beq $t6, $zero, skip_shoot_at_player
	
	# reset shoot cd
	li $s6, 30
	sw $s6, 0($t5)
	
	li $a3, 2
	li $k0, 30
	lw $a0, red
	li $k1, 1
	li $v1, 0
	
	blt $s0, $a1, set_bullet_direction_left
	continue_after_set_bullet_direction:
	
	move $t7, $ra
	jal init_bullet
	move $ra, $t7
	
	j skip_inactive_enemy
	
	skip_shoot_at_player:
	
	# move enemy
	move $t7, $ra
	jal move_enemy
	move $ra, $t7
	
	skip_inactive_enemy:
	
	bgt $t4, $zero, check_enemy_stack_loop
	
	jr $ra
	
	set_bullet_direction_left:
		li $t1, -1
		mult $a3, $t1
		mflo $a3
		j continue_after_set_bullet_direction
	
	decrease_shoot_cd:
		subi $s6, $s6, 1
		sw $s6, 0($t5)
		j skip_inactive_enemy
		
	player_shot_right:
		lw $s1, player_x
		bgt $a1, $s1, set_enemy_to_inactive
		j skip_shot_check
	
	player_shot_left:
		lw $s1, player_x
		blt $a1, $s1, set_enemy_to_inactive
		j skip_shot_check
		
	set_enemy_to_inactive:
		sw $zero, 0($s0)
	
		lw $a0, black
		
		move $t7, $ra
		jal draw_enemy
		move $ra, $t7
		
		j skip_inactive_enemy
	
check_bullet_stack:
	# load player variables
	lw $s0, player_x
	lw $s1, player_y
	lw $t4, bullet_stack_size
	li $s3, 64
	
	beq $t4, $zero, empty_bullet_stack
	
	# go to stack location
	lw $sp, current_stack_address
	lw $t1, bullet_stack_size
	li $t2, 28
	mult $t1, $t2
	mflo $t2
	sub $sp, $sp, $t2
	sw $sp, current_stack_address
	
	# loop
	check_bullet_stack_loop:
	lw $s5, 0($sp)		# type
	addi $sp, $sp, 4
	lw $k1, 0($sp)		# active/inactive
	move $s7, $sp
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
	
	beq $k1, $zero, skip_inactive_bullet
	
	ble $a1, $zero, set_bullet_to_inactive
	beq $a1, $s3, set_bullet_to_inactive
	beq $k0, $zero, set_bullet_to_inactive
	beq $k1, $zero, skip_inactive_bullet
	
	# check for collision with player
	lw $t2, player_targettable
	beq $t2, $zero, continue_after_check_collision
	
	lw $t2, player_width
	lw $t3, player_height
	
	blt $a2, $s1, continue_after_check_collision
	add $t6, $s1, $t3
	bgt $a2, $t6, continue_after_check_collision
	blt $a1, $s0, continue_after_check_collision
	add $t6, $s0, $t2
	ble $a1, $t6, take_damage
	
	continue_after_check_collision:
	
	# move bullet
	move $t7, $ra
	jal move_bullet
	move $ra, $t7	
	
	skip_inactive_bullet:
	
	bgt $t4, $zero, check_bullet_stack_loop
	
	empty_bullet_stack:
	
	jr $ra
		
	set_bullet_to_inactive:
		move $t7, $ra
		
		sw $zero, 0($s7)
		lw $a0, black
		jal draw_bullet
		
		move $ra, $t7	
		j skip_inactive_bullet
	
	take_damage:	
		li $t6, 1
		sb $t6, taking_damage
		j set_bullet_to_inactive
	
move_enemy:
	beq $a1, $k0, flip
	beq $a1, $a3, flip
	continue_after_flip:

	move $s7, $ra
	
	lw $a0, black
	jal draw_enemy
	
	add $a1, $a1, $s5
	
	lw $a0, red
	subi $sp, $sp, 4
	jal draw_enemy
	sw $a1, 0($sp)
	addi $sp, $sp, 4
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
	
	lw $a0, red
	jal draw_bullet
	sw $a1, 0($v1)
	
	move $ra, $s7
	
	stop_drawing_bullet:
	jr $ra
	
enemy_collision:	
	lw $t1, x0
	lw $t2, y0
	sw $t1, player_x
	sw $t2, player_y
	
	li $t1, 1
	sb $t1, player_targettable
	
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
	move $t6, $a0
	
	li $v0, 1
   	move $a0, $t6
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
   	move $a0, $s0
 	syscall
 	
 	li $v0, 4
 	la $a0, comma
 	syscall
 	
 	li $v0, 1
   	move $a0, $s1
 	syscall
 	
 	li $v0, 4
 	la $a0, newline
 	syscall
 
 	j continue_after_print

exit:
	li $v0, 10 
	syscall
