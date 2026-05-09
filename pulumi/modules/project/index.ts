import * as pulumi from '@pulumi/pulumi';
import * as gcp from '@pulumi/gcp';
import * as random from '@pulumi/random';

export interface ProjectArgs {
  /** Display name and projectId prefix (e.g. "cicd" → "cicd-a1b2"). */
  projectName: pulumi.Input<string>;
  /** Parent folder ID. */
  folderId: pulumi.Input<string>;
  /** Billing account ID to associate with the project. */
  billingAccount: pulumi.Input<string>;
  /** GCP labels to apply to the project. */
  labels?: pulumi.Input<Record<string, pulumi.Input<string>>>;
  /** List of GCP API service names to enable on the project. */
  apis?: string[];
}

export class Project extends pulumi.ComponentResource {
  public readonly project: gcp.organizations.Project;
  public readonly projectId: pulumi.Output<string>;
  public readonly projectNumber: pulumi.Output<string>;
  public readonly enabledApis: gcp.projects.Service[];

  constructor(name: string, args: ProjectArgs, opts?: pulumi.ComponentResourceOptions) {
    super('devops:project:Project', name, {}, opts);

    const suffix = new random.RandomId(`${name}-suffix`, {
      byteLength: 2,
    }, { parent: this });

    const projectId = pulumi.interpolate`${args.projectName}-${suffix.hex}`;

    this.project = new gcp.organizations.Project(`${name}-project`, {
      projectId: projectId,
      name: args.projectName,
      folderId: args.folderId,
      billingAccount: args.billingAccount,
      labels: args.labels,
    }, { parent: this });

    this.projectId = this.project.projectId;
    this.projectNumber = this.project.number;

    this.enabledApis = (args.apis ?? []).map(api => new gcp.projects.Service(`${name}-api-${api}`, {
      project: this.project.projectId,
      service: api,
    }, { parent: this }));

    this.registerOutputs({
      projectId: this.projectId,
      projectNumber: this.projectNumber,
    });
  }
}
