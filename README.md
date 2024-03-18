# Execute scripts using `nix-shell`

[![Continuous Integration](https://github.com/tweag/run-nix-shell/actions/workflows/ci.yaml/badge.svg?event=schedule)](https://github.com/tweag/run-nix-shell/actions/workflows/ci.yaml)

Executes a script or script file using `nix-shell`.

## Usage

To use this action, install Nix on your runner and start executing scripts.

```yaml
name: Example
on:
  workflow_dispatch: # allows manual triggering

jobs:
  run_under_nix:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout the repository
        uses: actions/checkout@v4
      - uses: DeterminateSystems/nix-installer-action@v9
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}

      - name: Execute script in Nix shell
        uses: tweag/run-nix-shell@v0
        with:
          run: |
            set -o errexit -o nounset -o pipefail
            echo "Hello"

      - name: Execute script file
        uses: tweag/run-nix-shell@v0
        with:
          run: path/to/my/script

      - name: Configure Nix shell before executing script
        uses: tweag/run-nix-shell@v0
        with:
          options: |
            --arg myNixArg true
            --argstr anotherNixArg "Hello, World!"
          run: |
            set -o errexit -o nounset -o pipefail
            echo "Hello"

      - name: Execute script in a specific directory
        uses: tweag/run-nix-shell@v0
        with:
          working-directory: my/working/directory
          run: |
            set -o errexit -o nounset -o pipefail
            echo "${PWD}"
```

## Inputs

| Input | Description |
| ----- | ----------- |
| `run` | The script to be executed using `nix-shell`. This can be the actual script or a path to as cript file. |
| `pure` | Whether to run the script with the `--pure` option. Defaults to `true`. |
| `options` | Any options that you want to pass to `nix-shell`. |
| `working-directory` | This will be the current working direcotry when the script is executed. |
| `derivation-path` | The path to directory or the `shell.nix` or `default.nix` to use to set up the environment. This is the directory where `nix-shell` is executed. |
| `shell-flags` | These flags will be set before executing the script. |
| `verbose` | Enables additional output for debugging this action. |
