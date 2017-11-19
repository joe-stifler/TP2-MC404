
@ Secao de constantes

@ Constante para os ciclos do relogio de perifeİricos
.set TIME_SZ,                       0x00000064

@ Constante para o intervalo entre as verificacoes do estado dos sonares
.set DIST_INTERVAL,                 100

@ Constante utilizada no delay do processo de leitura dos sonares
.set DELAY_READ_SONAR,              0x00001200

@ Constantes referentes a maxima quantidade de alarmes e callbacks
.set MAX_ALARMS,                    0x00000008
.set MAX_CALLBACKS,                 0x00000008

@ Constantes para os enderecos do TZIC
.set TZIC_BASE,		                0x0FFFC000
.set TZIC_INTCTRL,	                0x00000000
.set TZIC_INTSEC1,	                0x00000084
.set TZIC_ENSET1,	                0x00000104
.set TZIC_PRIOMASK,	                0x0000000C
.set TZIC_PRIORITY9,                0x00000424

@ Constantes para os enderecos do GPT
.set GPT_CR,		                0x53FA0000
.set GPT_PR,		                0x53FA0004
.set GPT_SR,		                0x53FA0008
.set GPT_IR,		                0x53FA000C
.set GPT_OCR1,		                0x53FA0010

@ Constantes para os enderecos do GPIO
.set GPIO_DR,                       0x53F84000
.set GPIO_GDIR,                     0x53F84004
.set GPIO_PSR,                      0x53F84008

.section .iv,"a"

_start:

INTERRUPT_VECTOR:
    .org 0x0
        b RESET_HANDLER
    .org 0x08
        b SVC_HANDLER
    .org 0x18
        b IRQ_HANDLER

.org 0x100
.text

RESET_HANDLER:
    ldr r1, =CONTADOR
    mov r0, #0
    str r0, [r1]                    @ Zera o relogio

    ldr r1, =NUM_ALARMS
    mov r0, #0
    strb r0, [r1]                   @ Zera o numero de alarmes

    ldr r1, =NUM_CALLBACKS
    mov r0, #0
    str r0, [r1]                    @ Zera o numero de callbacks

    mov r0, #-1                     @ Inicializo vetor de callback com -1 (pos vazia)
    ldr r2, =MAX_CALLBACKS          @ Quantidade maxima de iteracoes
    ldr r1, =VEC_CALLBACK           @ Base do vetor
    INIT_LOOP_CALLBACK:
        cmp r2, #0
        sub r2, r2, #1

        strgt r0, [r1]              @ vetor_callback[i] = -1
        addgt r1, r1, #12           @ Incrementa o indice do vetor
        bgt INIT_LOOP_CALLBACK

    ldr r0, =INTERRUPT_VECTOR       @ Ajusta valor do registrador que mantem
    mcr p15, 0, r0, c12, c0, 0      @   o endereco da tabela de interrupcoes

    ldr sp, =INICIO_PILHA_SVC

    msr CPSR_c, #0x12               @ Muda para o modo IRQ
    ldr sp, =INICIO_PILHA_IRQ       @ Configura inicio da pilha do modo IRQ

    msr CPSR_c, #0x11               @ Muda para o modo FIQ
    ldr sp, =INICIO_PILHA_FIQ       @ Configura inicio da pilha do modo IRQ

    bl SET_TZIC                     @ Configura TZIC
    bl SET_GPT                      @ Configura GPT
    bl SET_GPIO                     @ Configura GPIO

    msr CPSR_c, #0x10	            @ Muda para o modo usuario, habilitando interrupcoes
    ldr sp, =INICIO_PILHA_USER

    ldr r0, =0x77812000             @ .text do codigo usuario deve comecar em 0x77812000
    blx r0

    laco:
        b laco                      @ Apos termino de execucao do codigo do usuario,
                                    @   entra em laco infinito e espera por uma interrupcao

