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
display: .word 0x10008000

player_x: .word 4
player_y: .word 5
player_width: .word 3
player_height: .word 4
player_delta_y: .word 0
x0: .word 0
y0: .word 0
landed: .byte 1
air_time: .word 0

stack_size: .word 0

.globl main
#.eqv display 0x10008000
.text
main:
	# $t2 stores key input
	li $t2, 0x000000
	
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

	b game_loop
	
game_loop:
	# t0:exit condition ; t2-3: display ; t4-5: player ; t8,9: keypress

	#player stuff
	lw $t4, player_x
	lw $t5, player_y
	lw $t6, x0
	lw $t7, y0

#	draw player
	jal erase_player
	jal display_player
	
	# store previous player location
	lw $a1, player_x
	sw $a1, x0
	lw $a1, player_y
	sw $a1, y0

	# keypress stuff
	li $v1, 1
	li $t9, 0xffff0000
	lw $t8, 0($t9)
	beq $t8, 1, handle_keypress

	# if t0 is 1, end program
	beq $t0, $v1, exit

	bne $t0, $v1, sleep_in_main

player_gravity:
	li $s0, 2
	lw $a1, air_time
	bgt $a1, $s0, skip_add_time
	
	addi $a1, $a1, 1
   	sw $a1, air_time
   	
   	skip_add_time:
   	
   	lw $a3, player_delta_y
   	add $a3, $a3, $a1
   	sw $a3, player_delta_y
   	
   	lw $a2, player_y
	add $a2, $a2, $a3 
   	sw $a2, player_y
   	
   	j continue_after_player_gravity

land:
	li $a0, 0
   	sw $a0, air_time
   	sw $a0, player_delta_y
   	
   	li $a0, 1
   	sb $a0, landed
   	
   	j continue_after_land

erase_player:
	li $a0, 4
	lw $t0, display
	lw $t1, black
	
	mult $t6, $a0
	mflo $a1
	add $t0, $t0, $a1
	
	li $a0, 256
	mult $t7, $a0
	mflo $a1
	add $t0, $t0, $a1
	
	sw $t1, ($t0)
	
	jr $ra

display_player:	
	li $a0, 4
	lw $t0, display
	lw $t1, red
	lw $t2, green
	lw $t3, blue
	
	mult $t4, $a0
	mflo $a1
	add $t0, $t0, $a1
	
	li $a0, 256
	
	mult $t5, $a0
	mflo $a1
	add $t0, $t0, $a1
	
	sw $t2, ($t0)
	
	jr $ra
	
handle_keypress:
	# listen to key input
	lw $t2, 4($t9)
	
	beq $t2, 0, sleep_in_main
	beq $t2, 0x77, key_W
	beq $t2, 0x61, key_A
	beq $t2, 0x73, key_S
	beq $t2, 0x64, key_D
	
draw_platform:	
	# push coords of each platform to stack
	addi $sp, $sp, -4
	sw $a1, 0($sp)
	addi $sp, $sp, -4
	sw $a2, 0($sp)
	addi $sp, $sp, -4
	sw $a3, 0($sp)
	
	lw $s1, stack_size
	addi $s1, $s1, 1
	sw $s1, stack_size
	
	# actual drawing	
	lw $t0, display
	li $t2, 4
	
	mult $a1, $t2
	mflo $t1
	add $t0, $t0, $t1
	
	li $t2, 256
	
	mult $a2, $t2
	mflo $a2
	add $t0, $t0, $a2
	
	platform1_loop:
	sw $a0, ($t0)
	
	addi $t0, $t0, 4
	addi $a1, $a1, 1
	
	blt $a1, $a3, platform1_loop
	
	jr $ra
	
key_W:
   	li $a1, 0
   	sw $a1, landed
   	
   	li $a1, -10
   	sw $a1, player_delta_y
   	
	b sleep_in_main

key_A:
	lw $a1, player_x
	subi $a1, $a1, 2
   	sw $a1, player_x
	
	b sleep_in_main

key_S:
	lw $a1, player_y
	addi $a1, $a1, 2 
   	sw $a1, player_y

	b sleep_in_main

key_D:	
	lw $a1, player_x
	addi $a1, $a1, 2
   	sw $a1, player_x
   	
	b sleep_in_main

sleep_in_main:
	# gravity
	li $a0, 0
	lb $a1, landed
	beq $a0, $a1, player_gravity
	continue_after_player_gravity:

	li $v0, 32
	li $a0, 70
	
	#reset key input from last cycle
	li $t2, 0
	syscall
	
	b player_hitbox
	continue_after_player_hitbox:
	
	b game_loop
	
player_hitbox:
	li $a0, 0
	li $a1, 63
	lw $t4, player_x
	lw $t5, player_y
	
	blt $t4, 0, player_x_nb
	continue_after_player_x_nb:
	bgt $t4, 63, player_x_pb
	continue_after_player_x_pb:
	blt $t5, 0, player_y_nb
	continue_after_player_y_nb:
	bgt $t5, 63, player_y_pb	
	continue_after_player_y_pb:
	
	jal check_platform_stack
	
	j continue_after_player_hitbox

player_x_nb:
	sw $a0, player_x
	j continue_after_player_x_nb
	
player_x_pb:
	sw $a1, player_x
	j continue_after_player_x_pb
	
player_y_nb:
	sw $a0, player_y
	j continue_after_player_y_nb
	
player_y_pb:
	sw $a1, player_y
	
	li $a2, 2
	lw $a3, air_time
	blt $a3, $a2, continue_after_player_y_pb
	
	b land
	continue_after_land:
	
	j continue_after_player_y_pb

check_platform_stack:
	# t4 = player_x, t5 = player_y
	lw $s0, stack_size
	li $s1, 0
	lw $s2, player_width
	lw $s3, player_height
	move $s4, $sp

	check_stack_loop:
	lw $a1, 0($s4)
	addi $s4, $s4, 4
	lw $a2, 0($s4)
	addi $s4, $s4, 4
	lw $a3, 0($s4)
	addi $s4, $s4, 4
	
	subi $s0, $s0, 1
	
	add $zero, $t5, $s3
	ble $a2, $zero, skip_all_conditions
	bge $a2, $t5, skip_all_conditions
	add $zero, $t4, $s2
	ble $zero, $a1, skip_all_conditions
	ble $zero, $a3, stand_on_platform
	
	skip_all_conditions:
	bgt $s0, $s1, check_stack_loop
	
	continue_after_stand_on_platform:
	jr $ra
	
stand_on_platform:
	b print_coords
	continue_after_printing_coords:
	
	add $s4, $t5, $a2
	sw $s4, player_y
	
	j continue_after_stand_on_platform
	
print_coords:
	li $v0, 4
 	la $a0, bracket
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
 	la $a0, comma
 	syscall
 	
 	li $v0, 1
   	lw $a0, player_delta_y
 	syscall
 	
 	li $v0, 4
 	la $a0, comma
 	syscall
 	
 	li $v0, 1
   	lw $a0, air_time
 	syscall
 	
 	li $v0, 4
 	la $a0, bracket0
 	syscall
 	
 	li $v0, 4
 	la $a0, newline
 	syscall
 	
 	j continue_after_printing_coords

exit:
	li $v0, 10 
	syscall
