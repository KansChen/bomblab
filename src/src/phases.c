/*
 * CS:APP Binary Bomb (Autolab version)
 *
 * Copyright (c) 2004, R. Bryant and D. O'Hallaron, All rights reserved.
 * May not be used, modified, or copied without permission.
 */ 
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "phases.h"
#include "support.h"

/* Global bomb ID */
int bomb_id = 1;

/* Global userid */
char userid[] = "1234";

/* Global user_password */
char user_password[] = "jhWFeSrurHMmNlThtZxo";

/* 
 * phase1c.c - The user's input must match the specified string 
 */
void phase_1(char *input)
{
#if defined(PROBLEM)
    if (strings_not_equal(input, "I am the mayor. I can do anything I want.") != 0)
	explode_bomb();
#elif defined(SOLUTION)
    printf("I am the mayor. I can do anything I want.\n");
#else
    invalid_phase("1c");
#endif
}
/* 
 * phase2a.c - To defeat this stage the user must enter a sequence of 
 * 6 nonnegative numbers where x[i] = x[i-1] + i
 */
void phase_2(char *input)
{
#if defined(PROBLEM)
    int i;
    int numbers[6];

    read_six_numbers(input, numbers);

    if (numbers[0] < 0)
	explode_bomb();

    for(i = 1; i < 6; i++) {
	if (numbers[i] != numbers[i - 1] + i)
	    explode_bomb();
    }
#elif defined(SOLUTION)
    printf("2 3 5 8 12 17\n");
#else
    invalid_phase("2a");
#endif
}
/* 
 * phase3b.c - A long switch statement that the compiler should
 * implement with a jump table. The user must enter both an index 
 * into the table and the sum accumulated by falling through the rest 
 * of the table 
 */

void phase_3(char *input)
{
#if defined(PROBLEM)
    int index, sum, x = 0;
    int numScanned = 0;

    numScanned = sscanf(input, "%d %d", &index, &sum);

    if (numScanned < 2)
	explode_bomb();

    switch(index) {
    case 0:
	x = x + 337;
    case 1:
	x = x - 843;
    case 2:
	x = x + 913;
    case 3:
	x = x - 610;
    case 4:
	x = x + 610;
    case 5:
	x = x - 610;
    case 6:
	x = x + 610;
    case 7:
	x = x - 610;
	break;
    default:
	explode_bomb();
    }

    if ((index > 5) || (x != sum))
	explode_bomb();
#elif defined(SOLUTION)
    printf("3 -610\n");
#else
    invalid_phase("3b");
#endif
}
/* 
 * phase4a.c - A recursive binary search function to sort out.  The
 * search is over the indexes [0..14] of a binary search tree, where
 * root=7, root->left=3, root->right=11, and so on. The user must
 * predict the sum of the indexes that will be visited during the
 * search for a particular target index, and must input both the sum
 * and the target index.
 */
int func4(int val, int low, int high)
{
    int mid;

    mid = low + (high - low) / 2;

    if (mid > val)
	return func4(val, low, mid-1) + mid;
    else if (mid < val)
	return func4(val, mid+1, high) + mid;
    else
	return mid;
}


void phase_4(char *input) {
#if defined(PROBLEM)
    int user_val, user_sum, result, target_sum, numScanned;

    numScanned = sscanf(input, "%d %d", &user_val, &user_sum);
    if ((numScanned != 2) || user_val < 0 || user_val > 14) {
	explode_bomb();
    }

    target_sum = 35; 
    result = func4(user_val, 0, 14);

    if (result != target_sum || user_sum != target_sum) {
	explode_bomb();
    }
#elif defined(SOLUTION)
    int i;
    int target_sum = 35;
    
    for (i=0; i<15; i++) { 
	if (target_sum == func4(i, 0, 14))
	    break;
    }
	printf("%d %d %s\n", i, target_sum, SECRET_PHRASE);
#else
    invalid_phase("4a");
#endif
}

/* 
 * phase5a.c - Just to be hairy, this traverses a loop of pointers and 
 * counts its length.  The input determines where in the loop we begin. 
 * Just to make sure the user isn't guessing, we make them input the sum of
 * the pointers encountered along the path, too.
 */
void phase_5(char *input)
{
#if defined(PROBLEM)
    static int array[] = {
      10,
      2,
      14,
      7,
      8,
      12,
      15,
      11,
      0,
      4,
      1,
      13,
      3,
      9,
      6,
      5
    };

    int count, sum;
    int start;
    int p, result;
    int numScanned;

    numScanned = sscanf(input, "%d %d", &p, &result);
    
    if (numScanned < 2)
      explode_bomb();

    p = p & 0x0f;
    start = p; /* debug */

    count = 0;
    sum = 0;
    while(p != 15) {
	count++;
	p = array[p];
	sum += p;
    }

    if ((count != 15) || (sum != result))
	explode_bomb();
#elif defined(SOLUTION)
    switch (15) {
    case 1: printf("6 15"); break;
    case 2: printf("14 21"); break;
    case 3: printf("2 35"); break;
    case 4: printf("1 37"); break;
    case 5: printf("10 38"); break;
    case 6: printf("0 48"); break;
    case 7: printf("8 48"); break;
    case 8: printf("4 56"); break;
    case 9: printf("9 60"); break;
    case 10: printf("13 69"); break;
    case 11: printf("11 82"); break;
    case 12: printf("7 93"); break;
    case 13: printf("3 100"); break;
    case 14: printf("12 103"); break;
    case 15: printf("5 115"); break;
    default:
	printf("ERROR: bad count value in phase5a\n");
	exit(8);
    }
    printf("\n");
#else
    invalid_phase("5a");
#endif
}

