-- PRINT 'BEFORE TRY'
-- BEGIN TRY
--     BEGIN TRAN
--     PRINT 'First Statement in the TRY block'

-------->>CREATING TARGETS
    
    DROP TABLE IF EXISTS TMP_TARGET
    SELECT
    T0.U_BookingId AS U_BookingNumber,
    (
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
    ) AS U_BillingStatus
    INTO TMP_TARGET
    FROM [dbo].[@PCTP_BILLING] T0  WITH (NOLOCK)
        INNER JOIN [dbo].[@PCTP_POD] pod ON T0.U_BookingId = pod.U_BookingNumber
            AND (CAST(pod.U_PODStatusDetail as nvarchar(max)) LIKE '%Verified%' OR CAST(pod.U_PODStatusDetail as nvarchar(max)) LIKE '%ForAdvanceBilling%')

-------->>BILLING_EXTRACT

    UPDATE BILLING_EXTRACT
    SET U_BillingStatus = TMP.U_BillingStatus
    FROM TMP_TARGET TMP
    WHERE TMP.U_BookingNumber = BILLING_EXTRACT.U_BookingNumber

<<<<<<< HEAD
=======
-------->>SUMMARY_EXTRACT

    UPDATE SUMMARY_EXTRACT
    SET U_BillingStatus = TMP.U_BillingStatus
    FROM TMP_TARGET TMP
    WHERE TMP.U_BookingNumber = SUMMARY_EXTRACT.U_BookingNumber

>>>>>>> test/v1.0.0
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