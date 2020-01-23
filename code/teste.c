#include "api_robot2.h"

#define LIMIAR 4000
// #define LIMIAR2 400

void setMot0();
void setMot1();
void setMot2();
void especialFunc();

int _start(int argv, char** argc) {
    register_proximity_callback(3, LIMIAR, setMot0);
    register_proximity_callback(4, LIMIAR, setMot1);

    setMot2();

    return 0;
}

void setMot0() {
    motor_cfg_t mot1;
    motor_cfg_t mot2;

    mot1.id = 0;
    mot1.speed = 0;

    mot2.id = 1;
    mot2.speed = 63;

    set_motors_speed(&mot1, &mot2);

    while (read_sonar(3) < LIMIAR);

    setMot2();

    register_proximity_callback(3, LIMIAR, setMot0);
}

void setMot1() {
    motor_cfg_t mot1;
    motor_cfg_t mot2;

    mot1.id = 0;
    mot1.speed = 63;

    mot2.id = 1;
    mot2.speed = 0;

    set_motors_speed(&mot1, &mot2);

    while (read_sonar(4) < LIMIAR);

    setMot2();

    register_proximity_callback(4, LIMIAR, setMot1);
}

void setMot2() {
    motor_cfg_t mot1;
    motor_cfg_t mot2;

    mot1.id = 0;
    mot1.speed = 63;

    mot2.id = 1;
    mot2.speed = 63;

    set_motors_speed(&mot1, &mot2);
}
