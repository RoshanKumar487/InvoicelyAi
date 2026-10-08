package com.example.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Drafts
import androidx.compose.material.icons.filled.HourglassTop
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.ui.theme.StatusDraftSlate
import com.example.ui.theme.StatusOverdueRose
import com.example.ui.theme.StatusPaidGreen
import com.example.ui.theme.StatusPendingAmber
import java.util.Locale

@Composable
fun InvoiceStatusBadge(
    status: String,
    modifier: Modifier = Modifier
) {
    val (baseColor, icon) = when (status.lowercase(Locale.US)) {
        "paid" -> Pair(StatusPaidGreen, Icons.Default.CheckCircle)
        "sent" -> Pair(StatusPendingAmber, Icons.Default.HourglassTop)
        "overdue" -> Pair(StatusOverdueRose, Icons.Default.Warning)
        else -> Pair(StatusDraftSlate, Icons.Default.Drafts)
    }

    Box(
        modifier = modifier
            .clip(RoundedCornerShape(12.dp))
            .border(
                border = BorderStroke(1.dp, baseColor.copy(alpha = 0.40f)),
                shape = RoundedCornerShape(12.dp)
            )
            .background(baseColor.copy(alpha = 0.12f))
            .padding(horizontal = 9.dp, vertical = 4.dp),
        contentAlignment = Alignment.Center
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = baseColor,
                modifier = Modifier.size(12.dp)
            )
            Spacer(modifier = Modifier.width(4.5.dp))
            Text(
                text = status.replaceFirstChar { if (it.isLowerCase()) it.titlecase(Locale.US) else it.toString() },
                color = baseColor,
                fontSize = 11.5.sp,
                fontWeight = FontWeight.Bold
            )
        }
    }
}

