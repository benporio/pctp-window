SELECT
    SE.U_BookingNumber,
    CONCAT(
        CASE
            WHEN BE.U_BillingStatus <> SE.U_BillingStatus
                OR (
                    (BE.U_BillingStatus IS NOT NULL AND SE.U_BillingStatus IS NULL)
                    OR (SE.U_BillingStatus IS NOT NULL AND BE.U_BillingStatus IS NULL)
                ) THEN 'BillingStatus  '
            ELSE ''
        END,
        CASE
            WHEN BE.U_InvoiceNo <> SE.U_InvoiceNo
                OR (
                    (BE.U_InvoiceNo IS NOT NULL AND SE.U_InvoiceNo IS NULL)
                    OR (SE.U_InvoiceNo IS NOT NULL AND BE.U_InvoiceNo IS NULL)
                ) THEN 'SI #  '
            ELSE ''
        END,
        CASE
            WHEN BE.U_PODSONum <> SE.U_PODSONum
                OR (
                    (BE.U_PODSONum IS NOT NULL AND SE.U_PODSONum IS NULL)
                    OR (SE.U_PODSONum IS NOT NULL AND BE.U_PODSONum IS NULL)
                ) THEN 'SO #  '
            ELSE ''
        END,
        CASE
            WHEN BE.U_DocNum <> SE.U_ARDocNum
                OR (
                    (BE.U_DocNum IS NOT NULL AND SE.U_ARDocNum IS NULL)
                    OR (SE.U_ARDocNum IS NOT NULL AND BE.U_DocNum IS NULL)
                ) THEN 'AR #  '
            ELSE ''
        END
    ) AS Difference,
    BE.U_BillingStatus AS BE_BillingStatus,
    SE.U_BillingStatus AS SE_BillingStatus,
    (
        SELECT
            CASE WHEN EXISTS(
                SELECT TOP 1
                CASE 
                        WHEN EXISTS (
                            SELECT Code
                FROM [@BILLINGSTATUS]
                WHERE Code = header.U_BillingStatus
                        ) THEN header.U_BillingStatus
                        ELSE NULL 
                    END
            FROM OINV header
                LEFT JOIN INV1 line ON line.DocEntry = header.DocEntry
            WHERE line.ItemCode = T0.U_BookingId
                AND header.CANCELED = 'N'
                AND header.U_BillingStatus IS NOT NULL
            ) THEN (
                SELECT TOP 1
                CASE 
                        WHEN EXISTS (
                            SELECT Code
                FROM [@BILLINGSTATUS]
                WHERE Code = header.U_BillingStatus
                        ) THEN header.U_BillingStatus
                        ELSE NULL 
                    END
            FROM OINV header
                LEFT JOIN INV1 line ON line.DocEntry = header.DocEntry
            WHERE line.ItemCode = T0.U_BookingId
                AND header.CANCELED = 'N'
                AND header.U_BillingStatus IS NOT NULL
            ) ELSE T0.U_BillingStatus END AS U_BillingStatus
        FROM [dbo].[@PCTP_BILLING] T0  WITH (NOLOCK)
        WHERE T0.U_BookingId = SE.U_BookingNumber
    ) AS BILLING_BillingStatus,
    (
        SELECT
            CASE WHEN EXISTS(
                SELECT TOP 1
                CASE 
                        WHEN EXISTS (
                            SELECT Code
                FROM [@BILLINGSTATUS]
                WHERE Code = header.U_BillingStatus
                        ) THEN header.U_BillingStatus
                        ELSE NULL 
                    END
            FROM OINV header
                LEFT JOIN INV1 line ON line.DocEntry = header.DocEntry
            WHERE line.ItemCode = billing.U_BookingId
                AND header.CANCELED = 'N'
                AND header.U_BillingStatus IS NOT NULL
            ) THEN (
                SELECT TOP 1
                CASE 
                        WHEN EXISTS (
                            SELECT Code
                FROM [@BILLINGSTATUS]
                WHERE Code = header.U_BillingStatus
                        ) THEN header.U_BillingStatus
                        ELSE NULL 
                    END
            FROM OINV header
                LEFT JOIN INV1 line ON line.DocEntry = header.DocEntry
            WHERE line.ItemCode = billing.U_BookingId
                AND header.CANCELED = 'N'
                AND header.U_BillingStatus IS NOT NULL
            ) ELSE T0.U_BillingStatus END AS U_BillingStatus
        FROM [dbo].[@PCTP_POD] T0  WITH (NOLOCK)
        LEFT JOIN [dbo].[@PCTP_BILLING] billing ON T0.U_BookingNumber = billing.U_BookingId
        WHERE T0.U_BookingNumber = SE.U_BookingNumber
    ) AS SUMMARY_BillingStatus,
    BE.U_InvoiceNo AS BE_InvoiceNo,
    SE.U_InvoiceNo AS SE_InvoiceNo,
    BE.U_PODSONum AS BE_PODSONum,
    SE.U_PODSONum AS SE_PODSONum,
    BE.U_DocNum AS BE_DocNum,
    SE.U_ARDocNum AS SE_ARDocNum,
    (
        SELECT
            CAST((
                SELECT DISTINCT
                SUBSTRING(
                        (
                            SELECT CONCAT(', ', header.DocNum)  AS [text()]
                FROM INV1 line
                    LEFT JOIN OINV header ON header.DocEntry = line.DocEntry
                WHERE line.ItemCode = T0.U_BookingId
                    AND header.CANCELED = 'N'
                FOR XML PATH (''), TYPE
                        ).value('text()[1]','nvarchar(max)'), 2, 1000) DocEntry
            FROM OINV header
                LEFT JOIN INV1 line ON line.DocEntry = header.DocEntry
            WHERE line.ItemCode = T0.U_BookingId
                AND header.CANCELED = 'N') as nvarchar(max)
            ) AS U_DocNum
        FROM [dbo].[@PCTP_BILLING] T0  WITH (NOLOCK)
        WHERE T0.U_BookingId = SE.U_BookingNumber
    ) AS BILLING_DocNum,
    (
        SELECT
            CAST((
                SELECT DISTINCT
                SUBSTRING(
                        (
                            SELECT CONCAT(', ', header.DocNum)  AS [text()]
                FROM INV1 line
                    LEFT JOIN OINV header ON header.DocEntry = line.DocEntry
                WHERE line.ItemCode = T0.U_BookingNumber
                    AND header.CANCELED = 'N'
                FOR XML PATH (''), TYPE
                        ).value('text()[1]','nvarchar(max)'), 2, 1000) DocEntry
            FROM OINV header
                LEFT JOIN INV1 line ON line.DocEntry = header.DocEntry
            WHERE line.ItemCode = T0.U_BookingNumber
                AND header.CANCELED = 'N') as nvarchar(max)
            ) AS U_ARDocNum
        FROM [dbo].[@PCTP_POD] T0  WITH (NOLOCK)
        WHERE T0.U_BookingNumber = SE.U_BookingNumber
    ) AS SUMMARY_ARDocNum
