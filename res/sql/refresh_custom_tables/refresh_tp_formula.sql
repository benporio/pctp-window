PRINT 'CREATING TARGETS'
    
    DROP TABLE IF EXISTS TMP_TARGET_$serial
    SELECT
	    T0.U_BookingNumber
    INTO TMP_TARGET_$serial
    FROM [dbo].[@PCTP_POD] T0  WITH (NOLOCK)
    WHERE T0.U_BookingNumber IN ($bookingIds);

-- PRINT 'BEFORE TRY'
-- BEGIN TRY
--     BEGIN TRAN
--     PRINT 'First Statement in the TRY block'
    
    UPDATE [@FirstratesTP] 
    SET U_Amount = NULL
    WHERE U_Amount = 'NaN' AND U_BN IN (SELECT U_BookingNumber FROM TMP_TARGET_$serial WITH (NOLOCK));


    UPDATE [@FirstratesTP] 
    SET U_AddlAmount = NULL
    WHERE U_AddlAmount = 'NaN' AND U_BN IN (SELECT U_BookingNumber FROM TMP_TARGET_$serial WITH (NOLOCK));


    DROP TABLE IF EXISTS TMP_UPDATE_TP_FORMULA_$serial
    SELECT

        T0.U_BookingId,
        CASE
            WHEN (
                SELECT DISTINCT COUNT(*)
        FROM OPCH H LEFT JOIN PCH1 L ON H.DocEntry = L.DocEntry
        WHERE H.CANCELED = 'N'
            AND (L.ItemCode = T0.U_BookingId OR REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(H.U_PVNo)) + '%')
            ) > 1
            THEN 'Y'
            ELSE 'N'
        END AS DisableTableRow,
        CASE
            WHEN (
                SELECT DISTINCT COUNT(*)
        FROM OPCH H LEFT JOIN PCH1 L ON H.DocEntry = L.DocEntry
        WHERE H.CANCELED = 'N'
            AND (L.ItemCode = T0.U_BookingId) OR (REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(H.U_PVNo)) + '%')
            ) = 1
            THEN 'DisableSomeFields'
            ELSE ''
        END AS DisableSomeFields,
        CASE


            WHEN EXISTS(
                SELECT 1
        FROM OPCH header
            LEFT JOIN PCH1 line ON header.DocEntry = line.DocEntry
        WHERE header.CANCELED = 'N' AND REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%'
            ) THEN 
                CASE 
                    --TOTAL AP 2 PAID  ------------
                    WHEN CHARINDEX(',', CAST((
                        SELECT DISTINCT
                SUBSTRING(
                                (
                                    SELECT CONCAT(', ', header.DocNum)  AS [text()]
                FROM PCH1 line
                    LEFT JOIN OPCH header ON header.DocEntry = line.DocEntry
                WHERE header.CANCELED = 'N' AND header.PaidSum > 0 AND (line.ItemCode = T0.U_BookingId
                    or REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%')
                FOR XML PATH (''), TYPE
                                ).value('text()[1]','nvarchar(max)'), 2, 1000) DocEntry
            FROM OPCH header
                LEFT JOIN PCH1 line ON line.DocEntry = header.DocEntry
            WHERE header.CANCELED = 'N' AND (line.ItemCode = T0.U_BookingId
                or REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%')) as nvarchar(max)
                        )) >  0 AND
            CAST((
                            SELECT DISTINCT
                SUBSTRING(
                                (
                                    SELECT CONCAT(', ', header.DocNum)  AS [text()]
                FROM PCH1 line
                    LEFT JOIN OPCH header ON header.DocEntry = line.DocEntry
                WHERE header.CANCELED = 'N' AND header.PaidSum = 0 AND (line.ItemCode = T0.U_BookingId
                    or REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%')
                FOR XML PATH (''), TYPE
                                ).value('text()[1]','nvarchar(max)'), 2, 1000) DocEntry
            FROM OPCH header
                LEFT JOIN PCH1 line ON line.DocEntry = header.DocEntry
            WHERE header.CANCELED = 'N' AND (line.ItemCode = T0.U_BookingId
                or REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%')) as nvarchar(max)
                        ) IS NULL
                    THEN 
                    ISNULL((
                        SELECT DISTINCT

            (
                            CASE WHEN T5.U_Rates LIKE '%U_GrossTruckerRates%' THEN 
                                CASE
                                    WHEN ISNULL( truckersub.VatStatus,'Y') = 'Y' THEN pricingsub.U_GrossTruckerRates
                                    WHEN ISNULL(truckersub.VatStatus,'Y') = 'N' THEN (pricingsub.U_GrossTruckerRates / 1.12)
                                END 
                            ELSE 0.00 
                            END
                            +
                            CASE WHEN T5.U_Rates LIKE '%U_ActualRates%' THEN 
                                ISNULL(NULLIF(CAST(tpsub.U_ActualRates AS FLOAT),''),0)
                            ELSE 0.00
                            END 
                            +
                            CASE WHEN T5.U_Rates LIKE '%U_RateAdjustments%' THEN 
                                ISNULL(NULLIF(CAST(tpsub.U_RateAdjustments AS FLOAT),''),0)
                            ELSE 0.00
                            END 
                            +
                            CASE WHEN T5.U_Rates LIKE '%U_DemurrageN%' THEN 
                                CASE
                                    WHEN ISNULL(truckersub.VatStatus,'Y') = 'Y' THEN pricingsub.U_Demurrage2
                                    WHEN ISNULL(truckersub.VatStatus,'Y') = 'N' THEN (pricingsub.U_Demurrage2 / 1.12) 
                                END
                            ELSE 0.00
                            END 
                            +  
                            CASE WHEN T5.U_Rates LIKE '%U_totalAddtlCharges2%' THEN 
                                ISNULL(NULLIF(CAST(tpsub.U_ActualCharges AS FLOAT),''),0)
                            ELSE 0.00
                            END 
                            +  
                            CASE WHEN T5.U_Rates LIKE '%U_ActualDemurrage%' THEN 
                                ISNULL(NULLIF(CAST(tpsub.U_ActualDemurrage AS FLOAT),''),0)
                            ELSE 0.00
                            END 
                            +  
                            CASE WHEN T5.U_Rates LIKE '%U_ActualCharges%' THEN 
                                ISNULL(NULLIF(CAST(tpsub.U_ActualCharges AS FLOAT),''),0)

                            ELSE 0.00
                            END 
                            +  
                            CASE WHEN T5.U_Rates LIKE '%U_BoomTruck2%' THEN 
                                ISNULL(NULLIF(CAST(tpsub.U_BoomTruck2 AS FLOAT),''),0)
                            ELSE 0.00
                            END 
                            +  
                            CASE WHEN T5.U_Rates LIKE '%U_OtherCharges%' THEN 
                                ISNULL(NULLIF(CAST(tpsub.U_OtherCharges AS FLOAT),''),0)
                            ELSE 0.00
                            END 

                        )
                        -
                        ISNULL(tpsub.U_OtherDeductions,0) 

                        +

                            abs(dbo.computeTotalPenaltyWaived(
                                dbo.computeTotalSubPenalties(
                                    dbo.computeClientPenaltyCalc(
                                        dbo.computeClientSubOverdue(
                                            podsub.U_DeliveryDateDTR,
                                            podsub.U_ClientReceivedDate,
                                            ISNULL(podsub.U_WaivedDays, 0),
                                            CAST(ISNULL(clientsub.U_DCD,0) as int)
                                        )
                                    ),
                                    dbo.computeInteluckPenaltyCalc(
                                        dbo.computePODStatusPayment(
                                            dbo.computeOverdueDays(
                                                podsub.U_ActualHCRecDate,
                                                dbo.computePODSubmitDeadline(
                                                    podsub.U_DeliveryDateDTR,
                                                    ISNULL(clientsub.U_CDC,0)
                                                ),
                                                ISNULL(podsub.U_HolidayOrWeekend, 0)
                                            )
                                        ),
                                        dbo.computeOverdueDays(
                                            podsub.U_ActualHCRecDate,
                                            dbo.computePODSubmitDeadline(
                                                podsub.U_DeliveryDateDTR,
                                                ISNULL(clientsub.U_CDC,0)
                                            ),
                                            ISNULL(podsub.U_HolidayOrWeekend, 0)
                                        )
                                    ),
                                    dbo.computeLostPenaltyCalc(
                                        dbo.computePODStatusPayment(
                                            dbo.computeOverdueDays(
                                                podsub.U_ActualHCRecDate,
                                                dbo.computePODSubmitDeadline(
                                                    podsub.U_DeliveryDateDTR,
                                                    ISNULL(clientsub.U_CDC,0)
                                                ),
                                                ISNULL(podsub.U_HolidayOrWeekend, 0)
                                            )
                                        ),
                                        podsub.U_InitialHCRecDate,
                                        podsub.U_DeliveryDateDTR,
                                        pricingsub.U_TotalInitialTruckers
                                    ),
                                    ISNULL(podsub.U_PenaltiesManual,0)
                                ),
                                ISNULL(podsub.U_PercPenaltyCharge,0))
                            ) AS TotalAmount




        FROM [@PCTP_TP] tpsub
            INNER JOIN [@PCTP_POD] podsub ON tpsub.U_BookingId = podsub.U_BookingNumber
            INNER JOIN OCRD truckersub ON podsub.U_SAPTrucker = truckersub.CardCode
            INNER JOIN OCRD clientsub ON U_SAPClient = clientsub.CardCode
            INNER JOIN [dbo].[@PCTP_PRICING] pricingsub ON tpsub.U_BookingId = pricingsub.U_BookingId
            --INNER JOIN [@RATESPERPV] ratessub ON ratessub.Code = tpsub.U_PVNo
            INNER JOIN [@RATESPERPV] T5 ON T5.Code = SUBSTRING(tpsub.U_PVNo, 11, 19)
        WHERE tpsub.U_BookingId =  T0.U_BookingId


                        ),0)+ ISNULL((

                        SELECT DISTINCT

            (

                            ISNULL(TRY_PARSE(ratessub.U_Amount AS FLOAT),0)+
                        --ISNULL(tpsub.U_ActualRates,0) +

                            ISNULL(tpsub.U_RateAdjustments,0) +



                            ISNULL(TRY_PARSE(ratessub.U_AddlAmount AS FLOAT),0)  
                        --+

                        --ISNULL(tpsub.U_ActualDemurrage,0) +
                        --ISNULL(tpsub.U_ActualCharges,0)+
                        --ISNULL(NULLIF(tpsub.U_BoomTruck2,''),0) +
                        --ISNULL(tpsub.U_OtherCharges,0) 

                        )

                        -

                        (ABS(dbo.computeTotalSubPenalties(
                                dbo.computeClientPenaltyCalc(
                                    dbo.computeClientSubOverdue(
                                        podsub.U_DeliveryDateDTR,
                                        podsub.U_ClientReceivedDate,
                                        ISNULL(podsub.U_WaivedDays, 0),
                                        CAST(ISNULL(clientsub.U_DCD,0) as int)
                                    )
                                ),
                                dbo.computeInteluckPenaltyCalc(
                                    dbo.computePODStatusPayment(
                                        dbo.computeOverdueDays(
                                            podsub.U_ActualHCRecDate,
                                            dbo.computePODSubmitDeadline(
                                                podsub.U_DeliveryDateDTR,
                                                ISNULL(clientsub.U_CDC,0)
                                            ),
                                            ISNULL(podsub.U_HolidayOrWeekend, 0)
                                        )
                                    ),
                                    dbo.computeOverdueDays(
                                        podsub.U_ActualHCRecDate,
                                        dbo.computePODSubmitDeadline(
                                            podsub.U_DeliveryDateDTR,
                                            ISNULL(clientsub.U_CDC,0)
                                        ),
                                        ISNULL(podsub.U_HolidayOrWeekend, 0)
                                    )
                                ),
                                dbo.computeLostPenaltyCalc(
                                    dbo.computePODStatusPayment(
                                        dbo.computeOverdueDays(
                                            podsub.U_ActualHCRecDate,
                                            dbo.computePODSubmitDeadline(
                                                podsub.U_DeliveryDateDTR,
                                                ISNULL(clientsub.U_CDC,0)
                                            ),
                                            ISNULL(podsub.U_HolidayOrWeekend, 0)
                                        )
                                    ),
                                    podsub.U_InitialHCRecDate,
                                    podsub.U_DeliveryDateDTR,
                                    pricingsub.U_TotalInitialTruckers
                                ),
                                ISNULL(podsub.U_PenaltiesManual,0)
                            )) -

                            dbo.computeTotalPenaltyWaived(
                                dbo.computeTotalSubPenalties(
                                    dbo.computeClientPenaltyCalc(
                                        dbo.computeClientSubOverdue(
                                            podsub.U_DeliveryDateDTR,
                                            podsub.U_ClientReceivedDate,
                                            ISNULL(podsub.U_WaivedDays, 0),
                                            CAST(ISNULL(clientsub.U_DCD,0) as int)
                                        )
                                    ),
                                    dbo.computeInteluckPenaltyCalc(
                                        dbo.computePODStatusPayment(
                                            dbo.computeOverdueDays(
                                                podsub.U_ActualHCRecDate,
                                                dbo.computePODSubmitDeadline(
                                                    podsub.U_DeliveryDateDTR,
                                                    ISNULL(clientsub.U_CDC,0)
                                                ),
                                                ISNULL(podsub.U_HolidayOrWeekend, 0)
                                            )
                                        ),
                                        dbo.computeOverdueDays(
                                            podsub.U_ActualHCRecDate,
                                            dbo.computePODSubmitDeadline(
                                                podsub.U_DeliveryDateDTR,
                                                ISNULL(clientsub.U_CDC,0)
                                            ),
                                            ISNULL(podsub.U_HolidayOrWeekend, 0)
                                        )
                                    ),
                                    dbo.computeLostPenaltyCalc(
                                        dbo.computePODStatusPayment(
                                            dbo.computeOverdueDays(
                                                podsub.U_ActualHCRecDate,
                                                dbo.computePODSubmitDeadline(
                                                    podsub.U_DeliveryDateDTR,
                                                    ISNULL(clientsub.U_CDC,0)
                                                ),
                                                ISNULL(podsub.U_HolidayOrWeekend, 0)
                                            )
                                        ),
                                        podsub.U_InitialHCRecDate,
                                        podsub.U_DeliveryDateDTR,
                                        pricingsub.U_TotalInitialTruckers
                                    ),
                                    ISNULL(podsub.U_PenaltiesManual,0)
                                ),
                                ISNULL(podsub.U_PercPenaltyCharge,0)))



                            AS TotalAmount




        FROM [@PCTP_TP] tpsub
            INNER JOIN [@PCTP_POD] podsub ON tpsub.U_BookingId = podsub.U_BookingNumber
            INNER JOIN OCRD truckersub ON podsub.U_SAPTrucker = truckersub.CardCode
            INNER JOIN OCRD clientsub ON U_SAPClient = clientsub.CardCode
            INNER JOIN [dbo].[@PCTP_PRICING] pricingsub ON tpsub.U_BookingId = pricingsub.U_BookingId
            LEFT JOIN [@FirstratesTP] ratessub ON ratessub.U_BN = tpsub.U_BookingId AND ratessub.U_PVNo = SUBSTRING(tpsub.U_PVNo, 1, 9)


        WHERE tpsub.U_BookingId = T0.U_BookingId

                        )

                        ,0)    
                    --TOTAL AP 1 UNPAID 1 PAID  ------------
                    WHEN CAST((
                        SELECT DISTINCT
                SUBSTRING(
                            (
                                SELECT CONCAT(', ', header.DocNum)  AS [text()]
                FROM PCH1 line
                    LEFT JOIN OPCH header ON header.DocEntry = line.DocEntry
                WHERE header.CANCELED = 'N' AND header.PaidSum = 0 AND (line.ItemCode = T0.U_BookingId
                    or REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%')
                FOR XML PATH (''), TYPE
                            ).value('text()[1]','nvarchar(max)'), 2, 1000) DocEntry
            FROM OPCH header
                LEFT JOIN PCH1 line ON line.DocEntry = header.DocEntry
            WHERE header.CANCELED = 'N' AND (line.ItemCode = T0.U_BookingId
                or REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%')) as nvarchar(max)
                    ) IS NOT NULL AND
            CAST((
                        SELECT DISTINCT
                SUBSTRING(
                            (
                                SELECT CONCAT(', ', header.DocNum)  AS [text()]
                FROM PCH1 line
                    LEFT JOIN OPCH header ON header.DocEntry = line.DocEntry
                WHERE header.CANCELED = 'N' AND header.PaidSum > 0 AND (line.ItemCode = T0.U_BookingId
                    or REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%')
                FOR XML PATH (''), TYPE
                            ).value('text()[1]','nvarchar(max)'), 2, 1000) DocEntry
            FROM OPCH header
                LEFT JOIN PCH1 line ON line.DocEntry = header.DocEntry
            WHERE header.CANCELED = 'N' AND (line.ItemCode = T0.U_BookingId
                or REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%')) as nvarchar(max)
                    ) IS NOT NULL
                    THEN 

                ISNULL((
        SELECT DISTINCT

            (
        CASE WHEN T5.U_Rates LIKE '%U_GrossTruckerRates%' THEN 
                CASE
                    WHEN ISNULL( truckersub.VatStatus,'Y') = 'Y' THEN pricingsub.U_GrossTruckerRates
                    WHEN ISNULL(truckersub.VatStatus,'Y') = 'N' THEN (pricingsub.U_GrossTruckerRates / 1.12)
                END 
            ELSE 0.00 
            END
            +
            CASE WHEN T5.U_Rates LIKE '%U_ActualRates%' THEN 
                ISNULL(NULLIF(CAST(tpsub.U_ActualRates AS FLOAT),''),0)
            ELSE 0.00
            END 
            +
            CASE WHEN T5.U_Rates LIKE '%U_RateAdjustments%' THEN 
                ISNULL(NULLIF(CAST(tpsub.U_RateAdjustments AS FLOAT),''),0)
            ELSE 0.00
            END 
            +
            CASE WHEN T5.U_Rates LIKE '%U_DemurrageN%' THEN 
                CASE
                    WHEN ISNULL(truckersub.VatStatus,'Y') = 'Y' THEN pricingsub.U_Demurrage2
                    WHEN ISNULL(truckersub.VatStatus,'Y') = 'N' THEN (pricingsub.U_Demurrage2 / 1.12) 
                END
            ELSE 0.00
            END 
            +  
            CASE WHEN T5.U_Rates LIKE '%U_totalAddtlCharges2%' THEN 
                ISNULL(NULLIF(CAST(tpsub.U_ActualCharges AS FLOAT),''),0)
            ELSE 0.00
            END 
            +  
            CASE WHEN T5.U_Rates LIKE '%U_ActualDemurrage%' THEN 
                ISNULL(NULLIF(CAST(tpsub.U_ActualDemurrage AS FLOAT),''),0)
            ELSE 0.00
            END 
            +  
            CASE WHEN T5.U_Rates LIKE '%U_ActualCharges%' THEN 
                ISNULL(NULLIF(CAST(tpsub.U_ActualCharges AS FLOAT),''),0)

            ELSE 0.00
            END 
            +  
            CASE WHEN T5.U_Rates LIKE '%U_BoomTruck2%' THEN 
                ISNULL(NULLIF(CAST(tpsub.U_BoomTruck2 AS FLOAT),''),0)
            ELSE 0.00
            END 
            +  
            CASE WHEN T5.U_Rates LIKE '%U_OtherCharges%' THEN 
                ISNULL(NULLIF(CAST(tpsub.U_OtherCharges AS FLOAT),''),0)
            ELSE 0.00
            END 

        )
        -
        ISNULL(tpsub.U_OtherDeductions,0) 

        +

            abs(dbo.computeTotalPenaltyWaived(
                dbo.computeTotalSubPenalties(
                    dbo.computeClientPenaltyCalc(
                        dbo.computeClientSubOverdue(
                            podsub.U_DeliveryDateDTR,
                            podsub.U_ClientReceivedDate,
                            ISNULL(podsub.U_WaivedDays, 0),
                            CAST(ISNULL(clientsub.U_DCD,0) as int)
                        )
                    ),
                    dbo.computeInteluckPenaltyCalc(
                        dbo.computePODStatusPayment(
                            dbo.computeOverdueDays(
                                podsub.U_ActualHCRecDate,
                                dbo.computePODSubmitDeadline(
                                    podsub.U_DeliveryDateDTR,
                                    ISNULL(clientsub.U_CDC,0)
                                ),
                                ISNULL(podsub.U_HolidayOrWeekend, 0)
                            )
                        ),
                        dbo.computeOverdueDays(
                            podsub.U_ActualHCRecDate,
                            dbo.computePODSubmitDeadline(
                                podsub.U_DeliveryDateDTR,
                                ISNULL(clientsub.U_CDC,0)
                            ),
                            ISNULL(podsub.U_HolidayOrWeekend, 0)
                        )
                    ),
                    dbo.computeLostPenaltyCalc(
                        dbo.computePODStatusPayment(
                            dbo.computeOverdueDays(
                                podsub.U_ActualHCRecDate,
                                dbo.computePODSubmitDeadline(
                                    podsub.U_DeliveryDateDTR,
                                    ISNULL(clientsub.U_CDC,0)
                                ),
                                ISNULL(podsub.U_HolidayOrWeekend, 0)
                            )
                        ),
                        podsub.U_InitialHCRecDate,
                        podsub.U_DeliveryDateDTR,
                        pricingsub.U_TotalInitialTruckers
                    ),
                    ISNULL(podsub.U_PenaltiesManual,0)
                ),
                ISNULL(podsub.U_PercPenaltyCharge,0))
            ) AS TotalAmount




        FROM [@PCTP_TP] tpsub
            INNER JOIN [@PCTP_POD] podsub ON tpsub.U_BookingId = podsub.U_BookingNumber
            INNER JOIN OCRD truckersub ON podsub.U_SAPTrucker = truckersub.CardCode
            INNER JOIN OCRD clientsub ON U_SAPClient = clientsub.CardCode
            INNER JOIN [dbo].[@PCTP_PRICING] pricingsub ON tpsub.U_BookingId = pricingsub.U_BookingId
            --INNER JOIN [@RATESPERPV] ratessub ON ratessub.Code = tpsub.U_PVNo
            INNER JOIN [@RATESPERPV] T5 ON T5.Code = SUBSTRING(tpsub.U_PVNo, 11, 19)
        WHERE tpsub.U_BookingId =  T0.U_BookingId


        ),0)+ ISNULL((

        SELECT DISTINCT

            (

            ISNULL(TRY_PARSE(ratessub.U_Amount AS FLOAT),0)+
        --ISNULL(tpsub.U_ActualRates,0) +

        ISNULL(tpsub.U_RateAdjustments,0) +



            ISNULL(TRY_PARSE(ratessub.U_AddlAmount AS FLOAT),0)  
        --+

        --ISNULL(tpsub.U_ActualDemurrage,0) +
        --ISNULL(tpsub.U_ActualCharges,0)+
        --ISNULL(NULLIF(tpsub.U_BoomTruck2,''),0) +
        --ISNULL(tpsub.U_OtherCharges,0) 

        )

        -

        (ABS(dbo.computeTotalSubPenalties(
                dbo.computeClientPenaltyCalc(
                    dbo.computeClientSubOverdue(
                        podsub.U_DeliveryDateDTR,
                        podsub.U_ClientReceivedDate,
                        ISNULL(podsub.U_WaivedDays, 0),
                        CAST(ISNULL(clientsub.U_DCD,0) as int)
                    )
                ),
                dbo.computeInteluckPenaltyCalc(
                    dbo.computePODStatusPayment(
                        dbo.computeOverdueDays(
                            podsub.U_ActualHCRecDate,
                            dbo.computePODSubmitDeadline(
                                podsub.U_DeliveryDateDTR,
                                ISNULL(clientsub.U_CDC,0)
                            ),
                            ISNULL(podsub.U_HolidayOrWeekend, 0)
                        )
                    ),
                    dbo.computeOverdueDays(
                        podsub.U_ActualHCRecDate,
                        dbo.computePODSubmitDeadline(
                            podsub.U_DeliveryDateDTR,
                            ISNULL(clientsub.U_CDC,0)
                        ),
                        ISNULL(podsub.U_HolidayOrWeekend, 0)
                    )
                ),
                dbo.computeLostPenaltyCalc(
                    dbo.computePODStatusPayment(
                        dbo.computeOverdueDays(
                            podsub.U_ActualHCRecDate,
                            dbo.computePODSubmitDeadline(
                                podsub.U_DeliveryDateDTR,
                                ISNULL(clientsub.U_CDC,0)
                            ),
                            ISNULL(podsub.U_HolidayOrWeekend, 0)
                        )
                    ),
                    podsub.U_InitialHCRecDate,
                    podsub.U_DeliveryDateDTR,
                    pricingsub.U_TotalInitialTruckers
                ),
                ISNULL(podsub.U_PenaltiesManual,0)
            )) -

            dbo.computeTotalPenaltyWaived(
                dbo.computeTotalSubPenalties(
                    dbo.computeClientPenaltyCalc(
                        dbo.computeClientSubOverdue(
                            podsub.U_DeliveryDateDTR,
                            podsub.U_ClientReceivedDate,
                            ISNULL(podsub.U_WaivedDays, 0),
                            CAST(ISNULL(clientsub.U_DCD,0) as int)
                        )
                    ),
                    dbo.computeInteluckPenaltyCalc(
                        dbo.computePODStatusPayment(
                            dbo.computeOverdueDays(
                                podsub.U_ActualHCRecDate,
                                dbo.computePODSubmitDeadline(
                                    podsub.U_DeliveryDateDTR,
                                    ISNULL(clientsub.U_CDC,0)
                                ),
                                ISNULL(podsub.U_HolidayOrWeekend, 0)
                            )
                        ),
                        dbo.computeOverdueDays(
                            podsub.U_ActualHCRecDate,
                            dbo.computePODSubmitDeadline(
                                podsub.U_DeliveryDateDTR,
                                ISNULL(clientsub.U_CDC,0)
                            ),
                            ISNULL(podsub.U_HolidayOrWeekend, 0)
                        )
                    ),
                    dbo.computeLostPenaltyCalc(
                        dbo.computePODStatusPayment(
                            dbo.computeOverdueDays(
                                podsub.U_ActualHCRecDate,
                                dbo.computePODSubmitDeadline(
                                    podsub.U_DeliveryDateDTR,
                                    ISNULL(clientsub.U_CDC,0)
                                ),
                                ISNULL(podsub.U_HolidayOrWeekend, 0)
                            )
                        ),
                        podsub.U_InitialHCRecDate,
                        podsub.U_DeliveryDateDTR,
                        pricingsub.U_TotalInitialTruckers
                    ),
                    ISNULL(podsub.U_PenaltiesManual,0)
                ),
                ISNULL(podsub.U_PercPenaltyCharge,0)))



            AS TotalAmount




        FROM [@PCTP_TP] tpsub
            INNER JOIN [@PCTP_POD] podsub ON tpsub.U_BookingId = podsub.U_BookingNumber
            INNER JOIN OCRD truckersub ON podsub.U_SAPTrucker = truckersub.CardCode
            INNER JOIN OCRD clientsub ON U_SAPClient = clientsub.CardCode
            INNER JOIN [dbo].[@PCTP_PRICING] pricingsub ON tpsub.U_BookingId = pricingsub.U_BookingId
            LEFT JOIN [@FirstratesTP] ratessub ON ratessub.U_BN = tpsub.U_BookingId AND ratessub.U_PVNo = SUBSTRING(tpsub.U_PVNo, 1, 9)


        WHERE tpsub.U_BookingId = T0.U_BookingId

        )

        ,0)


                    --TOTAL AP 2 UNPAID  ------------
                    WHEN CHARINDEX(',', CAST((
                        SELECT DISTINCT
                SUBSTRING(
                                (
                                    SELECT CONCAT(', ', header.DocNum)  AS [text()]
                FROM PCH1 line
                    LEFT JOIN OPCH header ON header.DocEntry = line.DocEntry
                WHERE header.CANCELED = 'N' AND header.PaidSum = 0 AND (line.ItemCode = T0.U_BookingId
                    or REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%')
                FOR XML PATH (''), TYPE
                                ).value('text()[1]','nvarchar(max)'), 2, 1000) DocEntry
            FROM OPCH header
                LEFT JOIN PCH1 line ON line.DocEntry = header.DocEntry
            WHERE header.CANCELED = 'N' AND (line.ItemCode = T0.U_BookingId
                or REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%')) as nvarchar(max)
                        )) >  0 AND
            CAST((
                        SELECT DISTINCT
                SUBSTRING(
                            (
                                SELECT CONCAT(', ', header.DocNum)  AS [text()]
                FROM PCH1 line
                    LEFT JOIN OPCH header ON header.DocEntry = line.DocEntry
                WHERE header.CANCELED = 'N' AND header.PaidSum > 0 AND (line.ItemCode = T0.U_BookingId
                    or REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%')
                FOR XML PATH (''), TYPE
                            ).value('text()[1]','nvarchar(max)'), 2, 1000) DocEntry
            FROM OPCH header
                LEFT JOIN PCH1 line ON line.DocEntry = header.DocEntry
            WHERE header.CANCELED = 'N' AND (line.ItemCode = T0.U_BookingId
                or REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%')) as nvarchar(max)
                    ) IS NULL
                    THEN 
                    ISNULL((
                        SELECT DISTINCT

            (
                            CASE WHEN T5.U_Rates LIKE '%U_GrossTruckerRates%' THEN 
                                CASE
                                    WHEN ISNULL( truckersub.VatStatus,'Y') = 'Y' THEN pricingsub.U_GrossTruckerRates
                                    WHEN ISNULL(truckersub.VatStatus,'Y') = 'N' THEN (pricingsub.U_GrossTruckerRates / 1.12)
                                END 
                            ELSE 0.00 
                            END
                            +
                            CASE WHEN T5.U_Rates LIKE '%U_ActualRates%' THEN 
                                ISNULL(NULLIF(CAST(tpsub.U_ActualRates AS FLOAT),''),0)
                            ELSE 0.00
                            END 
                            +
                            CASE WHEN T5.U_Rates LIKE '%U_RateAdjustments%' THEN 
                                ISNULL(NULLIF(CAST(tpsub.U_RateAdjustments AS FLOAT),''),0)
                            ELSE 0.00
                            END 
                            +
                            CASE WHEN T5.U_Rates LIKE '%U_DemurrageN%' THEN 
                                CASE
                                    WHEN ISNULL(truckersub.VatStatus,'Y') = 'Y' THEN pricingsub.U_Demurrage2
                                    WHEN ISNULL(truckersub.VatStatus,'Y') = 'N' THEN (pricingsub.U_Demurrage2 / 1.12) 
                                END
                            ELSE 0.00
                            END 
                            +  
                            CASE WHEN T5.U_Rates LIKE '%U_totalAddtlCharges2%' THEN 
                                ISNULL(NULLIF(CAST(tpsub.U_ActualCharges AS FLOAT),''),0)
                            ELSE 0.00
                            END 
                            +  
                            CASE WHEN T5.U_Rates LIKE '%U_ActualDemurrage%' THEN 
                                ISNULL(NULLIF(CAST(tpsub.U_ActualDemurrage AS FLOAT),''),0)
                            ELSE 0.00
                            END 
                            +  
                            CASE WHEN T5.U_Rates LIKE '%U_ActualCharges%' THEN 
                                ISNULL(NULLIF(CAST(tpsub.U_ActualCharges AS FLOAT),''),0)

                            ELSE 0.00
                            END 
                            +  
                            CASE WHEN T5.U_Rates LIKE '%U_BoomTruck2%' THEN 
                                ISNULL(NULLIF(CAST(tpsub.U_BoomTruck2 AS FLOAT),''),0)
                            ELSE 0.00
                            END 
                            +  
                            CASE WHEN T5.U_Rates LIKE '%U_OtherCharges%' THEN 
                                ISNULL(NULLIF(CAST(tpsub.U_OtherCharges AS FLOAT),''),0)
                            ELSE 0.00
                            END 

                        )
                        -
                        ISNULL(tpsub.U_OtherDeductions,0) 

                        +

                            abs(dbo.computeTotalPenaltyWaived(
                                dbo.computeTotalSubPenalties(
                                    dbo.computeClientPenaltyCalc(
                                        dbo.computeClientSubOverdue(
                                            podsub.U_DeliveryDateDTR,
                                            podsub.U_ClientReceivedDate,
                                            ISNULL(podsub.U_WaivedDays, 0),
                                            CAST(ISNULL(clientsub.U_DCD,0) as int)
                                        )
                                    ),
                                    dbo.computeInteluckPenaltyCalc(
                                        dbo.computePODStatusPayment(
                                            dbo.computeOverdueDays(
                                                podsub.U_ActualHCRecDate,
                                                dbo.computePODSubmitDeadline(
                                                    podsub.U_DeliveryDateDTR,
                                                    ISNULL(clientsub.U_CDC,0)
                                                ),
                                                ISNULL(podsub.U_HolidayOrWeekend, 0)
                                            )
                                        ),
                                        dbo.computeOverdueDays(
                                            podsub.U_ActualHCRecDate,
                                            dbo.computePODSubmitDeadline(
                                                podsub.U_DeliveryDateDTR,
                                                ISNULL(clientsub.U_CDC,0)
                                            ),
                                            ISNULL(podsub.U_HolidayOrWeekend, 0)
                                        )
                                    ),
                                    dbo.computeLostPenaltyCalc(
                                        dbo.computePODStatusPayment(
                                            dbo.computeOverdueDays(
                                                podsub.U_ActualHCRecDate,
                                                dbo.computePODSubmitDeadline(
                                                    podsub.U_DeliveryDateDTR,
                                                    ISNULL(clientsub.U_CDC,0)
                                                ),
                                                ISNULL(podsub.U_HolidayOrWeekend, 0)
                                            )
                                        ),
                                        podsub.U_InitialHCRecDate,
                                        podsub.U_DeliveryDateDTR,
                                        pricingsub.U_TotalInitialTruckers
                                    ),
                                    ISNULL(podsub.U_PenaltiesManual,0)
                                ),
                                ISNULL(podsub.U_PercPenaltyCharge,0))
                            ) AS TotalAmount




        FROM [@PCTP_TP] tpsub
            INNER JOIN [@PCTP_POD] podsub ON tpsub.U_BookingId = podsub.U_BookingNumber
            INNER JOIN OCRD truckersub ON podsub.U_SAPTrucker = truckersub.CardCode
            INNER JOIN OCRD clientsub ON U_SAPClient = clientsub.CardCode
            INNER JOIN [dbo].[@PCTP_PRICING] pricingsub ON tpsub.U_BookingId = pricingsub.U_BookingId
            --INNER JOIN [@RATESPERPV] ratessub ON ratessub.Code = tpsub.U_PVNo
            INNER JOIN [@RATESPERPV] T5 ON T5.Code = SUBSTRING(tpsub.U_PVNo, 11, 19)
        WHERE tpsub.U_BookingId =  T0.U_BookingId


                        ),0)+ ISNULL((

                        SELECT DISTINCT

            (

                            ISNULL(TRY_PARSE(ratessub.U_Amount AS FLOAT),0)+
                        --ISNULL(tpsub.U_ActualRates,0) +

                            ISNULL(tpsub.U_RateAdjustments,0) +



                            ISNULL(TRY_PARSE(ratessub.U_AddlAmount AS FLOAT),0)  
                        --+

                        --ISNULL(tpsub.U_ActualDemurrage,0) +
                        --ISNULL(tpsub.U_ActualCharges,0)+
                        --ISNULL(NULLIF(tpsub.U_BoomTruck2,''),0) +
                        --ISNULL(tpsub.U_OtherCharges,0) 

                        )

                        -

                        (ABS(dbo.computeTotalSubPenalties(
                                dbo.computeClientPenaltyCalc(
                                    dbo.computeClientSubOverdue(
                                        podsub.U_DeliveryDateDTR,
                                        podsub.U_ClientReceivedDate,
                                        ISNULL(podsub.U_WaivedDays, 0),
                                        CAST(ISNULL(clientsub.U_DCD,0) as int)
                                    )
                                ),
                                dbo.computeInteluckPenaltyCalc(
                                    dbo.computePODStatusPayment(
                                        dbo.computeOverdueDays(
                                            podsub.U_ActualHCRecDate,
                                            dbo.computePODSubmitDeadline(
                                                podsub.U_DeliveryDateDTR,
                                                ISNULL(clientsub.U_CDC,0)
                                            ),
                                            ISNULL(podsub.U_HolidayOrWeekend, 0)
                                        )
                                    ),
                                    dbo.computeOverdueDays(
                                        podsub.U_ActualHCRecDate,
                                        dbo.computePODSubmitDeadline(
                                            podsub.U_DeliveryDateDTR,
                                            ISNULL(clientsub.U_CDC,0)
                                        ),
                                        ISNULL(podsub.U_HolidayOrWeekend, 0)
                                    )
                                ),
                                dbo.computeLostPenaltyCalc(
                                    dbo.computePODStatusPayment(
                                        dbo.computeOverdueDays(
                                            podsub.U_ActualHCRecDate,
                                            dbo.computePODSubmitDeadline(
                                                podsub.U_DeliveryDateDTR,
                                                ISNULL(clientsub.U_CDC,0)
                                            ),
                                            ISNULL(podsub.U_HolidayOrWeekend, 0)
                                        )
                                    ),
                                    podsub.U_InitialHCRecDate,
                                    podsub.U_DeliveryDateDTR,
                                    pricingsub.U_TotalInitialTruckers
                                ),
                                ISNULL(podsub.U_PenaltiesManual,0)
                            )) -

                            dbo.computeTotalPenaltyWaived(
                                dbo.computeTotalSubPenalties(
                                    dbo.computeClientPenaltyCalc(
                                        dbo.computeClientSubOverdue(
                                            podsub.U_DeliveryDateDTR,
                                            podsub.U_ClientReceivedDate,
                                            ISNULL(podsub.U_WaivedDays, 0),
                                            CAST(ISNULL(clientsub.U_DCD,0) as int)
                                        )
                                    ),
                                    dbo.computeInteluckPenaltyCalc(
                                        dbo.computePODStatusPayment(
                                            dbo.computeOverdueDays(
                                                podsub.U_ActualHCRecDate,
                                                dbo.computePODSubmitDeadline(
                                                    podsub.U_DeliveryDateDTR,
                                                    ISNULL(clientsub.U_CDC,0)
                                                ),
                                                ISNULL(podsub.U_HolidayOrWeekend, 0)
                                            )
                                        ),
                                        dbo.computeOverdueDays(
                                            podsub.U_ActualHCRecDate,
                                            dbo.computePODSubmitDeadline(
                                                podsub.U_DeliveryDateDTR,
                                                ISNULL(clientsub.U_CDC,0)
                                            ),
                                            ISNULL(podsub.U_HolidayOrWeekend, 0)
                                        )
                                    ),
                                    dbo.computeLostPenaltyCalc(
                                        dbo.computePODStatusPayment(
                                            dbo.computeOverdueDays(
                                                podsub.U_ActualHCRecDate,
                                                dbo.computePODSubmitDeadline(
                                                    podsub.U_DeliveryDateDTR,
                                                    ISNULL(clientsub.U_CDC,0)
                                                ),
                                                ISNULL(podsub.U_HolidayOrWeekend, 0)
                                            )
                                        ),
                                        podsub.U_InitialHCRecDate,
                                        podsub.U_DeliveryDateDTR,
                                        pricingsub.U_TotalInitialTruckers
                                    ),
                                    ISNULL(podsub.U_PenaltiesManual,0)
                                ),
                                ISNULL(podsub.U_PercPenaltyCharge,0)))



                            AS TotalAmount




        FROM [@PCTP_TP] tpsub
            INNER JOIN [@PCTP_POD] podsub ON tpsub.U_BookingId = podsub.U_BookingNumber
            INNER JOIN OCRD truckersub ON podsub.U_SAPTrucker = truckersub.CardCode
            INNER JOIN OCRD clientsub ON U_SAPClient = clientsub.CardCode
            INNER JOIN [dbo].[@PCTP_PRICING] pricingsub ON tpsub.U_BookingId = pricingsub.U_BookingId
            LEFT JOIN [@FirstratesTP] ratessub ON ratessub.U_BN = tpsub.U_BookingId AND ratessub.U_PVNo = SUBSTRING(tpsub.U_PVNo, 1, 9)


        WHERE tpsub.U_BookingId = T0.U_BookingId

                        )

                        ,0)


                    --TOTAL AP 1 PAID  NO UNPAID------------
                    WHEN CAST((
                        SELECT DISTINCT
                SUBSTRING(
                                (
                                    SELECT CONCAT(', ', header.DocNum)  AS [text()]
                FROM PCH1 line
                    LEFT JOIN OPCH header ON header.DocEntry = line.DocEntry
                WHERE header.CANCELED = 'N' AND header.PaidSum = 0 AND (line.ItemCode = T0.U_BookingId
                    or REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%')
                FOR XML PATH (''), TYPE
                                ).value('text()[1]','nvarchar(max)'), 2, 1000) DocEntry
            FROM OPCH header
                LEFT JOIN PCH1 line ON line.DocEntry = header.DocEntry
            WHERE header.CANCELED = 'N' AND (line.ItemCode = T0.U_BookingId
                or REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%')) as nvarchar(max)
                        ) IS NULL AND
            CAST((
                        SELECT DISTINCT
                SUBSTRING(
                            (
                                SELECT CONCAT(', ', header.DocNum)  AS [text()]
                FROM PCH1 line
                    LEFT JOIN OPCH header ON header.DocEntry = line.DocEntry
                WHERE header.CANCELED = 'N' AND header.PaidSum > 0 AND (line.ItemCode = T0.U_BookingId
                    or REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%')
                FOR XML PATH (''), TYPE
                            ).value('text()[1]','nvarchar(max)'), 2, 1000) DocEntry
            FROM OPCH header
                LEFT JOIN PCH1 line ON line.DocEntry = header.DocEntry
            WHERE header.CANCELED = 'N' AND (line.ItemCode = T0.U_BookingId
                or REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%')) as nvarchar(max)
                    ) IS NOT NULL
                    THEN 
                    ISNULL((

                        SELECT DISTINCT

            (

                            ISNULL(TRY_PARSE(ratessub.U_Amount AS FLOAT),0)+
                        --ISNULL(tpsub.U_ActualRates,0) +

                            ISNULL(tpsub.U_RateAdjustments,0) +



                            ISNULL(TRY_PARSE(ratessub.U_AddlAmount AS FLOAT),0)  
                        --+

                        --ISNULL(tpsub.U_ActualDemurrage,0) +
                        --ISNULL(tpsub.U_ActualCharges,0)+
                        --ISNULL(NULLIF(tpsub.U_BoomTruck2,''),0) +
                        --ISNULL(tpsub.U_OtherCharges,0) 

                        )

                        -

                        (ABS(dbo.computeTotalSubPenalties(
                                dbo.computeClientPenaltyCalc(
                                    dbo.computeClientSubOverdue(
                                        podsub.U_DeliveryDateDTR,
                                        podsub.U_ClientReceivedDate,
                                        ISNULL(podsub.U_WaivedDays, 0),
                                        CAST(ISNULL(clientsub.U_DCD,0) as int)
                                    )
                                ),
                                dbo.computeInteluckPenaltyCalc(
                                    dbo.computePODStatusPayment(
                                        dbo.computeOverdueDays(
                                            podsub.U_ActualHCRecDate,
                                            dbo.computePODSubmitDeadline(
                                                podsub.U_DeliveryDateDTR,
                                                ISNULL(clientsub.U_CDC,0)
                                            ),
                                            ISNULL(podsub.U_HolidayOrWeekend, 0)
                                        )
                                    ),
                                    dbo.computeOverdueDays(
                                        podsub.U_ActualHCRecDate,
                                        dbo.computePODSubmitDeadline(
                                            podsub.U_DeliveryDateDTR,
                                            ISNULL(clientsub.U_CDC,0)
                                        ),
                                        ISNULL(podsub.U_HolidayOrWeekend, 0)
                                    )
                                ),
                                dbo.computeLostPenaltyCalc(
                                    dbo.computePODStatusPayment(
                                        dbo.computeOverdueDays(
                                            podsub.U_ActualHCRecDate,
                                            dbo.computePODSubmitDeadline(
                                                podsub.U_DeliveryDateDTR,
                                                ISNULL(clientsub.U_CDC,0)
                                            ),
                                            ISNULL(podsub.U_HolidayOrWeekend, 0)
                                        )
                                    ),
                                    podsub.U_InitialHCRecDate,
                                    podsub.U_DeliveryDateDTR,
                                    pricingsub.U_TotalInitialTruckers
                                ),
                                ISNULL(podsub.U_PenaltiesManual,0)
                            )) -

                            dbo.computeTotalPenaltyWaived(
                                dbo.computeTotalSubPenalties(
                                    dbo.computeClientPenaltyCalc(
                                        dbo.computeClientSubOverdue(
                                            podsub.U_DeliveryDateDTR,
                                            podsub.U_ClientReceivedDate,
                                            ISNULL(podsub.U_WaivedDays, 0),
                                            CAST(ISNULL(clientsub.U_DCD,0) as int)
                                        )
                                    ),
                                    dbo.computeInteluckPenaltyCalc(
                                        dbo.computePODStatusPayment(
                                            dbo.computeOverdueDays(
                                                podsub.U_ActualHCRecDate,
                                                dbo.computePODSubmitDeadline(
                                                    podsub.U_DeliveryDateDTR,
                                                    ISNULL(clientsub.U_CDC,0)
                                                ),
                                                ISNULL(podsub.U_HolidayOrWeekend, 0)
                                            )
                                        ),
                                        dbo.computeOverdueDays(
                                            podsub.U_ActualHCRecDate,
                                            dbo.computePODSubmitDeadline(
                                                podsub.U_DeliveryDateDTR,
                                                ISNULL(clientsub.U_CDC,0)
                                            ),
                                            ISNULL(podsub.U_HolidayOrWeekend, 0)
                                        )
                                    ),
                                    dbo.computeLostPenaltyCalc(
                                        dbo.computePODStatusPayment(
                                            dbo.computeOverdueDays(
                                                podsub.U_ActualHCRecDate,
                                                dbo.computePODSubmitDeadline(
                                                    podsub.U_DeliveryDateDTR,
                                                    ISNULL(clientsub.U_CDC,0)
                                                ),
                                                ISNULL(podsub.U_HolidayOrWeekend, 0)
                                            )
                                        ),
                                        podsub.U_InitialHCRecDate,
                                        podsub.U_DeliveryDateDTR,
                                        pricingsub.U_TotalInitialTruckers
                                    ),
                                    ISNULL(podsub.U_PenaltiesManual,0)
                                ),
                                ISNULL(podsub.U_PercPenaltyCharge,0)))



                            AS TotalAmount




        FROM [@PCTP_TP] tpsub
            INNER JOIN [@PCTP_POD] podsub ON tpsub.U_BookingId = podsub.U_BookingNumber
            INNER JOIN OCRD truckersub ON podsub.U_SAPTrucker = truckersub.CardCode
            INNER JOIN OCRD clientsub ON U_SAPClient = clientsub.CardCode
            INNER JOIN [dbo].[@PCTP_PRICING] pricingsub ON tpsub.U_BookingId = pricingsub.U_BookingId
            LEFT JOIN [@FirstratesTP] ratessub ON ratessub.U_BN = tpsub.U_BookingId AND ratessub.U_PVNo = SUBSTRING(tpsub.U_PVNo, 1, 9)


        WHERE tpsub.U_BookingId = T0.U_BookingId

                        )

                        ,0)

                    --TOTAL AP 1 UNPAID  ------------
                    WHEN CAST((
                        SELECT DISTINCT
                SUBSTRING(
                                (
                                    SELECT CONCAT(', ', header.DocNum)  AS [text()]
                FROM PCH1 line
                    LEFT JOIN OPCH header ON header.DocEntry = line.DocEntry
                WHERE header.CANCELED = 'N' AND header.PaidSum = 0 AND (line.ItemCode = T0.U_BookingId
                    or REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%')
                FOR XML PATH (''), TYPE
                                ).value('text()[1]','nvarchar(max)'), 2, 1000) DocEntry
            FROM OPCH header
                LEFT JOIN PCH1 line ON line.DocEntry = header.DocEntry
            WHERE header.CANCELED = 'N' AND (line.ItemCode = T0.U_BookingId
                or REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%')) as nvarchar(max)
                        ) IS NOT NULL AND
            CAST((
                        SELECT DISTINCT
                SUBSTRING(
                            (
                                SELECT CONCAT(', ', header.DocNum)  AS [text()]
                FROM PCH1 line
                    LEFT JOIN OPCH header ON header.DocEntry = line.DocEntry
                WHERE header.CANCELED = 'N' AND header.PaidSum > 0 AND (line.ItemCode = T0.U_BookingId
                    or REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%')
                FOR XML PATH (''), TYPE
                            ).value('text()[1]','nvarchar(max)'), 2, 1000) DocEntry
            FROM OPCH header
                LEFT JOIN PCH1 line ON line.DocEntry = header.DocEntry
            WHERE header.CANCELED = 'N' AND (line.ItemCode = T0.U_BookingId
                or REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%')) as nvarchar(max)
                    ) IS NULL
                    THEN ISNULL((

                        SELECT DISTINCT

            (

                            ISNULL(TRY_PARSE(ratessub.U_Amount AS FLOAT),0)+
                        --ISNULL(tpsub.U_ActualRates,0) +

                            ISNULL(tpsub.U_RateAdjustments,0) +



                            ISNULL(TRY_PARSE(ratessub.U_AddlAmount AS FLOAT),0)  
                        --+

                        --ISNULL(tpsub.U_ActualDemurrage,0) +
                        --ISNULL(tpsub.U_ActualCharges,0)+
                        --ISNULL(NULLIF(tpsub.U_BoomTruck2,''),0) +
                        --ISNULL(tpsub.U_OtherCharges,0) 

                        )

                        -

                        (ABS(dbo.computeTotalSubPenalties(
                                dbo.computeClientPenaltyCalc(
                                    dbo.computeClientSubOverdue(
                                        podsub.U_DeliveryDateDTR,
                                        podsub.U_ClientReceivedDate,
                                        ISNULL(podsub.U_WaivedDays, 0),
                                        CAST(ISNULL(clientsub.U_DCD,0) as int)
                                    )
                                ),
                                dbo.computeInteluckPenaltyCalc(
                                    dbo.computePODStatusPayment(
                                        dbo.computeOverdueDays(
                                            podsub.U_ActualHCRecDate,
                                            dbo.computePODSubmitDeadline(
                                                podsub.U_DeliveryDateDTR,
                                                ISNULL(clientsub.U_CDC,0)
                                            ),
                                            ISNULL(podsub.U_HolidayOrWeekend, 0)
                                        )
                                    ),
                                    dbo.computeOverdueDays(
                                        podsub.U_ActualHCRecDate,
                                        dbo.computePODSubmitDeadline(
                                            podsub.U_DeliveryDateDTR,
                                            ISNULL(clientsub.U_CDC,0)
                                        ),
                                        ISNULL(podsub.U_HolidayOrWeekend, 0)
                                    )
                                ),
                                dbo.computeLostPenaltyCalc(
                                    dbo.computePODStatusPayment(
                                        dbo.computeOverdueDays(
                                            podsub.U_ActualHCRecDate,
                                            dbo.computePODSubmitDeadline(
                                                podsub.U_DeliveryDateDTR,
                                                ISNULL(clientsub.U_CDC,0)
                                            ),
                                            ISNULL(podsub.U_HolidayOrWeekend, 0)
                                        )
                                    ),
                                    podsub.U_InitialHCRecDate,
                                    podsub.U_DeliveryDateDTR,
                                    pricingsub.U_TotalInitialTruckers
                                ),
                                ISNULL(podsub.U_PenaltiesManual,0)
                            )) -

                            dbo.computeTotalPenaltyWaived(
                                dbo.computeTotalSubPenalties(
                                    dbo.computeClientPenaltyCalc(
                                        dbo.computeClientSubOverdue(
                                            podsub.U_DeliveryDateDTR,
                                            podsub.U_ClientReceivedDate,
                                            ISNULL(podsub.U_WaivedDays, 0),
                                            CAST(ISNULL(clientsub.U_DCD,0) as int)
                                        )
                                    ),
                                    dbo.computeInteluckPenaltyCalc(
                                        dbo.computePODStatusPayment(
                                            dbo.computeOverdueDays(
                                                podsub.U_ActualHCRecDate,
                                                dbo.computePODSubmitDeadline(
                                                    podsub.U_DeliveryDateDTR,
                                                    ISNULL(clientsub.U_CDC,0)
                                                ),
                                                ISNULL(podsub.U_HolidayOrWeekend, 0)
                                            )
                                        ),
                                        dbo.computeOverdueDays(
                                            podsub.U_ActualHCRecDate,
                                            dbo.computePODSubmitDeadline(
                                                podsub.U_DeliveryDateDTR,
                                                ISNULL(clientsub.U_CDC,0)
                                            ),
                                            ISNULL(podsub.U_HolidayOrWeekend, 0)
                                        )
                                    ),
                                    dbo.computeLostPenaltyCalc(
                                        dbo.computePODStatusPayment(
                                            dbo.computeOverdueDays(
                                                podsub.U_ActualHCRecDate,
                                                dbo.computePODSubmitDeadline(
                                                    podsub.U_DeliveryDateDTR,
                                                    ISNULL(clientsub.U_CDC,0)
                                                ),
                                                ISNULL(podsub.U_HolidayOrWeekend, 0)
                                            )
                                        ),
                                        podsub.U_InitialHCRecDate,
                                        podsub.U_DeliveryDateDTR,
                                        pricingsub.U_TotalInitialTruckers
                                    ),
                                    ISNULL(podsub.U_PenaltiesManual,0)
                                ),
                                ISNULL(podsub.U_PercPenaltyCharge,0)))



                            AS TotalAmount




        FROM [@PCTP_TP] tpsub
            INNER JOIN [@PCTP_POD] podsub ON tpsub.U_BookingId = podsub.U_BookingNumber
            INNER JOIN OCRD truckersub ON podsub.U_SAPTrucker = truckersub.CardCode
            INNER JOIN OCRD clientsub ON U_SAPClient = clientsub.CardCode
            INNER JOIN [dbo].[@PCTP_PRICING] pricingsub ON tpsub.U_BookingId = pricingsub.U_BookingId
            LEFT JOIN [@FirstratesTP] ratessub ON ratessub.U_BN = tpsub.U_BookingId AND ratessub.U_PVNo = SUBSTRING(tpsub.U_PVNo, 1, 9)


        WHERE tpsub.U_BookingId = T0.U_BookingId

                        )

                        ,0)
                    ELSE 

                    0.00
                END
            ELSE 0.00
        END AS U_TotalAP,
        -- (SELECT
        --     CV.U_TotalAP
        -- FROM ConcatenatedValued CV
        -- WHERE CV.U_BookingId = T0.U_BookingId) AS U_TotalAP,
        CASE


            WHEN EXISTS(
                SELECT 1
        FROM OPCH header
            LEFT JOIN PCH1 line ON header.DocEntry = line.DocEntry
        WHERE header.CANCELED = 'N' AND REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%'
            ) THEN 
                CASE 
                    --TOTAL AP 2 PAID  ------------
                    WHEN CHARINDEX(',', CAST((
                        SELECT DISTINCT
                SUBSTRING(
                                (
                                    SELECT CONCAT(', ', header.DocNum)  AS [text()]
                FROM PCH1 line
                    LEFT JOIN OPCH header ON header.DocEntry = line.DocEntry
                WHERE header.CANCELED = 'N' AND header.PaidSum > 0 AND (line.ItemCode = T0.U_BookingId
                    or REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%')
                FOR XML PATH (''), TYPE
                                ).value('text()[1]','nvarchar(max)'), 2, 1000) DocEntry
            FROM OPCH header
                LEFT JOIN PCH1 line ON line.DocEntry = header.DocEntry
            WHERE header.CANCELED = 'N' AND (line.ItemCode = T0.U_BookingId
                or REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%')) as nvarchar(max)
                        )) >  0 AND
            CAST((
                            SELECT DISTINCT
                SUBSTRING(
                                (
                                    SELECT CONCAT(', ', header.DocNum)  AS [text()]
                FROM PCH1 line
                    LEFT JOIN OPCH header ON header.DocEntry = line.DocEntry
                WHERE header.CANCELED = 'N' AND header.PaidSum = 0 AND (line.ItemCode = T0.U_BookingId
                    or REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%')
                FOR XML PATH (''), TYPE
                                ).value('text()[1]','nvarchar(max)'), 2, 1000) DocEntry
            FROM OPCH header
                LEFT JOIN PCH1 line ON line.DocEntry = header.DocEntry
            WHERE header.CANCELED = 'N' AND (line.ItemCode = T0.U_BookingId
                or REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%')) as nvarchar(max)
                        ) IS NULL
                    THEN 
                    ISNULL((
                        SELECT DISTINCT

            (
                            CASE WHEN T5.U_Rates LIKE '%U_GrossTruckerRates%' THEN 
                                CASE
                                    WHEN ISNULL( truckersub.VatStatus,'Y') = 'Y' THEN pricingsub.U_GrossTruckerRates
                                    WHEN ISNULL(truckersub.VatStatus,'Y') = 'N' THEN (pricingsub.U_GrossTruckerRates / 1.12)
                                END 
                            ELSE 0.00 
                            END
                            +
                            CASE WHEN T5.U_Rates LIKE '%U_ActualRates%' THEN 
                                ISNULL(NULLIF(CAST(tpsub.U_ActualRates AS FLOAT),''),0)
                            ELSE 0.00
                            END 
                            +
                            CASE WHEN T5.U_Rates LIKE '%U_RateAdjustments%' THEN 
                                ISNULL(NULLIF(CAST(tpsub.U_RateAdjustments AS FLOAT),''),0)
                            ELSE 0.00
                            END 
                            +
                            CASE WHEN T5.U_Rates LIKE '%U_DemurrageN%' THEN 
                                CASE
                                    WHEN ISNULL(truckersub.VatStatus,'Y') = 'Y' THEN pricingsub.U_Demurrage2
                                    WHEN ISNULL(truckersub.VatStatus,'Y') = 'N' THEN (pricingsub.U_Demurrage2 / 1.12) 
                                END
                            ELSE 0.00
                            END 
                            +  
                            CASE WHEN T5.U_Rates LIKE '%U_totalAddtlCharges2%' THEN 
                                ISNULL(NULLIF(CAST(tpsub.U_ActualCharges AS FLOAT),''),0)
                            ELSE 0.00
                            END 
                            +  
                            CASE WHEN T5.U_Rates LIKE '%U_ActualDemurrage%' THEN 
                                ISNULL(NULLIF(CAST(tpsub.U_ActualDemurrage AS FLOAT),''),0)
                            ELSE 0.00
                            END 
                            +  
                            CASE WHEN T5.U_Rates LIKE '%U_ActualCharges%' THEN 
                                ISNULL(NULLIF(CAST(tpsub.U_ActualCharges AS FLOAT),''),0)

                            ELSE 0.00
                            END 
                            +  
                            CASE WHEN T5.U_Rates LIKE '%U_BoomTruck2%' THEN 
                                ISNULL(NULLIF(CAST(tpsub.U_BoomTruck2 AS FLOAT),''),0)
                            ELSE 0.00
                            END 
                            +  
                            CASE WHEN T5.U_Rates LIKE '%U_OtherCharges%' THEN 
                                ISNULL(NULLIF(CAST(tpsub.U_OtherCharges AS FLOAT),''),0)
                            ELSE 0.00
                            END 

                        )
                        -
                        ISNULL(tpsub.U_OtherDeductions,0) 

                        +

                            abs(dbo.computeTotalPenaltyWaived(
                                dbo.computeTotalSubPenalties(
                                    dbo.computeClientPenaltyCalc(
                                        dbo.computeClientSubOverdue(
                                            podsub.U_DeliveryDateDTR,
                                            podsub.U_ClientReceivedDate,
                                            ISNULL(podsub.U_WaivedDays, 0),
                                            CAST(ISNULL(clientsub.U_DCD,0) as int)
                                        )
                                    ),
                                    dbo.computeInteluckPenaltyCalc(
                                        dbo.computePODStatusPayment(
                                            dbo.computeOverdueDays(
                                                podsub.U_ActualHCRecDate,
                                                dbo.computePODSubmitDeadline(
                                                    podsub.U_DeliveryDateDTR,
                                                    ISNULL(clientsub.U_CDC,0)
                                                ),
                                                ISNULL(podsub.U_HolidayOrWeekend, 0)
                                            )
                                        ),
                                        dbo.computeOverdueDays(
                                            podsub.U_ActualHCRecDate,
                                            dbo.computePODSubmitDeadline(
                                                podsub.U_DeliveryDateDTR,
                                                ISNULL(clientsub.U_CDC,0)
                                            ),
                                            ISNULL(podsub.U_HolidayOrWeekend, 0)
                                        )
                                    ),
                                    dbo.computeLostPenaltyCalc(
                                        dbo.computePODStatusPayment(
                                            dbo.computeOverdueDays(
                                                podsub.U_ActualHCRecDate,
                                                dbo.computePODSubmitDeadline(
                                                    podsub.U_DeliveryDateDTR,
                                                    ISNULL(clientsub.U_CDC,0)
                                                ),
                                                ISNULL(podsub.U_HolidayOrWeekend, 0)
                                            )
                                        ),
                                        podsub.U_InitialHCRecDate,
                                        podsub.U_DeliveryDateDTR,
                                        pricingsub.U_TotalInitialTruckers
                                    ),
                                    ISNULL(podsub.U_PenaltiesManual,0)
                                ),
                                ISNULL(podsub.U_PercPenaltyCharge,0))
                            ) AS TotalAmount




        FROM [@PCTP_TP] tpsub
            INNER JOIN [@PCTP_POD] podsub ON tpsub.U_BookingId = podsub.U_BookingNumber
            INNER JOIN OCRD truckersub ON podsub.U_SAPTrucker = truckersub.CardCode
            INNER JOIN OCRD clientsub ON U_SAPClient = clientsub.CardCode
            INNER JOIN [dbo].[@PCTP_PRICING] pricingsub ON tpsub.U_BookingId = pricingsub.U_BookingId
            --INNER JOIN [@RATESPERPV] ratessub ON ratessub.Code = tpsub.U_PVNo
            INNER JOIN [@RATESPERPV] T5 ON T5.Code = SUBSTRING(tpsub.U_PVNo, 11, 19)
        WHERE tpsub.U_BookingId =  T0.U_BookingId


                        ),0)+ ISNULL((

                        SELECT DISTINCT

            (

                            ISNULL(TRY_PARSE(ratessub.U_Amount AS FLOAT),0)+
                        --ISNULL(tpsub.U_ActualRates,0) +

                            ISNULL(tpsub.U_RateAdjustments,0) +



                            ISNULL(TRY_PARSE(ratessub.U_AddlAmount AS FLOAT),0)  
                        --+

                        --ISNULL(tpsub.U_ActualDemurrage,0) +
                        --ISNULL(tpsub.U_ActualCharges,0)+
                        --ISNULL(NULLIF(tpsub.U_BoomTruck2,''),0) +
                        --ISNULL(tpsub.U_OtherCharges,0) 

                        )

                        -

                        (ABS(dbo.computeTotalSubPenalties(
                                dbo.computeClientPenaltyCalc(
                                    dbo.computeClientSubOverdue(
                                        podsub.U_DeliveryDateDTR,
                                        podsub.U_ClientReceivedDate,
                                        ISNULL(podsub.U_WaivedDays, 0),
                                        CAST(ISNULL(clientsub.U_DCD,0) as int)
                                    )
                                ),
                                dbo.computeInteluckPenaltyCalc(
                                    dbo.computePODStatusPayment(
                                        dbo.computeOverdueDays(
                                            podsub.U_ActualHCRecDate,
                                            dbo.computePODSubmitDeadline(
                                                podsub.U_DeliveryDateDTR,
                                                ISNULL(clientsub.U_CDC,0)
                                            ),
                                            ISNULL(podsub.U_HolidayOrWeekend, 0)
                                        )
                                    ),
                                    dbo.computeOverdueDays(
                                        podsub.U_ActualHCRecDate,
                                        dbo.computePODSubmitDeadline(
                                            podsub.U_DeliveryDateDTR,
                                            ISNULL(clientsub.U_CDC,0)
                                        ),
                                        ISNULL(podsub.U_HolidayOrWeekend, 0)
                                    )
                                ),
                                dbo.computeLostPenaltyCalc(
                                    dbo.computePODStatusPayment(
                                        dbo.computeOverdueDays(
                                            podsub.U_ActualHCRecDate,
                                            dbo.computePODSubmitDeadline(
                                                podsub.U_DeliveryDateDTR,
                                                ISNULL(clientsub.U_CDC,0)
                                            ),
                                            ISNULL(podsub.U_HolidayOrWeekend, 0)
                                        )
                                    ),
                                    podsub.U_InitialHCRecDate,
                                    podsub.U_DeliveryDateDTR,
                                    pricingsub.U_TotalInitialTruckers
                                ),
                                ISNULL(podsub.U_PenaltiesManual,0)
                            )) -

                            dbo.computeTotalPenaltyWaived(
                                dbo.computeTotalSubPenalties(
                                    dbo.computeClientPenaltyCalc(
                                        dbo.computeClientSubOverdue(
                                            podsub.U_DeliveryDateDTR,
                                            podsub.U_ClientReceivedDate,
                                            ISNULL(podsub.U_WaivedDays, 0),
                                            CAST(ISNULL(clientsub.U_DCD,0) as int)
                                        )
                                    ),
                                    dbo.computeInteluckPenaltyCalc(
                                        dbo.computePODStatusPayment(
                                            dbo.computeOverdueDays(
                                                podsub.U_ActualHCRecDate,
                                                dbo.computePODSubmitDeadline(
                                                    podsub.U_DeliveryDateDTR,
                                                    ISNULL(clientsub.U_CDC,0)
                                                ),
                                                ISNULL(podsub.U_HolidayOrWeekend, 0)
                                            )
                                        ),
                                        dbo.computeOverdueDays(
                                            podsub.U_ActualHCRecDate,
                                            dbo.computePODSubmitDeadline(
                                                podsub.U_DeliveryDateDTR,
                                                ISNULL(clientsub.U_CDC,0)
                                            ),
                                            ISNULL(podsub.U_HolidayOrWeekend, 0)
                                        )
                                    ),
                                    dbo.computeLostPenaltyCalc(
                                        dbo.computePODStatusPayment(
                                            dbo.computeOverdueDays(
                                                podsub.U_ActualHCRecDate,
                                                dbo.computePODSubmitDeadline(
                                                    podsub.U_DeliveryDateDTR,
                                                    ISNULL(clientsub.U_CDC,0)
                                                ),
                                                ISNULL(podsub.U_HolidayOrWeekend, 0)
                                            )
                                        ),
                                        podsub.U_InitialHCRecDate,
                                        podsub.U_DeliveryDateDTR,
                                        pricingsub.U_TotalInitialTruckers
                                    ),
                                    ISNULL(podsub.U_PenaltiesManual,0)
                                ),
                                ISNULL(podsub.U_PercPenaltyCharge,0)))



                            AS TotalAmount




        FROM [@PCTP_TP] tpsub
            INNER JOIN [@PCTP_POD] podsub ON tpsub.U_BookingId = podsub.U_BookingNumber
            INNER JOIN OCRD truckersub ON podsub.U_SAPTrucker = truckersub.CardCode
            INNER JOIN OCRD clientsub ON U_SAPClient = clientsub.CardCode
            INNER JOIN [dbo].[@PCTP_PRICING] pricingsub ON tpsub.U_BookingId = pricingsub.U_BookingId
            LEFT JOIN [@FirstratesTP] ratessub ON ratessub.U_BN = tpsub.U_BookingId AND ratessub.U_PVNo = SUBSTRING(tpsub.U_PVNo, 1, 9)


        WHERE tpsub.U_BookingId = T0.U_BookingId

                        )

                        ,0)    
                    --TOTAL AP 1 UNPAID 1 PAID  ------------
                    WHEN CAST((
                        SELECT DISTINCT
                SUBSTRING(
                            (
                                SELECT CONCAT(', ', header.DocNum)  AS [text()]
                FROM PCH1 line
                    LEFT JOIN OPCH header ON header.DocEntry = line.DocEntry
                WHERE header.CANCELED = 'N' AND header.PaidSum = 0 AND (line.ItemCode = T0.U_BookingId
                    or REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%')
                FOR XML PATH (''), TYPE
                            ).value('text()[1]','nvarchar(max)'), 2, 1000) DocEntry
            FROM OPCH header
                LEFT JOIN PCH1 line ON line.DocEntry = header.DocEntry
            WHERE header.CANCELED = 'N' AND (line.ItemCode = T0.U_BookingId
                or REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%')) as nvarchar(max)
                    ) IS NOT NULL AND
            CAST((
                        SELECT DISTINCT
                SUBSTRING(
                            (
                                SELECT CONCAT(', ', header.DocNum)  AS [text()]
                FROM PCH1 line
                    LEFT JOIN OPCH header ON header.DocEntry = line.DocEntry
                WHERE header.CANCELED = 'N' AND header.PaidSum > 0 AND (line.ItemCode = T0.U_BookingId
                    or REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%')
                FOR XML PATH (''), TYPE
                            ).value('text()[1]','nvarchar(max)'), 2, 1000) DocEntry
            FROM OPCH header
                LEFT JOIN PCH1 line ON line.DocEntry = header.DocEntry
            WHERE header.CANCELED = 'N' AND (line.ItemCode = T0.U_BookingId
                or REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%')) as nvarchar(max)
                    ) IS NOT NULL
                    THEN 

                ISNULL((
        SELECT DISTINCT

            (
        CASE WHEN T5.U_Rates LIKE '%U_GrossTruckerRates%' THEN 
                CASE
                    WHEN ISNULL( truckersub.VatStatus,'Y') = 'Y' THEN pricingsub.U_GrossTruckerRates
                    WHEN ISNULL(truckersub.VatStatus,'Y') = 'N' THEN (pricingsub.U_GrossTruckerRates / 1.12)
                END 
            ELSE 0.00 
            END
            +
            CASE WHEN T5.U_Rates LIKE '%U_ActualRates%' THEN 
                ISNULL(NULLIF(CAST(tpsub.U_ActualRates AS FLOAT),''),0)
            ELSE 0.00
            END 
            +
            CASE WHEN T5.U_Rates LIKE '%U_RateAdjustments%' THEN 
                ISNULL(NULLIF(CAST(tpsub.U_RateAdjustments AS FLOAT),''),0)
            ELSE 0.00
            END 
            +
            CASE WHEN T5.U_Rates LIKE '%U_DemurrageN%' THEN 
                CASE
                    WHEN ISNULL(truckersub.VatStatus,'Y') = 'Y' THEN pricingsub.U_Demurrage2
                    WHEN ISNULL(truckersub.VatStatus,'Y') = 'N' THEN (pricingsub.U_Demurrage2 / 1.12) 
                END
            ELSE 0.00
            END 
            +  
            CASE WHEN T5.U_Rates LIKE '%U_totalAddtlCharges2%' THEN 
                ISNULL(NULLIF(CAST(tpsub.U_ActualCharges AS FLOAT),''),0)
            ELSE 0.00
            END 
            +  
            CASE WHEN T5.U_Rates LIKE '%U_ActualDemurrage%' THEN 
                ISNULL(NULLIF(CAST(tpsub.U_ActualDemurrage AS FLOAT),''),0)
            ELSE 0.00
            END 
            +  
            CASE WHEN T5.U_Rates LIKE '%U_ActualCharges%' THEN 
                ISNULL(NULLIF(CAST(tpsub.U_ActualCharges AS FLOAT),''),0)

            ELSE 0.00
            END 
            +  
            CASE WHEN T5.U_Rates LIKE '%U_BoomTruck2%' THEN 
                ISNULL(NULLIF(CAST(tpsub.U_BoomTruck2 AS FLOAT),''),0)
            ELSE 0.00
            END 
            +  
            CASE WHEN T5.U_Rates LIKE '%U_OtherCharges%' THEN 
                ISNULL(NULLIF(CAST(tpsub.U_OtherCharges AS FLOAT),''),0)
            ELSE 0.00
            END 

        )
        -
        ISNULL(tpsub.U_OtherDeductions,0) 

        +

            abs(dbo.computeTotalPenaltyWaived(
                dbo.computeTotalSubPenalties(
                    dbo.computeClientPenaltyCalc(
                        dbo.computeClientSubOverdue(
                            podsub.U_DeliveryDateDTR,
                            podsub.U_ClientReceivedDate,
                            ISNULL(podsub.U_WaivedDays, 0),
                            CAST(ISNULL(clientsub.U_DCD,0) as int)
                        )
                    ),
                    dbo.computeInteluckPenaltyCalc(
                        dbo.computePODStatusPayment(
                            dbo.computeOverdueDays(
                                podsub.U_ActualHCRecDate,
                                dbo.computePODSubmitDeadline(
                                    podsub.U_DeliveryDateDTR,
                                    ISNULL(clientsub.U_CDC,0)
                                ),
                                ISNULL(podsub.U_HolidayOrWeekend, 0)
                            )
                        ),
                        dbo.computeOverdueDays(
                            podsub.U_ActualHCRecDate,
                            dbo.computePODSubmitDeadline(
                                podsub.U_DeliveryDateDTR,
                                ISNULL(clientsub.U_CDC,0)
                            ),
                            ISNULL(podsub.U_HolidayOrWeekend, 0)
                        )
                    ),
                    dbo.computeLostPenaltyCalc(
                        dbo.computePODStatusPayment(
                            dbo.computeOverdueDays(
                                podsub.U_ActualHCRecDate,
                                dbo.computePODSubmitDeadline(
                                    podsub.U_DeliveryDateDTR,
                                    ISNULL(clientsub.U_CDC,0)
                                ),
                                ISNULL(podsub.U_HolidayOrWeekend, 0)
                            )
                        ),
                        podsub.U_InitialHCRecDate,
                        podsub.U_DeliveryDateDTR,
                        pricingsub.U_TotalInitialTruckers
                    ),
                    ISNULL(podsub.U_PenaltiesManual,0)
                ),
                ISNULL(podsub.U_PercPenaltyCharge,0))
            ) AS TotalAmount




        FROM [@PCTP_TP] tpsub
            INNER JOIN [@PCTP_POD] podsub ON tpsub.U_BookingId = podsub.U_BookingNumber
            INNER JOIN OCRD truckersub ON podsub.U_SAPTrucker = truckersub.CardCode
            INNER JOIN OCRD clientsub ON U_SAPClient = clientsub.CardCode
            INNER JOIN [dbo].[@PCTP_PRICING] pricingsub ON tpsub.U_BookingId = pricingsub.U_BookingId
            --INNER JOIN [@RATESPERPV] ratessub ON ratessub.Code = tpsub.U_PVNo
            INNER JOIN [@RATESPERPV] T5 ON T5.Code = SUBSTRING(tpsub.U_PVNo, 11, 19)
        WHERE tpsub.U_BookingId =  T0.U_BookingId


        ),0)+ ISNULL((

        SELECT DISTINCT

            (

            ISNULL(TRY_PARSE(ratessub.U_Amount AS FLOAT),0)+
        --ISNULL(tpsub.U_ActualRates,0) +

        ISNULL(tpsub.U_RateAdjustments,0) +



            ISNULL(TRY_PARSE(ratessub.U_AddlAmount AS FLOAT),0)  
        --+

        --ISNULL(tpsub.U_ActualDemurrage,0) +
        --ISNULL(tpsub.U_ActualCharges,0)+
        --ISNULL(NULLIF(tpsub.U_BoomTruck2,''),0) +
        --ISNULL(tpsub.U_OtherCharges,0) 

        )

        -

        (ABS(dbo.computeTotalSubPenalties(
                dbo.computeClientPenaltyCalc(
                    dbo.computeClientSubOverdue(
                        podsub.U_DeliveryDateDTR,
                        podsub.U_ClientReceivedDate,
                        ISNULL(podsub.U_WaivedDays, 0),
                        CAST(ISNULL(clientsub.U_DCD,0) as int)
                    )
                ),
                dbo.computeInteluckPenaltyCalc(
                    dbo.computePODStatusPayment(
                        dbo.computeOverdueDays(
                            podsub.U_ActualHCRecDate,
                            dbo.computePODSubmitDeadline(
                                podsub.U_DeliveryDateDTR,
                                ISNULL(clientsub.U_CDC,0)
                            ),
                            ISNULL(podsub.U_HolidayOrWeekend, 0)
                        )
                    ),
                    dbo.computeOverdueDays(
                        podsub.U_ActualHCRecDate,
                        dbo.computePODSubmitDeadline(
                            podsub.U_DeliveryDateDTR,
                            ISNULL(clientsub.U_CDC,0)
                        ),
                        ISNULL(podsub.U_HolidayOrWeekend, 0)
                    )
                ),
                dbo.computeLostPenaltyCalc(
                    dbo.computePODStatusPayment(
                        dbo.computeOverdueDays(
                            podsub.U_ActualHCRecDate,
                            dbo.computePODSubmitDeadline(
                                podsub.U_DeliveryDateDTR,
                                ISNULL(clientsub.U_CDC,0)
                            ),
                            ISNULL(podsub.U_HolidayOrWeekend, 0)
                        )
                    ),
                    podsub.U_InitialHCRecDate,
                    podsub.U_DeliveryDateDTR,
                    pricingsub.U_TotalInitialTruckers
                ),
                ISNULL(podsub.U_PenaltiesManual,0)
            )) -

            dbo.computeTotalPenaltyWaived(
                dbo.computeTotalSubPenalties(
                    dbo.computeClientPenaltyCalc(
                        dbo.computeClientSubOverdue(
                            podsub.U_DeliveryDateDTR,
                            podsub.U_ClientReceivedDate,
                            ISNULL(podsub.U_WaivedDays, 0),
                            CAST(ISNULL(clientsub.U_DCD,0) as int)
                        )
                    ),
                    dbo.computeInteluckPenaltyCalc(
                        dbo.computePODStatusPayment(
                            dbo.computeOverdueDays(
                                podsub.U_ActualHCRecDate,
                                dbo.computePODSubmitDeadline(
                                    podsub.U_DeliveryDateDTR,
                                    ISNULL(clientsub.U_CDC,0)
                                ),
                                ISNULL(podsub.U_HolidayOrWeekend, 0)
                            )
                        ),
                        dbo.computeOverdueDays(
                            podsub.U_ActualHCRecDate,
                            dbo.computePODSubmitDeadline(
                                podsub.U_DeliveryDateDTR,
                                ISNULL(clientsub.U_CDC,0)
                            ),
                            ISNULL(podsub.U_HolidayOrWeekend, 0)
                        )
                    ),
                    dbo.computeLostPenaltyCalc(
                        dbo.computePODStatusPayment(
                            dbo.computeOverdueDays(
                                podsub.U_ActualHCRecDate,
                                dbo.computePODSubmitDeadline(
                                    podsub.U_DeliveryDateDTR,
                                    ISNULL(clientsub.U_CDC,0)
                                ),
                                ISNULL(podsub.U_HolidayOrWeekend, 0)
                            )
                        ),
                        podsub.U_InitialHCRecDate,
                        podsub.U_DeliveryDateDTR,
                        pricingsub.U_TotalInitialTruckers
                    ),
                    ISNULL(podsub.U_PenaltiesManual,0)
                ),
                ISNULL(podsub.U_PercPenaltyCharge,0)))



            AS TotalAmount




        FROM [@PCTP_TP] tpsub
            INNER JOIN [@PCTP_POD] podsub ON tpsub.U_BookingId = podsub.U_BookingNumber
            INNER JOIN OCRD truckersub ON podsub.U_SAPTrucker = truckersub.CardCode
            INNER JOIN OCRD clientsub ON U_SAPClient = clientsub.CardCode
            INNER JOIN [dbo].[@PCTP_PRICING] pricingsub ON tpsub.U_BookingId = pricingsub.U_BookingId
            LEFT JOIN [@FirstratesTP] ratessub ON ratessub.U_BN = tpsub.U_BookingId AND ratessub.U_PVNo = SUBSTRING(tpsub.U_PVNo, 1, 9)


        WHERE tpsub.U_BookingId = T0.U_BookingId

        )

        ,0)


                    --TOTAL AP 2 UNPAID  ------------
                    WHEN CHARINDEX(',', CAST((
                        SELECT DISTINCT
                SUBSTRING(
                                (
                                    SELECT CONCAT(', ', header.DocNum)  AS [text()]
                FROM PCH1 line
                    LEFT JOIN OPCH header ON header.DocEntry = line.DocEntry
                WHERE header.CANCELED = 'N' AND header.PaidSum = 0 AND (line.ItemCode = T0.U_BookingId
                    or REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%')
                FOR XML PATH (''), TYPE
                                ).value('text()[1]','nvarchar(max)'), 2, 1000) DocEntry
            FROM OPCH header
                LEFT JOIN PCH1 line ON line.DocEntry = header.DocEntry
            WHERE header.CANCELED = 'N' AND (line.ItemCode = T0.U_BookingId
                or REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%')) as nvarchar(max)
                        )) >  0 AND
            CAST((
                        SELECT DISTINCT
                SUBSTRING(
                            (
                                SELECT CONCAT(', ', header.DocNum)  AS [text()]
                FROM PCH1 line
                    LEFT JOIN OPCH header ON header.DocEntry = line.DocEntry
                WHERE header.CANCELED = 'N' AND header.PaidSum > 0 AND (line.ItemCode = T0.U_BookingId
                    or REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%')
                FOR XML PATH (''), TYPE
                            ).value('text()[1]','nvarchar(max)'), 2, 1000) DocEntry
            FROM OPCH header
                LEFT JOIN PCH1 line ON line.DocEntry = header.DocEntry
            WHERE header.CANCELED = 'N' AND (line.ItemCode = T0.U_BookingId
                or REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%')) as nvarchar(max)
                    ) IS NULL
                    THEN 
                    ISNULL((
                        SELECT DISTINCT

            (
                            CASE WHEN T5.U_Rates LIKE '%U_GrossTruckerRates%' THEN 
                                CASE
                                    WHEN ISNULL( truckersub.VatStatus,'Y') = 'Y' THEN pricingsub.U_GrossTruckerRates
                                    WHEN ISNULL(truckersub.VatStatus,'Y') = 'N' THEN (pricingsub.U_GrossTruckerRates / 1.12)
                                END 
                            ELSE 0.00 
                            END
                            +
                            CASE WHEN T5.U_Rates LIKE '%U_ActualRates%' THEN 
                                ISNULL(NULLIF(CAST(tpsub.U_ActualRates AS FLOAT),''),0)
                            ELSE 0.00
                            END 
                            +
                            CASE WHEN T5.U_Rates LIKE '%U_RateAdjustments%' THEN 
                                ISNULL(NULLIF(CAST(tpsub.U_RateAdjustments AS FLOAT),''),0)
                            ELSE 0.00
                            END 
                            +
                            CASE WHEN T5.U_Rates LIKE '%U_DemurrageN%' THEN 
                                CASE
                                    WHEN ISNULL(truckersub.VatStatus,'Y') = 'Y' THEN pricingsub.U_Demurrage2
                                    WHEN ISNULL(truckersub.VatStatus,'Y') = 'N' THEN (pricingsub.U_Demurrage2 / 1.12) 
                                END
                            ELSE 0.00
                            END 
                            +  
                            CASE WHEN T5.U_Rates LIKE '%U_totalAddtlCharges2%' THEN 
                                ISNULL(NULLIF(CAST(tpsub.U_ActualCharges AS FLOAT),''),0)
                            ELSE 0.00
                            END 
                            +  
                            CASE WHEN T5.U_Rates LIKE '%U_ActualDemurrage%' THEN 
                                ISNULL(NULLIF(CAST(tpsub.U_ActualDemurrage AS FLOAT),''),0)
                            ELSE 0.00
                            END 
                            +  
                            CASE WHEN T5.U_Rates LIKE '%U_ActualCharges%' THEN 
                                ISNULL(NULLIF(CAST(tpsub.U_ActualCharges AS FLOAT),''),0)

                            ELSE 0.00
                            END 
                            +  
                            CASE WHEN T5.U_Rates LIKE '%U_BoomTruck2%' THEN 
                                ISNULL(NULLIF(CAST(tpsub.U_BoomTruck2 AS FLOAT),''),0)
                            ELSE 0.00
                            END 
                            +  
                            CASE WHEN T5.U_Rates LIKE '%U_OtherCharges%' THEN 
                                ISNULL(NULLIF(CAST(tpsub.U_OtherCharges AS FLOAT),''),0)
                            ELSE 0.00
                            END 

                        )
                        -
                        ISNULL(tpsub.U_OtherDeductions,0) 

                        +

                            abs(dbo.computeTotalPenaltyWaived(
                                dbo.computeTotalSubPenalties(
                                    dbo.computeClientPenaltyCalc(
                                        dbo.computeClientSubOverdue(
                                            podsub.U_DeliveryDateDTR,
                                            podsub.U_ClientReceivedDate,
                                            ISNULL(podsub.U_WaivedDays, 0),
                                            CAST(ISNULL(clientsub.U_DCD,0) as int)
                                        )
                                    ),
                                    dbo.computeInteluckPenaltyCalc(
                                        dbo.computePODStatusPayment(
                                            dbo.computeOverdueDays(
                                                podsub.U_ActualHCRecDate,
                                                dbo.computePODSubmitDeadline(
                                                    podsub.U_DeliveryDateDTR,
                                                    ISNULL(clientsub.U_CDC,0)
                                                ),
                                                ISNULL(podsub.U_HolidayOrWeekend, 0)
                                            )
                                        ),
                                        dbo.computeOverdueDays(
                                            podsub.U_ActualHCRecDate,
                                            dbo.computePODSubmitDeadline(
                                                podsub.U_DeliveryDateDTR,
                                                ISNULL(clientsub.U_CDC,0)
                                            ),
                                            ISNULL(podsub.U_HolidayOrWeekend, 0)
                                        )
                                    ),
                                    dbo.computeLostPenaltyCalc(
                                        dbo.computePODStatusPayment(
                                            dbo.computeOverdueDays(
                                                podsub.U_ActualHCRecDate,
                                                dbo.computePODSubmitDeadline(
                                                    podsub.U_DeliveryDateDTR,
                                                    ISNULL(clientsub.U_CDC,0)
                                                ),
                                                ISNULL(podsub.U_HolidayOrWeekend, 0)
                                            )
                                        ),
                                        podsub.U_InitialHCRecDate,
                                        podsub.U_DeliveryDateDTR,
                                        pricingsub.U_TotalInitialTruckers
                                    ),
                                    ISNULL(podsub.U_PenaltiesManual,0)
                                ),
                                ISNULL(podsub.U_PercPenaltyCharge,0))
                            ) AS TotalAmount




        FROM [@PCTP_TP] tpsub
            INNER JOIN [@PCTP_POD] podsub ON tpsub.U_BookingId = podsub.U_BookingNumber
            INNER JOIN OCRD truckersub ON podsub.U_SAPTrucker = truckersub.CardCode
            INNER JOIN OCRD clientsub ON U_SAPClient = clientsub.CardCode
            INNER JOIN [dbo].[@PCTP_PRICING] pricingsub ON tpsub.U_BookingId = pricingsub.U_BookingId
            --INNER JOIN [@RATESPERPV] ratessub ON ratessub.Code = tpsub.U_PVNo
            INNER JOIN [@RATESPERPV] T5 ON T5.Code = SUBSTRING(tpsub.U_PVNo, 11, 19)
        WHERE tpsub.U_BookingId =  T0.U_BookingId


                        ),0)+ ISNULL((

                        SELECT DISTINCT

            (

                            ISNULL(TRY_PARSE(ratessub.U_Amount AS FLOAT),0)+
                        --ISNULL(tpsub.U_ActualRates,0) +

                            ISNULL(tpsub.U_RateAdjustments,0) +



                            ISNULL(TRY_PARSE(ratessub.U_AddlAmount AS FLOAT),0)  
                        --+

                        --ISNULL(tpsub.U_ActualDemurrage,0) +
                        --ISNULL(tpsub.U_ActualCharges,0)+
                        --ISNULL(NULLIF(tpsub.U_BoomTruck2,''),0) +
                        --ISNULL(tpsub.U_OtherCharges,0) 

                        )

                        -

                        (ABS(dbo.computeTotalSubPenalties(
                                dbo.computeClientPenaltyCalc(
                                    dbo.computeClientSubOverdue(
                                        podsub.U_DeliveryDateDTR,
                                        podsub.U_ClientReceivedDate,
                                        ISNULL(podsub.U_WaivedDays, 0),
                                        CAST(ISNULL(clientsub.U_DCD,0) as int)
                                    )
                                ),
                                dbo.computeInteluckPenaltyCalc(
                                    dbo.computePODStatusPayment(
                                        dbo.computeOverdueDays(
                                            podsub.U_ActualHCRecDate,
                                            dbo.computePODSubmitDeadline(
                                                podsub.U_DeliveryDateDTR,
                                                ISNULL(clientsub.U_CDC,0)
                                            ),
                                            ISNULL(podsub.U_HolidayOrWeekend, 0)
                                        )
                                    ),
                                    dbo.computeOverdueDays(
                                        podsub.U_ActualHCRecDate,
                                        dbo.computePODSubmitDeadline(
                                            podsub.U_DeliveryDateDTR,
                                            ISNULL(clientsub.U_CDC,0)
                                        ),
                                        ISNULL(podsub.U_HolidayOrWeekend, 0)
                                    )
                                ),
                                dbo.computeLostPenaltyCalc(
                                    dbo.computePODStatusPayment(
                                        dbo.computeOverdueDays(
                                            podsub.U_ActualHCRecDate,
                                            dbo.computePODSubmitDeadline(
                                                podsub.U_DeliveryDateDTR,
                                                ISNULL(clientsub.U_CDC,0)
                                            ),
                                            ISNULL(podsub.U_HolidayOrWeekend, 0)
                                        )
                                    ),
                                    podsub.U_InitialHCRecDate,
                                    podsub.U_DeliveryDateDTR,
                                    pricingsub.U_TotalInitialTruckers
                                ),
                                ISNULL(podsub.U_PenaltiesManual,0)
                            )) -

                            dbo.computeTotalPenaltyWaived(
                                dbo.computeTotalSubPenalties(
                                    dbo.computeClientPenaltyCalc(
                                        dbo.computeClientSubOverdue(
                                            podsub.U_DeliveryDateDTR,
                                            podsub.U_ClientReceivedDate,
                                            ISNULL(podsub.U_WaivedDays, 0),
                                            CAST(ISNULL(clientsub.U_DCD,0) as int)
                                        )
                                    ),
                                    dbo.computeInteluckPenaltyCalc(
                                        dbo.computePODStatusPayment(
                                            dbo.computeOverdueDays(
                                                podsub.U_ActualHCRecDate,
                                                dbo.computePODSubmitDeadline(
                                                    podsub.U_DeliveryDateDTR,
                                                    ISNULL(clientsub.U_CDC,0)
                                                ),
                                                ISNULL(podsub.U_HolidayOrWeekend, 0)
                                            )
                                        ),
                                        dbo.computeOverdueDays(
                                            podsub.U_ActualHCRecDate,
                                            dbo.computePODSubmitDeadline(
                                                podsub.U_DeliveryDateDTR,
                                                ISNULL(clientsub.U_CDC,0)
                                            ),
                                            ISNULL(podsub.U_HolidayOrWeekend, 0)
                                        )
                                    ),
                                    dbo.computeLostPenaltyCalc(
                                        dbo.computePODStatusPayment(
                                            dbo.computeOverdueDays(
                                                podsub.U_ActualHCRecDate,
                                                dbo.computePODSubmitDeadline(
                                                    podsub.U_DeliveryDateDTR,
                                                    ISNULL(clientsub.U_CDC,0)
                                                ),
                                                ISNULL(podsub.U_HolidayOrWeekend, 0)
                                            )
                                        ),
                                        podsub.U_InitialHCRecDate,
                                        podsub.U_DeliveryDateDTR,
                                        pricingsub.U_TotalInitialTruckers
                                    ),
                                    ISNULL(podsub.U_PenaltiesManual,0)
                                ),
                                ISNULL(podsub.U_PercPenaltyCharge,0)))



                            AS TotalAmount




        FROM [@PCTP_TP] tpsub
            INNER JOIN [@PCTP_POD] podsub ON tpsub.U_BookingId = podsub.U_BookingNumber
            INNER JOIN OCRD truckersub ON podsub.U_SAPTrucker = truckersub.CardCode
            INNER JOIN OCRD clientsub ON U_SAPClient = clientsub.CardCode
            INNER JOIN [dbo].[@PCTP_PRICING] pricingsub ON tpsub.U_BookingId = pricingsub.U_BookingId
            LEFT JOIN [@FirstratesTP] ratessub ON ratessub.U_BN = tpsub.U_BookingId AND ratessub.U_PVNo = SUBSTRING(tpsub.U_PVNo, 1, 9)


        WHERE tpsub.U_BookingId = T0.U_BookingId

                        )

                        ,0)


                    --TOTAL AP 1 PAID  NO UNPAID------------
                    WHEN CAST((
                        SELECT DISTINCT
                SUBSTRING(
                                (
                                    SELECT CONCAT(', ', header.DocNum)  AS [text()]
                FROM PCH1 line
                    LEFT JOIN OPCH header ON header.DocEntry = line.DocEntry
                WHERE header.CANCELED = 'N' AND header.PaidSum = 0 AND (line.ItemCode = T0.U_BookingId
                    or REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%')
                FOR XML PATH (''), TYPE
                                ).value('text()[1]','nvarchar(max)'), 2, 1000) DocEntry
            FROM OPCH header
                LEFT JOIN PCH1 line ON line.DocEntry = header.DocEntry
            WHERE header.CANCELED = 'N' AND (line.ItemCode = T0.U_BookingId
                or REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%')) as nvarchar(max)
                        ) IS NULL AND
            CAST((
                        SELECT DISTINCT
                SUBSTRING(
                            (
                                SELECT CONCAT(', ', header.DocNum)  AS [text()]
                FROM PCH1 line
                    LEFT JOIN OPCH header ON header.DocEntry = line.DocEntry
                WHERE header.CANCELED = 'N' AND header.PaidSum > 0 AND (line.ItemCode = T0.U_BookingId
                    or REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%')
                FOR XML PATH (''), TYPE
                            ).value('text()[1]','nvarchar(max)'), 2, 1000) DocEntry
            FROM OPCH header
                LEFT JOIN PCH1 line ON line.DocEntry = header.DocEntry
            WHERE header.CANCELED = 'N' AND (line.ItemCode = T0.U_BookingId
                or REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%')) as nvarchar(max)
                    ) IS NOT NULL
                    THEN 
                    ISNULL((

                        SELECT DISTINCT

            (

                            ISNULL(TRY_PARSE(ratessub.U_Amount AS FLOAT),0)+
                        --ISNULL(tpsub.U_ActualRates,0) +

                            ISNULL(tpsub.U_RateAdjustments,0) +



                            ISNULL(TRY_PARSE(ratessub.U_AddlAmount AS FLOAT),0)  
                        --+

                        --ISNULL(tpsub.U_ActualDemurrage,0) +
                        --ISNULL(tpsub.U_ActualCharges,0)+
                        --ISNULL(NULLIF(tpsub.U_BoomTruck2,''),0) +
                        --ISNULL(tpsub.U_OtherCharges,0) 

                        )

                        -

                        (ABS(dbo.computeTotalSubPenalties(
                                dbo.computeClientPenaltyCalc(
                                    dbo.computeClientSubOverdue(
                                        podsub.U_DeliveryDateDTR,
                                        podsub.U_ClientReceivedDate,
                                        ISNULL(podsub.U_WaivedDays, 0),
                                        CAST(ISNULL(clientsub.U_DCD,0) as int)
                                    )
                                ),
                                dbo.computeInteluckPenaltyCalc(
                                    dbo.computePODStatusPayment(
                                        dbo.computeOverdueDays(
                                            podsub.U_ActualHCRecDate,
                                            dbo.computePODSubmitDeadline(
                                                podsub.U_DeliveryDateDTR,
                                                ISNULL(clientsub.U_CDC,0)
                                            ),
                                            ISNULL(podsub.U_HolidayOrWeekend, 0)
                                        )
                                    ),
                                    dbo.computeOverdueDays(
                                        podsub.U_ActualHCRecDate,
                                        dbo.computePODSubmitDeadline(
                                            podsub.U_DeliveryDateDTR,
                                            ISNULL(clientsub.U_CDC,0)
                                        ),
                                        ISNULL(podsub.U_HolidayOrWeekend, 0)
                                    )
                                ),
                                dbo.computeLostPenaltyCalc(
                                    dbo.computePODStatusPayment(
                                        dbo.computeOverdueDays(
                                            podsub.U_ActualHCRecDate,
                                            dbo.computePODSubmitDeadline(
                                                podsub.U_DeliveryDateDTR,
                                                ISNULL(clientsub.U_CDC,0)
                                            ),
                                            ISNULL(podsub.U_HolidayOrWeekend, 0)
                                        )
                                    ),
                                    podsub.U_InitialHCRecDate,
                                    podsub.U_DeliveryDateDTR,
                                    pricingsub.U_TotalInitialTruckers
                                ),
                                ISNULL(podsub.U_PenaltiesManual,0)
                            )) -

                            dbo.computeTotalPenaltyWaived(
                                dbo.computeTotalSubPenalties(
                                    dbo.computeClientPenaltyCalc(
                                        dbo.computeClientSubOverdue(
                                            podsub.U_DeliveryDateDTR,
                                            podsub.U_ClientReceivedDate,
                                            ISNULL(podsub.U_WaivedDays, 0),
                                            CAST(ISNULL(clientsub.U_DCD,0) as int)
                                        )
                                    ),
                                    dbo.computeInteluckPenaltyCalc(
                                        dbo.computePODStatusPayment(
                                            dbo.computeOverdueDays(
                                                podsub.U_ActualHCRecDate,
                                                dbo.computePODSubmitDeadline(
                                                    podsub.U_DeliveryDateDTR,
                                                    ISNULL(clientsub.U_CDC,0)
                                                ),
                                                ISNULL(podsub.U_HolidayOrWeekend, 0)
                                            )
                                        ),
                                        dbo.computeOverdueDays(
                                            podsub.U_ActualHCRecDate,
                                            dbo.computePODSubmitDeadline(
                                                podsub.U_DeliveryDateDTR,
                                                ISNULL(clientsub.U_CDC,0)
                                            ),
                                            ISNULL(podsub.U_HolidayOrWeekend, 0)
                                        )
                                    ),
                                    dbo.computeLostPenaltyCalc(
                                        dbo.computePODStatusPayment(
                                            dbo.computeOverdueDays(
                                                podsub.U_ActualHCRecDate,
                                                dbo.computePODSubmitDeadline(
                                                    podsub.U_DeliveryDateDTR,
                                                    ISNULL(clientsub.U_CDC,0)
                                                ),
                                                ISNULL(podsub.U_HolidayOrWeekend, 0)
                                            )
                                        ),
                                        podsub.U_InitialHCRecDate,
                                        podsub.U_DeliveryDateDTR,
                                        pricingsub.U_TotalInitialTruckers
                                    ),
                                    ISNULL(podsub.U_PenaltiesManual,0)
                                ),
                                ISNULL(podsub.U_PercPenaltyCharge,0)))



                            AS TotalAmount




        FROM [@PCTP_TP] tpsub
            INNER JOIN [@PCTP_POD] podsub ON tpsub.U_BookingId = podsub.U_BookingNumber
            INNER JOIN OCRD truckersub ON podsub.U_SAPTrucker = truckersub.CardCode
            INNER JOIN OCRD clientsub ON U_SAPClient = clientsub.CardCode
            INNER JOIN [dbo].[@PCTP_PRICING] pricingsub ON tpsub.U_BookingId = pricingsub.U_BookingId
            LEFT JOIN [@FirstratesTP] ratessub ON ratessub.U_BN = tpsub.U_BookingId AND ratessub.U_PVNo = SUBSTRING(tpsub.U_PVNo, 1, 9)


        WHERE tpsub.U_BookingId = T0.U_BookingId

                        )

                        ,0)

                    --TOTAL AP 1 UNPAID  ------------
                    WHEN CAST((
                        SELECT DISTINCT
                SUBSTRING(
                                (
                                    SELECT CONCAT(', ', header.DocNum)  AS [text()]
                FROM PCH1 line
                    LEFT JOIN OPCH header ON header.DocEntry = line.DocEntry
                WHERE header.CANCELED = 'N' AND header.PaidSum = 0 AND (line.ItemCode = T0.U_BookingId
                    or REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%')
                FOR XML PATH (''), TYPE
                                ).value('text()[1]','nvarchar(max)'), 2, 1000) DocEntry
            FROM OPCH header
                LEFT JOIN PCH1 line ON line.DocEntry = header.DocEntry
            WHERE header.CANCELED = 'N' AND (line.ItemCode = T0.U_BookingId
                or REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%')) as nvarchar(max)
                        ) IS NOT NULL AND
            CAST((
                        SELECT DISTINCT
                SUBSTRING(
                            (
                                SELECT CONCAT(', ', header.DocNum)  AS [text()]
                FROM PCH1 line
                    LEFT JOIN OPCH header ON header.DocEntry = line.DocEntry
                WHERE header.CANCELED = 'N' AND header.PaidSum > 0 AND (line.ItemCode = T0.U_BookingId
                    or REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%')
                FOR XML PATH (''), TYPE
                            ).value('text()[1]','nvarchar(max)'), 2, 1000) DocEntry
            FROM OPCH header
                LEFT JOIN PCH1 line ON line.DocEntry = header.DocEntry
            WHERE header.CANCELED = 'N' AND (line.ItemCode = T0.U_BookingId
                or REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%')) as nvarchar(max)
                    ) IS NULL
                    THEN ISNULL((

                        SELECT DISTINCT

            (

                            ISNULL(TRY_PARSE(ratessub.U_Amount AS FLOAT),0)+
                        --ISNULL(tpsub.U_ActualRates,0) +

                            ISNULL(tpsub.U_RateAdjustments,0) +



                            ISNULL(TRY_PARSE(ratessub.U_AddlAmount AS FLOAT),0)  
                        --+

                        --ISNULL(tpsub.U_ActualDemurrage,0) +
                        --ISNULL(tpsub.U_ActualCharges,0)+
                        --ISNULL(NULLIF(tpsub.U_BoomTruck2,''),0) +
                        --ISNULL(tpsub.U_OtherCharges,0) 

                        )

                        -

                        (ABS(dbo.computeTotalSubPenalties(
                                dbo.computeClientPenaltyCalc(
                                    dbo.computeClientSubOverdue(
                                        podsub.U_DeliveryDateDTR,
                                        podsub.U_ClientReceivedDate,
                                        ISNULL(podsub.U_WaivedDays, 0),
                                        CAST(ISNULL(clientsub.U_DCD,0) as int)
                                    )
                                ),
                                dbo.computeInteluckPenaltyCalc(
                                    dbo.computePODStatusPayment(
                                        dbo.computeOverdueDays(
                                            podsub.U_ActualHCRecDate,
                                            dbo.computePODSubmitDeadline(
                                                podsub.U_DeliveryDateDTR,
                                                ISNULL(clientsub.U_CDC,0)
                                            ),
                                            ISNULL(podsub.U_HolidayOrWeekend, 0)
                                        )
                                    ),
                                    dbo.computeOverdueDays(
                                        podsub.U_ActualHCRecDate,
                                        dbo.computePODSubmitDeadline(
                                            podsub.U_DeliveryDateDTR,
                                            ISNULL(clientsub.U_CDC,0)
                                        ),
                                        ISNULL(podsub.U_HolidayOrWeekend, 0)
                                    )
                                ),
                                dbo.computeLostPenaltyCalc(
                                    dbo.computePODStatusPayment(
                                        dbo.computeOverdueDays(
                                            podsub.U_ActualHCRecDate,
                                            dbo.computePODSubmitDeadline(
                                                podsub.U_DeliveryDateDTR,
                                                ISNULL(clientsub.U_CDC,0)
                                            ),
                                            ISNULL(podsub.U_HolidayOrWeekend, 0)
                                        )
                                    ),
                                    podsub.U_InitialHCRecDate,
                                    podsub.U_DeliveryDateDTR,
                                    pricingsub.U_TotalInitialTruckers
                                ),
                                ISNULL(podsub.U_PenaltiesManual,0)
                            )) -

                            dbo.computeTotalPenaltyWaived(
                                dbo.computeTotalSubPenalties(
                                    dbo.computeClientPenaltyCalc(
                                        dbo.computeClientSubOverdue(
                                            podsub.U_DeliveryDateDTR,
                                            podsub.U_ClientReceivedDate,
                                            ISNULL(podsub.U_WaivedDays, 0),
                                            CAST(ISNULL(clientsub.U_DCD,0) as int)
                                        )
                                    ),
                                    dbo.computeInteluckPenaltyCalc(
                                        dbo.computePODStatusPayment(
                                            dbo.computeOverdueDays(
                                                podsub.U_ActualHCRecDate,
                                                dbo.computePODSubmitDeadline(
                                                    podsub.U_DeliveryDateDTR,
                                                    ISNULL(clientsub.U_CDC,0)
                                                ),
                                                ISNULL(podsub.U_HolidayOrWeekend, 0)
                                            )
                                        ),
                                        dbo.computeOverdueDays(
                                            podsub.U_ActualHCRecDate,
                                            dbo.computePODSubmitDeadline(
                                                podsub.U_DeliveryDateDTR,
                                                ISNULL(clientsub.U_CDC,0)
                                            ),
                                            ISNULL(podsub.U_HolidayOrWeekend, 0)
                                        )
                                    ),
                                    dbo.computeLostPenaltyCalc(
                                        dbo.computePODStatusPayment(
                                            dbo.computeOverdueDays(
                                                podsub.U_ActualHCRecDate,
                                                dbo.computePODSubmitDeadline(
                                                    podsub.U_DeliveryDateDTR,
                                                    ISNULL(clientsub.U_CDC,0)
                                                ),
                                                ISNULL(podsub.U_HolidayOrWeekend, 0)
                                            )
                                        ),
                                        podsub.U_InitialHCRecDate,
                                        podsub.U_DeliveryDateDTR,
                                        pricingsub.U_TotalInitialTruckers
                                    ),
                                    ISNULL(podsub.U_PenaltiesManual,0)
                                ),
                                ISNULL(podsub.U_PercPenaltyCharge,0)))



                            AS TotalAmount




        FROM [@PCTP_TP] tpsub
            INNER JOIN [@PCTP_POD] podsub ON tpsub.U_BookingId = podsub.U_BookingNumber
            INNER JOIN OCRD truckersub ON podsub.U_SAPTrucker = truckersub.CardCode
            INNER JOIN OCRD clientsub ON U_SAPClient = clientsub.CardCode
            INNER JOIN [dbo].[@PCTP_PRICING] pricingsub ON tpsub.U_BookingId = pricingsub.U_BookingId
            LEFT JOIN [@FirstratesTP] ratessub ON ratessub.U_BN = tpsub.U_BookingId AND ratessub.U_PVNo = SUBSTRING(tpsub.U_PVNo, 1, 9)


        WHERE tpsub.U_BookingId = T0.U_BookingId

                        )

                        ,0)
                    ELSE 

                    0.00
                END
            ELSE 0.00
        END - (T0.U_TotalPayable + T0.U_CAandDP + T0.U_Interest) AS U_VarTP,


        CAST
        ((
                SELECT DISTINCT
            SUBSTRING(
                    (
                        SELECT CONCAT(', ', header.DocNum)  AS [text()]
            FROM PCH1 line
                LEFT JOIN OPCH header ON header.DocEntry = line.DocEntry
            WHERE header.CANCELED = 'N' AND header.PaidSum = 0 AND (line.ItemCode = T0.U_BookingId
                or REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%')
            FOR XML PATH (''), TYPE
                    ).value('text()[1]','nvarchar(max)'), 2, 1000) DocEntry
        FROM OPCH header
            LEFT JOIN PCH1 line ON line.DocEntry = header.DocEntry
        WHERE header.CANCELED = 'N' AND (line.ItemCode = T0.U_BookingId
            or REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%'))
        as nvarchar
        (max)
            ) AS U_DocNum,
        CAST
        ((
                SELECT DISTINCT
            SUBSTRING(
                    (
                        SELECT CONCAT(', ', header.DocNum)  AS [text()]
            FROM PCH1 line
                LEFT JOIN OPCH header ON header.DocEntry = line.DocEntry
            WHERE header.CANCELED = 'N' AND header.PaidSum > 0 AND (line.ItemCode = T0.U_BookingId
                or REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%')
            FOR XML PATH (''), TYPE
                    ).value('text()[1]','nvarchar(max)'), 2, 1000) DocEntry
        FROM OPCH header
            LEFT JOIN PCH1 line ON line.DocEntry = header.DocEntry
        WHERE header.CANCELED = 'N' AND (line.ItemCode = T0.U_BookingId
            or REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%'))
        as nvarchar
        (max)
            ) AS U_Paid,

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
                WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN pricing.U_GrossTruckerRates
                WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN (pricing.U_GrossTruckerRates / 1.12)
            END + CASE
                WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN pricing.U_Demurrage2
                WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN (pricing.U_Demurrage2 / 1.12)
            END + CASE
                WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN (pricing.U_AddtlDrop + pricing.U_BoomTruck + pricing.U_Manpower + pricing.U_Backload)
                WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN ((pricing.U_AddtlDrop + pricing.U_BoomTruck + pricing.U_Manpower + pricing.U_Backload) / 1.12)
            END
            -- pricing.U_TotalInitialTruckers
        ) AS U_LostPenaltyCalc,
        ABS(dbo.computeTotalSubPenalties(
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
                    WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN pricing.U_GrossTruckerRates
                    WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN (pricing.U_GrossTruckerRates / 1.12)
                END + CASE
                    WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN pricing.U_Demurrage2
                    WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN (pricing.U_Demurrage2 / 1.12)
                END + CASE
                    WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN (pricing.U_AddtlDrop + pricing.U_BoomTruck + pricing.U_Manpower + pricing.U_Backload)
                    WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN ((pricing.U_AddtlDrop + pricing.U_BoomTruck + pricing.U_Manpower + pricing.U_Backload) / 1.12)
                END
                -- pricing.U_TotalInitialTruckers
            ),
            ISNULL(pod.U_PenaltiesManual,0)
        )) AS U_TotalSubPenalty,
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
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN pricing.U_GrossTruckerRates
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN (pricing.U_GrossTruckerRates / 1.12)
                    END + CASE
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN pricing.U_Demurrage2
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN (pricing.U_Demurrage2 / 1.12)
                    END + CASE
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN (pricing.U_AddtlDrop + pricing.U_BoomTruck + pricing.U_Manpower + pricing.U_Backload)
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN ((pricing.U_AddtlDrop + pricing.U_BoomTruck + pricing.U_Manpower + pricing.U_Backload) / 1.12)
                    END
                    -- pricing.U_TotalInitialTruckers
                ),
                ISNULL(pod.U_PenaltiesManual,0)
            ),
            ISNULL(pod.U_PercPenaltyCharge,0)
        ) AS U_TotalPenaltyWaived,
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
        ) AS U_InteluckPenaltyCalc,

        dbo.computeClientSubOverdue(
            pod.U_DeliveryDateDTR,
            pod.U_ClientReceivedDate,
            ISNULL(pod.U_WaivedDays, 0),
            CAST(ISNULL(T4.U_DCD,0) as int)
        ) AS U_ClientSubOverdue,
        dbo.computeClientPenaltyCalc(
            dbo.computeClientSubOverdue(
                pod.U_DeliveryDateDTR,
                pod.U_ClientReceivedDate,
                ISNULL(pod.U_WaivedDays, 0),
                CAST(ISNULL(T4.U_DCD,0) as int)
            )
        ) AS U_ClientPenaltyCalc

    INTO TMP_UPDATE_TP_FORMULA_$serial

    FROM [dbo].[@PCTP_TP] T0 WITH (NOLOCK)
        RIGHT JOIN [dbo].[@PCTP_POD] pod ON T0.U_BookingId = pod.U_BookingNumber AND CAST(pod.U_PODStatusDetail as nvarchar(max)) LIKE '%Verified%'
        LEFT JOIN OCRD T4 ON pod.U_SAPClient = T4.CardCode
        LEFT JOIN [dbo].[@PCTP_PRICING] pricing ON T0.U_BookingId = pricing.U_BookingId
        LEFT JOIN OCRD trucker ON pod.U_SAPTrucker = trucker.CardCode
    WHERE T0.U_BookingId IN (SELECT U_BookingNumber FROM TMP_TARGET_$serial WITH (NOLOCK));


    DELETE FROM TP_FORMULA WHERE U_BookingId IN (SELECT U_BookingNumber FROM TMP_TARGET_$serial WITH (NOLOCK));


    INSERT INTO TP_FORMULA
    SELECT
        U_BookingId, DisableTableRow, DisableSomeFields, U_TotalAP, U_VarTP, U_DocNum, U_Paid, U_LostPenaltyCalc, U_TotalSubPenalty, U_TotalPenaltyWaived, U_InteluckPenaltyCalc, U_ClientSubOverdue, 
        U_ClientPenaltyCalc
    FROM TMP_UPDATE_TP_FORMULA_$serial;


    DROP TABLE IF EXISTS TMP_UPDATE_TP_FORMULA_$serial;


DROP TABLE IF EXISTS TMP_TARGET_$serial;
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