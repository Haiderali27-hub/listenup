import 'package:flutter/material.dart';

class HexColor extends Color {
  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));

  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }
    return int.parse(hexColor, radix: 16);
  }
}

class GlobalColors {
  static HexColor primaryColor = HexColor('#3F6CDF');
  static HexColor secondaryColor = HexColor('#2A2F37');
  static HexColor black = HexColor('#1E232C');
  static HexColor black2 = HexColor('#000000');
  static HexColor black3 = HexColor('#2D2D2D');
  static HexColor black4 = HexColor('#595959');
  static HexColor black5 = HexColor('#767676');
  static HexColor black6 = HexColor('#2e2c2c');
  static HexColor grey = HexColor('#909090');
  static HexColor grey2 = HexColor('#535763');
  static HexColor grey3 = HexColor('#606060');
  static HexColor darkGrey = HexColor('#424141');
  static HexColor darkGrey2 = HexColor('#6A707C');
  static HexColor darkGrey3 = HexColor('#757575');
  static HexColor lightGray = HexColor('#A8A8A8');
  static HexColor lightGray2 = HexColor('#D9D9D9');
  static HexColor lightGray3 = HexColor('#F5F5F5');
  static HexColor lightGray4 = HexColor('#C0BCBC');
  static HexColor borderColor = HexColor('#E8ECF4');
  static HexColor borderDark = HexColor('#CACACA');
  static HexColor greyText = HexColor('#8391A1');
  static HexColor red = HexColor('#F14336');
  static HexColor green = HexColor('#00BF58');
  static HexColor darkGreen = HexColor('#0F5627');
  static HexColor greenNeon = HexColor('#7CFFA8');
  static HexColor white = HexColor('#FFFFFF');
  static HexColor lightBlue = HexColor('#89A2B8');
  static HexColor lightBlue2 = HexColor('#7591D9');
  static HexColor lightBlue3 = HexColor('#BFD4E4');
  static HexColor bg = HexColor('#FAFAFA');
  static HexColor lightPurple = HexColor('#9997EF');
  static HexColor lightBlack = HexColor('#181A1F');
  static HexColor blue = HexColor('#156778');
}
