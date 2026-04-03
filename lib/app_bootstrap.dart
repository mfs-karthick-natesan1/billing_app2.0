/// Global callback set by main() so that auth screens can trigger a full
/// provider + widget-tree reload after sign-in or sign-out.
class AppBootstrap {
  static Future<void> Function()? restart;
}
