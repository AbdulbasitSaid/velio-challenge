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
  // The repository uses GitHub's immutable OIDC subject, which embeds the owner and repository IDs:
  // `gh api repos/AbdulbasitSaid/velio-challenge/actions/oidc/customization/sub` → sub_claim_prefix.
  githubRepository: 'AbdulbasitSaid@16627656/velio-challenge@1443959310',
  createGithubOidcProvider: app.node.tryGetContext('velio:createGithubOidcProvider') !== false,
  // The distribution's hostname is stable: it must never be deleted (MVP plan §8).
  appOrigin: 'https://depimls1pcvv4.cloudfront.net',
});
