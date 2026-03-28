import { ComposeOutput, Set, Program } from 'pulumi';

const artifactRegistry = new pulumi.ArtifactRegistry('myRegistry');

const program = new Program();

program
  .output('artifactRegistryUrl', {
    value: artifactRegistry.url,
  })
  .write();

export const app = program.makeAutoRestore();
