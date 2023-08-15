PRINT 'CREATING TARGETS'
    
    DROP TABLE IF EXISTS TMP_TARGET
    SELECT
	    T0.U_BookingNumber
    INTO TMP_TARGET
    FROM [dbo].[@PCTP_POD] T0  WITH (NOLOCK)
    WHERE T0.U_BookingNumber IN ($bookingIds);

-------->>TP_FORMULA
PRINT 'UPDATING [@FirstratesTP]'

    UPDATE [@FirstratesTP] 
    SET U_Amount = NULL
    WHERE U_Amount = 'NaN' AND U_BN IN (SELECT U_BookingNumber FROM TMP_TARGET WITH (NOLOCK));

    UPDATE [@FirstratesTP] 
    SET U_AddlAmount = NULL
    WHERE U_AddlAmount = 'NaN' AND U_BN IN (SELECT U_BookingNumber FROM TMP_TARGET WITH (NOLOCK));


PRINT 'CREATING TMP_UPDATE_TP_FORMULA'

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
    WHERE T0.U_BookingId IN (SELECT U_BookingNumber FROM TMP_TARGET WITH (NOLOCK));


PRINT 'DELETING TARGET BNs FROM TP_FORMULA'

    DELETE FROM TP_FORMULA WHERE U_BookingId IN (SELECT U_BookingNumber FROM TMP_TARGET WITH (NOLOCK));


PRINT 'INSERTING TARGET BNs TO TP_FORMULA'

    INSERT INTO TP_FORMULA
    SELECT
        U_BookingId, DisableTableRow, DisableSomeFields, U_TotalAP, U_VarTP, U_DocNum, U_Paid, U_LostPenaltyCalc, U_TotalSubPenalty, U_TotalPenaltyWaived, U_InteluckPenaltyCalc, U_ClientSubOverdue, 
        U_ClientPenaltyCalc
    FROM TMP_UPDATE_TP_FORMULA_$serial;


PRINT 'DROPPING TMP_UPDATE_TP_FORMULA'

    DROP TABLE IF EXISTS TMP_UPDATE_TP_FORMULA_$serial;


-------->>BILLING_EXTRACT

PRINT 'CREATING TMP_UPDATE_BILLING_EXTRACT'

    DROP TABLE IF EXISTS TMP_UPDATE_BILLING_EXTRACT_$serial
    SELECT
        --COLUMNS
        T0.U_BookingId AS U_BookingNumber ,
        CASE
            WHEN (SELECT DISTINCT COUNT(*)
        FROM OINV H LEFT JOIN INV1 L ON H.DocEntry = L.DocEntry
        WHERE L.ItemCode = T0.U_BookingId AND H.CANCELED = 'N') > 1
            THEN 'Y'
            ELSE 'N'
        END AS DisableTableRow,
        CASE
            WHEN (SELECT DISTINCT COUNT(*)
        FROM OINV H LEFT JOIN INV1 L ON H.DocEntry = L.DocEntry
        WHERE L.ItemCode = T0.U_BookingId AND H.CANCELED = 'N') = 1
            THEN 'DisableSomeFields'
            ELSE ''
        END AS DisableSomeFields,
        T0.Code,
        T0.U_BookingId,
        pod.U_BookingDate,
        -- T0.U_PODNum,
        T0.U_BookingId AS U_PODNum,
        (
            SELECT TOP 1
            header.DocNum
        FROM ORDR header
            LEFT JOIN RDR1 line ON line.DocEntry = header.DocEntry
        WHERE line.ItemCode = T0.U_BookingId
            AND header.CANCELED = 'N'
        ) AS U_PODSONum,
        T2.CardName AS U_CustomerName,
        pod.U_SAPClient AS U_SAPClient,
        T0.U_PlateNumber,
        pod.U_VehicleTypeCap,
        pod.U_DeliveryStatus,
        pod.U_DeliveryDatePOD,
        pod.U_NoOfDrops,
        pod.U_TripType AS U_TripType,
        pod.U_ClientReceivedDate,
        pod.U_ActualHCRecDate,
        pod.U_PODinCharge AS U_PODinCharge,
        pod.U_VerifiedDateHC,
        pod.U_PTFNo,
        T0.U_DateForwardedBT,
        T0.U_BillingDeadline,
        -- T0.U_BillingStatus,
        CASE WHEN EXISTS(
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
        ) THEN (
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
        ) ELSE T0.U_BillingStatus END AS U_BillingStatus,
        -- CASE WHEN ARHeader.U_BillingStatus IS NOT NULL THEN ARHeader.U_BillingStatus
        -- ELSE T0.U_BillingStatus END AS U_BillingStatus,
        T0.U_BillingTeam,
        pricing.U_GrossClientRates AS U_GrossInitialRate,
        pricing.U_Demurrage AS U_Demurrage,

        ISNULL(pricing.U_AddtlDrop,0) + 
    ISNULL(pricing.U_BoomTruck,0) + 
    ISNULL(pricing.U_Manpower,0) + 
    ISNULL(pricing.U_Backload,0)  AS U_AddCharges,


        T0.U_ActualBilledRate,
        T0.U_RateAdjustments,
        T0.U_ActualDemurrage,
        T0.U_ActualAddCharges,
        T0.U_TotalRecClients,
        T0.U_CheckingTotalBilled,
        T0.U_Checking,
        T0.U_CWT2307,
        pod.U_SOBNumber AS U_SOBNumber,
        pod.U_ForwardLoad AS U_ForwardLoad,
        pod.U_BackLoad AS U_BackLoad,
        pod.U_TypeOfAccessorial AS U_TypeOfAccessorial,
        pod.U_TimeInEmptyDem AS U_TimeInEmptyDem,
        pod.U_TimeOutEmptyDem AS U_TimeOutEmptyDem,
        pod.U_VerifiedEmptyDem AS U_VerifiedEmptyDem,
        pod.U_TimeInLoadedDem AS U_TimeInLoadedDem,
        pod.U_TimeOutLoadedDem AS U_TimeOutLoadedDem,
        pod.U_VerifiedLoadedDem AS U_VerifiedLoadedDem,
        pod.U_TimeInAdvLoading AS U_TimeInAdvLoading,
        pod.U_DayOfTheWeek AS U_DayOfTheWeek,
        pod.U_TimeIn AS U_TimeIn,
        pod.U_TimeOut AS U_TimeOut,
        pod.U_TotalNoExceed AS U_TotalExceed,
        pod.U_ODOIn AS U_ODOIn,
        pod.U_ODOOut AS U_ODOOut,
        pod.U_TotalUsage AS U_TotalUsage,
        T0.U_SOLineNum,
        T0.U_ARInvLineNum,
        T4.ExtraDays,
        (SELECT
            SUM(L.PriceAfVAT)
        FROM OINV H
            LEFT JOIN INV1 L ON H.DocEntry = L.DocEntry
        WHERE H.CANCELED = 'N' AND L.ItemCode = T0.U_BookingId) AS U_TotalAR,
        (SELECT
            SUM(L.PriceAfVAT)
        FROM OINV H
            LEFT JOIN INV1 L ON H.DocEntry = L.DocEntry
        WHERE H.CANCELED = 'N' AND L.ItemCode = T0.U_BookingId) - T0.U_TotalRecClients AS U_VarAR,
        CAST((
            SELECT DISTINCT
            SUBSTRING(
                    (
                        SELECT CONCAT(', ', header.U_ServiceType)  AS [text()]
            FROM INV1 line
                LEFT JOIN OINV header ON header.DocEntry = line.DocEntry
            WHERE line.ItemCode = T0.U_BookingId
                AND header.U_ServiceType IS NOT NULL
                AND header.CANCELED = 'N'
            FOR XML PATH (''), TYPE
                    ).value('text()[1]','nvarchar(max)'), 2, 1000) DocEntry
        FROM OINV header
            LEFT JOIN INV1 line ON line.DocEntry = header.DocEntry
        WHERE line.ItemCode = T0.U_BookingId
            AND header.U_ServiceType IS NOT NULL
            AND header.CANCELED = 'N'
            ) as nvarchar(max)
        ) AS U_ServiceType,
        CAST((
            SELECT DISTINCT
            SUBSTRING(
                    (
                        SELECT CONCAT(', ', header.DocNum)  AS [text()]
            FROM INV1 line
                LEFT JOIN OINV header ON header.DocEntry = line.DocEntry
            WHERE line.ItemCode = T0.U_BookingId
                AND header.CANCELED = 'N'
            FOR XML PATH (''), TYPE
                    ).value('text()[1]','nvarchar(max)'), 2, 1000) DocEntry
        FROM OINV header
            LEFT JOIN INV1 line ON line.DocEntry = header.DocEntry
        WHERE line.ItemCode = T0.U_BookingId
            AND header.CANCELED = 'N') as nvarchar(max)
        ) AS U_DocNum,
        CAST((
            SELECT DISTINCT
            SUBSTRING(
                    (
                        SELECT
                CASE
                            WHEN header.U_InvoiceNo = '' OR header.U_InvoiceNo IS NULL THEN ''
                            ELSE CONCAT(', ', header.U_InvoiceNo)
                        END AS [text()]
            FROM INV1 line
                LEFT JOIN OINV header ON header.DocEntry = line.DocEntry
            WHERE line.ItemCode = T0.U_BookingId
                AND header.CANCELED = 'N'
            FOR XML PATH (''), TYPE
                    ).value('text()[1]','nvarchar(max)'), 2, 1000) DocEntry
        FROM OINV header
            LEFT JOIN INV1 line ON line.DocEntry = header.DocEntry
        WHERE line.ItemCode = T0.U_BookingId
            AND header.CANCELED = 'N') as nvarchar(max)
        ) AS U_InvoiceNo,

        CAST(pod.U_DeliveryReceiptNo as nvarchar(max)) AS U_DeliveryReceiptNo,
        CAST(pod.U_SeriesNo as nvarchar(max)) AS U_SeriesNo,
        ISNULL(CAST(T2.U_GroupLocation as nvarchar(max)), T0.U_GroupProject) AS U_GroupProject,
        CAST(pod.U_DeliveryOrigin as nvarchar(max)) AS U_DeliveryOrigin,
        CAST(pod.U_Destination as nvarchar(max)) AS U_Destination,
        CAST(pod.U_OtherPODDoc as nvarchar(max)) AS U_OtherPODDoc,
        CAST(pod.U_RemarksPOD as nvarchar(max)) AS U_RemarksPOD,
        CAST(pod.U_PODStatusDetail as nvarchar(max)) AS U_PODStatusDetail,
        CAST(T0.U_BTRemarks as nvarchar(max)) AS U_BTRemarks,
        CAST(pod.U_DestinationClient as nvarchar(max)) AS U_DestinationClient,
        CAST(pod.U_Remarks as nvarchar(max)) AS U_Remarks,
        CAST(pod.U_Attachment as nvarchar(max)) AS U_Attachment,
        CAST(pod.U_SI_DRNo as nvarchar(max)) AS U_SI_DRNo,
        CAST(pod.U_TripTicketNo as nvarchar(max)) AS U_TripTicketNo,
        CAST(pod.U_WaybillNo as nvarchar(max)) AS U_WaybillNo,
        CAST(pod.U_ShipmentNo as nvarchar(max)) AS U_ShipmentManifestNo,
        CAST(pod.U_OutletNo as nvarchar(max)) AS U_OutletNo,
        CAST(pod.U_CBM as nvarchar(max)) AS U_CBM,
        CAST(pod.U_DeliveryMode as nvarchar(max)) AS U_DeliveryMode,
        CAST(pod.U_SourceWhse as nvarchar(max)) AS U_SourceWhse,
        CAST(pod.U_SONo as nvarchar(max)) AS U_SONo,
        CAST(pod.U_NameCustomer as nvarchar(max)) AS U_NameCustomer,
        CAST(pod.U_CategoryDR as nvarchar(max)) AS U_CategoryDR,
        CAST(pod.U_IDNumber as nvarchar(max)) AS U_IDNumber,
        CAST(pod.U_ApprovalStatus as nvarchar(max)) AS U_Status,
        CAST(pod.U_TotalInvAmount as nvarchar(max)) AS U_TotalInvAmount

    --COLUMNS

    INTO TMP_UPDATE_BILLING_EXTRACT_$serial

    FROM [dbo].[@PCTP_BILLING] T0  WITH (NOLOCK)
        INNER JOIN [dbo].[@PCTP_POD] pod ON T0.U_BookingId = pod.U_BookingNumber
            AND (CAST(pod.U_PODStatusDetail as nvarchar(max)) LIKE '%Verified%' OR CAST(pod.U_PODStatusDetail as nvarchar(max)) LIKE '%ForAdvanceBilling%')
        --JOINS
        LEFT JOIN OCRD T2 ON pod.U_SAPClient = T2.CardCode
        LEFT JOIN [dbo].[@PCTP_PRICING] pricing ON T0.U_BookingId = pricing.U_BookingId
        LEFT JOIN OCTG T4 ON T2.GroupNum = T4.GroupNum
        -- LEFT JOIN (SELECT DocEntry, MIN(ItemCode) AS ItemCode
        -- FROM INV1
        -- GROUP BY DocEntry, ItemCode) ARLine ON ARLine.ItemCode = T0.U_BookingId
        -- LEFT JOIN (SELECT DocEntry, MIN(U_BillingStatus) AS U_BillingStatus, MIN(DocNum) AS DocNum
        -- FROM OINV
        -- GROUP BY DocEntry) ARHeader ON ARHeader.DocEntry = ARLine.DocEntry
        LEFT JOIN TP_FORMULA TF ON TF.U_BookingId = T0.U_BookingId
    --JOINS
    WHERE T0.U_BookingId IN (SELECT U_BookingNumber FROM TMP_TARGET WITH (NOLOCK));


