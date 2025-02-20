############### TRABAJO PRACTICO MIPS LUCAS SELLART ###############

############### Estructura de datos en assembly del MIPS R2000 ####

 .macro print_label (%label)
 la $a0, %label	# Dirección de texto (mensaje)
 li $v0, 4
 syscall
 .end_macro

 .macro print_error (%error)
 print_label(error)		# Imprime "Error: "
 li $a0, %error
 li $v0, 1
 syscall			# Imprime el número del error
 print_label(return)		# Imprime un salto de línea
 .end_macro
 
 	.data
 slist:	.word 0	# Puntero a lista de memoria liberada
 cclist: 	.word 0	# Puntero a lista de categorías
 wclist: 	.word 0	# Puntero a lista actualmente seleccionada
 schedv: 	.space 32	# Vector de funciones
 objId: 	.word 0	# Variable que almacena el ID del objeto a crear
 menu:	.ascii "Colecciones de objetos categorizados\n"
	.ascii "====================================\n"
	.ascii "1-Nueva categoria\n"
	.ascii "2-Siguiente categoria\n"
	.ascii "3-Categoria anterior\n"
	.ascii "4-Listar categorias\n"
	.ascii "5-Borrar categoria actual\n"
	.ascii "6-Anexar objeto a la categoria actual\n"
	.ascii "7-Listar objetos de la categoria\n"
	.ascii "8-Borrar objeto de la categoria\n"
	.ascii "0-Salir\n"
	.asciiz "Ingrese la opcion deseada: "
	
 dospuntos: .asciiz ": "
 marca: ">"
 ErrorNotFound: .asciiz "Not found\n"
 Id: .asciiz "ID "
 mensaje_listadoCats: .asciiz "Listado de categorias: \n"
 mensaje_listadoObjs: .asciiz "Listado de objetos de la categoria: "
 mensaje_categoriaNoVacia: .asciiz "La categoria tiene objetos, debes eliminarlos primero\n"
 error:	.asciiz "Error: "
 return:	.asciiz "\n"
 catName:.asciiz "\nIngrese el nombre de una categoria: "
 selCat:	.asciiz "\nSe ha seleccionado la categoria:"
 idObj:	.asciiz "\nIngrese el ID del objeto a eliminar: "
 objName:.asciiz "\nIngrese el nombre de un objeto: "
 success:.asciiz "La operacion se realizo con exito\n\n"
 
 .text
 main:
	# initialization scheduler vector
	la $t0, schedv
	la $t1, newcaterogy		# Crear nueva categoría
	sw $t1, 0($t0)
	la $t1, nextcategory		# Selecciona sig. categoría
	sw $t1, 4($t0)
	la $t1, prevcaterogy		# Selecciona categoría anterior
	sw $t1, 8($t0)
	la $t1, listcategories		# Imprime todas las categorías
	sw $t1, 12($t0)
	la $t1, delcaterogy		# Elimina la categoría actual
	sw $t1, 16($t0)
	la $t1, newobject		# Agg. un objeto a la categoría actual
	sw $t1, 20($t0)
	la $t1, listobjects		# Imprime los objetos dentro de la cat. actual
	sw $t1, 24($t0)
	la $t1, delobject		# Elimina un objeto de la cat. actual
	sw $t1, 28($t0)
 
 main_loop:
	# show menu
	jal menu_display		# Muestra el menú y espera la opción del usuario
	beqz $v0, main_end		# Si la opción es 0, salir
	addi $v0, $v0, -1		# Convierte la opción en índice del vector 'schedv'
	sll $v0, $v0, 2         	# Multiplica por 4 (tamaño de dirección en bytes)
	la $t0, schedv			# Carga la dirección base de schedv
	add $t0, $t0, $v0		# Suma el desplazamiento (opción ingresada * 4)
	lw $t1, ($t0)			# Carga la dirección de la función correspondiente en $t1
    	la $ra, main_ret 		# Guarda la dirección de retorno
    	jr $t1				# Salta a la función seleccionada
    	
 main_ret:
    	j main_loop	
    		
 main_end:					# Finaliza el programa si el usuario ingresó 0.
	li $v0, 10
	syscall

 menu_display:
	# write your code
	la $a0, menu
	li $v0, 4
	syscall
	li $v0, 5				# Leer un número entero desde el teclado
	syscall
	# test if invalid option go to L1	# Maneja el error por si se ingresa un núm. mayor a 8 o menor que 0.
	bgt $v0, 8, menu_display_L1
	bltz $v0, menu_display_L1
	# else return
	jr $ra
	
	# print error 101 and try again
 menu_display_L1:
	print_error(101)		# Muestra "Error: 101"
	j menu_display			# Vuelve a pedir la opción al usuario
	
 ###########   NUEVA CATEGORIA   ###########  
 
 newcaterogy:
	addiu $sp, $sp, -4
	sw $ra, 4($sp)		# Guarda $ra en la pila para poder regresar después a 'main_loop'
	la $a0, catName		# input category name
	jal getblock		# Pide memoria para guardar el nombre de la categoría
	move $a2, $v0		# $a2 = *char to category name
	la $a0, cclist		# $a0 = list
	li $a1, 0		# $a1 = NULL (porque una cat. no necesita ID)
	jal addnode		# Crea un nodo en la lista de categorías
	lw $t0, wclist
	bnez $t0, newcategory_end
	sw $v0, wclist		# update working list if was NULL
	
 newcategory_end:
	la $a0, success
	li $v0, 4
	syscall			# return success
	lw $ra, 4($sp)
	addiu $sp, $sp, 4
	jr $ra
	
 ###########   CATEGORIA SIGUIENTE   ###########  
  
 nextcategory:
	lw $t0, cclist             	# Contiene la dirección de la 1er cat. de la lista
	beqz $t0, error201		# Verificamos que existan categorias
	lw $t1, 12($t0)
	beq $t0, $t1, error202  	# Verificamos que exista mas de 1 categoria 
	
 nextCategory_select:
	lw $t0, wclist			# Cargamos la categoria en curso
	lw $t1, 12($t0)			# Cargamos la siguiente categoría
	sw $t1, wclist			# Actualizamos la categoria en curso a la categoria siguiente
	la $a0, selCat			# Imprimimos mensaje de la categor a seleccionada
        	li $v0, 4
        	syscall
        	lw $a0, 8($t1)		# Imprimimos la nueva categoria en curso		
        	li $v0, 4
        	syscall
        	j nextcategory_end
        	
 error201:
    	print_error(201)
    	j menu_display
    	
 error202:
    	print_error(202)
    	j menu_display
    	
 nextcategory_end:
	la $a0, success		
	li $v0, 4
	syscall
	jr $ra
	
 ###########   CATEGORIA ANTERIOR   ###########  
  
 prevcaterogy:
	lw $t0, cclist		#Verificamos que existan categorias
	beqz $t0, error201
	lw $t1, 12($t0)		# Verificamos que exista una categoría anterior
	beq $t0, $t1, error202	#Verificamos que exista mas de 1 categoria 
			
 prevcategory_select:
	lw $t0, wclist		#Cargamos la categoria en curso
	lw $t1, 0($t0)		#Cargamos la categoría anterior
	sw $t1, wclist		#Actualizamos la categoria en curso a la categoria anterior
	la $a0, selCat
        	li $v0, 4
        	syscall
        	lw $a0, 8($t1)		#Imprimimos la nueva categoria en curso
        	li $v0, 4
       	 syscall
	j prevcategory_end	
	
 prevcategory_end:
	la $a0, success
	li $v0, 4
	syscall
	jr $ra
	
 ###########   LISTAR  CATEGORIAS   ###########  
 
 listcategories:
    	lw $t0, cclist			# Verificamos que existan categorias
    	beqz $t0, error301     
    	lw $t1, cclist  		# Cargamos en t1 la primer categoria
    	lw $t2, wclist   		# Cargamos en t2 la categoria en curso
    	la $a0, mensaje_listadoCats
    	li $v0, 4
    	syscall
    	
 listcategories_loop:
    	beq $t0, $t2, listcategories_wcprint	# Si la cat. en curso es la actual, ir a etiqueta
    	lw $a0, 8($t0)     			# Cargamos la dirección del  nombre de la cat.	
    	li $v0, 4           
    	syscall            
    	j listcategories_continue
    		
 listcategories_wcprint:
    	la $a0, marca				# Si la categoria a imprimir es la categoria en curso le colocamos una distincion (>)
    	li $v0, 4
    	syscall
    	lw $a0, 8($t0)     			# Cargamos la dirección del nombre de la categoría
    	li $v0, 4           
    	syscall 				# Imprimimos la categoría
    	
 listcategories_continue:
    	lw $t0, 12($t0)     			# Avanzamos a la siguiente categoria
    	beq $t0, $t1, listcategories_end  	# t1 tiene el primer nodo y $t0 el nodo a imprimir, si son iguales significa que ya imprimimos todas las categorias y finaliza la función.
    	j listcategories_loop 
    	
 error301:
    	print_error(301)
    	j menu_display
    	
 listcategories_end:
    	la $a0, success
	li $v0, 4
	syscall
    	jr $ra
    	
 ###########   BORRAR CATEGORIA   ###########   
 
 delcaterogy:
	addiu $sp, $sp, -4
	sw $ra, 4($sp)
	lw $t0, cclist			#Verificamos que existan categorias
	beqz $t0, error401		
	la $a1, cclist			#Cargamos en a1 la direccion de la lista que tiene el nodo a eliminar
	lw $a0, wclist			#Cargamos en a0 el nodo a eliminar
	lw $t1, 4($a0)			
	bnez $t1, errorCatNoVacia	#Verificamos que la categoria no tenga objetos, de lo contrario deber  eliminarlos primero
	lw $t3, 12($a0)			
	sw $t3, wclist			#Actualizamos la cateogoria en curso a la siguiente a eliminar
	bne $a0, $t3, delnode		#Verificamos que exista mas de 1 categoria
	sw $0, wclist			#Si hay 1 sola categoria, ponemos nula la categoria en curso
	jal delnode			#Eliminamos la unica categoria existente
	j delcategory_end
	
 error401:
	print_error(401)
    	j menu_display
    	
 errorCatNoVacia:
	la $a0, mensaje_categoriaNoVacia
	li $v0, 4
	syscall
	j menu_display
	
 delcategory_end:
	lw $ra, 4($sp)
	addiu $sp, $sp, 4
	la $a0, success
	li $v0, 4
	syscall
	jr $ra
	
 ###########   AGREGAR OBJETO A LA CATEGORIA ACTUAL   ###########   
 
 newobject:
	la $a0, cclist			
	lw $t0, 0($a0)
	beq $t0, 0, error501		#Verificamos que existan categorias
	addiu $sp, $sp, -4
	sw $ra, 4($sp)
	la $a0, objName			
	jal getblock			#Establecemos el nombre del objeto	
	move $a2, $v0			#Lo movemos a a2
	lw $t2, wclist			#Cargamos la dirección de la categoria en curso
	lw $t3, 4($t2)			#Cargamos el campo que apunta al primer objeto. Obtiene el valor almacenado en 4($t2)
	lw $t4, 4($t2)			#Guardamos la dirección del 1er objeto para detectar el final del bucle.
	la $a0, 4($t2)			#Cargamos en $a0 la dirección de la variable 4($t2)
	li $t6, 1
	beqz $t3, firstnode_add		#Si el puntero al primer objeto es nulo, a adimos el primer objeto
	j findlastnode_loop		#Si ya hay objetos, buscamos el ultimo para tomar su id e incrementarla en 1 

 findlastnode_loop:	
	lw $t6, 4($t3)			#En este loop recorremos los objetos hasta llegar al  último, tomamos su id y le añadimos 1, para que el nuevo nodo tenga por id uno mayor al ultimo
	addi $t6, $t6, 1
	lw $t3, 12($t3)	
	beq $t3, $t4, othernode_add		
	j findlastnode_loop	
	
 othernode_add:
	move $a1, $t6			#Cargamos en $a1 el id que va a tener el nuevo nodo
	jal addnode			
	j newobject_end
				
 firstnode_add:
	move $a1, $t6
	jal addnode
	la $t5, ($v0)
	sw $t5, 4($t2)			#Hacemos que el puntero de lista apunte al primer objeto
	j newobject_end
	
 error501:
    	print_error(501)
    	j menu_display	
    		
 newobject_end:			
	lw $ra, 4($sp)			# Recuperamos la dirección de retorno
	addiu $sp, $sp, 4		# Liberamos espacio en la pila
	la $a0, success			# Mensaje de éxito
	li $v0, 4			# Código de syscall para imprimir cadena de caracteres
	syscall
	jr $ra				# Retornamos a la función que nos llamó 
	
