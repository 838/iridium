// Copyright (c) 2021 Mantano. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:core';

import 'package:dfunc/dfunc.dart';
import 'package:mno_shared/fetcher.dart';
import 'package:mno_shared/mediatype.dart';
import 'package:mno_shared/publication.dart';
import 'package:mno_streamer/src/container/container.dart';
import 'package:mno_streamer/src/container/publication_container.dart';
import 'package:mno_streamer/src/image/image_parser.dart';
import 'package:universal_io/io.dart';

import '../../publication_parser.dart';

class CbzParserException implements Exception {
  /// Invalid EPUB package.
  factory CbzParserException.invalidCbz(String message) =>
      CbzParserException("Invalid CBZ: $message");

  const CbzParserException(this.message) : assert(message != null);

  final String message;
}

///      CBZParser : Handle any CBZ file. Opening, listing files
///                  get name of the resource, creating the Publication
///                  for rendering
class CBZParser extends PublicationParser {
  final ImageParser imageParser = ImageParser();

  @override
  Future<PubBox> parseWithFallbackTitle(
      String fileAtPath, String fallbackTitle) async {
    File file = File(fileAtPath);

    Fetcher fetcher = await Fetcher.fromArchiveOrDirectory(fileAtPath);
    if (fetcher == null) {
      throw ContainerError.missingFile(fileAtPath);
    }

    Publication publication =
        (await imageParser.parseFile(FileAsset(file), fetcher))
            ?.let((builder) {
              LocalizedString title = LocalizedString.fromString(fallbackTitle);
              Metadata metadata =
                  builder.manifest.metadata.copy(localizedTitle: title);
              Manifest manifest = builder.manifest.copy(metadata: metadata);
              return PublicationBuilder(
                  manifest: manifest,
                  fetcher: builder.fetcher,
                  servicesBuilder: builder.servicesBuilder);
            })
            ?.build()
            ?.also((pub) {
              pub.type = TYPE.cbz;
            });
    if (publication == null) {
      return null;
    }

    PublicationContainer container = PublicationContainer(
        publication: publication,
        path: file.canonicalPath,
        mediaType: MediaType.cbz);

    return PubBox(publication, container);
  }
}
