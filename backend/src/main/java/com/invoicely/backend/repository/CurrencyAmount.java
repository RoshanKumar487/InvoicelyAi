package com.invoicely.backend.repository;

import java.math.BigDecimal;

public interface CurrencyAmount {
    String getCurrency();
    BigDecimal getTotal();
}
