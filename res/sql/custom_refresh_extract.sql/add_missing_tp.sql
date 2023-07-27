PRINT 'BEFORE TRY'
BEGIN TRY
    BEGIN TRAN
    PRINT 'First Statement in the TRY block'

    DROP TABLE IF EXISTS TMP_NEW_TP_EXTRACT_202307141207PM
    SELECT
        U_BookingNumber
    INTO TMP_NEW_TP_EXTRACT_202307141207PM
    FROM [@PCTP_POD] WITH (NOLOCK)
    WHERE U_BookingNumber NOT IN (SELECT U_BookingNumber
    FROM TP_EXTRACT WITH (NOLOCK))
    AND CAST(U_PODStatusDetail as nvarchar(max)) LIKE '%Verified%'
    
    UPDATE [@FirstratesTP] 
    SET U_Amount = NULL
    WHERE U_Amount = 'NaN' AND U_BN IN (SELECT U_BookingNumber
    FROM TMP_NEW_TP_EXTRACT_202307141207PM WITH (NOLOCK))

    UPDATE [@FirstratesTP] 
    SET U_AddlAmount = NULL
    WHERE U_AddlAmount = 'NaN' AND U_BN IN (SELECT U_BookingNumber
    FROM TMP_NEW_TP_EXTRACT_202307141207PM WITH (NOLOCK))

    DROP TABLE IF EXISTS TMP_UPDATE_TP_FORMULA_202307141207PM
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

    INTO TMP_UPDATE_TP_FORMULA_202307141207PM

    FROM [dbo].[@PCTP_TP] T0 WITH (NOLOCK)
        RIGHT JOIN [dbo].[@PCTP_POD] pod ON T0.U_BookingId = pod.U_BookingNumber AND CAST(pod.U_PODStatusDetail as nvarchar(max)) LIKE '%Verified%'
        LEFT JOIN OCRD T4 ON pod.U_SAPClient = T4.CardCode
        LEFT JOIN [dbo].[@PCTP_PRICING] pricing ON T0.U_BookingId = pricing.U_BookingId
        LEFT JOIN OCRD trucker ON pod.U_SAPTrucker = trucker.CardCode
    WHERE T0.U_BookingId IN (SELECT U_BookingNumber
    FROM TMP_NEW_TP_EXTRACT_202307141207PM WITH (NOLOCK))

    DELETE FROM TP_FORMULA WHERE U_BookingId IN (SELECT U_BookingNumber
    FROM TMP_NEW_TP_EXTRACT_202307141207PM WITH (NOLOCK))

    INSERT INTO TP_FORMULA
    SELECT
        *
    FROM TMP_UPDATE_TP_FORMULA_202307141207PM

    DROP TABLE IF EXISTS TMP_UPDATE_TP_FORMULA_202307141207PM

    DROP TABLE IF EXISTS TMP_UPDATE_TP_EXTRACT_202307141207PM
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
    billing.U_PODSONum AS U_PODSONum,
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

    T0.U_ORRefNo,
    T0.U_ActualPaymentDate,
    T0.U_PaymentReference,
    T0.U_PaymentStatus,
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
    CAST(pod.U_SeriesNo as nvarchar(max)) AS U_SeriesNo






--COLUMNS

INTO TMP_UPDATE_TP_EXTRACT_202307141207PM

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
    WHERE T0.U_BookingId IN (SELECT U_BookingNumber
    FROM TMP_NEW_TP_EXTRACT_202307141207PM WITH (NOLOCK))

    DELETE FROM TP_EXTRACT WHERE U_BookingNumber IN (SELECT U_BookingNumber
    FROM TMP_NEW_TP_EXTRACT_202307141207PM WITH (NOLOCK))

    INSERT INTO TP_EXTRACT
    SELECT
        *
    FROM TMP_UPDATE_TP_EXTRACT_202307141207PM

    DROP TABLE IF EXISTS TMP_UPDATE_TP_EXTRACT_202307141207PM
    DROP TABLE IF EXISTS TMP_NEW_TP_EXTRACT_202307141207PM    

    PRINT 'Last Statement in the TRY block'
    COMMIT TRAN
END TRY
BEGIN CATCH
    PRINT 'In CATCH Block'
    IF(@@TRANCOUNT > 0)
        ROLLBACK TRAN;

    THROW; -- raise error to the client
END CATCH
PRINT 'After END CATCH'