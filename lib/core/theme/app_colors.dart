import 'package:flutter/material.dart';

abstract final class AppColors {
  // Cosy Cove reference palette.
  //
  // These are representative UI colors sampled from the supplied artwork.
  // They intentionally omit tiny anti-aliasing and gradient variations so
  // screens can share a compact, predictable design system.
  static const inkDark = Color(0xFF49352A);
  static const inkBrown = Color(0xFF634838);
  static const outlineBrown = Color(0xFF89684F);
  static const woodDeep = Color(0xFF704832);
  static const wood = Color(0xFF96684B);
  static const woodLight = Color(0xFFC5966A);

  static const ivory = Color(0xFFFFF9E5);
  static const creamLight = Color(0xFFFFF4D4);
  static const cream = Color(0xFFF6EAC3);
  static const creamDeep = Color(0xFFE8D7A8);
  static const parchment = Color(0xFFF0DFB4);
  static const panel = Color(0xFFFFF1CC);
  static const panelMuted = Color(0xFFE3D1AA);
  static const authCard = Color(0xFFFFFBF1);

  // Olive greens sampled by UI role from the reference:
  // dark outlines, controls, header fill, progress fill and soft highlight.
  static const oliveDeep = Color(0xFF596232);
  static const olive = Color(0xFF747F43);
  static const leafShadow = Color(0xFF68733A);
  static const leaf = Color(0xFFA8B968);
  static const leafBright = Color(0xFFB7C47C);
  static const leafLight = Color(0xFFD3DCA0);
  static const sage = Color(0xFFC0C993);
  static const success = Color(0xFF8FA64F);

  static const coin = Color(0xFFD8A536);
  static const gold = Color(0xFFE8B943);
  static const goldLight = Color(0xFFF4D269);
  static const amber = Color(0xFFE89A3D);

  static const sky = Color(0xFF73BCCB);
  static const aqua = Color(0xFF91CED2);
  static const blossom = Color(0xFFF3B2AE);
  static const pink = Color(0xFFEA969D);
  static const coral = Color(0xFFD97968);
  static const danger = Color(0xFFC85B55);
  static const lavender = Color(0xFF8D85B5);

  // Button variants from the reference UI.
  static const buttonGreen = leaf;
  static const buttonYellow = Color(0xFFF0C25F);
  static const buttonBlue = Color(0xFF79BDCA);
  static const buttonSecondary = Color(0xFFF3E7C9);
  static const buttonText = Color(0xFFFFFCF1);
  static const buttonBorder = woodDeep;

  // Light mode — direct semantic mapping to the reference palette.
  static const lightBackground = cream;
  static const lightForeground = inkDark;
  static const lightCard = authCard;
  static const lightPrimary = leaf;
  static const lightPrimaryForeground = oliveDeep;
  static const lightAccent = goldLight;
  static const lightMuted = creamDeep;
  static const lightMutedForeground = outlineBrown;
  static const lightBorder = wood;
  static const lightLuminaGlow = leafLight;
  static const lightLife = amber;
  static const lightBond = success;
  static const lightDew = sky;
  static const lightNavigation = authCard;
  static const lightNavigationActive = ivory;
  static const lightNavigationIcon = woodDeep;
  static const lightIconButtonBackground = authCard;

  // Dark mode — muted version of the same garden palette
  static const darkBackground = Color(0xFF0B081A);
  static const darkForeground = Color(0xFFFFF5FA);
  static const darkTextOutline = Color(0xFF342B50);
  static const darkCard = Color(0xFF665B8F);
  // Raised surface for child cards inside dark panels.
  static const darkNestedCard = Color(0xFF8279A8);
  // Dark interactive/tab surface: purple-lavender, matching the profile cards.
  static const darkPrimary = Color(0xFF7A6EA3);
  static const darkPrimaryForeground = Color(0xFFFFF5FA);
  static const darkAccent = Color(0xFFEF5DA8);
  static const darkMuted = Color(0xFF777B9D);
  static const darkMutedForeground = Color(0xFFA5B4FC);
  // Dark-theme outlines use the soft ivory/lavender edge from the reference
  // instead of the warm gold used by the light theme.
  // Pastel-gold highlight used for primary dark-theme card/button outlines.
  static const darkBorder = Color(0xFFF3D98B);
  // Warm wood outline for cards nested inside a larger panel.
  static const darkCardBorder = woodDeep;
  // Subtle frame for icon containers nested inside cards.
  // Icon tiles should recede into the dark card instead of competing with
  // the bright outer card border.
  static const darkIconBorder = Color(0xFF4B476A);
  static const darkLuminaGlow = leafBright;
  static const darkLife = Color(0xFFFBBF24);
  static const darkBond = Color(0xFFEF5DA8);
  static const darkDew = Color(0xFF38BDF8);
  static const darkNavigation = Color(0xFF665B8F);
  static const darkNavigationActive = Color(0xFF7A6EA3);
  static const darkNavigationIcon = Color(0xFFFFF5FA);
  static const darkIconButtonBackground = Color(0xFF312858);
}
