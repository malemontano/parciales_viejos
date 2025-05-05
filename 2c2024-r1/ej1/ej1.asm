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
;   - optimizar
global EJERCICIO_1A_HECHO
EJERCICIO_1A_HECHO: db FALSE ; Cambiar por `TRUE` para correr los tests.

; Marca el ejercicio 1B como hecho (`true`) o pendiente (`false`).
;
; Funciones a implementar:
;   - contarCombustibleAsignado
global EJERCICIO_1B_HECHO
EJERCICIO_1B_HECHO: db FALSE ; Cambiar por `TRUE` para correr los tests.

; Marca el ejercicio 1C como hecho (`true`) o pendiente (`false`).
;
; Funciones a implementar:
;   - modificarUnidad
global EJERCICIO_1C_HECHO
EJERCICIO_1C_HECHO: db FALSE ; Cambiar por `TRUE` para correr los tests.

;########### ESTOS SON LOS OFFSETS Y TAMAÑO DE LOS STRUCTS
; Completar las definiciones (serán revisadas por ABI enforcer):
ATTACKUNIT_CLASE EQU 0
ATTACKUNIT_COMBUSTIBLE EQU 12
ATTACKUNIT_REFERENCES EQU 14
ATTACKUNIT_SIZE EQU 16

global optimizar
	; Te recomendamos llenar una tablita acá con cada parámetro y su
	; ubicación según la convención de llamada. Prestá atención a qué
	; valores son de 64 bits y qué valores son de 32 bits o 8 bits.
	;
	; r/m64 = mapa_t           mapa
	; r/m64 = attackunit_t*    compartida
	; r/m64 = uint32_t*        fun_hash(attackunit_t*)
; rdi->mapa, rsi->compartida, rdx->fun_hash
optimizar:
	push rbp ;alineada
	mov rbp, rsp
	push rbx ;desalineada
	push r12 ;alineada
	push r13 ;desalineada
	push r14 ;alineada
	push r15 ;desalineada
	sub rsp, 8 ;alineada

	mov r12, rdi ;guardo el mapa
	mov r13, rsi ;guardo compartida
	mov rbx, rdx ;guardo fun_hash
	xor r15, r15 ;iterador

	mov rdi, r13
	call rbx ;llamo a fun_hash con param compartida
	mov r14d, eax ;guardo en r14 fun_hash(compartida)

	;recorro la matriz
	.loop:
	mov rdi, [r12 + r15*8] ;unidad actual
	cmp rdi, 0 ;chequeo si es null
	je .sig_iteracion

	cmp rdi, r13 ;chequeo si compartida == actual
	je .sig_iteracion

	call rbx ;llamo a fun_hash con param actual
	cmp eax, r14d ;fun_hash(compartida) == fun_hash(actual) ?
	jne .sig_iteracion

	inc byte [r13+ATTACKUNIT_REFERENCES];compartida->references++
	mov rdi, [r12 + r15*8] ;unidad actual
	dec byte [rdi+ATTACKUNIT_REFERENCES];actual->references--
	mov [r12 + r15*8], r13 ;mapa[i][j]=compartida

	cmp byte [rdi+ATTACKUNIT_REFERENCES], 0 ;actual->references == 0?
	jne .sig_iteracion
	call free ;tengo en rdi la unidad actual

	.sig_iteracion:
	inc r15
	cmp r15, 255*255
	jl .loop

	add rsp, 8
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbx
	pop rbp
	ret

global contarCombustibleAsignado
contarCombustibleAsignado:
	; r/m64 = mapa_t           mapa
	; r/m64 = uint16_t*        fun_combustible(char*)
	ret

global modificarUnidad
modificarUnidad:
	; r/m64 = mapa_t           mapa
	; r/m8  = uint8_t          x
	; r/m8  = uint8_t          y
	; r/m64 = void*            fun_modificar(attackunit_t*)
	ret