void phase_10(char *input) {
#if defined(PROBLEM)
    char target[] = "gnirts"; // "string" 逆序后
    int length = string_length(input);



    if (length != 6) {
        explode_bomb();
    }

    for (int i = 0; i < 6; i++) {
        if (input[i] != target[5 - i]) {
            explode_bomb();
        }
    }
#elif defined(SOLUTION)
    printf("string\n"); // 逆序后为 "gnirts"
#else
    invalid_phase("10");
#endif
}

typedef struct treeNodeStruct {
    int value;
    struct treeNodeStruct *left, *right;
} treeNode;

treeNode* insert_node(treeNode* node, int value) {
    if (node == NULL) {
        node = (treeNode*)malloc(sizeof(treeNode));
        node->value = value;
        node->left = node->right = NULL;
    } else if (value < node->value) {
        node->left = insert_node(node->left, value);
    } else {
        node->right = insert_node(node->right, value);
    }
    return node;
}

// 平衡检查函数
int is_balanced(treeNode* node) {
    if (node == NULL) {
        return 1;
    }
    int left_depth = tree_depth(node->left);
    int right_depth = tree_depth(node->right);

    return abs(left_depth - right_depth) <= 1 &&
           is_balanced(node->left) &&
           is_balanced(node->right);
}

int tree_depth(treeNode* node) {
    if (node == NULL) {
        return 0;
    }
    return 1 + fmax(tree_depth(node->left), tree_depth(node->right));
}
void phase_10(char *input) {
#if defined(PROBLEM)
    treeNode *root = NULL;
    int values[6];

    read_six_numbers(input, values);

    for (int i = 0; i < 6; i++) {
        root = insert_node(root, values[i]);
    }

    if (!is_balanced(root)) {
        explode_bomb();
    }
#elif defined(SOLUTION)
    printf("50 25 75 10 30 60\n"); 
#else
    invalid_phase("10");
#endif
}

