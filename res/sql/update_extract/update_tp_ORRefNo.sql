-------->>CREATING TARGETS
    
    DROP TABLE IF EXISTS TMP_TARGET
    SELECT
    T0.U_BookingId AS U_BookingNumber,
    SUBSTRING((
        SELECT
			CONCAT(', ', T0.U_OR_Ref) AS [text()]
		FROM OPCH T0 WITH (NOLOCK)
		WHERE T0.Canceled <> 'Y' AND T0.DocNum IN (SELECT RTRIM(LTRIM(value)) AS DocNum FROM STRING_SPLIT(TF.U_Paid, ','))
		FOR XML PATH (''), TYPE).value('text()[1]','nvarchar(max)'), 2, 1000
    ) AS U_ORRefNo
    INTO TMP_TARGET
    FROM [dbo].[@PCTP_TP] T0  WITH (NOLOCK)
    LEFT JOIN TP_FORMULA TF ON TF.U_BookingId = T0.U_BookingId

-------->>TP_EXTRACT

    UPDATE TP_EXTRACT
    SET U_ORRefNo = TMP.U_ORRefNo
    FROM TMP_TARGET TMP
    WHERE TMP.U_BookingNumber = TP_EXTRACT.U_BookingNumber

-------->>DELETING TMP_TARGET

    DROP TABLE IF EXISTS TMP_TARGET