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


SELECT
    TP.U_BookingNumber AS id,
    CONCAT('AP', head.DocNum, '-', FORMAT(head.UpdateDate, 'yyyyMMdd'), head.UpdateTS) AS serial
FROM (
SELECT DocEntry, DocNum, U_PVNo, UpdateDate, UpdateTS
FROM OPCH WITH(NOLOCK)
WHERE CAST(CreateDate AS date) = CAST(GETDATE() AS date)
OR CAST(UpdateDate AS date) = CAST(GETDATE() AS date)
) head
LEFT JOIN (
    SELECT DocEntry, ItemCode
    FROM PCH1 WITH(NOLOCK)
) line ON head.DocEntry = line.DocEntry
LEFT JOIN (
SELECT U_BookingId AS U_BookingNumber, U_PVNo
FROM [@PCTP_TP] WITH(NOLOCK)
) TP ON 1 = CASE
    WHEN TP.U_PVNo = head.U_PVNo THEN 1
    WHEN head.U_PVNo IN (
        SELECT 
            RTRIM(LTRIM(value))
        FROM STRING_SPLIT(TP.U_PVNo, ',')
    ) THEN 1
    WHEN TP.U_PVNo IN (
        SELECT 
            RTRIM(LTRIM(value))
        FROM STRING_SPLIT(head.U_PVNo, ',')
    ) THEN 1
    ELSE 0
END OR TP.U_BookingNumber = line.ItemCode
WHERE TP.U_BookingNumber IS NOT NULL

UNION

SELECT
    line.ItemCode AS id,
    CONCAT('SO', head.DocNum, '-', FORMAT(head.UpdateDate, 'yyyyMMdd'), head.UpdateTS) AS serial
FROM (
SELECT DocEntry, DocNum, UpdateDate, UpdateTS
FROM ORDR WITH(NOLOCK)
WHERE CAST(CreateDate AS date) = CAST(GETDATE() AS date)
OR CAST(UpdateDate AS date) = CAST(GETDATE() AS date)
) head
LEFT JOIN (
    SELECT DocEntry, ItemCode
    FROM RDR1 WITH(NOLOCK)
) line ON head.DocEntry = line.DocEntry
WHERE line.ItemCode IS NOT NULL

UNION

SELECT
    line.ItemCode AS id,
    CONCAT('AR', head.DocNum, '-', FORMAT(head.UpdateDate, 'yyyyMMdd'), head.UpdateTS) AS serial
FROM (
SELECT DocEntry, DocNum, UpdateDate, UpdateTS
FROM OINV WITH(NOLOCK)
WHERE CAST(CreateDate AS date) = CAST(GETDATE() AS date)
OR CAST(UpdateDate AS date) = CAST(GETDATE() AS date)
) head
LEFT JOIN (
    SELECT DocEntry, ItemCode
    FROM INV1 WITH(NOLOCK)
) line ON head.DocEntry = line.DocEntry
WHERE line.ItemCode IS NOT NULL

UNION

SELECT 
    head.ItemCode AS id,
    CONCAT('BN-', FORMAT(head.CreateDate, 'yyyyMMdd'), head.CreateTS) AS serial
FROM (
    SELECT ItemCode, CreateDate, CreateTS
    FROM OITM WITH(NOLOCK) 
) head
WHERE head.ItemCode IS NOT NULL
AND CAST(head.CreateDate AS date) = CAST(GETDATE() AS date)
AND (
    EXISTS(SELECT 1 FROM [@PCTP_POD] WITH(NOLOCK) WHERE U_BookingNumber = head.ItemCode)
    OR EXISTS(SELECT 1 FROM [@PCTP_PRICING] WITH(NOLOCK) WHERE U_BookingId = head.ItemCode)
)
AND (
    NOT EXISTS(SELECT 1 FROM SUMMARY_EXTRACT WITH(NOLOCK) WHERE U_BookingNumber = head.ItemCode)
    OR NOT EXISTS(SELECT 1 FROM POD_EXTRACT WITH(NOLOCK) WHERE U_BookingNumber = head.ItemCode)
    OR NOT EXISTS(SELECT 1 FROM BILLING_EXTRACT WITH(NOLOCK) WHERE U_BookingId = head.ItemCode)
    OR NOT EXISTS(SELECT 1 FROM TP_EXTRACT WITH(NOLOCK) WHERE U_BookingId = head.ItemCode)
    OR NOT EXISTS(SELECT 1 FROM PRICING_EXTRACT WITH(NOLOCK) WHERE U_BookingId = head.ItemCode)
)

