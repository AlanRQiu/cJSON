/* fuzz_parse.c - libFuzzer target for cJSON.c (parse, print, duplicate, compare, minify).
 * Each input is copied into an exactly-sized heap buffer (no NUL terminator for the WithLength calls) so
 * AddressSanitizer catches reads/writes past the end. Property under test: memory safety (ASan/UBSan abort). */
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include "cJSON.h"

int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size);

int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size)
{
    char *exact = (char *)malloc(size > 0 ? size : 1);   /* NOT NUL terminated */
    char *z = (char *)malloc(size + 1);                   /* NUL terminated copy for the string APIs */
    cJSON *a = NULL, *b = NULL, *c = NULL, *d = NULL;
    const char *end = NULL;
    char *s = NULL;
    if (exact == NULL || z == NULL) { free(exact); free(z); return 0; }
    if (size > 0) { memcpy(exact, data, size); memcpy(z, data, size); }
    z[size] = '\0';

    a = cJSON_ParseWithLength(exact, size);
    b = cJSON_Parse(z);
    c = cJSON_ParseWithOpts(z, &end, 1);
    d = cJSON_ParseWithLengthOpts(exact, size, &end, 0);
    if (a != NULL)
    {
        char *pre = NULL;
        int n = 0;
        s = cJSON_Print(a); free(s);
        s = cJSON_PrintUnformatted(a);
        if (s != NULL)
        {
            n = (int)strlen(s);
            pre = (char *)malloc((size_t)n + 1);                 /* exact fit */
            if (pre != NULL) { (void)cJSON_PrintPreallocated(a, pre, n + 1, 0); free(pre); }
            pre = (char *)malloc((size_t)n > 0 ? (size_t)n : 1); /* too small: must fail cleanly */
            if (pre != NULL) { (void)cJSON_PrintPreallocated(a, pre, n > 0 ? n : 1, 0); free(pre); }
            free(s);
        }
        s = cJSON_PrintBuffered(a, 1, 1); free(s);
        if (b != NULL) { (void)cJSON_Compare(a, b, 1); (void)cJSON_Compare(a, b, 0); }
        {
            cJSON *dup = cJSON_Duplicate(a, 1);
            if (dup != NULL) { (void)cJSON_Compare(a, dup, 1); cJSON_Delete(dup); }
        }
    }
    {
        char *m = (char *)malloc(size + 1);                       /* Minify works in place */
        if (m != NULL) { memcpy(m, z, size + 1); cJSON_Minify(m); free(m); }
    }
    cJSON_Delete(a); cJSON_Delete(b); cJSON_Delete(c); cJSON_Delete(d);
    free(exact); free(z);
    return 0;
}
