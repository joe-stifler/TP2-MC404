
@ Secao de constantes

@ Constante para os ciclos do relogio de perifericos
.set TIME_SZ,                       0x000000C8

@ Constante para o intervalo entre as verificacoes do estado dos sonares
.set DIST_INTERVAL,                 0x00000019

@ Constante utilizada no delay do processo de leitura dos sonares
.set DELAY_READ_SONAR,              0x00000320

@ Constantes referentes a maxima quantidade de alarmes e callbacks
.set MAX_ALARMS,                    0x00000008
.set MAX_CALLBACKS,                 0x00000008

@ Constantes para os enderecos do TZIC
.set TZIC_BASE,                     0x0FFFC000
.set TZIC_INTCTRL,                  0x00000000
.set TZIC_INTSEC1,                  0x00000084
.set TZIC_ENSET1,                   0x00000104
.set TZIC_PRIOMASK,                 0x0000000C
.set TZIC_PRIORITY9,                0x00000424

@ Constantes para os enderecos do GPT
.set GPT_CR,                        0x53FA0000
.set GPT_PR,                        0x53FA0004
.set GPT_SR,                        0x53FA0008
.set GPT_IR,                        0x53FA000C
.set GPT_OCR1,                      0x53FA0010

@ Constantes para os enderecos do GPIO
.set GPIO_DR,                       0x53F84000
.set GPIO_GDIR,                     0x53F84004
.set GPIO_PSR,                      0x53F84008

.section .iv,"a"

_start:

INTERRUPT_VECTOR:
    .org 0x0                        @ Reset
        b RESET_HANDLER
    .org 0x4                        @ Undefined Instruction (instrucao invalida foi encontrada)
        b UNINPLEMENTED_HANDLER
    .org 0x08                       @ Software interrupt
        b SVC_HANDLER
    .org 0x0C                       @ Abort (barramento gerou um erro)
        b UNINPLEMENTED_HANDLER
    .org 0x18                       @ IRQ interrupt
        b IRQ_HANDLER

.org 0x100
.text

@@
@ Chamado quando ocorrer uma interrupcao inesperada. Neste caso, reseta o estado da maquina.
@@
UNINPLEMENTED_HANDLER:
    b RESET_HANDLER

@@
@ Inicializa variaveis, o inicio da pilha dos modos utilizados (SVC, IRQ, USER) e realiza
@   as configuracoes das interrupcoes, relogio do sistema,alem da entrada e saida. Aphos,
@   realiza um salto para o inicio do programa do usuario.
@@
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

    msr cpsr_c, #0x12               @ Muda para o modo IRQ
    ldr sp, =INICIO_PILHA_IRQ       @ Configura inicio da pilha do modo IRQs

    bl SET_TZIC                     @ Configura TZIC
    bl SET_GPT                      @ Configura GPT
    bl SET_GPIO                     @ Configura GPIO

    msr cpsr_c, #0x10	            @ Muda para o modo usuario, habilitando interrupcoes
    ldr sp, =INICIO_PILHA_USER

    ldr r0, =0x77812000             @ .text do codigo usuario deve comecar em 0x77812000
    blx r0

    laco:
        b laco                      @ Apos termino de execucao do codigo do usuario,
                                    @   entra em laco infinito e espera por uma interrupcao

@@
@ Configura as interrupcoes do sistema.
@@
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

@@
@ Configura o relogio do sistema.
@@
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

@@
@ Configura a entrada e saida do sistema.
@@
SET_GPIO:
    ldr r0, =0xFFFC003E             @ Move a mascara responsavel por setar a
    ldr r1, =GPIO_GDIR              @   entrada ou saida para o registrador GDIR
    str r0, [r1]

    mov r0, #0
    ldr r1, =GPIO_DR                @ Zera registrador DR por seguranca
    str r0, [r1]

    mov pc, lr

