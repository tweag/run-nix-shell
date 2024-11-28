const core = require("@actions/core");
const exec = require("@actions/exec");
const path = require("path");
const sh_join = require("shlex").join;
const sh_split = require("shlex").split;

async function run() {
  try {
    // Get inputs
    const runScript = core.getInput("run");
    const pure = core.getBooleanInput("pure");
    const options = core.getInput("options");
    const workingDir = core.getInput("working-directory");
    const derivationPath = core.getInput("derivation-path");
    const shellFlags = core.getInput("shell-flags");
    const verbose = core.getBooleanInput("verbose");

    // Construct the nix-shell command
    const nixShellArgs = [];
    if (derivationPath) {
      nixShellArgs.push(path.resolve(derivationPath));
    }
    let scriptCommand = `${shellFlags}
${runScript}`;

    nixShellArgs.push("--run", scriptCommand);

    if (pure) {
      nixShellArgs.unshift("--pure");
    }

    if (options) {
      nixShellArgs.unshift(...sh_split(options));
    }
    const execOptions = {
      silent: true, // need to enable silent mode, otherwise additional output gets written to stdout which breaks tests
      listeners: {
        stdout: (data) => process.stdout.write(data),
        stderr: (data) => process.stderr.write(data),
      },
    };

    // Change working directory if specified
    if (workingDir) {
      execOptions["cwd"] = path.resolve(workingDir);
    }

    if (verbose) {
      console.error(`nix-shell ${sh_join(nixShellArgs)}`);
    }

    const exitCode = await exec.exec("nix-shell", nixShellArgs, execOptions);

    if (exitCode !== 0) {
      throw new Error(`nix-shell command exited with code ${exitCode}`);
    }
  } catch (error) {
    core.setFailed(error.message);
  }
}

run();
