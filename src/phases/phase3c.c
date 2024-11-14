void phase_3(char *input)
{
#if(defined(PROBLEM))
    int number=0;
    number=atoi(input);
    if(number!=0x2a)
        explode_bomb();
#elif defined(SOLUTION)
    printf("42\n");
#else
    invalid_phase("3c");
#endif
}