PRINT 'DELETING TARGET BNs FROM BILLING_EXTRACT'

    DELETE FROM BILLING_EXTRACT WHERE U_BookingNumber IN (SELECT U_BookingNumber FROM TMP_TARGET WITH (NOLOCK));


PRINT 'INSERTING TARGET BNs TO BILLING_EXTRACT'

    INSERT INTO BILLING_EXTRACT
    SELECT
        X.U_BookingNumber, X.DisableTableRow, X.DisableSomeFields, X.Code, X.U_BookingId, X.U_BookingDate, X.U_PODNum, X.U_PODSONum, X.U_CustomerName, X.U_SAPClient, X.U_PlateNumber, X.U_VehicleTypeCap, X.U_DeliveryStatus, X.U_DeliveryDatePOD,
        X.U_NoOfDrops, X.U_TripType, X.U_ClientReceivedDate, X.U_ActualHCRecDate, X.U_PODinCharge, X.U_VerifiedDateHC, X.U_PTFNo, X.U_DateForwardedBT, X.U_BillingDeadline, X.U_BillingStatus, X.U_BillingTeam, X.U_GrossInitialRate, X.U_Demurrage,
        X.U_AddCharges, X.U_ActualBilledRate, X.U_RateAdjustments, X.U_ActualDemurrage, X.U_ActualAddCharges, X.U_TotalRecClients, X.U_CheckingTotalBilled, X.U_Checking, X.U_CWT2307, X.U_SOBNumber, X.U_ForwardLoad, X.U_BackLoad,
        X.U_TypeOfAccessorial, X.U_TimeInEmptyDem, X.U_TimeOutEmptyDem, X.U_VerifiedEmptyDem, X.U_TimeInLoadedDem, X.U_TimeOutLoadedDem, X.U_VerifiedLoadedDem, X.U_TimeInAdvLoading, X.U_DayOfTheWeek, X.U_TimeIn, X.U_TimeOut,
        X.U_TotalExceed, X.U_ODOIn, X.U_ODOOut, X.U_TotalUsage, X.U_SOLineNum, X.U_ARInvLineNum, X.ExtraDays, X.U_TotalAR, X.U_VarAR, X.U_ServiceType, X.U_DocNum, X.U_InvoiceNo, X.U_DeliveryReceiptNo, X.U_SeriesNo, X.U_GroupProject, X.U_DeliveryOrigin,
        X.U_Destination, X.U_OtherPODDoc, X.U_RemarksPOD, X.U_PODStatusDetail, X.U_BTRemarks, X.U_DestinationClient, X.U_Remarks, X.U_Attachment, X.U_SI_DRNo, X.U_TripTicketNo, X.U_WaybillNo, X.U_ShipmentManifestNo, X.U_OutletNo, X.U_CBM,
        X.U_DeliveryMode, X.U_SourceWhse, X.U_SONo, X.U_NameCustomer, X.U_CategoryDR, X.U_IDNumber, X.U_Status, X.U_TotalInvAmount
    FROM TMP_UPDATE_BILLING_EXTRACT_$serial X;


PRINT 'DROPPING TMP_UPDATE_BILLING_EXTRACT'

    DROP TABLE IF EXISTS TMP_UPDATE_BILLING_EXTRACT_$serial;


-------->>TP_EXTRACT

PRINT 'CREATING TMP_UPDATE_TP_EXTRACT'

    DROP TABLE IF EXISTS TMP_UPDATE_TP_EXTRACT_$serial
    SELECT


    --COLUMNS
    -- CASE
    --     WHEN (
    --         SELECT DISTINCT COUNT(*)
    -- FROM OPCH H LEFT JOIN PCH1 L ON H.DocEntry = L.DocEntry
    -- WHERE H.CANCELED = 'N'
    --     AND (L.ItemCode = T0.U_BookingId OR REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(H.U_PVNo)) + '%')
    --     ) > 1
    --     THEN 'Y'
    --     ELSE 'N'
    -- END AS DisableTableRow,
    TF.DisableTableRow,
    -- CASE
    --     WHEN (
    --         SELECT DISTINCT COUNT(*)
    -- FROM OPCH H LEFT JOIN PCH1 L ON H.DocEntry = L.DocEntry
    -- WHERE H.CANCELED = 'N'
    --     AND (L.ItemCode = T0.U_BookingId) OR (REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(H.U_PVNo)) + '%')
    --     ) = 1
    --     THEN 'DisableSomeFields'
    --     ELSE ''
    -- END AS DisableSomeFields,
    T0.U_BookingId AS U_BookingNumber ,
    TF.DisableSomeFields,
    T0.Code,
    T0.U_BookingId,
    pod.U_BookingDate,
    -- T0.U_PODNum,
    T0.U_BookingId AS U_PODNum,
    (
        SELECT TOP 1
        header.DocNum
    FROM ORDR header
        LEFT JOIN RDR1 line ON line.DocEntry = header.DocEntry
    WHERE line.ItemCode = billing.U_BookingId
        AND header.CANCELED = 'N'
    ) AS U_PODSONum,
    T4.CardName AS U_ClientName,
    T5.CardName AS U_TruckerName,
    pod.U_SAPTrucker AS U_TruckerSAP,

    pod.U_PlateNumber AS U_PlateNumber,
    pod.U_VehicleTypeCap AS U_VehicleTypeCap,
    pod.U_ISLAND AS U_ISLAND,
    pod.U_ISLAND_D AS U_ISLAND_D,
    pod.U_IFINTERISLAND AS U_IFINTERISLAND,

    pod.U_DeliveryStatus AS U_DeliveryStatus,
    pod.U_DeliveryDatePOD AS U_DeliveryDatePOD,

    pod.U_NoOfDrops AS U_NoOfDrops,
    pod.U_TripType AS U_TripType,

    pod.U_Receivedby AS U_Receivedby,
    pod.U_ClientReceivedDate AS U_ClientReceivedDate,
    pod.U_ActualDateRec_Intitial AS U_ActualDateRec_Intitial,
    pod.U_ActualHCRecDate AS U_ActualHCRecDate,
    pod.U_DateReturned AS U_DateReturned,
    pod.U_PODinCharge AS U_PODinCharge,
    pod.U_VerifiedDateHC AS U_VerifiedDateHC,

    T0.U_TPStatus,
    DATEADD(day, 15, T0.U_BookingDate) 'U_Aging',
    ISNULL(pricing.U_GrossTruckerRates, 0) AS U_GrossTruckerRates,
    pricing.U_RateBasisT AS U_RateBasis,
    CASE
        WHEN ISNULL(T5.VatStatus,'Y') = 'Y' THEN ISNULL(pricing.U_GrossTruckerRates, 0)
        WHEN ISNULL(T5.VatStatus,'Y') = 'N' THEN (ISNULL(pricing.U_GrossTruckerRates, 0) / 1.12)
    END AS 'U_GrossTruckerRatesN',
    CASE
       WHEN ISNULL(T5.VatStatus,'Y') = 'Y' THEN 'VAT' ELSE 'NONVAT'
    END AS 'U_TaxType',
    ISNULL(pricing.U_Demurrage2, 0) AS U_Demurrage,
    ISNULL(pricing.U_AddtlDrop2, 0) AS U_AddtlDrop,
    ISNULL(pricing.U_BoomTruck2, 0) AS U_BoomTruck,
    ISNULL(T0.U_BoomTruck2, 0) AS U_BoomTruck2,
    ISNULL(pricing.U_Manpower2, 0) AS U_Manpower,
    ISNULL(pricing.U_Backload2, 0) AS U_BackLoad,
    -- pricing.U_totalAddtlCharges2 AS U_Addtlcharges,
    ISNULL(pricing.U_AddtlDrop2, 0) 
    + ISNULL(pricing.U_BoomTruck2, 0) 
    + ISNULL(pricing.U_Manpower2, 0) 
    + ISNULL(pricing.U_Backload2, 0) AS U_Addtlcharges,
    CASE
        WHEN ISNULL(T5.VatStatus,'Y') = 'Y' THEN ISNULL(pricing.U_Demurrage2, 0)
        WHEN ISNULL(T5.VatStatus,'Y') = 'N' THEN (ISNULL(pricing.U_Demurrage2, 0) / 1.12)
    END AS 'U_DemurrageN',

    CASE
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
    END AS 'U_AddtlChargesN',

    -- pricing.U_AddtlCharges AS U_AddtlChargesN,
    ISNULL(T0.U_ActualRates, 0) AS U_ActualRates,
    ISNULL(T0.U_RateAdjustments, 0) AS U_RateAdjustments,
    ISNULL(T0.U_ActualDemurrage, 0) AS U_ActualDemurrage,
    ISNULL(T0.U_ActualCharges, 0) AS U_ActualCharges,
    ISNULL(T0.U_OtherCharges, 0) AS U_OtherCharges,
    ISNULL(pod.U_WaivedDays, 0) AS WaivedDaysx,
    TF.U_ClientSubOverdue,
    TF.U_ClientPenaltyCalc,
    ISNULL(pod.U_HolidayOrWeekend, 0) AS xHolidayOrWeekend,
    TF.U_InteluckPenaltyCalc,
    pod.U_InitialHCRecDate,
    pod.U_DeliveryDateDTR,
    pricing.U_TotalInitialTruckers,
    TF.U_LostPenaltyCalc,
    ISNULL(TF.U_TotalSubPenalty, 0) AS U_TotalSubPenalty,
    ISNULL(TF.U_TotalPenaltyWaived, 0) AS U_TotalPenaltyWaived,
    ISNULL(T0.U_TotalPenalty, 0) AS U_TotalPenalty,
    ISNULL(T0.U_TotalPayable, 0) AS U_TotalPayable,
    T0.U_EWT2307,
    ISNULL(T0.U_TotalPayableRec, 0) AS U_TotalPayableRec,

    CASE 
    WHEN substring(T0.U_PVNo, 1, 2) <> ' ,'
      THEN T0.U_PVNo
    ELSE substring(T0.U_PVNo, 3, 100)
    END AS U_PVNo,

    -- T0.U_ORRefNo,
    -- T0.U_ActualPaymentDate,
    -- T0.U_PaymentReference,
    -- T0.U_PaymentStatus,
    T0.U_TPincharge,
    ISNULL(T0.U_CAandDP,0) AS U_CAandDP,
    ISNULL(T0.U_Interest,0) AS U_Interest,
    ISNULL(T0.U_OtherDeductions,0) AS U_OtherDeductions,
    -- ISNULL(T0.U_TOTALDEDUCTIONS,0) AS U_TOTALDEDUCTIONS,
    ISNULL(T0.U_CAandDP,0) + ISNULL(T0.U_Interest,0) + ISNULL(T0.U_OtherDeductions,0) 
    + (ABS(ABS(ISNULL(TF.U_TotalSubPenalty,0)) - ABS(ISNULL(TF.U_TotalPenaltyWaived,0)))) AS U_TOTALDEDUCTIONS,
    T0.U_REMARKS1,
    TF.U_TotalAP,
    TF.U_VarTP,
    '' AS U_APInvLineNum,
    pod.U_PercPenaltyCharge,
    T6.ExtraDays,
    TF.U_DocNum,
    TF.U_Paid,

    CAST(pod.U_OtherPODDoc as nvarchar(max)) AS U_OtherPODDoc,
    CAST(pod.U_DeliveryOrigin as nvarchar(max)) AS U_DeliveryOrigin,
    CAST(pod.U_Remarks as nvarchar(max)) AS U_Remarks2,
    CAST(pod.U_RemarksPOD as nvarchar(max)) AS U_RemarksPOD,
    ISNULL(CAST(T4.U_GroupLocation as nvarchar(max)), '') AS U_GroupProject,
    CAST(pod.U_Destination as nvarchar(max)) AS U_Destination,
    CAST(T0.U_Remarks as nvarchar(max)) AS U_Remarks,
    CAST(pod.U_Attachment as nvarchar(max)) AS U_Attachment,
    CAST(pod.U_TripTicketNo as nvarchar(max)) AS U_TripTicketNo,
    CAST(pod.U_WaybillNo as nvarchar(max)) AS U_WaybillNo,
    CAST(pod.U_ShipmentNo as nvarchar(max)) AS U_ShipmentManifestNo,
    CAST(pod.U_DeliveryReceiptNo as nvarchar(max)) AS U_DeliveryReceiptNo,
    CAST(pod.U_SeriesNo as nvarchar(max)) AS U_SeriesNo,

    SUBSTRING((
        SELECT
			CONCAT(', ', T0.U_OR_Ref) AS [text()]
		FROM OPCH T0 WITH (NOLOCK)
		WHERE T0.Canceled <> 'Y' AND T0.DocNum IN (SELECT RTRIM(LTRIM(value)) AS DocNum FROM STRING_SPLIT(TF.U_Paid, ','))
		FOR XML PATH (''), TYPE).value('text()[1]','nvarchar(max)'), 2, 1000
    ) AS U_ORRefNo,
    SUBSTRING((
        SELECT
            CONCAT(', ', CAST(T0.TrsfrDate AS DATE)) AS [text()]
        FROM OVPM T0
        INNER JOIN VPM2 T1 ON T1.DocNum = T0.DocEntry
        LEFT JOIN VPM1 T2 ON T1.DocNum = T2.DocNum
        LEFT JOIN OPCH T3 ON T1.DocEntry = T3.DocEntry
        WHERE T3.DocNum IN (SELECT RTRIM(LTRIM(value)) AS DocNum FROM STRING_SPLIT(TF.U_Paid, ','))
        FOR XML PATH (''), TYPE).value('text()[1]','nvarchar(max)'), 2, 1000
    ) AS U_ActualPaymentDate,
    SUBSTRING((
        SELECT
            CONCAT(', ', T0.TrsfrRef) AS [text()]
        FROM OVPM T0
        INNER JOIN VPM2 T1 ON T1.DocNum = T0.DocEntry
        LEFT JOIN VPM1 T2 ON T1.DocNum = T2.DocNum
        LEFT JOIN OPCH T3 ON T1.DocEntry = T3.DocEntry
        WHERE T3.DocNum IN (SELECT RTRIM(LTRIM(value)) AS DocNum FROM STRING_SPLIT(TF.U_Paid, ','))
        FOR XML PATH (''), TYPE).value('text()[1]','nvarchar(max)'), 2, 1000
    ) AS U_PaymentReference,
    SUBSTRING((
        SELECT
            CONCAT(', ', 
            CASE 
                WHEN T3.PaidSum - T3.DocTotal <= 0 THEN 'Paid'
                ELSE 'Unpaid' 
            END
            ) AS [text()]
        FROM OVPM T0
        INNER JOIN VPM2 T1 ON T1.DocNum = T0.DocEntry
        LEFT JOIN VPM1 T2 ON T1.DocNum = T2.DocNum
        LEFT JOIN OPCH T3 ON T1.DocEntry = T3.DocEntry
        WHERE T3.DocNum IN (SELECT RTRIM(LTRIM(value)) AS DocNum FROM STRING_SPLIT(TF.U_Paid, ','))
        FOR XML PATH (''), TYPE).value('text()[1]','nvarchar(max)'), 2, 1000
    ) AS U_PaymentStatus






