import { describe, expect, test } from 'bun:test';
import { App } from 'aws-cdk-lib';
import { Match, Template } from 'aws-cdk-lib/assertions';
import { AppStack } from '../lib/app-stack';

const EMAIL = 'alerts@example.test';

function synth(createGithubOidcProvider = true) {
  const app = new App();
  const stack = new AppStack(app, 'Test', {
    env: { account: '111111111111', region: 'eu-west-2' },
    amiId: 'ami-0123456789abcdef0',
    cloudfrontPrefixListId: 'pl-12345678',
    alertEmail: EMAIL,
    githubRepository: 'owner/repo',
    createGithubOidcProvider,
  });
  return Template.fromStack(stack);
}

const template = synth();

describe('instance and network (SEC-001)', () => {
  test('the security group admits only the API port from the CloudFront prefix list', () => {
    const groups = Object.values(template.findResources('AWS::EC2::SecurityGroup'));
    expect(groups).toHaveLength(1);
    expect(groups[0]!.Properties.SecurityGroupIngress).toBeUndefined();
    const ingress = Object.values(template.findResources('AWS::EC2::SecurityGroupIngress'));
    expect(ingress.map((r) => r.Properties)).toEqual([
      {
        Description: 'CloudFront origin-facing',
        FromPort: 3001,
        ToPort: 3001,
        IpProtocol: 'tcp',
        SourcePrefixListId: 'pl-12345678',
        GroupId: { 'Fn::GetAtt': [expect.any(String), 'GroupId'] },
      },
    ]);
  });

  test('IMDSv2 is required', () => {
    template.hasResourceProperties('AWS::EC2::LaunchTemplate', {
      LaunchTemplateData: { MetadataOptions: { HttpTokens: 'required' } },
    });
  });

  test('the root volume is encrypted gp3, kept on termination', () => {
    template.hasResourceProperties('AWS::EC2::Instance', {
      InstanceType: 't4g.small',
      ImageId: 'ami-0123456789abcdef0',
      BlockDeviceMappings: [
        {
          DeviceName: '/dev/xvda',
          Ebs: { VolumeSize: 30, VolumeType: 'gp3', Encrypted: true, DeleteOnTermination: false },
        },
      ],
    });
  });

  test('there is no NAT gateway', () => {
    template.resourceCountIs('AWS::EC2::NatGateway', 0);
  });
});

describe('buckets (SEC-006, FR-006)', () => {
  test('every bucket blocks public access and is encrypted', () => {
    const buckets = Object.values(template.findResources('AWS::S3::Bucket'));
    expect(buckets).toHaveLength(3);
    for (const bucket of buckets) {
      expect(bucket.Properties.PublicAccessBlockConfiguration).toEqual({
        BlockPublicAcls: true,
        BlockPublicPolicy: true,
        IgnorePublicAcls: true,
        RestrictPublicBuckets: true,
      });
      expect(bucket.Properties.BucketEncryption).toBeDefined();
    }
  });

  test('backups expire after 14 days and survive stack deletion', () => {
    template.hasResource('AWS::S3::Bucket', {
      DeletionPolicy: 'Retain',
      Properties: { LifecycleConfiguration: { Rules: [Match.objectLike({ ExpirationInDays: 14 })] } },
    });
  });

  test('daily snapshots of the tagged volume keep 7', () => {
    template.hasResourceProperties('AWS::DLM::LifecyclePolicy', {
      PolicyDetails: {
        TargetTags: [{ Key: 'velio:backup', Value: 'daily' }],
        Schedules: [Match.objectLike({ RetainRule: { Count: 7 } })],
      },
    });
  });
});

