void phase_4(char *input)
{
#if(defined(PROBLEM))
    int a=0,b=0;
    a=atoi(input);
    b=0xb3;
    if(a+b!=200)
        explode_bomb();
#elif defined(SOLUTION)
    printf("21\n");
#else
    invalid_phase("4a");
#endif
}