import { readFileSync } from 'node:fs';
import {
  CfnOutput,
  Duration,
  Fn,
  RemovalPolicy,
  SecretValue,
  Stack,
  Tags,
  type StackProps,
  aws_cloudfront as cloudfront,
  aws_cloudfront_origins as origins,
  aws_cloudwatch as cloudwatch,
  aws_cloudwatch_actions as cwActions,
  aws_dlm as dlm,
  aws_ec2 as ec2,
  aws_iam as iam,
  aws_s3 as s3,
  aws_secretsmanager as secretsmanager,
  aws_sns as sns,
  aws_sns_subscriptions as subscriptions,
} from 'aws-cdk-lib';
import type { Construct } from 'constructs';

export interface AppStackProps extends StackProps {
  /** Amazon Linux 2023 arm64 AMI in eu-west-2, pinned (README "Updating the AMI"). */
  amiId: string;
  /** ID of the `com.amazonaws.global.cloudfront.origin-facing` managed prefix list in eu-west-2. */
  cloudfrontPrefixListId: string;
  /** Status-check alarm recipient. Passed at deploy time; never committed (public repository). */
  alertEmail: string;
  /** `owner/name` of the GitHub repository allowed to deploy. */
  githubRepository: string;
  /** False when the account already has GitHub's OIDC provider; it is then referenced, not created. */
  createGithubOidcProvider: boolean;
  /**
   * The app's origin, `https://<distribution>.cloudfront.net`: browsers POST photos to the bucket from
   * it (S5 §4.9). A prop, because the bucket's CORS can't reference the distribution that uses it.
   */
  appOrigin: string;
}

const API_PORT = 3001;
const WEB_PORT = 3000;
const SECRET_PREFIX = 'velio/prod';
const SCRIPTS = new URL('../scripts/', import.meta.url);

