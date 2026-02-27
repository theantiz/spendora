package com.spendora.common.util;

import java.time.LocalDate;

public final class DateRangeUtil {

    private DateRangeUtil() {
    }

    public static LocalDate startOfMonth(LocalDate date) {
        return date.withDayOfMonth(1);
    }

    public static LocalDate endOfMonth(LocalDate date) {
        return date.withDayOfMonth(date.lengthOfMonth());
    }
}
