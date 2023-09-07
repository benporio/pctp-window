SELECT
    BE.U_BookingId AS U_BookingNumber,
    TRY_PARSE(PE.U_GrossClientRatesTax AS FLOAT) AS PE_U_GrossClientRatesTax,
    TRY_PARSE(BE.U_GrossInitialRate AS FLOAT) AS BE_U_GrossInitialRate,
    TRY_PARSE(PE.U_Demurrage AS FLOAT) AS PE_U_Demurrage,
    TRY_PARSE(BE.U_Demurrage AS FLOAT) AS BE_U_Demurrage,
    TRY_PARSE(PE.U_TotalAddtlCharges AS FLOAT) AS PE_U_TotalAddtlCharges,
    TRY_PARSE(BE.U_AddCharges AS FLOAT) AS BE_U_AddCharges,
    'BILLING-TP-PRICING-DATA-INCONSISTENCY' AS ISSUE
FROM BILLING_EXTRACT BE
LEFT JOIN PRICING_EXTRACT PE ON PE.U_BookingId = BE.U_BookingId
WHERE (
    TRY_PARSE(PE.U_GrossClientRatesTax AS FLOAT) <> TRY_PARSE(BE.U_GrossInitialRate AS FLOAT)
    OR TRY_PARSE(PE.U_Demurrage AS FLOAT) <> TRY_PARSE(BE.U_Demurrage AS FLOAT)
    OR TRY_PARSE(PE.U_TotalAddtlCharges AS FLOAT) <> TRY_PARSE(BE.U_AddCharges AS FLOAT)
    OR ((
            (TRY_PARSE(PE.U_GrossClientRatesTax AS FLOAT) IS NOT NULL AND TRY_PARSE(PE.U_GrossClientRatesTax AS FLOAT) <> 0)
            AND (TRY_PARSE(BE.U_GrossInitialRate AS FLOAT) IS NULL OR TRY_PARSE(BE.U_GrossInitialRate AS FLOAT) = 0)
        )
        OR (
            (TRY_PARSE(PE.U_Demurrage AS FLOAT) IS NOT NULL AND TRY_PARSE(PE.U_Demurrage AS FLOAT) <> 0)
            AND (TRY_PARSE(BE.U_Demurrage AS FLOAT) IS NULL OR TRY_PARSE(BE.U_Demurrage AS FLOAT) = 0)
        )
        OR (
            (TRY_PARSE(PE.U_TotalAddtlCharges AS FLOAT) IS NOT NULL AND TRY_PARSE(PE.U_TotalAddtlCharges AS FLOAT) <> 0)
            AND (TRY_PARSE(BE.U_AddCharges AS FLOAT) IS NULL OR TRY_PARSE(BE.U_AddCharges AS FLOAT) = 0)
    ))
)
UNION
SELECT
    TE.U_BookingId AS U_BookingNumber,
    'BILLING-TP-PRICING-DATA-INCONSISTENCY' AS ISSUE
