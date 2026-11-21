/* fuzz_utils.c - libFuzzer target for cJSON_Utils.c (JSON Pointer, JSON Patch, Merge Patch, sorting).
 * Input layout:  <document> 0x00 <patch or second document> 0x00 <pointer string>
 * Build flag -DNAN_SKIP_MERGE_ALIAS=1 compiles out the two "patch is a subtree of the target" MergePatch calls,
 * so the sustained campaign is not stopped by the known finding (see findings/). The discovery and after-fix
 * runs leave them enabled. Property under test: memory safety (ASan/UBSan abort). */
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include "cJSON.h"
#include "cJSON_Utils.h"

static char *dup_piece(const uint8_t *p, size_t n)
{
    char *s = (char *)malloc(n + 1);
    if (s == NULL) { return NULL; }
    if (n > 0) { memcpy(s, p, n); }
    s[n] = '\0';
    return s;
}

int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size);

int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size)
{
    size_t i, cut1 = size, cut2 = size;
    char *s_doc = NULL, *s_patch = NULL, *s_ptr = NULL, *found = NULL;
    cJSON *doc = NULL, *patch = NULL, *work = NULL, *gen = NULL, *res = NULL;

    for (i = 0; i < size; i++) { if (data[i] == 0) { cut1 = i; break; } }
    if (cut1 < size) { for (i = cut1 + 1; i < size; i++) { if (data[i] == 0) { cut2 = i; break; } } }

    s_doc = dup_piece(data, cut1);
    s_patch = dup_piece(data + (cut1 < size ? cut1 + 1 : size), cut2 > cut1 && cut1 < size ? cut2 - cut1 - 1 : 0);
    s_ptr = dup_piece(data + (cut2 < size ? cut2 + 1 : size), cut2 < size ? size - cut2 - 1 : 0);
    if (s_doc == NULL || s_patch == NULL || s_ptr == NULL) { goto done; }

    doc = cJSON_Parse(s_doc);
    patch = cJSON_Parse(s_patch);

    if (doc != NULL)
    {
        (void)cJSONUtils_GetPointer(doc, s_ptr);
        (void)cJSONUtils_GetPointerCaseSensitive(doc, s_ptr);
        if (doc->child != NULL)
        {
            found = cJSONUtils_FindPointerFromObjectTo(doc, doc->child);
            if (found != NULL) { cJSON_free(found); found = NULL; }
        }
    }

    if (doc != NULL && patch != NULL)
    {
        work = cJSON_Duplicate(doc, 1);
        if (work != NULL) { (void)cJSONUtils_ApplyPatches(work, patch); cJSON_Delete(work); }
        work = cJSON_Duplicate(doc, 1);
        if (work != NULL) { (void)cJSONUtils_ApplyPatchesCaseSensitive(work, patch); cJSON_Delete(work); }

        work = cJSON_Duplicate(doc, 1);   /* MergePatch takes ownership of 'work' */
        if (work != NULL) { res = cJSONUtils_MergePatch(work, patch); cJSON_Delete(res); res = NULL; }
        work = cJSON_Duplicate(doc, 1);
        if (work != NULL) { res = cJSONUtils_MergePatchCaseSensitive(work, patch); cJSON_Delete(res); res = NULL; }

#ifndef NAN_SKIP_MERGE_ALIAS
        /* Aliasing: the merge patch is a subtree of the target (pattern behind upstream issue #1065). */
        work = cJSON_Duplicate(doc, 1);
        if (work != NULL)
        {
            if (work->child != NULL) { res = cJSONUtils_MergePatch(work, work->child); cJSON_Delete(res); res = NULL; }
            else { cJSON_Delete(work); }
        }
        work = cJSON_Duplicate(doc, 1);
        if (work != NULL)
        {
            if (work->child != NULL) { res = cJSONUtils_MergePatchCaseSensitive(work, work->child); cJSON_Delete(res); res = NULL; }
            else { cJSON_Delete(work); }
        }
#endif

        gen = cJSONUtils_GeneratePatches(doc, patch); cJSON_Delete(gen);
        gen = cJSONUtils_GeneratePatchesCaseSensitive(patch, doc); cJSON_Delete(gen);
        gen = cJSONUtils_GenerateMergePatch(doc, patch); cJSON_Delete(gen);
        gen = cJSONUtils_GenerateMergePatchCaseSensitive(patch, doc); cJSON_Delete(gen);
    }

    if (doc != NULL)
    {
        work = cJSON_Duplicate(doc, 1);
        if (work != NULL) { cJSONUtils_SortObject(work); cJSONUtils_SortObjectCaseSensitive(work); cJSON_Delete(work); }
        gen = cJSON_CreateArray();
        if (gen != NULL) { cJSONUtils_AddPatchToArray(gen, "add", s_ptr, doc); cJSON_Delete(gen); }
    }

done:
    cJSON_Delete(doc);
    cJSON_Delete(patch);
    free(s_doc); free(s_patch); free(s_ptr);
    return 0;
}
