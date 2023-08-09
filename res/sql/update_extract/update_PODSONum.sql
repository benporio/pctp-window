-------->>CREATING TARGETS
    
    DROP TABLE IF EXISTS TMP_TARGET
    SELECT
    T0.U_BookingId AS U_BookingNumber,
    (
        SELECT TOP 1
        header.DocNum
    FROM ORDR header
        LEFT JOIN RDR1 line ON line.DocEntry = header.DocEntry
    WHERE line.ItemCode = T0.U_BookingId
        AND header.CANCELED = 'N'
    ) AS U_PODSONum
    INTO TMP_TARGET
    FROM [dbo].[@PCTP_BILLING] T0  WITH (NOLOCK)
    WHERE EXISTS(
        SELECT TOP 1
        header.DocNum
    FROM ORDR header
        LEFT JOIN RDR1 line ON line.DocEntry = header.DocEntry
    WHERE line.ItemCode = T0.U_BookingId
        AND header.CANCELED = 'N'
    );

-------->>SUMMARY_EXTRACT

    UPDATE SUMMARY_EXTRACT
    SET U_PODSONum = TMP.U_PODSONum
    FROM TMP_TARGET TMP
    WHERE TMP.U_BookingNumber = SUMMARY_EXTRACT.U_BookingNumber;

-------->>POD_EXTRACT

    UPDATE POD_EXTRACT
    SET U_PODSONum = TMP.U_PODSONum
    FROM TMP_TARGET TMP
    WHERE TMP.U_BookingNumber = POD_EXTRACT.U_BookingNumber;

-------->>TP_EXTRACT

    UPDATE TP_EXTRACT
    SET U_PODSONum = TMP.U_PODSONum
    FROM TMP_TARGET TMP
    WHERE TMP.U_BookingNumber = TP_EXTRACT.U_BookingNumber;

-------->>PRICING_EXTRACT

    UPDATE PRICING_EXTRACT
    SET U_PODSONum = TMP.U_PODSONum
    FROM TMP_TARGET TMP
    WHERE TMP.U_BookingNumber = PRICING_EXTRACT.U_BookingNumber;

-------->>DELETING TMP_TARGET

    DROP TABLE IF EXISTS TMP_TARGET