###########   LISTAR OBJETOS  ########### 

 listobjects:
        	lw $t0, wclist		#Verificamos que existan categorias
	beq $t0, 0, error601
	lw $t1, 4($t0)
	beq $t1, 0, error602		#Verificamos que la categoria en curso tenga al menos 1 objeto
	lw $t2, 4($t0) 		
	la $a0, mensaje_listadoObjs
	li $v0, 4
	syscall
	lw $a0, 8($t0)			#Imprimimos el nombre de la categoria en curso
	li $v0, 4
	syscall
	
 listobjects_loop:
	la $a0, Id
	li $v0, 4
	syscall
	lw $a0, 4($t1)
	li $v0, 1
	syscall
	la $a0, dospuntos
	li $v0, 4
	syscall
	lw $a0, 8($t1) 			#Imprimimos el nombre del objeto
	li $v0, 4
	syscall
	
 listobjects_continue:
    	lw $t1, 12($t1)     		#Avanzamos al siguiente objeto
    	beq $t1, $t2, listobject_end 	#Si ya imprimimos todos los objetos finalizamos
    	j listobjects_loop 		#Si faltan objetos por imprimir volvemos al bucle
    	
 error601: 
    	print_error(601)
    	j menu_display
    	
 error602:
    	print_error(602)
    	j menu_display
    	
 listobject_end:
    	la $a0, success
	li $v0, 4
	syscall
	jr $ra
	
 ###########   ELIMINAR OBJETO DE LA CATEGORIA ACTUAL   ###########  
 
 delobject:
	la $a0, cclist				#Verificamos que existan categorias
	lw $t0, 0($a0)
	beqz $t0, error701		
	lw $t0, wclist
	lw $a1, 4($t0)				#Cargamos el primer objeto
	la $a0, idObj				#Pedimos el id del objeto a eliminar
	li $v0, 4
	syscall
	li $v0, 5				#Pedimos el id del objeto a eliminar
	syscall
	move $t1, $v0				#Movemos el id ingresado por el usuario al registro $t1
	move $a0, $a1				#Movemos el primer objeto al registro $a0
	lw $t6, 4($a0)				#Cargamos en $t6 el ID del Objeto en curso				
	beq $t1, $t6, delobject_firstobj	#Comparamos la ID ingresada con el ID del objeto en curso, si es el primero saltamos a la funcion
	lw $a0, 12($a0)				#Si no es el primer objeto, avanzamos al siguiente
	lw $t6, 4($a0)				#Y cargamos la ID del siguiente objeto en $t6

 delobject_findobj:
	beq $t1, $t6, delnode			#Iteramos hasta encontrar el objeto a eliminar, encontrado llamamos a la funcion delnode
	lw $a0, 12($a0)
	lw $t6, 4($a0)
	beq $a0, $a1, error_notfound		#Si recorrimos todos los objetos y no hay ninguno con el ID indicado devolvemos error notFound
	j delobject_findobj
	
 delobject_firstobj:
	lw $t4, 12($a0)				#Si el objeto a eliminar es el primero
	sw $t4, 4($t0) 				#Actualizamos el puntero a la lista de objetos para que apunte al siguiente
	bne $t4, $a0, delnode			#Si el primero y el sgte son iguales, entonces hay 1 solo	
	li $t5, 0				
	sw $t5, 4($t0)				#Si no quedan objetos en la lista, actualizamos el puntero a la lista a valor NULL
	j delnode
	
 delobject_end:
	la $a0, success
	li $v0, 4
	syscall
	
 error_notfound:
	la $a0, ErrorNotFound
	li $v0, 4
	syscall
	j menu_display
		
 error701:
    	print_error(701)
    	j menu_display
    	
 # a0: list address
 # a1: NULL if category, node address if object
 # v0: node address added
 
 addnode:
	addi $sp, $sp, -8
	sw $ra, 8($sp)
	sw $a0, 4($sp)
	jal smalloc
	sw $a1, 4($v0) 			# set node content (ID)
	sw $a2, 8($v0)			# store data (nombre)
	lw $a0, 4($sp)
	lw $t0, ($a0) 			# first node address
	beqz $t0, addnode_empty_list
	
 addnode_to_end:
	lw $t1, ($t0) 			# last node address, cargamos en $t1 la dirección del último nodo de la lista
 	# update prev and next pointers of new node
	sw $t1, 0($v0)			# Hacemos que el nuevo nodo apunte al último nodo como 'prev'
	sw $t0, 12($v0)			# Hacemos que el nuevo nodo apunte al primer nodo como 'next'
	# update prev and first node to new node
	sw $v0, 12($t1)			# Hacemos que el último nodo apunte al nuevo nodo como 'next'
	sw $v0, 0($t0)			# Hacemos que el primer nodo apunte al nuevo nodo como 'prev'
	j addnode_exit
	
 addnode_empty_list:
	sw $v0, ($a0)		# La lista ahora apunta al nuevo nodo
	sw $v0, 0($v0)		# El nodo apunta a sí mismo como 'prev'
	sw $v0, 12($v0)		# El nodo apunta a sí mismo como 'next'
	
 addnode_exit:
	lw $ra, 8($sp)
	addi $sp, $sp, 8
	jr $ra			# Retornamos a la función que  llamó 'addnode'

 # a0: node address to delete
 # a1: list address where node is deleted
 
 delnode:
	addi $sp, $sp, -8
	sw $ra, 8($sp)			# Dirección de retorno
	sw $a0, 4($sp)			# Dirección del nodo
	lw $a0, 8($a0) 			# get block address
	jal sfree 			# free block
	lw $a0, 4($sp) 			# Restauramos la dirección del nodo a eliminar
	lw $t0, 12($a0)			# Cargamos la dirección del siguiente nodo 
	beq $a0, $t0, delnode_point_self
	lw $t1, 0($a0) 			# get address to prev node, cargamos la dirección del nodo anterior
	sw $t1, 0($t0)			# El siguiente nodo apunta al nodo anterior  como 'prev'
	sw $t0, 12($t1)			# El nodo anterior apunta al siguiente nodo como 'next'
	lw $t1, 0($a1) 			# get address to first node again
	bne $a0, $t1, delnode_exit	# Si no era el primer nodo, saltamos a la salida
	sw $t0, ($a1) 			# list point to next node
	j delnode_exit
	
 delnode_point_self:
	sw $zero, ($a1) 		# only one node
	
 delnode_exit:
	jal sfree			# Liberamos memoria del nodo eliminado
	lw $ra, 8($sp)			# Restauramos la dirección de retorno
	addi $sp, $sp, 8		# Restauramos la pila
	jr $ra				# Retornamos a la función que llamó a 'delnode'

 # a0: msg to ask
 # v0: block address allocated with string
 
 getblock:
	addi $sp, $sp, -4	# Reservamos espacio en la pila
	sw $ra, 4($sp)		# Guardamos $ra en la pila
	li $v0, 4
	syscall
	jal smalloc		# Llamamos a smalloc para reservar memoria
	move $a0, $v0		# Guardamos la dirección de la memoria reservada en $a0
	li $a1, 16		# 16 caracteres como tamaño máximo
	li $v0, 8		# Código syscall para leer un string
	syscall
	move $v0, $a0		# Guardamos en $v0 la dirección del bloque de memoria
	lw $ra, 4($sp)		# Restauramos la dirección de retorno
	addi $sp, $sp, 4	# Restauramos la pila
	jr $ra	

 smalloc:
	lw $t0, slist		# Cargamos la dirección del 1er bloque libre en $t0
	beqz $t0, sbrk		# Pedir más memoria si $t0 es NULL
	move $v0, $t0		# Devolvemos en $v0 la dirección del bloque de memoria asignado
	lw $t0, 12($t0)		# Cargamos la dirección del sig. bloque libre en la lista
	sw $t0, slist		# Actualizamos slist para que apunte al sig. bloque libre
	jr $ra			# Retornar a la función que llamó a smalloc
	
 sbrk:
	li $a0, 16 		# node size fixed 4 words, reserva 16 bytes 
	li $v0, 9		# Código syscall para reservar memoria en el heap
	syscall 		# return node address in v0
	jr $ra

 sfree:
	lw $t0, slist		# Cargamos en $t0 la dirección del 1er bloque libre
	sw $t0, 12($a0)		# Guardamos en 12($a0) la dirección del 1er bloque libre
	sw $a0, slist 		# Slist apunta al nodo recién liberado
	jr $ra

