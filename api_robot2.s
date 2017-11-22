.global set_motor_speed
.global set_motors_speed
.global read_sonar
.global read_sonars
.global register_proximity_callback
.global add_alarm
.global get_time
.global set_time

.text
.align 4

set_motor_speed:
    push {r7, lr}

    mov r1, r0
    ldrb r0, [r1]                           @   Captura o id do motor
    ldrb r1, [r1, #1]                       @   Captura a velocidade definida pro motor

    mov r7, #18                             @   Define a syscal 18, set_motor_speed
    svc 0x0

    pop {r7, pc}

set_motors_speed:
    push {r2, r7, lr}

    ldrb r2, [r0]

    cmp r2, #1                          @   Caso r0.id == 1, faz um exchange dele com r1
    moveq r2, r0
    moveq r0, r1
    moveq r1, r2

    ldrb r2, [r0]
    cmp r2, #0
    bne end_set_motors                  @   Se mesmo aphos o exchange, r0.id != 0, sai da funcao

    ldrb r0, [r0, #1]                   @   Armazena em r0 a velocidade definida para motor0

    ldrb r2, [r1]
    cmp r2, #1                          @   Se r1.id != 1, sai da funcao
    bne end_set_motors

    ldrb r1, [r1, #1]                   @   Armazena em r1 a velocidade definida para motor1

    mov r7, #19                         @   Indica em r7 a syscall set_motors_speed

    svc 0x0

    end_set_motors:
        pop {r2, r7, pc}

read_sonar:
    push {r7, lr}

    mov r1, #255                        @   Seta mascara 11111111
    mov r0, r0
    and r0, r0, r1                      @   Limpa os 8 bits finais
    mov r7, #16
    svc 0x0

    pop {r7, pc}

read_sonars:
    push {r4, r5, r6, r7, lr}

    cmp r0, r1                          @   Caso r0 > r1, realiza um exchange
    movgt r4, r0
    movgt r0, r1
    movgt r1, r4

    mov r4, r0
    mov r5, r1
    mov r6, r2                          @   Salva em r6 a base do vetor de distancias

    loop:
        cmp r4, r5
        bgt end_read_sonars             @   Caso r4 > r5, sai do loop

        mov r0, r4
        mov r7, #16
        svc 0x0

        strb r0, [r6]
        add r6, r6, #1

        add r4, r4, #1
        b loop

    end_read_sonars:
        pop {r4, r5, r6, r7, pc}

register_proximity_callback:
    push {r7, lr}

    mov r7, #17
    svc 0x0

    pop {r7, pc}

get_time:
    push {r5, r7, lr}

    mov r5, r0

    mov r7, #20
    svc 0x0

    str r0, [r5]

    pop {r5, r7, pc}

set_time:
    push {r7, lr}

    mov r7, #21
    svc 0x0

    pop {r7, pc}

add_alarm:
    push {r7, lr}

    mov r7, #22
    svc 0x0

    pop {r7, pc}
