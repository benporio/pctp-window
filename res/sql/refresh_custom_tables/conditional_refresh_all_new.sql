DROP TABLE IF EXISTS TMP_TARGET_$serial
SELECT
*
INTO TMP_TARGET_$serial 
FROM (
    -----> issue #30
	SELECT DISTINCT 
		BILLING.U_BookingId AS U_BookingNumber,
        'SO-RELATED-BN' AS ISSUE
	FROM [@PCTP_BILLING] BILLING WITH(NOLOCK)
	-- LEFT JOIN [@PCTP_POD] POD ON POD.U_BookingNumber = BILLING.U_BookingId
	WHERE EXISTS(
		SELECT
			1
		FROM ORDR header WITH(NOLOCK)
			LEFT JOIN RDR1 line ON line.DocEntry = header.DocEntry
		WHERE line.ItemCode = BILLING.U_BookingId
			AND header.CANCELED = 'N'
			AND header.DocNum IN (3698)
	)
	UNION
    -----> issue #20
    SELECT
        SE.U_BookingNumber,
        'SUMMARY-BILLING-DATA-INCONSISTENCY' AS ISSUE
    FROM SUMMARY_EXTRACT SE WITH(NOLOCK)
    LEFT JOIN BILLING_EXTRACT BE ON BE.U_BookingId = SE.U_BookingNumber
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
	-- OR BE.U_InvoiceNo <> SE.U_InvoiceNo
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
	-- OR BE.U_PODSONum <> SE.U_PODSONum
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
	AND BE.U_BookingId IS NOT NULL
	--AND SE.U_BookingDate >= '2023-07-01'
	--AND SE.U_BookingDate <= '2023-08-30'

    UNION
    -----> issue #22
    SELECT
        T0.U_BookingNumber,
        'TP-BILLING-VERIFIED-NOT-REFLECTED' AS ISSUE
    FROM [dbo].[@PCTP_POD] T0 WITH(NOLOCK)
    WHERE 1=1
    AND (CAST(T0.U_PODStatusDetail as nvarchar(max)) LIKE '%Verified%' OR CAST(T0.U_PODStatusDetail as nvarchar(max)) LIKE '%ForAdvanceBilling%')
    AND T0.U_BookingNumber NOT IN (SELECT U_BookingId FROM BILLING_EXTRACT WITH(NOLOCK))
    UNION
    SELECT
        T0.U_BookingNumber,
        'TP-BILLING-VERIFIED-NOT-REFLECTED' AS ISSUE
    FROM [dbo].[@PCTP_POD] T0 WITH(NOLOCK)
    WHERE 1=1
    AND (CAST(T0.U_PODStatusDetail as nvarchar(max)) LIKE '%Verified%')
    AND T0.U_BookingNumber NOT IN (SELECT U_BookingId FROM TP_EXTRACT WITH(NOLOCK))

    UNION
    -----> issue #23
    SELECT
        BE.U_BookingId AS U_BookingNumber,
        'BILLING-TP-PRICING-DATA-INCONSISTENCY' AS ISSUE
    FROM BILLING_EXTRACT BE WITH(NOLOCK)
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
    FROM TP_EXTRACT TE WITH(NOLOCK)
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

    UNION
    -----> issue #27
    SELECT 
        U_BookingNumber,
        'DUPLICATE' AS ISSUE 
    FROM SUMMARY_EXTRACT WITH(NOLOCK) GROUP BY U_BookingNumber HAVING COUNT(*) > 1
    UNION
    SELECT 
        U_BookingNumber,
        'DUPLICATE' AS ISSUE 
    FROM POD_EXTRACT WITH(NOLOCK) GROUP BY U_BookingNumber HAVING COUNT(*) > 1
    UNION
    SELECT 
        U_BookingNumber,
        'DUPLICATE' AS ISSUE 
    FROM BILLING_EXTRACT WITH(NOLOCK) GROUP BY U_BookingNumber HAVING COUNT(*) > 1
    UNION
    SELECT 
        U_BookingNumber,
        'DUPLICATE' AS ISSUE 
    FROM TP_EXTRACT WITH(NOLOCK) GROUP BY U_BookingNumber HAVING COUNT(*) > 1
    UNION
    SELECT 
        U_BookingNumber,
        'DUPLICATE' AS ISSUE 
    FROM PRICING_EXTRACT WITH(NOLOCK) GROUP BY U_BookingNumber HAVING COUNT(*) > 1
    
) CONDITIONAL_TARGETS
-- LEFT JOIN (SELECT U_BookingNumber, U_BookingDate FROM [@PCTP_POD]) X ON X.U_BookingNumber = CONDITIONAL_TARGETS.U_BookingNumber
WHERE U_BookingNumber IS NOT NULL
-- ORDER BY U_BookingDate DESC, ISSUE ASC
;

UPDATE [@FirstratesTP] 
SET U_Amount = NULL
WHERE U_Amount = 'NaN' AND U_BN IN (SELECT U_BookingNumber FROM TMP_TARGET_$serial WITH (NOLOCK));

UPDATE [@FirstratesTP] 
SET U_AddlAmount = NULL
WHERE U_AddlAmount = 'NaN' AND U_BN IN (SELECT U_BookingNumber FROM TMP_TARGET_$serial WITH (NOLOCK));

DECLARE @BookingIdsCSV NVARCHAR(MAX);
SET @BookingIdsCSV = SUBSTRING((
    SELECT  
        CONCAT(', ', U_BookingNumber) AS [text()]
    FROM TMP_TARGET_$serial WITH (NOLOCK)
    FOR XML PATH (''), TYPE).value('text()[1]','nvarchar(max)'), 2, 10000000
);

DELETE FROM PCTP_UNIFIED WHERE U_BookingNumber IN ($bookingIds);

INSERT INTO PCTP_UNIFIED
SELECT *
FROM [dbo].fetchGenericPctpDataRows(@BookingIdsCSV) X;