FROM TP_EXTRACT TE
LEFT JOIN PRICING_EXTRACT PE ON PE.U_BookingId = TE.U_BookingId
WHERE (
    TRY_PARSE(PE.U_GrossTruckerRates AS FLOAT) <> TRY_PARSE(TE.U_GrossTruckerRates AS FLOAT)
    OR TRY_PARSE(PE.U_GrossTruckerRatesTax AS FLOAT) <> TRY_PARSE(TE.U_GrossTruckerRatesN AS FLOAT)
    OR TRY_PARSE(PE.U_RateBasisT AS FLOAT) <> TRY_PARSE(TE.U_RateBasis AS FLOAT)
    OR TRY_PARSE(PE.U_Demurrage2 AS FLOAT) <> TRY_PARSE(TE.U_Demurrage AS FLOAT)
    OR TRY_PARSE(PE.U_AddtlDrop2 AS FLOAT) <> TRY_PARSE(TE.U_AddtlDrop AS FLOAT)
    OR TRY_PARSE(PE.U_BoomTruck2 AS FLOAT) <> TRY_PARSE(TE.U_BoomTruck AS FLOAT)
    OR TRY_PARSE(PE.U_Manpower2 AS FLOAT) <> TRY_PARSE(TE.U_Manpower AS FLOAT)
    OR TRY_PARSE(PE.U_Backload2 AS FLOAT) <> TRY_PARSE(TE.U_BackLoad AS FLOAT)
    OR TRY_PARSE(PE.U_totalAddtlCharges2 AS FLOAT) <> TRY_PARSE(TE.U_Addtlcharges AS FLOAT)
    OR TRY_PARSE(PE.U_Demurrage3 AS FLOAT) <> TRY_PARSE(TE.U_DemurrageN AS FLOAT)
    OR TRY_PARSE(PE.U_AddtlCharges AS FLOAT) <> TRY_PARSE(TE.U_AddtlChargesN AS FLOAT)
    OR ((
            (TRY_PARSE(PE.U_GrossTruckerRates AS FLOAT) IS NOT NULL AND TRY_PARSE(PE.U_GrossTruckerRates AS FLOAT) <> 0)
            AND (TRY_PARSE(TE.U_GrossTruckerRates AS FLOAT) IS NULL OR TRY_PARSE(TE.U_GrossTruckerRates AS FLOAT) = 0)
        )
        OR (
            (TRY_PARSE(PE.U_GrossTruckerRatesTax AS FLOAT) IS NOT NULL AND TRY_PARSE(PE.U_GrossTruckerRatesTax AS FLOAT) <> 0)
            AND (TRY_PARSE(TE.U_GrossTruckerRatesN AS FLOAT) IS NULL OR TRY_PARSE(TE.U_GrossTruckerRatesN AS FLOAT) = 0)
        )
        OR (
            (TRY_PARSE(PE.U_RateBasisT AS FLOAT) IS NOT NULL AND TRY_PARSE(PE.U_RateBasisT AS FLOAT) <> '')
            AND (TRY_PARSE(TE.U_RateBasis AS FLOAT) IS NULL OR TRY_PARSE(TE.U_RateBasis AS FLOAT) = '')
        )
        OR (
            (TRY_PARSE(PE.U_Demurrage2 AS FLOAT) IS NOT NULL AND TRY_PARSE(PE.U_Demurrage2 AS FLOAT) <> 0)
            AND (TRY_PARSE(TE.U_Demurrage AS FLOAT) IS NULL OR TRY_PARSE(TE.U_Demurrage AS FLOAT) = 0)
        )
        OR (
            (TRY_PARSE(PE.U_AddtlDrop2 AS FLOAT) IS NOT NULL AND TRY_PARSE(PE.U_AddtlDrop2 AS FLOAT) <> 0)
            AND (TRY_PARSE(TE.U_AddtlDrop AS FLOAT) IS NULL OR TRY_PARSE(TE.U_AddtlDrop AS FLOAT) = 0)
        )
        OR (
            (TRY_PARSE(PE.U_BoomTruck2 AS FLOAT) IS NOT NULL AND TRY_PARSE(PE.U_BoomTruck2 AS FLOAT) <> 0)
            AND (TRY_PARSE(TE.U_BoomTruck AS FLOAT) IS NULL OR TRY_PARSE(TE.U_BoomTruck AS FLOAT) = 0)
        )
        OR (
            (TRY_PARSE(PE.U_Manpower2 AS FLOAT) IS NOT NULL AND TRY_PARSE(PE.U_Manpower2 AS FLOAT) <> 0)
            AND (TRY_PARSE(TE.U_Manpower AS FLOAT) IS NULL OR TRY_PARSE(TE.U_Manpower AS FLOAT) = 0)
        )
        OR (
            (TRY_PARSE(PE.U_Backload2 AS FLOAT) IS NOT NULL AND TRY_PARSE(PE.U_Backload2 AS FLOAT) <> 0)
            AND (TRY_PARSE(TE.U_BackLoad AS FLOAT) IS NULL OR TRY_PARSE(TE.U_BackLoad AS FLOAT) = 0)
        )
        OR (
            (TRY_PARSE(PE.U_totalAddtlCharges2 AS FLOAT) IS NOT NULL AND TRY_PARSE(PE.U_totalAddtlCharges2 AS FLOAT) <> 0)
            AND (TRY_PARSE(TE.U_Addtlcharges AS FLOAT) IS NULL OR TRY_PARSE(TE.U_Addtlcharges AS FLOAT) = 0)
        )
        OR (
            (TRY_PARSE(PE.U_Demurrage3 AS FLOAT) IS NOT NULL AND TRY_PARSE(PE.U_Demurrage3 AS FLOAT) <> 0)
            AND (TRY_PARSE(TE.U_DemurrageN AS FLOAT) IS NULL OR TRY_PARSE(TE.U_DemurrageN AS FLOAT) = 0)
        )
        OR (
            (TRY_PARSE(PE.U_AddtlCharges AS FLOAT) IS NOT NULL AND TRY_PARSE(PE.U_AddtlCharges AS FLOAT) <> 0)
            AND (TRY_PARSE(TE.U_AddtlChargesN AS FLOAT) IS NULL OR TRY_PARSE(TE.U_AddtlChargesN AS FLOAT) = 0)
    ))
)


