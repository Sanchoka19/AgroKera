/// Defines the target destination after the splash choreography finishes.
enum SplashDestination {
  /// User has an active authenticated session; navigates straight to main app.
  mainNav,

  /// User is unauthenticated / first time visitor; presents the welcome & auth screen.
  authWelcome,
}

