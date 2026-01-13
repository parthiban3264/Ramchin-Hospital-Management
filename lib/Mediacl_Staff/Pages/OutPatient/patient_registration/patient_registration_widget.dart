void onPhoneChanged(String value, void Function(bool) setValidity) {
  String digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (digitsOnly.startsWith('91')) digitsOnly = digitsOnly.substring(2);
  setValidity(digitsOnly.length == 10);
}
