##############################################################################
# SENSORES CON E/S MAPEADA EN MEMORIA PARA MIPS32
# Incluye:
#   - Sensor de luminosidad
#   - Sensor de presión  
#   - Sensor de tensión arterial
##############################################################################

.data
# No se necesitan datos adicionales, todo es acceso directo a memoria

##############################################################################
# CONSTANTES - DIRECCIONES DE REGISTROS
##############################################################################

# Sensor de luminosidad
.eqv LUZ_CONTROL 0xFFFF0000    # Escribir 0x1 para inicializar
.eqv LUZ_ESTADO  0xFFFF0004    # 0=no listo, 1=listo, -1=error hardware
.eqv LUZ_DATOS   0xFFFF0008    # Lectura de luminosidad (0-1023)

# Sensor de presión
.eqv PRES_CONTROL 0xFFFF0010   # Escribir 0x5 para inicializar
.eqv PRES_ESTADO  0xFFFF0014   # 0=no listo, 1=válido, -1=error transitorio
.eqv PRES_DATOS   0xFFFF0018   # Presión medida (32 bits)

# Sensor de tensión arterial
.eqv TENS_CONTROL 0xFFFF0020   # Escribir 1 para iniciar medición
.eqv TENS_ESTADO  0xFFFF0024   # 0=midiendo, 1=listo
.eqv TENS_SISTOL  0xFFFF0028   # Tensión sistólica
.eqv TENS_DIASTOL 0xFFFF002C   # Tensión diastólica

##############################################################################
# CÓDIGO PRINCIPAL
##############################################################################

.text
.globl main

main:
    # Mensaje inicial
    li $v0, 4
    la $a0, msg_inicio
    syscall
    
    # 1. INICIALIZAR TODOS LOS SENSORES
    jal InicializarSensorLuz
    jal InicializarSensorPresion
    # El sensor de tensión no necesita inicialización explícita
    
    # 2. LEER SENSOR DE LUMINOSIDAD
    jal LeerLuminosidad
    move $t0, $v0        # Guardar valor
    move $t1, $v1        # Guardar estado
    
    # Mostrar resultado
    li $v0, 4
    la $a0, msg_luz
    syscall
    
    li $v0, 1
    move $a0, $t0
    syscall
    
    li $v0, 4
    la $a0, msg_estado
    syscall
    
    li $v0, 1
    move $a0, $t1
    syscall
    
    li $v0, 4
    la $a0, msg_newline
    syscall
    
    # 3. LEER SENSOR DE PRESIÓN
    jal LeerPresion
    move $t0, $v0        # Guardar valor
    move $t1, $v1        # Guardar estado
    
    # Mostrar resultado
    li $v0, 4
    la $a0, msg_presion
    syscall
    
    li $v0, 1
    move $a0, $t0
    syscall
    
    li $v0, 4
    la $a0, msg_estado
    syscall
    
    li $v0, 1
    move $a0, $t1
    syscall
    
    li $v0, 4
    la $a0, msg_newline
    syscall
    
    # 4. LEER SENSOR DE TENSIÓN ARTERIAL
    jal controlador_tension
    move $t0, $v0        # Guardar sistólica
    move $t1, $v1        # Guardar diastólica
    
    # Mostrar resultado
    li $v0, 4
    la $a0, msg_tension
    syscall
    
    li $v0, 4
    la $a0, msg_sistolica
    syscall
    
    li $v0, 1
    move $a0, $t0
    syscall
    
    li $v0, 4
    la $a0, msg_diastolica
    syscall
    
    li $v0, 1
    move $a0, $t1
    syscall
    
    li $v0, 4
    la $a0, msg_newline
    syscall
    
    # 5. FINALIZAR PROGRAMA
    li $v0, 4
    la $a0, msg_fin
    syscall
    
    li $v0, 10
    syscall

##############################################################################
# EJERCICIO 1 - SENSOR DE LUMINOSIDAD
##############################################################################

