// Stub implementations for non-web platforms
class WebBlob {
  final List<dynamic> _content;
  WebBlob(this._content);
}

class WebUrl {
  static String createObjectUrlFromBlob(WebBlob blob) => '';
  static void revokeObjectUrl(String url) {}
}

class WebAnchorElement {
  String? href;
  WebAnchorElement({this.href});
  
  void setAttribute(String name, String value) {}
  void click() {}
}

class html {
  static WebBlob Blob(List<dynamic> content) => WebBlob(content);
  static final WebUrl Url = WebUrl();
  static WebAnchorElement AnchorElement({String? href}) => WebAnchorElement(href: href);
} 