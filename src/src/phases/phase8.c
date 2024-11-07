void phase_8(char *input) {
#if defined(PROBLEM)
    int numbers[4];
    int sum_square = 0, target = 36;

    read_four_numbers(input, numbers);

    for (int i = 0; i < 4; i++) {
        sum_square += numbers[i] * numbers[i];
    }

    if (sum_square != target) {
        explode_bomb();
    }
#elif defined(SOLUTION)
    printf("3 3 3 3\n"); // 例如，当 target 为 30 时
#else
    invalid_phase("8");
#endif
}