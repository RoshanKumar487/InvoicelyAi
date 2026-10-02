package com.example.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Calculate
import androidx.compose.material.icons.filled.CurrencyExchange
import androidx.compose.material.icons.filled.SwapHoriz
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.FilterChip
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableDoubleStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.model.InvoiceUtils
import com.example.ui.theme.PrimaryNavy

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TaxCalculatorScreen(
    onBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    var selectedTab by remember { mutableIntStateOf(0) } // 0: Tax Tool, 1: Currency Converter

    Scaffold(
        modifier = modifier.fillMaxSize(),
        topBar = {
            TopAppBar(
                title = { Text("Tax & Currency Tools", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(imageVector = Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = MaterialTheme.colorScheme.surface)
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            TabRow(
                selectedTabIndex = selectedTab,
                containerColor = MaterialTheme.colorScheme.surface,
                contentColor = PrimaryNavy
            ) {
                Tab(
                    selected = selectedTab == 0,
                    onClick = { selectedTab = 0 },
                    text = { Text("Tax Calculator", fontWeight = FontWeight.SemiBold) },
                    icon = { Icon(Icons.Default.Calculate, contentDescription = null, modifier = Modifier.size(18.dp)) }
                )
                Tab(
                    selected = selectedTab == 1,
                    onClick = { selectedTab = 1 },
                    text = { Text("Multi-Currency", fontWeight = FontWeight.SemiBold) },
                    icon = { Icon(Icons.Default.CurrencyExchange, contentDescription = null, modifier = Modifier.size(18.dp)) }
                )
            }

            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                if (selectedTab == 0) {
                    TaxCalculatorSection()
                } else {
                    CurrencyConverterSection()
                }
            }
        }
    }
}

@Composable
fun TaxCalculatorSection() {
    var isReverseCalc by remember { mutableStateOf(false) }

    // Forward Tax State
    var baseAmountStr by remember { mutableStateOf("1000") }
    var taxRate1Str by remember { mutableStateOf("10") }
    var taxLabel1 by remember { mutableStateOf("VAT / Sales Tax") }
    var taxRate2Str by remember { mutableStateOf("0") }
    var taxLabel2 by remember { mutableStateOf("Secondary Tax / Cess") }
    var discountPercentStr by remember { mutableStateOf("0") }
    var shippingStr by remember { mutableStateOf("0") }

    // Reverse Tax State (Extract tax from gross)
    var grossAmountStr by remember { mutableStateOf("1100") }
    var reverseTaxRateStr by remember { mutableStateOf("10") }

    Card(
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        shape = RoundedCornerShape(16.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = if (isReverseCalc) "Reverse Tax (Gross to Net)" else "Forward Tax (Net to Gross)",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = PrimaryNavy
                )

                FilterChip(
                    selected = isReverseCalc,
                    onClick = { isReverseCalc = !isReverseCalc },
                    label = { Text(if (isReverseCalc) "Switch: Forward" else "Switch: Reverse", fontSize = 11.sp) },
                    leadingIcon = { Icon(Icons.Default.SwapHoriz, contentDescription = null, modifier = Modifier.size(14.dp)) },
                    modifier = Modifier.testTag("toggle_reverse_tax")
                )
            }

            if (!isReverseCalc) {
                // Forward Calculation Inputs
                OutlinedTextField(
                    value = baseAmountStr,
                    onValueChange = { baseAmountStr = it },
                    label = { Text("Base Net Amount ($)") },
                    modifier = Modifier.fillMaxWidth().testTag("base_amount_input"),
                    shape = RoundedCornerShape(10.dp),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal)
                )

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    OutlinedTextField(
                        value = taxLabel1,
                        onValueChange = { taxLabel1 = it },
                        label = { Text("Primary Tax Label") },
                        modifier = Modifier.weight(1.3f),
                        shape = RoundedCornerShape(10.dp)
                    )
                    OutlinedTextField(
                        value = taxRate1Str,
                        onValueChange = { taxRate1Str = it },
                        label = { Text("Rate 1 (%)") },
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(10.dp),
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal)
                    )
                }

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    OutlinedTextField(
                        value = taxLabel2,
                        onValueChange = { taxLabel2 = it },
                        label = { Text("Secondary Tax") },
                        modifier = Modifier.weight(1.3f),
                        shape = RoundedCornerShape(10.dp)
                    )
                    OutlinedTextField(
                        value = taxRate2Str,
                        onValueChange = { taxRate2Str = it },
                        label = { Text("Rate 2 (%)") },
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(10.dp),
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal)
                    )
                }

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    OutlinedTextField(
                        value = discountPercentStr,
                        onValueChange = { discountPercentStr = it },
                        label = { Text("Discount (%)") },
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(10.dp),
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal)
                    )
                    OutlinedTextField(
                        value = shippingStr,
                        onValueChange = { shippingStr = it },
                        label = { Text("Shipping ($)") },
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(10.dp),
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal)
                    )
                }

                // Compute Forward
                val base = baseAmountStr.toDoubleOrNull() ?: 0.0
                val r1 = taxRate1Str.toDoubleOrNull() ?: 0.0
                val r2 = taxRate2Str.toDoubleOrNull() ?: 0.0
                val disc = discountPercentStr.toDoubleOrNull() ?: 0.0
                val ship = shippingStr.toDoubleOrNull() ?: 0.0

                val discountedBase = maxOf(0.0, base * (1.0 - (disc / 100.0)))
                val tax1Amt = discountedBase * (r1 / 100.0)
                val tax2Amt = discountedBase * (r2 / 100.0)
                val totalTax = tax1Amt + tax2Amt
                val totalGross = discountedBase + totalTax + ship

                // Breakdown Card
                Card(
                    colors = CardDefaults.cardColors(containerColor = PrimaryNavy),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        Text("Calculation Result", color = Color.White, fontWeight = FontWeight.Bold)
                        HorizontalDivider(color = Color.White.copy(alpha = 0.2f))

                        CalcRow("Net Base Amount:", InvoiceUtils.formatMoney(base))
                        if (disc > 0) CalcRow("Discount ($disc%):", "-${InvoiceUtils.formatMoney(base - discountedBase)}")
                        CalcRow("$taxLabel1 ($r1%):", InvoiceUtils.formatMoney(tax1Amt))
                        if (r2 > 0) CalcRow("$taxLabel2 ($r2%):", InvoiceUtils.formatMoney(tax2Amt))
                        if (ship > 0) CalcRow("Shipping:", InvoiceUtils.formatMoney(ship))
                        HorizontalDivider(color = Color.White.copy(alpha = 0.3f))
                        CalcRow("Final Total Amount:", InvoiceUtils.formatMoney(totalGross), isBold = true)
                    }
                }
            } else {
                // Reverse Tax Inputs
                OutlinedTextField(
                    value = grossAmountStr,
                    onValueChange = { grossAmountStr = it },
                    label = { Text("Gross / Tax-Inclusive Total ($)") },
                    modifier = Modifier.fillMaxWidth().testTag("gross_amount_input"),
                    shape = RoundedCornerShape(10.dp),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal)
                )

                OutlinedTextField(
                    value = reverseTaxRateStr,
                    onValueChange = { reverseTaxRateStr = it },
                    label = { Text("Tax Rate (%)") },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(10.dp),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal)
                )

                // Compute Reverse
                val gross = grossAmountStr.toDoubleOrNull() ?: 0.0
                val rate = reverseTaxRateStr.toDoubleOrNull() ?: 0.0
                val net = if (rate >= 0) gross / (1.0 + (rate / 100.0)) else gross
                val extractedTax = gross - net

                Card(
                    colors = CardDefaults.cardColors(containerColor = PrimaryNavy),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        Text("Extracted Net & Tax Breakdown", color = Color.White, fontWeight = FontWeight.Bold)
                        HorizontalDivider(color = Color.White.copy(alpha = 0.2f))

                        CalcRow("Gross Amount (Input):", InvoiceUtils.formatMoney(gross))
                        CalcRow("Pre-Tax Base Amount (Net):", InvoiceUtils.formatMoney(net), isBold = true)
                        CalcRow("Tax Extracted ($rate%):", InvoiceUtils.formatMoney(extractedTax))
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CurrencyConverterSection() {
    var amountStr by remember { mutableStateOf("1000") }
    var fromCurrency by remember { mutableStateOf("USD") }
    var toCurrency by remember { mutableStateOf("EUR") }

    // Multi-currency rate table vs USD
    val ratesToUsd = mapOf(
        "USD" to 1.0,
        "EUR" to 1.08,
        "GBP" to 1.28,
        "INR" to 0.012,
        "CAD" to 0.74,
        "AUD" to 0.66,
        "JPY" to 0.0067,
        "AED" to 0.27
    )

    val currencies = ratesToUsd.keys.toList()

    val amount = amountStr.toDoubleOrNull() ?: 0.0
    val fromRate = ratesToUsd[fromCurrency] ?: 1.0
    val toRate = ratesToUsd[toCurrency] ?: 1.0

    // Amount in USD = amount * fromRate
    val inUsd = amount * fromRate
    // Amount in target = inUsd / toRate
    val converted = if (toRate > 0) inUsd / toRate else 0.0

    Card(
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        shape = RoundedCornerShape(16.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
            Text(
                text = "Currency Converter",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = PrimaryNavy
            )

            OutlinedTextField(
                value = amountStr,
                onValueChange = { amountStr = it },
                label = { Text("Amount to Convert") },
                modifier = Modifier.fillMaxWidth().testTag("currency_conv_amount"),
                shape = RoundedCornerShape(10.dp),
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal)
            )

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(10.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                // From Currency
                var fromExpanded by remember { mutableStateOf(false) }
                ExposedDropdownMenuBox(
                    expanded = fromExpanded,
                    onExpandedChange = { fromExpanded = it },
                    modifier = Modifier.weight(1f)
                ) {
                    OutlinedTextField(
                        value = fromCurrency,
                        onValueChange = {},
                        readOnly = true,
                        label = { Text("From") },
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = fromExpanded) },
                        modifier = Modifier.menuAnchor(),
                        shape = RoundedCornerShape(10.dp)
                    )
                    ExposedDropdownMenu(
                        expanded = fromExpanded,
                        onDismissRequest = { fromExpanded = false }
                    ) {
                        currencies.forEach { c ->
                            DropdownMenuItem(
                                text = { Text(c) },
                                onClick = {
                                    fromCurrency = c
                                    fromExpanded = false
                                }
                            )
                        }
                    }
                }

                Icon(
                    imageVector = Icons.Default.SwapHoriz,
                    contentDescription = "Swap",
                    modifier = Modifier
                        .size(32.dp)
                        .clickable {
                            val temp = fromCurrency
                            fromCurrency = toCurrency
                            toCurrency = temp
                        }
                )

                // To Currency
                var toExpanded by remember { mutableStateOf(false) }
                ExposedDropdownMenuBox(
                    expanded = toExpanded,
                    onExpandedChange = { toExpanded = it },
                    modifier = Modifier.weight(1f)
                ) {
                    OutlinedTextField(
                        value = toCurrency,
                        onValueChange = {},
                        readOnly = true,
                        label = { Text("To") },
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = toExpanded) },
                        modifier = Modifier.menuAnchor(),
                        shape = RoundedCornerShape(10.dp)
                    )
                    ExposedDropdownMenu(
                        expanded = toExpanded,
                        onDismissRequest = { toExpanded = false }
                    ) {
                        currencies.forEach { c ->
                            DropdownMenuItem(
                                text = { Text(c) },
                                onClick = {
                                    toCurrency = c
                                    toExpanded = false
                                }
                            )
                        }
                    }
                }
            }

            // Converted Result Display
            Card(
                colors = CardDefaults.cardColors(containerColor = PrimaryNavy),
                shape = RoundedCornerShape(12.dp)
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        text = "$amount $fromCurrency =",
                        color = Color.White.copy(alpha = 0.8f),
                        fontSize = 14.sp
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = "${String.format(java.util.Locale.US, "%,.2f", converted)} $toCurrency",
                        color = Color.White,
                        fontSize = 24.sp,
                        fontWeight = FontWeight.Bold
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    val unitRate = fromRate / toRate
                    Text(
                        text = "1 $fromCurrency = ${String.format(java.util.Locale.US, "%.4f", unitRate)} $toCurrency",
                        color = Color.White.copy(alpha = 0.6f),
                        fontSize = 11.sp
                    )
                }
            }
        }
    }
}

@Composable
fun CalcRow(label: String, value: String, isBold: Boolean = false) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = label,
            color = Color.White.copy(alpha = 0.85f),
            fontSize = if (isBold) 14.sp else 12.sp,
            fontWeight = if (isBold) FontWeight.Bold else FontWeight.Normal
        )
        Text(
            text = value,
            color = Color.White,
            fontSize = if (isBold) 16.sp else 12.sp,
            fontWeight = if (isBold) FontWeight.Bold else FontWeight.SemiBold
        )
    }
}
