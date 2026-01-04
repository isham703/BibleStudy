#!/bin/bash

# Design Token Migration Script
# Automatically replaces hardcoded values with design system tokens

PROJECT_DIR="/Users/idon/Documents/BibleStudy/BibleStudy"

echo "🎨 Design Token Migration Script"
echo "================================="

# Function to perform replacements on Swift files
fix_files() {
    find "$PROJECT_DIR" -name "*.swift" -type f | while read -r file; do
        # Skip Theme files (they define the tokens)
        if [[ "$file" == *"/Theme/"* ]]; then
            continue
        fi

        # Create temp file for modifications
        tmp_file=$(mktemp)
        cp "$file" "$tmp_file"

        # =====================
        # OPACITY REPLACEMENTS
        # =====================
        sed -i '' 's/\.opacity(0\.08)/\.opacity(AppTheme.Opacity.faint)/g' "$tmp_file"
        sed -i '' 's/\.opacity(0\.1)/\.opacity(AppTheme.Opacity.subtle)/g' "$tmp_file"
        sed -i '' 's/\.opacity(0\.15)/\.opacity(AppTheme.Opacity.light)/g' "$tmp_file"
        sed -i '' 's/\.opacity(0\.2)/\.opacity(AppTheme.Opacity.lightMedium)/g' "$tmp_file"
        sed -i '' 's/\.opacity(0\.25)/\.opacity(AppTheme.Opacity.quarter)/g' "$tmp_file"
        sed -i '' 's/\.opacity(0\.3)/\.opacity(AppTheme.Opacity.medium)/g' "$tmp_file"
        sed -i '' 's/\.opacity(0\.4)/\.opacity(AppTheme.Opacity.disabled)/g' "$tmp_file"
        sed -i '' 's/\.opacity(0\.5)/\.opacity(AppTheme.Opacity.heavy)/g' "$tmp_file"
        sed -i '' 's/\.opacity(0\.6)/\.opacity(AppTheme.Opacity.strong)/g' "$tmp_file"
        sed -i '' 's/\.opacity(0\.7)/\.opacity(AppTheme.Opacity.overlay)/g' "$tmp_file"
        sed -i '' 's/\.opacity(0\.8)/\.opacity(AppTheme.Opacity.pressed)/g' "$tmp_file"
        sed -i '' 's/\.opacity(0\.9)/\.opacity(AppTheme.Opacity.high)/g' "$tmp_file"
        sed -i '' 's/\.opacity(0\.95)/\.opacity(AppTheme.Opacity.nearOpaque)/g' "$tmp_file"

        # =====================
        # ANIMATION REPLACEMENTS
        # =====================
        # withAnimation patterns
        sed -i '' 's/withAnimation(\.easeInOut(duration: 0\.15))/withAnimation(AppTheme.Animation.quick)/g' "$tmp_file"
        sed -i '' 's/withAnimation(\.easeInOut(duration: 0\.2))/withAnimation(AppTheme.Animation.standard)/g' "$tmp_file"
        sed -i '' 's/withAnimation(\.easeInOut(duration: 0\.25))/withAnimation(AppTheme.Animation.standard)/g' "$tmp_file"
        sed -i '' 's/withAnimation(\.easeInOut(duration: 0\.3))/withAnimation(AppTheme.Animation.standard)/g' "$tmp_file"
        sed -i '' 's/withAnimation(\.easeInOut(duration: 0\.4))/withAnimation(AppTheme.Animation.slow)/g' "$tmp_file"
        sed -i '' 's/withAnimation(\.easeInOut(duration: 0\.5))/withAnimation(AppTheme.Animation.slow)/g' "$tmp_file"

        sed -i '' 's/withAnimation(\.easeOut(duration: 0\.15))/withAnimation(AppTheme.Animation.quick)/g' "$tmp_file"
        sed -i '' 's/withAnimation(\.easeOut(duration: 0\.2))/withAnimation(AppTheme.Animation.standard)/g' "$tmp_file"
        sed -i '' 's/withAnimation(\.easeOut(duration: 0\.25))/withAnimation(AppTheme.Animation.standard)/g' "$tmp_file"
        sed -i '' 's/withAnimation(\.easeOut(duration: 0\.3))/withAnimation(AppTheme.Animation.standard)/g' "$tmp_file"
        sed -i '' 's/withAnimation(\.easeOut(duration: 0\.4))/withAnimation(AppTheme.Animation.slow)/g' "$tmp_file"
        sed -i '' 's/withAnimation(\.easeOut(duration: 0\.5))/withAnimation(AppTheme.Animation.slow)/g' "$tmp_file"

        sed -i '' 's/withAnimation(\.easeIn(duration: 0\.15))/withAnimation(AppTheme.Animation.quick)/g' "$tmp_file"
        sed -i '' 's/withAnimation(\.easeIn(duration: 0\.2))/withAnimation(AppTheme.Animation.standard)/g' "$tmp_file"
        sed -i '' 's/withAnimation(\.easeIn(duration: 0\.25))/withAnimation(AppTheme.Animation.standard)/g' "$tmp_file"
        sed -i '' 's/withAnimation(\.easeIn(duration: 0\.3))/withAnimation(AppTheme.Animation.standard)/g' "$tmp_file"

        # Spring animations
        sed -i '' 's/withAnimation(\.spring(response: 0\.3, dampingFraction: 0\.7))/withAnimation(AppTheme.Animation.spring)/g' "$tmp_file"
        sed -i '' 's/withAnimation(\.spring(response: 0\.35, dampingFraction: 0\.75))/withAnimation(AppTheme.Animation.spring)/g' "$tmp_file"
        sed -i '' 's/withAnimation(\.spring(response: 0\.35, dampingFraction: 0\.7))/withAnimation(AppTheme.Animation.spring)/g' "$tmp_file"
        sed -i '' 's/withAnimation(\.spring(response: 0\.4, dampingFraction: 0\.8))/withAnimation(AppTheme.Animation.spring)/g' "$tmp_file"

        # .animation() modifier patterns
        sed -i '' 's/\.animation(\.easeInOut(duration: 0\.15)/\.animation(AppTheme.Animation.quick/g' "$tmp_file"
        sed -i '' 's/\.animation(\.easeInOut(duration: 0\.2)/\.animation(AppTheme.Animation.standard/g' "$tmp_file"
        sed -i '' 's/\.animation(\.easeInOut(duration: 0\.25)/\.animation(AppTheme.Animation.standard/g' "$tmp_file"
        sed -i '' 's/\.animation(\.easeInOut(duration: 0\.3)/\.animation(AppTheme.Animation.standard/g' "$tmp_file"
        sed -i '' 's/\.animation(\.easeInOut(duration: 0\.4)/\.animation(AppTheme.Animation.slow/g' "$tmp_file"

        sed -i '' 's/\.animation(\.easeOut(duration: 0\.15)/\.animation(AppTheme.Animation.quick/g' "$tmp_file"
        sed -i '' 's/\.animation(\.easeOut(duration: 0\.2)/\.animation(AppTheme.Animation.standard/g' "$tmp_file"
        sed -i '' 's/\.animation(\.easeOut(duration: 0\.25)/\.animation(AppTheme.Animation.standard/g' "$tmp_file"
        sed -i '' 's/\.animation(\.easeOut(duration: 0\.3)/\.animation(AppTheme.Animation.standard/g' "$tmp_file"
        sed -i '' 's/\.animation(\.easeOut(duration: 0\.4)/\.animation(AppTheme.Animation.slow/g' "$tmp_file"

        # =====================
        # SPACING REPLACEMENTS (VStack, HStack, etc.)
        # =====================
        sed -i '' 's/VStack(spacing: 2)/VStack(spacing: AppTheme.Spacing.xxs)/g' "$tmp_file"
        sed -i '' 's/VStack(spacing: 4)/VStack(spacing: AppTheme.Spacing.xs)/g' "$tmp_file"
        sed -i '' 's/VStack(spacing: 8)/VStack(spacing: AppTheme.Spacing.sm)/g' "$tmp_file"
        sed -i '' 's/VStack(spacing: 12)/VStack(spacing: AppTheme.Spacing.md)/g' "$tmp_file"
        sed -i '' 's/VStack(spacing: 16)/VStack(spacing: AppTheme.Spacing.lg)/g' "$tmp_file"
        sed -i '' 's/VStack(spacing: 24)/VStack(spacing: AppTheme.Spacing.xl)/g' "$tmp_file"
        sed -i '' 's/VStack(spacing: 32)/VStack(spacing: AppTheme.Spacing.xxl)/g' "$tmp_file"
        sed -i '' 's/VStack(spacing: 48)/VStack(spacing: AppTheme.Spacing.xxxl)/g' "$tmp_file"

        sed -i '' 's/HStack(spacing: 2)/HStack(spacing: AppTheme.Spacing.xxs)/g' "$tmp_file"
        sed -i '' 's/HStack(spacing: 4)/HStack(spacing: AppTheme.Spacing.xs)/g' "$tmp_file"
        sed -i '' 's/HStack(spacing: 8)/HStack(spacing: AppTheme.Spacing.sm)/g' "$tmp_file"
        sed -i '' 's/HStack(spacing: 12)/HStack(spacing: AppTheme.Spacing.md)/g' "$tmp_file"
        sed -i '' 's/HStack(spacing: 16)/HStack(spacing: AppTheme.Spacing.lg)/g' "$tmp_file"
        sed -i '' 's/HStack(spacing: 24)/HStack(spacing: AppTheme.Spacing.xl)/g' "$tmp_file"
        sed -i '' 's/HStack(spacing: 32)/HStack(spacing: AppTheme.Spacing.xxl)/g' "$tmp_file"

        sed -i '' 's/LazyVStack(spacing: 4)/LazyVStack(spacing: AppTheme.Spacing.xs)/g' "$tmp_file"
        sed -i '' 's/LazyVStack(spacing: 8)/LazyVStack(spacing: AppTheme.Spacing.sm)/g' "$tmp_file"
        sed -i '' 's/LazyVStack(spacing: 12)/LazyVStack(spacing: AppTheme.Spacing.md)/g' "$tmp_file"
        sed -i '' 's/LazyVStack(spacing: 16)/LazyVStack(spacing: AppTheme.Spacing.lg)/g' "$tmp_file"
        sed -i '' 's/LazyVStack(spacing: 24)/LazyVStack(spacing: AppTheme.Spacing.xl)/g' "$tmp_file"

        # =====================
        # PADDING REPLACEMENTS
        # =====================
        sed -i '' 's/\.padding(2)/\.padding(AppTheme.Spacing.xxs)/g' "$tmp_file"
        sed -i '' 's/\.padding(4)/\.padding(AppTheme.Spacing.xs)/g' "$tmp_file"
        sed -i '' 's/\.padding(8)/\.padding(AppTheme.Spacing.sm)/g' "$tmp_file"
        sed -i '' 's/\.padding(12)/\.padding(AppTheme.Spacing.md)/g' "$tmp_file"
        sed -i '' 's/\.padding(16)/\.padding(AppTheme.Spacing.lg)/g' "$tmp_file"
        sed -i '' 's/\.padding(24)/\.padding(AppTheme.Spacing.xl)/g' "$tmp_file"
        sed -i '' 's/\.padding(32)/\.padding(AppTheme.Spacing.xxl)/g' "$tmp_file"
        sed -i '' 's/\.padding(48)/\.padding(AppTheme.Spacing.xxxl)/g' "$tmp_file"

        # =====================
        # CORNER RADIUS REPLACEMENTS
        # =====================
        sed -i '' 's/cornerRadius: 2)/cornerRadius: AppTheme.CornerRadius.xs)/g' "$tmp_file"
        sed -i '' 's/cornerRadius: 4)/cornerRadius: AppTheme.CornerRadius.small)/g' "$tmp_file"
        sed -i '' 's/cornerRadius: 8)/cornerRadius: AppTheme.CornerRadius.medium)/g' "$tmp_file"
        sed -i '' 's/cornerRadius: 12)/cornerRadius: AppTheme.CornerRadius.large)/g' "$tmp_file"
        sed -i '' 's/cornerRadius: 14)/cornerRadius: AppTheme.CornerRadius.menu)/g' "$tmp_file"
        sed -i '' 's/cornerRadius: 16)/cornerRadius: AppTheme.CornerRadius.xl)/g' "$tmp_file"
        sed -i '' 's/cornerRadius: 20)/cornerRadius: AppTheme.CornerRadius.sheet)/g' "$tmp_file"

        # =====================
        # BLUR RADIUS REPLACEMENTS
        # =====================
        sed -i '' 's/\.blur(radius: 4)/\.blur(radius: AppTheme.Blur.small)/g' "$tmp_file"
        sed -i '' 's/\.blur(radius: 8)/\.blur(radius: AppTheme.Blur.medium)/g' "$tmp_file"
        sed -i '' 's/\.blur(radius: 12)/\.blur(radius: AppTheme.Blur.large)/g' "$tmp_file"
        sed -i '' 's/\.blur(radius: 16)/\.blur(radius: AppTheme.Blur.xl)/g' "$tmp_file"
        sed -i '' 's/\.blur(radius: 20)/\.blur(radius: AppTheme.Blur.xl)/g' "$tmp_file"
        sed -i '' 's/\.blur(radius: 24)/\.blur(radius: AppTheme.Blur.xxl)/g' "$tmp_file"
        sed -i '' 's/\.blur(radius: 30)/\.blur(radius: AppTheme.Blur.xxxl)/g' "$tmp_file"

        # =====================
        # SCALE EFFECT REPLACEMENTS
        # =====================
        sed -i '' 's/\.scaleEffect(0\.9)/\.scaleEffect(AppTheme.Scale.subtle)/g' "$tmp_file"
        sed -i '' 's/\.scaleEffect(0\.95)/\.scaleEffect(AppTheme.Scale.pressed)/g' "$tmp_file"
        sed -i '' 's/\.scaleEffect(0\.96)/\.scaleEffect(AppTheme.Scale.pressed)/g' "$tmp_file"
        sed -i '' 's/\.scaleEffect(0\.98)/\.scaleEffect(AppTheme.Scale.hover)/g' "$tmp_file"

        # =====================
        # BORDER/LINE WIDTH REPLACEMENTS
        # =====================
        sed -i '' 's/lineWidth: 0\.5)/lineWidth: AppTheme.Border.hairline)/g' "$tmp_file"
        sed -i '' 's/lineWidth: 1)/lineWidth: AppTheme.Border.thin)/g' "$tmp_file"
        sed -i '' 's/lineWidth: 1\.5)/lineWidth: AppTheme.Border.regular)/g' "$tmp_file"
        sed -i '' 's/lineWidth: 2)/lineWidth: AppTheme.Border.regular)/g' "$tmp_file"
        sed -i '' 's/lineWidth: 3)/lineWidth: AppTheme.Border.thick)/g' "$tmp_file"

        # Check if file was modified
        if ! cmp -s "$file" "$tmp_file"; then
            cp "$tmp_file" "$file"
            echo "✅ Updated: ${file#$PROJECT_DIR/}"
        fi

        rm "$tmp_file"
    done
}

echo ""
echo "🔄 Processing Swift files..."
echo ""

fix_files

echo ""
echo "✨ Migration complete!"
echo ""
echo "Next steps:"
echo "  1. Run: /opt/homebrew/bin/swiftlint lint --config .swiftlint.yml 2>/dev/null | grep -c warning"
echo "  2. Build the project to check for errors"
echo "  3. Manually review any remaining violations"