UNION

SELECT Z.id, Z.serial FROM (
    SELECT 
        U_BookingNumber AS id,
        CONCAT('DUP-', FORMAT(GETDATE(), 'yyyyMMddhhmmss')) AS serial
    FROM SUMMARY_EXTRACT WITH(NOLOCK) GROUP BY U_BookingNumber HAVING COUNT(*) > 1
    UNION
    SELECT 
        U_BookingNumber AS id,
        CONCAT('DUP-', FORMAT(GETDATE(), 'yyyyMMddhhmmss')) AS serial
    FROM POD_EXTRACT WITH(NOLOCK) GROUP BY U_BookingNumber HAVING COUNT(*) > 1
    UNION
    SELECT 
        U_BookingNumber AS id,
        CONCAT('DUP-', FORMAT(GETDATE(), 'yyyyMMddhhmmss')) AS serial
    FROM BILLING_EXTRACT WITH(NOLOCK) GROUP BY U_BookingNumber HAVING COUNT(*) > 1
    UNION
    SELECT 
        U_BookingNumber AS id,
        CONCAT('DUP-', FORMAT(GETDATE(), 'yyyyMMddhhmmss')) AS serial
    FROM TP_EXTRACT WITH(NOLOCK) GROUP BY U_BookingNumber HAVING COUNT(*) > 1
    UNION
    SELECT 
        U_BookingNumber AS id,
        CONCAT('DUP-', FORMAT(GETDATE(), 'yyyyMMddhhmmss')) AS serial
    FROM PRICING_EXTRACT WITH(NOLOCK) GROUP BY U_BookingNumber HAVING COUNT(*) > 1
) Z
LEFT JOIN
(
    SELECT X.id,
    CONCAT(CASE
            WHEN (SELECT COUNT(*) FROM [@PCTP_POD] WITH(NOLOCK) WHERE U_BookingNumber = X.id) > 1 THEN 'POD '
            ELSE ''
        END,
        CASE
            WHEN (SELECT COUNT(*) FROM [@PCTP_BILLING] WITH(NOLOCK) WHERE U_BookingId = X.id) > 1 THEN 'BILLING '
            ELSE ''
        END,
        CASE
            WHEN (SELECT COUNT(*) FROM [@PCTP_TP] WITH(NOLOCK) WHERE U_BookingId = X.id) > 1 THEN 'TP '
            ELSE ''
        END,
        CASE
            WHEN (SELECT COUNT(*) FROM [@PCTP_PRICING] WITH(NOLOCK) WHERE U_BookingId = X.id) > 1 THEN 'PRICING '
            ELSE ''
        END) AS DuplicateInMainTable
    FROM (SELECT 
            U_BookingNumber as id
        FROM SUMMARY_EXTRACT WITH(NOLOCK) GROUP BY U_BookingNumber HAVING COUNT(*) > 1
        UNION
        SELECT 
            U_BookingNumber as id
        FROM POD_EXTRACT WITH(NOLOCK) GROUP BY U_BookingNumber HAVING COUNT(*) > 1
        UNION
        SELECT 
            U_BookingNumber as id
        FROM BILLING_EXTRACT WITH(NOLOCK) GROUP BY U_BookingNumber HAVING COUNT(*) > 1
        UNION
        SELECT 
            U_BookingNumber as id
        FROM TP_EXTRACT WITH(NOLOCK) GROUP BY U_BookingNumber HAVING COUNT(*) > 1
        UNION
        SELECT 
            U_BookingNumber as id
        FROM PRICING_EXTRACT WITH(NOLOCK) GROUP BY U_BookingNumber HAVING COUNT(*) > 1
    ) X
    WHERE X.id IS NOT NULL
) Y ON Z.id = Y.id
WHERE Y.id IS NOT NULL 
AND (
    Y.DuplicateInMainTable = '' 
    OR Y.DuplicateInMainTable IS NULL
)

