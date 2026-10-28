# Stonefish GitHub Actions

## `stonefish-dev/actions/build`

Builds [Stonefish](https://github.com/stonefish-dev/code-shield)-protected wheels
of a Python project, one per Python version, and checks that every wheel is
protected.

Protected wheels contain interpreter-specific bytecode, so a wheel built for
Python 3.13 is tagged `cp313` and only installs there. The action builds all
supported versions (3.9–3.15) in a single job.

```yaml
name: release

on:
  release:
    types: [released]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: stonefish-dev/actions/build@v1
        with:
          license-key: ${{ secrets.STONEFISH_LICENSE_KEY }}
      - uses: actions/upload-artifact@v7
        with:
          name: dist
          path: dist

  publish:
    needs: build
    runs-on: ubuntu-latest
    environment: pypi
    permissions:
      id-token: write # PyPI trusted publishing
    steps:
      - uses: actions/download-artifact@v8
        with:
          name: dist
          path: dist
      - uses: pypa/gh-action-pypi-publish@release/v1
```

The project's `pyproject.toml` must use the Stonefish build backend:

```toml
[build-system]
requires = ["stonefish", "setuptools"]
build-backend = "stonefish.build_meta"
```

No sdist is built: an sdist would ship the plain source, and Stonefish refuses
to build one while protection is on.

### Inputs

| Input               | Default                                | Description                                                                                                  |
| ------------------- | -------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| `license-key`       | `$STONEFISH_LICENSE_KEY`               | Stonefish license key that names the project. Pass it from a repository secret.                              |
| `python-versions`   | `3.9 3.10 3.11 3.12 3.13 3.14 3.15`    | Space-separated Python versions to build wheels for.                                                         |
| `package-dir`       | `.`                                    | Directory of the project to build.                                                                           |
| `output-dir`        | `dist`                                 | Directory the wheels are written to.                                                                         |
| `secret`            |                                        | Optional module-encryption secret (hex). The bootstrap must supply the same bytes via `set_secret()`.        |
| `stonefish-version` | `>=0.8`                                | Version specifier for the stonefish build backend, e.g. `==0.8.2`.                                           |

### Outputs

| Output   | Description                                 |
| -------- | ------------------------------------------- |
| `wheels` | Newline-separated paths of the built wheels. |