SELECT
    TE.U_BookingId AS U_BookingNumber,
    TRY_PARSE(PE.U_GrossTruckerRates AS FLOAT) AS PE_U_GrossTruckerRates,
    TRY_PARSE(TE.U_GrossTruckerRates AS FLOAT) AS TE_U_GrossTruckerRates,
    TRY_PARSE(PE.U_GrossTruckerRatesTax AS FLOAT) AS PE_U_GrossTruckerRatesTax,
    TRY_PARSE(TE.U_GrossTruckerRatesN AS FLOAT) AS TE_U_GrossTruckerRatesN,
    TRY_PARSE(PE.U_RateBasisT AS FLOAT) AS PE_U_RateBasisT,
    TRY_PARSE(TE.U_RateBasis AS FLOAT) AS TE_U_RateBasis,
    TRY_PARSE(PE.U_Demurrage2 AS FLOAT) AS PE_U_Demurrage2,
    TRY_PARSE(TE.U_Demurrage AS FLOAT) AS TE_U_Demurrage,
    TRY_PARSE(PE.U_AddtlDrop2 AS FLOAT) AS PE_U_AddtlDrop2,
    TRY_PARSE(TE.U_AddtlDrop AS FLOAT) AS TE_U_AddtlDrop,
    TRY_PARSE(PE.U_BoomTruck2 AS FLOAT) AS PE_U_BoomTruck2,
    TRY_PARSE(TE.U_BoomTruck AS FLOAT) AS TE_U_BoomTruck,
    TRY_PARSE(PE.U_Manpower2 AS FLOAT) AS PE_U_Manpower2,
    TRY_PARSE(TE.U_Manpower AS FLOAT) AS TE_U_Manpower,
    TRY_PARSE(PE.U_Backload2 AS FLOAT) AS PE_U_Backload2,
    TRY_PARSE(TE.U_BackLoad AS FLOAT) AS TE_U_BackLoad,
    TRY_PARSE(PE.U_totalAddtlCharges2 AS FLOAT) AS PE_U_totalAddtlCharges2,
    TRY_PARSE(TE.U_Addtlcharges AS FLOAT) AS TE_U_Addtlcharges,
    TRY_PARSE(PE.U_Demurrage3 AS FLOAT) AS PE_U_Demurrage3,
    TRY_PARSE(TE.U_DemurrageN AS FLOAT) AS TE_U_DemurrageN,
    TRY_PARSE(PE.U_AddtlCharges AS FLOAT) AS PE_U_AddtlCharges,
    TRY_PARSE(TE.U_AddtlChargesN AS FLOAT) AS TE_U_AddtlChargesN,
    'BILLING-TP-PRICING-DATA-INCONSISTENCY' AS ISSUE
