import 'package:velio_api/src/model/activity_card.dart';
import 'package:velio_api/src/model/activity_card_location.dart';
import 'package:velio_api/src/model/activity_create.dart';
import 'package:velio_api/src/model/activity_patch.dart';
import 'package:velio_api/src/model/activity_state.dart';
import 'package:velio_api/src/model/admin_activity.dart';
import 'package:velio_api/src/model/admin_activity_list.dart';
import 'package:velio_api/src/model/admin_audit.dart';
import 'package:velio_api/src/model/admin_audit_failures_inner.dart';
import 'package:velio_api/src/model/admin_goal.dart';
import 'package:velio_api/src/model/admin_metrics.dart';
import 'package:velio_api/src/model/admin_metrics_audit.dart';
import 'package:velio_api/src/model/admin_metrics_funnel_inner.dart';
import 'package:velio_api/src/model/admin_metrics_guardrail.dart';
import 'package:velio_api/src/model/admin_metrics_holdout_inner.dart';
import 'package:velio_api/src/model/admin_metrics_invite_rate_inner.dart';
import 'package:velio_api/src/model/admin_metrics_k_factor_inner.dart';
import 'package:velio_api/src/model/attendance.dart';
import 'package:velio_api/src/model/attendance_activity.dart';
import 'package:velio_api/src/model/attendance_mark_create.dart';
import 'package:velio_api/src/model/attendee.dart';
import 'package:velio_api/src/model/booking.dart';
import 'package:velio_api/src/model/booking_response.dart';
import 'package:velio_api/src/model/claim_create.dart';
import 'package:velio_api/src/model/claim_response.dart';
import 'package:velio_api/src/model/client_event.dart';
import 'package:velio_api/src/model/client_event_one_of.dart';
import 'package:velio_api/src/model/client_event_one_of1.dart';
import 'package:velio_api/src/model/community.dart';
import 'package:velio_api/src/model/community_list.dart';
import 'package:velio_api/src/model/community_page.dart';
import 'package:velio_api/src/model/error_envelope.dart';
import 'package:velio_api/src/model/error_envelope_error.dart';
import 'package:velio_api/src/model/health.dart';
import 'package:velio_api/src/model/host_activity.dart';
import 'package:velio_api/src/model/host_activity_item.dart';
import 'package:velio_api/src/model/host_activity_list.dart';
import 'package:velio_api/src/model/invite.dart';
import 'package:velio_api/src/model/invite_create.dart';
import 'package:velio_api/src/model/invite_create_one_of.dart';
import 'package:velio_api/src/model/invite_create_one_of1.dart';
import 'package:velio_api/src/model/invite_view.dart';
import 'package:velio_api/src/model/location.dart';
import 'package:velio_api/src/model/member_person.dart';
import 'package:velio_api/src/model/my_plan.dart';
import 'package:velio_api/src/model/my_plan_members.dart';
import 'package:velio_api/src/model/my_plans.dart';
import 'package:velio_api/src/model/next_steps.dart';
import 'package:velio_api/src/model/open_create.dart';
import 'package:velio_api/src/model/photo_upload_request.dart';
import 'package:velio_api/src/model/photo_upload_response.dart';
import 'package:velio_api/src/model/photo_upload_response_uploads.dart';
import 'package:velio_api/src/model/plan_invite.dart';
import 'package:velio_api/src/model/plan_view.dart';
import 'package:velio_api/src/model/plan_view_activity.dart';
import 'package:velio_api/src/model/plan_view_members_inner.dart';
import 'package:velio_api/src/model/plan_view_viewer.dart';
import 'package:velio_api/src/model/plan_view_viewer_booking.dart';
import 'package:velio_api/src/model/presigned_post.dart';
import 'package:velio_api/src/model/profile.dart';
import 'package:velio_api/src/model/public_activity.dart';
import 'package:velio_api/src/model/public_activity_community.dart';
import 'package:velio_api/src/model/public_activity_members.dart';
import 'package:velio_api/src/model/public_activity_viewer.dart';
import 'package:velio_api/src/model/public_activity_viewer_booking.dart';
import 'package:velio_api/src/model/public_location.dart';
import 'package:velio_api/src/model/public_person.dart';
import 'package:velio_api/src/model/ratio.dart';
import 'package:velio_api/src/model/session_create.dart';
import 'package:velio_api/src/model/session_response.dart';

