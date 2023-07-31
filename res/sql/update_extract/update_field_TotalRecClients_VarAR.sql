-- PRINT 'BEFORE TRY'
-- BEGIN TRY
--     BEGIN TRAN
--     PRINT 'First Statement in the TRY block'

-------->>CREATING TARGETS
    
    DROP TABLE IF EXISTS TMP_TARGET
    SELECT

    T0.U_BookingId AS U_BookingNumber,
    ISNULL(pricing.U_GrossClientRates, 0) 
    + ISNULL(pricing.U_Demurrage, 0)
    + (ISNULL(pricing.U_AddtlDrop,0) + 
    ISNULL(pricing.U_BoomTruck,0) + 
    ISNULL(pricing.U_Manpower,0) + 
    ISNULL(pricing.U_Backload,0))
    + ISNULL(T0.U_ActualBilledRate, 0)
    + ISNULL(T0.U_RateAdjustments, 0)
    + ISNULL(T0.U_ActualDemurrage, 0)
    + ISNULL(T0.U_ActualAddCharges, 0) AS U_TotalRecClients,
    ISNULL((SELECT
        SUM(L.PriceAfVAT)
    FROM OINV H
        LEFT JOIN INV1 L ON H.DocEntry = L.DocEntry
    WHERE H.CANCELED = 'N' AND L.ItemCode = T0.U_BookingId), 0) 
    - (ISNULL(pricing.U_GrossClientRates, 0) 
    + ISNULL(pricing.U_Demurrage, 0)
    + (ISNULL(pricing.U_AddtlDrop,0) + 
    ISNULL(pricing.U_BoomTruck,0) + 
    ISNULL(pricing.U_Manpower,0) + 
    ISNULL(pricing.U_Backload,0))
    + ISNULL(T0.U_ActualBilledRate, 0)
    + ISNULL(T0.U_RateAdjustments, 0)
    + ISNULL(T0.U_ActualDemurrage, 0)
    + ISNULL(T0.U_ActualAddCharges, 0)) AS U_VarAR

INTO TMP_TARGET

FROM [dbo].[@PCTP_BILLING] T0  WITH (NOLOCK)
    INNER JOIN [dbo].[@PCTP_POD] pod ON T0.U_BookingId = pod.U_BookingNumber
        AND (CAST(pod.U_PODStatusDetail as nvarchar(max)) LIKE '%Verified%' OR CAST(pod.U_PODStatusDetail as nvarchar(max)) LIKE '%ForAdvanceBilling%')
    LEFT JOIN [dbo].[@PCTP_PRICING] pricing ON T0.U_BookingId = pricing.U_BookingId

-------->>BILLING_EXTRACT

    UPDATE BILLING_EXTRACT
    SET U_TotalRecClients = TMP.U_TotalRecClients,
        U_VarAR = TMP.U_VarAR
    FROM TMP_TARGET TMP
    WHERE TMP.U_BookingNumber = BILLING_EXTRACT.U_BookingNumber

-------->>SUMMARY_EXTRACT

    UPDATE SUMMARY_EXTRACT
    SET U_TotalRecClients = TMP.U_TotalRecClients,
        U_VarAR = TMP.U_VarAR
    FROM TMP_TARGET TMP
    WHERE TMP.U_BookingNumber = SUMMARY_EXTRACT.U_BookingNumber

-------->>PRICING_EXTRACT

    UPDATE PRICING_EXTRACT
    SET U_TotalRecClients = TMP.U_TotalRecClients,
        U_VarAR = TMP.U_VarAR
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