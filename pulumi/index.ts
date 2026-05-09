import * as pulumi from '@pulumi/pulumi';
import * as gcp from '@pulumi/gcp';

import { Project } from './modules/project';

const config = new pulumi.Config();
const orgId = config.require('gcpOrgId');
const orgName = config.require('gcpOrgName');
const billingAccountId = config.require('gcpBillingAccountId');
const region = config.require('gcpRegion');
const stackEnv = config.require('stackEnv');
const stackScope = config.require('stackScope');

// Sanitised labels for GCP (lowercase, underscores, no camelCase)
const labels = {
  stack_env: stackEnv.toLowerCase(),
  stack_scope: stackScope.toLowerCase(),
  managed_by: 'pulumi',
};

// Create a folder named "common" under the organization
const folder = new gcp.organizations.Folder('common', {
  displayName: 'common',
  parent: `organizations/${orgId}`,
});

// Create a project named "cicd-XXXX" inside the folder
const cicd = new Project('cicd', {
  projectName: 'cicd',
  folderId: folder.id,
  billingAccount: billingAccountId,
  labels: labels,
  apis: config.requireObject('gcpApis'),
});
const project = cicd.project;
const projectId = cicd.projectId;

// Artifact Registry - Docker repository
const devtoolsRepo = new gcp.artifactregistry.Repository('devtools', {
  repositoryId: 'devtools',
  project: project.projectId,
  location: region,
  format: 'DOCKER',
  mode: 'STANDARD_REPOSITORY',
  labels: labels,
}, { dependsOn: cicd.enabledApis });

// Storage Bucket for state
const stateBucket = new gcp.storage.Bucket('state', {
  name: pulumi.interpolate`${project.projectId}-state`,
  project: project.projectId,
  location: region,
  uniformBucketLevelAccess: true,
  versioning: { enabled: true },
  labels: labels,
}, { dependsOn: cicd.enabledApis });

// Export outputs
export const commonFolder = folder;
export const cicdProject = project;
export const projectIdOutput = projectId;
export const devtoolsRepository = devtoolsRepo.id;
export const stateBucketName = stateBucket.name;
