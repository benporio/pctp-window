-------->>CREATING TARGETS
    
    DROP TABLE IF EXISTS TMP_TARGET_202309010320PM
    SELECT
        pod.U_BookingNumber, 
        dbo.computeLostPenaltyCalc(
            dbo.computePODStatusPayment(
                dbo.computeOverdueDays(
                    pod.U_ActualHCRecDate,
                    dbo.computePODSubmitDeadline(
                        pod.U_DeliveryDateDTR,
                        ISNULL(T4.U_CDC,0)
                    ),
                    ISNULL(pod.U_HolidayOrWeekend, 0)
                )
            ),
            pod.U_InitialHCRecDate,
            pod.U_DeliveryDateDTR,
            CASE
                WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN ISNULL(pricing.U_GrossTruckerRates, 0)
                WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN (ISNULL(pricing.U_GrossTruckerRates, 0) / 1.12)
            END + CASE
                WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN ISNULL(pricing.U_Demurrage2, 0)
                WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN (ISNULL(pricing.U_Demurrage2, 0) / 1.12)
            END + CASE
                WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN (ISNULL(pricing.U_AddtlDrop2, 0) + ISNULL(pricing.U_BoomTruck2, 0) + ISNULL(pricing.U_Manpower2, 0) + ISNULL(pricing.U_Backload2, 0))
                WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN ((ISNULL(pricing.U_AddtlDrop2, 0) + ISNULL(pricing.U_BoomTruck2, 0) + ISNULL(pricing.U_Manpower2, 0) + ISNULL(pricing.U_Backload2, 0)) / 1.12)
            END
            -- pricing.U_TotalInitialTruckers
        ) AS U_LostPenaltyCalc,
        ISNULL(ABS(dbo.computeTotalSubPenalties(
            dbo.computeClientPenaltyCalc(
                dbo.computeClientSubOverdue(
                    pod.U_DeliveryDateDTR,
                    pod.U_ClientReceivedDate,
                    ISNULL(pod.U_WaivedDays, 0),
                    CAST(ISNULL(T4.U_DCD,0) as int)
                )
            ),
            dbo.computeInteluckPenaltyCalc(
                dbo.computePODStatusPayment(
                    dbo.computeOverdueDays(
                        pod.U_ActualHCRecDate,
                        dbo.computePODSubmitDeadline(
                            pod.U_DeliveryDateDTR,
                            ISNULL(T4.U_CDC,0)
                        ),
                        ISNULL(pod.U_HolidayOrWeekend, 0)
                    )
                ),
                dbo.computeOverdueDays(
                    pod.U_ActualHCRecDate,
                    dbo.computePODSubmitDeadline(
                        pod.U_DeliveryDateDTR,
                        ISNULL(T4.U_CDC,0)
                    ),
                    ISNULL(pod.U_HolidayOrWeekend, 0)
                )
            ),
            dbo.computeLostPenaltyCalc(
                dbo.computePODStatusPayment(
                    dbo.computeOverdueDays(
                        pod.U_ActualHCRecDate,
                        dbo.computePODSubmitDeadline(
                            pod.U_DeliveryDateDTR,
                            ISNULL(T4.U_CDC,0)
                        ),
                        ISNULL(pod.U_HolidayOrWeekend, 0)
                    )
                ),
                pod.U_InitialHCRecDate,
                pod.U_DeliveryDateDTR,
                CASE
                    WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN ISNULL(pricing.U_GrossTruckerRates, 0)
                    WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN (ISNULL(pricing.U_GrossTruckerRates, 0) / 1.12)
                END + CASE
                    WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN ISNULL(pricing.U_Demurrage2, 0)
                    WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN (ISNULL(pricing.U_Demurrage2, 0) / 1.12)
                END + CASE
                    WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN (ISNULL(pricing.U_AddtlDrop2, 0) + ISNULL(pricing.U_BoomTruck2, 0) + ISNULL(pricing.U_Manpower2, 0) + ISNULL(pricing.U_Backload2, 0))
                    WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN ((ISNULL(pricing.U_AddtlDrop2, 0) + ISNULL(pricing.U_BoomTruck2, 0) + ISNULL(pricing.U_Manpower2, 0) + ISNULL(pricing.U_Backload2, 0)) / 1.12)
                END
                -- pricing.U_TotalInitialTruckers
            ),
            ISNULL(pod.U_PenaltiesManual,0)
        )), 0) AS U_TotalSubPenalty,
        dbo.computeTotalPenaltyWaived(
            dbo.computeTotalSubPenalties(
                dbo.computeClientPenaltyCalc(
                    dbo.computeClientSubOverdue(
                        pod.U_DeliveryDateDTR,
                        pod.U_ClientReceivedDate,
                        ISNULL(pod.U_WaivedDays, 0),
                        CAST(ISNULL(T4.U_DCD,0) as int)
                    )
                ),
                dbo.computeInteluckPenaltyCalc(
                    dbo.computePODStatusPayment(
                        dbo.computeOverdueDays(
                            pod.U_ActualHCRecDate,
                            dbo.computePODSubmitDeadline(
                                pod.U_DeliveryDateDTR,
                                ISNULL(T4.U_CDC,0)
                            ),
                            ISNULL(pod.U_HolidayOrWeekend, 0)
                        )
                    ),
                    dbo.computeOverdueDays(
                        pod.U_ActualHCRecDate,
                        dbo.computePODSubmitDeadline(
                            pod.U_DeliveryDateDTR,
                            ISNULL(T4.U_CDC,0)
                        ),
                        ISNULL(pod.U_HolidayOrWeekend, 0)
                    )
                ),
                dbo.computeLostPenaltyCalc(
                    dbo.computePODStatusPayment(
                        dbo.computeOverdueDays(
                            pod.U_ActualHCRecDate,
                            dbo.computePODSubmitDeadline(
                                pod.U_DeliveryDateDTR,
                                ISNULL(T4.U_CDC,0)
                            ),
                            ISNULL(pod.U_HolidayOrWeekend, 0)
                        )
                    ),
                    pod.U_InitialHCRecDate,
                    pod.U_DeliveryDateDTR,
                    CASE
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN ISNULL(pricing.U_GrossTruckerRates, 0)
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN (ISNULL(pricing.U_GrossTruckerRates, 0) / 1.12)
                    END + CASE
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN ISNULL(pricing.U_Demurrage2, 0)
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN (ISNULL(pricing.U_Demurrage2, 0) / 1.12)
                    END + CASE
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN (ISNULL(pricing.U_AddtlDrop2, 0) + ISNULL(pricing.U_BoomTruck2, 0) + ISNULL(pricing.U_Manpower2, 0) + ISNULL(pricing.U_Backload2, 0))
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN ((ISNULL(pricing.U_AddtlDrop2, 0) + ISNULL(pricing.U_BoomTruck2, 0) + ISNULL(pricing.U_Manpower2, 0) + ISNULL(pricing.U_Backload2, 0)) / 1.12)
                    END
                    -- pricing.U_TotalInitialTruckers
                ),
                ISNULL(pod.U_PenaltiesManual,0)
            ),
            ISNULL(pod.U_PercPenaltyCharge,0)
        ) AS U_TotalPenaltyWaived
    INTO TMP_TARGET_202309010320PM
    FROM [dbo].[@PCTP_TP] T0 WITH (NOLOCK)
    INNER JOIN [dbo].[@PCTP_POD] pod ON T0.U_BookingId = pod.U_BookingNumber AND CAST(pod.U_PODStatusDetail as nvarchar(max)) LIKE '%Verified%'
    LEFT JOIN OCRD T4 ON pod.U_SAPClient = T4.CardCode
    LEFT JOIN [dbo].[@PCTP_PRICING] pricing ON T0.U_BookingId = pricing.U_BookingId
    LEFT JOIN OCRD trucker ON pod.U_SAPTrucker = trucker.CardCode;

-------->>POD_EXTRACT

    UPDATE POD_EXTRACT
    SET U_LostPenaltyCalc = TMP.U_LostPenaltyCalc,
        U_TotalSubPenalties = TMP.U_TotalSubPenalty,
        U_TotalPenaltyWaived = TMP.U_TotalPenaltyWaived
    FROM TMP_TARGET_202309010320PM TMP
    WHERE TMP.U_BookingNumber = POD_EXTRACT.U_BookingNumber;

-------->>TP_EXTRACT

    UPDATE TP_EXTRACT
    SET U_LostPenaltyCalc = TMP.U_LostPenaltyCalc,
        U_TotalSubPenalty = TMP.U_TotalSubPenalty,
        U_TotalPenaltyWaived = TMP.U_TotalPenaltyWaived,
        U_TotalPenalty = ABS(ISNULL(TMP.U_TotalSubPenalty, 0) - ISNULL(TMP.U_TotalPenaltyWaived, 0))
    FROM TMP_TARGET_202309010320PM TMP
    WHERE TMP.U_BookingNumber = TP_EXTRACT.U_BookingId;
    
-------->>DELETING TMP_TARGET

    DROP TABLE IF EXISTS TMP_TARGET_202309010320PM;