@@
@ Trata as interrupcoes, no caso geradas pela relogio do sistema. Aproveita e verifica
@   a existencia de algum alarme que necessita ser ativado no exato periodo de tempo.
@   verifica tambem o estado das callbacks.
@@
IRQ_HANDLER:
    sub	lr, lr, #4                  @ Recupera valor correto de pc
    push {r0-r12, lr}               @ Salva o contexto atual de forma a nao corrompe-lo

    mrs r4, spsr                    @ Salva o estado atual do registrador SPSR
    push {r4}

    ldr r1, =GPT_SR
    mov r0, #1                      @ Indica para o GPT, pelo registrador de status
    str r0, [r1]                    @ que o processador estah ciente da interrupcao

    ldr r1, =CONTADOR
    ldr r0, [r1]                    @ Le estado atual do relogio do sistema
    add r0, r0, #1                  @ Incrementa em uma unidade tal valor
    str r0, [r1]                    @ E atualiza valor obtido no relogio do sistema

    bl RUN_ALARM                    @ Procura alarmes para ativar no tempo incrementado

    ldr r2, =DIST_INTERVAL
    ldr r1, =CONTADOR_CALLBACK
    ldr r0, [r1]                    @ Le valor do estador atual do contador de callbacks

    cmp r0, r2                      @ Verifica se jah passou DIST_INTERVAL ciclos
    movge r0, #0                    @ Neste caso, zera contador dos ciclos de distancia
    addlt r0, r0, #1                @ Do contrario, incrementa contador
    str r0, [r1]                    @ Atualiza valor do contador_callback de qualquer forma
    blge RUN_CALLBACK               @ E em caso de ter se passado DIST_INTERVAL
                                    @   ciclos, verifica o estado dos sonares

    END_IRQ:
        pop {r4}
        msr spsr, r4                @ Restaura estado anterior do registrador SPSR

        pop {r0-r12, lr}
        movs pc, lr                 @ retorna ao estado antigo

@@
@ Trata as interrupcoes de software, ignorando syscalls nao esperadas pelo sistema.
@@
SVC_HANDLER:
    cmp r7, #1                      @ Verifica chamada de syscall do pelo proprio S.O. (run_alarm)
    moveq r7, lr
    bleq MUDA_MODO1

    cmp r7, #2                      @ Verifica chamada de syscall do pelo proprio S.O. (run_callback)
    moveq r7, lr
    bleq MUDA_MODO2

    push {r4, lr}
    mrs r4, spsr                    @ Salva o estado atual do registrador SPSR
    push {r4}

    cmp r7, #16
    bleq READ_SONAR

    cmp r7, #17
    bleq REGISTER_PROXIMITY_CALLBACK

    cmp r7, #18
    bleq SET_MOTOR_SPEED

    cmp r7, #19
    bleq SET_MOTORS_SPEED

    cmp r7, #20
    bleq GET_TIME

    cmp r7, #21
    bleq SET_TIME

    cmp r7, #22
    bleq SET_ALARM

    pop {r4}
    msr spsr, r4                    @ Restaura estado anterior do registrador SPSR

    pop {r4, lr}
    movs pc, lr                     @ Retorna ao modo anterior a chamada da syscall

@@
@ Chaveia para o modo IRQ sem interrupcoes somente se o run_alarm chamou tal syscall. Do contrario, ignora chamada.
@@
MUDA_MODO1:
    ldr r1, =TEMPO_DIFERENTE
    cmp r7, r1
    msreq cpsr_c, #0xD2             @ Volta pro modo irq sem interrupcoes
    beq TEMPO_DIFERENTE             @ E continua no loop do alarme

    push {lr}
    mov lr, r7
    mov r7, #1
    pop {pc}

@@
@ Chaveia para o modo IRQ sem interrupcoes somente se o run_callback chamou tal syscall. Do contrario, ignora chamada.
@@
MUDA_MODO2:
    ldr r1, =ATUALIZA_INDICES_CALLBACK
    cmp r7, r1
    msreq cpsr_c, #0xD2             @ Volta pro modo irq sem interrupcoes
    beq ATUALIZA_INDICES_CALLBACK   @ E continua no loop do callback

    push {lr}
    mov lr, r7
    mov r7, #2
    pop {pc}