FROM SUMMARY_EXTRACT SE
LEFT JOIN BILLING_EXTRACT BE ON BE.U_BookingId = SE.U_BookingNumber
WHERE (
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
OR BE.U_InvoiceNo <> SE.U_InvoiceNo
OR BE.U_PODSONum <> SE.U_PODSONum
OR BE.U_DocNum <> SE.U_ARDocNum
ORDER BY SE.U_BookingNumber DESC


-----> OTHER FIXES FOR REMAINING DATA ISSUE
DROP TABLE IF EXISTS TMP_TARGET_ISSUE20;
SELECT
    SE.U_BookingNumber,
    CONCAT(
        CASE
            WHEN BE.U_BillingStatus <> SE.U_BillingStatus
                OR (
                    (BE.U_BillingStatus IS NOT NULL AND SE.U_BillingStatus IS NULL)
                    OR (SE.U_BillingStatus IS NOT NULL AND BE.U_BillingStatus IS NULL)
                ) THEN 'BillingStatus  '
            ELSE ''
        END,
        CASE
            WHEN BE.U_InvoiceNo <> SE.U_InvoiceNo
                OR (
                    (BE.U_InvoiceNo IS NOT NULL AND SE.U_InvoiceNo IS NULL)
                    OR (SE.U_InvoiceNo IS NOT NULL AND BE.U_InvoiceNo IS NULL)
                ) THEN 'SI #  '
            ELSE ''
        END,
        CASE
            WHEN BE.U_PODSONum <> SE.U_PODSONum
                OR (
                    (BE.U_PODSONum IS NOT NULL AND SE.U_PODSONum IS NULL)
                    OR (SE.U_PODSONum IS NOT NULL AND BE.U_PODSONum IS NULL)
                ) THEN 'SO #  '
            ELSE ''
        END,
        CASE
            WHEN BE.U_DocNum <> SE.U_ARDocNum
                OR (
                    (BE.U_DocNum IS NOT NULL AND SE.U_ARDocNum IS NULL)
                    OR (SE.U_ARDocNum IS NOT NULL AND BE.U_DocNum IS NULL)
                ) THEN 'AR #  '
            ELSE ''
        END
    ) AS Difference,
    BE.U_BillingStatus AS BE_BillingStatus,
    SE.U_BillingStatus AS SE_BillingStatus,
    (
        SELECT
            CASE WHEN EXISTS(
                SELECT TOP 1
                CASE 
                        WHEN EXISTS (
                            SELECT Code
                FROM [@BILLINGSTATUS]
                WHERE Code = header.U_BillingStatus
                        ) THEN header.U_BillingStatus
                        ELSE NULL 
                    END
            FROM OINV header
                LEFT JOIN INV1 line ON line.DocEntry = header.DocEntry
            WHERE line.ItemCode = T0.U_BookingId
                AND header.CANCELED = 'N'
                AND header.U_BillingStatus IS NOT NULL
            ) THEN (
                SELECT TOP 1
                CASE 
                        WHEN EXISTS (
                            SELECT Code
                FROM [@BILLINGSTATUS]
                WHERE Code = header.U_BillingStatus
                        ) THEN header.U_BillingStatus
                        ELSE NULL 
                    END
            FROM OINV header
                LEFT JOIN INV1 line ON line.DocEntry = header.DocEntry
            WHERE line.ItemCode = T0.U_BookingId
                AND header.CANCELED = 'N'
                AND header.U_BillingStatus IS NOT NULL
            ) ELSE T0.U_BillingStatus END AS U_BillingStatus
        FROM [dbo].[@PCTP_BILLING] T0  WITH (NOLOCK)
        WHERE T0.U_BookingId = SE.U_BookingNumber
    ) AS BILLING_BillingStatus,
    (
        SELECT
            CASE WHEN EXISTS(
                SELECT TOP 1
                CASE 
                        WHEN EXISTS (
                            SELECT Code
                FROM [@BILLINGSTATUS]
                WHERE Code = header.U_BillingStatus
                        ) THEN header.U_BillingStatus
                        ELSE NULL 
                    END
            FROM OINV header
                LEFT JOIN INV1 line ON line.DocEntry = header.DocEntry
            WHERE line.ItemCode = billing.U_BookingId
                AND header.CANCELED = 'N'
                AND header.U_BillingStatus IS NOT NULL
            ) THEN (
                SELECT TOP 1
                CASE 
                        WHEN EXISTS (
                            SELECT Code
                FROM [@BILLINGSTATUS]
                WHERE Code = header.U_BillingStatus
                        ) THEN header.U_BillingStatus
                        ELSE NULL 
                    END
            FROM OINV header
                LEFT JOIN INV1 line ON line.DocEntry = header.DocEntry
            WHERE line.ItemCode = billing.U_BookingId
                AND header.CANCELED = 'N'
                AND header.U_BillingStatus IS NOT NULL
            ) ELSE T0.U_BillingStatus END AS U_BillingStatus
        FROM [dbo].[@PCTP_POD] T0  WITH (NOLOCK)
        LEFT JOIN [dbo].[@PCTP_BILLING] billing ON T0.U_BookingNumber = billing.U_BookingId
        WHERE T0.U_BookingNumber = SE.U_BookingNumber
    ) AS SUMMARY_BillingStatus,
    BE.U_InvoiceNo AS BE_InvoiceNo,
    SE.U_InvoiceNo AS SE_InvoiceNo,
    BE.U_PODSONum AS BE_PODSONum,
    SE.U_PODSONum AS SE_PODSONum,
    BE.U_DocNum AS BE_DocNum,
    SE.U_ARDocNum AS SE_ARDocNum,
    (
        SELECT
            CAST((
                SELECT DISTINCT
                SUBSTRING(
                        (
                            SELECT CONCAT(', ', header.DocNum)  AS [text()]
                FROM INV1 line
                    LEFT JOIN OINV header ON header.DocEntry = line.DocEntry
                WHERE line.ItemCode = T0.U_BookingId
                    AND header.CANCELED = 'N'
                FOR XML PATH (''), TYPE
                        ).value('text()[1]','nvarchar(max)'), 2, 1000) DocEntry
            FROM OINV header
                LEFT JOIN INV1 line ON line.DocEntry = header.DocEntry
            WHERE line.ItemCode = T0.U_BookingId
                AND header.CANCELED = 'N') as nvarchar(max)
            ) AS U_DocNum
        FROM [dbo].[@PCTP_BILLING] T0  WITH (NOLOCK)
        WHERE T0.U_BookingId = SE.U_BookingNumber
    ) AS BILLING_DocNum,
    (
        SELECT
            CAST((
                SELECT DISTINCT
                SUBSTRING(
                        (
                            SELECT CONCAT(', ', header.DocNum)  AS [text()]
                FROM INV1 line
                    LEFT JOIN OINV header ON header.DocEntry = line.DocEntry
                WHERE line.ItemCode = T0.U_BookingNumber
                    AND header.CANCELED = 'N'
                FOR XML PATH (''), TYPE
                        ).value('text()[1]','nvarchar(max)'), 2, 1000) DocEntry
            FROM OINV header
                LEFT JOIN INV1 line ON line.DocEntry = header.DocEntry
            WHERE line.ItemCode = T0.U_BookingNumber
                AND header.CANCELED = 'N') as nvarchar(max)
            ) AS U_ARDocNum
        FROM [dbo].[@PCTP_POD] T0  WITH (NOLOCK)
        WHERE T0.U_BookingNumber = SE.U_BookingNumber
    ) AS SUMMARY_ARDocNum
INTO TMP_TARGET_ISSUE20 
FROM SUMMARY_EXTRACT SE
LEFT JOIN BILLING_EXTRACT BE ON BE.U_BookingId = SE.U_BookingNumber
WHERE (
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
OR BE.U_InvoiceNo <> SE.U_InvoiceNo
OR BE.U_PODSONum <> SE.U_PODSONum
OR BE.U_DocNum <> SE.U_ARDocNum;

UPDATE [@PCTP_BILLING] 
SET U_BillingStatus = TMP.SE_BillingStatus
FROM TMP_TARGET_ISSUE20 TMP
WHERE TMP.U_BookingNumber = [@PCTP_BILLING].U_BookingId
AND TMP.SE_BillingStatus IN ('SenttoBT', 'Sent to BT')
AND TMP.SUMMARY_BillingStatus IN ('SenttoBT', 'Sent to BT')
AND (TMP.BE_BillingStatus IS NULL OR REPLACE(TMP.BE_BillingStatus, ' ', '') = '')
-- AND (TMP.BILLING_BillingStatus IS NULL OR REPLACE(TMP.BILLING_BillingStatus, ' ', '') = '')
;

UPDATE BILLING_EXTRACT
SET U_BillingStatus = TMP.SE_BillingStatus
FROM TMP_TARGET_ISSUE20 TMP
WHERE TMP.U_BookingNumber = BILLING_EXTRACT.U_BookingId
AND TMP.SE_BillingStatus IN ('SenttoBT', 'Sent to BT')
AND TMP.SUMMARY_BillingStatus IN ('SenttoBT', 'Sent to BT')
AND (TMP.BE_BillingStatus IS NULL OR REPLACE(TMP.BE_BillingStatus, ' ', '') = '')
-- AND (TMP.BILLING_BillingStatus IS NULL OR REPLACE(TMP.BILLING_BillingStatus, ' ', '') = '')
;

UPDATE [@PCTP_POD] 
SET U_BillingStatus = TMP.BE_BillingStatus
FROM TMP_TARGET_ISSUE20 TMP
WHERE TMP.U_BookingNumber = [@PCTP_POD].U_BookingNumber
AND TMP.BE_BillingStatus IN ('SenttoBT', 'Sent to BT')
AND TMP.BILLING_BillingStatus IN ('SenttoBT', 'Sent to BT')
AND (TMP.SE_BillingStatus IS NULL OR REPLACE(TMP.SE_BillingStatus, ' ', '') = '')
-- AND (TMP.SUMMARY_BillingStatus IS NULL OR REPLACE(TMP.SUMMARY_BillingStatus, ' ', '') = '')
;

UPDATE POD_EXTRACT
SET U_BillingStatus = TMP.BE_BillingStatus
FROM TMP_TARGET_ISSUE20 TMP
WHERE TMP.U_BookingNumber = POD_EXTRACT.U_BookingNumber
AND TMP.BE_BillingStatus IN ('SenttoBT', 'Sent to BT')
AND TMP.BILLING_BillingStatus IN ('SenttoBT', 'Sent to BT')
AND (TMP.SE_BillingStatus IS NULL OR REPLACE(TMP.SE_BillingStatus, ' ', '') = '')
-- AND (TMP.SUMMARY_BillingStatus IS NULL OR REPLACE(TMP.SUMMARY_BillingStatus, ' ', '') = '')
;

UPDATE SUMMARY_EXTRACT
SET U_BillingStatus = TMP.BE_BillingStatus
FROM TMP_TARGET_ISSUE20 TMP
WHERE TMP.U_BookingNumber = SUMMARY_EXTRACT.U_BookingNumber
AND TMP.BE_BillingStatus IN ('SenttoBT', 'Sent to BT')
AND TMP.BILLING_BillingStatus IN ('SenttoBT', 'Sent to BT')
AND (TMP.SE_BillingStatus IS NULL OR REPLACE(TMP.SE_BillingStatus, ' ', '') = '')
-- AND (TMP.SUMMARY_BillingStatus IS NULL OR REPLACE(TMP.SUMMARY_BillingStatus, ' ', '') = '')
;

DROP TABLE IF EXISTS TMP_TARGET_ISSUE20;