-------->>MODIFICATION
ALTER TABLE PRICING_EXTRACT
DROP COLUMN U_PODDocNum;
GO
ALTER TABLE PRICING_EXTRACT
ADD U_PODDocNum TEXT;

-------->>CREATING TARGETS
    
    DROP TABLE IF EXISTS TMP_TARGET
    SELECT
    T0.U_BookingId AS U_BookingNumber,
    CAST(pod.U_DocNum as nvarchar(max)) AS U_PODDocNum
    INTO TMP_TARGET
    --COLUMNS
    FROM [dbo].[@PCTP_PRICING] T0  WITH (NOLOCK)
        LEFT JOIN [dbo].[@PCTP_POD] pod ON T0.U_BookingId = pod.U_BookingNumber

-------->>PRICING_EXTRACT

    UPDATE PRICING_EXTRACT
    SET U_PODDocNum = TMP.U_PODDocNum
    FROM TMP_TARGET TMP
    WHERE TMP.U_BookingNumber = PRICING_EXTRACT.U_BookingNumber

-------->>DELETING TMP_TARGET

    DROP TABLE IF EXISTS TMP_TARGET