/** S10a (spec/2026-11-03_16-15_s10-aws-app-stack): one instance running Compose, behind CloudFront. */
export class AppStack extends Stack {
  constructor(scope: Construct, id: string, props: AppStackProps) {
    super(scope, id, props);

    // Secrets. Generated values are alphanumeric so they fit in URLs and env files unquoted.
    const generated = (name: string) =>
      new secretsmanager.Secret(this, `Secret-${name}`, {
        secretName: `${SECRET_PREFIX}/${name}`,
        generateSecretString: { passwordLength: 64, excludePunctuation: true },
      });
    const originVerify = generated('origin-verify');
    const secrets = [
      originVerify,
      generated('contact-pepper'),
      // S8: bearer token for /api/admin/* and the web /admin page.
      generated('admin-token'),
      generated('db-superuser-password'),
      generated('db-api-password'),
      generated('db-readonly-password'),
      // Filled in by hand once the Grafana Cloud stack exists (README "Grafana Cloud").
      new secretsmanager.Secret(this, 'Secret-grafana', {
        secretName: `${SECRET_PREFIX}/grafana`,
        secretStringValue: SecretValue.unsafePlainText('{}'),
      }),
      // Filled in by hand: {"serverKey": "...", "signingSecret": "..."} (S6 §4.6). Empty → no map images.
      new secretsmanager.Secret(this, 'Secret-google-maps', {
        secretName: `${SECRET_PREFIX}/google-maps`,
        secretStringValue: SecretValue.unsafePlainText('{}'),
      }),
    ];

    // Buckets.
    const bucketDefaults = {
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      encryption: s3.BucketEncryption.S3_MANAGED,
      enforceSSL: true,
    } satisfies s3.BucketProps;
    const photos = new s3.Bucket(this, 'Photos', {
      ...bucketDefaults,
      removalPolicy: RemovalPolicy.DESTROY,
      autoDeleteObjects: true,
      // Presigned POSTs from the browser (S5 FR-041). The policy in each POST limits key, type and size.
      cors: [{ allowedOrigins: [props.appOrigin], allowedMethods: [s3.HttpMethods.POST], maxAge: 3600 }],
    });
    const backups = new s3.Bucket(this, 'Backups', {
      ...bucketDefaults,
      lifecycleRules: [{ expiration: Duration.days(14) }],
      removalPolicy: RemovalPolicy.RETAIN,
    });
    const deploy = new s3.Bucket(this, 'Deploy', {
      ...bucketDefaults,
      lifecycleRules: [{ expiration: Duration.days(30) }],
      removalPolicy: RemovalPolicy.DESTROY,
      autoDeleteObjects: true,
    });

    // Network: public subnets only, no NAT gateway.
    const vpc = new ec2.Vpc(this, 'Vpc', {
      maxAzs: 2,
      natGateways: 0,
      subnetConfiguration: [{ name: 'public', subnetType: ec2.SubnetType.PUBLIC, cidrMask: 24 }],
    });
    // The CloudFront origin-facing prefix list counts as ~55 rules per use, so two rules need the region's
    // "rules per security group" quota above the default 60 (raised to 120, README "AWS quotas").
    // A group's description is immutable: changing it replaces the group and restarts the instance.
    const securityGroup = new ec2.SecurityGroup(this, 'AppSg', {
      vpc,
      description: 'Velio app: API port from CloudFront only',
      allowAllOutbound: true,
    });
    for (const port of [API_PORT, WEB_PORT]) {
      securityGroup.addIngressRule(
        ec2.Peer.prefixList(props.cloudfrontPrefixListId),
        ec2.Port.tcp(port),
        'CloudFront origin-facing',
      );
    }

    // Instance.
    const role = new iam.Role(this, 'InstanceRole', {
      assumedBy: new iam.ServicePrincipal('ec2.amazonaws.com'),
      managedPolicies: [iam.ManagedPolicy.fromAwsManagedPolicyName('AmazonSSMManagedInstanceCore')],
    });
    for (const secret of secrets) secret.grantRead(role);
    deploy.grantRead(role);
    backups.grantPut(role);
    // The API presigns photo uploads and checks they exist (S5 §4.9): signatures carry the role's rights.
    photos.grantPut(role, 'photos/*');
    photos.grantRead(role, 'photos/*');

    const userData = ec2.UserData.forLinux();
    userData.addCommands(
      'mkdir -p /opt/velio',
      "cat >/opt/velio/stack.env <<'EOF'",
      `AWS_REGION=${this.region}`,
      `DEPLOY_BUCKET=${deploy.bucketName}`,
      `BACKUP_BUCKET=${backups.bucketName}`,
      'EOF',
      readFileSync(new URL('user-data.sh', SCRIPTS), 'utf8'),
    );

    const instance = new ec2.Instance(this, 'App', {
      vpc,
      vpcSubnets: { subnetType: ec2.SubnetType.PUBLIC },
      instanceType: ec2.InstanceType.of(ec2.InstanceClass.T4G, ec2.InstanceSize.SMALL),
      machineImage: ec2.MachineImage.genericLinux({ [this.region]: props.amiId }),
      securityGroup,
      role,
      userData,
      requireImdsv2: true,
      propagateTagsToVolumeOnCreation: true,
      blockDevices: [
        {
          deviceName: '/dev/xvda',
          // Postgres data lives here (/opt/velio/data); kept if the instance is terminated.
          volume: ec2.BlockDeviceVolume.ebs(30, {
            volumeType: ec2.EbsDeviceVolumeType.GP3,
            encrypted: true,
            deleteOnTermination: false,
          }),
        },
      ],
    });
    Tags.of(instance).add('velio:backup', 'daily');

    // A stable address across stop/start. CloudFront needs a DNS name: the EIP's public DNS name.
    const eip = new ec2.CfnEIP(this, 'AppEip', { instanceId: instance.instanceId });
    const originDomain = Fn.join('', [
      'ec2-',
      Fn.join('-', Fn.split('.', eip.attrPublicIp)),
      `.${this.region}.compute.amazonaws.com`,
    ]);

    // CloudFront. The origin header value is a dynamic reference, resolved by CloudFormation.
    const instanceOrigin = (httpPort: number) =>
      new origins.HttpOrigin(originDomain, {
        protocolPolicy: cloudfront.OriginProtocolPolicy.HTTP_ONLY,
        httpPort,
        customHeaders: { 'X-Origin-Verify': originVerify.secretValue.unsafeUnwrap() },
      });
    const uncached = (origin: cloudfront.IOrigin): cloudfront.BehaviorOptions => ({
      origin,
      viewerProtocolPolicy: cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
      allowedMethods: cloudfront.AllowedMethods.ALLOW_ALL,
      cachePolicy: cloudfront.CachePolicy.CACHING_DISABLED,
      originRequestPolicy: cloudfront.OriginRequestPolicy.ALL_VIEWER_EXCEPT_HOST_HEADER,
    });
    const web = instanceOrigin(WEB_PORT);
    const distribution = new cloudfront.Distribution(this, 'Cdn', {
      comment: 'Velio',
      priceClass: cloudfront.PriceClass.PRICE_CLASS_100,
      httpVersion: cloudfront.HttpVersion.HTTP2_AND_3,
      // Pages go to the Next.js app (S5); the socket is /api/ws, under /api/* (S3).
      defaultBehavior: uncached(web),
      additionalBehaviors: {
        '/api/*': uncached(instanceOrigin(API_PORT)),
        // Content-hashed build assets: safe to cache for as long as CloudFront keeps them.
        '/_next/static/*': {
          origin: web,
          viewerProtocolPolicy: cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
          cachePolicy: cloudfront.CachePolicy.CACHING_OPTIMIZED,
        },
        '/photos/*': {
          origin: origins.S3BucketOrigin.withOriginAccessControl(photos),
          viewerProtocolPolicy: cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
          cachePolicy: cloudfront.CachePolicy.CACHING_OPTIMIZED,
        },
      },
    });

    // Daily snapshots of the tagged volume, keeping 7.
    const dlmRole = new iam.Role(this, 'SnapshotRole', {
      assumedBy: new iam.ServicePrincipal('dlm.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('service-role/AWSDataLifecycleManagerServiceRole'),
      ],
    });
    new dlm.CfnLifecyclePolicy(this, 'DailySnapshots', {
      description: 'Velio daily EBS snapshots',
      state: 'ENABLED',
      executionRoleArn: dlmRole.roleArn,
      policyDetails: {
        resourceTypes: ['VOLUME'],
        targetTags: [{ key: 'velio:backup', value: 'daily' }],
        schedules: [
          {
            name: 'daily',
            // After the 02:00 UTC dump.
            createRule: { interval: 24, intervalUnit: 'HOURS', times: ['03:00'] },
            retainRule: { count: 7 },
            copyTags: true,
          },
        ],
      },
    });

    // Failed system status check: recover the instance and email.
    const alerts = new sns.Topic(this, 'Alerts', { displayName: 'Velio alerts' });
    alerts.addSubscription(new subscriptions.EmailSubscription(props.alertEmail));
    const statusAlarm = new cloudwatch.Alarm(this, 'StatusCheckAlarm', {
      alarmDescription: 'Velio app instance failed its system status check',
      metric: new cloudwatch.Metric({
        namespace: 'AWS/EC2',
        metricName: 'StatusCheckFailed_System',
        dimensionsMap: { InstanceId: instance.instanceId },
        statistic: 'Maximum',
        period: Duration.minutes(1),
      }),
      threshold: 1,
      evaluationPeriods: 2,
      comparisonOperator: cloudwatch.ComparisonOperator.GREATER_THAN_OR_EQUAL_TO_THRESHOLD,
    });
    statusAlarm.addAlarmAction(new cwActions.Ec2Action(cwActions.Ec2InstanceAction.RECOVER));
    statusAlarm.addAlarmAction(new cwActions.SnsAction(alerts));

    // GitHub Actions deploys through OIDC: only pushes to master of this repository.
    const githubHost = 'token.actions.githubusercontent.com';
    const provider = props.createGithubOidcProvider
      ? new iam.OidcProviderNative(this, 'GithubOidc', {
          url: `https://${githubHost}`,
          clientIds: ['sts.amazonaws.com'],
        })
      : iam.OidcProviderNative.fromOidcProviderArn(
          this,
          'GithubOidc',
          `arn:aws:iam::${this.account}:oidc-provider/${githubHost}`,
        );
    const deployRole = new iam.Role(this, 'DeployRole', {
      roleName: 'velio-deploy',
      maxSessionDuration: Duration.hours(1),
      assumedBy: new iam.WebIdentityPrincipal(provider.oidcProviderArn, {
        StringEquals: {
          [`${githubHost}:aud`]: 'sts.amazonaws.com',
          [`${githubHost}:sub`]: `repo:${props.githubRepository}:ref:refs/heads/master`,
        },
      }),
    });
    deploy.grantPut(deployRole);
    deployRole.addToPolicy(
      new iam.PolicyStatement({
        actions: ['ssm:SendCommand'],
        resources: [
          `arn:aws:ec2:${this.region}:${this.account}:instance/${instance.instanceId}`,
          `arn:aws:ssm:${this.region}::document/AWS-RunShellScript`,
        ],
      }),
    );
    // Reads only: waiting for the command, and finding this stack's outputs.
    deployRole.addToPolicy(
      new iam.PolicyStatement({ actions: ['ssm:GetCommandInvocation'], resources: ['*'] }),
    );
    deployRole.addToPolicy(
      new iam.PolicyStatement({ actions: ['cloudformation:DescribeStacks'], resources: [this.stackId] }),
    );

    new CfnOutput(this, 'DistributionDomain', { value: distribution.distributionDomainName });
    new CfnOutput(this, 'InstanceId', { value: instance.instanceId });
    new CfnOutput(this, 'OriginIp', { value: eip.attrPublicIp });
    new CfnOutput(this, 'DeployBucket', { value: deploy.bucketName });
    new CfnOutput(this, 'BackupBucket', { value: backups.bucketName });
    new CfnOutput(this, 'PhotosBucket', { value: photos.bucketName });
    new CfnOutput(this, 'DeployRoleArn', { value: deployRole.roleArn });
  }
}