SET_TZIC:
    ldr r1, =TZIC_BASE              @ Liga o controlador de interrupcoes

    mov r0, #(1 << 7)               @ Configura interrupcao 39 do GPT como nao segura
    str r0, [r1, #TZIC_INTSEC1]

    mov r0, #(1 << 7)               @ Habilita interrupcao 39 (GPT)
    str r0, [r1, #TZIC_ENSET1]

    ldr r0, [r1, #TZIC_PRIORITY9]
    bic r0, r0, #0xFF000000
    mov r2, #1                      @ Configure interrupt39 priority como 1
    orr r0, r0, r2, lsl #24
    str r0, [r1, #TZIC_PRIORITY9]

    eor r0, r0, r0                  @ Configure PRIOMASK as 0
    str r0, [r1, #TZIC_PRIOMASK]

    mov r0, #1                      @ Habilita o controlador de interrupcoes
    str r0, [r1, #TZIC_INTCTRL]

    mov pc, lr

SET_GPT:
    ldr r1, =GPT_CR
    mov r0, #0x41                   @ Inicializo o control register com 0x41
    str r0, [r1]

    ldr r1, =GPT_PR
    mov r0, #0                      @ Inicializo o prescaler register com 0x0
    str r0, [r1]

    ldr r1, =GPT_IR
    mov r0, #1                      @ Demonstra interesse na interrupcao
    str r0, [r1]                    @   do tipo Output Compare Channel 1

    ldr r1, =GPT_OCR1
    ldr r0, =TIME_SZ                @ Configura o GPT para contar ateh TIME_SZ
    str r0, [r1]

    mov pc, lr

SET_GPIO:
    ldr r0, =0xFFFC003E             @ Move a mascara responsavel por setar a
    ldr r1, =GPIO_GDIR              @   entrada ou saida para o registrador GDIR
    str r0, [r1]

    mov r0, #0
    ldr r1, =GPIO_DR                @ Zera registrador DR por seguranca
    str r0, [r1]

    mov pc, lr

IRQ_HANDLER:
    sub	lr, lr, #4                  @ Recupera valor correto de pc
    push {r0, r1, lr}

    ldr r1, =GPT_SR
    mov r0, #1                      @ Indica para o GPT, pelo registrador de status
    str r0, [r1]                    @ que o processador estah ciente da interrupcao

    @ incrementando relogio do sistema
    ldr r1, =CONTADOR
    ldr r0, [r1]
    add r0, r0, #1
    str r0, [r1]

    bl RUN_ALARM                    @ Procura alarmes para ativar no tempo incrementado

    @ Incrementa CONTADOR_CALLBACK
    ldr r2, =DIST_INTERVAL
    ldr r1, =CONTADOR_CALLBACK
    ldr r0, [r1]

    cmp r0, r2                      @ Verifica se jah passou DIST_INTERVAL ciclos
    movge r0, #0                    @ Neste caso, zera contador dos ciclos de distancia
    addlt r0, r0, #1                @ Do contrario, incrementa contador
    str r0, [r1]                    @ Atualiza valor do contador_callback de qualquer forma

    blge RUN_CALLBACK               @ E em caso de ter se passado DIST_INTERVAL
                                    @   ciclos, verifica o estado dos sonares
    pop {r0, r1, lr}
    movs pc, lr                     @ retorna ao estado antigo

SVC_HANDLER:
    cmp r7, #1                      @ Verifica chamada de syscall do pelo proprio S.O.
    moveq r7, lr
    bleq MUDA_MODO1

    cmp r7, #2                      @ Verifica chamada de syscall do pelo proprio S.O.
    moveq r7, lr
    bleq MUDA_MODO2

    cmp r7, #16
    moveq r7, lr
    bleq READ_SONAR

    cmp r7, #17
    moveq r7, lr
    bleq REGISTER_PROXIMITY_CALLBACK

    cmp r7, #18
    moveq r7, lr
    bleq SET_MOTOR_SPEED

    cmp r7, #19
    moveq r7, lr
    bleq SET_MOTORS_SPEED

    cmp r7, #20
    moveq r7, lr
    bleq GET_TIME

    cmp r7, #21
    moveq r7, lr
    bleq SET_TIME

    cmp r7, #22
    moveq r7, lr
    bleq SET_ALARM

    movs pc, r7                     @ Retorna ao modo usuario


MUDA_MODO1:
    ldr r1, =TEMPO_DIFERENTE
    cmp r7, r1
    msreq CPSR_c, #0x12             @ Volta pro modo irq com interrupcoes
    beq TEMPO_DIFERENTE

    mov pc, lr

MUDA_MODO2:
    ldr r1, =ATUALIZA_INDICES_CALLBACK
    cmp r7, r1
    msreq CPSR_c, #0xD2             @ Volta pro modo irq com interrupcoes
    beq ATUALIZA_INDICES_CALLBACK

    mov pc, lr

READ_SONAR:
    push {r1, r2, r3, r4}

    cmp r0, #0
    movlt r0, #-1                   @ Caso identificador do sonar seja
    blt END_READ_SONAR              @    menor que 0, nao realiza a leitura

    cmp r0, #15
    movgt r0, #-1                   @ Caso identificador do sonar seja
    bgt END_READ_SONAR              @   maior que 15, nao realiza a leitura

    lsl r0, r0, #2                  @ Move conteudo de r0 dois pinos para e
                                    @    esquerda, de forma a ignorar pinos flag e trigger
    ldr r1, =GPIO_DR
    ldr r2, [r1]                    @ Le conteudo do registrador DR
    mvn r3, #60                     @ Seta a negacao da mascara 111100
                                    @   (de forma a desabilitar os bits de sonar_mux)

    and r2, r2, r3                  @ Efetivamente, desativa tais bits
    orr r0, r0, r2                  @ Reativa somente os bits especificados na entrada
    str r0, [r1]                    @ Atualizo valor do registrador DR

    ldr r2, =DELAY_READ_SONAR

    DELAY_1:
        subs r2, r2, #1
        bne DELAY_1                 @ Continua no loop enquanto nao tiver passado 15ms

    orr r0, r0, #2                  @ Ativo o pino do trigger atraves da mascara 10
    str r0, [r1]                    @ Atualizo valor do registrador DR

    ldr r2, =DELAY_READ_SONAR

    DELAY_2:
        subs r2, r2, #1
        bne DELAY_2                 @ Continua no loop enquanto nao tiver passado 15ms

    eor r0, r0, #2                  @ Desativo o mesmo pino do trigger atraves da mascara 10
    str r0, [r1]                    @ Atualizo valor do registrador DR

    WAIT_FLAG:
        ldr r0, [r1]                @ Le o conteudo do registrador DR

        mov r2, #1
        and r2, r2, r0              @ Verifica se o primeiro bit (flag) estah setada

        cmp r2, #1
        ldreq r2, =4095             @ mascara 111111111111
        andeq r0, r2, r0, lsr #6    @ Desloca conteudo de r0, de forma a
                                    @   ignorar pinos flag, trigger e sonar_mux

        @ Falta aplicar a formula do fabricante time / 58 distance (cm)

        beq END_READ_SONAR

        ldr r2, =DELAY_READ_SONAR

        DELAY_3:
            subs r2, r2, #1
            bne DELAY_3             @ Continua no loop enquanto nao tiver passado 15ms

        b WAIT_FLAG                 @ Retorna para a verificacao do pino da flag

    END_READ_SONAR:
        pop {r1, r2, r3, r4}
        mov pc, lr                  @ Recupera estado de pc

REGISTER_PROXIMITY_CALLBACK:
    push {r3-r5}

    ldr r3, =MAX_CALLBACKS
    ldr r4, =NUM_CALLBACKS
    ldr r5, [r4]

    cmp r5, r3
    movge r0, #-1                   @ Caso limite de callbacks jah tenha
    bge END_REGISTER_CALLBACK       @   sido atingido nao realiza nenhuma acao

    cmp r0, #0
    movlt r0, #-2                   @ Caso identificador do sonar seja menor
    blt END_REGISTER_CALLBACK       @   do que 0, nao realiza nenhuma acao

    cmp r0, #15
    movgt r0, #-2                   @ Caso identificador do sonar seja maior
    bgt END_REGISTER_CALLBACK       @   do que 15, nao realiza nenhuma acao

    add r5, r5, #1                  @ Atualiza quantidade de callbacks ativas
    str r5, [r4]

    ldr r4, =VEC_CALLBACK           @ Base do vetor de callbacks
    REGISTER_CALLBACK_LOOP:
        cmp r3, #0
        ble END_REGISTER_CALLBACK

        ldr r5, [r4]
        cmp r5, #-1                 @ Caso posicao esteja vazia, armazena nova callback
        streq r0, [r4]              @ Salva id do sonar a se monitorar
        streq r1, [r4, #4]          @ Salva seu limiar de distancia
        streq r2, [r4, #8]          @ Salva endereco de funcao a se chamar quando atingir limiar
        moveq r0, #0                @ Indica que nenhum erro ocorreu
        beq END_REGISTER_CALLBACK

        sub r3, r3, #1              @ Atualiza indices
        add r4, r4, #12

        b REGISTER_CALLBACK_LOOP

    END_REGISTER_CALLBACK:
        pop {r3-r5}
        mov pc, lr

SET_MOTOR_SPEED:
    push {r2}

    cmp r0, #0
    movlt r0, #-1                   @ Caso conteudo de r0 nao seja 0 ou 1,
    blt END_SET_MOTOR

    cmp r0, #1
    movgt r0, #-1                   @ Caso conteudo de r0 nao seja 0 ou 1,
    bgt END_SET_MOTOR

    cmp r1, #0
    movlt r0, #-2                   @ Caso conteudo de r1 < 0,   retorna
    blt END_SET_MOTOR

    cmp r1, #63
    movgt r0, #-2                   @ Caso conteudo de r1 > 63, retorna
    bgt END_SET_MOTOR

    cmp r0, #1
    beq WRITE_MOTOR1

    WRITE_MOTOR0:
        ldr r2, =GPIO_DR
        ldr r0, [r2]                @ Carrega conteudo do registrador DR
        lsr r0, r0, #18             @ [r0] movido pra direita, preservando velocidade de motor1
        and r0, r0, #16256          @ Desativa os sete primeiros bits
        lsl r1, r1, #1              @ Ignora pino de write do motor0 (setando-o para 0)
        orr r0, r0, r1              @ Por fim, concatena velocidade do motor0 com a do motor1
        lsl r0, r0, #18             @ Retorna posicao dos bits ao estado correto

        str r0, [r2]
        mov r0, #0                  @ Indica que nenhum erro ocorreu
        b END_SET_MOTOR

    WRITE_MOTOR1:
        ldr r2, =GPIO_DR
        ldr r0, [r2]                @ Carrega conteudo do registrador DR
        lsr r0, r0, #18             @ [r0] movido pra direita, preservando velocidade de motor2
        orr r0, r0, #127            @ Desativa os sete ultimos bits
        lsl r1, r1, #8              @ Ignora pino de write do motor1 (setando-o para 1)
        orr r0, r0, r1              @ Por fim, concatena velocidade do motor0 com a do motor1
        lsl r0, r0, #18             @ Retorna posicao dos bits ao estado correto

        str r0, [r2]
        mov r0, #0                  @ Indica que nenhum erro ocorreu

    END_SET_MOTOR:
        pop {r2}
        mov pc, lr

SET_MOTORS_SPEED:
    cmp r0, #0
    movlt r0, #-1                   @ Caso conteudo de r0 < 0, retorna erro -1
    movlt pc, lr                    @ e nao realiza a escrita

    cmp r0, #63
    movgt r0, #-1                   @ Caso conteudo de r0 > 63,  retorna
    movgt pc, lr                    @    erro -1 e nao realiza a escrita

    cmp r1, #0
    movlt r0, #-2                   @ Caso conteudo de r1 < 0,   retorna
    movlt pc, lr                    @    erro -2 e nao realiza a escrita

    cmp r1, #63
    movgt r0, #-2                   @ Caso conteudo de r1 > 63, retorna
    movgt pc, lr                    @   erro -2 e nao realiza a escrita

    lsl r0, r0, #19                 @ Desloca bits para posicoes referentes aos pinos de speed
    orr r0, r0, r1, lsl #26         @ Desloca conteudo de r1 pra esquerda, para
                                    @   que seja concatenado com conteudo de r0

    ldr r1, =GPIO_DR
    str r0, [r1]

    mov r0, #0                      @ Indica que nenhum erro ocorreu

    mov pc, lr

GET_TIME:
    ldr r1, =CONTADOR
    ldr r1, [r1]

    str r1, [r0]

    mov pc, lr

GET_TIME2:
    ldr r0, =CONTADOR
    ldr r0, [r0]

    mov pc, lr

SET_TIME:
    push {r1}

    ldr r1, =CONTADOR
    str r0, [r1]

    pop {r1}
    mov pc, lr

SET_ALARM:
    push {r1-r6, lr}

    @checando se o tempo eh valido

    mov r4, r0						@ copia do endereco da funcao
    bl GET_TIME2 					@ r0 <- tempo do sistema
    cmp r0, r1
    movhs r0, #-2					@ r0 >= r1
    bhs SET_ALARM_EXIT
    mov r0, r4

    ldr r3, =MAX_ALARMS
    ldr r4, =NUM_ALARMS
    ldr r2, [r4]

    cmp r2, r3
    movge r0, #-1                   @ Caso nhumero mhaximo de alarmes jah foi
    bge SET_ALARM_EXIT              @ atingido, seta -1 em r0 e retorna da syscall,

    add r2, r2, #1                  @ sem armazenar novo alarme no vetor de alarmes
    str r2, [r4]					@ sen�£o, aumenta o contador de alarmes

    ldr r3, =TIME_ALARMS
    ldr r4, =FLAG_ALARMS
    ldr r6, =FUNC_ALARMS
    mov r2, #0

    @ procurando a primeira pos livre do vetor
    ALARM_LOOP:
        ldr r5, =MAX_ALARMS
		cmp r2, r5
		bge ALARM_FIM_LOOP

		ldr r5, [r4] 		       @ FLAG_ALARMS[n*4]
		cmp r5, #0
		bne POS_CHEIA

		@ encontrada posicao livre, preenchendo os vetores
		mov r5, #1
		str r5, [r4] 		       @ FLAG_ALARMS[n*4] <- 1
		str r0, [r6] 		       @ FUNC_ALARMS[n*4] <- r0
		str r1, [r3] 		       @ TIME_ALARMS[n*4] <- r1
		b ALARM_FIM_LOOP

		POS_CHEIA:
    		add r3, r3, #4
    		add r4, r4, #4
    		add r6, r6, #4
    		add r2, r2, #1
    		b ALARM_LOOP

    ALARM_FIM_LOOP:
        mov r0, #0                 @ Indica que nenhum erro ocorreu

	SET_ALARM_EXIT:
        pop {r1-r6, lr}
        mov pc, lr

RUN_ALARM:
	push {r0-r6, lr}

	ldr r0, =TIME_ALARMS
	ldr r1, =FUNC_ALARMS
	ldr r2, =FLAG_ALARMS
	mov r3, #0
	ldr r4, =CONTADOR
	ldr r4, [r4] @ r4 <- tempo do sistema

	RUN_ALARM_LOOP:
        ldr r5, =MAX_ALARMS
		cmp r3, r5
		bge FIM_RUN_LOOP

		ldr r5, [r0, r3, lsl #2]    @ r5 <- TIME_ALARMS[n*4]
		cmp r5, r4
		bne TEMPO_DIFERENTE

		@ r4 == r5 : ativar o alarme n
		mov r5, #0
		ldr r6, [r1, r3, lsl #2]    @ r6 <- endereco da funcao
		str r5, [r2, r3, lsl #2]    @ FLAG_ALARMS[n*4] <- LIVRE
		str r5, [r1, r3, lsl #2]    @ FUNC_ALARMS[n*4] <- LIVRE
		str r5, [r0, r3, lsl #2]    @ TIME_ALARMS[n*4] <- LIVRE

        @ Atualiza numero de alarmes ativos
        ldr r5, =NUM_ALARMS
        ldr r7, [r5]
        sub r7, r7, #1
        str r7, [r5]

		@ executando r6 em modo IRQ com interrupcoes
		msr CPSR_c, #0x10
		blx r6

        mov r7, #1                  @ Chama syscall para retornar ao modo irq
        svc 0x0

		TEMPO_DIFERENTE:
    		add r3, r3, #1
    		b RUN_ALARM_LOOP

	FIM_RUN_LOOP:
    	pop {r0-r6, lr}
    	mov pc, lr

RUN_CALLBACK:
    push {r0-r5, r7, lr}

    ldr r4, =MAX_CALLBACKS
    ldr r5, =VEC_CALLBACK           @ Base do vetor de callback
    RUN_CALLBACK_LOOP:
        cmp r4, #0
        ble END_RUN_CALLBACK

        ldr r0, [r5]                @ Le o id do sonar
        cmp r0, #-1                 @ Nao analisa posicao vazia
        beq ATUALIZA_INDICES_CALLBACK

        bl READ_SONAR
        ldr r1, [r5, #4]            @ Le o limiar para esse sonar

        cmp r0, r1                  @ Verifica o sonar atingiu seu limiar de distancia
        bge ATUALIZA_INDICES_CALLBACK

        ldr r2, [r5, #8]            @ Carrega em r2 o endereco da funcao
        mov r0, #-1
        str r0, [r5]                @ Desativa callback

        ldr r0, =NUM_CALLBACKS
        ldr r7, [r0]
        sub r7, r7, #1
        str r7, [r0]                @ Atualiza a quantidade de callbacks ativas

        msr CPSR_c, #0xD0           @ Muda modo para usuario sem interrupcoes
        blx r2                      @ E salta para o endereco da respectiva funcao

        mov r7, #2                  @ Chama syscall para retornar ao modo irq
        svc 0x0

        ATUALIZA_INDICES_CALLBACK:
            sub r4, r4, #1
            add r5, r5, #12

        b RUN_CALLBACK_LOOP

    END_RUN_CALLBACK:
        pop {r0-r5, r7, lr}
        mov pc, lr

@ Secao de dados

.data
    .align 4

    CONTADOR: .space 4
    CONTADOR_CALLBACK: .space 4

    NUM_ALARMS: .space 4            @ Numero de alarmes ativos (inicialmente 0). Suporta athe 13 alarmes
	FLAG_ALARMS: .space 52			@ flag_alarms[i] informa a existencia de um alarme
    TIME_ALARMS: .space 52      	@ time_alarms[i] contem o tempo que o alarme deve ser ativado
    FUNC_ALARMS: .space 52			@ func_alarms[i] contem o endereco da funcao associada ao alarme

    NUM_CALLBACKS: .space 4         @ Numero de callbacks ativas (inicialmente 0). Suporta athe 13 callbacks
    VEC_CALLBACK: .space 156        @ vec_callback[i][0] <- id do sonar, -1 para linha i vazia
                                    @ vec_callback[i][1] <- limiar de distancia
                                    @ vec_callback[i][2] <- ponteiro para funcao a ser chamada

    .space 500
    INICIO_PILHA_SVC:   .space 500
    INICIO_PILHA_IRQ:   .space 500
    INICIO_PILHA_FIQ:   .space 500
    INICIO_PILHA_USER:  .space 1