final _regList = RegExp(r'^List<(.*)>$');
final _regSet = RegExp(r'^Set<(.*)>$');
final _regMap = RegExp(r'^Map<String,(.*)>$');

  ReturnType deserialize<ReturnType, BaseType>(dynamic value, String targetType, {bool growable= true}) {
      switch (targetType) {
        case 'String':
          return '$value' as ReturnType;
        case 'int':
          return (value is int ? value : int.parse('$value')) as ReturnType;
        case 'bool':
          if (value is bool) {
            return value as ReturnType;
          }
          final valueString = '$value'.toLowerCase();
          return (valueString == 'true' || valueString == '1') as ReturnType;
        case 'double':
          return (value is double ? value : double.parse('$value')) as ReturnType;
        case 'ActivityCard':
          return ActivityCard.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ActivityCardLocation':
          return ActivityCardLocation.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ActivityCreate':
          return ActivityCreate.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ActivityPatch':
          return ActivityPatch.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ActivityState':
          return ActivityState.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminActivity':
          return AdminActivity.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminActivityList':
          return AdminActivityList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminAudit':
          return AdminAudit.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminAuditFailuresInner':
          return AdminAuditFailuresInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminGoal':
          return AdminGoal.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminMetrics':
          return AdminMetrics.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminMetricsAudit':
          return AdminMetricsAudit.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminMetricsFunnelInner':
          return AdminMetricsFunnelInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminMetricsGuardrail':
          return AdminMetricsGuardrail.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminMetricsHoldoutInner':
          return AdminMetricsHoldoutInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminMetricsInviteRateInner':
          return AdminMetricsInviteRateInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminMetricsKFactorInner':
          return AdminMetricsKFactorInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Attendance':
          return Attendance.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AttendanceActivity':
          return AttendanceActivity.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AttendanceMark':
          
          
        case 'AttendanceMarkCreate':
          return AttendanceMarkCreate.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Attendee':
          return Attendee.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Booking':
          return Booking.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BookingResponse':
          return BookingResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ClaimCreate':
          return ClaimCreate.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ClaimResponse':
          return ClaimResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ClientEvent':
          return ClientEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ClientEventOneOf':
          return ClientEventOneOf.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ClientEventOneOf1':
          return ClientEventOneOf1.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Community':
          return Community.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CommunityList':
          return CommunityList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CommunityPage':
          return CommunityPage.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ErrorCode':
          
          
        case 'ErrorEnvelope':
          return ErrorEnvelope.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ErrorEnvelopeError':
          return ErrorEnvelopeError.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Health':
          return Health.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'HostActivity':
          return HostActivity.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'HostActivityItem':
          return HostActivityItem.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'HostActivityList':
          return HostActivityList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Invite':
          return Invite.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'InviteCreate':
          return InviteCreate.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'InviteCreateOneOf':
          return InviteCreateOneOf.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'InviteCreateOneOf1':
          return InviteCreateOneOf1.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'InviteStatus':
          
          
        case 'InviteView':
          return InviteView.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Location':
          return Location.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'MemberPerson':
          return MemberPerson.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'MyPlan':
          return MyPlan.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'MyPlanMembers':
          return MyPlanMembers.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'MyPlans':
          return MyPlans.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'NextSteps':
          return NextSteps.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'OpenCreate':
          return OpenCreate.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PauseReason':
          
          
        case 'PhotoUploadRequest':
          return PhotoUploadRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PhotoUploadResponse':
          return PhotoUploadResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PhotoUploadResponseUploads':
          return PhotoUploadResponseUploads.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PlanInvite':
          return PlanInvite.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PlanView':
          return PlanView.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PlanViewActivity':
          return PlanViewActivity.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PlanViewMembersInner':
          return PlanViewMembersInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PlanViewViewer':
          return PlanViewViewer.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PlanViewViewerBooking':
          return PlanViewViewerBooking.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PresignedPost':
          return PresignedPost.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Profile':
          return Profile.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PublicActivity':
          return PublicActivity.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PublicActivityCommunity':
          return PublicActivityCommunity.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PublicActivityMembers':
          return PublicActivityMembers.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PublicActivityViewer':
          return PublicActivityViewer.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PublicActivityViewerBooking':
          return PublicActivityViewerBooking.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PublicLocation':
          return PublicLocation.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PublicPerson':
          return PublicPerson.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Ratio':
          return Ratio.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SessionCreate':
          return SessionCreate.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SessionResponse':
          return SessionResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        default:
          RegExpMatch? match;

          if (value is List && (match = _regList.firstMatch(targetType)) != null) {
            targetType = match![1]!; // ignore: parameter_assignments
            return value
              .map<BaseType>((dynamic v) => deserialize<BaseType, BaseType>(v, targetType, growable: growable))
              .toList(growable: growable) as ReturnType;
          }
          if (value is Set && (match = _regSet.firstMatch(targetType)) != null) {
            targetType = match![1]!; // ignore: parameter_assignments
            return value
              .map<BaseType>((dynamic v) => deserialize<BaseType, BaseType>(v, targetType, growable: growable))
              .toSet() as ReturnType;
          }
          if (value is Map && (match = _regMap.firstMatch(targetType)) != null) {
            targetType = match![1]!.trim(); // ignore: parameter_assignments
            return Map<String, BaseType>.fromIterables(
              value.keys as Iterable<String>,
              value.values.map((dynamic v) => deserialize<BaseType, BaseType>(v, targetType, growable: growable)),
            ) as ReturnType;
          }
          break;
    }
    throw Exception('Cannot deserialize');
  }