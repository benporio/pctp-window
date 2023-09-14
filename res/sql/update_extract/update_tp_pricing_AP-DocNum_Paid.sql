-------->>CREATING TARGETS

DROP TABLE IF EXISTS TMP_TARGET_20230912
SELECT
    POD.U_BookingNumber,
    CAST(SUBSTRING(
            (
                SELECT DISTINCT CONCAT(', ', header.DocNum)  AS [text()]
    FROM PCH1 line WITH (NOLOCK)
        LEFT JOIN (SELECT DocNum, DocEntry, CANCELED, PaidSum, U_PVNo FROM OPCH WITH (NOLOCK)) header ON header.DocEntry = line.DocEntry
    WHERE header.CANCELED = 'N' AND header.PaidSum = 0 AND (line.ItemCode = T0.U_BookingId
        or REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%')
    FOR XML PATH (''), TYPE
            ).value('text()[1]','nvarchar(max)'), 2, 1000) as nvarchar(max)) AS U_DocNum,
    CAST(SUBSTRING(
            (
                SELECT DISTINCT CONCAT(', ', header.DocNum)  AS [text()]
    FROM PCH1 line WITH (NOLOCK)
        LEFT JOIN (SELECT DocNum, DocEntry, CANCELED, PaidSum, U_PVNo FROM OPCH WITH (NOLOCK)) header ON header.DocEntry = line.DocEntry
    WHERE header.CANCELED = 'N' AND header.PaidSum > 0 AND (line.ItemCode = T0.U_BookingId
        or REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%')
    FOR XML PATH (''), TYPE
            ).value('text()[1]','nvarchar(max)'), 2, 1000) as nvarchar(max)) As U_Paid
INTO TMP_TARGET_20230912
FROM [dbo].[@PCTP_TP] T0 WITH (NOLOCK)
    INNER JOIN (SELECT U_BookingNumber, U_BookingDate, U_PODStatusDetail FROM [dbo].[@PCTP_POD] WITH(NOLOCK)) POD ON T0.U_BookingId = POD.U_BookingNumber AND CAST(POD.U_PODStatusDetail as nvarchar(max)) LIKE '%Verified%'

-------->>SUMMARY_EXTRACT

UPDATE SUMMARY_EXTRACT
SET U_APDocNum = CASE 
                    WHEN TMP.U_DocNum IS NULL OR TMP.U_DocNum = '' THEN TMP.U_Paid
                    ELSE 
                        CASE 
                            WHEN TMP.U_Paid IS NULL OR TMP.U_Paid = '' THEN TMP.U_DocNum 
                            ELSE CONCAT(TMP.U_DocNum, ', ', TMP.U_Paid)
                        END
                END
FROM TMP_TARGET_20230912 TMP
WHERE TMP.U_BookingNumber = SUMMARY_EXTRACT.U_BookingNumber;

-------->>TP_EXTRACT

UPDATE TP_EXTRACT
SET U_DocNum = TMP.U_DocNum,
    U_Paid = TMP.U_Paid,
    U_ORRefNo = SUBSTRING((
                    SELECT
                        CONCAT(', ', T0.U_OR_Ref) AS [text()]
                    FROM OPCH T0 WITH (NOLOCK)
                    WHERE T0.Canceled <> 'Y' AND T0.DocNum IN (SELECT RTRIM(LTRIM(value)) AS DocNum FROM STRING_SPLIT(TMP.U_Paid, ','))
                    FOR XML PATH (''), TYPE).value('text()[1]','nvarchar(max)'), 2, 1000
                ),
    U_ActualPaymentDate = SUBSTRING((
                    SELECT
                        CONCAT(CASE WHEN T0.TrsfrDate IS NOT NULL THEN CONCAT(', ', CAST(T0.TrsfrDate AS DATE))
                        ELSE '' END,
                        CASE WHEN T2.DueDate IS NOT NULL THEN CONCAT(', ', CAST(T2.DueDate AS DATE))
                        ELSE '' END) AS [text()]
                    FROM OVPM T0 WITH (NOLOCK)
                    INNER JOIN VPM2 T1 ON T1.DocNum = T0.DocEntry
                    LEFT JOIN VPM1 T2 ON T1.DocNum = T2.DocNum
                    LEFT JOIN OPCH T3 ON T1.DocEntry = T3.DocEntry
                    WHERE T0.Canceled <> 'Y' AND T3.DocNum IN (SELECT RTRIM(LTRIM(value)) AS DocNum FROM STRING_SPLIT(TMP.U_Paid, ','))
                    FOR XML PATH (''), TYPE).value('text()[1]','nvarchar(max)'), 2, 1000
                ),
    U_PaymentReference = SUBSTRING((
                    SELECT
                        CONCAT(CASE WHEN T0.TrsfrRef IS NOT NULL THEN CONCAT(', ', T0.TrsfrRef)
                        ELSE '' END,
                        CASE WHEN T2.CheckNum IS NOT NULL THEN CONCAT(', ', T2.CheckNum)
                        ELSE '' END) AS [text()]
                    FROM OVPM T0 WITH (NOLOCK)
                    INNER JOIN VPM2 T1 ON T1.DocNum = T0.DocEntry
                    LEFT JOIN VPM1 T2 ON T1.DocNum = T2.DocNum
                    LEFT JOIN OPCH T3 ON T1.DocEntry = T3.DocEntry
                    WHERE T0.Canceled <> 'Y' AND T3.DocNum IN (SELECT RTRIM(LTRIM(value)) AS DocNum FROM STRING_SPLIT(TMP.U_Paid, ','))
                    FOR XML PATH (''), TYPE).value('text()[1]','nvarchar(max)'), 2, 1000
                ),
    U_PaymentStatus = SUBSTRING((
                        SELECT
                            CONCAT(', ', 
                            CASE 
                                WHEN T3.PaidSum - T3.DocTotal <= 0 THEN 'Paid'
                                ELSE 'Unpaid' 
                            END
                            ) AS [text()]
                        FROM OVPM T0 WITH (NOLOCK)
                        INNER JOIN VPM2 T1 ON T1.DocNum = T0.DocEntry
                        LEFT JOIN VPM1 T2 ON T1.DocNum = T2.DocNum
                        LEFT JOIN OPCH T3 ON T1.DocEntry = T3.DocEntry
                        WHERE T0.Canceled <> 'Y' AND T3.DocNum IN (SELECT RTRIM(LTRIM(value)) AS DocNum FROM STRING_SPLIT(TMP.U_Paid, ','))
                        FOR XML PATH (''), TYPE).value('text()[1]','nvarchar(max)'), 2, 1000
                    )
FROM TMP_TARGET_20230912 TMP
WHERE TMP.U_BookingNumber = TP_EXTRACT.U_BookingId;

-------->>PRICING_EXTRACT

UPDATE PRICING_EXTRACT
SET U_APDocNum = TMP.U_DocNum,
    U_Paid = TMP.U_Paid
FROM TMP_TARGET_20230912 TMP
WHERE TMP.U_BookingNumber = PRICING_EXTRACT.U_BookingId;

-------->>DELETING TMP_TARGET_20230912

DROP TABLE IF EXISTS TMP_TARGET_20230912