#-----------------------------------------------------------------------------
# Procedimiento: InicializarSensorLuz
# Inicializa el sensor de luminosidad y espera a que esté listo
# No recibe parámetros
# No retorna valor
#-----------------------------------------------------------------------------
InicializarSensorLuz:
    # Guardar registro de retorno
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Escribir 0x1 en LuzControl para inicializar
    li $t0, 0x1
    li $t1, LUZ_CONTROL
    sw $t0, 0($t1)
    
EsperarListoLuz:
    # Leer LuzEstado
    li $t1, LUZ_ESTADO
    lw $t0, 0($t1)
    
    # Si es 0, todavía no está listo
    beqz $t0, EsperarListoLuz
    
    # Si es -1, error de hardware
    li $t2, -1
    beq $t0, $t2, ErrorHardwareLuz
    
    # Si es 1, está listo (salir)
    li $t2, 1
    beq $t0, $t2, FinInicializarLuz
    
ErrorHardwareLuz:
    # Aquí se podría manejar el error
    # Por simplicidad, simplemente salimos
    
FinInicializarLuz:
    # Restaurar registro de retorno
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

#-----------------------------------------------------------------------------
# Procedimiento: LeerLuminosidad
# Devuelve el valor leído y código de estado
# Retorna: $v0 = valor leído, $v1 = código de estado (0 éxito, -1 error)
#-----------------------------------------------------------------------------
LeerLuminosidad:
    # Guardar registros
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Inicializar valores por defecto
    li $v0, 0
    li $v1, -1
    
    # Verificar si el sensor está listo
    li $t0, LUZ_ESTADO
    lw $t1, 0($t0)
    
    # Si no está listo (0), esperar un poco (simplificado: retornar error)
    beqz $t1, ErrorLecturaLuz
    
    # Si hay error (-1), retornar error
    li $t2, -1
    beq $t1, $t2, ErrorLecturaLuz
    
    # Si está listo (1), leer el dato
    li $t0, LUZ_DATOS
    lw $v0, 0($t0)     # Valor leído en $v0
    li $v1, 0           # Código de éxito
    
ErrorLecturaLuz:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

##############################################################################
# EJERCICIO 2 - SENSOR DE PRESIÓN
##############################################################################

#-----------------------------------------------------------------------------
# Procedimiento: InicializarSensorPresion
# Inicializa el sensor de presión
# No recibe parámetros
# No retorna valor
#-----------------------------------------------------------------------------
InicializarSensorPresion:
    # Guardar registro de retorno
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Escribir 0x5 en PresionControl para inicializar
    li $t0, 0x5
    li $t1, PRES_CONTROL
    sw $t0, 0($t1)
    
    # Restaurar y retornar
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

#-----------------------------------------------------------------------------
# Procedimiento: LeerPresion
# Lee la presión, si hay error reinicializa y reintenta una vez
# Retorna: $v0 = valor leído, $v1 = código de estado (0 éxito, -1 error)
#-----------------------------------------------------------------------------
LeerPresion:
    # Guardar registros
    addi $sp, $sp, -12
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    
    # Inicializar contador de reintentos
    li $s0, 0           # 0 = primer intento, 1 = reintento
    
IntentoLecturaPresion:
    # Esperar a que el sensor esté listo
EsperarListoPresion:
    li $t0, PRES_ESTADO
    lw $t1, 0($t0)
    
    # Si es 0, seguir esperando
    beqz $t1, EsperarListoPresion
    
    # Si es -1, error transitorio
    li $t2, -1
    beq $t1, $t2, ErrorPresion
    
    # Si es 1, lectura válida
    li $t2, 1
    beq $t1, $t2, LecturaValidaPresion
    
ErrorPresion:
    # Verificar si ya hemos reintentado
    bnez $s0, ErrorDefinitivoPresion
    
    # Reintentar una vez
    # Reinicializar sensor
    jal InicializarSensorPresion
    
    # Incrementar contador de reintentos
    li $s0, 1
    
    # Volver a intentar la lectura
    j IntentoLecturaPresion
    
