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
char userid[] = "1";

/* Global user_password */
char user_password[] = "e5Ru2N7cRpZ3rsp2fU1j";

/* 
 * phase1b.c - The user's input must match the specified string 
 */
void phase_1(char *input)
{
#if defined(PROBLEM)
    if (strings_not_equal(input, "Crikey! I have lost my mojo!") != 0)
	explode_bomb();
#elif defined(SOLUTION)
    printf("Crikey! I have lost my mojo!\n");
#else
    invalid_phase("1b");
#endif
}

/* 
 * phase2b.c - To defeat this stage the user must enter the geometric
 * sequence starting at 1, with a factor of 2 between each number
 */
void phase_2(char *input)
{
#if defined(PROBLEM)
    int i;
    int numbers[6];
    
    read_six_numbers(input, numbers);
    
    if (numbers[0] != 1)
	explode_bomb();

    for(i = 1; i < 6; i++) {
	if (numbers[i] != numbers[i-1] * 2)
	    explode_bomb();
    }
#elif defined(SOLUTION)
    printf("1 2 4 8 16 32\n");
#else
    invalid_phase("2b");
#endif
}
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
}void phase_4(char *input)
{
#if(defined(PROBLEM))
    int a=0,b=0;
    a=atoi(input);
    b=0xb4;
    if(a+b!=200)
        explode_bomb();
#elif defined(SOLUTION)
    printf("20\n");
#else
    invalid_phase("4b");
#endif
}/* 
 * phase3a.c - A long switch statement that the compiler should implement
 * with a jump table. The user has to enter both an index into the table 
 * and a value stored there.
 */
void phase_5(char *input)
{
#if defined(PROBLEM)
    int index, val, x = 0;
    int numScanned = 0;

    numScanned = sscanf(input, "%d %d", &index, &val);

    if (numScanned < 2)
	explode_bomb();

    switch(index) {
    case 0:
	x = 973;
	break;
    case 1:
	x = 64;
	break;
    case 2:
	x = 808;
	break;
    case 3:
	x = 924;
	break;
    case 4:
	x = 206;
	break;
    case 5:
	x = 195;
	break;
    case 6:
	x = 490;
	break;
    case 7:
	x = 387;
	break;
    default:
	explode_bomb();
    }

    if (x != val)
	explode_bomb();
#elif defined(SOLUTION)
    printf("4 206\n");
#else
    invalid_phase("5a");
#endif
}
/* 
 * phase6b.c - The user has to enter the permutation vector that
 * sorts a list in ascending order. The catch here is that the 
 * code inverts the permutation and checks for descending order.
 */
listNode node6 = {196, 6, NULL};
listNode node5 = {932, 5, &node6};
listNode node4 = {443, 4, &node5};
listNode node3 = {589, 3, &node4};
listNode node2 = {954, 2, &node3};
listNode node1 = {805, 1, &node2};

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

	while ((r != NULL) && (r->value > p->value)) {
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

    /* Reverse the permutation */
    for (i = 0; i < 6; i++) {
	indices[i] = 7 - indices[i];
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

    /* Now see if the list is sorted in descending order*/
    p = start;
    for (i = 0; i < 5; i++) {
	if (p->value < p->next->value)
	    explode_bomb();
	
	p = p->next;
    }
#elif defined(SOLUTION)
    listNode *start = &node1;
    listNode *p;

    /* sort */
    start = fun6(start);

    /* emit the (inverted) node indices of the sorted list */
    p = start;
    while (p) {
	printf("%d ", 7 - p->index);
	p = p->next;
    }
    printf("\n");
#else
    invalid_phase("6b");
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
    if (path != 3)
	explode_bomb();
  
    printf("Wow! You've defused the secret stage!\n");

    phase_defused();
#elif defined(SOLUTION)
    int path = 3;
    treeNode *node = &n1;
    
    node = (path    & 0x1) ? node->right : node->left;
    node = (path>>1 & 0x1) ? node->right : node->left;
    node = (path>>2 & 0x1) ? node->right : node->left;
    printf("%d\n", node->value);
#else
    invalid_phase("7");
#endif
}


