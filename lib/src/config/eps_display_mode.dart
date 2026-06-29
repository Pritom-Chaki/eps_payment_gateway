/// How the EPS payment page is presented to the user.
enum EpsDisplayMode {
  /// Pushes a full-screen payment page onto the navigator stack.
  fullScreen,

  /// Shows the payment page as a draggable modal bottom sheet.
  modalBottomSheet,
}
