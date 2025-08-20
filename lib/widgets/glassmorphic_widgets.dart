import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../theme/app_theme.dart';

class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double blur;
  final double opacity;
  final Color? borderColor;
  final double borderWidth;
  final VoidCallback? onTap;

  const GlassmorphicCard({
    Key? key,
    required this.child,
    this.width,
    this.height,
    this.margin,
    this.padding,
    this.borderRadius = AppTheme.mediumRadius,
    this.blur = 10.0,
    this.opacity = 0.1,
    this.borderColor,
    this.borderWidth = 1.0,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: GestureDetector(
        onTap: onTap,
        child: GlassmorphicContainer(
          width: width ?? double.infinity,
          height: height ?? double.infinity,
          borderRadius: borderRadius,
          blur: blur,
          alignment: Alignment.center,
          border: borderWidth,
          linearGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isDark 
                ? Colors.white.withOpacity(opacity)
                : Colors.white.withOpacity(opacity * 2),
              isDark 
                ? Colors.white.withOpacity(opacity * 0.5)
                : Colors.white.withOpacity(opacity),
            ],
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              borderColor?.withOpacity(0.5) ?? 
                (isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1)),
              borderColor?.withOpacity(0.2) ?? 
                (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
            ],
          ),
          child: Container(
            padding: padding ?? const EdgeInsets.all(AppTheme.mediumSpacing),
            child: child,
          ),
        ),
      ),
    );
  }
}

class GlassmorphicButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? textColor;
  final double fontSize;
  final FontWeight fontWeight;
  final bool isLoading;

  const GlassmorphicButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.icon,
    this.width,
    this.height,
    this.padding,
    this.borderRadius = AppTheme.mediumRadius,
    this.backgroundColor,
    this.textColor,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w600,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      width: width,
      height: height ?? 50,
      child: GestureDetector(
        onTap: isLoading ? null : onPressed,
        child: GlassmorphicContainer(
          width: width ?? double.infinity,
          height: height ?? 50,
          borderRadius: borderRadius,
          blur: 15,
          alignment: Alignment.center,
          border: 1.5,
          linearGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              backgroundColor ?? AppTheme.primaryRed.withOpacity(0.8),
              backgroundColor ?? AppTheme.darkRed.withOpacity(0.6),
            ],
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryRed.withOpacity(0.6),
              AppTheme.darkRed.withOpacity(0.3),
            ],
          ),
          child: Container(
            padding: padding ?? const EdgeInsets.symmetric(
              horizontal: AppTheme.mediumSpacing,
              vertical: AppTheme.smallSpacing,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryWhite),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ..[
                        Icon(
                          icon,
                          color: textColor ?? AppTheme.primaryWhite,
                          size: fontSize + 2,
                        ),
                        const SizedBox(width: AppTheme.smallSpacing),
                      ],
                      Text(
                        text,
                        style: TextStyle(
                          color: textColor ?? AppTheme.primaryWhite,
                          fontSize: fontSize,
                          fontWeight: fontWeight,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class GlassmorphicTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconTap;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final int? maxLines;
  final bool enabled;
  final double borderRadius;
  final EdgeInsetsGeometry? contentPadding;

  const GlassmorphicTextField({
    Key? key,
    this.controller,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.enabled = true,
    this.borderRadius = AppTheme.mediumRadius,
    this.contentPadding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return GlassmorphicContainer(
      width: double.infinity,
      height: maxLines == 1 ? 56 : null,
      borderRadius: borderRadius,
      blur: 10,
      alignment: Alignment.center,
      border: 1,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          isDark 
            ? Colors.white.withOpacity(0.05)
            : Colors.white.withOpacity(0.3),
          isDark 
            ? Colors.white.withOpacity(0.02)
            : Colors.white.withOpacity(0.1),
        ],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          isDark 
            ? Colors.white.withOpacity(0.2)
            : Colors.black.withOpacity(0.1),
          isDark 
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.05),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        onChanged: onChanged,
        onFieldSubmitted: onSubmitted,
        maxLines: maxLines,
        enabled: enabled,
        style: TextStyle(
          color: isDark ? AppTheme.primaryWhite : AppTheme.primaryBlack,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          prefixIcon: prefixIcon != null
              ? Icon(
                  prefixIcon,
                  color: isDark ? AppTheme.mediumGrey : AppTheme.greyBlack,
                )
              : null,
          suffixIcon: suffixIcon != null
              ? GestureDetector(
                  onTap: onSuffixIconTap,
                  child: Icon(
                    suffixIcon,
                    color: isDark ? AppTheme.mediumGrey : AppTheme.greyBlack,
                  ),
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: contentPadding ?? const EdgeInsets.symmetric(
            horizontal: AppTheme.mediumSpacing,
            vertical: AppTheme.mediumSpacing,
          ),
          labelStyle: TextStyle(
            color: isDark ? AppTheme.mediumGrey : AppTheme.greyBlack,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(
            color: isDark ? AppTheme.mediumGrey : AppTheme.greyBlack,
            fontWeight: FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class GlassmorphicAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final double elevation;
  final Color? backgroundColor;
  final double toolbarHeight;

  const GlassmorphicAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.elevation = 0,
    this.backgroundColor,
    this.toolbarHeight = kToolbarHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      height: toolbarHeight + MediaQuery.of(context).padding.top,
      child: GlassmorphicContainer(
        width: double.infinity,
        height: double.infinity,
        borderRadius: 0,
        blur: 20,
        alignment: Alignment.center,
        border: 0,
        linearGradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            backgroundColor ?? (isDark 
              ? AppTheme.lightBlack.withOpacity(0.9)
              : AppTheme.primaryWhite.withOpacity(0.9)),
            backgroundColor ?? (isDark 
              ? AppTheme.lightBlack.withOpacity(0.7)
              : AppTheme.primaryWhite.withOpacity(0.7)),
          ],
        ),
        borderGradient: const LinearGradient(
          colors: [Colors.transparent, Colors.transparent],
        ),
        child: AppBar(
          title: Text(
            title,
            style: TextStyle(
              color: isDark ? AppTheme.primaryWhite : AppTheme.primaryBlack,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          actions: actions,
          leading: leading,
          automaticallyImplyLeading: automaticallyImplyLeading,
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(
            color: isDark ? AppTheme.primaryWhite : AppTheme.primaryBlack,
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight);
}

class GlassmorphicBottomSheet extends StatelessWidget {
  final Widget child;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  const GlassmorphicBottomSheet({
    Key? key,
    required this.child,
    this.height,
    this.padding,
    this.borderRadius = AppTheme.largeRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      height: height,
      child: GlassmorphicContainer(
        width: double.infinity,
        height: height ?? double.infinity,
        borderRadius: borderRadius,
        blur: 20,
        alignment: Alignment.topCenter,
        border: 1,
        linearGradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            isDark 
              ? AppTheme.lightBlack.withOpacity(0.95)
              : AppTheme.primaryWhite.withOpacity(0.95),
            isDark 
              ? AppTheme.lightBlack.withOpacity(0.9)
              : AppTheme.primaryWhite.withOpacity(0.9),
          ],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark 
              ? Colors.white.withOpacity(0.2)
              : Colors.black.withOpacity(0.1),
            isDark 
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
          ],
        ),
        child: Container(
          padding: padding ?? const EdgeInsets.all(AppTheme.mediumSpacing),
          child: child,
        ),
      ),
    );
  }
}