ErrorDefinitivoPresion:
    # Error definitivo
    li $v0, 0
    li $v1, -1
    j FinLecturaPresion
    
LecturaValidaPresion:
    # Leer el dato
    li $t0, PRES_DATOS
    lw $v0, 0($t0)
    li $v1, 0           # Código de éxito
    
FinLecturaPresion:
    # Restaurar registros
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    addi $sp, $sp, 12
    jr $ra

##############################################################################
# EJERCICIO 3 - SENSOR DE TENSIÓN ARTERIAL
##############################################################################

#-----------------------------------------------------------------------------
# Procedimiento: controlador_tension
# Inicia medición, espera resultado y retorna valores sistólico y diastólico
# Retorna: $v0 = tensión sistólica, $v1 = tensión diastólica
#-----------------------------------------------------------------------------
controlador_tension:
    # Guardar registros
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Iniciar medición (escribir 1 en TensionControl)
    li $t0, 1
    li $t1, TENS_CONTROL
    sw $t0, 0($t1)
    
    # Esperar a que la medición esté completa
EsperarMedicion:
    li $t0, TENS_ESTADO
    lw $t1, 0($t0)
    
    # Mientras sea 0, seguir esperando
    beqz $t1, EsperarMedicion
    
    # Cuando sea 1, los resultados están listos
    # Leer tensión sistólica
    li $t0, TENS_SISTOL
    lw $v0, 0($t0)
    
    # Leer tensión diastólica
    li $t0, TENS_DIASTOL
    lw $v1, 0($t0)
    
    # Restaurar y retornar
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

##############################################################################
# FUNCIONES AUXILIARES (SIMULACIÓN)
##############################################################################

# Estas funciones son solo para simulación y prueba
# En un sistema real, los sensores estarían en el hardware

#-----------------------------------------------------------------------------
# Procedimiento: simular_sensores
# Inicializa los sensores con valores de prueba para simulación
#-----------------------------------------------------------------------------
simular_sensores:
    # Simular sensor de luz listo
    li $t0, 1
    li $t1, LUZ_ESTADO
    sw $t0, 0($t1)
    
    # Simular valor de luz (ej: 512)
    li $t0, 512
    li $t1, LUZ_DATOS
    sw $t0, 0($t1)
    
    # Simular sensor de presión listo
    li $t0, 1
    li $t1, PRES_ESTADO
    sw $t0, 0($t1)
    
    # Simular valor de presión (ej: 760)
    li $t0, 760
    li $t1, PRES_DATOS
    sw $t0, 0($t1)
    
    # Simular sensor de tensión listo
    li $t0, 1
    li $t1, TENS_ESTADO
    sw $t0, 0($t1)
    
    # Simular valores de tensión (ej: 120/80)
    li $t0, 120
    li $t1, TENS_SISTOL
    sw $t0, 0($t1)
    
    li $t0, 80
    li $t1, TENS_DIASTOL
    sw $t0, 0($t1)
    
    jr $ra

##############################################################################
# DATOS PARA MENSAJES
##############################################################################

.data
msg_inicio:    .asciiz "\n=== INICIANDO SISTEMA DE SENSORES ===\n"
msg_luz:       .asciiz "\nSensor Luz - Valor: "
msg_presion:   .asciiz "Sensor Presión - Valor: "
msg_tension:   .asciiz "Sensor Tensión Arterial:\n"
msg_sistolica: .asciiz "  Sistólica: "
msg_diastolica: .asciiz "\n  Diastólica: "
msg_estado:    .asciiz " (Estado: "
msg_newline:   .asciiz ")\n"
msg_fin:       .asciiz "\n=== PROGRAMA FINALIZADO ===\n"

##############################################################################
# FIN DEL PROGRAMA
##############################################################################