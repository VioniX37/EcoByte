import 'dart:io';

String getMimeType(File imageFile) {
  final String path = imageFile.path.toLowerCase();
  if (path.endsWith('.jpg') || path.endsWith('.jpeg')) {
    return 'image/jpeg';
  } else if (path.endsWith('.png')) {
    return 'image/png';
  } else if (path.endsWith('.gif')) {
    return 'image/gif';
  } else if (path.endsWith('.bmp')) {
    return 'image/bmp';
  } else if (path.endsWith('.webp')) {
    return 'image/webp';
  } else {
    return 'image/jpeg';
  }
}