--COLUMNS

INTO TMP_UPDATE_TP_EXTRACT_$serial

FROM [dbo].[@PCTP_TP] T0  WITH (NOLOCK)
    INNER JOIN [dbo].[@PCTP_POD] pod ON T0.U_BookingId = pod.U_BookingNumber AND CAST(pod.U_PODStatusDetail as nvarchar(max)) LIKE '%Verified%'
    --JOINS
    LEFT JOIN [dbo].[@PCTP_PRICING] pricing ON T0.U_BookingId = pricing.U_BookingId
    LEFT JOIN [dbo].[@PCTP_BILLING] billing ON T0.U_BookingId = billing.U_BookingId
    LEFT JOIN OCRD T4 ON pod.U_SAPClient = T4.CardCode
    LEFT JOIN OCRD T5 ON T5.CardCode = pod.U_SAPTrucker
    LEFT JOIN OCTG T6 ON T5.GroupNum = T6.GroupNum
    LEFT JOIN TP_FORMULA TF ON TF.U_BookingId = T0.U_BookingId
--JOINS
    WHERE T0.U_BookingId IN (SELECT U_BookingNumber FROM TMP_TARGET WITH (NOLOCK));


PRINT 'DELETING TARGET BNs FROM TP_EXTRACT'

    DELETE FROM TP_EXTRACT WHERE U_BookingNumber IN (SELECT U_BookingNumber FROM TMP_TARGET WITH (NOLOCK));


PRINT 'INSERTING TARGET BNs TO TP_EXTRACT'

    INSERT INTO TP_EXTRACT
    SELECT
        X.DisableTableRow, X.U_BookingNumber, X.DisableSomeFields, X.Code, X.U_BookingId, X.U_BookingDate, X.U_PODNum, X.U_PODSONum, X.U_ClientName, X.U_TruckerName, X.U_TruckerSAP, X.U_PlateNumber, X.U_VehicleTypeCap, X.U_ISLAND, X.U_ISLAND_D, 
        X.U_IFINTERISLAND, X.U_DeliveryStatus, X.U_DeliveryDatePOD, X.U_NoOfDrops, X.U_TripType, X.U_Receivedby, X.U_ClientReceivedDate, X.U_ActualDateRec_Intitial, X.U_ActualHCRecDate, X.U_DateReturned, X.U_PODinCharge, X.U_VerifiedDateHC, 
        X.U_TPStatus, X.U_Aging, X.U_GrossTruckerRates, X.U_RateBasis, X.U_GrossTruckerRatesN, X.U_TaxType, X.U_Demurrage, X.U_AddtlDrop, X.U_BoomTruck, X.U_BoomTruck2, X.U_Manpower, X.U_BackLoad, X.U_Addtlcharges, X.U_DemurrageN, 
        X.U_AddtlChargesN, X.U_ActualRates, X.U_RateAdjustments, X.U_ActualDemurrage, X.U_ActualCharges, X.U_OtherCharges, X.WaivedDaysx, X.U_ClientSubOverdue, X.U_ClientPenaltyCalc, X.xHolidayOrWeekend, X.U_InteluckPenaltyCalc, 
        X.U_InitialHCRecDate, X.U_DeliveryDateDTR, X.U_TotalInitialTruckers, X.U_LostPenaltyCalc, X.U_TotalSubPenalty, X.U_TotalPenaltyWaived, X.U_TotalPenalty, X.U_TotalPayable, X.U_EWT2307, X.U_TotalPayableRec, X.U_PVNo, X.U_ORRefNo, X.U_TPincharge, 
        X.U_CAandDP, X.U_Interest, X.U_OtherDeductions, X.U_TOTALDEDUCTIONS, X.U_REMARKS1, X.U_TotalAP, X.U_VarTP, X.U_APInvLineNum, X.U_PercPenaltyCharge, X.ExtraDays, X.U_DocNum, X.U_Paid, X.U_OtherPODDoc, X.U_DeliveryOrigin, X.U_Remarks2, 
        X.U_RemarksPOD, X.U_GroupProject, X.U_Destination, X.U_Remarks, X.U_Attachment, X.U_TripTicketNo, X.U_WaybillNo, X.U_ShipmentManifestNo, X.U_DeliveryReceiptNo, X.U_SeriesNo, X.U_ActualPaymentDate, X.U_PaymentReference, 
        X.U_PaymentStatus
    FROM TMP_UPDATE_TP_EXTRACT_$serial X;


PRINT 'DROPPING TMP_UPDATE_TP_EXTRACT'

    DROP TABLE IF EXISTS TMP_UPDATE_TP_EXTRACT_$serial;


