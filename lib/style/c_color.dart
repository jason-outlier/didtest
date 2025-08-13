import 'package:flutter/material.dart';

enum CColor {
  brand1(Color(0xff3366CC)),
  brand2(Color(0xff24478F)),
  brand3(Color(0xff223355)),
  brand4(Color(0xff66CCFF)),
  brand5(Color(0xffCCDDFF)),
  bk1(Color(0xff333333)),
  bk2(Color(0xff666666)),
  bk3(Color(0xff999999)),
  bk4(Color(0xffCCCCCC)),
  bk5(Color(0xffBBBBBB)),
  bk6(Color(0xffECECEC)),
  bk7(Color(0xffE6E6E6)),
  bk8(Color(0xffF6F6F6)),
  systemRed(Color(0xffDD1133)),
  systemOrange(Color(0xffFFAA00)),
  systemGreen(Color(0xff00AA55)),
  systemBlue(Color(0xff0099FF)),
  systemPurple(Color(0xff6633FF)),
  systemPink(Color(0xffFF3399)),
  systemBackground(Color(0xffF4F8FB)),
  rev1(Color(0xffF6F6F6)),
  rev2(Color(0x99FFFFFF)),
  rev3(Color(0x66FFFFFF)),
  rev4(Color(0x33FFFFFF)),
  dim1(Color(0x66000000)),
  dim2(Color(0x33000000)),
  dim3(Color(0x1A000000)),
  dim4(Color(0x0D000000));

  // Constructor for the enum
  const CColor(this._color);

  // Internal color property
  final Color _color;

  // Custom getter to access the color directly
  Color get color => _color;

  // Static map for accessing styles by name
  static final Map<String, Color> styles = {for (var style in CColor.values) style.name: style.color};
}
