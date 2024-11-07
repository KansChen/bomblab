void phase_9(char *input) {
#if defined(PROBLEM)
    char target[] = "bcdefg";
    int length = string_length(input);

    if (length != 6) {
        explode_bomb();
    }

    for (int i = 0; i < 6; i++) {
        if (input[i] + 1 != target[i]) {
            explode_bomb();
        }
    }
#elif defined(SOLUTION)
    printf("abcdef\n"); // 每个字符在转换后变为 "bcdefg"
#else
    invalid_phase("9");
#endif
}