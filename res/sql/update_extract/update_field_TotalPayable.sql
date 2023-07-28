-- PRINT 'BEFORE TRY'
-- BEGIN TRY
--     BEGIN TRAN
--     PRINT 'First Statement in the TRY block'

-------->>CREATING TARGETS
    
    DROP TABLE IF EXISTS TMP_TARGET
    SELECT

    T0.U_BookingId AS U_BookingNumber,
    ISNULL(CASE
        WHEN ISNULL(T5.VatStatus,'Y') = 'Y' THEN ISNULL(pricing.U_GrossTruckerRates, 0)
        WHEN ISNULL(T5.VatStatus,'Y') = 'N' THEN (ISNULL(pricing.U_GrossTruckerRates, 0) / 1.12)
    END, 0) 
    + ISNULL(CASE
        WHEN ISNULL(T5.VatStatus,'Y') = 'Y' THEN ISNULL(TRY_PARSE(CAST(pricing.U_Demurrage2 AS nvarchar) AS FLOAT), 0)
        WHEN ISNULL(T5.VatStatus,'Y') = 'N' THEN (ISNULL(TRY_PARSE(CAST(pricing.U_Demurrage2 AS nvarchar) AS FLOAT), 0) / 1.12)
    END, 0) 
    + ISNULL(CASE
        WHEN ISNULL(T5.VatStatus,'Y') = 'Y' THEN 
        (ISNULL(pricing.U_AddtlDrop2, 0) 
        + ISNULL(pricing.U_BoomTruck2, 0) 
        + ISNULL(pricing.U_Manpower2, 0) 
        + ISNULL(pricing.U_Backload2, 0))
        WHEN ISNULL(T5.VatStatus,'Y') = 'N' THEN 
        ((ISNULL(pricing.U_AddtlDrop2, 0) 
        + ISNULL(pricing.U_BoomTruck2, 0) 
        + ISNULL(pricing.U_Manpower2, 0) 
        + ISNULL(pricing.U_Backload2, 0)) / 1.12)
    END, 0) 
    + ISNULL(T0.U_ActualRates, 0) 
    + ISNULL(T0.U_RateAdjustments, 0) 
    + ISNULL(T0.U_ActualDemurrage, 0) 
    + ISNULL(T0.U_ActualCharges, 0) 
    + ISNULL(TRY_PARSE(CAST(T0.U_BoomTruck2 AS nvarchar) AS FLOAT), 0) 
    + ISNULL(T0.U_OtherCharges, 0) 
    - (ISNULL(T0.U_CAandDP,0) + ISNULL(T0.U_Interest,0) + ISNULL(T0.U_OtherDeductions,0) 
    + (ABS(ABS(ISNULL(TF.U_TotalSubPenalty,0)) - ABS(ISNULL(TF.U_TotalPenaltyWaived,0))))) AS U_TotalPayable

INTO TMP_TARGET

FROM [dbo].[@PCTP_TP] T0  WITH (NOLOCK)
    INNER JOIN [dbo].[@PCTP_POD] pod ON T0.U_BookingId = pod.U_BookingNumber AND CAST(pod.U_PODStatusDetail as nvarchar(max)) LIKE '%Verified%'
    LEFT JOIN [dbo].[@PCTP_PRICING] pricing ON T0.U_BookingId = pricing.U_BookingId
    LEFT JOIN OCRD T5 ON T5.CardCode = pod.U_SAPTrucker
    LEFT JOIN TP_FORMULA TF ON TF.U_BookingId = T0.U_BookingId

-------->>TP_EXTRACT

    UPDATE TP_EXTRACT
    SET U_TotalPayable = TMP.U_TotalPayable
    FROM TMP_TARGET TMP
    WHERE TMP.U_BookingNumber = TP_EXTRACT.U_BookingNumber

-------->>SUMMARY_EXTRACT

    UPDATE SUMMARY_EXTRACT
    SET U_TotalPayable = TMP.U_TotalPayable
    FROM TMP_TARGET TMP
    WHERE TMP.U_BookingNumber = SUMMARY_EXTRACT.U_BookingNumber

-------->>PRICING_EXTRACT

    UPDATE PRICING_EXTRACT
    SET U_TotalPayable = TMP.U_TotalPayable
    FROM TMP_TARGET TMP
    WHERE TMP.U_BookingNumber = PRICING_EXTRACT.U_BookingNumber

-------->>DELETING TMP_TARGET

    DROP TABLE IF EXISTS TMP_TARGET

--     PRINT 'Last Statement in the TRY block'
--     COMMIT TRAN
-- END TRY
-- BEGIN CATCH
--     PRINT 'In CATCH Block'
--     IF(@@TRANCOUNT > 0)
--         ROLLBACK TRAN;

--     THROW; -- raise error to the client
-- END CATCH
-- PRINT 'After END CATCH'