// This is a generated file - do not edit.
//
// Generated from plane.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use planeDescriptor instead')
const Plane$json = {
  '1': 'Plane',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 5, '10': 'id'},
    {'1': 'lat', '3': 2, '4': 1, '5': 2, '10': 'lat'},
    {'1': 'lon', '3': 3, '4': 1, '5': 2, '10': 'lon'},
    {'1': 'alt', '3': 4, '4': 1, '5': 17, '10': 'alt'},
    {'1': 'trk', '3': 5, '4': 1, '5': 5, '10': 'trk'},
    {'1': 'vs', '3': 6, '4': 1, '5': 17, '10': 'vs'},
    {'1': 'flight', '3': 7, '4': 1, '5': 9, '10': 'flight'},
    {'1': 'icao', '3': 8, '4': 1, '5': 9, '10': 'icao'},
  ],
};

/// Descriptor for `Plane`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List planeDescriptor = $convert.base64Decode(
    'CgVQbGFuZRIOCgJpZBgBIAEoBVICaWQSEAoDbGF0GAIgASgCUgNsYXQSEAoDbG9uGAMgASgCUg'
    'Nsb24SEAoDYWx0GAQgASgRUgNhbHQSEAoDdHJrGAUgASgFUgN0cmsSDgoCdnMYBiABKBFSAnZz'
    'EhYKBmZsaWdodBgHIAEoCVIGZmxpZ2h0EhIKBGljYW8YCCABKAlSBGljYW8=');

@$core.Deprecated('Use planesDescriptor instead')
const Planes$json = {
  '1': 'Planes',
  '2': [
    {'1': 'planes', '3': 1, '4': 3, '5': 11, '6': '.Plane', '10': 'planes'},
  ],
};

/// Descriptor for `Planes`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List planesDescriptor = $convert
    .base64Decode('CgZQbGFuZXMSHgoGcGxhbmVzGAEgAygLMgYuUGxhbmVSBnBsYW5lcw==');
