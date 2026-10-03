package com.example.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.ui.theme.StatusPaidGreen
import com.example.ui.viewmodel.MonthlyRevenueItem

@Composable
fun RevenueChart(
    items: List<MonthlyRevenueItem>,
    currencySymbol: String = "$",
    modifier: Modifier = Modifier
) {
    val isDark = isSystemInDarkTheme()

    GlassCard(
        modifier = modifier
            .testTag("revenue_chart_card")
            .fillMaxWidth(),
        shape = RoundedCornerShape(20.dp),
        elevation = 6.dp
    ) {
        Column(modifier = Modifier.padding(18.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text(
                        text = "Revenue & Billing Trends",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = if (isDark) Color.White else Color(0xFF0F172A),
                        fontSize = 16.sp
                    )
                    Text(
                        text = "Invoiced vs Collected payments",
                        style = MaterialTheme.typography.bodySmall,
                        color = if (isDark) Color(0xFF94A3B8) else Color(0xFF64748B),
                        fontSize = 12.sp
                    )
                }

                // Legend Pills
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Box(
                        modifier = Modifier
                            .size(10.dp)
                            .clip(CircleShape)
                            .background(Color(0xFF2563EB))
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = "Billed",
                        fontSize = 11.5.sp,
                        fontWeight = FontWeight.Medium,
                        color = if (isDark) Color(0xFF94A3B8) else Color(0xFF475569)
                    )
                    Spacer(modifier = Modifier.width(12.dp))
                    Box(
                        modifier = Modifier
                            .size(10.dp)
                            .clip(CircleShape)
                            .background(StatusPaidGreen)
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = "Paid",
                        fontSize = 11.5.sp,
                        fontWeight = FontWeight.Medium,
                        color = if (isDark) Color(0xFF94A3B8) else Color(0xFF475569)
                    )
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            val maxVal = maxOf(1000.0, items.maxOfOrNull { maxOf(it.totalAmount, it.paidAmount) } ?: 1000.0)
            val chartHeight = 150.dp

            Canvas(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(chartHeight)
            ) {
                val canvasWidth = size.width
                val canvasHeight = size.height
                val bottomLabelHeight = 40f
                val availableHeight = canvasHeight - bottomLabelHeight

                // Draw subtle horizontal grid lines
                val gridLines = 3
                val gridColor = if (isDark) Color(0x33475569) else Color(0x3394A3B8)
                for (g in 0..gridLines) {
                    val y = availableHeight * (g.toFloat() / gridLines)
                    drawLine(
                        color = gridColor,
                        start = Offset(0f, y),
                        end = Offset(canvasWidth, y),
                        strokeWidth = 1f
                    )
                }

                if (items.isNotEmpty()) {
                    val groupWidth = canvasWidth / items.size
                    val barWidth = groupWidth * 0.28f
                    val barSpacing = 5f

                    val billedGradient = Brush.verticalGradient(
                        colors = listOf(Color(0xFF3B82F6), Color(0xFF1D4ED8))
                    )
                    val paidGradient = Brush.verticalGradient(
                        colors = listOf(Color(0xFF10B981), Color(0xFF059669))
                    )

                    items.forEachIndexed { index, item ->
                        val groupCenterX = (index * groupWidth) + (groupWidth / 2)

                        // Invoiced Bar
                        val invoicedHeight = ((item.totalAmount / maxVal) * availableHeight).toFloat().coerceAtLeast(8f)
                        val invoicedLeft = groupCenterX - barWidth - (barSpacing / 2)
                        val invoicedTop = availableHeight - invoicedHeight

                        drawRoundRect(
                            brush = billedGradient,
                            topLeft = Offset(invoicedLeft, invoicedTop),
                            size = Size(barWidth, invoicedHeight),
                            cornerRadius = CornerRadius(6f, 6f)
                        )

                        // Paid Bar
                        val paidHeight = ((item.paidAmount / maxVal) * availableHeight).toFloat().coerceAtLeast(8f)
                        val paidLeft = groupCenterX + (barSpacing / 2)
                        val paidTop = availableHeight - paidHeight

                        drawRoundRect(
                            brush = paidGradient,
                            topLeft = Offset(paidLeft, paidTop),
                            size = Size(barWidth, paidHeight),
                            cornerRadius = CornerRadius(6f, 6f)
                        )

                        // Draw Month Label
                        drawContext.canvas.nativeCanvas.apply {
                            val paint = android.graphics.Paint().apply {
                                color = if (isDark) android.graphics.Color.parseColor("#94A3B8") else android.graphics.Color.parseColor("#475569")
                                textSize = 28f
                                textAlign = android.graphics.Paint.Align.CENTER
                                isAntiAlias = true
                                typeface = android.graphics.Typeface.create(android.graphics.Typeface.DEFAULT, android.graphics.Typeface.BOLD)
                            }
                            drawText(
                                item.monthName,
                                groupCenterX,
                                canvasHeight - 6f,
                                paint
                            )
                        }
                    }
                }
            }
        }
    }
}