UNION

SELECT
    SE.U_BookingNumber as id,
    CONCAT('SBDI-', FORMAT(GETDATE(), 'yyyyMMddhhmmss')) AS serial
FROM (
    SELECT U_BookingNumber, U_BillingStatus, U_InvoiceNo, U_PODSONum, U_ARDocNum
    FROM SUMMARY_EXTRACT WITH(NOLOCK)
) SE
LEFT JOIN (
    SELECT U_BookingId, U_BillingStatus, U_InvoiceNo, U_PODSONum, U_DocNum
    FROM BILLING_EXTRACT WITH(NOLOCK)
) BE ON BE.U_BookingId = SE.U_BookingNumber
WHERE ((
    (BE.U_BillingStatus <> SE.U_BillingStatus AND REPLACE(BE.U_BillingStatus, ' ', '') <> REPLACE(SE.U_BillingStatus, ' ', '')) 
    OR (
        (
            BE.U_BillingStatus IS NOT NULL AND REPLACE(BE.U_BillingStatus, ' ', '') <> '' 
            AND (SE.U_BillingStatus IS NULL OR REPLACE(SE.U_BillingStatus, ' ', '') = '')
        )
        OR (
            SE.U_BillingStatus IS NOT NULL AND REPLACE(SE.U_BillingStatus, ' ', '') <> '' 
            AND (BE.U_BillingStatus IS NULL OR REPLACE(BE.U_BillingStatus, ' ', '') = '')
        )
    )
)
OR (
    (BE.U_InvoiceNo <> SE.U_InvoiceNo AND REPLACE(BE.U_InvoiceNo, ' ', '') <> REPLACE(SE.U_InvoiceNo, ' ', '')) 
    OR (
        (
            BE.U_InvoiceNo IS NOT NULL AND REPLACE(BE.U_InvoiceNo, ' ', '') <> '' 
            AND (SE.U_InvoiceNo IS NULL OR REPLACE(SE.U_InvoiceNo, ' ', '') = '')
        )
        OR (
            SE.U_InvoiceNo IS NOT NULL AND REPLACE(SE.U_InvoiceNo, ' ', '') <> '' 
            AND (BE.U_InvoiceNo IS NULL OR REPLACE(BE.U_InvoiceNo, ' ', '') = '')
        )
    )
)
OR (
    (BE.U_PODSONum <> SE.U_PODSONum AND REPLACE(BE.U_PODSONum, ' ', '') <> REPLACE(SE.U_PODSONum, ' ', '')) 
    OR (
        (
            BE.U_PODSONum IS NOT NULL AND REPLACE(BE.U_PODSONum, ' ', '') <> '' 
            AND (SE.U_PODSONum IS NULL OR REPLACE(SE.U_PODSONum, ' ', '') = '')
        )
        OR (
            SE.U_PODSONum IS NOT NULL AND REPLACE(SE.U_PODSONum, ' ', '') <> '' 
            AND (BE.U_PODSONum IS NULL OR REPLACE(BE.U_PODSONum, ' ', '') = '')
        )
    )
)
OR (
    (BE.U_DocNum <> SE.U_ARDocNum AND REPLACE(BE.U_DocNum, ' ', '') <> REPLACE(SE.U_ARDocNum, ' ', '')) 
    OR (
        (
            BE.U_DocNum IS NOT NULL AND REPLACE(BE.U_DocNum, ' ', '') <> '' 
            AND (SE.U_ARDocNum IS NULL OR REPLACE(SE.U_ARDocNum, ' ', '') = '')
        )
        OR (
            SE.U_ARDocNum IS NOT NULL AND REPLACE(SE.U_ARDocNum, ' ', '') <> '' 
            AND (BE.U_DocNum IS NULL OR REPLACE(BE.U_DocNum, ' ', '') = '')
        )
    )
))
AND BE.U_BookingId IS NOT NULL AND SE.U_BookingNumber IS NOT NULL

UNION

SELECT
    T0.U_BookingNumber as id,
    CONCAT('B-TBVNR-', FORMAT(GETDATE(), 'yyyyMMddhhmmss')) AS serial
