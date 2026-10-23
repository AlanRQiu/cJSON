#include <stdio.h>
#include <stdlib.h>

#ifdef _WIN32
#include <fcntl.h>
#include <io.h>
#endif

#include "../cJSON.h"

#define MAX_INPUT_BYTES ((size_t)16 * 1024 * 1024)

int main(int argc, char **argv)
{
    FILE *input = stdin;
    unsigned char *buffer = NULL;
    size_t capacity = 4096;
    size_t length = 0;
    int executions = 0;
    int successes = 0;
    int status = EXIT_FAILURE;
    cJSON *tree = NULL;

    if (argc > 2)
    {
        fprintf(stderr, "Usage: %s [input-file]\n", argv[0]);
        goto cleanup;
    }
    if (argc == 2)
    {
        input = fopen(argv[1], "rb");
        if (input == NULL)
        {
            perror("Cannot open input");
            goto cleanup;
        }
    }
#ifdef _WIN32
    else if (_setmode(_fileno(stdin), _O_BINARY) == -1)
    {
        perror("Cannot set binary stdin");
        goto cleanup;
    }
#endif

    buffer = (unsigned char *)malloc(capacity);
    if (buffer == NULL)
    {
        fprintf(stderr, "Input allocation failed\n");
        goto cleanup;
    }

    for (;;)
    {
        size_t count;
        if (length == capacity)
        {
            unsigned char *grown;
            if (capacity == MAX_INPUT_BYTES)
            {
                int extra = fgetc(input);
                if (extra != EOF)
                {
                    fprintf(stderr, "Input exceeds 16777216-byte limit\n");
                    goto cleanup;
                }
                if (ferror(input))
                {
                    fprintf(stderr, "Input read failed\n");
                    goto cleanup;
                }
                break;
            }
            capacity *= 2;
            grown = (unsigned char *)realloc(buffer, capacity);
            if (grown == NULL)
            {
                fprintf(stderr, "Input allocation failed\n");
                goto cleanup;
            }
            buffer = grown;
        }

        count = fread(buffer + length, 1, capacity - length, input);
        length += count;
        if (ferror(input))
        {
            fprintf(stderr, "Input read failed\n");
            goto cleanup;
        }
        if (feof(input))
        {
            break;
        }
    }

    tree = cJSON_ParseWithLengthOpts((const char *)buffer, length, NULL, 0);
    executions = 1;
    successes = tree != NULL;
    cJSON_Delete(tree);
    status = EXIT_SUCCESS;

cleanup:
    free(buffer);
    if ((input != NULL) && (input != stdin) && (fclose(input) != 0))
    {
        fprintf(stderr, "Input close failed\n");
        status = EXIT_FAILURE;
    }
    if (printf("Executions: %d, Bytes processed: %zu, Parse successes: %d\n",
               executions, length, successes) < 0 || fflush(stdout) == EOF)
    {
        status = EXIT_FAILURE;
    }
    return status;
}