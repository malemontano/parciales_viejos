extern malloc
extern free

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
EJERCICIO_1A_HECHO: db TRUE ; Cambiar por `TRUE` para correr los tests.

; Marca el ejercicio 1B como hecho (`true`) o pendiente (`false`).
;
; Funciones a implementar:
;   - contarCombustibleAsignado
global EJERCICIO_1B_HECHO
EJERCICIO_1B_HECHO: db TRUE ; Cambiar por `TRUE` para correr los tests.

; Marca el ejercicio 1C como hecho (`true`) o pendiente (`false`).
;
; Funciones a implementar:
;   - modificarUnidad
global EJERCICIO_1C_HECHO
EJERCICIO_1C_HECHO: db TRUE ; Cambiar por `TRUE` para correr los tests.

;########### ESTOS SON LOS OFFSETS Y TAMAÑO DE LOS STRUCTS
; Completar las definiciones (serán revisadas por ABI enforcer):
ATTACKUNIT_CLASE EQU 0
ATTACKUNIT_COMBUSTIBLE EQU 12
ATTACKUNIT_REFERENCES EQU 14
ATTACKUNIT_SIZE EQU 16

FILAS     equ 255
COLUMNAS  equ 255

global optimizar
	; Te recomendamos llenar una tablita acá con cada parámetro y su
	; ubicación según la convención de llamada. Prestá atención a qué
	; valores son de 64 bits y qué valores son de 32 bits o 8 bits.
	;
	; rdi = mapa_t           mapa
	; rsi = attackunit_t*    compartida
	; rdx = uint32_t*        fun_hash(attackunit_t*)
; rdi->mapa, rsi->compartida, rdx->fun_hash
optimizar:
	push rbp
	mov rbp, rsp
	push r12
	push r13
	push r14
	push r15 ;alineada
	push rbx
	sub rsp, 8

	mov r12, rdi ;mapa
	mov r13, rsi ;compartida
	mov r14, rdx ;fun_hash

	;avanzar al siguiente es simplemente avanzar 8
	mov rdi, r13
	call r14 ;fun_hash(compartida)
	mov r15d, eax ;r15 = fun_hash(compartida)

	xor rbx, rbx
	.ciclo:
	mov r10, qword [r12+rbx*8] ;mapa[i][j] (puntero a attack unit)
	cmp r10, 0
	je .siguiente ;mapa[i][j]==NULL

	cmp r10, r13 ;si son exactamente la misma unidad avanzo al siguiente
    je .siguiente

	mov rdi, r10
	push r10
	call r14 ;fun_hash(actual)
	pop r10
	cmp eax, r15d ; fun_hash(actual)==fun_hash(compartida)?
	jne .siguiente
	
	dec byte [r10+ATTACKUNIT_REFERENCES] ;desreferencio el puntero a attack unit y accedo a references (actual)
	;references--

	inc byte [r13+ATTACKUNIT_REFERENCES] ;desreferencio el puntero a attack unit y accedo a references (compartida)
	;references++

	mov qword [r12+rbx*8], r13 ;mapa[i][j]-->compartida

	cmp byte [r10+ATTACKUNIT_REFERENCES], 0;chequeo actual.references == 0.
	jne .siguiente
	mov rdi, r10
	call free


	.siguiente:
	inc rbx
	cmp rbx, FILAS * COLUMNAS
	jl .ciclo

	add rsp, 8
	pop rbx
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbp
	ret
global contarCombustibleAsignado
contarCombustibleAsignado:
	; rdi = mapa_t           mapa
	; rsi = uint16_t*        fun_combustible(char*)
	push rbp
	mov rbp, rsp
	push r12
	push r13 ;alineada
	push r14
	push r15
	push rbx ;desalineada

	xor rbx, rbx ;contador
	xor r15, r15 ;acumulador

	mov r12, rdi ; mapa
	mov r13, rsi ; fun_combustible

	.ciclo:
	mov r14, [r12 + rbx*8] ; elem del mapa
	cmp r14, 0 ;chequeo si es null
	je .siguiente

	add r14, ATTACKUNIT_CLASE
	mov rdi, r14 ; agarro la clase
	call r13 ; ax = fun_combustible(*actual.clase) entero de 16bits(word)
	
	movzx r10d, word [r14+ATTACKUNIT_COMBUSTIBLE] ;r10d = actual.combustible
	movzx r11d, ax ;extiendo fun_combustible(*actual.clase)
	sub r10d, r11d ; r10d=actual.combustible-combustible_base
	add r15d, r10d

	.siguiente:
	inc rbx
	cmp rbx, FILAS*COLUMNAS
	jl .ciclo

	mov eax, r15d
	pop rbx
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbp
	ret

global modificarUnidad
modificarUnidad:
	; rdi = mapa_t           mapa
	; sil  = uint8_t          x
	; dl  = uint8_t          y
	; rcx = void*            fun_modificar(attackunit_t*)
	push rbp
	mov rbp, rsp
	push r12
	push r13
	push r14
	push r15
	push rbx

	mov r12, rdi ;mapa
	movzx r13, sil ;x (extendido a 64bits)
	movzx r14, dl ;y (extendido a 64bits)
	mov r15, rcx ;fun_modificar

	mov rax, COLUMNAS
	mul r13 ;rax = r13*COLUMNAS --> x*COLUMNAS
	add rax, r14 ; rax = x*COLUMNAS + y
	mov rbx, [r12+rax*8] ;accedo a mapa[x][y]

	cmp rbx, 0
	je .fin

	movzx r10, byte [rbx+ATTACKUNIT_REFERENCES] ;r10=references
	cmp r10, 1
	jg .nueva_unidad ;si tiene mas de 1 ref, tengo q crear una nueva attackunit
	;es unica, aplico la funcion
	mov rdi, rbx
	call r15 ;fun_modificar(mapa[x][y]) puntero al attack unit
	jmp .fin

	.nueva_unidad:
	mov rdi, ATTACKUNIT_SIZE
	call malloc ;rax = malloc(sizeof(attackunit))

	dec byte [rbx+ATTACKUNIT_REFERENCES] ;ref--
	inc byte [rax+ATTACKUNIT_REFERENCES]
	mov r10w, word [rbx+ATTACKUNIT_COMBUSTIBLE]
	mov word [rax+ATTACKUNIT_COMBUSTIBLE], r10w ;nueva.combustible = vieja.combustible
	movzx r9b, byte [rbx+ATTACKUNIT_CLASE]
	mov [rax+ATTACKUNIT_CLASE], r9b


	mov r8, COLUMNAS
	mul r13
	add r8, r14
	
	mov [r12+r8*8], rax ; mapa[x][y]-->puntero a la nueva unidad

	.fin:
	pop rbx
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbp
	ret