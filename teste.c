#include "api_robot2.h"

#define LIMIAR 800

void setMot0();
void setMot1();
void setMot2();
void especialFunc();

int _start(int argv, char** argc) {
    add_alarm(setMot0, 1000);

    return 0;
}

void setMot0() {
    motor_cfg_t mot1;
    motor_cfg_t mot2;

    mot1.id = 0;
    mot1.speed = 30;

    mot2.id = 1;
    mot2.speed = 0;

    set_motors_speed(&mot1, &mot2);

    unsigned int t;
    get_time(&t);
    add_alarm(setMot1, t + 800);
}

void setMot1() {
    motor_cfg_t mot1;
    motor_cfg_t mot2;

    mot1.id = 0;
    mot1.speed = 0;

    mot2.id = 1;
    mot2.speed = 30;

    set_motors_speed(&mot1, &mot2);

    unsigned int t;
    get_time(&t);
    add_alarm(setMot0, t + 800);
}

void setMot2() {
    motor_cfg_t mot1;
    motor_cfg_t mot2;

    mot1.id = 0;
    mot1.speed = 40;

    mot2.id = 1;
    mot2.speed = 40;

    set_motors_speed(&mot1, &mot2);
}
