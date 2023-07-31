-------->>MODIFICATION
ALTER TABLE TP_EXTRACT
DROP COLUMN U_ActualPaymentDate, U_PaymentReference, U_PaymentStatus;

ALTER TABLE TP_EXTRACT
ADD U_ActualPaymentDate TEXT,
    U_PaymentReference TEXT,
    U_PaymentStatus TEXT;

-------->>CREATING TARGETS
    
    DROP TABLE IF EXISTS TMP_TARGET
    SELECT
    T0.U_BookingId AS U_BookingNumber,
    SUBSTRING((
        SELECT
        CONCAT(', ', CAST(T0.TrsfrDate AS DATE)) AS [text()]
    FROM OVPM T0 WITH (NOLOCK)
        INNER JOIN VPM2 T1 ON T1.DocNum = T0.DocEntry
        LEFT JOIN VPM1 T2 ON T1.DocNum = T2.DocNum
        LEFT JOIN OPCH T3 ON T1.DocEntry = T3.DocEntry
    WHERE T0.Canceled <> 'Y' AND T3.DocNum IN (SELECT RTRIM(LTRIM(value)) AS DocNum
    FROM STRING_SPLIT(TF.U_Paid, ','))
    FOR XML PATH (''), TYPE).value('text()[1]','nvarchar(max)'), 2, 1000
    ) AS U_ActualPaymentDate,
    SUBSTRING((
        SELECT
        CONCAT(', ', T0.TrsfrRef) AS [text()]
    FROM OVPM T0 WITH (NOLOCK)
        INNER JOIN VPM2 T1 ON T1.DocNum = T0.DocEntry
        LEFT JOIN VPM1 T2 ON T1.DocNum = T2.DocNum
        LEFT JOIN OPCH T3 ON T1.DocEntry = T3.DocEntry
    WHERE T0.Canceled <> 'Y' AND T3.DocNum IN (SELECT RTRIM(LTRIM(value)) AS DocNum
    FROM STRING_SPLIT(TF.U_Paid, ','))
    FOR XML PATH (''), TYPE).value('text()[1]','nvarchar(max)'), 2, 1000
    ) AS U_PaymentReference,
    SUBSTRING((
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
    WHERE T0.Canceled <> 'Y' AND T3.DocNum IN (SELECT RTRIM(LTRIM(value)) AS DocNum
    FROM STRING_SPLIT(TF.U_Paid, ','))
    FOR XML PATH (''), TYPE).value('text()[1]','nvarchar(max)'), 2, 1000
    ) AS U_PaymentStatus

INTO TMP_TARGET
--COLUMNS
FROM [dbo].[@PCTP_TP] T0  WITH (NOLOCK)
    LEFT JOIN TP_FORMULA TF ON TF.U_BookingId = T0.U_BookingId

-------->>TP_EXTRACT
    BEGIN TRAN

    UPDATE TP_EXTRACT
    SET U_ActualPaymentDate = TMP.U_ActualPaymentDate,
        U_PaymentReference = TMP.U_PaymentReference,
        U_PaymentStatus = TMP.U_PaymentStatus
    FROM TMP_TARGET TMP
    WHERE TMP.U_BookingNumber = TP_EXTRACT.U_BookingNumber
    COMMIT TRAN

-------->>DELETING TMP_TARGET

    DROP TABLE IF EXISTS TMP_TARGET