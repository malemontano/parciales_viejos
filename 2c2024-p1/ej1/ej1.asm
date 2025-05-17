extern malloc

section .rodata
; Acá se pueden poner todas las máscaras y datos que necesiten para el ejercicio

section .text
; Marca un ejercicio como aún no completado (esto hace que no corran sus tests)
FALSE EQU 0
; Marca un ejercicio como hecho
TRUE  EQU 1

; Marca el ejercicio 1A como hecho (`true`) o pendiente (`false`).
;
; Funciones a implementar:
;   - es_indice_ordenado
global EJERCICIO_1A_HECHO
EJERCICIO_1A_HECHO: db TRUE ; Cambiar por `TRUE` para correr los tests.

; Marca el ejercicio 1B como hecho (`true`) o pendiente (`false`).
;
; Funciones a implementar:
;   - indice_a_inventario
global EJERCICIO_1B_HECHO
EJERCICIO_1B_HECHO: db TRUE ; Cambiar por `TRUE` para correr los tests.

;########### ESTOS SON LOS OFFSETS Y TAMAÑO DE LOS STRUCTS
; Completar las definiciones (serán revisadas por ABI enforcer):
ITEM_NOMBRE EQU 0
ITEM_FUERZA EQU 20
ITEM_DURABILIDAD EQU 24
ITEM_SIZE EQU 28

;; La funcion debe verificar si una vista del inventario está correctamente 
;; ordenada de acuerdo a un criterio (comparador)

;; bool es_indice_ordenado(item_t** inventario, uint16_t* indice, uint16_t tamanio, comparador_t comparador);

;; Dónde:
;; - `inventario`: Un array de punteros a ítems que representa el inventario a
;;   procesar.
;; - `indice`: El arreglo de índices en el inventario que representa la vista.
;; - `tamanio`: El tamaño del inventario (y de la vista).
;; - `comparador`: La función de comparación que a utilizar para verificar el
;;   orden.
;; 
;; Tenga en consideración:
;; - `tamanio` es un valor de 16 bits. La parte alta del registro en dónde viene
;;   como parámetro podría tener basura.
;; - `comparador` es una dirección de memoria a la que se debe saltar (vía `jmp` o
;;   `call`) para comenzar la ejecución de la subrutina en cuestión.
;; - Los tamaños de los arrays `inventario` e `indice` son ambos `tamanio`.
;; - `false` es el valor `0` y `true` es todo valor distinto de `0`.
;; - Importa que los ítems estén ordenados según el comparador. No hay necesidad
;;   de verificar que el orden sea estable.

global es_indice_ordenado
es_indice_ordenado:
	; Te recomendamos llenar una tablita acá con cada parámetro y su
	; ubicación según la convención de llamada. Prestá atención a qué
	; valores son de 64 bits y qué valores son de 32 bits o 8 bits.
	;
	; rdi = item_t**     inventario
	; rsi = uint16_t*    indice
	; rdx(16bits mas bajos) = uint16_t     tamanio
	; rcx = comparador_t comparador

	push rbp
	mov rbp, rsp
	push r12
	push r13
	push r14
	push r15;alineada

	mov r12, rdi;puntero a inventario
	mov r13, rsi;puntero a indice
	movzx r14, dx;extiendo a 64bits el tamaño
	mov r15, rcx;puntero a la funcion comparadora?
	dec r14 ;tamaño-1
	.ciclo:
	movzx r8, word [r13];arreglo indice. indice[i]. IMPORTANTE, SON ELEMENTOS DE 2BYTES
	mov rax, 8
	mul r8 ;r8*8
	mov r8, rax

	movzx r9, word [r13+2];indice[i+1](son de 16bits asi q me muevo 2 bytes para acceder al sig elem)
	mov rax, 8
	mul r9 ;r9*8
	mov r9, rax

	mov rdi, [r12+r8];inventario[indice[i]]
	mov rsi, [r12+r9];inventario[indice[i+1]]
	call r15
	cmp rax, 0;chequeo si dio false
	je .no_esta_bien_ordenado
	;esta bien ordenado hasta el momento, avanzo
	dec r14
	cmp r14, 0
	mov rax, 1;llegue hasta el final sin encontrar una comp erronea, devuelvo true
	je .fin
	add r13, 2;avanzo el puntero de indice
	;add r12, 8;avanzo el puntero de inventario
	jmp .ciclo

	.no_esta_bien_ordenado:
	mov rax, 0
	
	.fin:

	pop r15
	pop r14
	pop r13
	pop r12
	pop rbp
		ret

;; Dado un inventario y una vista, crear un nuevo inventario que mantenga el
;; orden descrito por la misma.

;; La memoria a solicitar para el nuevo inventario debe poder ser liberada
;; utilizando `free(ptr)`.

;; item_t** indice_a_inventario(item_t** inventario, uint16_t* indice, uint16_t tamanio);

;; Donde:
;; - `inventario` un array de punteros a ítems que representa el inventario a
;;   procesar.
;; - `indice` es el arreglo de índices en el inventario que representa la vista
;;   que vamos a usar para reorganizar el inventario.
;; - `tamanio` es el tamaño del inventario.
;; 
;; Tenga en consideración:
;; - Tanto los elementos de `inventario` como los del resultado son punteros a
;;   `ítems`. Se pide *copiar* estos punteros, **no se deben crear ni clonar
;;   ítems**

global indice_a_inventario
indice_a_inventario:
	; Te recomendamos llenar una tablita acá con cada parámetro y su
	; ubicación según la convención de llamada. Prestá atención a qué
	; valores son de 64 bits y qué valores son de 32 bits o 8 bits.
	;
	; rdi = item_t**  inventario
	; rsi = uint16_t* indice
	; rdx = uint16_t  tamanio
	push rbp
	mov rbp, rsp
	push r12
	push r13
	push r14 ;desalineada
	push r15 ;alineada

	mov r12, rdi ;preservo el puntero a inventario(arreglo de punteros)
	mov r13, rsi ;preservo el puntero a indice
	movzx r14, dx ;extiendo el tamaño a 64 bits

	mov rax, ITEM_SIZE
	mul r14 ;rax = tamanio*ITEM_SIZE
	mov rdi, rax ;preparo para llamada a malloc
	call malloc ;malloc(tamanio*ITEM_SIZE)
	mov r15, rax ;preservo el puntero al nuevo inventario, es lo q voy a devolver

	xor r8, r8 ;contador
	;mov [r15+j], puntero a inventario[indice[j]]
	.ciclo:
	xor rax, rax
	mov rax, 8
	mul r8 ;rax = r8*8
	mov r11, rax ;r11 = r8*8

	movzx r9, word [r13] ;indice[r8](incremento r13 a mano pq aumenta de a 2 bytes, no de a 8 como inventario y nuevo)
	mov rax, 8
	mul r9 ;rax=r9*8. indice[r8]
	mov r10, [r12+rax] ;inventario[indice[r8]]
	mov [r15+r11], r10;nuevo[r8] = inventario[indice[r8]]

	dec r14 ;tamanio--
	cmp r14, 0
	je .fin
	inc r8
	add r13, 2 ;avanzo al sig elem de indice
	jmp .ciclo

	.fin
	mov rax, r15
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbp
	ret
