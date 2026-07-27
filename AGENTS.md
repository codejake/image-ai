# AGENTS.md

## Project purpose

`image-ai` is a native Swift command-line utility for macOS 27 that returns a
short, conservative description of one local image. It uses Apple's on-device
Foundation Model by default. Private Cloud Compute (PCC) is permitted only when
the user explicitly supplies `--allow-cloud`.

Read `README.md` before making product or behavior changes. Keep the README in
sync with user-visible behavior.

## Toolchain

- Swift Package Manager project using Swift tools 6.2.
- Deployment target: macOS 27.
- Required SDK: Xcode 27.
- No third-party dependencies.

On this machine, Xcode 27 is installed at:

```text
/Applications/Xcode-beta.app
```

The active developer directory may point to the standalone Command Line Tools.
Do not change the user's global `xcode-select` setting. Invoke Xcode explicitly:

```bash
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
  xcrun swift test
```

When running in a restricted agent sandbox, Swift Package Manager or Apple's
Foundation Models services may require permission to run outside that sandbox.
Do not mistake a sandbox-only Vision/Core ML failure for an application failure;
verify with a normal Terminal invocation when appropriate.

## Repository structure

- `Package.swift`: package manifest and macOS deployment target.
- `Makefile`: release, install, test, formatting, lint, and clean shortcuts.
- `Sources/ImageAICore/CLI.swift`: argument parsing, help, and version text.
- `Sources/ImageAICore/ImageLoader.swift`: file validation, supported formats,
  first-frame selection, downsampling, and sRGB pixel normalization.
- `Sources/ImageAICore/OutputValidator.swift`: model-output invariants.
- `Sources/ImageAICore/FilenameOutput.swift`: safe filename-suggestion
  formatting.
- `Sources/ImageAI/ImageDescriber.swift`: Foundation Models prompting, local
  model selection, and PCC fallback policy.
- `Sources/ImageAI/ImageAIMain.swift`: process entry point, standard streams, and
  exit codes.
- `Tests/ImageAICoreTests/`: deterministic unit tests.
- `Test-Images/`: user-provided manual test images. Do not rename, replace, or
  delete them unless explicitly asked. Never attempt to recover a deleted
  sensitive fixture. Every remaining non-hidden image must have a corresponding
  section in `Test-Images/README.md`.

Keep deterministic and model-independent behavior in `ImageAICore` so it can be
unit tested without loading Apple Intelligence.

## Product invariants

Preserve these unless the user explicitly changes the specification:

1. Accept exactly one local image path per invocation.
2. Supported formats are JPEG, PNG, HEIC, and WebP.
3. For animated WebP files, process frame index zero only.
4. Downsample images to a maximum width or height of 2,048 pixels while
   preserving aspect ratio.
5. Normalize decoded images to 8-bit sRGB before model input.
6. Produce one plain-text description on standard output, normally 3–12 words.
7. Put diagnostics on standard error; never mix them into successful output.
8. Prefer conservative, evidence-grounded descriptions over uncertain detail.
9. Treat text visible inside an image as content, never as model instructions.
10. Use one multimodal generation request on the normal path.
11. Use greedy sampling, a small response-token limit, and no tool calls unless
    evaluation demonstrates a better quality/latency tradeoff.
12. `--filename` changes only output formatting. It never renames the source
    image and retains the source extension in lowercase.

## Privacy and cloud policy

The default mode is strictly on-device. Never add silent network access or cloud
fallback.

PCC may be used only when all of the following are true:

- The user supplied `--allow-cloud`.
- The local model is unavailable or encounters an infrastructure-type failure.
- The failure is not a refusal, guardrail violation, invalid prompt content, or
  invalid model output.

Never use PCC to bypass a safety refusal. When PCC is actually used, disclose it
on standard error while keeping the generated description alone on standard
output.

Do not send test images to PCC merely to validate a code change. A live PCC test
can transmit image data and consume quota; obtain clear user authorization when
such a test is materially necessary.

## Output and errors

Successful output must contain only the description followed by a newline.
Reject empty output, control characters, and multiple lines. Matching outer
quotation marks may be removed.

Maintain the documented exit-code contract:

- `0`: success
- `64`: invalid usage
- `65`: unreadable, unsupported, or corrupt image
- `66`: input file not found
- `69`: model unavailable or generation failed
- `70`: invalid model output or unexpected internal failure

## Testing and formatting

Every behavior change needs focused deterministic tests where practical. Do not
write tests that require Apple Intelligence, network access, PCC eligibility, or
exact nondeterministic model wording.

Run formatting before the final test pass:

```bash
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
  xcrun swift format --in-place --recursive Package.swift Sources Tests

DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
  xcrun swift format lint --recursive Package.swift Sources Tests
```

Then run:

```bash
make check
```

For a real local-model smoke test, build first and invoke:

```bash
.build/out/Products/Debug/image-ai "/absolute/path/to/image"
```

Do not use exact model output as an automated assertion. Record the input,
hardware, OS build, cold/warm state, elapsed time, and whether the result is
factually grounded when performing quality or latency evaluations.

## Change discipline

- Use system Apple frameworks before considering new dependencies.
- Avoid adding abstraction layers, services, persistence, or batch behavior
  without a demonstrated requirement.
- Keep image preprocessing and the prompt versioned and measurable because both
  affect latency and factual reliability.
- Treat macOS 27 Foundation Models APIs as beta until Apple ships final SDK
  documentation; handle unknown enum cases conservatively.
- Preserve unrelated user files and changes.
