.data
    visit: .space 301 * 4
    matrix: .space  301 * 301 * 4
    queue: .space 301 * 4
    queue_history: .space 301 * 4
    space: .asciiz " "
    newline: .asciiz "\n"


.text
    main:
        #Get the value of the N, N, V using syscall with code 5, and store them in $s0, $s1, $s2
        li $v0, 5           
        syscall             
        move $s0, $v0                           

        li $v0, 5          
        syscall 
        move $s1, $v0             

        li $v0, 5         
        syscall
        move $s2, $v0  

        la $s3, visit      #get the base of the visit
        li $t0, 0          #t0 is going to be a counter, i=1

    #Fill the visit array with zeros for now
    fill_visit:
        #Compare i to N
        bgt  $t0, $s0, end_fill_visit       #if (i>N), then break the loop
                           
        mul $t1, $t0, 4                     #calculate the shift according to i value
        add $t1, $s3, $t1                   #address of the visit[i]

        sw $zero, 0($t1)                    #visit[i]=0

        addi $t0, $t0, 1                    #i++
        j fill_visit

    end_fill_visit:
        la $s5, queue_history      #get the base of the queue_history
        li $t0, 0                  #t0 is going to be a counter, i=1

    #Fill the queue_history array with zeros for now
    fill_queue_history:
        #Compare i to N
        bgt  $t0, $s0, end_fill_queue_history   #if (i>N), then break the loop
                           
        mul $t1, $t0, 4                         #calculate the shift according to i value
        add $t1, $s5, $t1                       #address of the queue_history[i]

        sw $zero, 0($t1)                        #queue_history[i]=0

        addi $t0, $t0, 1                        #i++
        j fill_queue_history

    end_fill_queue_history:
        la $s4, matrix      #Get the base of the matrix
        li $t0, 1           #t0 is the counter for the row, i=1

    #Fill the adj. matrix with zeros for now
    fill_matrix:
        bgt  $t0, $s0, end_fill_matrix       #if (i>N), start populating adj.matrix

        mul $t1, $t0, 1204                       #calculate the shift for the row, 301x4 = 1204
        add $t1, $s4, $t1                        #get the base of the row

        li $t2, 1                                #Reset j value to 1
    j_loop:
        bgt  $t2, $s0, end_j_loop       #if (k>N), then break the loop

        mul $t3, $t2, 4                          #calculate the shift for the col
        add $t3, $t1, $t3                        #get the address of matrix[i][j], which is base row + col shift

        sw $zero, 0($t3)                         #matrix[i][j]=0

        addi $t2, $t2, 1                         #j++
        j j_loop

    end_j_loop:
        addi $t0, $t0, 1                         #i++
        j fill_matrix

    #Populate the adj. matrix
    end_fill_matrix: 
        li $t0, 0                                #Loop counter, i=0
        li $s7, 1                                #save 1 in register

    populate_matrix:
        bge  $t0, $s1, end_populate_matrix       #if (i>=M), then break the loop
        
        #Get the values of two vertexes
        li $v0, 5          
        syscall  
        move $t2, $v0

        li $v0, 5          
        syscall  
        move $t3, $v0   

        mul $t4, $t2, 1204
        add $t4, $s4, $t4      #Get the base of the row

        mul $t5, $t3, 4        #calculate the shift for the col
        add $t5, $t4, $t5                       

        sw $s7, 0($t5)         #matrix[vert_1][vert_2] = 1

        mul $t4, $t3, 1204
        add $t4, $s4, $t4 

        mul $t5, $t2, 4                         
        add $t5, $t4, $t5

        sw $s7, 0($t5)         #matrix[vert_2][vert_1] = 1

        addi $t0, $t0, 1                         #i++
        j populate_matrix
    
    end_populate_matrix:
        #call DFS with V as an argument    
        move $a0, $s2         
        jal DFS   

        li $v0, 4              
        la $a0, newline          
        syscall 

        la $s6, queue

        sw $s2, 0($s6)    #queue[0]=V

        mul $t0, $s2, 4
        add $t0, $s5, $t0  #get the address of queue_history[V]

        sw $s7, 0($t0)    #queue_history[V]=1

        move $a0, $zero   #que_l = 0
        move $a1, $s7      #que_r = 1 

        #call DFS with que_l=0, que_r=1
        jal BFS

        li $v0, 4              
        la $a0, newline          
        syscall 

        li $v0, 10       
        syscall




    DFS:
        addi $sp, $sp, -12
        sw $ra, 8($sp)       #save return address
        sw $t1, 4($sp)       #save the address of the matrix[vert]
        sw $t2, 0($sp)       #save the counter for the loop     

        move $t0, $a0

        li $v0, 1            #Print the int, vert is already in $a0
        syscall              #Print the result

        li $v0, 4              
        la $a0, space          
        syscall              #Print space   

        mul $t1, $t0, 4
        add $t1, $s3, $t1    #Get the address of visit[vert]
             
        sw $s7, 0($t1)       #visit[vert]=1
        
        mul $t1, $t0, 1204
        add $t1, $s4, $t1    #get the base of the matrix[vert]

        li $t2, 1            #i=1
    
    iterate_visit:
        #Compare i to N
        bgt $t2, $s0, end_iterate_visit       #if (i>N), then break the loop                     

        mul $t3, $t2, 4                    
        add $t3, $t1, $t3                  #calc the shift of matrix[vert][i]

        lw $t4, 0($t3)                     #get the value of matrix[vert][i]
        beq $t4, $zero, next_iteration     #if matrix[vert][i]==0, then next iteration

        mul $t3, $t2, 4
        add $t3, $s3, $t3                  #calc the shift of visit[i]

        lw $t4, 0($t3)                     #get the value of visit[i]
        beq $t4, $s7, next_iteration       #if matrix[visit]==1, then next iteration

        #recursive call of the DFS with argument of i
        move $a0, $t2                      
        jal DFS
        j next_iteration                   

    next_iteration:
        addi $t2, $t2, 1      #i++
        j iterate_visit

    #Populate the adj. matrix with zeros for now
    end_iterate_visit:
        lw $t2, 0($sp)         #Get the i value back
        lw $t1, 4($sp)         #Get the argument back
        lw $ra, 8($sp)         #Get the return address back
        addi $sp, $sp, 12      #Change the stack pointer

        jr $ra                 #Return










    BFS:
        addi $sp, $sp, -4
        sw $ra, 0($sp)             #save return address

        move $t0, $a0              #i=que_l
        move $t1, $a1              #new_que_r = que_r


    iterate_queue:
        bge $t0, $a1, end_iterate_queue

        mul $t2, $t0, 4
        add $t2, $s6, $t2          #the address of queue[i]

        lw $t2, 0($t2)             #vert = queue[i]

        li $v0, 1
        move $a0, $t2              
        syscall                

        li $v0, 4              
        la $a0, space          
        syscall                

        mul $t2, $t2, 1204
        add $t2, $s4, $t2      #get the base of the matrix[vert]   

        li $t3, 1              #j=1

    iterate_edges:
        #Compare j to N
        bgt $t3, $s0, next_queue       #if (i>N), then break the loop                      

        mul $t4, $t3, 4                    
        add $t4, $t2, $t4                  #calc the shift of matrix[vert][j]

        lw $t4, 0($t4)                     #get the value of matrix[vert][i]
        beq $t4, $zero, next_edge          #if matrix[vert][j]==1

        mul $t4, $t3, 4
        add $t4, $s5, $t4                  #calc the address of queue_history[j]

        lw $t4, 0($t4)                     #get the value of queue_address[i]
        beq $t4, $s7, next_edge
        
        mul $t4, $t1, 4
        add $t4, $s6, $t4          #the address of queue[new_que_r]

        sw $t3, 0($t4)             #queue[new_que_r] = j

        mul $t4, $t3, 4
        add $t4, $s5, $t4          #the address of queue_history[j]

        sw $s7, 0($t4)             #queue_history[j] = 1
        
        addi $t1, $t1, 1           #new_que_r++
        j next_edge           

    next_edge:
        addi $t3, $t3, 1      #j++
        j iterate_edges
    
    next_queue:
        addi $t0, $t0, 1      #i++
        j iterate_queue
    
    end_iterate_queue:
        beq $a1, $t1, end_BFS

        move $a0, $a1
        move $a1, $t1
        jal BFS
    
    end_BFS:
        lw $ra, 0($sp)         #Get the return address back
        addi $sp, $sp, 4       #Change the stack pointer
        jr $ra