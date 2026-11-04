//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

enum AttendanceMark {
  @JsonValue(r'attended')
  attended(r'attended'),
  @JsonValue(r'no_show')
  noShow(r'no_show');

  const AttendanceMark(this.value);

  final String value;

  @override
  String toString() => value;
}
