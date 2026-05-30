# Contributing

## Source layout

```
src/
  @orb.yml              # orb entry point
  commands/             # orb command definitions
  examples/             # usage examples shown in the orb registry
  scripts/              # human-authored shell scripts — edit these
  scripts_generated/    # packed scripts embedded via <<include(...)>> — do not edit
```

`scripts_generated/` is produced by `make scripts/gen`, which uses `sosh pack` to inline
dependencies from the `shell-gr` library. After editing `scripts/`, regenerate before committing.

## Development

```bash
make scripts/gen      # regenerate packed scripts after editing scripts/
make orb/validate     # pack and validate the orb
make format           # format shell and YAML
make lint             # lint shell scripts
```

## Release Process

1. **Review unreleased changes**

   Compare the `[Unreleased]` section in `CHANGELOG.md` against actual commits since the last tag:

   ```sh
   git log $(git describe --tags --abbrev=0)..HEAD --oneline
   ```

   Add any notable changes that are missing from the `[Unreleased]` section.

2. **Update CHANGELOG.md**

   Move all entries from `[Unreleased]` into a new versioned section placed above it:

   ```markdown
   ## [Unreleased]

   [Unreleased]: https://github.com/rynkowsg/shell-gr/compare/vX.Y.Z..main

   ## [X.Y.Z](https://github.com/rynkowsg/shell-gr/commits/vX.Y.Z) (YYYY-MM-DD)

   - ...
   ```

   Also update the `[Unreleased]` comparison link to point to the new version.

3. **Commit**

   ```sh
   git commit -m "chore: Bump to version X.Y.Z" --no-gpg-sign
   ```

4. **Tag**

   ```sh
   git tag -a vX.Y.Z -m "Version vX.Y.Z"
   ```