describe('CloudFront (FR-003, SEC-002)', () => {
  const config = () =>
    Object.values(template.findResources('AWS::CloudFront::Distribution'))[0]!.Properties.DistributionConfig;

  test('api, ws and default behaviors go uncached to the instance; photos are cached from S3', () => {
    const { DefaultCacheBehavior, CacheBehaviors, Origins } = config();
    const apiOrigin = Origins.find((o: { CustomOriginConfig?: unknown }) => o.CustomOriginConfig);
    expect(apiOrigin.CustomOriginConfig).toMatchObject({ HTTPPort: 3001, OriginProtocolPolicy: 'http-only' });

    const cachingDisabled = '4135ea2d-6df8-44a3-9df3-4b5a84be39ad';
    const allViewerExceptHost = 'b689b0a8-53d0-40ab-baf2-68738e2966ac';
    for (const behavior of [
      DefaultCacheBehavior,
      ...CacheBehaviors.filter((b: { PathPattern: string }) => b.PathPattern !== '/photos/*'),
    ]) {
      expect(behavior.TargetOriginId).toBe(apiOrigin.Id);
      expect(behavior.CachePolicyId).toBe(cachingDisabled);
      expect(behavior.OriginRequestPolicyId).toBe(allViewerExceptHost);
      expect(behavior.ViewerProtocolPolicy).toBe('redirect-to-https');
    }
    expect(CacheBehaviors.map((b: { PathPattern: string }) => b.PathPattern)).toEqual([
      '/api/*',
      '/ws',
      '/photos/*',
    ]);

    const photos = CacheBehaviors.find((b: { PathPattern: string }) => b.PathPattern === '/photos/*');
    expect(photos.TargetOriginId).not.toBe(apiOrigin.Id);
    expect(photos.CachePolicyId).toBe('658327ea-f89d-4fab-a63d-7e88639e58f6');
    template.resourceCountIs('AWS::CloudFront::OriginAccessControl', 1);
  });

  test('the origin header is a Secrets Manager dynamic reference, not a value', () => {
    const header = config().Origins.flatMap(
      (o: { OriginCustomHeaders?: unknown[] }) => o.OriginCustomHeaders ?? [],
    )[0];
    expect(header.HeaderName).toBe('X-Origin-Verify');
    expect(JSON.stringify(header.HeaderValue)).toContain('{{resolve:secretsmanager:');
  });
});

describe('secrets (SEC-003)', () => {
  test('six secrets under velio/prod; all but grafana are generated', () => {
    const secrets = Object.values(template.findResources('AWS::SecretsManager::Secret'));
    expect(secrets.map((s) => s.Properties.Name).sort()).toEqual(
      [
        'contact-pepper',
        'db-api-password',
        'db-readonly-password',
        'db-superuser-password',
        'grafana',
        'origin-verify',
      ].map((n) => `velio/prod/${n}`),
    );
    for (const s of secrets) {
      if (s.Properties.Name === 'velio/prod/grafana') expect(s.Properties.SecretString).toBe('{}');
      else
        expect(s.Properties.GenerateSecretString).toMatchObject({
          PasswordLength: 64,
          ExcludePunctuation: true,
        });
    }
  });
});

describe('deploy role (SEC-004)', () => {
  test('trusts only master of the repository through GitHub OIDC', () => {
    template.hasResourceProperties('AWS::IAM::Role', {
      RoleName: 'velio-deploy',
      AssumeRolePolicyDocument: {
        Statement: [
          Match.objectLike({
            Action: 'sts:AssumeRoleWithWebIdentity',
            Condition: {
              StringEquals: {
                'token.actions.githubusercontent.com:aud': 'sts.amazonaws.com',
                'token.actions.githubusercontent.com:sub': 'repo:owner/repo:ref:refs/heads/master',
              },
            },
          }),
        ],
      },
    });
  });

  test('SendCommand is limited to the instance and AWS-RunShellScript', () => {
    const policies = Object.values(template.findResources('AWS::IAM::Policy'));
    const send = policies
      .flatMap((p) => p.Properties.PolicyDocument.Statement)
      .filter((s: { Action: unknown }) => s.Action === 'ssm:SendCommand');
    expect(send).toHaveLength(1);
    expect(JSON.stringify(send[0].Resource)).toContain(':instance/');
    expect(JSON.stringify(send[0].Resource)).toContain('document/AWS-RunShellScript');
  });

  test('the OIDC provider is created only when asked', () => {
    template.resourceCountIs('AWS::IAM::OIDCProvider', 1);
    synth(false).resourceCountIs('AWS::IAM::OIDCProvider', 0);
  });
});

describe('alarms (FR-009)', () => {
  test('the status-check alarm recovers the instance and notifies the email from props', () => {
    template.hasResourceProperties('AWS::SNS::Subscription', { Protocol: 'email', Endpoint: EMAIL });
    const alarm = Object.values(template.findResources('AWS::CloudWatch::Alarm'))[0]!.Properties;
    expect(alarm.MetricName).toBe('StatusCheckFailed_System');
    expect(JSON.stringify(alarm.AlarmActions)).toContain(':ec2:recover');
    expect(alarm.AlarmActions).toContainEqual({ Ref: expect.stringMatching(/^Alerts/) });
  });
});
