// This is a generated file - do not edit.
//
// Generated from plane.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class Plane extends $pb.GeneratedMessage {
  factory Plane({
    $core.int? id,
    $core.double? lat,
    $core.double? lon,
    $core.int? alt,
    $core.int? trk,
    $core.int? vs,
    $core.String? flight,
    $core.String? icao,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (lat != null) result.lat = lat;
    if (lon != null) result.lon = lon;
    if (alt != null) result.alt = alt;
    if (trk != null) result.trk = trk;
    if (vs != null) result.vs = vs;
    if (flight != null) result.flight = flight;
    if (icao != null) result.icao = icao;
    return result;
  }

  Plane._();

  factory Plane.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Plane.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Plane',
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'id')
    ..aD(2, _omitFieldNames ? '' : 'lat', fieldType: $pb.PbFieldType.OF)
    ..aD(3, _omitFieldNames ? '' : 'lon', fieldType: $pb.PbFieldType.OF)
    ..aI(4, _omitFieldNames ? '' : 'alt', fieldType: $pb.PbFieldType.OS3)
    ..aI(5, _omitFieldNames ? '' : 'trk')
    ..aI(6, _omitFieldNames ? '' : 'vs', fieldType: $pb.PbFieldType.OS3)
    ..aOS(7, _omitFieldNames ? '' : 'flight')
    ..aOS(8, _omitFieldNames ? '' : 'icao')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Plane clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Plane copyWith(void Function(Plane) updates) =>
      super.copyWith((message) => updates(message as Plane)) as Plane;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Plane create() => Plane._();
  @$core.override
  Plane createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Plane getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Plane>(create);
  static Plane? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get id => $_getIZ(0);
  @$pb.TagNumber(1)
  set id($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get lat => $_getN(1);
  @$pb.TagNumber(2)
  set lat($core.double value) => $_setFloat(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLat() => $_has(1);
  @$pb.TagNumber(2)
  void clearLat() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get lon => $_getN(2);
  @$pb.TagNumber(3)
  set lon($core.double value) => $_setFloat(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLon() => $_has(2);
  @$pb.TagNumber(3)
  void clearLon() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get alt => $_getIZ(3);
  @$pb.TagNumber(4)
  set alt($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAlt() => $_has(3);
  @$pb.TagNumber(4)
  void clearAlt() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get trk => $_getIZ(4);
  @$pb.TagNumber(5)
  set trk($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTrk() => $_has(4);
  @$pb.TagNumber(5)
  void clearTrk() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get vs => $_getIZ(5);
  @$pb.TagNumber(6)
  set vs($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasVs() => $_has(5);
  @$pb.TagNumber(6)
  void clearVs() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get flight => $_getSZ(6);
  @$pb.TagNumber(7)
  set flight($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasFlight() => $_has(6);
  @$pb.TagNumber(7)
  void clearFlight() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get icao => $_getSZ(7);
  @$pb.TagNumber(8)
  set icao($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasIcao() => $_has(7);
  @$pb.TagNumber(8)
  void clearIcao() => $_clearField(8);
}

class Planes extends $pb.GeneratedMessage {
  factory Planes({
    $core.Iterable<Plane>? planes,
  }) {
    final result = create();
    if (planes != null) result.planes.addAll(planes);
    return result;
  }

  Planes._();

  factory Planes.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Planes.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Planes',
      createEmptyInstance: create)
    ..pPM<Plane>(1, _omitFieldNames ? '' : 'planes', subBuilder: Plane.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Planes clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Planes copyWith(void Function(Planes) updates) =>
      super.copyWith((message) => updates(message as Planes)) as Planes;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Planes create() => Planes._();
  @$core.override
  Planes createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Planes getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Planes>(create);
  static Planes? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Plane> get planes => $_getList(0);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
