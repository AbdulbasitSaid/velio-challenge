//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

enum PauseReason {
  @JsonValue(r'owner')
  owner(r'owner'),
  @JsonValue(r'host')
  host(r'host'),
  @JsonValue(r'auto')
  auto(r'auto');

  const PauseReason(this.value);

  final String value;

  @override
  String toString() => value;
}
