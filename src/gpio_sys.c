#include "gpio_sys.h"

int export_gpio(int pin) {
	char buffer[BUFFER_MAX];
	ssize_t bytes_written;
	int fd;

	fd = open("/sys/class/gpio/export", O_WRONLY);
	if (-1 == fd)
		return(-1);

	bytes_written = snprintf(buffer, BUFFER_MAX, "%d", pin);
	write(fd, buffer, bytes_written);
	close(fd);
	return(0);
}

int unexport_gpio(int pin) {
	char buffer[BUFFER_MAX];
	ssize_t bytes_written;
	int fd;

	fd = open("/sys/class/gpio/unexport", O_WRONLY);
	if (-1 == fd)
		return(-1);

	bytes_written = snprintf(buffer, BUFFER_MAX, "%d", pin);
	write(fd, buffer, bytes_written);
	close(fd);
	return(0);
}

int direction_gpio(int pin, int dir) {
	static const char s_directions_str[]  = "in\0out";

	char path[DIRECTION_MAX];
	int fd;

	snprintf(path, DIRECTION_MAX, "/sys/class/gpio/gpio%d/direction", pin);
	fd = open(path, O_WRONLY);
	if (-1 == fd)
		return(-1);

	if (-1 == write(fd, &s_directions_str[INPUT == dir ? 0 : 3], INPUT == dir ? 2 : 3))
		return(-1);

	close(fd);
	return(0);
}

int write_gpio(int pin, int value) {
	static const char s_values_str[] = "01";
	
  char path[VALUE_MAX];
	int fd;

	snprintf(path, VALUE_MAX, "/sys/class/gpio/gpio%d/value", pin);
	fd = open(path, O_WRONLY);
	if (-1 == fd)
		return(-1);

	if (1 != write(fd, &s_values_str[LOW == value ? 0 : 1], 1))
		return(-1);

	close(fd);
	return(0);
}