@@
@ Realiza a leitura de um dado sonar.
@
@ Parametros:
@     r0: identificador do sonar (0 a 15 somente)
@ Retorno:
@     r0: valor obtido na leitura dos sonares;
@         -1 caso id do sonar seja invalido
@@
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
        ldreq r2, =4095             @ Mascara 111111111111
        andeq r0, r2, r0, lsr #6    @ Desloca conteudo de r0, de forma a
                                    @   ignorar pinos flag, trigger e sonar_mux

        beq END_READ_SONAR

        ldr r2, =DELAY_READ_SONAR

        DELAY_3:
            subs r2, r2, #1
            bne DELAY_3             @ Continua no loop enquanto nao tiver passado 15ms

        b WAIT_FLAG                 @ Retorna para a verificacao do pino da flag

    END_READ_SONAR:
        pop {r1, r2, r3, r4}
        mov pc, lr                  @ Recupera estado de pc

@@
@ Armazena um callback no vetor de callbacks para ser inspecionada a uma certa taxa de tempo.
@
@ Parametros:
@     r0: identificador do sonar (0 a 15 somente)
@     r1: limiar de distancia
@     r2: ponteiro da funcao a ser chamada na ocorrencia do evento
@ Retorno:
@     r0: -1 caso nhumero maximo de callbacks jah atingido;
@         -2 caso id do sonar invalido;
@          0 do contrario.
@@
REGISTER_PROXIMITY_CALLBACK:
    push {r3-r5}

    mrs r4, cpsr
    orr r4, r4, #0xC0               @ Desabilita interrupcoes (IRQ e FIQ)
                                    @   durante a insercao de um novo callback
    msr cpsr_c, r4

    ldr r3, =MAX_CALLBACKS
    ldr r4, =NUM_CALLBACKS
    ldr r5, [r4]

    cmp r5, r3
    movge r0, #-1                   @ Caso limite de callbacks ativas jah tenha
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
        streq r0, [r4]              @ Salva id do sonar a se monitorar, vec_callback[indice][0]
        streq r1, [r4, #4]          @ Salva seu limiar de distancia, vec_callback[indice][1]
        streq r2, [r4, #8]          @ Salva endereco de funcao a se chamar quando atingir limiar
        moveq r0, #0                @ Indica que nenhum erro ocorreu
        beq END_REGISTER_CALLBACK

        sub r3, r3, #1              @ Atualiza indices
        add r4, r4, #12

        b REGISTER_CALLBACK_LOOP

    END_REGISTER_CALLBACK:
        mrs r4, cpsr                @ Reativa interrupcoes (IRQ e FIQ)
        bic r4, r4, #0xC0           @   setando seus respectivos bits para 0
        msr cpsr_c, r4

        pop {r3-r5}
        mov pc, lr

@@
@ Seta a velocidade de um dado motor.
@
@ Parametros:
@     r0: identificador do motor (0 a 15 somente)
@     r1: velocidade do motor
@ Retorno:
@     r0: -1 caso id do motor invalido;
@         -2 caso velocidade invalida;
@          0 do contrario.
@@
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

@@
@ Seta a velocidade de ambos os motores.
@
@ Parametros:
@     r0: velocidade para o motor 0
@     r1: velocidade para o motor 1
@ Retorno:
@     r0: -1 caso a velocidade motor0 invalida;
@         -2 caso velocidade motor1 invalida;
@          0 do contrario.
@@
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

@@
@ Le o estado atual do relogio do sistema
@
@ Retorno:
@     r0: tempo do sistema
@@
GET_TIME:
    ldr r0, =CONTADOR
    ldr r0, [r0]

    mov pc, lr

@@
@ Seta o tempo do sistema com um dado valor passado por parametro. Alem disso, elimina
@   todos os alarmes com um tempo menor ou igual do que o novo valor do relogio do sistema.
@
@ Parametros:
@     r0: tempo do sistema
@@
SET_TIME:
    push {r1, r4, lr}

    mrs r4, cpsr
    orr r4, r4, #0xC0               @ Desabilita interrupcoes (IRQ e FIQ)
                                    @   durante a mudanca do relogio do sistema
    msr cpsr_c, r4

    ldr r1, =CONTADOR
    str r0, [r1]

    bl UPDATE_ALARMS                @ Remove alarmes com um tempo menor do que o atual do sistema

    mrs r4, cpsr                    @ Reativa interrupcoes (IRQ e FIQ)
    bic r4, r4, #0xC0               @   setando seus respectivos bits para 0
    msr cpsr_c, r4

    pop {r1, r4, pc}

@@
@ Armazena um novo alarme no vetor de alarmes para ser inspecionado a uma certa taxa de tempo.
@
@ Parametros:
@     r0: ponteiro para a funcao a ser chamada na ocorrencia do alarme
@     r1: tempo que o alarme devera ser acionado
@ Retorno:
@     r0: -1 caso jah tenha atingido o nhumero maximo de alarmes;
@         -2 caso tempo seja menor do que o tempo do sistema atual;
@          0 do contrario.
@@
SET_ALARM:
    push {r1-r6, lr}

    mrs r4, cpsr
    orr r4, r4, #0xC0               @ Desabilita interrupcoes (IRQ e FIQ)
                                    @   durante a insercao de um novo alarme
    msr cpsr_c, r4

    ldr r3, =MAX_ALARMS
    ldr r4, =NUM_ALARMS
    ldr r2, [r4]                    @ Coloca em r2 a quantidade de alarmes atualmente ativos

    cmp r2, r3
    movge r0, #-1                   @ Caso nhumero mhaximo de alarmes ativos jah foi
    bge SET_ALARM_EXIT              @   atingido, seta -1 em r0 e retorna da syscall

    mov r4, r0					    @ Copia do endereco da funcao
    bl GET_TIME 				    @ Registrador r0 recebe tempo do sistema

    cmp r0, r1
    movhs r0, #-2				    @ Caso tempo atual do sistema seja maior ou igual do que r1
    bhs SET_ALARM_EXIT              @   nao armazena alarme, dando um pulo pro final de set_alarm

    mov r0, r4                      @ Coloca em r0 o endereco da funcao passada por parametro

	ldr r3, =NUM_ALARMS
    add r2, r2, #1
    str r2, [r3]				    @ Incrementa nhumero de alarmes ativos atualmente

    ldr r3, =TIME_ALARMS
    ldr r4, =FLAG_ALARMS
    ldr r6, =FUNC_ALARMS
    mov r2, #0

    ALARM_LOOP:                     @ Loop procura pela primeira posicao livre e armazena o novo alarme
        ldr r5, =MAX_ALARMS

		cmp r2, r5
		bge ALARM_FIM_LOOP

		ldr r5, [r4]   		        @ FLAG_ALARMS[indice * 4]
		cmp r5, #0
		bne POS_CHEIA               @ Caso posicao atual seja diferente de zero, ignora
                                    @    posicao atual nao vazia e atualiza os indices

		mov r5, #1
		str r5, [r4] 		        @ FLAG_ALARMS[indice * 4] recebe contehudo de 1
		str r0, [r6] 		        @ FUNC_ALARMS[indice * 4] recebe contehudo de r0
		str r1, [r3] 		        @ TIME_ALARMS[indice * 4] recebe contehudo de r1
		b ALARM_FIM_LOOP

		POS_CHEIA:
    		add r3, r3, #4
    		add r4, r4, #4
    		add r6, r6, #4
    		add r2, r2, #1          @ Atualiza os indices

    		b ALARM_LOOP

    ALARM_FIM_LOOP:
        mov r0, #0              @ Indica que nenhum erro ocorreu

	SET_ALARM_EXIT:
        mrs r4, cpsr            @ Reativa interrupcoes (IRQ e FIQ)
        bic r4, r4, #0xC0       @   setando seus respectivos bits para 0
        msr cpsr_c, r4

        pop {r1-r6, pc}

@@
@ Verifica todas as posicoes do vetor de alarmes e caso alguma posicao nao vazia,
@   esteja associada a um tempo igual ao atual do sistema, realiza um pulo com link
@   (jah no modo usuario) para a respectiva funcao associada ao alarme.
@@
RUN_ALARM:
	push {r0-r1, r4-r10, lr}

    mov r4, #0

    ldr r5, =CONTADOR
	ldr r5, [r5]                    @ Registrador r5 recebe o tempo atual do sistema

	ldr r8, =TIME_ALARMS
	ldr r9, =FUNC_ALARMS
	ldr r10, =FLAG_ALARMS           @ Base dos vetores

	RUN_ALARM_LOOP:
        ldr r0, =MAX_ALARMS

		cmp r4, r0
		bge FIM_RUN_LOOP

        mrs r0, cpsr                @ Salva o estado atual do registrador CPSR
        mrs r1, spsr                @ Salva o estado atual do registrador SPSR

        push {r0, r1}

		ldr r0, [r8, r4, lsl #2]    @ Registrador r5 recebe TIME_ALARMS[indice * 4]

		cmp r0, r5
		bne TEMPO_DIFERENTE         @ Caso tempo do alarme atual seja maior do que o do sistema
                                    @   ignora posicao atual e atualiza o indice para o proximo

		mov r0, #0
        str r0, [r8,r4,lsl #2]      @ Posicao do vetor TIME_ALARMS[indice * 4] livre
		ldr r6, [r9,r4,lsl #2]      @ Registrador r6 recebe endereco da funcao
		str r0, [r9,r4,lsl #2]      @ Posicao do vetor FUNC_ALARMS[indice * 4] livre
        str r0, [r10,r4,lsl #2]     @ Posicao do vetor FLAG_ALARMS[indice * 4] livre

        ldr r0, =NUM_ALARMS
        ldr r7, [r0]                @ Carrega em r7 quantidade atual de alarmes ativos
        sub r7, r7, #1              @ Removendo o alarme que serha executado logo em seguida
        str r7, [r0]                @ Atualiza nhumero de alarmes ativos

		msr cpsr_c, #0x10           @ Muda para o modo usuario com interrupcoes
		blx r6

        mov r7, #1                  @ Chama syscall para retornar ao modo irq sem interrupcoes
        svc 0x0

		TEMPO_DIFERENTE:
            pop {r0, r1}

            msr cpsr, r0            @ Restaura estado do registrador CPSR
            msr spsr, r1            @ Restaura estado do registrador SPSR

    		add r4, r4, #1          @ Atualiza o indice

    		b RUN_ALARM_LOOP

	FIM_RUN_LOOP:
    	pop {r0-r1, r4-r10, pc}

@@
@ Verifica todas as posicoes do vetor de callbacks e caso o a distancia detectada por um sonar,
@   presente em uma posicao nao vazia, seja menor do que o respectivo limiar, realiza um pulo com link
@   (jah no modo usuario) para a respectiva funcao associada ao callback.
@@
RUN_CALLBACK:
    push {r0-r1, r4-r7, lr}

    ldr r5, =VEC_CALLBACK           @ Base do vetor de callback
    ldr r4, =MAX_CALLBACKS          @ Nhumero maximo de posicoes do vetor a se analizar

    RUN_CALLBACK_LOOP:
        cmp r4, #0
        ble END_RUN_CALLBACK

        mrs r0, cpsr                @ Salva o estado atual do registrador CPSR
        mrs r1, spsr                @ Salva o estado atual do registrador SPSR

        push {r0, r1}

        ldr r0, [r5]                @ Le o id do sonar
        cmp r0, #-1                 @ Nao analisa posicao vazia
        beq ATUALIZA_INDICES_CALLBACK

        bl READ_SONAR
        ldr r1, [r5, #4]            @ Le o limiar para esse sonar

        cmp r0, r1                  @ Verifica se o sonar atingiu seu limiar de distancia
        bge ATUALIZA_INDICES_CALLBACK

        ldr r6, [r5, #8]            @ Caso tenha atingido, carrega em r2 o endereco da funcao
        mov r0, #-1
        str r0, [r5]                @ E desativa callback, setando vec_callback[indice][0] = -1

        ldr r0, =NUM_CALLBACKS
        ldr r7, [r0]                @ Carrega em r7 quantidade atual de callbacks ativas
        sub r7, r7, #1              @ Removendo a callback que serha executada logo em seguida
        str r7, [r0]                @ Atualiza a quantidade de callbacks ativas

        msr cpsr_c, #0x10           @ Muda modo para usuario com interrupcoes
        blx r6                      @ E salta para o endereco da respectiva funcao

        mov r7, #2                  @ Chama syscall para retornar ao modo irq com interrupcoes
        svc 0x0

        ATUALIZA_INDICES_CALLBACK:
            pop {r0, r1}

            msr cpsr, r0            @ Restaura estado anterior do registrador CPSR
            msr spsr, r1            @ Restaura estado anterior do registrador SPSR

            sub r4, r4, #1
            add r5, r5, #12         @ Atualiza o indice

        b RUN_CALLBACK_LOOP

    END_RUN_CALLBACK:
        pop {r0-r1, r4-r7, pc}

@@
@ Recebe por parametro em r0 o tempo atual do sistema e remove todos os alarmes com um tempo menor do que tal valor.
@ Parametros:
@     r0: tempo atual do sistema
@@
UPDATE_ALARMS:
    push {r4-r10}

	ldr r4, =FUNC_ALARMS
	ldr r5, =TIME_ALARMS
	ldr r6, =FLAG_ALARMS
	mov r7, #0
	ldr r8, =MAX_ALARMS				@ Registrador r8 recebe quantidade maxima de
                                    @   alarmes que podem ser aramazenados simultaneamente

	UPDATE_ALARMS_LOOP:
		cmp r7, r8
		bhs UPDATE_ALARMS_END

		ldr r9, [r5]				@ Registrador r9 recebe TIME_ALARMS[indice * 4] (tempo do alarme)
		cmp r9, r0					@  e verifica se o alarme na posicao indice * 4 deve ser removido
		bhi	UPDATE_ALARMS_CONTINUE

		mov r9, #0
		str r9, [r4]				@ Posicao do vetor FUNC_ALARMS[indice * 4] livre
		str r9, [r5]				@ Posicao do vetor TIME_ALARMS[indice * 4] livre
		str r9, [r6]				@ Posicao do vetor FLAG_ALARMS[indice * 4] livre

		ldr r9, =NUM_ALARMS
		ldr r10, [r9]				@ Carrega em r10 quantidade atual de alarmes ativos
		sub r10, r10, #1            @ Removendo o alarme que serha executado logo em seguida
		str r10, [r9]               @ Atualiza nhumero de alarmes ativos

		UPDATE_ALARMS_CONTINUE:
    		add r7, r7, #1
    		add r4, r4, #4
    		add r5, r5, #4
    		add r6, r6, #4          @ Atualiza por fim os indices

		b UPDATE_ALARMS_LOOP

	UPDATE_ALARMS_END:
    	pop {r4-r10}
    	mov pc, lr

@ Secao de dados

.data
    .align 4

    CONTADOR:
        .space 4
    CONTADOR_CALLBACK:
        .space 4

    NUM_ALARMS:                     @ Numero de alarmes ativos (inicialmente 0). Suporta athe 13 alarmes
         .space 4
	FLAG_ALARMS:           			@ Flag_alarms[i] informa a existencia de um alarme
         .space 52
    TIME_ALARMS:                  	@ Time_alarms[i] contem o tempo que o alarme deve ser ativado
         .space 52
    FUNC_ALARMS:        			@ Func_alarms[i] contem o endereco da funcao associada ao alarme
         .space 52

    NUM_CALLBACKS:                  @ Numero de callbacks ativas (inicialmente 0). Suporta athe 13 callbacks
         .space 4
    VEC_CALLBACK:                   @ Vec_callback[i][0] <- id do sonar, -1 para linha i vazia
         .space 156                 @ Vec_callback[i][1] <- limiar de distancia
                                    @ Vec_callback[i][2] <- ponteiro para funcao a ser chamada

    .space 2048
        INICIO_PILHA_SVC:
    .space 2048
        INICIO_PILHA_IRQ:
    .space 2048
        INICIO_PILHA_USER:
    .space 1
