SELECT
    BE.U_BookingId,
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
WHERE (BE.U_BillingStatus <> SE.U_BillingStatus AND REPLACE(BE.U_BillingStatus, ' ', '') <> REPLACE(SE.U_BillingStatus, ' ', ''))
OR BE.U_InvoiceNo <> SE.U_InvoiceNo
OR BE.U_PODSONum <> SE.U_PODSONum
OR BE.U_DocNum <> SE.U_ARDocNum
ORDER BY BE.U_BookingId DESC