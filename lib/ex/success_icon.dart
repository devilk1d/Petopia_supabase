import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SuccessIcon extends StatelessWidget {
  final double size;

  const SuccessIcon({
    Key? key,
    required this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // SVG string for the success icon
    const String svgString = '''
<svg width="188" height="188" viewBox="0 0 188 188" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M172.333 90.0833V47.893C172.333 41.6968 172.333 38.6027 170.813 35.4067C169.705 33.2882 168.203 31.4006 166.388 29.845C163.615 27.6517 161.296 27.1268 156.666 26.0615C149.46 24.4165 141.517 23.5 133.166 23.5C118.15 23.5 104.434 26.461 93.9998 31.3333C83.5658 36.2057 69.8497 39.1667 54.8332 39.1667C46.4828 39.1667 38.5398 38.2502 31.3332 36.6052C23.8132 34.8818 15.6665 40.1772 15.6665 47.893V132.274C15.6665 138.47 15.6665 141.572 17.1862 144.76C18.0478 146.585 20.0297 149.068 21.612 150.322C24.385 152.515 26.7037 153.04 31.3332 154.105C38.5398 155.75 46.4828 156.667 54.8332 156.667C66.3403 156.667 77.0798 154.928 86.1665 151.928M109.667 148.833C109.667 148.833 117.5 148.833 125.333 164.5C125.333 164.5 150.22 125.333 172.333 117.5" stroke="#B60051" stroke-width="13.4375" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M43.083 97.9167V97.9872M144.916 82.1873V82.2657M113.583 90.0833C113.583 95.2772 111.52 100.258 107.847 103.931C104.175 107.603 99.1935 109.667 93.9997 109.667C88.8058 109.667 83.8248 107.603 80.1522 103.931C76.4796 100.258 74.4163 95.2772 74.4163 90.0833C74.4163 84.8895 76.4796 79.9084 80.1522 76.2358C83.8248 72.5632 88.8058 70.5 93.9997 70.5C99.1935 70.5 104.175 72.5632 107.847 76.2358C111.52 79.9084 113.583 84.8895 113.583 90.0833Z" stroke="#B60051" stroke-width="13.4375" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.string(
        svgString,
        width: size,
        height: size,
      ),
    );
  }
}