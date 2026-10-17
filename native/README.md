# Native runtime bundles

Mix installs `clingo-5.8.2-<target>.tar.gz` after checking its `.sha256` and
embedded target. Each archive contains the patched library, matching NIF,
CLI driver, C header, and component licenses. No compiler, installed clingo,
or source download is needed for an available bundle.

See [MULTIPLATFORM.md](../MULTIPLATFORM.md) for platform status, build/test
procedures, local overrides, and remaining validation. macOS archives are not
yet available. The contents of [licenses/](licenses/) also accompany each runtime.
