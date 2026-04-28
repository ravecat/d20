const { join } = require("node:path");
const { VersionActions } = require("nx/release");

const VERSION_PATTERN = /^(\s*)@version\s+"([^"]+)"(\s*)$/m;

class ElixirVersionActions extends VersionActions {
  validManifestFilenames = ["mix.exs"];

  sourceManifestPath() {
    return join(this.projectGraphNode.data.root, "mix.exs");
  }

  readManifest(tree, manifestPath = this.sourceManifestPath()) {
    const content = tree.read(manifestPath)?.toString("utf-8");

    if (!content) {
      throw new Error(`Unable to read Elixir manifest: ${manifestPath}`);
    }

    const match = content.match(VERSION_PATTERN);

    if (!match) {
      throw new Error(`Unable to find @version "x.y.z" in ${manifestPath}`);
    }

    return {
      content,
      currentVersion: match[2],
      manifestPath,
    };
  }

  async readCurrentVersionFromSourceManifest(tree) {
    const { currentVersion, manifestPath } = this.readManifest(tree);

    return {
      currentVersion,
      manifestPath,
    };
  }

  async readCurrentVersionFromRegistry() {
    return null;
  }

  async readCurrentVersionOfDependency() {
    return {
      currentVersion: null,
      dependencyCollection: null,
    };
  }

  async updateProjectDependencies() {
    return [];
  }

  async updateProjectVersion(tree, newVersion) {
    const logMessages = [];
    const manifestsToUpdate = this.manifestsToUpdate.length
      ? this.manifestsToUpdate
      : [{ manifestPath: this.sourceManifestPath() }];

    for (const { manifestPath } of manifestsToUpdate) {
      const { content, currentVersion } = this.readManifest(tree, manifestPath);
      const updatedContent = content.replace(VERSION_PATTERN, `$1@version "${newVersion}"$3`);

      tree.write(manifestPath, updatedContent);
      logMessages.push(`Updated ${manifestPath} from ${currentVersion} to ${newVersion}`);
    }

    return logMessages;
  }
}

module.exports = ElixirVersionActions;
