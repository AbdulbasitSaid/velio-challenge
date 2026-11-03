import { App } from 'aws-cdk-lib';
import { AppStack } from '../lib/app-stack';

const app = new App();

const alertEmail: unknown = app.node.tryGetContext('alertEmail');
if (typeof alertEmail !== 'string' || !alertEmail.includes('@')) {
  throw new Error('Pass the alarm email at deploy time: bun run aws:deploy -c alertEmail=you@example.com');
}

new AppStack(app, 'VelioApp', {
  env: { account: process.env.CDK_DEFAULT_ACCOUNT, region: 'eu-west-2' },
  // Pinned; refreshed by hand (README "Updating the AMI").
  amiId: 'ami-0d623184a69654e22', // al2023-ami-2023.12.20261102.0-kernel-6.18-arm64
  cloudfrontPrefixListId: 'pl-93a247fa',
  alertEmail,
  githubRepository: 'AbdulbasitSaid/velio-challenge',
  createGithubOidcProvider: app.node.tryGetContext('velio:createGithubOidcProvider') !== false,
});