-------->>POD_EXTRACT
PRINT 'CREATING TMP_UPDATE_POD_EXTRACT'

    DROP TABLE IF EXISTS TMP_UPDATE_POD_EXTRACT_$serial
    SELECT
        --COLUMNS
        CASE
            WHEN EXISTS(SELECT 1
            FROM OINV H, INV1 L
            WHERE H.DocEntry = L.DocEntry AND L.ItemCode = T0.U_BookingNumber AND H.CANCELED = 'N')
            AND EXISTS(
                    SELECT 1
            FROM OPCH H, PCH1 L
            WHERE H.DocEntry = L.DocEntry AND H.CANCELED = 'N'
                AND (L.ItemCode = T0.U_BookingNumber
                OR (REPLACE(REPLACE(RTRIM(LTRIM(tp.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(H.U_PVNo)) + '%')))
            THEN 'Y'
            ELSE 'N'
        END AS DisableTableRow,
        -- T0.Code,
        T0.U_BookingNumber AS Code,
        T0.U_BookingDate,
        T0.U_BookingNumber,
        (
        SELECT TOP 1
            header.DocNum
        FROM ORDR header
            LEFT JOIN RDR1 line ON line.DocEntry = header.DocEntry
        WHERE line.ItemCode = billing.U_BookingId
            AND header.CANCELED = 'N'
        ) AS U_PODSONum,
        -- billing.U_PODSONum AS U_PODSONum,
        -- T0.U_ClientName,
        client.CardName AS U_ClientName,
        T0.U_SAPClient,
        -- T0.U_TruckerName,
        trucker.CardName AS U_TruckerName,
        T0.U_ISLAND,
        T0.U_ISLAND_D,
        T0.U_IFINTERISLAND,
        T0.U_VERIFICATION_TAT,
        T0.U_POD_TAT,
        T0.U_ActualDateRec_Intitial,
        T0.U_SAPTrucker,
        T0.U_PlateNumber,
        T0.U_VehicleTypeCap,
        T0.U_DeliveryStatus,
        T0.U_DeliveryDateDTR,
        T0.U_DeliveryDatePOD,
        T0.U_NoOfDrops,
        T0.U_TripType,
        -- T0.U_DocNum,
        -- T0.U_TripTicketNo,
        -- T0.U_WaybillNo,
        -- T0.U_ShipmentNo,
        -- T0.U_DeliveryReceiptNo,
        -- T0.U_SeriesNo,
        T0.U_Receivedby,
        T0.U_ClientReceivedDate,
        T0.U_InitialHCRecDate,
        T0.U_ActualHCRecDate,
        T0.U_DateReturned,
        T0.U_PODinCharge,
        T0.U_VerifiedDateHC,
        T0.U_PTFNo,
        T0.U_DateForwardedBT,
        T0.U_BillingDeadline,
        -- T0.U_BillingStatus,
        CASE WHEN EXISTS(
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
        WHERE line.ItemCode = T0.U_BookingNumber
            AND header.CANCELED = 'N'
            AND header.U_BillingStatus IS NOT NULL
        ) THEN (
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
        WHERE line.ItemCode = T0.U_BookingNumber
            AND header.CANCELED = 'N'
            AND header.U_BillingStatus IS NOT NULL
        ) ELSE T0.U_BillingStatus END AS U_BillingStatus,
        -- CASE WHEN ARHeader.U_BillingStatus IS NOT NULL THEN ARHeader.U_BillingStatus
        -- ELSE T0.U_BillingStatus END AS U_BillingStatus,
        T0.U_ServiceType,
        T0.U_SINo,
        T0.U_BillingTeam,
        T0.U_SOBNumber,
        -- T0.U_OutletNo,
        -- T0.U_CBM,
        -- T0.U_SI_DRNo,
        -- T0.U_DeliveryMode,
        -- T0.U_SourceWhse,
        -- T0.U_TotalInvAmount,
        -- T0.U_SONo,
        -- T0.U_NameCustomer,
        -- T0.U_CategoryDR,
        T0.U_ForwardLoad,
        T0.U_BackLoad,
        -- T0.U_IDNumber,
        T0.U_TypeOfAccessorial,
        -- T0.U_ApprovalStatus,
        T0.U_TimeInEmptyDem,
        T0.U_TimeOutEmptyDem,
        T0.U_VerifiedEmptyDem,
        T0.U_TimeInLoadedDem,
        T0.U_TimeOutLoadedDem,
        T0.U_VerifiedLoadedDem,
        T0.U_TimeInAdvLoading,
        T0.U_PenaltiesManual,
        CASE WHEN ISNULL(T0.U_DayOfTheWeek,'') = '' THEN DATENAME(dw, T0.U_BookingDate)
        ELSE T0.U_DayOfTheWeek END AS 'U_DayOfTheWeek',
        T0.U_TimeIn,
        T0.U_TimeOut,
        T0.U_TotalNoExceed,
        T0.U_ODOIn,
        T0.U_ODOOut,
        T0.U_TotalUsage,
        CASE WHEN ISNULL(T0.U_ClientReceivedDate,'') = '' THEN 'PENDING' 
        ELSE 'SUBMITTED' 
        END AS 'U_ClientSubStatus',
        -- CASE WHEN ISNULL(T0.U_ClientReceivedDate,'') != '' AND ISNULL(T0.U_DeliveryDateDTR,'') != '' THEN DATEDIFF(day, T0.U_ClientReceivedDate, T0.U_DeliveryDateDTR) + ISNULL(client.U_DCD,0) + CAST(ISNULL(NULLIF(ISNUMERIC(T0.U_WaivedDays), 0),'0') AS int) 
        -- ELSE 0 END AS 'U_ClientSubOverdue', 
        dbo.computeClientSubOverdue(
            T0.U_DeliveryDateDTR,
            T0.U_ClientReceivedDate,
            ISNULL(T0.U_WaivedDays, 0),
            CAST(ISNULL(client.U_DCD,0) as int)
        ) AS 'U_ClientSubOverdue',
        -- CASE WHEN ISNULL(T0.U_ClientReceivedDate,'') != '' AND ISNULL(T0.U_DeliveryDateDTR,'') != '' THEN 
        --     (CASE WHEN (DATEDIFF(day, T0.U_ClientReceivedDate, T0.U_DeliveryDateDTR) + ISNULL(client.U_DCD,0)) < 0 THEN (DATEDIFF(day, T0.U_ClientReceivedDate, T0.U_DeliveryDateDTR) + ISNULL(client.U_DCD,0)) * 200 ELSE 0 END)
        -- ELSE 0 END AS 'U_ClientPenaltyCalc',
        dbo.computeClientPenaltyCalc(
            dbo.computeClientSubOverdue(
                T0.U_DeliveryDateDTR,
                T0.U_ClientReceivedDate,
                ISNULL(T0.U_WaivedDays, 0),
                CAST(ISNULL(client.U_DCD,0) as int)
            )
        ) AS 'U_ClientPenaltyCalc',
        -- CASE 
        -- WHEN ISNULL(T0.U_ActualHCRecDate,'') = '' AND ISNULL(T0.U_DeliveryDateDTR,'') != ''  THEN 
        --     (CASE WHEN DATEDIFF(day, GETDATE(), DATEADD(day, CAST(ISNULL(client.U_CDC,'0') AS int) + CAST(ISNULL(NULLIF(ISNUMERIC(T0.U_WaivedDays), 0),'0') AS int) + CAST(ISNULL(NULLIF(ISNUMERIC(T0.U_HolidayOrWeekend), 0),'0') AS int), T0.U_DeliveryDateDTR)) >= 0 THEN 'Ontime' 
        --         WHEN DATEDIFF(day, GETDATE(), DATEADD(day, CAST(ISNULL(client.U_CDC,'0') AS int) + CAST(ISNULL(NULLIF(ISNUMERIC(T0.U_WaivedDays), 0),'0') AS int) + CAST(ISNULL(NULLIF(ISNUMERIC(T0.U_HolidayOrWeekend), 0),'0') AS int), T0.U_DeliveryDateDTR)) BETWEEN -13 AND 0 THEN 'Late'
        --         WHEN DATEDIFF(day, GETDATE(), DATEADD(day, CAST(ISNULL(client.U_CDC,'0') AS int) + CAST(ISNULL(NULLIF(ISNUMERIC(T0.U_WaivedDays), 0),'0') AS int) + CAST(ISNULL(NULLIF(ISNUMERIC(T0.U_HolidayOrWeekend), 0),'0') AS int), T0.U_DeliveryDateDTR)) <= -13 THEN 'Lost'
        --     END)
        -- WHEN ISNULL(T0.U_ActualHCRecDate,'') != '' AND ISNULL(T0.U_DeliveryDateDTR,'') != '' THEN 
        --     (CASE WHEN DATEDIFF(day, T0.U_ActualHCRecDate, DATEADD(day, CAST(ISNULL(client.U_CDC,'0') AS int) + CAST(ISNULL(NULLIF(ISNUMERIC(T0.U_WaivedDays), 0),'0') AS int) + CAST(ISNULL(NULLIF(ISNUMERIC(T0.U_HolidayOrWeekend), 0),'0') AS int), T0.U_DeliveryDateDTR)) >= 0 THEN 'Ontime'
        --         WHEN DATEDIFF(day, T0.U_ActualHCRecDate, DATEADD(day, CAST(ISNULL(client.U_CDC,'0') AS int) + CAST(ISNULL(NULLIF(ISNUMERIC(T0.U_WaivedDays), 0),'0') AS int) + CAST(ISNULL(NULLIF(ISNUMERIC(T0.U_HolidayOrWeekend), 0),'0') AS int), T0.U_DeliveryDateDTR)) BETWEEN -13 AND 0 THEN 'Late'
        --         WHEN DATEDIFF(day, T0.U_ActualHCRecDate, DATEADD(day, CAST(ISNULL(client.U_CDC,'0') AS int) + CAST(ISNULL(NULLIF(ISNUMERIC(T0.U_WaivedDays), 0),'0') AS int) + CAST(ISNULL(NULLIF(ISNUMERIC(T0.U_HolidayOrWeekend), 0),'0') AS int), T0.U_DeliveryDateDTR)) <= -13 THEN 'Lost'
        --     END)
        -- ELSE '' END AS 'U_PODStatusPayment',
        dbo.computePODStatusPayment(
            dbo.computeOverdueDays(
                T0.U_ActualHCRecDate,
                dbo.computePODSubmitDeadline(
                    T0.U_DeliveryDateDTR,
                    ISNULL(client.U_CDC,0)
                ),
                ISNULL(T0.U_HolidayOrWeekend, 0)
            )
        ) AS 'U_PODStatusPayment',
        --T0.U_PODStatusPayment,
        -- CASE WHEN ISNULL(T0.U_DeliveryDateDTR,'') != '' THEN DATEADD(day, CAST(ISNULL(client.U_CDC,0) AS int) , T0.U_DeliveryDateDTR)
        -- ELSE T0.U_PODSubmitDeadline END AS 'U_PODSubmitDeadline',
        dbo.computePODSubmitDeadline(
            T0.U_DeliveryDateDTR,
            ISNULL(client.U_CDC,0)
        ) AS 'U_PODSubmitDeadline',
        -- CASE 
        --     WHEN ISNULL(T0.U_ActualHCRecDate,'') = '' AND ISNULL(T0.U_DeliveryDateDTR,'') != '' THEN DATEDIFF(day, GETDATE(), DATEADD(day, CAST(ISNULL(client.U_CDC,'0') AS int) + CAST(ISNULL(NULLIF(ISNUMERIC(T0.U_HolidayOrWeekend), 0),'0') AS int), T0.U_DeliveryDateDTR))
        --     WHEN ISNULL(T0.U_ActualHCRecDate,'') != '' AND ISNULL(T0.U_DeliveryDateDTR,'') != '' THEN DATEDIFF(day, T0.U_ActualHCRecDate, DATEADD(day, CAST(ISNULL(client.U_CDC,'0') AS int) + CAST(ISNULL(NULLIF(ISNUMERIC(T0.U_HolidayOrWeekend), 0),'0') AS int), T0.U_DeliveryDateDTR)) 
        -- ELSE 0 END AS 'U_OverdueDays',
        dbo.computeOverdueDays(
            T0.U_ActualHCRecDate,
            dbo.computePODSubmitDeadline(
                T0.U_DeliveryDateDTR,
                ISNULL(client.U_CDC,0)
            ),
            ISNULL(T0.U_HolidayOrWeekend, 0)
        ) AS 'U_OverdueDays',
        --T0.U_OverdueDays,
        -- CASE 
        -- WHEN ISNULL(T0.U_InitialHCRecDate,'') = '' AND ISNULL(T0.U_DeliveryDateDTR,'') != '' THEN 
        --     (CASE WHEN DATEDIFF(day, GETDATE(), DATEADD(day, CAST(ISNULL(client.U_CDC,'0') AS int) , T0.U_DeliveryDateDTR)) BETWEEN -13 AND 0 THEN DATEDIFF(day, GETDATE(), DATEADD(day, CAST(ISNULL(client.U_CDC,'0') AS int) , T0.U_DeliveryDateDTR)) * 200 ELSE 0 END)
        -- WHEN ISNULL(T0.U_InitialHCRecDate,'') != '' AND ISNULL(T0.U_DeliveryDateDTR,'') != '' THEN 
        --     (CASE WHEN DATEDIFF(day, T0.U_InitialHCRecDate, DATEADD(day, CAST(ISNULL(client.U_CDC,'0') AS int) , T0.U_DeliveryDateDTR)) BETWEEN -13 AND 0 THEN DATEDIFF(day, T0.U_InitialHCRecDate, DATEADD(day, CAST(ISNULL(client.U_CDC,'0') AS int) , T0.U_DeliveryDateDTR)) * 200 ELSE 0 END)
        -- ELSE 0 END AS 'U_InteluckPenaltyCalc',
        dbo.computeInteluckPenaltyCalc(
            dbo.computePODStatusPayment(
                dbo.computeOverdueDays(
                    T0.U_ActualHCRecDate,
                    dbo.computePODSubmitDeadline(
                        T0.U_DeliveryDateDTR,
                        ISNULL(client.U_CDC,0)
                    ),
                    ISNULL(T0.U_HolidayOrWeekend, 0)
                )
            ),
            dbo.computeOverdueDays(
                T0.U_ActualHCRecDate,
                dbo.computePODSubmitDeadline(
                    T0.U_DeliveryDateDTR,
                    ISNULL(client.U_CDC,0)
                ),
                ISNULL(T0.U_HolidayOrWeekend, 0)
            )
        ) AS 'U_InteluckPenaltyCalc',
        T0.U_WaivedDays,
        T0.U_HolidayOrWeekend,
        -- CASE 
        -- WHEN ISNULL(T0.U_InitialHCRecDate,'') = '' AND ISNULL(T0.U_DeliveryDateDTR,'') != '' THEN 
        --     (CASE WHEN DATEDIFF(day, GETDATE(), DATEADD(day, CAST(ISNULL(client.U_CDC,'0') AS int) , T0.U_DeliveryDateDTR)) <= -13 THEN (CASE WHEN ISNULL(pricing.U_TotalInitialTruckers,0) <> 0 THEN -(pricing.U_TotalInitialTruckers * 2) ELSE 0 END) END )
        -- WHEN ISNULL(T0.U_InitialHCRecDate,'') != '' AND ISNULL(T0.U_DeliveryDateDTR,'') != '' THEN 
        --     (CASE WHEN DATEDIFF(day, T0.U_InitialHCRecDate, DATEADD(day, CAST(ISNULL(client.U_CDC,'0') AS int) , T0.U_DeliveryDateDTR)) <= -13 THEN (CASE WHEN ISNULL(pricing.U_TotalInitialTruckers,0) <> 0 THEN -(pricing.U_TotalInitialTruckers * 2) ELSE 0 END) END )
        -- ELSE 0 END AS 'U_LostPenaltyCalc',
        dbo.computeLostPenaltyCalc(
            dbo.computePODStatusPayment(
                dbo.computeOverdueDays(
                    T0.U_ActualHCRecDate,
                    dbo.computePODSubmitDeadline(
                        T0.U_DeliveryDateDTR,
                        ISNULL(client.U_CDC,0)
                    ),
                    ISNULL(T0.U_HolidayOrWeekend, 0)
                )
            ),
            T0.U_InitialHCRecDate,
            T0.U_DeliveryDateDTR,
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
        ) AS 'U_LostPenaltyCalc',
        -- T0.U_TotalSubPenalties,
        dbo.computeTotalSubPenalties(
            dbo.computeClientPenaltyCalc(
                dbo.computeClientSubOverdue(
                    T0.U_DeliveryDateDTR,
                    T0.U_ClientReceivedDate,
                    ISNULL(T0.U_WaivedDays, 0),
                    CAST(ISNULL(client.U_DCD,0) as int)
                )
            ),
            dbo.computeInteluckPenaltyCalc(
                dbo.computePODStatusPayment(
                    dbo.computeOverdueDays(
                        T0.U_ActualHCRecDate,
                        dbo.computePODSubmitDeadline(
                            T0.U_DeliveryDateDTR,
                            ISNULL(client.U_CDC,0)
                        ),
                        ISNULL(T0.U_HolidayOrWeekend, 0)
                    )
                ),
                dbo.computeOverdueDays(
                    T0.U_ActualHCRecDate,
                    dbo.computePODSubmitDeadline(
                        T0.U_DeliveryDateDTR,
                        ISNULL(client.U_CDC,0)
                    ),
                    ISNULL(T0.U_HolidayOrWeekend, 0)
                )
            ),
            dbo.computeLostPenaltyCalc(
                dbo.computePODStatusPayment(
                    dbo.computeOverdueDays(
                        T0.U_ActualHCRecDate,
                        dbo.computePODSubmitDeadline(
                            T0.U_DeliveryDateDTR,
                            ISNULL(client.U_CDC,0)
                        ),
                        ISNULL(T0.U_HolidayOrWeekend, 0)
                    )
                ),
                T0.U_InitialHCRecDate,
                T0.U_DeliveryDateDTR,
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
            ),
            ISNULL(T0.U_PenaltiesManual,0)
        ) AS U_TotalSubPenalties,
        CASE WHEN ISNULL(T0.U_Waived,'') = '' THEN 'N' 
        ELSE T0.U_Waived END AS 'U_Waived',
        T0.U_PercPenaltyCharge,
        T0.U_Approvedby,
        -- T0.U_TotalPenaltyWaived,
        dbo.computeTotalPenaltyWaived(
            dbo.computeTotalSubPenalties(
                dbo.computeClientPenaltyCalc(
                    dbo.computeClientSubOverdue(
                        T0.U_DeliveryDateDTR,
                        T0.U_ClientReceivedDate,
                        ISNULL(T0.U_WaivedDays, 0),
                        CAST(ISNULL(client.U_DCD,0) as int)
                    )
                ),
                dbo.computeInteluckPenaltyCalc(
                    dbo.computePODStatusPayment(
                        dbo.computeOverdueDays(
                            T0.U_ActualHCRecDate,
                            dbo.computePODSubmitDeadline(
                                T0.U_DeliveryDateDTR,
                                ISNULL(client.U_CDC,0)
                            ),
                            ISNULL(T0.U_HolidayOrWeekend, 0)
                        )
                    ),
                    dbo.computeOverdueDays(
                        T0.U_ActualHCRecDate,
                        dbo.computePODSubmitDeadline(
                            T0.U_DeliveryDateDTR,
                            ISNULL(client.U_CDC,0)
                        ),
                        ISNULL(T0.U_HolidayOrWeekend, 0)
                    )
                ),
                dbo.computeLostPenaltyCalc(
                    dbo.computePODStatusPayment(
                        dbo.computeOverdueDays(
                            T0.U_ActualHCRecDate,
                            dbo.computePODSubmitDeadline(
                                T0.U_DeliveryDateDTR,
                                ISNULL(client.U_CDC,0)
                            ),
                            ISNULL(T0.U_HolidayOrWeekend, 0)
                        )
                    ),
                    T0.U_InitialHCRecDate,
                    T0.U_DeliveryDateDTR,
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
                ),
                ISNULL(T0.U_PenaltiesManual,0)
            ),
            ISNULL(T0.U_PercPenaltyCharge,0)
        ) AS U_TotalPenaltyWaived,
        ISNULL(billing.Code,'') 'BillingNum',
        ISNULL(tp.Code,'') 'TPNum',
        ISNULL(pricing.Code,'') 'PricingNum',
        ISNULL(client.U_CDC,0) 'CDC',
        ISNULL(client.U_DCD,0) 'DCD',
        ISNULL(pricing.U_GrossTruckerRates,0) 'GrossTruckerRates',
        ISNULL(CAST(client.U_GroupLocation as nvarchar(max)), '') AS U_GroupProject,
        CAST(T0.U_Attachment as nvarchar(max)) AS U_Attachment,
        CAST(T0.U_DeliveryOrigin as nvarchar(max)) AS U_DeliveryOrigin,
        CAST(T0.U_Destination as nvarchar(max)) AS U_Destination,
        CAST(T0.U_Remarks as nvarchar(max)) AS U_Remarks,
        CAST(T0.U_OtherPODDoc as nvarchar(max)) AS U_OtherPODDoc,
        CAST(T0.U_RemarksPOD as nvarchar(max)) AS U_RemarksPOD,
        CAST(T0.U_PODStatusDetail as nvarchar(max)) AS U_PODStatusDetail,
        CAST(T0.U_BTRemarks as nvarchar(max)) AS U_BTRemarks,
        CAST(T0.U_DestinationClient as nvarchar(max)) AS U_DestinationClient,
        CAST(T0.U_Remarks2 as nvarchar(max)) AS U_Remarks2,
        CAST(T0.U_DocNum as nvarchar(max)) AS U_DocNum,
        CAST(T0.U_TripTicketNo as nvarchar(max)) AS U_TripTicketNo,
        CAST(T0.U_WaybillNo as nvarchar(max)) AS U_WaybillNo,
        CAST(T0.U_ShipmentNo as nvarchar(max)) AS U_ShipmentNo,
        CAST(T0.U_DeliveryReceiptNo as nvarchar(max)) AS U_DeliveryReceiptNo,
        CAST(T0.U_SeriesNo as nvarchar(max)) AS U_SeriesNo,
        CAST(T0.U_OutletNo as nvarchar(max)) AS U_OutletNo,
        CAST(T0.U_CBM as nvarchar(max)) AS U_CBM,
        CAST(T0.U_SI_DRNo as nvarchar(max)) AS U_SI_DRNo,
        CAST(T0.U_DeliveryMode as nvarchar(max)) AS U_DeliveryMode,
        CAST(T0.U_SourceWhse as nvarchar(max)) AS U_SourceWhse,
        CAST(T0.U_SONo as nvarchar(max)) AS U_SONo,
        CAST(T0.U_NameCustomer as nvarchar(max)) AS U_NameCustomer,
        CAST(T0.U_CategoryDR as nvarchar(max)) AS U_CategoryDR,
        CAST(T0.U_IDNumber as nvarchar(max)) AS U_IDNumber,
        CAST(T0.U_ApprovalStatus as nvarchar(max)) AS U_ApprovalStatus,
        CAST(T0.U_TotalInvAmount as nvarchar(max)) AS U_TotalInvAmount

    INTO TMP_UPDATE_POD_EXTRACT_$serial
    --COLUMNS
    FROM [dbo].[@PCTP_POD] T0 WITH (NOLOCK)
        --JOINS
        LEFT JOIN [dbo].[@PCTP_BILLING] billing ON T0.U_BookingNumber = billing.U_BookingId
        LEFT JOIN [dbo].[@PCTP_TP] tp ON T0.U_BookingNumber = tp.U_BookingId
        LEFT JOIN [dbo].[@PCTP_PRICING] pricing ON T0.U_BookingNumber = pricing.U_BookingId
        LEFT JOIN OCRD client ON T0.U_SAPClient = client.CardCode
        LEFT JOIN OCRD trucker ON T0.U_SAPTrucker = trucker.CardCode
        -- LEFT JOIN (SELECT DocEntry, MIN(ItemCode) AS ItemCode FROM INV1 GROUP BY DocEntry, ItemCode) ARLine ON ARLine.ItemCode = T0.U_BookingNumber
        -- LEFT JOIN (SELECT DocEntry, MIN(U_BillingStatus) AS U_BillingStatus, MIN(DocNum) AS DocNum FROM OINV GROUP BY DocEntry) ARHeader ON ARHeader.DocEntry = ARLine.DocEntry
        LEFT JOIN TP_FORMULA TF ON TF.U_BookingId = T0.U_BookingNumber
    WHERE T0.U_BookingNumber IN (SELECT U_BookingNumber FROM TMP_TARGET WITH (NOLOCK));


PRINT 'DELETING TARGET BNs FROM POD_EXTRACT'

    DELETE FROM POD_EXTRACT WHERE U_BookingNumber IN (SELECT U_BookingNumber FROM TMP_TARGET WITH (NOLOCK));


PRINT 'INSERTING TARGET BNs TO POD_EXTRACT'

    INSERT INTO POD_EXTRACT
    SELECT
        X.DisableTableRow, 
        X.Code, 
        X.U_BookingDate, 
        X.U_BookingNumber, 
        X.U_PODSONum, 
        X.U_ClientName, 
        X.U_SAPClient, 
        X.U_TruckerName, 
        X.U_ISLAND, 
        X.U_ISLAND_D, 
        X.U_IFINTERISLAND, 
        X.U_VERIFICATION_TAT, 
        X.U_POD_TAT, 
        X.U_ActualDateRec_Intitial,
        X.U_SAPTrucker, 
        X.U_PlateNumber, 
        X.U_VehicleTypeCap, 
        X.U_DeliveryStatus, 
        X.U_DeliveryDateDTR, 
        X.U_DeliveryDatePOD, 
        X.U_NoOfDrops, 
        X.U_TripType, 
        X.U_Receivedby, 
        X.U_ClientReceivedDate, 
        X.U_InitialHCRecDate, 
        X.U_ActualHCRecDate,
        X.U_DateReturned, 
        X.U_PODinCharge, 
        X.U_VerifiedDateHC, 
        X.U_PTFNo, 
        X.U_DateForwardedBT, 
        X.U_BillingDeadline, 
        X.U_BillingStatus, 
        X.U_ServiceType, 
        X.U_SINo, 
        X.U_BillingTeam, 
        X.U_SOBNumber, 
        X.U_ForwardLoad, 
        X.U_BackLoad, 
        X.U_TypeOfAccessorial,
        X.U_TimeInEmptyDem, 
        X.U_TimeOutEmptyDem, 
        X.U_VerifiedEmptyDem, 
        X.U_TimeInLoadedDem, 
        X.U_TimeOutLoadedDem, 
        X.U_VerifiedLoadedDem, 
        X.U_TimeInAdvLoading, 
        X.U_PenaltiesManual, 
        X.U_DayOfTheWeek, 
        X.U_TimeIn, 
        X.U_TimeOut,
        X.U_TotalNoExceed, 
        X.U_ODOIn, 
        X.U_ODOOut, 
        X.U_TotalUsage, 
        X.U_ClientSubStatus, 
        X.U_ClientSubOverdue, 
        X.U_ClientPenaltyCalc, 
        X.U_PODStatusPayment, 
        X.U_PODSubmitDeadline, 
        X.U_OverdueDays, 
        X.U_InteluckPenaltyCalc, 
        X.U_WaivedDays,
        X.U_HolidayOrWeekend, 
        X.U_LostPenaltyCalc, 
        X.U_TotalSubPenalties, 
        X.U_Waived, 
        X.U_PercPenaltyCharge, 
        X.U_Approvedby, 
        X.U_TotalPenaltyWaived, 
        X.BillingNum, 
        X.TPNum, 
        X.PricingNum, 
        X.CDC, 
        X.DCD, 
        X.GrossTruckerRates, 
        X.U_GroupProject, 
        X.U_Attachment,
        X.U_DeliveryOrigin, 
        X.U_Destination, 
        X.U_Remarks, 
        X.U_OtherPODDoc, 
        X.U_RemarksPOD, 
        X.U_PODStatusDetail, 
        X.U_BTRemarks, 
        X.U_DestinationClient, 
        X.U_Remarks2, 
        X.U_DocNum, 
        X.U_TripTicketNo, 
        X.U_WaybillNo, 
        X.U_ShipmentNo, 
        X.U_DeliveryReceiptNo,
        X.U_SeriesNo, 
        X.U_OutletNo, 
        X.U_CBM, 
        X.U_SI_DRNo, 
        X.U_DeliveryMode, 
        X.U_SourceWhse, 
        X.U_SONo, 
        X.U_NameCustomer, 
        X.U_CategoryDR, 
        X.U_IDNumber, 
        X.U_ApprovalStatus, 
        X.U_TotalInvAmount
    FROM TMP_UPDATE_POD_EXTRACT_$serial X;


PRINT 'DROPPING TMP_UPDATE_POD_EXTRACT'

    DROP TABLE IF EXISTS TMP_UPDATE_POD_EXTRACT_$serial;


-------->>SUMMARY_EXTRACT
PRINT 'CREATING TMP_UPDATE_SUMMARY_EXTRACT'

    DROP TABLE IF EXISTS TMP_UPDATE_SUMMARY_EXTRACT_$serial
    SELECT
    --COLUMNS
    T0.Code,
    T0.U_BookingNumber,
    T0.U_BookingDate,
    T1.CardName AS U_ClientName,
    T0.U_SAPClient,
    -- T0.U_ServiceType,
    CASE
      WHEN ISNULL(T1.VatStatus,'Y') = 'Y' THEN 'VAT' ELSE 'NONVAT'
    END AS 'U_ClientVatStatus',
    T0.U_TruckerName,
    T0.U_SAPTrucker,
    CASE
       WHEN ISNULL(T2.VatStatus,'Y') = 'Y' THEN 'VAT' ELSE 'NONVAT'
    END AS 'U_TruckerVatStatus',
    T0.U_VehicleTypeCap,
    T0.U_ISLAND,
    T0.U_ISLAND_D,
    T0.U_IFINTERISLAND,
    T0.U_DeliveryStatus,
    T0.U_DeliveryDateDTR,
    T0.U_DeliveryDatePOD,
    T0.U_ClientReceivedDate,
    T0.U_ActualDateRec_Intitial,
    T0.U_InitialHCRecDate,
    T0.U_ActualHCRecDate,
    T0.U_DateReturned,
    T0.U_VerifiedDateHC,
    T0.U_PTFNo,
    T0.U_DateForwardedBT,
    (
        SELECT TOP 1
        header.DocNum
    FROM ORDR header
        LEFT JOIN RDR1 line ON line.DocEntry = header.DocEntry
    WHERE line.ItemCode = billing.U_BookingId
        AND header.CANCELED = 'N'
    ) AS U_PODSONum,
    pricing.U_GrossClientRates,
    CASE
        WHEN ISNULL(T1.VatStatus,'Y') = 'Y' THEN pricing.U_GrossClientRates
        WHEN ISNULL(T1.VatStatus,'Y') = 'N' THEN (pricing.U_GrossClientRates / 1.12)
    END AS 'U_GrossClientRatesTax',
    pricing.U_GrossTruckerRates,
    CASE
        WHEN ISNULL(T2.VatStatus,'Y') = 'Y' THEN pricing.U_GrossTruckerRates
        WHEN ISNULL(T2.VatStatus,'Y') = 'N' THEN (pricing.U_GrossTruckerRates / 1.12)
    END AS 'U_GrossTruckerRatesTax',
    (CASE
        WHEN ISNULL(T1.VatStatus,'Y') = 'Y' THEN pricing.U_GrossClientRates
        WHEN ISNULL(T1.VatStatus,'Y') = 'N' THEN (pricing.U_GrossClientRates / 1.12)
    END) - (CASE
        WHEN ISNULL(T2.VatStatus,'Y') = 'Y' THEN pricing.U_GrossTruckerRates
        WHEN ISNULL(T2.VatStatus,'Y') = 'N' THEN (pricing.U_GrossTruckerRates / 1.12)
    END) AS U_GrossProfitNet,
    CASE
        WHEN ISNULL(T1.VatStatus,'Y') = 'Y' THEN 
            (ISNULL(pricing.U_AddtlDrop, 0) + ISNULL(pricing.U_BoomTruck, 0) + ISNULL(pricing.U_Manpower, 0) + ISNULL(pricing.U_Backload, 0))
        WHEN ISNULL(T1.VatStatus,'Y') = 'N' THEN 
            ((ISNULL(pricing.U_AddtlDrop, 0) + ISNULL(pricing.U_BoomTruck, 0) + ISNULL(pricing.U_Manpower, 0) + ISNULL(pricing.U_Backload, 0)) / 1.12)
    END + CASE
        WHEN ISNULL(T1.VatStatus,'Y') = 'Y' THEN ISNULL(pricing.U_GrossClientRates, 0)
        WHEN ISNULL(T1.VatStatus,'Y') = 'N' THEN (ISNULL(pricing.U_GrossClientRates, 0) / 1.12)
    END + CASE
        WHEN ISNULL(T1.VatStatus,'Y') = 'Y' THEN ISNULL(pricing.U_Demurrage, 0)
        WHEN ISNULL(T1.VatStatus,'Y') = 'N' THEN (ISNULL(pricing.U_Demurrage, 0) / 1.12)
    END  AS U_TotalInitialClient,
    CASE
        WHEN ISNULL(T2.VatStatus,'Y') = 'Y' THEN ISNULL(pricing.U_GrossTruckerRates, 0)
        WHEN ISNULL(T2.VatStatus,'Y') = 'N' THEN (ISNULL(pricing.U_GrossTruckerRates, 0) / 1.12)
    END + CASE
        WHEN ISNULL(T2.VatStatus,'Y') = 'Y' THEN ISNULL(pricing.U_Demurrage2, 0)
        WHEN ISNULL(T2.VatStatus,'Y') = 'N' THEN (ISNULL(pricing.U_Demurrage2, 0) / 1.12)
    END + CASE
        WHEN ISNULL(T2.VatStatus,'Y') = 'Y' THEN (ISNULL(pricing.U_AddtlDrop2, 0) + ISNULL(pricing.U_BoomTruck2, 0) + ISNULL(pricing.U_Manpower2, 0) + ISNULL(pricing.U_Backload2, 0))
        WHEN ISNULL(T2.VatStatus,'Y') = 'N' THEN ((ISNULL(pricing.U_AddtlDrop2, 0) + ISNULL(pricing.U_BoomTruck2, 0) + ISNULL(pricing.U_Manpower2, 0) + ISNULL(pricing.U_Backload2, 0)) / 1.12)
    END AS U_TotalInitialTruckers,
    (CASE
        WHEN ISNULL(T1.VatStatus,'Y') = 'Y' THEN 
            (ISNULL(pricing.U_AddtlDrop, 0) + ISNULL(pricing.U_BoomTruck, 0) + ISNULL(pricing.U_Manpower, 0) + ISNULL(pricing.U_Backload, 0))
        WHEN ISNULL(T1.VatStatus,'Y') = 'N' THEN 
            ((ISNULL(pricing.U_AddtlDrop, 0) + ISNULL(pricing.U_BoomTruck, 0) + ISNULL(pricing.U_Manpower, 0) + ISNULL(pricing.U_Backload, 0)) / 1.12)
    END + CASE
        WHEN ISNULL(T1.VatStatus,'Y') = 'Y' THEN ISNULL(pricing.U_GrossClientRates, 0)
        WHEN ISNULL(T1.VatStatus,'Y') = 'N' THEN (ISNULL(pricing.U_GrossClientRates, 0) / 1.12)
    END + CASE
        WHEN ISNULL(T1.VatStatus,'Y') = 'Y' THEN ISNULL(pricing.U_Demurrage, 0)
        WHEN ISNULL(T1.VatStatus,'Y') = 'N' THEN (ISNULL(pricing.U_Demurrage, 0) / 1.12)
    END) - (CASE
        WHEN ISNULL(T2.VatStatus,'Y') = 'Y' THEN ISNULL(pricing.U_GrossTruckerRates, 0)
        WHEN ISNULL(T2.VatStatus,'Y') = 'N' THEN (ISNULL(pricing.U_GrossTruckerRates, 0) / 1.12)
    END + CASE
        WHEN ISNULL(T2.VatStatus,'Y') = 'Y' THEN ISNULL(pricing.U_Demurrage2, 0)
        WHEN ISNULL(T2.VatStatus,'Y') = 'N' THEN (ISNULL(pricing.U_Demurrage2, 0) / 1.12)
    END + CASE
        WHEN ISNULL(T2.VatStatus,'Y') = 'Y' THEN (ISNULL(pricing.U_AddtlDrop2, 0) + ISNULL(pricing.U_BoomTruck2, 0) + ISNULL(pricing.U_Manpower2, 0) + ISNULL(pricing.U_Backload2, 0))
        WHEN ISNULL(T2.VatStatus,'Y') = 'N' THEN ((ISNULL(pricing.U_AddtlDrop2, 0) + ISNULL(pricing.U_BoomTruck2, 0) + ISNULL(pricing.U_Manpower2, 0) + ISNULL(pricing.U_Backload2, 0)) / 1.12)
    END) AS U_TotalGrossProfit,
    -- pricing.U_TotalGrossProfit,
    CASE WHEN EXISTS(
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
    WHERE line.ItemCode = billing.U_BookingId
        AND header.CANCELED = 'N'
        AND header.U_BillingStatus IS NOT NULL
    ) THEN (
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
    WHERE line.ItemCode = billing.U_BookingId
        AND header.CANCELED = 'N'
        AND header.U_BillingStatus IS NOT NULL
    ) ELSE T0.U_BillingStatus END AS U_BillingStatus,
    -- CASE WHEN BE.U_BillingStatus IS NOT NULL THEN BE.U_BillingStatus
    -- ELSE T0.U_BillingStatus END AS U_BillingStatus,
    -- T0.U_SINo,
    T0.U_PODStatusPayment,
    tp.U_PaymentReference,
    tp.U_PaymentStatus,
    '' AS U_ProofOfPayment,
    billing.U_TotalRecClients,
    ISNULL(tp.U_TotalPayable, 0) AS U_TotalPayable,
    CASE 
    WHEN substring(tp.U_PVNo, 1, 2) <> ' ,'
      THEN tp.U_PVNo
    ELSE substring(tp.U_PVNo, 3, 100)
    END AS U_PVNo,
    (SELECT
        SUM(L.PriceAfVAT)
    FROM OINV H
        LEFT JOIN INV1 L ON H.DocEntry = L.DocEntry
    WHERE H.CANCELED = 'N' AND L.ItemCode = T0.U_BookingNumber) AS U_TotalAR,
    (SELECT
        SUM(L.PriceAfVAT)
    FROM OINV H
        LEFT JOIN INV1 L ON H.DocEntry = L.DocEntry
    WHERE H.CANCELED = 'N' AND L.ItemCode = T0.U_BookingNumber) - billing.U_TotalRecClients AS U_VarAR,
    TF.U_TotalAP,
    TF.U_VarTP,
    TF.U_DocNum AS U_APDocNum,
    CAST((
        SELECT DISTINCT
        SUBSTRING(
                (
                    SELECT CONCAT(', ', header.DocNum)  AS [text()]
        FROM INV1 line
            LEFT JOIN OINV header ON header.DocEntry = line.DocEntry
        WHERE line.ItemCode = T0.U_BookingNumber
            AND header.CANCELED = 'N'
        FOR XML PATH (''), TYPE
                ).value('text()[1]','nvarchar(max)'), 2, 1000) DocEntry
    FROM OINV header
        LEFT JOIN INV1 line ON line.DocEntry = header.DocEntry
    WHERE line.ItemCode = T0.U_BookingNumber
        AND header.CANCELED = 'N') as nvarchar(max)
    ) AS U_ARDocNum,
    CAST(T0.U_DeliveryOrigin as nvarchar(max)) AS U_DeliveryOrigin,
    CAST(T0.U_Destination as nvarchar(max)) AS U_Destination,
    CAST(T0.U_PODStatusDetail as nvarchar(max)) AS U_PODStatusDetail,
    CAST(T0.U_Remarks as nvarchar(max)) AS U_Remarks,
    CAST(T0.U_WaybillNo as nvarchar(max)) AS U_WaybillNo,
    CAST((
        SELECT DISTINCT
        SUBSTRING(
                (
                    SELECT CONCAT(', ', header.U_ServiceType)  AS [text()]
        FROM INV1 line
            LEFT JOIN OINV header ON header.DocEntry = line.DocEntry
        WHERE line.ItemCode = T0.U_BookingNumber
            AND header.U_ServiceType IS NOT NULL
            AND header.CANCELED = 'N'
        FOR XML PATH (''), TYPE
                ).value('text()[1]','nvarchar(max)'), 2, 1000) DocEntry
    FROM OINV header
        LEFT JOIN INV1 line ON line.DocEntry = header.DocEntry
    WHERE line.ItemCode = T0.U_BookingNumber
        AND header.U_ServiceType IS NOT NULL
        AND header.CANCELED = 'N'
        ) as nvarchar(max)
    ) AS U_ServiceType,
    CAST((
        SELECT DISTINCT
        SUBSTRING(
                (
                    SELECT
            CASE
                        WHEN header.U_InvoiceNo = '' OR header.U_InvoiceNo IS NULL THEN ''
                        ELSE CONCAT(', ', header.U_InvoiceNo)
                    END AS [text()]
        FROM INV1 line
            LEFT JOIN OINV header ON header.DocEntry = line.DocEntry
        WHERE line.ItemCode = T0.U_BookingNumber
            AND header.CANCELED = 'N'
        FOR XML PATH (''), TYPE
                ).value('text()[1]','nvarchar(max)'), 2, 1000) DocEntry
    FROM OINV header
        LEFT JOIN INV1 line ON line.DocEntry = header.DocEntry
    WHERE line.ItemCode = T0.U_BookingNumber
        AND header.CANCELED = 'N') as nvarchar(max)
    ) AS U_InvoiceNo
--COLUMNS
INTO TMP_UPDATE_SUMMARY_EXTRACT_$serial
FROM [dbo].[@PCTP_POD] T0  WITH (NOLOCK)
    --JOINS
    LEFT JOIN [dbo].[@PCTP_BILLING] billing ON T0.U_BookingNumber = billing.U_BookingId
    LEFT JOIN [dbo].[@PCTP_TP] tp ON T0.U_BookingNumber = tp.U_BookingId
    LEFT JOIN OCRD T1 ON T1.CardCode = T0.U_SAPClient
    LEFT JOIN OCRD T2 ON T2.CardCode = T0.U_SAPTrucker
    LEFT JOIN [dbo].[@PCTP_PRICING] pricing ON T0.U_BookingNumber = pricing.U_BookingId
    LEFT JOIN TP_FORMULA TF ON TF.U_BookingId = T0.U_BookingNumber
    -- LEFT JOIN BILLING_EXTRACT BE ON BE.U_BookingNumber = T0.U_BookingNumber
--JOINS
WHERE T0.U_BookingNumber IN (SELECT U_BookingNumber FROM TMP_TARGET WITH (NOLOCK));


PRINT 'DELETING TARGET BNs FROM SUMMARY_EXTRACT'

    DELETE FROM SUMMARY_EXTRACT WHERE U_BookingNumber IN (SELECT U_BookingNumber FROM TMP_TARGET WITH (NOLOCK));


PRINT 'INSERTING TARGET BNs TO SUMMARY_EXTRACT'

    INSERT INTO SUMMARY_EXTRACT
SELECT
    X.Code, X.U_BookingNumber, X.U_BookingDate, X.U_ClientName, X.U_SAPClient, X.U_ClientVatStatus, X.U_TruckerName, X.U_SAPTrucker, X.U_TruckerVatStatus, X.U_VehicleTypeCap, X.U_ISLAND, X.U_ISLAND_D, X.U_IFINTERISLAND, X.U_DeliveryStatus, X.U_DeliveryDateDTR,
    X.U_DeliveryDatePOD, X.U_ClientReceivedDate, X.U_ActualDateRec_Intitial, X.U_InitialHCRecDate, X.U_ActualHCRecDate, X.U_DateReturned, X.U_VerifiedDateHC, X.U_PTFNo, X.U_DateForwardedBT, X.U_PODSONum, X.U_GrossClientRates,
    X.U_GrossClientRatesTax, X.U_GrossTruckerRates, X.U_GrossTruckerRatesTax, X.U_GrossProfitNet, X.U_TotalInitialClient, X.U_TotalInitialTruckers, X.U_TotalGrossProfit, X.U_BillingStatus, X.U_PODStatusPayment, X.U_PaymentReference,
    X.U_PaymentStatus, X.U_ProofOfPayment, X.U_TotalRecClients, X.U_TotalPayable, X.U_PVNo, X.U_TotalAR, X.U_VarAR, X.U_TotalAP, X.U_VarTP, X.U_APDocNum, X.U_ARDocNum, X.U_DeliveryOrigin, X.U_Destination, X.U_PODStatusDetail, X.U_Remarks, X.U_WaybillNo, X.U_ServiceType,
    X.U_InvoiceNo
FROM TMP_UPDATE_SUMMARY_EXTRACT_$serial X;


PRINT 'DROPPING TMP_UPDATE_SUMMARY_EXTRACT'

    DROP TABLE IF EXISTS TMP_UPDATE_SUMMARY_EXTRACT_$serial;


-------->>PRICING_EXTRACT
PRINT 'CREATING TMP_UPDATE_PRICING_EXTRACT'

    DROP TABLE IF EXISTS TMP_UPDATE_PRICING_EXTRACT_$serial
    SELECT
    --COLUMNS
    T0.U_BookingId AS U_BookingNumber ,
    CASE
        WHEN (SELECT DISTINCT COUNT(*)
    FROM OINV H LEFT JOIN INV1 L ON H.DocEntry = L.DocEntry
    WHERE L.ItemCode = T0.U_BookingId AND H.CANCELED = 'N') > 0
        THEN 'DisableFieldsForBilling'
        ELSE ''
    END AS DisableSomeFields,
    CASE
        WHEN EXISTS(
            SELECT 1
    FROM OPCH H, PCH1 L
    WHERE H.DocEntry = L.DocEntry AND H.CANCELED = 'N'
        AND (L.ItemCode = T0.U_BookingId
        OR (REPLACE(REPLACE(RTRIM(LTRIM(tp.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(H.U_PVNo)) + '%')))
        THEN 'DisableFieldsForTp'
        ELSE ''
    END AS DisableSomeFields2,
    T0.Code,
    T0.U_BookingId,
    pod.U_BookingDate,
    -- T0.U_PODNum,
    T0.U_BookingId AS U_PODNum,
    client.CardName AS U_CustomerName,
    pod.U_SAPClient AS U_ClientTag,
    ISNULL(T1.U_GroupLocation, T0.U_ClientProject) 'U_ClientProject',
    trucker.CardName AS U_TruckerName,
    pod.U_SAPTrucker AS U_TruckerTag,
    -- T0.U_VehicleTypeCap,
    pod.U_VehicleTypeCap,
    -- T0.U_DeliveryStatus,
    pod.U_DeliveryStatus,
    T0.U_TripType,
    T0.U_NoOfDrops,
    T0.U_GrossClientRates,
    pod.U_ISLAND,
    pod.U_ISLAND_D,
    pod.U_IFINTERISLAND,
    CASE
        WHEN ISNULL(T1.VatStatus,'Y') = 'Y' THEN ISNULL(T0.U_GrossClientRates, 0)
        WHEN ISNULL(T1.VatStatus,'Y') = 'N' THEN (ISNULL(T0.U_GrossClientRates, 0) / 1.12)
    END AS 'U_GrossClientRatesTax',
    -- T0.U_GrossClientRatesTax,
    T0.U_RateBasis,
    CASE
      WHEN ISNULL(T1.VatStatus,'Y') = 'Y' THEN 'VAT' ELSE 'NONVAT'
    END AS 'U_TaxType',
    (CASE
        WHEN ISNULL(T1.VatStatus,'Y') = 'Y' THEN ISNULL(T0.U_GrossClientRates, 0)
        WHEN ISNULL(T1.VatStatus,'Y') = 'N' THEN (ISNULL(T0.U_GrossClientRates, 0) / 1.12)
    END) - (CASE
        WHEN ISNULL(T2.VatStatus,'Y') = 'Y' THEN ISNULL(T0.U_GrossTruckerRates, 0)
        WHEN ISNULL(T2.VatStatus,'Y') = 'N' THEN (ISNULL(T0.U_GrossTruckerRates, 0) / 1.12)
    END) AS U_GrossProfitNet,
    -- T0.U_GrossProfitNet,
    ISNULL(T0.U_Demurrage, 0) AS U_Demurrage,
    ISNULL(T0.U_AddtlDrop, 0) AS U_AddtlDrop,
    ISNULL(T0.U_BoomTruck, 0) AS U_BoomTruck,
    ISNULL(T0.U_Manpower, 0) AS U_Manpower,
    ISNULL(T0.U_Backload, 0) AS U_Backload,
    (ISNULL(T0.U_AddtlDrop, 0) + ISNULL(T0.U_BoomTruck, 0) + ISNULL(T0.U_Manpower, 0) + ISNULL(T0.U_Backload, 0)) AS U_TotalAddtlCharges,
    -- T0.U_TotalAddtlCharges,
    ISNULL(T0.U_Demurrage2, 0) AS U_Demurrage2,
    ISNULL(T0.U_AddtlDrop2, 0) AS U_AddtlDrop2,
    ISNULL(T0.U_BoomTruck2, 0) AS U_BoomTruck2,
    ISNULL(T0.U_Manpower2, 0) AS U_Manpower2,
    ISNULL(T0.U_Backload2, 0) AS U_Backload2,
    ISNULL(T0.U_AddtlDrop2, 0) + ISNULL(T0.U_BoomTruck2, 0) + ISNULL(T0.U_Manpower2, 0) + ISNULL(T0.U_Backload2, 0) AS U_totalAddtlCharges2,
    -- T0.U_totalAddtlCharges2,
    CASE
        WHEN ISNULL(T2.VatStatus,'Y') = 'Y' THEN ISNULL(T0.U_Demurrage2, 0)
        WHEN ISNULL(T2.VatStatus,'Y') = 'N' THEN (ISNULL(T0.U_Demurrage2, 0) / 1.12)
    END AS U_Demurrage3,
    -- T0.U_Demurrage3,
    CASE
        WHEN ISNULL(T2.VatStatus,'Y') = 'Y' THEN (ISNULL(T0.U_AddtlDrop2, 0) + ISNULL(T0.U_BoomTruck2, 0) + ISNULL(T0.U_Manpower2, 0) + ISNULL(T0.U_Backload2, 0))
        WHEN ISNULL(T2.VatStatus,'Y') = 'N' THEN ((ISNULL(T0.U_AddtlDrop2, 0) + ISNULL(T0.U_BoomTruck2, 0) + ISNULL(T0.U_Manpower2, 0) + ISNULL(T0.U_Backload2, 0)) / 1.12)
    END AS U_AddtlCharges,
    -- T0.U_AddtlCharges,
    ((CASE
        WHEN ISNULL(T1.VatStatus,'Y') = 'Y' THEN ISNULL(T0.U_Demurrage, 0)
        WHEN ISNULL(T1.VatStatus,'Y') = 'N' THEN (ISNULL(T0.U_Demurrage, 0) / 1.12)
    END) + (CASE
        WHEN ISNULL(T1.VatStatus,'Y') = 'Y' THEN 
            (ISNULL(T0.U_AddtlDrop, 0) + ISNULL(T0.U_BoomTruck, 0) + ISNULL(T0.U_Manpower, 0) + ISNULL(T0.U_Backload, 0))
        WHEN ISNULL(T1.VatStatus,'Y') = 'N' THEN 
            ((ISNULL(T0.U_AddtlDrop, 0) + ISNULL(T0.U_BoomTruck, 0) + ISNULL(T0.U_Manpower, 0) + ISNULL(T0.U_Backload, 0)) / 1.12)
    END)) - ((CASE
        WHEN ISNULL(T2.VatStatus,'Y') = 'Y' THEN ISNULL(T0.U_Demurrage2, 0)
        WHEN ISNULL(T2.VatStatus,'Y') = 'N' THEN (ISNULL(T0.U_Demurrage2, 0) / 1.12)
    END) + (CASE
        WHEN ISNULL(T2.VatStatus,'Y') = 'Y' THEN (ISNULL(T0.U_AddtlDrop2, 0) + ISNULL(T0.U_BoomTruck2, 0) + ISNULL(T0.U_Manpower2, 0) + ISNULL(T0.U_Backload2, 0))
        WHEN ISNULL(T2.VatStatus,'Y') = 'N' THEN ((ISNULL(T0.U_AddtlDrop2, 0) + ISNULL(T0.U_BoomTruck2, 0) + ISNULL(T0.U_Manpower2, 0) + ISNULL(T0.U_Backload2, 0)) / 1.12)
    END))
    AS U_GrossProfit,
    -- T0.U_GrossProfit,
    -- T0.U_TotalInitialClient,
    CASE
        WHEN ISNULL(T1.VatStatus,'Y') = 'Y' THEN 
            (ISNULL(T0.U_AddtlDrop, 0) + ISNULL(T0.U_BoomTruck, 0) + ISNULL(T0.U_Manpower, 0) + ISNULL(T0.U_Backload, 0))
        WHEN ISNULL(T1.VatStatus,'Y') = 'N' THEN 
            ((ISNULL(T0.U_AddtlDrop, 0) + ISNULL(T0.U_BoomTruck, 0) + ISNULL(T0.U_Manpower, 0) + ISNULL(T0.U_Backload, 0)) / 1.12)
    END + CASE
        WHEN ISNULL(T1.VatStatus,'Y') = 'Y' THEN ISNULL(T0.U_GrossClientRates, 0)
        WHEN ISNULL(T1.VatStatus,'Y') = 'N' THEN (ISNULL(T0.U_GrossClientRates, 0) / 1.12)
    END + CASE
        WHEN ISNULL(T1.VatStatus,'Y') = 'Y' THEN ISNULL(T0.U_Demurrage, 0)
        WHEN ISNULL(T1.VatStatus,'Y') = 'N' THEN (ISNULL(T0.U_Demurrage, 0) / 1.12)
    END  AS U_TotalInitialClient,
    CASE
        WHEN ISNULL(T2.VatStatus,'Y') = 'Y' THEN ISNULL(T0.U_GrossTruckerRates, 0)
        WHEN ISNULL(T2.VatStatus,'Y') = 'N' THEN (ISNULL(T0.U_GrossTruckerRates, 0) / 1.12)
    END + CASE
        WHEN ISNULL(T2.VatStatus,'Y') = 'Y' THEN ISNULL(T0.U_Demurrage2, 0)
        WHEN ISNULL(T2.VatStatus,'Y') = 'N' THEN (ISNULL(T0.U_Demurrage2, 0) / 1.12)
    END + CASE
        WHEN ISNULL(T2.VatStatus,'Y') = 'Y' THEN (ISNULL(T0.U_AddtlDrop2, 0) + ISNULL(T0.U_BoomTruck2, 0) + ISNULL(T0.U_Manpower2, 0) + ISNULL(T0.U_Backload2, 0))
        WHEN ISNULL(T2.VatStatus,'Y') = 'N' THEN ((ISNULL(T0.U_AddtlDrop2, 0) + ISNULL(T0.U_BoomTruck2, 0) + ISNULL(T0.U_Manpower2, 0) + ISNULL(T0.U_Backload2, 0)) / 1.12)
    END AS U_TotalInitialTruckers,
    -- T0.U_TotalInitialTruckers,
    (CASE
        WHEN ISNULL(T1.VatStatus,'Y') = 'Y' THEN 
            (ISNULL(T0.U_AddtlDrop, 0) + ISNULL(T0.U_BoomTruck, 0) + ISNULL(T0.U_Manpower, 0) + ISNULL(T0.U_Backload, 0))
        WHEN ISNULL(T1.VatStatus,'Y') = 'N' THEN 
            ((ISNULL(T0.U_AddtlDrop, 0) + ISNULL(T0.U_BoomTruck, 0) + ISNULL(T0.U_Manpower, 0) + ISNULL(T0.U_Backload, 0)) / 1.12)
    END + CASE
        WHEN ISNULL(T1.VatStatus,'Y') = 'Y' THEN ISNULL(T0.U_GrossClientRates, 0)
        WHEN ISNULL(T1.VatStatus,'Y') = 'N' THEN (ISNULL(T0.U_GrossClientRates, 0) / 1.12)
    END + CASE
        WHEN ISNULL(T1.VatStatus,'Y') = 'Y' THEN ISNULL(T0.U_Demurrage, 0)
        WHEN ISNULL(T1.VatStatus,'Y') = 'N' THEN (ISNULL(T0.U_Demurrage, 0) / 1.12)
    END) - (CASE
        WHEN ISNULL(T2.VatStatus,'Y') = 'Y' THEN ISNULL(T0.U_GrossTruckerRates, 0)
        WHEN ISNULL(T2.VatStatus,'Y') = 'N' THEN (ISNULL(T0.U_GrossTruckerRates, 0) / 1.12)
    END + CASE
        WHEN ISNULL(T2.VatStatus,'Y') = 'Y' THEN ISNULL(T0.U_Demurrage2, 0)
        WHEN ISNULL(T2.VatStatus,'Y') = 'N' THEN (ISNULL(T0.U_Demurrage2, 0) / 1.12)
    END + CASE
        WHEN ISNULL(T2.VatStatus,'Y') = 'Y' THEN (ISNULL(T0.U_AddtlDrop2, 0) + ISNULL(T0.U_BoomTruck2, 0) + ISNULL(T0.U_Manpower2, 0) + ISNULL(T0.U_Backload2, 0))
        WHEN ISNULL(T2.VatStatus,'Y') = 'N' THEN ((ISNULL(T0.U_AddtlDrop2, 0) + ISNULL(T0.U_BoomTruck2, 0) + ISNULL(T0.U_Manpower2, 0) + ISNULL(T0.U_Backload2, 0)) / 1.12)
    END) AS U_TotalGrossProfit,
    -- T0.U_TotalGrossProfit,
    T0.U_ClientTag2,
    ISNULL(T0.U_GrossTruckerRates, 0) AS U_GrossTruckerRates,
    CASE
        WHEN ISNULL(T2.VatStatus,'Y') = 'Y' THEN ISNULL(T0.U_GrossTruckerRates, 0)
        WHEN ISNULL(T2.VatStatus,'Y') = 'N' THEN (ISNULL(T0.U_GrossTruckerRates, 0) / 1.12)
    END AS 'U_GrossTruckerRatesTax',
    -- T0.U_GrossTruckerRatesTax,
    T0.U_RateBasisT,
    CASE
       WHEN ISNULL(T2.VatStatus,'Y') = 'Y' THEN 'VAT' ELSE 'NONVAT'
    END AS 'U_TaxTypeT',
    CASE
        WHEN ISNULL(T1.VatStatus,'Y') = 'Y' THEN ISNULL(T0.U_Demurrage, 0)
        WHEN ISNULL(T1.VatStatus,'Y') = 'N' THEN (ISNULL(T0.U_Demurrage, 0) / 1.12)
    END AS 'U_Demurrage4',
    -- T0.U_Demurrage4,
    -- T0.U_AddtlCharges2,
    CASE
        WHEN ISNULL(T1.VatStatus,'Y') = 'Y' THEN 
            (ISNULL(T0.U_AddtlDrop, 0) + ISNULL(T0.U_BoomTruck, 0) + ISNULL(T0.U_Manpower, 0) + ISNULL(T0.U_Backload, 0))
        WHEN ISNULL(T1.VatStatus,'Y') = 'N' THEN 
            ((ISNULL(T0.U_AddtlDrop, 0) + ISNULL(T0.U_BoomTruck, 0) + ISNULL(T0.U_Manpower, 0) + ISNULL(T0.U_Backload, 0)) / 1.12)
    END AS U_AddtlCharges2,
    T0.U_GrossProfitC,
    billing.Code 'BillingNum',
    tp.Code 'TPNum',
    billing.U_ActualBilledRate,
    billing.U_RateAdjustments AS U_BillingRateAdjustments,
    billing.U_ActualDemurrage AS U_BillingActualDemurrage,
    billing.U_ActualAddCharges,
    billing.U_TotalRecClients,
    (SELECT
        SUM(L.PriceAfVAT)
    FROM OINV H
        LEFT JOIN INV1 L ON H.DocEntry = L.DocEntry
    WHERE H.CANCELED = 'N' AND L.ItemCode = T0.U_BookingId) AS U_TotalAR,
    (SELECT
        SUM(L.PriceAfVAT)
    FROM OINV H
        LEFT JOIN INV1 L ON H.DocEntry = L.DocEntry
    WHERE H.CANCELED = 'N' AND L.ItemCode = T0.U_BookingId) - billing.U_TotalRecClients AS U_VarAR,
    (
        SELECT TOP 1
        header.DocNum
    FROM ORDR header
        LEFT JOIN RDR1 line ON line.DocEntry = header.DocEntry
    WHERE line.ItemCode = billing.U_BookingId
        AND header.CANCELED = 'N'
    ) AS U_PODSONum,
    ISNULL(tp.U_ActualRates, 0) AS U_ActualRates,
    ISNULL(tp.U_RateAdjustments, 0) AS U_TPRateAdjustments,
    ISNULL(tp.U_ActualDemurrage, 0) AS U_TPActualDemurrage,
    ISNULL(tp.U_ActualCharges, 0) AS U_ActualCharges,
    ISNULL(tp.U_BoomTruck2, 0) AS U_TPBoomTruck2,
    ISNULL(tp.U_OtherCharges, 0) AS U_OtherCharges,
    ISNULL(tp.U_TotalPayable, 0) AS U_TotalPayable,
    CASE 
    WHEN substring(tp.U_PVNo, 1, 2) <> ' ,'
      THEN tp.U_PVNo
    ELSE substring(tp.U_PVNo, 3, 100)
    END AS U_PVNo,
    TF.U_TotalAP,
    TF.U_VarTP,
    TF.U_DocNum AS U_APDocNum,
    TF.U_Paid,
    CAST((
        SELECT DISTINCT
        SUBSTRING(
                (
                    SELECT CONCAT(', ', header.DocNum)  AS [text()]
        FROM INV1 line
            LEFT JOIN OINV header ON header.DocEntry = line.DocEntry
        WHERE line.ItemCode = T0.U_BookingId
            AND header.CANCELED = 'N'
        FOR XML PATH (''), TYPE
                ).value('text()[1]','nvarchar(max)'), 2, 1000) DocEntry
    FROM OINV header
        LEFT JOIN INV1 line ON line.DocEntry = header.DocEntry
    WHERE line.ItemCode = T0.U_BookingId
        AND header.CANCELED = 'N') as nvarchar(max)
    ) AS U_DocNum,
    CAST(pod.U_DeliveryOrigin as nvarchar(max)) AS U_DeliveryOrigin,
    CAST(pod.U_Destination as nvarchar(max)) AS U_Destination,
    CAST(T0.U_RemarksDTR as nvarchar(max)) AS U_RemarksDTR,
    CAST(T0.U_RemarksPOD as nvarchar(max)) AS U_RemarksPOD,
    CAST(pod.U_DocNum as nvarchar(max)) AS U_PODDocNum
--COLUMNS

INTO TMP_UPDATE_PRICING_EXTRACT_$serial

FROM [dbo].[@PCTP_PRICING] T0  WITH (NOLOCK)


    LEFT JOIN [dbo].[@PCTP_POD] pod ON T0.U_BookingId = pod.U_BookingNumber
    --JOINS
    LEFT JOIN [dbo].[@PCTP_BILLING] billing ON T0.U_BookingId = billing.U_BookingId
    LEFT JOIN [dbo].[@PCTP_TP] tp ON T0.U_BookingId = tp.U_BookingId



    LEFT JOIN OCRD T1 ON T1.CardCode = pod.U_SAPClient
    LEFT JOIN OCRD T2 ON T2.CardCode = pod.U_SAPTrucker


    LEFT JOIN OCRD client ON pod.U_SAPClient = client.CardCode
    LEFT JOIN OCRD trucker ON pod.U_SAPTrucker = trucker.CardCode
    LEFT JOIN TP_FORMULA TF ON TF.U_BookingId = T0.U_BookingId
--JOINS
WHERE T0.U_BookingId IN (SELECT U_BookingNumber FROM TMP_TARGET WITH (NOLOCK));


PRINT 'DELETING TARGET BNs FROM PRICING_EXTRACT'

    DELETE FROM PRICING_EXTRACT WHERE U_BookingNumber IN (SELECT U_BookingNumber FROM TMP_TARGET WITH (NOLOCK));


PRINT 'INSERTING TARGET BNs TO PRICING_EXTRACT'

    INSERT INTO PRICING_EXTRACT
SELECT
    X.U_BookingNumber, X.DisableSomeFields, X.DisableSomeFields2, X.Code, X.U_BookingId, X.U_BookingDate, X.U_PODNum, X.U_CustomerName, X.U_ClientTag, X.U_ClientProject, X.U_TruckerName, X.U_TruckerTag, X.U_VehicleTypeCap, X.U_DeliveryStatus,
    X.U_TripType, X.U_NoOfDrops, X.U_GrossClientRates, X.U_ISLAND, X.U_ISLAND_D, X.U_IFINTERISLAND, X.U_GrossClientRatesTax, X.U_RateBasis, X.U_TaxType, X.U_GrossProfitNet, X.U_Demurrage, X.U_AddtlDrop, X.U_BoomTruck, X.U_Manpower, X.U_Backload,
    X.U_TotalAddtlCharges, X.U_Demurrage2, X.U_AddtlDrop2, X.U_BoomTruck2, X.U_Manpower2, X.U_Backload2, X.U_totalAddtlCharges2, X.U_Demurrage3, X.U_AddtlCharges, X.U_GrossProfit, X.U_TotalInitialClient, X.U_TotalInitialTruckers, X.U_TotalGrossProfit,
    X.U_ClientTag2, X.U_GrossTruckerRates, X.U_GrossTruckerRatesTax, X.U_RateBasisT, X.U_TaxTypeT, X.U_Demurrage4, X.U_AddtlCharges2, X.U_GrossProfitC, X.BillingNum, X.TPNum, X.U_ActualBilledRate, X.U_BillingRateAdjustments,
    X.U_BillingActualDemurrage, X.U_ActualAddCharges, X.U_TotalRecClients, X.U_TotalAR, X.U_VarAR, X.U_PODSONum, X.U_ActualRates, X.U_TPRateAdjustments, X.U_TPActualDemurrage, X.U_ActualCharges, X.U_TPBoomTruck2, X.U_OtherCharges,
    X.U_TotalPayable, X.U_PVNo, X.U_TotalAP, X.U_VarTP, X.U_APDocNum, X.U_Paid, X.U_DocNum, X.U_DeliveryOrigin, X.U_Destination, X.U_RemarksDTR, X.U_RemarksPOD, X.U_PODDocNum
FROM TMP_UPDATE_PRICING_EXTRACT_$serial X;


PRINT 'DROPPING TMP_UPDATE_PRICING_EXTRACT'

    DROP TABLE IF EXISTS TMP_UPDATE_PRICING_EXTRACT_$serial;


DROP TABLE IF EXISTS TMP_TARGET;