/* 
 * phase6a.c - The user has to enter the node numbers (from 1 to 6) in 
 * the order that they will occur when the list is sorted in ascending
 * order.
 */
listNode node6 = {362, 6, NULL};
listNode node5 = {967, 5, &node6};
listNode node4 = {365, 4, &node5};
listNode node3 = {999, 3, &node4};
listNode node2 = {718, 2, &node3};
listNode node1 = {697, 1, &node2};

#if defined(SOLUTION)
/* Sort list in ascending order */
listNode *fun6(listNode *start)
{
    listNode *head = start;
    listNode *p, *q, *r;

    head = start;
    p = start->next;
    head->next = NULL;

    while (p != NULL) {
	r = head;
	q = head;

	while ((r != NULL) && (r->value < p->value)) {
	    q = r;
	    r = r->next;
	}

	if (q != r)
	    q->next = p;
	else
	    head = p;

	q = p->next;
	p->next = r;

	p = q;
    }

    return head;
}
#endif

void phase_6(char *input)
{
#if defined(PROBLEM)
    listNode *start = &node1;
    listNode *p;
    int indices[6];
    listNode *pointers[6];
    int i, j;

    read_six_numbers(input, indices);

    /* Check the range of the indices and whether or not any repeat */
    for (i = 0; i < 6; i++) {
	if ((indices[i] < 1) || (indices[i] > 6))
	    explode_bomb();
	
	for (j = i + 1; j < 6; j++) {
	    if (indices[i] == indices[j])
		explode_bomb();
	}
    }

    /* Rearrange the list according to the user input */
    for (i = 0; i < 6; i++) {
	p = start;
	for (j = 1; j < indices[i]; j++)
	    p = p -> next;
	pointers[i] = p;
    }

    start = pointers[0];
    p = start;

    for (i = 1; i < 6; i++) {
	p->next = pointers[i];
	p = p->next;
    }
    p->next = NULL;

    /* Now see if the list is sorted in ascending order*/
    p = start;
    for (i = 0; i < 5; i++) {
	if (p->value > p->next->value)
	    explode_bomb();
	p = p->next;
    }

#elif defined(SOLUTION)
    listNode *start = &node1;
    listNode *p;

    /* sort */
    start = fun6(start);

    /* emit the node indices of the sorted list */
    p = start;
    while (p) {
	printf("%d ", p->index);
	p = p->next;
    }
    printf("\n");
#else
    invalid_phase("6a");
#endif
}



/* 
 * phase7.c - The infamous secret stage! 
 * The user has to find leaf value given path in a binary tree.
 */

typedef struct treeNodeStruct
{
    int value;
    struct treeNodeStruct *left, *right;
} treeNode;

/* balanced binary tree containing randomly chosen values */
treeNode n48 = {1001, NULL, NULL};
treeNode n46 = {47, NULL, NULL};
treeNode n43 = {20, NULL, NULL};
treeNode n42 = {7, NULL, NULL};
treeNode n44 = {35, NULL, NULL};
treeNode n47 = {99, NULL, NULL};
treeNode n41 = {1, NULL, NULL};
treeNode n45 = {40, NULL, NULL};
treeNode n34 = {107, &n47, &n48};
treeNode n31 = {6, &n41, &n42};
treeNode n33 = {45, &n45, &n46};
treeNode n32 = {22, &n43, &n44};
treeNode n22 = {50, &n33, &n34};
treeNode n21 = {8, &n31, &n32};
treeNode n1 = {36, &n21, &n22};

/* 
 * Searches for a node in a binary tree and returns path value.
 * 0 bit denotes left branch, 1 bit denotes right branch
 * Example: the path to leaf value "35" is left, then right,
 * then right, and thus the path value is 110(base 2) = 6.
 */

int fun7(treeNode* node, int val)
{
    if (node == NULL) 
	return -1;
  
    if (val < node->value) 
	return fun7(node->left, val) << 1;
    else if (val == node->value) 
	return 0;
    else 
	return (fun7(node->right, val) << 1) + 1;
}
     
void secret_phase()
{

#if defined(PROBLEM)
    char *input = read_line();
    int target = atoi(input);
    int path;

    /* Make sure target is in the right range */
    if ((target < 1) || (target > 1001))
	explode_bomb();

    /* Determine the path to the given target */
    path = fun7(&n1, target);

    /* Compare the retrieved path to a random path */
    if (path != 7)
	explode_bomb();
  
    printf("Wow! You've defused the secret stage!\n");

    phase_defused();
#elif defined(SOLUTION)
    int path = 7;
    treeNode *node = &n1;
    
    node = (path    & 0x1) ? node->right : node->left;
    node = (path>>1 & 0x1) ? node->right : node->left;
    node = (path>>2 & 0x1) ? node->right : node->left;
    printf("%d\n", node->value);
#else
    invalid_phase("7");
#endif
}

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
    printf("3 3 3 3\n"); 
#else
    invalid_phase("8");
#endif
}

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
    printf("abcdef\n"); 
#else
    invalid_phase("9");
#endif
}

void phase_10(char *input) {
#if defined(PROBLEM)
    char target[] = "gnirts"; 
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
    printf("string\n"); 
#else
    invalid_phase("10");
#endif
}


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




