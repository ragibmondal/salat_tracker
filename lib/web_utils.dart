// Stub implementations for non-web platforms
class Blob {
  Blob(List<dynamic> content);
}

class Url {
  static String createObjectUrlFromBlob(Blob blob) => '';
  static void revokeObjectUrl(String url) {}
}

class AnchorElement {
  AnchorElement({String? href});
  
  void setAttribute(String name, String value) {}
  void click() {}
}

class html {
  static Blob Blob(List<dynamic> content) => Blob(content);
  static Url Url = Url();
  static AnchorElement AnchorElement({String? href}) => AnchorElement(href: href);
} 