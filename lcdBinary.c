/* ***************************************************************************** */
/* You can use this file to define the low-level hardware control fcts for       */
/* LED, button and LCD devices.                                                  */
/* Note that these need to be implemented in Assembler.                          */
/* You can use inline Assembler code, or use a stand-alone Assembler file.       */
/* Alternatively, you can implement all fcts directly in master-mind.c,          */
/* using inline Assembler code there.                                            */
/* The Makefile assumes you define the functions here.                           */
/* ***************************************************************************** */

#ifndef TRUE
#define TRUE (1 == 1)
#define FALSE (1 == 2)
#endif

#define DELAY 200

#define PAGE_SIZE (4 * 1024)
#define BLOCK_SIZE (4 * 1024)

#define INPUT 0
#define OUTPUT 1

#define LOW 0
#define HIGH 1

// APP constants   ---------------------------------

// Wiring (see call to lcdInit in main, using BCM numbering)
// NB: this needs to match the wiring as defined in master-mind.c

#define STRB_PIN 24
#define RS_PIN 25
#define DATA0_PIN 23
#define DATA1_PIN 10
#define DATA2_PIN 27
#define DATA3_PIN 22

// -----------------------------------------------------------------------------
// includes
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <sys/types.h>
#include <time.h>

// -----------------------------------------------------------------------------
// prototypes

int failure(int fatal, const char *message, ...);
void delay(unsigned int howLong);

// -----------------------------------------------------------------------------
// Functions to implement here (or directly in master-mind.c)

/* this version needs gpio as argument, because it is in a separate file */
void digitalWrite(uint32_t *gpio, int pin, int value)
{
	int offset, res;
	offset = (value == LOW) ? 10 : 7; // since all lcd pins are on the register i.e. GPFSET0 and GPFCLR0, we can use the same offset for all pins

	asm volatile(
		"\tLDR R1, %[gpio]\n"		// Loads address of GPIO from stack to register 1
		"\tADD R0, R1, %[offset]\n" // adds the offset value to GPIO address
		"\tMOV R2, #1\n"			// register immediate addressing of constant 1 to register 2
		"\tMOV R1, %[pin]\n"		// move pin value to R1
		"\tAND R1, #31\n"			// and R1 and 31
		"\tLSL R2, R1\n"
		"\tSTR R2, [R0, #0]\n"
		"\tMOV %[result], R2\n"
		: [result] "=r"(res)
		: [pin] "r"(pin), [gpio] "m"(gpio), [offset] "r"(offset * 4)
		: "r0", "r1", "r2", "cc");
}

// adapted from setPinMode
void pinMode(uint32_t *gpio, int pin, int mode /*, int fSel, int shift */)
{
	int fSel = pin / 10;
	int shift = (pin % 10) * 3;
	int res;

	// output
	if (mode == OUTPUT)
	{
		asm(/* inline assembler version of setting to ouput" */
			"\tLDR R1, %[gpio]\n"
			"\tADD R0, R1, %[fSel]\n"
			"\tLDR R1, [R0, #0]\n"
			"\tMOV R2, #0b111\n"
			"\tLSL R2, %[shift]\n"
			"\tBIC R1, R1, R2\n"
			"\tMOV R2, #1\n"
			"\tLSL R2, %[shift]\n"
			"\tORR R1, R2\n"
			"\tSTR R1, [R0, #0]\n"
			"\tMOV %[result], R1\n"
			: [result] "=r"(res)
			: [pin] "r"(pin), [gpio] "m"(gpio), [fSel] "r"(fSel * 4), [shift] "r"(shift)
			: "r0", "r1", "r2", "cc");
	}
	// input
	else if (mode == INPUT)
	{
		asm(/* inline assembler version of setting to input" */
			"\tLDR R1, %[gpio]\n"
			"\tADD R0, R1, %[fSel]\n"
			"\tLDR R1, [R0, #0]\n"
			"\tMOV R2, #0b111\n"
			"\tLSL R2, %[shift]\n"
			"\tBIC R1, R1, R2\n"
			"\tSTR R1, [R0, #0]\n"
			"\tMOV %[result], R1\n"
			: [result] "=r"(res)
			: [pin] "r"(pin), [gpio] "m"(gpio), [fSel] "r"(fSel * 4), [shift] "r"(shift)
			: "r0", "r1", "r2", "cc");
	}
	else
	{
		fprintf(stderr, "Invalid mode");
	}
}

void writeLED(uint32_t *gpio, int led, int value)
{
	digitalWrite(gpio, led, value);
}

int readButton(uint32_t *gpio, int button)
{
	int state = 0;
	asm volatile(
		"MOV R1, %[gpio]\n"
		"LDR R2, [R1, #0x34]\n"
		"MOV R3, %[pin]\n"
		"MOV R4, #1\n"
		"LSL R4, R3\n"
		"AND %[state], R2, R4\n"
		: [state] "=r"(state)
		: [pin] "r"(button), [gpio] "r"(gpio)
		: "r0", "r1", "r2", "r3", "r4", "cc");

	return state != 0;
}

void waitForButton(uint32_t *gpio, int button)
{
	for (;;)
	{
		if (readButton(gpio, button) == HIGH)
			break;
	}
}
