#include "include/native_minilzo.h"
#include "include/minilzo.h"
#import "include/lzoconf.h"
#import "include/lzodefs.h"

#define HEAP_ALLOC(var,size) \
    lzo_align_t __LZO_MMODEL var [ ((size) + (sizeof(lzo_align_t) - 1)) / sizeof(lzo_align_t) ]

static HEAP_ALLOC(wrkmem, LZO1X_1_MEM_COMPRESS);

// A very short-lived native function.
//
// For very short-lived functions, it is fine to call them on the main isolate.
// They will block the Dart execution while running the native function, so
// only do this for native functions which are guaranteed to be short-lived.
FFI_PLUGIN_EXPORT intptr_t sum(intptr_t a, intptr_t b) { return a + b; }

// A longer-lived native function, which occupies the thread calling it.
//
// Do not call these kind of native functions in the main isolate. They will
// block Dart execution. This will cause dropped frames in Flutter applications.
// Instead, call these native functions on a separate isolate.
FFI_PLUGIN_EXPORT intptr_t sum_long_running(intptr_t a, intptr_t b) {
    // Simulate work.
#if _WIN32
    Sleep(5000);
#else
    usleep(5000 * 1000);
#endif
    return a + b;
}


// + (BOOL)FMCompressData:(unsigned char *)inData inLen:(size_t)inLen outData:(unsigned char *)outData outLen:(size_t *)outLen
FFI_PLUGIN_EXPORT int
FMCompressData(unsigned char *inData, size_t inLen, unsigned char *outData, size_t *outLen) {
    //压缩算法初始化
    if (lzo_init() != LZO_E_OK) {
        printf("lzo init error");
        return NO;
    }

    int r = 0;
    //清空outData
    lzo_memset(outData, 0, *outLen);
    //压缩数据
    r = lzo1x_1_compress(inData, inLen, outData, &(*outLen), wrkmem);
    if (r != LZO_E_OK) {
        printf("compress error: %d", r);
        return NO;
    }

    if (outLen >= inLen)
    {
        printf("This block contains incompressible data.\n");
    }

    return YES;
}

//数据解压缩
FFI_PLUGIN_EXPORT int
FMDecompressData(unsigned char *inData, size_t inLen, unsigned char *outData, size_t *outLen) {
    //压缩算法初始化
    if (lzo_init() != LZO_E_OK) {
        printf("lzo init error");
        return NO;
    }

    int r = 0;
    //清空outData
    lzo_memset(outData, 0, *outLen);
    //压缩数据
    r = lzo1x_decompress(inData, inLen, outData, &(*outLen), NULL);
    if (r != LZO_E_OK) {
        printf("decompress error: %d", r);
        return NO;
    }
    printf("decompressed %lu bytes into %lu bytes\n",
           (unsigned long) inLen, (unsigned long) outLen);
    return YES;
}
