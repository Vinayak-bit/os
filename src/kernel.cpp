#include <stdint.h>
#include <stddef.h>
#include "limine.h"

__attribute__((used, section(".limine_requests")))
static volatile uint64_t limine_base_revision[] = LIMINE_BASE_REVISION(6);

__attribute__((used, section(".limine_requests_start")))
static volatile uint64_t limine_requests_start_marker[] = LIMINE_REQUESTS_START_MARKER;

__attribute__((used, section(".limine_requests_end")))
static volatile uint64_t limine_requests_end_marker[] = LIMINE_REQUESTS_END_MARKER;

extern "C" {
void* memcpy(void* dest, const void* src, size_t n) {
    auto d = static_cast<uint8_t*>(dest);
    auto s = static_cast<const uint8_t*>(src);
    for (size_t i = 0; i < n; i++) d[i] = s[i];
    return dest;
}
void* memset(void* s, int c, size_t n) {
    auto p = static_cast<uint8_t*>(s);
    for (size_t i = 0; i < n; i++) p[i] = static_cast<uint8_t>(c);
    return s;
}
void* memmove(void* dest, const void* src, size_t n) {
    auto d = static_cast<uint8_t*>(dest);
    auto s = static_cast<const uint8_t*>(src);
    if (s > d) { for (size_t i = 0; i < n; i++) d[i] = s[i]; }
    else if (s < d) { for (size_t i = n; i > 0; i--) d[i-1] = s[i-1]; }
    return dest;
}
int memcmp(const void* a, const void* b, size_t n) {
    auto p = static_cast<const uint8_t*>(a);
    auto q = static_cast<const uint8_t*>(b);
    for (size_t i = 0; i < n; i++)
        if (p[i] != q[i]) return p[i] < q[i] ? -1 : 1;
    return 0;
}
}

static inline void outb(uint16_t port, uint8_t val) {
    asm volatile("outb %0, %1" : : "a"(val), "Nd"(port));
}

static void serial_print(const char* s) {
    while (*s) outb(0x3F8, *s++);
}

static void hcf() {
    for (;;) asm volatile("hlt");
}

extern "C" void kmain() {
    if (!LIMINE_BASE_REVISION_SUPPORTED(limine_base_revision)) hcf();
    serial_print("Hello from our OS!\n");
    hcf();
}
