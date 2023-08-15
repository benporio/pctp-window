-------->>CREATING TARGETS
    
    DROP TABLE IF EXISTS TMP_TARGET_202308151234PM
    SELECT
    T0.U_BookingNumber
    INTO TMP_TARGET_202308151234PM
    FROM [dbo].[@PCTP_POD] T0  WITH (NOLOCK)
    WHERE LOWER(T0.U_DeliveryStatus) = 'cancelled'
    AND (
        T0.U_PTFNo IS NOT NULL
        OR T0.U_DateForwardedBT IS NOT NULL
    );

-------->>POD

    UPDATE [@PCTP_POD]
    SET U_PTFNo = NULL,
    U_DateForwardedBT = NULL
    FROM TMP_TARGET_202308151234PM TMP
    WHERE TMP.U_BookingNumber = [@PCTP_POD].U_BookingNumber;

-------->>SUMMARY_EXTRACT

    UPDATE SUMMARY_EXTRACT
    SET U_PTFNo = NULL,
    U_DateForwardedBT = NULL
    FROM TMP_TARGET_202308151234PM TMP
    WHERE TMP.U_BookingNumber = SUMMARY_EXTRACT.U_BookingNumber;

-------->>POD_EXTRACT

    UPDATE POD_EXTRACT
    SET U_PTFNo = NULL,
    U_DateForwardedBT = NULL
    FROM TMP_TARGET_202308151234PM TMP
    WHERE TMP.U_BookingNumber = POD_EXTRACT.U_BookingNumber;

-------->>BILLING_EXTRACT

    UPDATE BILLING_EXTRACT
    SET U_PTFNo = NULL,
    U_DateForwardedBT = NULL
    FROM TMP_TARGET_202308151234PM TMP
    WHERE TMP.U_BookingNumber = BILLING_EXTRACT.U_BookingNumber;
    
-------->>DELETING TMP_TARGET

    DROP TABLE IF EXISTS TMP_TARGET_202308151234PM;