import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:moon_guard_flutter/theme/app_colors.dart";

void main() {
  test("app colors load", () {
    expect(const Color(0xFFA41E22), AppColors.primary);
  });
}
