/* emscripten has no libtiff/libwebp port (cocos2d-x-wasm doesn't build them
 * either) and the game ships only png/ccz, so the decoders just fail. */
#include "tiffio.h"
#include "decode.h"

TIFF *TIFFClientOpen(const char *n, const char *m, thandle_t h, TIFFReadWriteProc r, TIFFReadWriteProc w,
                     TIFFSeekProc s, TIFFCloseProc c, TIFFSizeProc z, TIFFMapFileProc mp, TIFFUnmapFileProc u) { return 0; }
int TIFFGetField(TIFF *t, uint32 tag, ...) { return 0; }
int TIFFReadRGBAImageOriented(TIFF *t, uint32 w, uint32 h, uint32 *r, int o, int s) { return 0; }
void *_TIFFmalloc(tmsize_t s) { return 0; }
void _TIFFfree(void *p) {}
void TIFFClose(TIFF *t) {}

int WebPGetInfo(const uint8_t *d, size_t n, int *w, int *h) { return 0; }
int WebPInitDecoderConfigInternal(WebPDecoderConfig *c, int v) { return 0; }
VP8StatusCode WebPGetFeaturesInternal(const uint8_t *d, size_t n, WebPBitstreamFeatures *f, int v) { return VP8_STATUS_UNSUPPORTED_FEATURE; }
VP8StatusCode WebPDecode(const uint8_t *d, size_t n, WebPDecoderConfig *c) { return VP8_STATUS_UNSUPPORTED_FEATURE; }
uint8_t *WebPDecodeRGBAInto(const uint8_t *d, size_t n, uint8_t *o, size_t s, int st) { return 0; }
