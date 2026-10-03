package com.example.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.ui.theme.DarkBackground
import com.example.ui.theme.GlassDarkBorder
import com.example.ui.theme.GlassDarkSurface
import com.example.ui.theme.GlassDarkSurfaceSubtle
import com.example.ui.theme.GlassGlowCyan
import com.example.ui.theme.GlassGlowIndigo
import com.example.ui.theme.GlassGlowPurple
import com.example.ui.theme.GlassGlowSapphire
import com.example.ui.theme.GlassInputBorder
import com.example.ui.theme.GlassInputFocusedBorder
import com.example.ui.theme.GlassInputPlaceholder
import com.example.ui.theme.GlassInputText
import com.example.ui.theme.GlassLightBorder
import com.example.ui.theme.GlassLightBorderSubtle
import com.example.ui.theme.GlassLightSurface
import com.example.ui.theme.GlassLightSurfaceSubtle
import com.example.ui.theme.PrimaryLightBlue
import com.example.ui.theme.PrimaryNavy
import com.example.ui.theme.Slate50
import com.example.ui.theme.Slate100

/**
 * Ambient Atmospheric Mesh Backdrop for the Glassmorphism system.
 * Renders subtle glowing orbs and gradients that shine through frosted glass components.
 */
@Composable
fun AmbientGlassBackdrop(
    modifier: Modifier = Modifier,
    content: @Composable BoxScope.() -> Unit
) {
    val isDark = isSystemInDarkTheme()

    Box(
        modifier = modifier
            .fillMaxSize()
            .background(
                brush = if (isDark) {
                    Brush.verticalGradient(
                        colors = listOf(
                            Color(0xFF090D16),
                            Color(0xFF0F172A),
                            Color(0xFF0B1120)
                        )
                    )
                } else {
                    Brush.verticalGradient(
                        colors = listOf(
                            Color(0xFFF1F5F9),
                            Color(0xFFE2E8F0),
                            Color(0xFFF8FAFC)
                        )
                    )
                }
            )
    ) {
        // Glowing Ambient Mesh Highlights (Orbs)
        // Top-right glowing orb
        Box(
            modifier = Modifier
                .size(340.dp)
                .align(Alignment.TopEnd)
                .offset(x = 100.dp, y = (-80).dp)
                .background(
                    brush = Brush.radialGradient(
                        colors = listOf(
                            (if (isDark) GlassGlowSapphire else Color(0xFF60A5FA)).copy(alpha = if (isDark) 0.28f else 0.18f),
                            Color.Transparent
                        )
                    ),
                    shape = CircleShape
                )
        )

        // Mid-left glowing orb
        Box(
            modifier = Modifier
                .size(380.dp)
                .align(Alignment.CenterStart)
                .offset(x = (-120).dp, y = 60.dp)
                .background(
                    brush = Brush.radialGradient(
                        colors = listOf(
                            (if (isDark) GlassGlowPurple else Color(0xFFA78BFA)).copy(alpha = if (isDark) 0.24f else 0.16f),
                            Color.Transparent
                        )
                    ),
                    shape = CircleShape
                )
        )

        // Bottom-right glowing orb
        Box(
            modifier = Modifier
                .size(320.dp)
                .align(Alignment.BottomEnd)
                .offset(x = 80.dp, y = 100.dp)
                .background(
                    brush = Brush.radialGradient(
                        colors = listOf(
                            (if (isDark) GlassGlowCyan else Color(0xFF38BDF8)).copy(alpha = if (isDark) 0.20f else 0.14f),
                            Color.Transparent
                        )
                    ),
                    shape = CircleShape
                )
        )

        // Foreground content with frosted interaction
        content()
    }
}

/**
 * Premium Frosted Glass Card with subtle specular gradient border,
 * diffused ambient elevation shadow, and pristine content visibility.
 */
@Composable
fun GlassCard(
    modifier: Modifier = Modifier,
    shape: Shape = RoundedCornerShape(20.dp),
    elevation: Dp = 6.dp,
    onClick: (() -> Unit)? = null,
    borderBrush: Brush? = null,
    border: BorderStroke? = null,
    content: @Composable () -> Unit
) {
    val isDark = isSystemInDarkTheme()

    val surfaceBrush = Brush.verticalGradient(
        colors = if (isDark) {
            listOf(
                GlassDarkSurface,
                GlassDarkSurfaceSubtle
            )
        } else {
            listOf(
                GlassLightSurface,
                GlassLightSurfaceSubtle
            )
        }
    )

    val specularBorder = borderBrush ?: Brush.linearGradient(
        colors = if (isDark) {
            listOf(
                GlassDarkBorder,
                Color.White.copy(alpha = 0.08f)
            )
        } else {
            listOf(
                GlassLightBorder,
                GlassLightBorderSubtle
            )
        }
    )

    val effectiveBorder = border ?: BorderStroke(1.2.dp, specularBorder)
    val shadowSpotColor = if (isDark) Color(0x66000000) else Color(0x1F1E3A8A)

    val cardModifier = modifier
        .shadow(
            elevation = elevation,
            shape = shape,
            spotColor = shadowSpotColor,
            ambientColor = Color(0x10000000)
        )
        .clip(shape)
        .border(
            border = effectiveBorder,
            shape = shape
        )
        .background(surfaceBrush)
        .then(
            if (onClick != null) Modifier.clickable(onClick = onClick) else Modifier
        )

    Box(modifier = cardModifier) {
        content()
    }
}

