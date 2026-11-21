/* Standalone reproducers for MergePatch aliasing: the patch is part of the target.
 * usage: poc <variant> [cs]     variants 1-2 fail on the unfixed library; 3-5 are controls that do not.      */
#include <stdio.h>
#include <stdlib.h>
#include "cJSON.h"
#include "cJSON_Utils.h"
int main(int argc, char **argv)
{
    int v = argc > 1 ? atoi(argv[1]) : 1;
    int cs = argc > 2;
    const char *doc[] = {"", "[{}]", "{\"a\":{\"a\":5}}", "{\"t\":{\"x\":1}}", "[[1,2],3]", "{\"a\":{\"b\":{\"c\":1}}}"};
    cJSON *target = cJSON_Parse(doc[v]), *patch = NULL, *res;
    switch (v) {
        case 1: patch = target->child; break;                   /* patch = child object of an array target   */
        case 2: patch = target->child; break;                   /* patch = child object of an object target  */
        case 3: patch = target; target = target->child; break;  /* control: patch is the PARENT of the target */
        case 4: patch = target->child; break;                   /* control: patch = child ARRAY               */
        case 5: patch = target->child->child; break;            /* control: patch = grandchild object         */
    }
    res = cs ? cJSONUtils_MergePatchCaseSensitive(target, patch) : cJSONUtils_MergePatch(target, patch);
    char *s = cJSON_PrintUnformatted(res);
    printf("variant %d result: %s\n", v, s ? s : "(null)");
    free(s);
    if (v != 3) {
        cJSON_Delete(res);
    } else {
        /* control 3: 'target' was a child still linked inside 'patch' (the root) and was consumed by the merge;
         * unlink it so deleting the root frees only the root and does not touch the consumed node. */
        patch->child = NULL;
        cJSON_Delete(patch);
        cJSON_Delete(res);
    }
    return 0;
}
