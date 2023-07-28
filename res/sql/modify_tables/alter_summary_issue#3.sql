-------->>MODIFICATION
ALTER TABLE SUMMARY_EXTRACT
ADD U_DeliveryDateDTR DATE,
    U_Remarks TEXT,
    U_WaybillNo TEXT;

-------->>CREATING TARGETS
    
    DROP TABLE IF EXISTS TMP_TARGET
    SELECT
    T0.U_BookingNumber,
    T0.U_DeliveryDateDTR,
    CAST(T0.U_Remarks as nvarchar(max)) AS U_Remarks,
    CAST(T0.U_WaybillNo as nvarchar(max)) AS U_WaybillNo
    INTO TMP_TARGET
    --COLUMNS
    FROM [dbo].[@PCTP_POD] T0  WITH (NOLOCK)

-------->>PRICING_EXTRACT

    UPDATE SUMMARY_EXTRACT
    SET U_DeliveryDateDTR = TMP.U_DeliveryDateDTR,
        U_Remarks = TMP.U_Remarks,
        U_WaybillNo = TMP.U_WaybillNo
    FROM TMP_TARGET TMP
    WHERE TMP.U_BookingNumber = SUMMARY_EXTRACT.U_BookingNumber

-------->>DELETING TMP_TARGET

    DROP TABLE IF EXISTS TMP_TARGET