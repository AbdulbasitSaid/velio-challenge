//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

enum InviteStatus {
  @JsonValue(r'created')
  created(r'created'),
  @JsonValue(r'opened')
  opened(r'opened'),
  @JsonValue(r'claimed')
  claimed(r'claimed'),
  @JsonValue(r'expired')
  expired(r'expired');

  const InviteStatus(this.value);

  final String value;

  @override
  String toString() => value;
}
