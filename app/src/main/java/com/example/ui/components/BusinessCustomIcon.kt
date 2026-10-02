package com.example.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccountBalance
import androidx.compose.material.icons.filled.Business
import androidx.compose.material.icons.filled.Diamond
import androidx.compose.material.icons.filled.Receipt
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.Storefront
import androidx.compose.material.icons.filled.TrendingUp
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.model.BusinessProfile

@Composable
fun BusinessCustomIcon(
    profile: BusinessProfile,
    modifier: Modifier = Modifier,
    size: Dp = 48.dp,
    borderWidth: Dp = 0.dp,
    borderColor: Color = Color.Transparent
) {
    val bgColor = remember(profile.customIconBgColorHex) {
        try {
            Color(android.graphics.Color.parseColor(profile.customIconBgColorHex))
        } catch (_: Exception) {
            Color(0xFF1E3A8A)
        }
    }

    val fgColor = remember(profile.customIconFgColorHex) {
        try {
            Color(android.graphics.Color.parseColor(profile.customIconFgColorHex))
        } catch (_: Exception) {
            Color.White
        }
    }

    val shape: Shape = when (profile.customIconShape.lowercase()) {
        "circle" -> CircleShape
        "square" -> RoundedCornerShape(4.dp)
        else -> RoundedCornerShape((size.value * 0.28f).dp)
    }

    val iconVector: ImageVector = when (profile.customIconSymbol.lowercase()) {
        "business" -> Icons.Default.Business
        "store", "storefront" -> Icons.Default.Storefront
        "star" -> Icons.Default.Star
        "diamond" -> Icons.Default.Diamond
        "verified" -> Icons.Default.Verified
        "trending" -> Icons.Default.TrendingUp
        "account_balance" -> Icons.Default.AccountBalance
        else -> Icons.Default.Receipt
    }

    Box(
        modifier = modifier
            .size(size)
            .clip(shape)
            .background(bgColor)
            .then(
                if (borderWidth > 0.dp) Modifier.border(borderWidth, borderColor, shape)
                else Modifier
            ),
        contentAlignment = Alignment.Center
    ) {
        if (profile.customIconType == "initials") {
            val text = if (profile.customIconText.isNotBlank()) profile.customIconText
            else profile.businessName.take(2).uppercase()

            Text(
                text = text,
                color = fgColor,
                fontWeight = FontWeight.Bold,
                fontSize = (size.value * 0.40f).sp,
                letterSpacing = 1.sp
            )
        } else {
            Icon(
                imageVector = iconVector,
                contentDescription = profile.businessName,
                tint = fgColor,
                modifier = Modifier.size((size.value * 0.55f).dp)
            )
        }
    }
}
