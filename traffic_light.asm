#mask for interrupt
.eqv EXT_INTTIME 0x400
.eqv EXT_INTBUTTON 0x800
.eqv EXCHMASK 0x003c

#for IO
.eqv WALKLIGHT 0xFFFF0010
.eqv DRIVLIGHT 0xFFFF0011
.eqv BUTTONADR 0xFFFF0013
.eqv ENABLE_TIMER_ADR 0xFFFF0012


#Mask for values
.eqv WALK_BUTTON 0x01
.eqv DRIV_BUTTON 0x02
.eqv ENABLE_TIMER 0x01


#For lights
.eqv RED 0x01
.eqv GREEN 0x04
.eqv YELLO 0x02
.eqv DARK 0x00
.eqv WALK 0x02
.eqv STOP 0x01

.data
knapp: .word 0
nyrad:.asciiz "\n"
utskrift: .asciiz "knapptryck"
raknare: .word 0
.ktext 0x80000180
la $k0, int_routine
jr $k0
.text
.globl main
main:
mfc0 $t0, $12 #Status register
nop
ori $t0, $t0, 1 #enable user interrupts
ori $t0, $t0, EXT_INTTIME
ori $t0, $t0, EXT_INTBUTTON
mtc0 $t0, $12 #update status registry
la $t0, DRIVLIGHT
add $a0, $zero, GREEN # satter trafikljus till grön
sb $a0, 0x0($t0)
la $t0, WALKLIGHT
add $a0, $zero, STOP # satter ganvagen till röd
sb $a0, 0x0($t0)
la $t0, ENABLE_TIMER_ADR
add $a0, $zero, 0x01
sb $a0, 0x0($t0)

L1:
b L1
li $v0, 10
syscall

orangeljus:
la $t0, DRIVLIGHT
add $a0, $zero, YELLO # satter trafikljus till gul
sb $a0, 0x0($t0)
lw $t0, raknare
jr $ra

skifta1:
la $t0, DRIVLIGHT
add $a0, $zero, RED # satter trafikljus till röd
sb $a0, 0x0($t0)
la $t0, WALKLIGHT
add $a0, $zero, WALK # satter gangvag till grön
sb $a0, 0x0($t0)
jr $ra

skifta2:
la $t0, DRIVLIGHT
add $a0, $zero, YELLO # satter trafikljus till gul
sb $a0, 0x0($t0)
la $t0, WALKLIGHT # satter gangvag till röd
add $a0, $zero, STOP
sb $a0, 0x0($t0)
jr $ra


rodtrafikljus:
la $t0, WALKLIGHT
add $a0, $zero, STOP # satter ganvag till röd
sb $a0, 0x0($t0)
jr $ra
stangav:
la $t0, WALKLIGHT
add $a0, $zero, DARK # satter gangvag till svart
sb $a0, 0x0($t0)
jr $ra

skifta3:
la $t0, WALKLIGHT
add $a0, $zero, STOP # satter gangvag till röd
sb $a0, 0x0($t0)
la $t0, DRIVLIGHT
add $a0, $zero, GREEN # satter trafikljus till grön
sb $a0, 0x0($t0)

li $t0, 0 # aterstaller register t0 , genom att placera nolla pa den
sw $t0, knapp # laddar upp knapp i t0
sw $t0, raknare # laddar upp raknare i t0
jr $ra # hoppar tillbaka till returadressen
int_routine: # avbrottsrutinen börjar
subu $sp,$sp, 72 # reserverar utrymme i stacken
sw $t0, 68($sp)
sw $a0, 64($sp)


sw $a1, 60($sp)
sw $v0, 56($sp)

lw $t0,raknare # placerar raknare i t0 register
beq $t0,10, hoppaover # kollar ifall raknare = 10, om sant, hoppa till hoppaöver, annars stanna
add $t0,$t0, 1 # raknare++
sw $t0, raknare # spara raknare+=1 i t1
b L2 # branchar till L2

hoppaover:
lw $t2, knapp # laddar upp knapp i register t2
lw $t0, raknare # laddar upp raknare i t0
beq $t2, 1, t # kollar ifall knapp=1, da hoppa till t, annars stanna
b L2
t:
jal orangeljus # jump and link med subrutinen orangeljust
lw $t0, raknare # laddar upp raknare i t0
addi $t0, $t0, 1 # raknare++
sw $t0, raknare # spara raknare++ i t1

L2:
bne $t0, 14, if # ifall raknare != 14, hoppa till if, annars stanna
jal skifta1 # da rknare=21, jump and link skifta2
if:
bne $t0, 21, if2 # ifall raknare != 21, hoppa till if2, annars stanna
jal skifta2 # da raknare=21, jump and link skifta2
if2:
bne $t0, 22, if3 # ifall raknare !=22, hoppa till if3, annars stanna


jal stangav # da raknare=22, jump and link stangav
if3:
bne $t0, 23, if4 # ifall raknare !=23, hoppa till if4, annars stanna
jal rodtrafikljus # da raknare=23, jump and link rodtrafikljus
if4:
bne $t0, 24, if5 # ifall raknare !=24, hoppa till if4, annars stanna
jal stangav # da raknare=24, jump and stangav
if5:
bne $t0, 25, ex # ifall raknare !=25, hoppa till if4, annars stanna
jal skifta3 # da raknare=25, jump and link skifta3
ex:
mfc0 $k0, $13
nop
andi $t0, $k0, EXCHMASK
bne $t0, $zero, goback
andi $t0, $k0, EXT_INTBUTTON
beq $t0, $zero, goback
k:
la $t0, BUTTONADR
lb $a1, 0x0($t0)
beq $a1, WALK_BUTTON, knappreg1
j goback


knappreg1:
li $t0, 1
sw $t0, knapp # registrerar knapptrycket
li $v0,4
la $a0, utskrift
syscall
li $v0,4
la $a0,nyrad
syscall
#jal goback
mtc0 $zero, $13
lw $t0, 68($sp)
lw $a0, 64($sp)
lw $a1, 60($sp)
lw $v0, 56($sp)
goback:
mtc0 $zero, $13 #kvittera interrupt
#andi $t0, $k0, 0xFFFFF7FF
#mtc0 $t0, $13
addu $sp, $sp, 72 #≈terst‰llning
eret
#.end int_routine