FROM TP_EXTRACT TE
LEFT JOIN PRICING_EXTRACT PE ON PE.U_BookingId = TE.U_BookingId
WHERE (
    TRY_PARSE(PE.U_GrossTruckerRates AS FLOAT) <> TRY_PARSE(TE.U_GrossTruckerRates AS FLOAT)
    OR TRY_PARSE(PE.U_GrossTruckerRatesTax AS FLOAT) <> TRY_PARSE(TE.U_GrossTruckerRatesN AS FLOAT)
    OR TRY_PARSE(PE.U_RateBasisT AS FLOAT) <> TRY_PARSE(TE.U_RateBasis AS FLOAT)
    OR TRY_PARSE(PE.U_Demurrage2 AS FLOAT) <> TRY_PARSE(TE.U_Demurrage AS FLOAT)
    OR TRY_PARSE(PE.U_AddtlDrop2 AS FLOAT) <> TRY_PARSE(TE.U_AddtlDrop AS FLOAT)
    OR TRY_PARSE(PE.U_BoomTruck2 AS FLOAT) <> TRY_PARSE(TE.U_BoomTruck AS FLOAT)
    OR TRY_PARSE(PE.U_Manpower2 AS FLOAT) <> TRY_PARSE(TE.U_Manpower AS FLOAT)
    OR TRY_PARSE(PE.U_Backload2 AS FLOAT) <> TRY_PARSE(TE.U_BackLoad AS FLOAT)
    OR TRY_PARSE(PE.U_totalAddtlCharges2 AS FLOAT) <> TRY_PARSE(TE.U_Addtlcharges AS FLOAT)
    OR TRY_PARSE(PE.U_Demurrage3 AS FLOAT) <> TRY_PARSE(TE.U_DemurrageN AS FLOAT)
    OR TRY_PARSE(PE.U_AddtlCharges AS FLOAT) <> TRY_PARSE(TE.U_AddtlChargesN AS FLOAT)
    OR ((
            (TRY_PARSE(PE.U_GrossTruckerRates AS FLOAT) IS NOT NULL AND TRY_PARSE(PE.U_GrossTruckerRates AS FLOAT) <> 0)
            AND (TRY_PARSE(TE.U_GrossTruckerRates AS FLOAT) IS NULL OR TRY_PARSE(TE.U_GrossTruckerRates AS FLOAT) = 0)
        )
        OR (
            (TRY_PARSE(PE.U_GrossTruckerRatesTax AS FLOAT) IS NOT NULL AND TRY_PARSE(PE.U_GrossTruckerRatesTax AS FLOAT) <> 0)
            AND (TRY_PARSE(TE.U_GrossTruckerRatesN AS FLOAT) IS NULL OR TRY_PARSE(TE.U_GrossTruckerRatesN AS FLOAT) = 0)
        )
        OR (
            (TRY_PARSE(PE.U_RateBasisT AS FLOAT) IS NOT NULL AND TRY_PARSE(PE.U_RateBasisT AS FLOAT) <> '')
            AND (TRY_PARSE(TE.U_RateBasis AS FLOAT) IS NULL OR TRY_PARSE(TE.U_RateBasis AS FLOAT) = '')
        )
        OR (
            (TRY_PARSE(PE.U_Demurrage2 AS FLOAT) IS NOT NULL AND TRY_PARSE(PE.U_Demurrage2 AS FLOAT) <> 0)
            AND (TRY_PARSE(TE.U_Demurrage AS FLOAT) IS NULL OR TRY_PARSE(TE.U_Demurrage AS FLOAT) = 0)
        )
        OR (
            (TRY_PARSE(PE.U_AddtlDrop2 AS FLOAT) IS NOT NULL AND TRY_PARSE(PE.U_AddtlDrop2 AS FLOAT) <> 0)
            AND (TRY_PARSE(TE.U_AddtlDrop AS FLOAT) IS NULL OR TRY_PARSE(TE.U_AddtlDrop AS FLOAT) = 0)
        )
        OR (
            (TRY_PARSE(PE.U_BoomTruck2 AS FLOAT) IS NOT NULL AND TRY_PARSE(PE.U_BoomTruck2 AS FLOAT) <> 0)
            AND (TRY_PARSE(TE.U_BoomTruck AS FLOAT) IS NULL OR TRY_PARSE(TE.U_BoomTruck AS FLOAT) = 0)
        )
        OR (
            (TRY_PARSE(PE.U_Manpower2 AS FLOAT) IS NOT NULL AND TRY_PARSE(PE.U_Manpower2 AS FLOAT) <> 0)
            AND (TRY_PARSE(TE.U_Manpower AS FLOAT) IS NULL OR TRY_PARSE(TE.U_Manpower AS FLOAT) = 0)
        )
        OR (
            (TRY_PARSE(PE.U_Backload2 AS FLOAT) IS NOT NULL AND TRY_PARSE(PE.U_Backload2 AS FLOAT) <> 0)
            AND (TRY_PARSE(TE.U_BackLoad AS FLOAT) IS NULL OR TRY_PARSE(TE.U_BackLoad AS FLOAT) = 0)
        )
        OR (
            (TRY_PARSE(PE.U_totalAddtlCharges2 AS FLOAT) IS NOT NULL AND TRY_PARSE(PE.U_totalAddtlCharges2 AS FLOAT) <> 0)
            AND (TRY_PARSE(TE.U_Addtlcharges AS FLOAT) IS NULL OR TRY_PARSE(TE.U_Addtlcharges AS FLOAT) = 0)
        )
        OR (
            (TRY_PARSE(PE.U_Demurrage3 AS FLOAT) IS NOT NULL AND TRY_PARSE(PE.U_Demurrage3 AS FLOAT) <> 0)
            AND (TRY_PARSE(TE.U_DemurrageN AS FLOAT) IS NULL OR TRY_PARSE(TE.U_DemurrageN AS FLOAT) = 0)
        )
        OR (
            (TRY_PARSE(PE.U_AddtlCharges AS FLOAT) IS NOT NULL AND TRY_PARSE(PE.U_AddtlCharges AS FLOAT) <> 0)
            AND (TRY_PARSE(TE.U_AddtlChargesN AS FLOAT) IS NULL OR TRY_PARSE(TE.U_AddtlChargesN AS FLOAT) = 0)
    ))
)