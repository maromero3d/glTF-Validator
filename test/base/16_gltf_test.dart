/*
 * # Copyright (c) 2016-2017 The Khronos Group Inc.
 * # Copyright (c) 2016 Alexey Knyazev
 * #
 * # Licensed under the Apache License, Version 2.0 (the "License");
 * # you may not use this file except in compliance with the License.
 * # You may obtain a copy of the License at
 * #
 * #     http://www.apache.org/licenses/LICENSE-2.0
 * #
 * # Unless required by applicable law or agreed to in writing, software
 * # distributed under the License is distributed on an "AS IS" BASIS,
 * # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * # See the License for the specific language governing permissions and
 * # limitations under the License.
 */

import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';
import 'package:gltf/gltf.dart';
import 'package:gltf/src/errors.dart';

void main() {
  group('glTF', () {
    test('Invalid Collection', () async {
      const json = '{"asset": {"version": "2.0"},"samplers": {}}';
      final reader = new GltfJsonReader(
          new Stream<List<int>>.fromIterable([json.codeUnits]));

      final context = new Context()
        ..addIssue(SchemaError.typeMismatch,
            name: 'samplers', args: [<Object, Object>{}, 'array']);

      await reader.read();

      expect(reader.context.issues, unorderedMatches(context.issues));
    });

    test('Invalid Collection Element', () async {
      const json = '{"asset": {"version": "2.0"},"samplers": [[], null]}';
      final reader = new GltfJsonReader(
          new Stream<List<int>>.fromIterable([json.codeUnits]));

      final context = new Context()
        ..path.add('samplers')
        ..addIssue(SchemaError.typeMismatch,
            index: 0, args: [<Object>[], 'object'])
        ..addIssue(SchemaError.typeMismatch, index: 1, args: [null, 'object']);

      await reader.read();

      expect(reader.context.issues, unorderedMatches(context.issues));
    });

    test('Invalid Linkable Collection Element', () async {
      const json = '{"asset": {"version": "2.0"},"materials": [[], null]}';
      final reader = new GltfJsonReader(
          new Stream<List<int>>.fromIterable([json.codeUnits]));

      final context = new Context()
        ..path.add('materials')
        ..addIssue(SchemaError.typeMismatch,
            index: 0, args: [<Object>[], 'object'])
        ..addIssue(SchemaError.typeMismatch, index: 1, args: [null, 'object']);

      await reader.read();

      expect(reader.context.issues, unorderedMatches(context.issues));
    });

    test('Invalid Extensions', () async {
      final reader = new GltfJsonReader(
          new File('test/base/data/gltf/invalid_extensions_arrays.gltf')
              .openRead());

      final context = new Context()
        ..addIssue(SchemaError.arrayDuplicateElements, name: 'extensionsUsed/1')
        ..addIssue(SchemaError.arrayDuplicateElements,
            name: 'extensionsRequired/1')
        ..addIssue(SemanticError.unreservedExtensionPrefix,
            name: 'extensionsUsed/0', args: [''])
        ..addIssue(LinkError.unsupportedExtension,
            name: 'extensionsUsed/0', args: ['_test_extension'])
        ..addIssue(SemanticError.unreservedExtensionPrefix,
            name: 'extensionsUsed/1', args: [''])
        ..addIssue(LinkError.unsupportedExtension,
            name: 'extensionsUsed/1', args: ['_test_extension'])
        ..addIssue(SemanticError.unusedExtensionRequired,
            name: 'extensionsRequired/0', args: ['_test_extension2'])
        ..addIssue(SemanticError.unusedExtensionRequired,
            name: 'extensionsRequired/1', args: ['_test_extension2']);

      await reader.read();

      expect(reader.context.issues, unorderedMatches(context.issues));
    });

    test('Invalid Extensions Deps', () async {
      final reader = new GltfJsonReader(
          new File('test/base/data/gltf/undefined_used_extensions.gltf')
              .openRead());

      final context = new Context()
        ..addIssue(SchemaError.unsatisfiedDependency,
            name: 'extensionsRequired', args: ['extensionsUsed'])
        ..addIssue(SemanticError.unusedExtensionRequired,
            name: 'extensionsRequired/0', args: ['_test_extension2']);

      await reader.read();

      expect(reader.context.issues, unorderedMatches(context.issues));
    });

    test('Valid Full', () async {
      final reader = new GltfJsonReader(
          new File('test/base/data/gltf/valid_full.gltf').openRead());

      final result = await reader.read();

      expect(reader.context.issues, isEmpty);

      expect(result.gltf.toString(),
          '{asset: {version: 2.0, extensions: {}}, accessors: [], animations: [], buffers: [], bufferViews: [], cameras: [], images: [], materials: [], meshes: [], nodes: [], samplers: [], scenes: [], scene: -1, skins: [], textures: [], extensionsRequired: [], extensionsUsed: [], extensions: {}}');
    });
  });
}
