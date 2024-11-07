void phase_3(char *input)
{
#if(defined(PROBLEM))
    int number=0;
    number=atoi(input);
    if(number!=0x3b)
        explode_bomb();
#elif defined(SOLUTION)
    printf("59\n");
#else
    invalid_phase("3a");
#endif
}