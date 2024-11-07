void phase_3(char *input)
{
#if(defined(PROBLEM))
    int number=0;
    number=atoi(input);
    if(number!=0x4c)
        explode_bomb();
#elif defined(SOLUTION)
    printf("76\n");
#else
    invalid_phase("3b");
#endif
}