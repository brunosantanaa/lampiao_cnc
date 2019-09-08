#ifndef GPIO_SYS_H
#define GPIO_SYS_H

#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#define BUFFER_MAX      3
#define DIRECTION_MAX   35
#define VALUE_MAX       30

#define INPUT   0
#define OUTPUT  1

#define LOW     0
#define HIGH    1

int export_gpio(int pin);

int unexport_gpio(int pin);

int direction_gpio(int pin, int dir);

int write_gpio(int pin, int value);
#endif // GPIO_SYS_H
