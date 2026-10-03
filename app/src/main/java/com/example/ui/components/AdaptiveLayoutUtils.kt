package com.example.ui.components

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.widthIn
import androidx.compose.runtime.Composable
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * Responsive Window Size Classes matching Material 3 & Android commercial app standards:
 * - Compact (< 600 dp): Standard phones in portrait.
 * - Medium (600 dp .. 839 dp): Foldables unfolded, small tablets (7-8"), large phones in landscape.
 * - Expanded (>= 840 dp): 10-12" tablets (Pixel Tablet, Galaxy Tab, iPad), landscape tablets, desktop / DeX mode.
 */
enum class WindowWidthClass {
    Compact,
    Medium,
    Expanded
}

@Immutable
data class WindowAdaptiveInfo(
    val widthDp: Dp,
    val heightDp: Dp,
    val widthClass: WindowWidthClass
) {
    val isCompact: Boolean get() = widthClass == WindowWidthClass.Compact
    val isMedium: Boolean get() = widthClass == WindowWidthClass.Medium
    val isExpanded: Boolean get() = widthClass == WindowWidthClass.Expanded
    val isTablet: Boolean get() = widthClass != WindowWidthClass.Compact

    /**
     * Standard horizontal screen padding based on device form factor.
     */
    val horizontalPadding: Dp
        get() = when (widthClass) {
            WindowWidthClass.Compact -> 16.dp
            WindowWidthClass.Medium -> 24.dp
            WindowWidthClass.Expanded -> 36.dp
        }

    /**
     * Column count for dashboard metrics / KPI cards.
     * Phones: 2 columns (2x2 grid)
     * Tablets & Foldables: 4 columns across
     */
    val metricColumns: Int
        get() = when (widthClass) {
            WindowWidthClass.Compact -> 2
            WindowWidthClass.Medium -> 4
            WindowWidthClass.Expanded -> 4
        }

    /**
     * Column count for list views (Invoices, Clients, Expenses).
     * Phones: 1 column
     * Tablets: 2 columns (or 3 on ultra-wide)
     */
    val listGridColumns: Int
        get() = when (widthClass) {
            WindowWidthClass.Compact -> 1
            WindowWidthClass.Medium -> 2
            WindowWidthClass.Expanded -> if (widthDp >= 1100.dp) 3 else 2
        }

    /**
     * Adaptive column count for Modal Menu Sheet.
     */
    val menuColumns: Int
        get() = when {
            widthDp < 480.dp -> 1
            widthDp < 840.dp -> 2
            else -> 3
        }

    /**
     * Recommended max width for form and editor containers to ensure optimal readability.
     */
    val formMaxWidth: Dp get() = 860.dp

    /**
     * Recommended max width for content dashboards and list screens.
     */
    val contentMaxWidth: Dp get() = 1200.dp

    /**
     * Responsive font size multipliers for comfortable typography across phone and tablet screens.
     */
    val titleLargeSize: TextUnit get() = if (isTablet) 24.sp else 20.sp
    val titleMediumSize: TextUnit get() = if (isTablet) 18.sp else 16.sp
    val bodyLargeSize: TextUnit get() = if (isTablet) 15.sp else 13.5.sp
    val bodySmallSize: TextUnit get() = if (isTablet) 13.sp else 11.5.sp
    val menuTitleSize: TextUnit get() = if (isTablet) 16.5.sp else 14.5.sp
    val menuSubtitleSize: TextUnit get() = if (isTablet) 12.5.sp else 11.sp
    val iconSize: Dp get() = if (isTablet) 46.dp else 40.dp
}

@Composable
fun rememberWindowAdaptiveInfo(): WindowAdaptiveInfo {
    val configuration = LocalConfiguration.current
    val widthDp = configuration.screenWidthDp.dp
    val heightDp = configuration.screenHeightDp.dp

    return remember(widthDp, heightDp) {
        val widthClass = when {
            widthDp < 600.dp -> WindowWidthClass.Compact
            widthDp < 840.dp -> WindowWidthClass.Medium
            else -> WindowWidthClass.Expanded
        }
        WindowAdaptiveInfo(
            widthDp = widthDp,
            heightDp = heightDp,
            widthClass = widthClass
        )
    }
}

/**
 * Centered responsive container that automatically limits maximum width on wide/tablet displays
 * while taking full width on mobile devices.
 */
@Composable
fun AdaptiveContainer(
    modifier: Modifier = Modifier,
    maxWidth: Dp = 1200.dp,
    content: @Composable BoxScope.() -> Unit
) {
    Box(
        modifier = modifier.fillMaxWidth(),
        contentAlignment = Alignment.TopCenter
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .widthIn(max = maxWidth),
            content = content
        )
    }
}
