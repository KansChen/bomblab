/*
 * bomb-solve.c - driver for a bomb that prints its own solution
 */
#include <stdio.h>
#include "support.h"
#include "phases.h"

FILE *infile;

int main()
{
    char *input="";

    initialize_bomb_solve();
    phase_1(input);
    phase_2(input);
    phase_3(input);
    phase_4(input);
    phase_5(input);
    phase_6(input);
    secret_phase();
    phase_8(input);
    phase_9(input);
    phase_10(input);
    return 0;
}