FROM (
    SELECT U_BookingNumber, U_PODStatusDetail
    FROM [dbo].[@PCTP_POD] WITH(NOLOCK)
) T0
WHERE 1=1
AND (CAST(T0.U_PODStatusDetail as nvarchar(100)) LIKE '%Verified%' OR CAST(T0.U_PODStatusDetail as nvarchar(100)) LIKE '%ForAdvanceBilling%')
AND T0.U_BookingNumber NOT IN (SELECT U_BookingId FROM BILLING_EXTRACT WITH(NOLOCK))
                                    AND T0.U_BookingNumber IN (SELECT U_BookingId FROM [dbo].[@PCTP_BILLING] WITH(NOLOCK) WHERE U_BookingId IS NOT NULL)
AND T0.U_BookingNumber IS NOT NULL

UNION

SELECT
    T0.U_BookingNumber as id,
    CONCAT('T-TBVNR-', FORMAT(GETDATE(), 'yyyyMMddhhmmss')) AS serial
FROM [dbo].[@PCTP_POD] T0 WITH(NOLOCK)
WHERE 1=1
AND (CAST(T0.U_PODStatusDetail as nvarchar(100)) LIKE '%Verified%')
AND T0.U_BookingNumber NOT IN (SELECT U_BookingId FROM TP_EXTRACT WITH(NOLOCK) WHERE U_BookingId IS NOT NULL)
AND T0.U_BookingNumber IN (SELECT U_BookingId FROM [dbo].[@PCTP_TP] WITH(NOLOCK) WHERE U_BookingId IS NOT NULL)
AND T0.U_BookingNumber IS NOT NULL

UNION

SELECT
    BE.U_BookingId AS id,
    CONCAT('B-BTPDI-', FORMAT(GETDATE(), 'yyyyMMddhhmmss')) AS serial
FROM (
    SELECT U_BookingId, U_GrossInitialRate, U_Demurrage, U_AddCharges
    FROM BILLING_EXTRACT WITH(NOLOCK)
) BE
LEFT JOIN (
    SELECT U_BookingId, U_GrossClientRatesTax, U_Demurrage, U_TotalAddtlCharges
    FROM PRICING_EXTRACT WITH(NOLOCK)
) PE ON PE.U_BookingId = BE.U_BookingId
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
) AND PE.U_BookingId IS NOT NULL AND BE.U_BookingId IS NOT NULL

UNION

SELECT
    TE.U_BookingId AS id,
    CONCAT('T-BTPDI-', FORMAT(GETDATE(), 'yyyyMMddhhmmss')) AS serial
FROM (
    SELECT U_BookingId, U_GrossTruckerRates, U_GrossTruckerRatesN, U_RateBasis, U_Demurrage,
    U_AddtlDrop, U_BoomTruck, U_Manpower, U_BackLoad, U_Addtlcharges, U_DemurrageN, U_AddtlChargesN
    FROM TP_EXTRACT WITH(NOLOCK)
) TE
LEFT JOIN (
    SELECT U_BookingId, U_GrossTruckerRates, U_GrossTruckerRatesTax, U_RateBasisT, U_Demurrage2,
    U_AddtlDrop2, U_BoomTruck2, U_Manpower2, U_Backload2, U_totalAddtlCharges2, U_Demurrage3, U_AddtlCharges
    FROM PRICING_EXTRACT WITH(NOLOCK)
) PE ON PE.U_BookingId = TE.U_BookingId
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
) AND PE.U_BookingId IS NOT NULL AND TE.U_BookingId IS NOT NULL

UNION

SELECT
    POD.U_BookingNumber as id,
    CONCAT('PTF-', FORMAT(GETDATE(), 'yyyyMMddhhmmss')) AS serial
FROM (
    SELECT U_BookingNumber, U_PTFNo
    FROM [dbo].[@PCTP_POD] WITH(NOLOCK)
) POD
WHERE POD.U_PTFNo IS NOT NULL AND POD.U_PTFNo <> ''
AND POD.U_BookingNumber IN (
    SELECT U_BookingNumber 
    FROM POD_EXTRACT WITH(NOLOCK)
    WHERE U_BookingNumber IS NOT NULL AND (U_PTFNo IS NULL OR U_PTFNo = '')
) AND POD.U_BookingNumber IS NOT NULL