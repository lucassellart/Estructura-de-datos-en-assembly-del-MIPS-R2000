	.data

 # Punteros inicializados a NULL

 slist: 	.word 0	# Lista de bloques liberados
 cclist: 	.word 0	# Lista de categorias
 wclist: 	.word 0	# Categoria seleccionada
 schedv: 	.space 32	# Espacio para el vector de funciones del menú

 menu: 	.ascii "Colecciones de objetos categorizados\n"
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
 error: 	.asciiz "Error: "
 return: 	.asciiz "\n"
 catName: 	.asciiz "\nIngrese el nombre de una categoria: "
 selCat: 	.asciiz "\nSe ha seleccionado la categoria:"
 idObj: 	.asciiz "\nIngrese el ID del objeto a eliminar: "
 objName: 	.asciiz "\nIngrese el nombre de un objeto: "
 success: 	.asciiz "La operación se realizo con exito\n\n"


 error_702: .asciiz "Error 702: No hay objetos disponibles en esta categoría\n"

 .text
 main:	la $t0, schedv		# Inicializar el vector del menú
	la $t1, newcategory	
	sw $t1, 0($t0)		# Opcion 1: Crear nueva categoria
	la $t1, nextcategory
	sw $t1, 4($t0)		# Opción 2: Siguiente categoría
	la $t1, prevcategory	
	sw $t1, 8($t0)		# Opcion 3: Anterior  categoria
	la $t1, listcategories
	sw $t1, 12($t0)		# Opcion 4: Listar categorias
	la $t1, delcategory
	sw $t1, 16($t0)		# Opcion 5: Eliminar categoria
	la $t1, newobject
	sw $t1, 20($t0)		# Opcion 6: Agregar objeto
	la $t1, listobjects		
	sw $t1, 24($t0)		# Opcion 7: Listar objetos
	la $t1, delobject
	sw $t1, 28($t0)		# Opcion 8: Borrar objeto
	
	li $v0, 10		# Salir del programa
	syscall	
	

 menu_loop:
    	# Imprimir el menú
    	la $a0, menu               	# Dirección del texto del menú
    	li $v0, 4                  	# Syscall para imprimir texto
    	syscall

    	# Leer la opción del usuario
    	li $v0, 5                  	# Syscall para leer un entero
    	syscall
    	move $t0, $v0              	# Guardar la opción ingresada en $t0

    	# Validar la opción ingresada
    	blt $t0, 0, invalid_option 	# Si $t0 < 0, opción inválida
    	bgt $t0, 8, invalid_option 	# Si $t0 > 8, opción inválida

    	# Ejecutar la opción seleccionada
    	la $t1, schedv             	# Cargar la base del vector de funciones
    	mul $t0, $t0, 4            	# Calcular el offset: $t0 * 4 (cada dirección es de 4 bytes)
    	add $t2, $t1, $t0          	# Calcular la dirección efectiva: base + offset
    	lw $t1, 0($t2)             	# Cargar la dirección de la función seleccionada
    	jalr $t1                   	# Llamar a la función

    	# Redibujar el menú
    	j menu_loop                	# Volver al inicio del menú

 invalid_option:
    	# Manejo del error 101: opción inválida
    	li $v0, 4                  	# Syscall para imprimir texto
    	la $a0, error              	# Mensaje: "Error 101: Opción inválida"
    	syscall
    	j menu_loop                	# Volver al menú


 newcategory:
	addiu $sp, $sp, -4		# Crear espacio en el stack
	sw $ra, 4($sp)		# Guardar la dirección de retorno
	la $a0, catName 		# Pedir el nombre de la categoría
	jal getblock		# Obtener memoria para el nombre
	move $a2, $v0 		# Guardar la dirección del nombre de la categoría
	la $a0, cclist 		# Dirección de la lista de categorías
	li $a1, 0 		# Inicializar $a1 como NULL
	jal addnode		# Agregar un nodo a la lista
	lw $t0, wclist		# Verificar si hay una categoría seleccionada
	bnez $t0, newcategory_end	# Si ya hay una categoría seleccionada, salir
	sw $v0, wclist 		# Si no hay categoría seleccionada, usar la nueva
	
 newcategory_end:
	li $v0, 0 		# Indicar éxito
	lw $ra, 4($sp)		# Restaurar la dirección de retorno
	addiu $sp, $sp, 4		# Restaurar el stack
	jr $ra		# Retornar
	

 nextcategory:
    	addiu $sp, $sp, -4         	# Crear espacio en el stack
    	sw $ra, 4($sp)             	# Guardar la dirección de retorno

    	lw $t0, wclist             	# Cargar la categoría actual
    	beqz $t0, nextcategory_error_201 	# Si no hay categorías, error 201

    	lw $t1, 12($t0)            	# Cargar el puntero 'next'
    	beq $t1, $t0, nextcategory_error_202 	# Si hay una sola categoría, error 202

    	sw $t1, wclist             	# Actualizar la categoría seleccionada

    	# Imprimir el nombre de la categoría seleccionada
    	li $v0, 4                  	# Código de syscall para imprimir cadena
    	la $a0, selCat             	# Mensaje: "Se ha seleccionado la categoría:"
    	syscall
    	lw $a0, 8($t1)             	# Cargar el nombre de la categoría seleccionada
    	syscall

    	li $v0, 0                  	# Indicar éxito
    	lw $ra, 4($sp)             	# Restaurar valor de retorno
    	addiu $sp, $sp, 4          	# Restaurar el stack
    	jr $ra                     	# Retornar

 nextcategory_error_201:
    	li $v0, 4                  	# Imprimir mensaje de error 201
    	la $a0, error              	# Mensaje: "Error 201: No hay categorías"
    	syscall
    	li $v0, 201                	# Código de error 201
    	lw $ra, 4($sp)             	# Restaurar valor de retorno
    	addiu $sp, $sp, 4          	# Restaurar el stack
    	jr $ra                     	# Retornar con error

 nextcategory_error_202:
    	li $v0, 4                  	# Imprimir mensaje de error 202
    	la $a0, error              	# Mensaje: "Error 202: Solo hay una categoría"
    	syscall
    	li $v0, 202                	# Código de error 202
    	lw $ra, 4($sp)             	# Restaurar valor de retorno
    	addiu $sp, $sp, 4          	# Restaurar el stack
    	jr $ra                     	# Retornar con error



 prevcategory:
    	addiu $sp, $sp, -4         	# Crear espacio en el stack
    	sw $ra, 4($sp)             	# Guardar la dirección de retorno

    	lw $t0, wclist             	# Cargar la categoría actual
    	beqz $t0, prevcategory_error_201 	# Si no hay categorías, error 201

    	lw $t1, 0($t0)             	# Cargar el puntero 'prev'
    	beq $t1, $t0, prevcategory_error_202 	# Si hay una sola categoría, error 202

    	sw $t1, wclist             	# Actualizar la categoría seleccionada

    	# Imprimir el nombre de la categoría seleccionada
    	li $v0, 4                  	# Código de syscall para imprimir cadena
    	la $a0, selCat             	# Mensaje: "Se ha seleccionado la categoría:"
    	syscall
    	lw $a0, 8($t1)             	# Cargar el nombre de la categoría seleccionada
    	syscall

    	li $v0, 0                  	# Indicar éxito
    	lw $ra, 4($sp)             	# Restaurar valor de retorno
    	addiu $sp, $sp, 4          	# Restaurar el stack
    	jr $ra                     	# Retornar

 prevcategory_error_201:
    	li $v0, 4                  	# Imprimir mensaje de error 201
    	la $a0, error              	# Mensaje: "Error 201: No hay categorías"
    	syscall
    	li $v0, 201                	# Código de error 201
    	lw $ra, 4($sp)             	# Restaurar valor de retorno
    	addiu $sp, $sp, 4          	# Restaurar el stack
    	jr $ra                     	# Retornar con error

 prevcategory_error_202:
    	li $v0, 4                  	# Imprimir mensaje de error 202
    	la $a0, error              	# Mensaje: "Error 202: Solo hay una categoría"
    	syscall
    	li $v0, 202                	# Código de error 202
    	lw $ra, 4($sp)             	# Restaurar valor de retorno
    	addiu $sp, $sp, 4          	# Restaurar el stack
    	jr $ra                     	# Retornar con error


 listcategories:
    	addiu $sp, $sp, -4         	# Crear espacio en el stack
    	sw $ra, 4($sp)             	# Guardar la dirección de retorno

    	lw $t0, cclist             	# Cargar la cabeza de la lista de categorías
    	beqz $t0, listcategories_error_301 	# Si la lista está vacía, error 301

    	move $t1, $t0              	# Nodo actual

 list_loop:
    	lw $t2, wclist             	# Cargar la categoría seleccionada en curso
    	beq $t1, $t2, print_selected 	# Si el nodo actual es la categoría seleccionada

    	# Categoría no seleccionada: Imprimir el nombre
    	li $v0, 4                  	# Imprimir texto
    	lw $a0, 8($t1)             	# Cargar el nombre de la categoría
    	syscall
    	j move_to_next_node        	# Ir al siguiente nodo

 print_selected:
    	# Categoría seleccionada: Imprimir ">" seguido del nombre
    	li $v0, 4                  	# Imprimir texto
    	la $a0, selCat             	# Símbolo ">"
    	syscall
    	li $v0, 4
    	lw $a0, 8($t1)             	# Imprimir el nombre de la categoría seleccionada
    	syscall

 move_to_next_node:
    	lw $t1, 12($t1)           	# Mover al siguiente nodo
    	bne $t1, $t0, list_loop    	# Si no volvemos al inicio, continuar

    	li $v0, 0                  	# Indicar éxito
    	lw $ra, 4($sp)             	# Restaurar valor de retorno
    	addiu $sp, $sp, 4          	# Restaurar el stack
    	jr $ra                     	# Retornar

 listcategories_error_301:
    	li $v0, 4                  	# Imprimir mensaje de error
    	la $a0, error              	# Mensaje: "Error 301: No hay categorías"
    	syscall
    	li $v0, 301                	# Código de error 301
    	lw $ra, 4($sp)             	# Restaurar valor de retorno
    	addiu $sp, $sp, 4          	# Restaurar el stack
    	jr $ra                     	# Retornar con error


 delcategory:
    	addiu $sp, $sp, -4         	# Crear espacio en el stack
    	sw $ra, 4($sp)             	# Guardar la dirección de retorno

    	lw $t0, wclist             	# Cargar la categoría seleccionada
    	beqz $t0, delcategory_error_401 	# Si no hay categorías seleccionadas, error 401

    	# Verificar si la lista de objetos está vacía
    	lw $t3, 4($t0)             	# Cargar la lista de objetos de la categoría
    	bnez $t3, delete_objects   	# Si no está vacía, ir a eliminar objetos

 delete_category:
    	lw $t1, 0($t0)             	# Cargar el puntero 'prev'
    	lw $t2, 12($t0)            	# Cargar el puntero 'next'

    	sw $t2, 12($t1)            	# El nodo anterior apunta al siguiente
    	sw $t1, 0($t2)             	# El nodo siguiente apunta al anterior

    	# Si era la única categoría, vaciar la lista
    	beq $t0, $t2, empty_list

    	sw $t2, wclist             	# Actualizar la categoría seleccionada
    	move $a0, $t0              	# Preparar el nodo para liberar
    	jal delnode                	# Llamar a delnode para liberar memoria

    	li $v0, 0                  	# Indicar éxito
    	lw $ra, 4($sp)             	# Restaurar valor de retorno
    	addiu $sp, $sp, 4          	# Restaurar el stack
    	jr $ra                     	# Retornar

 delete_objects:
    	# Recorrer y borrar todos los objetos de la categoría
    	move $t4, $t3              	# Nodo actual (lista de objetos)
    	
 delete_objects_loop:
    	lw $t5, 12($t4)            	# Cargar el siguiente nodo
    	move $a0, $t4              	# Preparar el nodo actual para liberar
    	lw $a1, 4($t0)             	# Pasar la dirección de la lista de objetos
    	jal delnode                	# Llamar a delnode para liberar el nodo
    	move $t4, $t5              	# Mover al siguiente nodo
    	bnez $t4, delete_objects_loop 	# Si quedan más nodos, continuar

    	# Lista de objetos vacía, proceder a borrar la categoría
    	j delete_category

 empty_list:
    	sw $zero, cclist           	# Vaciar la lista de categorías
    	sw $zero, wclist           	# No hay categoría seleccionada
    	li $v0, 0                  	# Indicar éxito
    	lw $ra, 4($sp)             	# Restaurar valor de retorno
    	addiu $sp, $sp, 4          	# Restaurar el stack
    	jr $ra                     	# Retornar

 delcategory_error_401:
    	li $v0, 4                  	# Imprimir mensaje de error
    	la $a0, error              	# Mensaje: "Error 401: No hay categorías disponibles"
    	syscall
    	li $v0, 401                	# Código de error 401
    	lw $ra, 4($sp)             	# Restaurar valor de retorno
    	addiu $sp, $sp, 4          	# Restaurar el stack
    	jr $ra                     	# Retornar con error


 newobject:
    	addiu $sp, $sp, -4         	# Crear espacio en el stack
    	sw $ra, 4($sp)             	# Guardar la dirección de retorno

    	lw $t0, wclist             	# Cargar la categoría seleccionada
    	beqz $t0, newobject_error_501 	# Si no hay categoría seleccionada, error 501

    	lw $t1, 4($t0)             	# Cargar la lista de objetos de la categoría
    	beqz $t1, newobject_empty_list 	# Si la lista está vacía, el ID será 1

    	# Encontrar el último objeto en la lista para determinar el ID
    	move $t2, $t1              	# Nodo actual

 find_last_object:
    	lw $t3, 12($t2)            	# Cargar el puntero 'next'
    	beq $t3, $t1, last_object_found 	# Si volvemos al inicio, hemos encontrado el último
    	move $t2, $t3              	# Mover al siguiente nodo
    	j find_last_object

 last_object_found:
    	lw $t4, 4($t2)             	# Cargar el ID del último objeto
    	addiu $t4, $t4, 1          	# ID del nuevo objeto = último ID + 1
    	j create_new_object

 newobject_empty_list:
    	li $t4, 1                  	# ID por defecto = 1

 create_new_object:
    	la $a0, objName            	# Pedir el nombre del objeto
    	jal getblock               	# Obtener memoria para el nombre
    	move $a2, $v0              	# $a2 = Dirección al nombre del objeto

    	lw $a0, 4($t0)             	# Cargar la lista de objetos de la categoría
    	move $a1, $t4              	# $a1 = ID del objeto
    	jal addnode                	# Agregar el nuevo nodo de objeto

    	# Imprimir mensaje de éxito
    	li $v0, 4                  	# Imprimir texto
    	la $a0, success            	# Mensaje: "La operación se realizó con éxito"
    	syscall

    	li $v0, 0                  	# Indicar éxito
    	lw $ra, 4($sp)             	# Restaurar valor de retorno
    	addiu $sp, $sp, 4          	# Restaurar el stack
    	jr $ra                     	# Retornar

 newobject_error_501:
    	li $v0, 4                  	# Imprimir mensaje de error
    	la $a0, error              	# Mensaje: "Error 501: No hay categoría seleccionada"
    	syscall
    	li $v0, 501                	# Código de error 501
    	lw $ra, 4($sp)             	# Restaurar valor de retorno
    	addiu $sp, $sp, 4          	# Restaurar el stack
    	jr $ra                     	# Retornar con error


 listobjects:
    	addiu $sp, $sp, -4         	# Crear espacio en el stack
    	sw $ra, 4($sp)             	# Guardar la dirección de retorno

    	lw $t0, wclist             	# Cargar la categoría seleccionada
    	beqz $t0, listobjects_error_601 	# Si no hay categoría seleccionada, error 601

    	lw $t1, 4($t0)             	# Cargar la lista de objetos de la categoría
    	beqz $t1, listobjects_error_602 	# Si no hay objetos, error 602

    	move $t2, $t1              	# Nodo actual (primer objeto)

 list_obj_loop:
    	# Imprimir el nombre del objeto
    	li $v0, 4                  	# Código de syscall para imprimir cadena
    	lw $a0, 8($t2)             	# Cargar el campo 'data' (nombre del objeto)
    	syscall

    	# Imprimir el ID del objeto
    	li $v0, 1                  	# Código de syscall para imprimir un entero
    	lw $a0, 4($t2)             	# Cargar el campo 'ID' del objeto
    	syscall

    	# Imprimir una línea de separación entre objetos
    	li $v0, 4
    	la $a0, return             	# Salto de línea
    	syscall

    	# Mover al siguiente nodo
    	lw $t2, 12($t2)            	# Cargar el puntero 'next'
    	bne $t2, $t1, list_obj_loop 	# Si no volvimos al inicio, continuar

    	li $v0, 0                  	# Indicar éxito
    	lw $ra, 4($sp)             	# Restaurar valor de retorno
    	addiu $sp, $sp, 4          	# Restaurar el stack
    	jr $ra                     	# Retornar

 listobjects_error_601:
    	# Imprimir mensaje de error 601
    	li $v0, 4                  	# Código de syscall para imprimir cadena
    	la $a0, error              	# Mensaje: "Error 601: No hay categorías creadas"
    	syscall
    	li $v0, 601                	# Código de error 601
    	lw $ra, 4($sp)             	# Restaurar valor de retorno
    	addiu $sp, $sp, 4          	# Restaurar el stack
    	jr $ra                     	# Retornar con error

 listobjects_error_602:
    	# Imprimir mensaje de error 602
    	li $v0, 4                  	# Código de syscall para imprimir cadena
    	la $a0, error              	# Mensaje: "Error 602: No hay objetos en la categoría"
    	syscall
    	li $v0, 602                	# Código de error 602
    	lw $ra, 4($sp)             	# Restaurar valor de retorno
    	addiu $sp, $sp, 4          	# Restaurar el stack
    	jr $ra                     	# Retornar con error
	
	
 delobject:
    	addiu $sp, $sp, -4         	# Crear espacio en el stack
    	sw $ra, 4($sp)             	# Guardar la dirección de retorno

    	lw $t0, wclist             	# Cargar la categoría seleccionada
    	beqz $t0, delobject_error_701 	# Si no hay categorías, error 701

    	lw $t1, 4($t0)             	# Cargar la lista de objetos
    	beqz $t1, delobject_error_702 	# Si no hay objetos, error 702

    	# Pedir el ID del objeto a eliminar
    	li $v0, 4                  	# Mostrar mensaje al usuario
    	la $a0, idObj              	# "Ingrese el ID del objeto a eliminar:"
    	syscall

    	li $v0, 5                  	# Leer el ID ingresado por el usuario
    	syscall
    	move $t2, $v0              	# Guardar el ID en $t2

    	move $t3, $t1              	# Nodo actual (primer objeto)

 del_obj_loop:
    	lw $t4, 4($t3)             	# Cargar el campo 'ID' del nodo actual
    	beq $t4, $t2, del_obj_found 	# Si el ID coincide, ir a eliminar el nodo

    	lw $t3, 12($t3)            	# Mover al siguiente nodo
    	bne $t3, $t1, del_obj_loop 	# Si no volvimos al inicio, continuar

    	# Si el bucle termina y no encontramos el ID, mostrar "notFound"
    	j delobject_not_found

 del_obj_found:
    	move $a0, $t3              	# Preparar el nodo para liberar
    	lw $a1, 4($t0)             	# Dirección de la lista de objetos
    	jal delnode                	# Llamar a delnode para liberar el nodo

    	# Imprimir mensaje de éxito
    	li $v0, 4
    	la $a0, success            	# "La operación se realizó con éxito"
    	syscall

    	li $v0, 0                  	# Indicar éxito
    	lw $ra, 4($sp)             	# Restaurar valor de retorno
    	addiu $sp, $sp, 4          	# Restaurar el stack
    	jr $ra                     	# Retornar

 delobject_not_found:
    	# Imprimir el mensaje "notFound"
    	li $v0, 4
    	la $a0, error              	# "notFound"
    	syscall
    	li $v0, -1                 	# Retornar un código de error genérico
    	lw $ra, 4($sp)             	# Restaurar valor de retorno
    	addiu $sp, $sp, 4          	# Restaurar el stack
    	jr $ra

 delobject_error_701:
    	# Imprimir mensaje de error 701
    	li $v0, 4                  	# Mostrar mensaje al usuario
    	la $a0, error              	# "Error 701: No hay categorías creadas"
    	syscall
    	li $v0, 701                	# Código de error 701
    	lw $ra, 4($sp)             	# Restaurar valor de retorno
    	addiu $sp, $sp, 4          	# Restaurar el stack
    	jr $ra

 delobject_error_702:
    	# Imprimir mensaje de error 702
    	li $v0, 4
    	la $a0, error_702          	# "Error 702: No hay objetos en la categoría seleccionada"
    	syscall
    	li $v0, 702                	# Código de error 702
    	lw $ra, 4($sp)             	# Restaurar valor de retorno
    	addiu $sp, $sp, 4          	# Restaurar el stack
    	jr $ra
	

 addnode:
    	addi $sp, $sp, -8         	# Reservar espacio en el stack
    	sw $ra, 8($sp)            	# Guardar el valor de retorno
    	sw $a0, 4($sp)            	# Guardar el argumento de entrada $a0 en el stack

    	# Verificar si hay nodos libres en la lista slist
    	lw $t0, slist             	# Cargar el puntero a la lista de nodos libres
    	beqz $t0, addnode_empty_list 	# Si no hay nodos libres, crear un nodo nuevo

    	# Reutilizar nodo de la lista slist
    	lw $v0, slist             	# Cargar la dirección del nodo libre
    	lw $t0, 12($v0)           	# Actualizar el puntero al siguiente nodo libre
    	sw $t0, slist             	# Actualizar la lista de nodos libres

 addnode_to_end:
    	lw $t0, ($a0)             	# Cargar la dirección del primer nodo en la lista
    	beqz $t0, addnode_empty_list 	# Si la lista está vacía, inicializarla

    	lw $t1, ($t0)             	# Cargar la dirección del último nodo
    	# Actualizar punteros 'prev' y 'next' del nuevo nodo
    	sw $t1, 0($v0)            	# Establecer el puntero 'prev'
    	sw $t0, 12($v0)           	# Establecer el puntero 'next'

    	# Actualizar la lista existente
    	sw $v0, 12($t1)           	# El último nodo ahora apunta al nuevo nodo
    	sw $v0, 0($t0)            	# El primer nodo apunta al nuevo nodo
    	j addnode_exit            	# Salir

 addnode_empty_list:
    	# Inicializar la lista si está vacía
    	sw $v0, ($a0)             	# La lista apunta al nuevo nodo
    	sw $v0, 0($v0)            	# El nuevo nodo se apunta a sí mismo (prev)
    	sw $v0, 12($v0)           	# El nuevo nodo se apunta a sí mismo (next)

 addnode_exit:
    	lw $ra, 8($sp)            	# Restaurar el valor de retorno
    	addi $sp, $sp, 8          	# Liberar el stack
    	jr $ra                    	# Retornar
	
	
 delnode:
    	addi $sp, $sp, -8         	# Reservar espacio en el stack
    	sw $ra, 8($sp)            	# Guardar el valor de retorno
    	sw $a0, 4($sp)            	# Guardar el nodo a eliminar en el stack

    	lw $t0, 12($a0)           	# Cargar la dirección del nodo siguiente
    	beq $a0, $t0, delnode_point_self 	# Si es el único nodo, manejar caso especial

    	lw $t1, 0($a0)            	# Cargar la dirección del nodo anterior
    	sw $t1, 0($t0)            	# Actualizar el puntero 'prev' del nodo siguiente
    	sw $t0, 12($t1)           	# Actualizar el puntero 'next' del nodo anterior

    	lw $t1, 4($sp)            	# Restaurar la dirección de la lista
    	lw $t2, ($t1)             	# Cargar el primer nodo de la lista
    	bne $a0, $t2, delnode_exit 	# Si no es el primer nodo, salir

    	# Si es el primer nodo, actualizar la lista
    	sw $t0, ($t1)

 delnode_point_self:
    	# Caso especial: el nodo eliminado es el único en la lista
    	sw $zero, ($t1)           	# Vaciar la lista

 delnode_exit:
    	# Añadir el nodo eliminado a la lista de nodos libres (slist)
    	lw $t0, slist             	# Cargar la lista de nodos libres
    	sw $t0, 12($a0)           	# El nodo eliminado apunta al primer nodo libre
    	sw $a0, slist             	# Actualizar la lista de nodos libres

    	lw $ra, 8($sp)            	# Restaurar el valor de retorno
    	addi $sp, $sp, 8          	# Liberar el stack
    	jr $ra                    	# Retornar
	
	
 getblock:
    	addi $sp, $sp, -4         	# Reservar espacio en el stack
    	sw $ra, 4($sp)            	# Guardar el valor de retorno

    	li $v0, 4                 	# Syscall para imprimir mensaje de solicitud
    	syscall

    	# Verificar si hay nodos libres
    	lw $v0, slist             	# Cargar la lista de nodos libres
    	beqz $v0, getblock_error  	# Si no hay nodos libres, manejar el error

    	# Extraer un nodo de la lista de nodos libres
    	lw $t0, 12($v0)           	# Cargar el siguiente nodo libre
    	sw $t0, slist             	# Actualizar la lista de nodos libres

    	# Pedir la cadena de caracteres al usuario
    	move $a0, $v0             	# Dirección del bloque asignado
    	li $a1, 16                	# Longitud máxima de la cadena
    	li $v0, 8                 	# Syscall para leer cadena
    	syscall

    	lw $ra, 4($sp)            	# Restaurar el valor de retorno
    	addi $sp, $sp, 4          	# Liberar el stack
    	jr $ra                    	# Retornar

 getblock_error:
    	la $a0, error             	# Mensaje de error: "No hay memoria disponible"
    	li $v0, 4                 	# Syscall para imprimir el error
    	syscall
    	jr $ra                    	# Retornar con error
    	
    	