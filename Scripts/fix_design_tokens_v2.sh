#!/bin/bash

# Design Token Migration Script v2
# Handles more complex patterns

PROJECT_DIR="/Users/idon/Documents/BibleStudy/BibleStudy"

echo "🎨 Design Token Migration Script v2"
echo "===================================="

fix_files() {
    find "$PROJECT_DIR" -name "*.swift" -type f | while read -r file; do
        # Skip Theme files
        if [[ "$file" == *"/Theme/"* ]]; then
            continue
        fi

        tmp_file=$(mktemp)
        cp "$file" "$tmp_file"

        # =====================
        # MORE OPACITY PATTERNS (with spaces, decimals)
        # =====================
        sed -i '' 's/\.opacity(0\.05)/\.opacity(AppTheme.Opacity.faint)/g' "$tmp_file"
        sed -i '' 's/opacity: 0\.1)/opacity: AppTheme.Opacity.subtle)/g' "$tmp_file"
        sed -i '' 's/opacity: 0\.15)/opacity: AppTheme.Opacity.light)/g' "$tmp_file"
        sed -i '' 's/opacity: 0\.2)/opacity: AppTheme.Opacity.lightMedium)/g' "$tmp_file"
        sed -i '' 's/opacity: 0\.3)/opacity: AppTheme.Opacity.medium)/g' "$tmp_file"
        sed -i '' 's/opacity: 0\.4)/opacity: AppTheme.Opacity.disabled)/g' "$tmp_file"
        sed -i '' 's/opacity: 0\.5)/opacity: AppTheme.Opacity.heavy)/g' "$tmp_file"
        sed -i '' 's/opacity: 0\.6)/opacity: AppTheme.Opacity.strong)/g' "$tmp_file"

        # =====================
        # ROUNDED RECTANGLE WITH STYLE
        # =====================
        sed -i '' 's/RoundedRectangle(cornerRadius: 4, style:/RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style:/g' "$tmp_file"
        sed -i '' 's/RoundedRectangle(cornerRadius: 8, style:/RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style:/g' "$tmp_file"
        sed -i '' 's/RoundedRectangle(cornerRadius: 12, style:/RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style:/g' "$tmp_file"
        sed -i '' 's/RoundedRectangle(cornerRadius: 14, style:/RoundedRectangle(cornerRadius: AppTheme.CornerRadius.menu, style:/g' "$tmp_file"
        sed -i '' 's/RoundedRectangle(cornerRadius: 16, style:/RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl, style:/g' "$tmp_file"
        sed -i '' 's/RoundedRectangle(cornerRadius: 20, style:/RoundedRectangle(cornerRadius: AppTheme.CornerRadius.sheet, style:/g' "$tmp_file"

        # =====================
        # LINE WIDTH DECIMALS
        # =====================
        sed -i '' 's/lineWidth: 0\.33)/lineWidth: AppTheme.Border.hairline)/g' "$tmp_file"
        sed -i '' 's/lineWidth: 1\.0)/lineWidth: AppTheme.Border.thin)/g' "$tmp_file"
        sed -i '' 's/lineWidth: 2\.0)/lineWidth: AppTheme.Border.regular)/g' "$tmp_file"

        # =====================
        # FRAME HEIGHTS FOR DIVIDERS
        # =====================
        sed -i '' 's/\.frame(height: 0\.5)/\.frame(height: AppTheme.Divider.hairline)/g' "$tmp_file"
        sed -i '' 's/\.frame(height: 1)/\.frame(height: AppTheme.Divider.thin)/g' "$tmp_file"
        sed -i '' 's/\.frame(height: 2)/\.frame(height: AppTheme.Divider.medium)/g' "$tmp_file"

        # =====================
        # ANIMATION VARIATIONS
        # =====================
        sed -i '' 's/\.easeInOut(duration: 0\.15)/AppTheme.Animation.quick/g' "$tmp_file"
        sed -i '' 's/\.easeInOut(duration: 0\.2)/AppTheme.Animation.standard/g' "$tmp_file"
        sed -i '' 's/\.easeInOut(duration: 0\.25)/AppTheme.Animation.standard/g' "$tmp_file"
        sed -i '' 's/\.easeInOut(duration: 0\.3)/AppTheme.Animation.standard/g' "$tmp_file"
        sed -i '' 's/\.easeInOut(duration: 0\.35)/AppTheme.Animation.slow/g' "$tmp_file"
        sed -i '' 's/\.easeInOut(duration: 0\.4)/AppTheme.Animation.slow/g' "$tmp_file"
        sed -i '' 's/\.easeInOut(duration: 0\.5)/AppTheme.Animation.slow/g' "$tmp_file"
        sed -i '' 's/\.easeInOut(duration: 1)/AppTheme.Animation.contemplative/g' "$tmp_file"
        sed -i '' 's/\.easeInOut(duration: 1\.0)/AppTheme.Animation.contemplative/g' "$tmp_file"
        sed -i '' 's/\.easeInOut(duration: 1\.5)/AppTheme.Animation.contemplative/g' "$tmp_file"
        sed -i '' 's/\.easeInOut(duration: 2)/AppTheme.Animation.reverent/g' "$tmp_file"
        sed -i '' 's/\.easeInOut(duration: 2\.0)/AppTheme.Animation.reverent/g' "$tmp_file"

        sed -i '' 's/\.easeOut(duration: 0\.15)/AppTheme.Animation.quick/g' "$tmp_file"
        sed -i '' 's/\.easeOut(duration: 0\.2)/AppTheme.Animation.standard/g' "$tmp_file"
        sed -i '' 's/\.easeOut(duration: 0\.25)/AppTheme.Animation.standard/g' "$tmp_file"
        sed -i '' 's/\.easeOut(duration: 0\.3)/AppTheme.Animation.standard/g' "$tmp_file"
        sed -i '' 's/\.easeOut(duration: 0\.4)/AppTheme.Animation.slow/g' "$tmp_file"
        sed -i '' 's/\.easeOut(duration: 0\.5)/AppTheme.Animation.slow/g' "$tmp_file"

        sed -i '' 's/\.easeIn(duration: 0\.15)/AppTheme.Animation.quick/g' "$tmp_file"
        sed -i '' 's/\.easeIn(duration: 0\.2)/AppTheme.Animation.standard/g' "$tmp_file"
        sed -i '' 's/\.easeIn(duration: 0\.25)/AppTheme.Animation.standard/g' "$tmp_file"
        sed -i '' 's/\.easeIn(duration: 0\.3)/AppTheme.Animation.standard/g' "$tmp_file"

        sed -i '' 's/\.spring(response: 0\.3)/AppTheme.Animation.spring/g' "$tmp_file"
        sed -i '' 's/\.spring(response: 0\.35)/AppTheme.Animation.spring/g' "$tmp_file"
        sed -i '' 's/\.spring(response: 0\.4)/AppTheme.Animation.spring/g' "$tmp_file"

        # =====================
        # MORE SPACING PATTERNS
        # =====================
        sed -i '' 's/VStack(alignment: \.leading, spacing: 4)/VStack(alignment: .leading, spacing: AppTheme.Spacing.xs)/g' "$tmp_file"
        sed -i '' 's/VStack(alignment: \.leading, spacing: 8)/VStack(alignment: .leading, spacing: AppTheme.Spacing.sm)/g' "$tmp_file"
        sed -i '' 's/VStack(alignment: \.leading, spacing: 12)/VStack(alignment: .leading, spacing: AppTheme.Spacing.md)/g' "$tmp_file"
        sed -i '' 's/VStack(alignment: \.leading, spacing: 16)/VStack(alignment: .leading, spacing: AppTheme.Spacing.lg)/g' "$tmp_file"
        sed -i '' 's/VStack(alignment: \.leading, spacing: 24)/VStack(alignment: .leading, spacing: AppTheme.Spacing.xl)/g' "$tmp_file"

        sed -i '' 's/VStack(alignment: \.center, spacing: 8)/VStack(alignment: .center, spacing: AppTheme.Spacing.sm)/g' "$tmp_file"
        sed -i '' 's/VStack(alignment: \.center, spacing: 12)/VStack(alignment: .center, spacing: AppTheme.Spacing.md)/g' "$tmp_file"
        sed -i '' 's/VStack(alignment: \.center, spacing: 16)/VStack(alignment: .center, spacing: AppTheme.Spacing.lg)/g' "$tmp_file"

        # =====================
        # INDICATOR SIZES
        # =====================
        sed -i '' 's/\.frame(width: 6, height: 6)/\.frame(width: AppTheme.ComponentSize.dot, height: AppTheme.ComponentSize.dot)/g' "$tmp_file"
        sed -i '' 's/\.frame(width: 8, height: 8)/\.frame(width: AppTheme.ComponentSize.indicator, height: AppTheme.ComponentSize.indicator)/g' "$tmp_file"
        sed -i '' 's/\.frame(width: 10, height: 10)/\.frame(width: AppTheme.ComponentSize.indicator + 2, height: AppTheme.ComponentSize.indicator + 2)/g' "$tmp_file"

        # =====================
        # BOOK SPINE RGB COLORS (for IlluminatedBookEmptyState)
        # =====================
        sed -i '' 's/Color(red: 0\.5, green: 0\.3, blue: 0\.18)/IlluminatedPalette.BookSpine.leather/g' "$tmp_file"
        sed -i '' 's/Color(red: 0\.45, green: 0\.27, blue: 0\.16)/IlluminatedPalette.BookSpine.leatherMedium/g' "$tmp_file"
        sed -i '' 's/Color(red: 0\.4, green: 0\.25, blue: 0\.15)/IlluminatedPalette.BookSpine.leatherDark/g' "$tmp_file"
        sed -i '' 's/Color(red: 0\.3, green: 0\.2, blue: 0\.12)/IlluminatedPalette.BookSpine.leatherShadow/g' "$tmp_file"
        sed -i '' 's/Color(red: 0\.25, green: 0\.15, blue: 0\.1)/IlluminatedPalette.BookSpine.leatherDeep/g' "$tmp_file"

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
echo "✨ Migration v2 complete!"