/**
 * Elevated Hero Glass Card with vibrant gradient accent bar
 */
@Composable
fun GlassHeroCard(
    modifier: Modifier = Modifier,
    shape: Shape = RoundedCornerShape(22.dp),
    accentGradient: Brush = Brush.horizontalGradient(
        listOf(Color(0xFF2563EB), Color(0xFF7C3AED), Color(0xFF06B6D4))
    ),
    content: @Composable () -> Unit
) {
    GlassCard(
        modifier = modifier,
        shape = shape,
        elevation = 8.dp
    ) {
        Box(modifier = Modifier.fillMaxWidth()) {
            // Subtle glowing top border highlight line
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(3.5.dp)
                    .background(accentGradient)
            )
            content()
        }
    }
}

/**
 * High-Contrast Glassmorphic OutlinedTextField Colors ensuring
 * 100% field, label, placeholder, and border visibility.
 */
@Composable
fun glassTextFieldColors() = OutlinedTextFieldDefaults.colors(
    focusedTextColor = if (isSystemInDarkTheme()) Color.White else GlassInputText,
    unfocusedTextColor = if (isSystemInDarkTheme()) Color(0xFFF1F5F9) else GlassInputText,
    focusedContainerColor = if (isSystemInDarkTheme()) Color(0xEE0F172A) else Color(0xF8FFFFFF),
    unfocusedContainerColor = if (isSystemInDarkTheme()) Color(0xCC0F172A) else Color(0xF2FFFFFF),
    focusedBorderColor = GlassInputFocusedBorder,
    unfocusedBorderColor = if (isSystemInDarkTheme()) Color(0xFF475569) else Color(0xFFCBD5E1),
    focusedLabelColor = GlassInputFocusedBorder,
    unfocusedLabelColor = if (isSystemInDarkTheme()) Color(0xFF94A3B8) else Color(0xFF334155),
    focusedPlaceholderColor = GlassInputPlaceholder,
    unfocusedPlaceholderColor = GlassInputPlaceholder,
    cursorColor = GlassInputFocusedBorder,
    focusedLeadingIconColor = GlassInputFocusedBorder,
    unfocusedLeadingIconColor = if (isSystemInDarkTheme()) Color(0xFF94A3B8) else Color(0xFF64748B),
    focusedTrailingIconColor = GlassInputFocusedBorder,
    unfocusedTrailingIconColor = if (isSystemInDarkTheme()) Color(0xFF94A3B8) else Color(0xFF64748B)
)

/**
 * Premium Radiant Glass Button with multi-stop sapphire to indigo gradient
 */
@Composable
fun GlassPrimaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    icon: ImageVector? = null,
    enabled: Boolean = true
) {
    val gradient = if (enabled) {
        Brush.horizontalGradient(
            colors = listOf(
                Color(0xFF1D4ED8),
                Color(0xFF3B82F6),
                Color(0xFF6366F1)
            )
        )
    } else {
        Brush.horizontalGradient(
            colors = listOf(
                Color(0xFF94A3B8),
                Color(0xFFCBD5E1)
            )
        )
    }

    Box(
        modifier = modifier
            .shadow(elevation = 6.dp, shape = RoundedCornerShape(16.dp), spotColor = Color(0x401D4ED8))
            .clip(RoundedCornerShape(16.dp))
            .border(
                border = BorderStroke(1.dp, Color.White.copy(alpha = 0.4f)),
                shape = RoundedCornerShape(16.dp)
            )
            .background(gradient)
            .clickable(enabled = enabled, onClick = onClick)
            .padding(horizontal = 20.dp, vertical = 14.dp),
        contentAlignment = Alignment.Center
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically
        ) {
            if (icon != null) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    tint = Color.White,
                    modifier = Modifier.size(18.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
            }
            Text(
                text = text,
                color = Color.White,
                fontWeight = FontWeight.Bold,
                fontSize = 14.sp
            )
        }
    }
}

/**
 * Frosted Glass Status Badge Pill with glowing translucent tint
 */
@Composable
fun GlassPillBadge(
    text: String,
    tintColor: Color,
    icon: ImageVector? = null,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .clip(RoundedCornerShape(14.dp))
            .border(
                border = BorderStroke(1.dp, tintColor.copy(alpha = 0.45f)),
                shape = RoundedCornerShape(14.dp)
            )
            .background(tintColor.copy(alpha = 0.14f))
            .padding(horizontal = 10.dp, vertical = 4.dp),
        contentAlignment = Alignment.Center
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            if (icon != null) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    tint = tintColor,
                    modifier = Modifier.size(12.dp)
                )
                Spacer(modifier = Modifier.width(4.dp))
            }
            Text(
                text = text,
                color = tintColor,
                fontSize = 11.sp,
                fontWeight = FontWeight.Bold
            )
        }
    }
}
