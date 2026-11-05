part of 'claim_bloc.dart';

/// Where a final claim outcome leads: You're in, back to the invite showing "already going", or back
/// to the invite screen that already shows why (expired, paused, claimed, host).
enum ClaimResult { claimed, alreadyGoing, back }

final class ClaimState extends Equatable {
  const ClaimState({
    required this.signedIn,
    this.view,
    this.submitting = false,
    this.nameError,
    this.contactError,
    this.banner,
    this.result,
    this.planId,
    this.results = 0,
  });

  /// Claiming as the person saved on this phone.
  final bool signedIn;
  final InviteView? view;
  final bool submitting;
  final String? nameError;
  final String? contactError;
  final ClaimBanner? banner;

  /// The latest final outcome; [results] counts them so the view acts once on each.
  final ClaimResult? result;
  final String? planId;
  final int results;

  /// A final banner: no "Try again".
  bool get blocked => banner != null && !banner!.retry;

  ClaimState copyWith({
    bool? signedIn,
    InviteView? view,
    bool? submitting,
    String? Function()? nameError,
    String? Function()? contactError,
    ClaimBanner? Function()? banner,
    ClaimResult? result,
    String? planId,
    int? results,
  }) => ClaimState(
    signedIn: signedIn ?? this.signedIn,
    view: view ?? this.view,
    submitting: submitting ?? this.submitting,
    nameError: nameError != null ? nameError() : this.nameError,
    contactError: contactError != null ? contactError() : this.contactError,
    banner: banner != null ? banner() : this.banner,
    result: result ?? this.result,
    planId: planId ?? this.planId,
    results: results ?? this.results,
  );

  @override
  List<Object?> get props => [signedIn, view, submitting, nameError, contactError, banner, result, planId, results];
}
