// Isolated-process probe of clingo's C++ bad_alloc-to-C-error boundary.
#include <atomic>
#include <cstdlib>
#include <cstring>
#include <dlfcn.h>
#include <new>
#include <unistd.h>

static std::atomic<long> budget{-1};
static std::atomic<bool> armed{false};
static thread_local bool inspecting;
__attribute__((constructor)) static void configure() {
    if (const char *value = std::getenv("CLINGO_FAIL_ALLOCATION"))
        budget.store(std::strtol(value, nullptr, 10));
}
extern "C" void *dlopen(const char *filename, int flags) {
    auto load = reinterpret_cast<void *(*)(const char *, int)>(dlsym(RTLD_NEXT, "dlopen"));
    void *handle = load(filename, flags);
    if (handle && filename && std::strstr(filename, "clingo_elixir.so")) armed.store(true);
    return handle;
}
void *operator new(std::size_t size) {
    if (armed.load() && !inspecting && budget.load() >= 0) {
        inspecting = true;
        Dl_info info{};
        bool upstream = dladdr(__builtin_return_address(0), &info) &&
                        info.dli_fname && std::strstr(info.dli_fname, "libclingo.so");
        inspecting = false;
        if (upstream && budget.fetch_sub(1) == 0) {
            const char message[] = "ALLOCATION_INJECTED\n";
            write(2, message, sizeof(message) - 1);
            throw std::bad_alloc();
        }
    }
    if (void *memory = std::malloc(size ? size : 1)) return memory;
    throw std::bad_alloc();
}
void *operator new[](std::size_t size) { return ::operator new(size); }
void operator delete(void *memory) noexcept { std::free(memory); }
void operator delete[](void *memory) noexcept { std::free(memory); }
void operator delete(void *memory, std::size_t) noexcept { std::free(memory); }
void operator delete[](void *memory, std::size_t) noexcept { std::free(memory); }
