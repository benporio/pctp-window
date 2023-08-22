IF (OBJECT_ID('fetchDataRow') IS NOT NULL)
    DROP PROCEDURE [dbo].fetchDataRow
GO

CREATE PROCEDURE [dbo].fetchDataRow   
    @TabName nvarchar(20),   
    @BookingIds nvarchar(max),   
    @AccessColumns nvarchar(30) = 'ALL'  
AS

SET NOCOUNT ON;  

--BOOKING IDS
DECLARE @BookingIdList TABLE(item nvarchar(max));
INSERT INTO @BookingIdList
SELECT 
RTRIM(LTRIM(value)) AS item
FROM STRING_SPLIT(@BookingIds, ',');

--ACCESS COLUMNS
DECLARE @AccessColumnList TABLE(item nvarchar(max));
INSERT INTO @AccessColumnList
SELECT 
RTRIM(LTRIM(value)) AS item
FROM STRING_SPLIT(@AccessColumns, ',');

WITH LOCAL_TP_FORMULA(
    U_BookingNumber, 
    DisableTableRow, 
    DisableSomeFields, 
    U_TotalAP,
    U_VarTP,
    U_DocNum,
    U_Paid,
    U_LostPenaltyCalc,
    U_TotalSubPenalty,
    U_TotalPenaltyWaived,
    U_InteluckPenaltyCalc,
    U_ClientSubOverdue,
    U_ClientPenaltyCalc
) AS (
    SELECT
        T0.U_BookingId AS U_BookingNumber,
        CASE
            WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'DisableTableRow') THEN
                CASE
                    WHEN @TabName = 'TP' THEN
                        CASE
                            WHEN (
                                SELECT DISTINCT COUNT(*)
                        FROM OPCH H LEFT JOIN PCH1 L ON H.DocEntry = L.DocEntry
                        WHERE H.CANCELED = 'N'
                            AND (L.ItemCode = T0.U_BookingId OR REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(H.U_PVNo)) + '%')
                            ) > 1
                            THEN 'Y'
                            ELSE 'N'
                        END
                    ELSE NULL
                END
            ELSE NULL
        END AS DisableTableRow,
        CASE
            WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'DisableSomeFields') THEN
                CASE
                    WHEN @TabName = 'TP' THEN
                        CASE
                            WHEN (
                                SELECT DISTINCT COUNT(*)
                        FROM OPCH H LEFT JOIN PCH1 L ON H.DocEntry = L.DocEntry
                        WHERE H.CANCELED = 'N'
                            AND (L.ItemCode = T0.U_BookingId) OR (REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(H.U_PVNo)) + '%')
                            ) = 1
                            THEN 'DisableSomeFields'
                            ELSE ''
                        END
                    ELSE NULL
                END
            ELSE NULL
        END AS DisableSomeFields,
        CASE
            WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_TotalAP') THEN
                CASE
                    WHEN @TabName = 'SUMMARY' OR @TabName = 'TP' OR @TabName = 'PRICING' THEN
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
                        END
                    ELSE NULL
                END
            ELSE NULL
        END AS U_TotalAP,
        CASE
            WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_VarTP') THEN
                CASE
                    WHEN @TabName = 'SUMMARY' OR @TabName = 'TP' OR @TabName = 'PRICING' THEN
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
                        END - (T0.U_TotalPayable + T0.U_CAandDP + T0.U_Interest)
                    ELSE NULL
                END
            ELSE NULL
        END AS U_VarTP,
        CASE
            WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_DocNum') THEN
                CASE
                    WHEN @TabName = 'SUMMARY' OR @TabName = 'TP' OR @TabName = 'PRICING' THEN
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
                            or REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%'))
                        as nvarchar(max))
                    ELSE NULL
                END
            ELSE NULL
        END AS U_DocNum,
        CASE
            WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_Paid') THEN
                CASE
                    WHEN @TabName = 'SUMMARY' OR @TabName = 'TP' THEN 
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
                            or REPLACE(REPLACE(RTRIM(LTRIM(T0.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%'))
                        as nvarchar(max))
                    ELSE NULL
                END
            ELSE NULL
        END As U_Paid,
        CASE
            WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_LostPenaltyCalc') THEN
                CASE
                    WHEN @TabName = 'TP' OR @TabName = 'POD' THEN
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
                        )
                    ELSE NULL
                END
            ELSE NULL
        END AS U_LostPenaltyCalc,
        CASE
            WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_TotalSubPenalty') THEN
                CASE
                    WHEN @TabName = 'SUMMARY' OR @TabName = 'TP' OR @TabName = 'PRICING' THEN
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
                        )), 0)
                    ELSE NULL
                END
            ELSE NULL
        END AS U_TotalSubPenalty,
        CASE
            WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_TotalPenaltyWaived') THEN
                CASE
                    WHEN @TabName = 'SUMMARY' OR @TabName = 'POD' OR @TabName = 'TP' OR @TabName = 'PRICING' THEN
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
                        )
                    ELSE NULL
                END
            ELSE NULL
        END AS U_TotalPenaltyWaived,
        CASE
            WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_InteluckPenaltyCalc') THEN
                CASE
                    WHEN @TabName = 'TP' OR @TabName = 'POD' THEN
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
                        )
                    ELSE NULL
                END
            ELSE NULL
        END AS U_InteluckPenaltyCalc,
        CASE
            WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_ClientSubOverdue') THEN
                CASE
                    WHEN @TabName = 'TP' OR @TabName = 'POD' THEN
                        dbo.computeClientSubOverdue(
                            pod.U_DeliveryDateDTR,
                            pod.U_ClientReceivedDate,
                            ISNULL(pod.U_WaivedDays, 0),
                            CAST(ISNULL(T4.U_DCD,0) as int)
                        )
                    ELSE NULL
                END
            ELSE NULL
        END AS U_ClientSubOverdue,
        CASE
            WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_ClientPenaltyCalc') THEN
                CASE
                    WHEN @TabName = 'TP' OR @TabName = 'POD' THEN
                        dbo.computeClientPenaltyCalc(
                            dbo.computeClientSubOverdue(
                                pod.U_DeliveryDateDTR,
                                pod.U_ClientReceivedDate,
                                ISNULL(pod.U_WaivedDays, 0),
                                CAST(ISNULL(T4.U_DCD,0) as int)
                            )
                        )
                    ELSE NULL
                END
            ELSE NULL
        END AS U_ClientPenaltyCalc
    FROM [dbo].[@PCTP_TP] T0 WITH (NOLOCK)
    INNER JOIN [dbo].[@PCTP_POD] pod ON T0.U_BookingId = pod.U_BookingNumber AND CAST(pod.U_PODStatusDetail as nvarchar(max)) LIKE '%Verified%'
    LEFT JOIN OCRD T4 ON pod.U_SAPClient = T4.CardCode
    LEFT JOIN [dbo].[@PCTP_PRICING] pricing ON T0.U_BookingId = pricing.U_BookingId
    LEFT JOIN OCRD trucker ON pod.U_SAPTrucker = trucker.CardCode
    WHERE T0.U_BookingId IN (SELECT item FROM @BookingIdList) 
)

--->MAIN_QUERY

SELECT
    --COLUMNS
    CASE
        WHEN @TabName = 'SUMMARY' THEN CAST(POD.Code AS nvarchar(max))
        WHEN @TabName = 'POD' THEN POD.U_BookingNumber
        WHEN @TabName = 'BILLING' THEN CAST(BILLING.Code AS nvarchar(max))
        WHEN @TabName = 'TP' THEN CAST(TP.Code AS nvarchar(max))
        WHEN @TabName = 'PRICING' THEN CAST(PRICING.Code AS nvarchar(max))
        ELSE NULL
    END As Code,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'DisableTableRow') THEN
            CASE
                WHEN @TabName = 'POD' THEN 
                    CASE
                        WHEN EXISTS(SELECT 1
                        FROM OINV H, INV1 L
                        WHERE H.DocEntry = L.DocEntry AND L.ItemCode = POD.U_BookingNumber AND H.CANCELED = 'N')
                        AND EXISTS(
                                SELECT 1
                        FROM OPCH H, PCH1 L
                        WHERE H.DocEntry = L.DocEntry AND H.CANCELED = 'N'
                            AND (L.ItemCode = POD.U_BookingNumber
                            OR (REPLACE(REPLACE(RTRIM(LTRIM(TP.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(H.U_PVNo)) + '%')))
                        THEN 'Y'
                        ELSE 'N'
                    END
                WHEN @TabName = 'BILLING' THEN 
                    CASE
                        WHEN (SELECT DISTINCT COUNT(*)
                    FROM OINV H LEFT JOIN INV1 L ON H.DocEntry = L.DocEntry
                    WHERE L.ItemCode = BILLING.U_BookingId AND H.CANCELED = 'N') > 1
                        THEN 'Y'
                        ELSE 'N'
                    END
                WHEN @TabName = 'TP' THEN TF.DisableTableRow
                ELSE 'N'
            END
        ELSE NULL
    END As DisableTableRow,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'DisableSomeFields') THEN
            CASE
                WHEN @TabName = 'BILLING' THEN 
                    CASE
                        WHEN (SELECT DISTINCT COUNT(*)
                    FROM OINV H LEFT JOIN INV1 L ON H.DocEntry = L.DocEntry
                    WHERE L.ItemCode = BILLING.U_BookingId AND H.CANCELED = 'N') = 1
                        THEN 'DisableSomeFields'
                        ELSE ''
                    END
                WHEN @TabName = 'TP' THEN TF.DisableSomeFields
                WHEN @TabName = 'PRICING' THEN 
                    CASE
                        WHEN (SELECT DISTINCT COUNT(*)
                    FROM OINV H LEFT JOIN INV1 L ON H.DocEntry = L.DocEntry
                    WHERE L.ItemCode = PRICING.U_BookingId AND H.CANCELED = 'N') > 0
                        THEN 'DisableFieldsForBilling'
                        ELSE ''
                    END
                ELSE ''
            END
        ELSE NULL
    END AS DisableSomeFields,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'DisableSomeFields2') THEN
            CASE
                WHEN @TabName = 'PRICING' THEN 
                    CASE
                        WHEN EXISTS(
                            SELECT 1
                    FROM OPCH H, PCH1 L
                    WHERE H.DocEntry = L.DocEntry AND H.CANCELED = 'N'
                        AND (L.ItemCode = PRICING.U_BookingId
                        OR (REPLACE(REPLACE(RTRIM(LTRIM(tp.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(H.U_PVNo)) + '%')))
                        THEN 'DisableFieldsForTp'
                        ELSE ''
                    END
                ELSE ''
            END
        ELSE NULL
    END AS DisableSomeFields2,
    POD.U_BookingDate,
    CASE
        WHEN @TabName = 'SUMMARY' THEN POD.U_BookingNumber
        WHEN @TabName = 'POD' THEN POD.U_BookingNumber
        WHEN @TabName = 'BILLING' THEN BILLING.U_BookingId
        WHEN @TabName = 'TP' THEN TP.U_BookingId
        WHEN @TabName = 'PRICING' THEN PRICING.U_BookingId
        ELSE NULL
    END AS U_BookingNumber,
    CASE
        WHEN @TabName = 'SUMMARY' THEN POD.U_BookingNumber
        WHEN @TabName = 'POD' THEN POD.U_BookingNumber
        WHEN @TabName = 'BILLING' THEN BILLING.U_BookingId
        WHEN @TabName = 'TP' THEN TP.U_BookingId
        WHEN @TabName = 'PRICING' THEN PRICING.U_BookingId
        ELSE NULL
    END AS U_BookingId,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_PODNum') THEN
            CASE
                WHEN @TabName = 'BILLING' THEN BILLING.U_BookingId
                WHEN @TabName = 'TP' THEN TP.U_BookingId
                WHEN @TabName = 'PRICING' THEN PRICING.U_BookingId
                ELSE NULL
            END
        ELSE NULL
    END AS U_PODNum,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_PODSONum') THEN
            (
                SELECT TOP 1
                header.DocNum
            FROM ORDR header
                LEFT JOIN RDR1 line ON line.DocEntry = header.DocEntry
            WHERE line.ItemCode = BILLING.U_BookingId
                AND header.CANCELED = 'N'
            )
        ELSE NULL
    END AS U_PODSONum,
    client.CardName AS U_CustomerName,
    PRICING.U_GrossClientRates,
    PRICING.U_GrossClientRates AS U_GrossInitialRate,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_Demurrage') THEN
            CASE
                WHEN @TabName = 'TP' THEN ISNULL(PRICING.U_Demurrage2, 0)
                WHEN @TabName = 'BILLING' OR @TabName = 'PRICING' THEN ISNULL(PRICING.U_Demurrage, 0)
                ELSE NULL
            END
        ELSE NULL
    END AS U_Demurrage,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_AddtlDrop') THEN
            CASE
                WHEN @TabName = 'TP' THEN ISNULL(PRICING.U_AddtlDrop2, 0)
                WHEN @TabName = 'PRICING' THEN ISNULL(PRICING.U_AddtlDrop, 0)
                ELSE NULL
            END
        ELSE NULL
    END AS U_AddtlDrop,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_BoomTruck') THEN
            CASE
                WHEN @TabName = 'TP' THEN ISNULL(PRICING.U_BoomTruck2, 0)
                WHEN @TabName = 'PRICING' THEN ISNULL(PRICING.U_BoomTruck, 0)
                ELSE NULL
            END
        ELSE NULL
    END AS U_BoomTruck,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_BoomTruck2') THEN
            CASE
                WHEN @TabName = 'TP' OR @TabName = 'PRICING' THEN ISNULL(TP.U_BoomTruck2, 0)
                ELSE NULL
            END
        ELSE NULL
    END AS U_BoomTruck2,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_Manpower') THEN
            CASE
                WHEN @TabName = 'TP' THEN ISNULL(PRICING.U_Manpower2, 0)
                WHEN @TabName = 'PRICING' THEN ISNULL(PRICING.U_Manpower, 0)
                ELSE NULL
            END
        ELSE NULL
    END AS U_Manpower,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_BackLoad') THEN
            CASE
                WHEN @TabName = 'TP' THEN ISNULL(PRICING.U_Backload2, 0)
                WHEN @TabName = 'PRICING' THEN ISNULL(PRICING.U_Backload, 0)
                ELSE NULL
            END
        ELSE NULL
    END AS U_BackLoad,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_TotalAddtlCharges') THEN
            CASE
                WHEN @TabName = 'PRICING' THEN 
                    (ISNULL(PRICING.U_AddtlDrop, 0) + ISNULL(PRICING.U_BoomTruck, 0) + ISNULL(PRICING.U_Manpower, 0) + ISNULL(PRICING.U_Backload, 0))
                ELSE NULL
            END
        ELSE NULL
    END AS U_TotalAddtlCharges,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_Demurrage2') THEN
            CASE
                WHEN @TabName = 'PRICING' THEN ISNULL(PRICING.U_Demurrage2, 0)
                ELSE NULL
            END
        ELSE NULL
    END AS U_Demurrage2,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_AddtlDrop2') THEN
            CASE
                WHEN @TabName = 'PRICING' THEN ISNULL(PRICING.U_AddtlDrop2, 0)
                ELSE NULL
            END
        ELSE NULL
    END AS U_AddtlDrop2,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_BoomTruck2') THEN
            CASE
                WHEN @TabName = 'PRICING' THEN ISNULL(PRICING.U_BoomTruck2, 0)
                ELSE NULL
            END
        ELSE NULL
    END AS U_BoomTruck2,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_Manpower2') THEN
            CASE
                WHEN @TabName = 'PRICING' THEN ISNULL(PRICING.U_Manpower2, 0)
                ELSE NULL
            END
        ELSE NULL
    END AS U_Manpower2,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_Backload2') THEN
            CASE
                WHEN @TabName = 'PRICING' THEN ISNULL(PRICING.U_Backload2, 0)
                ELSE NULL
            END
        ELSE NULL
    END AS U_Backload2,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_totalAddtlCharges2') THEN
            CASE
                WHEN @TabName = 'PRICING' THEN 
                    ISNULL(PRICING.U_AddtlDrop2, 0) + ISNULL(PRICING.U_BoomTruck2, 0) + ISNULL(PRICING.U_Manpower2, 0) + ISNULL(PRICING.U_Backload2, 0)
                ELSE NULL
            END
        ELSE NULL
    END AS U_totalAddtlCharges2,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_Demurrage3') THEN
            CASE
                WHEN @TabName = 'PRICING' THEN 
                    CASE
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN ISNULL(PRICING.U_Demurrage2, 0)
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN (ISNULL(PRICING.U_Demurrage2, 0) / 1.12)
                    END
                ELSE NULL
            END
        ELSE NULL
    END AS U_Demurrage3,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_GrossProfit') THEN
            CASE
                WHEN @TabName = 'PRICING' THEN 
                    ((CASE
                        WHEN ISNULL(client.VatStatus,'Y') = 'Y' THEN ISNULL(PRICING.U_Demurrage, 0)
                        WHEN ISNULL(client.VatStatus,'Y') = 'N' THEN (ISNULL(PRICING.U_Demurrage, 0) / 1.12)
                    END) + (CASE
                        WHEN ISNULL(client.VatStatus,'Y') = 'Y' THEN 
                            (ISNULL(PRICING.U_AddtlDrop, 0) + ISNULL(PRICING.U_BoomTruck, 0) + ISNULL(PRICING.U_Manpower, 0) + ISNULL(PRICING.U_Backload, 0))
                        WHEN ISNULL(client.VatStatus,'Y') = 'N' THEN 
                            ((ISNULL(PRICING.U_AddtlDrop, 0) + ISNULL(PRICING.U_BoomTruck, 0) + ISNULL(PRICING.U_Manpower, 0) + ISNULL(PRICING.U_Backload, 0)) / 1.12)
                    END)) - ((CASE
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN ISNULL(PRICING.U_Demurrage2, 0)
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN (ISNULL(PRICING.U_Demurrage2, 0) / 1.12)
                    END) + (CASE
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN (ISNULL(PRICING.U_AddtlDrop2, 0) + ISNULL(PRICING.U_BoomTruck2, 0) + ISNULL(PRICING.U_Manpower2, 0) + ISNULL(PRICING.U_Backload2, 0))
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN ((ISNULL(PRICING.U_AddtlDrop2, 0) + ISNULL(PRICING.U_BoomTruck2, 0) + ISNULL(PRICING.U_Manpower2, 0) + ISNULL(PRICING.U_Backload2, 0)) / 1.12)
                    END))
                ELSE NULL
            END
        ELSE NULL
    END AS U_GrossProfit,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_Addtlcharges') THEN
            CASE
                WHEN @TabName = 'TP' THEN
                    ISNULL(pricing.U_AddtlDrop2, 0) 
                    + ISNULL(pricing.U_BoomTruck2, 0) 
                    + ISNULL(pricing.U_Manpower2, 0) 
                    + ISNULL(pricing.U_Backload2, 0)
                WHEN @TabName = 'PRICING' THEN
                    CASE
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN (ISNULL(PRICING.U_AddtlDrop2, 0) + ISNULL(PRICING.U_BoomTruck2, 0) + ISNULL(PRICING.U_Manpower2, 0) + ISNULL(PRICING.U_Backload2, 0))
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN ((ISNULL(PRICING.U_AddtlDrop2, 0) + ISNULL(PRICING.U_BoomTruck2, 0) + ISNULL(PRICING.U_Manpower2, 0) + ISNULL(PRICING.U_Backload2, 0)) / 1.12)
                    END
                ELSE NULL
            END
        ELSE NULL
    END AS U_Addtlcharges,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_DemurrageN') THEN
            CASE
                WHEN @TabName = 'TP' THEN
                    CASE
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN ISNULL(pricing.U_Demurrage2, 0)
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN (ISNULL(pricing.U_Demurrage2, 0) / 1.12)
                    END
                ELSE NULL
            END
        ELSE NULL
    END AS U_DemurrageN,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_AddtlChargesN') THEN
            CASE
                WHEN @TabName = 'TP' THEN
                    CASE
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN 
                        (ISNULL(pricing.U_AddtlDrop2, 0) 
                        + ISNULL(pricing.U_BoomTruck2, 0) 
                        + ISNULL(pricing.U_Manpower2, 0) 
                        + ISNULL(pricing.U_Backload2, 0))
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN 
                        ((ISNULL(pricing.U_AddtlDrop2, 0) 
                        + ISNULL(pricing.U_BoomTruck2, 0) 
                        + ISNULL(pricing.U_Manpower2, 0) 
                        + ISNULL(pricing.U_Backload2, 0)) / 1.12)
                    END
                ELSE NULL
            END
        ELSE NULL
    END AS U_AddtlChargesN,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_ActualRates') THEN
            CASE
                WHEN @TabName = 'TP' THEN ISNULL(TP.U_ActualRates, 0)
                ELSE NULL
            END
        ELSE NULL
    END AS U_ActualRates,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_RateAdjustments') THEN
            CASE
                WHEN @TabName = 'TP' THEN ISNULL(TP.U_RateAdjustments, 0)
                ELSE NULL
            END
        ELSE NULL
    END AS U_RateAdjustments,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_ActualDemurrage') THEN
            CASE
                WHEN @TabName = 'TP' THEN ISNULL(TP.U_ActualDemurrage, 0)
                ELSE NULL
            END
        ELSE NULL
    END AS U_ActualDemurrage,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_ActualCharges') THEN
            CASE
                WHEN @TabName = 'TP' THEN ISNULL(TP.U_ActualCharges, 0)
                ELSE NULL
            END
        ELSE NULL
    END AS U_ActualCharges,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_OtherCharges') THEN
            CASE
                WHEN @TabName = 'TP' THEN ISNULL(TP.U_OtherCharges, 0)
                ELSE NULL
            END
        ELSE NULL
    END AS U_OtherCharges,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_AddCharges') THEN
            ISNULL(PRICING.U_AddtlDrop,0) + 
            ISNULL(PRICING.U_BoomTruck,0) + 
            ISNULL(PRICING.U_Manpower,0) + 
            ISNULL(PRICING.U_Backload,0)
        ELSE NULL
    END AS U_AddCharges,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_ActualBilledRate') THEN
            CASE
                WHEN @TabName = 'BILLING' OR @TabName = 'PRICING' THEN BILLING.U_ActualBilledRate
                ELSE NULL
            END
        ELSE NULL
    END AS U_ActualBilledRate,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_RateAdjustments') THEN
            CASE
                WHEN @TabName = 'BILLING' THEN BILLING.U_RateAdjustments
                ELSE NULL
            END
        ELSE NULL
    END AS U_RateAdjustments,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_BillingRateAdjustments') THEN
            CASE
                WHEN @TabName = 'PRICING' THEN BILLING.U_RateAdjustments
                ELSE NULL
            END
        ELSE NULL
    END AS U_BillingRateAdjustments,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_ActualDemurrage') THEN
            CASE
                WHEN @TabName = 'BILLING' THEN BILLING.U_ActualDemurrage
                ELSE NULL
            END
        ELSE NULL
    END AS U_ActualDemurrage,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_BillingActualDemurrage') THEN
            CASE
                WHEN @TabName = 'PRICING' THEN BILLING.U_ActualDemurrage
                ELSE NULL
            END
        ELSE NULL
    END AS U_BillingActualDemurrage,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_ActualAddCharges') THEN
            CASE
                WHEN @TabName = 'BILLING' OR @TabName = 'PRICING' THEN BILLING.U_ActualAddCharges
                ELSE NULL
            END
        ELSE NULL
    END AS U_ActualAddCharges,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_GrossClientRatesTax') THEN
            CASE
                WHEN @TabName = 'PRICING' THEN 
                    CASE
                        WHEN ISNULL(client.VatStatus,'Y') = 'Y' THEN PRICING.U_GrossClientRates
                        WHEN ISNULL(client.VatStatus,'Y') = 'N' THEN (PRICING.U_GrossClientRates / 1.12)
                    END
                ELSE NULL
            END
        ELSE NULL
    END AS U_GrossClientRatesTax,
    ISNULL(PRICING.U_GrossTruckerRates, 0) AS U_GrossTruckerRates,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_RateBasis') THEN
            CASE
                WHEN @TabName = 'TP' THEN PRICING.U_RateBasisT
                WHEN @TabName = 'PRICING' THEN PRICING.U_RateBasis
                ELSE NULL
            END
        ELSE NULL
    END AS U_RateBasis,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_GrossTruckerRatesN') THEN
            CASE
                WHEN @TabName = 'TP' THEN
                    CASE
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN ISNULL(PRICING.U_GrossTruckerRates, 0)
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN (ISNULL(PRICING.U_GrossTruckerRates, 0) / 1.12)
                    END
                ELSE NULL
            END
        ELSE NULL
    END AS U_GrossTruckerRatesN,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_TaxType') THEN
            CASE
                WHEN @TabName = 'TP' THEN
                    CASE
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN 'VAT' ELSE 'NONVAT'
                    END
                WHEN @TabName = 'PRICING' THEN
                    CASE
                        WHEN ISNULL(client.VatStatus,'Y') = 'Y' THEN 'VAT' ELSE 'NONVAT'
                    END
                ELSE NULL
            END
        ELSE NULL
    END AS U_TaxType,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_GrossTruckerRatesTax') THEN
            CASE
                WHEN @TabName = 'SUMMARY' OR @TabName = 'PRICING' THEN
                    CASE
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN PRICING.U_GrossTruckerRates
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN (PRICING.U_GrossTruckerRates / 1.12)
                    END
                ELSE NULL
            END
        ELSE NULL
    END AS U_GrossTruckerRatesTax,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_RateBasisT') THEN
            CASE
                WHEN @TabName = 'PRICING' THEN PRICING.U_RateBasisT
                ELSE NULL
            END
        ELSE NULL
    END AS U_RateBasisT,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_TaxTypeT') THEN
            CASE
                WHEN @TabName = 'PRICING' THEN 
                    CASE
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN 'VAT' ELSE 'NONVAT'
                    END
                ELSE NULL
            END
        ELSE NULL
    END AS U_TaxTypeT,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_Demurrage4') THEN
            CASE
                WHEN @TabName = 'PRICING' THEN 
                    CASE
                        WHEN ISNULL(client.VatStatus,'Y') = 'Y' THEN ISNULL(PRICING.U_Demurrage, 0)
                        WHEN ISNULL(client.VatStatus,'Y') = 'N' THEN (ISNULL(PRICING.U_Demurrage, 0) / 1.12)
                    END
                ELSE NULL
            END
        ELSE NULL
    END AS U_Demurrage4,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_AddtlCharges2') THEN
            CASE
                WHEN @TabName = 'PRICING' THEN
                    CASE
                        WHEN ISNULL(client.VatStatus,'Y') = 'Y' THEN 
                            (ISNULL(PRICING.U_AddtlDrop, 0) + ISNULL(PRICING.U_BoomTruck, 0) + ISNULL(PRICING.U_Manpower, 0) + ISNULL(PRICING.U_Backload, 0))
                        WHEN ISNULL(client.VatStatus,'Y') = 'N' THEN 
                            ((ISNULL(PRICING.U_AddtlDrop, 0) + ISNULL(PRICING.U_BoomTruck, 0) + ISNULL(PRICING.U_Manpower, 0) + ISNULL(PRICING.U_Backload, 0)) / 1.12)
                    END
                ELSE NULL
            END
        ELSE NULL
    END AS U_AddtlCharges2,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_GrossProfitC') THEN
            CASE
                WHEN @TabName = 'PRICING' THEN PRICING.U_GrossProfitC
                ELSE NULL
            END
        ELSE NULL
    END AS U_GrossProfitC,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_GrossProfitNet') THEN
            CASE
                WHEN @TabName = 'SUMMARY' OR @TabName = 'PRICING' THEN
                    (CASE
                        WHEN ISNULL(client.VatStatus,'Y') = 'Y' THEN PRICING.U_GrossClientRates
                        WHEN ISNULL(client.VatStatus,'Y') = 'N' THEN (PRICING.U_GrossClientRates / 1.12)
                    END) - (CASE
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN PRICING.U_GrossTruckerRates
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN (PRICING.U_GrossTruckerRates / 1.12)
                    END)
                ELSE NULL
            END
        ELSE NULL
    END AS U_GrossProfitNet,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_TotalInitialClient') THEN
            CASE
                WHEN @TabName = 'SUMMARY' OR @TabName = 'PRICING' THEN
                    CASE
                        WHEN ISNULL(client.VatStatus,'Y') = 'Y' THEN 
                            (ISNULL(PRICING.U_AddtlDrop, 0) + ISNULL(PRICING.U_BoomTruck, 0) + ISNULL(PRICING.U_Manpower, 0) + ISNULL(PRICING.U_Backload, 0))
                        WHEN ISNULL(client.VatStatus,'Y') = 'N' THEN 
                            ((ISNULL(PRICING.U_AddtlDrop, 0) + ISNULL(PRICING.U_BoomTruck, 0) + ISNULL(PRICING.U_Manpower, 0) + ISNULL(PRICING.U_Backload, 0)) / 1.12)
                    END + CASE
                        WHEN ISNULL(client.VatStatus,'Y') = 'Y' THEN ISNULL(PRICING.U_GrossClientRates, 0)
                        WHEN ISNULL(client.VatStatus,'Y') = 'N' THEN (ISNULL(PRICING.U_GrossClientRates, 0) / 1.12)
                    END + CASE
                        WHEN ISNULL(client.VatStatus,'Y') = 'Y' THEN ISNULL(PRICING.U_Demurrage, 0)
                        WHEN ISNULL(client.VatStatus,'Y') = 'N' THEN (ISNULL(PRICING.U_Demurrage, 0) / 1.12)
                    END
                ELSE NULL
            END
        ELSE NULL
    END AS U_TotalInitialClient,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_TotalInitialTruckers') THEN
            CASE
                WHEN @TabName = 'SUMMARY' OR @TabName = 'TP' OR @TabName = 'PRICING' THEN
                    CASE
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN ISNULL(PRICING.U_GrossTruckerRates, 0)
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN (ISNULL(PRICING.U_GrossTruckerRates, 0) / 1.12)
                    END + CASE
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN ISNULL(PRICING.U_Demurrage2, 0)
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN (ISNULL(PRICING.U_Demurrage2, 0) / 1.12)
                    END + CASE
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN (ISNULL(PRICING.U_AddtlDrop2, 0) + ISNULL(PRICING.U_BoomTruck2, 0) + ISNULL(PRICING.U_Manpower2, 0) + ISNULL(PRICING.U_Backload2, 0))
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN ((ISNULL(PRICING.U_AddtlDrop2, 0) + ISNULL(PRICING.U_BoomTruck2, 0) + ISNULL(PRICING.U_Manpower2, 0) + ISNULL(PRICING.U_Backload2, 0)) / 1.12)
                    END
                ELSE NULL
            END
        ELSE NULL
    END AS U_TotalInitialTruckers,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_TotalGrossProfit') THEN
            CASE
                WHEN @TabName = 'SUMMARY' OR @TabName = 'PRICING' THEN
                    (CASE
                        WHEN ISNULL(client.VatStatus,'Y') = 'Y' THEN 
                            (ISNULL(PRICING.U_AddtlDrop, 0) + ISNULL(PRICING.U_BoomTruck, 0) + ISNULL(PRICING.U_Manpower, 0) + ISNULL(PRICING.U_Backload, 0))
                        WHEN ISNULL(client.VatStatus,'Y') = 'N' THEN 
                            ((ISNULL(PRICING.U_AddtlDrop, 0) + ISNULL(PRICING.U_BoomTruck, 0) + ISNULL(PRICING.U_Manpower, 0) + ISNULL(PRICING.U_Backload, 0)) / 1.12)
                    END + CASE
                        WHEN ISNULL(client.VatStatus,'Y') = 'Y' THEN ISNULL(PRICING.U_GrossClientRates, 0)
                        WHEN ISNULL(client.VatStatus,'Y') = 'N' THEN (ISNULL(PRICING.U_GrossClientRates, 0) / 1.12)
                    END + CASE
                        WHEN ISNULL(client.VatStatus,'Y') = 'Y' THEN ISNULL(PRICING.U_Demurrage, 0)
                        WHEN ISNULL(client.VatStatus,'Y') = 'N' THEN (ISNULL(PRICING.U_Demurrage, 0) / 1.12)
                    END) - (CASE
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN ISNULL(PRICING.U_GrossTruckerRates, 0)
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN (ISNULL(PRICING.U_GrossTruckerRates, 0) / 1.12)
                    END + CASE
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN ISNULL(PRICING.U_Demurrage2, 0)
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN (ISNULL(PRICING.U_Demurrage2, 0) / 1.12)
                    END + CASE
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN (ISNULL(PRICING.U_AddtlDrop2, 0) + ISNULL(PRICING.U_BoomTruck2, 0) + ISNULL(PRICING.U_Manpower2, 0) + ISNULL(PRICING.U_Backload2, 0))
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN ((ISNULL(PRICING.U_AddtlDrop2, 0) + ISNULL(PRICING.U_BoomTruck2, 0) + ISNULL(PRICING.U_Manpower2, 0) + ISNULL(PRICING.U_Backload2, 0)) / 1.12)
                    END)
                ELSE NULL
            END
        ELSE NULL
    END AS U_TotalGrossProfit,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_ClientTag2') THEN
            CASE
                WHEN @TabName = 'PRICING' THEN PRICING.U_ClientTag
                ELSE NULL
            END
        ELSE NULL
    END AS U_ClientTag2,
    client.CardName AS U_ClientName,
    POD.U_SAPClient,
    POD.U_SAPClient AS U_ClientTag,
    ISNULL(client.U_GroupLocation, PRICING.U_ClientProject) AS U_ClientProject,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_ClientVatStatus') THEN
            CASE
            WHEN ISNULL(client.VatStatus,'Y') = 'Y' THEN 'VAT' ELSE 'NONVAT'
            END
        ELSE NULL
    END AS U_ClientVatStatus,
    trucker.CardName AS U_TruckerName,
    POD.U_SAPTrucker AS U_TruckerSAP,
    POD.U_SAPTrucker AS U_TruckerTag,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_TruckerVatStatus') THEN
            CASE
                WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN 'VAT' ELSE 'NONVAT'
            END
        ELSE NULL
    END AS U_TruckerVatStatus,
    TP.U_TPStatus,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_Aging') THEN
            DATEADD(day, 15, POD.U_BookingDate)
        ELSE NULL
    END AS U_Aging,
    POD.U_ISLAND,
    POD.U_ISLAND_D,
    POD.U_IFINTERISLAND,
    POD.U_VERIFICATION_TAT,
    POD.U_POD_TAT,
    POD.U_ActualDateRec_Intitial,
    POD.U_SAPTrucker,
    POD.U_PlateNumber,
    POD.U_VehicleTypeCap,
    POD.U_DeliveryStatus,
    POD.U_DeliveryDateDTR,
    POD.U_DeliveryDatePOD,
    POD.U_NoOfDrops,
    POD.U_TripType,
    POD.U_Receivedby,
    POD.U_ClientReceivedDate,
    POD.U_InitialHCRecDate,
    POD.U_ActualHCRecDate,
    POD.U_DateReturned,
    POD.U_PODinCharge,
    POD.U_VerifiedDateHC,
    POD.U_PTFNo,
    POD.U_DateForwardedBT,
    POD.U_BillingDeadline,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_BillingStatus') THEN
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
            WHERE line.ItemCode = POD.U_BookingNumber
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
            WHERE line.ItemCode = POD.U_BookingNumber
                AND header.CANCELED = 'N'
                AND header.U_BillingStatus IS NOT NULL
            ) ELSE 
                CASE 
                    WHEN @TabName = 'BILLING' THEN BILLING.U_BillingStatus 
                    ELSE POD.U_BillingStatus 
                END
            END
        ELSE NULL
    END AS U_BillingStatus,
    -- POD.U_ServiceType,
    POD.U_SINo,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_BillingTeam') THEN
            CASE
                WHEN @TabName = 'BILLING' THEN BILLING.U_BillingTeam
                ELSE POD.U_BillingTeam
            END
        ELSE NULL
    END As U_BillingTeam,
    POD.U_SOBNumber,
    POD.U_ForwardLoad,
    POD.U_BackLoad,
    POD.U_TypeOfAccessorial,
    POD.U_TimeInEmptyDem,
    POD.U_TimeOutEmptyDem,
    POD.U_VerifiedEmptyDem,
    POD.U_TimeInLoadedDem,
    POD.U_TimeOutLoadedDem,
    POD.U_VerifiedLoadedDem,
    POD.U_TimeInAdvLoading,
    POD.U_PenaltiesManual,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_DayOfTheWeek') THEN
            CASE WHEN ISNULL(POD.U_DayOfTheWeek,'') = '' THEN DATENAME(dw, POD.U_BookingDate)
            ELSE POD.U_DayOfTheWeek END
        ELSE NULL
    END AS U_DayOfTheWeek,
    POD.U_TimeIn,
    POD.U_TimeOut,
    POD.U_TotalNoExceed,
    POD.U_ODOIn,
    POD.U_ODOOut,
    POD.U_TotalUsage,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_ClientSubStatus') THEN
            CASE
                WHEN @TabName = 'POD' THEN
                    CASE WHEN ISNULL(POD.U_ClientReceivedDate,'') = '' THEN 'PENDING' 
                    ELSE 'SUBMITTED' 
                    END
                ELSE NULL
            END
        ELSE NULL
    END AS U_ClientSubStatus,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_ClientSubOverdue') THEN
            CASE
                WHEN @TabName = 'TP' OR @TabName = 'POD' THEN TF.U_ClientSubOverdue
                ELSE NULL
            END
        ELSE NULL
    END AS U_ClientSubOverdue,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_ClientPenaltyCalc') THEN
            CASE
                WHEN @TabName = 'TP' OR @TabName = 'POD' THEN TF.U_ClientPenaltyCalc
                ELSE NULL
            END
        ELSE NULL
    END AS U_ClientPenaltyCalc,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_PODStatusPayment') THEN
            CASE
                WHEN @TabName = 'SUMMARY' OR @TabName = 'POD' THEN 
                    dbo.computePODStatusPayment(
                        dbo.computeOverdueDays(
                            POD.U_ActualHCRecDate,
                            dbo.computePODSubmitDeadline(
                                POD.U_DeliveryDateDTR,
                                ISNULL(client.U_CDC,0)
                            ),
                            ISNULL(POD.U_HolidayOrWeekend, 0)
                        )
                    )
                ELSE NULL
            END
        ELSE NULL
    END AS U_PODStatusPayment,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_PaymentReference') THEN
            CASE
                WHEN @TabName = 'TP' THEN TP.U_PaymentReference
                ELSE NULL
            END
        ELSE NULL
    END AS U_PaymentReference,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_PaymentStatus') THEN
            CASE
                WHEN @TabName = 'TP' THEN TP.U_PaymentStatus
                ELSE NULL
            END
        ELSE NULL
    END AS U_PaymentStatus,
    '' AS U_ProofOfPayment,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_TotalRecClients') THEN
            CASE
                WHEN @TabName = 'SUMMARY' OR @TabName = 'BILLING' OR @TabName = 'PRICING' THEN
                    ISNULL(PRICING.U_GrossClientRates, 0) 
                    + ISNULL(PRICING.U_Demurrage, 0)
                    + (ISNULL(PRICING.U_AddtlDrop,0) + 
                    ISNULL(PRICING.U_BoomTruck,0) + 
                    ISNULL(PRICING.U_Manpower,0) + 
                    ISNULL(PRICING.U_Backload,0))
                    + ISNULL(BILLING.U_ActualBilledRate, 0)
                    + ISNULL(BILLING.U_RateAdjustments, 0)
                    + ISNULL(BILLING.U_ActualDemurrage, 0)
                    + ISNULL(BILLING.U_ActualAddCharges, 0)
                ELSE NULL
            END
        ELSE NULL
    END AS U_TotalRecClients,
    CASE
        WHEN @TabName = 'BILLING' THEN BILLING.U_CheckingTotalBilled
        ELSE NULL
    END AS U_CheckingTotalBilled,
    CASE
        WHEN @TabName = 'BILLING' THEN BILLING.U_Checking
        ELSE NULL
    END AS U_Checking,
    CASE
        WHEN @TabName = 'BILLING' THEN BILLING.U_CWT2307
        ELSE NULL
    END AS U_CWT2307,
    CASE
        WHEN @TabName = 'BILLING' THEN BILLING.U_SOLineNum
        ELSE NULL
    END AS U_SOLineNum,
    CASE
        WHEN @TabName = 'BILLING' THEN BILLING.U_ARInvLineNum
        ELSE NULL
    END AS U_ARInvLineNum,
    CASE
        WHEN @TabName = 'BILLING' THEN client_group.ExtraDays
        WHEN @TabName = 'TP' THEN trucker_group.ExtraDays
        ELSE NULL
    END ExtraDays,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_TotalPayable') THEN
            CASE
                WHEN @TabName = 'SUMMARY' OR @TabName = 'TP' OR @TabName = 'PRICING' THEN
                    ISNULL(CASE
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN ISNULL(PRICING.U_GrossTruckerRates, 0)
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN (ISNULL(PRICING.U_GrossTruckerRates, 0) / 1.12)
                    END, 0) 
                    + ISNULL(CASE
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN ISNULL(TRY_PARSE(CAST(PRICING.U_Demurrage2 AS nvarchar) AS FLOAT), 0)
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN (ISNULL(TRY_PARSE(CAST(PRICING.U_Demurrage2 AS nvarchar) AS FLOAT), 0) / 1.12)
                    END, 0) 
                    + ISNULL(CASE
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN 
                        (ISNULL(PRICING.U_AddtlDrop2, 0) 
                        + ISNULL(PRICING.U_BoomTruck2, 0) 
                        + ISNULL(PRICING.U_Manpower2, 0) 
                        + ISNULL(PRICING.U_Backload2, 0))
                        WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN 
                        ((ISNULL(PRICING.U_AddtlDrop2, 0) 
                        + ISNULL(PRICING.U_BoomTruck2, 0) 
                        + ISNULL(PRICING.U_Manpower2, 0) 
                        + ISNULL(PRICING.U_Backload2, 0)) / 1.12)
                    END, 0) 
                    + ISNULL(TP.U_ActualRates, 0) 
                    + ISNULL(TP.U_RateAdjustments, 0) 
                    + ISNULL(TP.U_ActualDemurrage, 0) 
                    + ISNULL(TP.U_ActualCharges, 0) 
                    + ISNULL(TRY_PARSE(CAST(TP.U_BoomTruck2 AS nvarchar) AS FLOAT), 0) 
                    + ISNULL(TP.U_OtherCharges, 0) 
                    - (ISNULL(TP.U_CAandDP,0) + ISNULL(TP.U_Interest,0) + ISNULL(TP.U_OtherDeductions,0) 
                    + (ABS(ABS(ISNULL(TF.U_TotalSubPenalty,0)) - ABS(ISNULL(TF.U_TotalPenaltyWaived,0)))))
                ELSE NULL
            END
        ELSE NULL
    END AS U_TotalPayable,
    CASE
        WHEN @TabName = 'TP' THEN ISNULL(TF.U_TotalSubPenalty, 0)
        ELSE NULL
    END AS U_TotalSubPenalty,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_PVNo') THEN
            CASE
                WHEN @TabName = 'SUMMARY' OR @TabName = 'TP' OR @TabName = 'PRICING' THEN
                    CASE 
                    WHEN substring(TP.U_PVNo, 1, 2) <> ' ,'
                    THEN TP.U_PVNo
                    ELSE substring(TP.U_PVNo, 3, 100)
                    END
                ELSE NULL
            END
        ELSE NULL
    END AS U_PVNo,
    CASE
        WHEN @TabName = 'TP' THEN ISNULL(TP.U_CAandDP,0)
        ELSE NULL
    END AS U_CAandDP,
    CASE
        WHEN @TabName = 'TP' THEN ISNULL(TP.U_Interest,0)
        ELSE NULL
    END AS U_Interest,
    CASE
        WHEN @TabName = 'TP' THEN ISNULL(TP.U_OtherDeductions,0)
        ELSE NULL
    END AS U_OtherDeductions,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_TOTALDEDUCTIONS') THEN
            CASE
                WHEN @TabName = 'TP' THEN
                    ISNULL(TP.U_CAandDP,0) + ISNULL(TP.U_Interest,0) + ISNULL(TP.U_OtherDeductions,0) 
                    + (ABS(ABS(ISNULL(TF.U_TotalSubPenalty,0)) - ABS(ISNULL(TF.U_TotalPenaltyWaived,0))))
                ELSE NULL
            END
        ELSE NULL
    END AS U_TOTALDEDUCTIONS,
    CASE
        WHEN @TabName = 'TP' THEN TP.U_REMARKS1
        ELSE NULL
    END AS U_REMARKS1,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_TotalAR') THEN
            CASE
                WHEN @TabName = 'SUMMARY' OR @TabName = 'BILLING' OR @TabName = 'PRICING' THEN
                    (SELECT
                        SUM(L.PriceAfVAT)
                    FROM OINV H
                        LEFT JOIN INV1 L ON H.DocEntry = L.DocEntry
                    WHERE H.CANCELED = 'N' AND L.ItemCode = POD.U_BookingNumber)
                ELSE NULL
            END
        ELSE NULL
    END AS U_TotalAR,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_VarAR') THEN
            CASE
                WHEN @TabName = 'SUMMARY' OR @TabName = 'BILLING' OR @TabName = 'PRICING' THEN
                    ISNULL((SELECT
                        SUM(L.PriceAfVAT)
                    FROM OINV H
                        LEFT JOIN INV1 L ON H.DocEntry = L.DocEntry
                    WHERE H.CANCELED = 'N' AND L.ItemCode = POD.U_BookingNumber), 0) 
                    - (ISNULL(PRICING.U_GrossClientRates, 0) 
                    + ISNULL(PRICING.U_Demurrage, 0)
                    + (ISNULL(PRICING.U_AddtlDrop,0) + 
                    ISNULL(PRICING.U_BoomTruck,0) + 
                    ISNULL(PRICING.U_Manpower,0) + 
                    ISNULL(PRICING.U_Backload,0))
                    + ISNULL(BILLING.U_ActualBilledRate, 0)
                    + ISNULL(BILLING.U_RateAdjustments, 0)
                    + ISNULL(BILLING.U_ActualDemurrage, 0)
                    + ISNULL(BILLING.U_ActualAddCharges, 0))
                ELSE NULL
            END
        ELSE NULL
    END AS U_VarAR,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_TotalAP') THEN
            CASE
                WHEN @TabName = 'SUMMARY' OR @TabName = 'TP' OR @TabName = 'PRICING' THEN TF.U_TotalAP
                ELSE NULL
            END
        ELSE NULL
    END AS U_TotalAP,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_VarTP') THEN
            CASE
                WHEN @TabName = 'SUMMARY' OR @TabName = 'TP' OR @TabName = 'PRICING' THEN TF.U_VarTP
                ELSE NULL
            END
        ELSE NULL
    END AS U_VarTP,
    '' AS U_APInvLineNum,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_APDocNum') THEN
            CASE
                WHEN @TabName = 'SUMMARY' THEN 
                    CASE 
                        WHEN TF.U_DocNum IS NULL OR TF.U_DocNum = '' THEN TF.U_Paid
                        ELSE 
                            CASE 
                                WHEN TF.U_Paid IS NULL OR TF.U_Paid = '' THEN TF.U_DocNum 
                                ELSE CONCAT(TF.U_DocNum, ', ', TF.U_Paid)
                            END
                    END
                WHEN @TabName = 'PRICING' THEN TF.U_DocNum
                ELSE NULL
            END
        ELSE NULL
    END As U_APDocNum,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_PODSubmitDeadline') THEN
            CASE
                WHEN @TabName = 'POD' THEN 
                    dbo.computePODSubmitDeadline(
                        POD.U_DeliveryDateDTR,
                        ISNULL(client.U_CDC,0)
                    )
                ELSE NULL
            END
        ELSE NULL
    END AS U_PODSubmitDeadline,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_OverdueDays') THEN
            CASE
                WHEN @TabName = 'POD' THEN 
                    dbo.computeOverdueDays(
                        POD.U_ActualHCRecDate,
                        dbo.computePODSubmitDeadline(
                            POD.U_DeliveryDateDTR,
                            ISNULL(client.U_CDC,0)
                        ),
                        ISNULL(POD.U_HolidayOrWeekend, 0)
                    )
                ELSE NULL
            END
        ELSE NULL
    END AS U_OverdueDays,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_InteluckPenaltyCalc') THEN
            CASE
                WHEN @TabName = 'TP' OR @TabName = 'POD' THEN TF.U_InteluckPenaltyCalc
                ELSE NULL
            END
        ELSE NULL
    END AS U_InteluckPenaltyCalc,
    POD.U_WaivedDays,
    POD.U_HolidayOrWeekend,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_LostPenaltyCalc') THEN
            CASE
                WHEN @TabName = 'TP' OR @TabName = 'POD' THEN TF.U_LostPenaltyCalc
                ELSE NULL
            END
        ELSE NULL
    END AS U_LostPenaltyCalc,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_TotalSubPenalties') THEN
            CASE
                WHEN @TabName = 'POD' THEN 
                    dbo.computeTotalSubPenalties(
                        dbo.computeClientPenaltyCalc(
                            dbo.computeClientSubOverdue(
                                POD.U_DeliveryDateDTR,
                                POD.U_ClientReceivedDate,
                                ISNULL(POD.U_WaivedDays, 0),
                                CAST(ISNULL(client.U_DCD,0) as int)
                            )
                        ),
                        dbo.computeInteluckPenaltyCalc(
                            dbo.computePODStatusPayment(
                                dbo.computeOverdueDays(
                                    POD.U_ActualHCRecDate,
                                    dbo.computePODSubmitDeadline(
                                        POD.U_DeliveryDateDTR,
                                        ISNULL(client.U_CDC,0)
                                    ),
                                    ISNULL(POD.U_HolidayOrWeekend, 0)
                                )
                            ),
                            dbo.computeOverdueDays(
                                POD.U_ActualHCRecDate,
                                dbo.computePODSubmitDeadline(
                                    POD.U_DeliveryDateDTR,
                                    ISNULL(client.U_CDC,0)
                                ),
                                ISNULL(POD.U_HolidayOrWeekend, 0)
                            )
                        ),
                        dbo.computeLostPenaltyCalc(
                            dbo.computePODStatusPayment(
                                dbo.computeOverdueDays(
                                    POD.U_ActualHCRecDate,
                                    dbo.computePODSubmitDeadline(
                                        POD.U_DeliveryDateDTR,
                                        ISNULL(client.U_CDC,0)
                                    ),
                                    ISNULL(POD.U_HolidayOrWeekend, 0)
                                )
                            ),
                            POD.U_InitialHCRecDate,
                            POD.U_DeliveryDateDTR,
                            CASE
                                WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN PRICING.U_GrossTruckerRates
                                WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN (PRICING.U_GrossTruckerRates / 1.12)
                            END + CASE
                                WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN PRICING.U_Demurrage2
                                WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN (PRICING.U_Demurrage2 / 1.12)
                            END + CASE
                                WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN (PRICING.U_AddtlDrop + PRICING.U_BoomTruck + PRICING.U_Manpower + PRICING.U_Backload)
                                WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN ((PRICING.U_AddtlDrop + PRICING.U_BoomTruck + PRICING.U_Manpower + PRICING.U_Backload) / 1.12)
                            END
                        ),
                        ISNULL(POD.U_PenaltiesManual,0)
                    )
                ELSE NULL
            END
        ELSE NULL
    END AS U_TotalSubPenalties,
    CASE WHEN ISNULL(POD.U_Waived,'') = '' THEN 'N' 
    ELSE POD.U_Waived END AS 'U_Waived',
    POD.U_PercPenaltyCharge,
    POD.U_Approvedby,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_TotalPenaltyWaived') THEN
            CASE
                WHEN @TabName = 'POD' OR @TabName = 'TP' THEN ISNULL(TF.U_TotalPenaltyWaived, 0)
                ELSE NULL
            END
        ELSE NULL
    END AS U_TotalPenaltyWaived,
    ISNULL(TP.U_TotalPenalty, 0) AS U_TotalPenalty,
    ISNULL(BILLING.Code,'') 'BillingNum',
    ISNULL(TP.Code,'') 'TPNum',
    ISNULL(PRICING.Code,'') 'PricingNum',
    ISNULL(client.U_CDC,0) 'CDC',
    ISNULL(client.U_DCD,0) 'DCD',
    ISNULL(PRICING.U_GrossTruckerRates,0) 'GrossTruckerRates',
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_ServiceType') THEN
            CASE
                WHEN @TabName = 'SUMMARY' OR @TabName = 'POD' OR @TabName = 'BILLING' THEN 
                    CAST((
                        SELECT DISTINCT
                        SUBSTRING(
                                (
                                    SELECT CONCAT(', ', header.U_ServiceType)  AS [text()]
                        FROM INV1 line
                            LEFT JOIN OINV header ON header.DocEntry = line.DocEntry
                        WHERE line.ItemCode = POD.U_BookingNumber
                            AND header.U_ServiceType IS NOT NULL
                            AND header.CANCELED = 'N'
                        FOR XML PATH (''), TYPE
                                ).value('text()[1]','nvarchar(max)'), 2, 1000) DocEntry
                    FROM OINV header
                        LEFT JOIN INV1 line ON line.DocEntry = header.DocEntry
                    WHERE line.ItemCode = POD.U_BookingNumber
                        AND header.U_ServiceType IS NOT NULL
                        AND header.CANCELED = 'N'
                        ) as nvarchar(max)
                    )
                ELSE NULL
            END
        ELSE NULL
    END AS U_ServiceType,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_InvoiceNo') THEN
            CASE
                WHEN @TabName = 'SUMMARY' OR @TabName = 'BILLING' THEN 
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
                        WHERE line.ItemCode = POD.U_BookingNumber
                            AND header.CANCELED = 'N'
                        FOR XML PATH (''), TYPE
                                ).value('text()[1]','nvarchar(max)'), 2, 1000) DocEntry
                    FROM OINV header
                        LEFT JOIN INV1 line ON line.DocEntry = header.DocEntry
                    WHERE line.ItemCode = POD.U_BookingNumber
                        AND header.CANCELED = 'N') as nvarchar(max)
                    )
                ELSE NULL
            END
        ELSE NULL
    END AS U_InvoiceNo,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_ARDocNum') THEN
            CASE
                WHEN @TabName = 'SUMMARY' THEN 
                    CAST((
                        SELECT DISTINCT
                        SUBSTRING(
                                (
                                    SELECT CONCAT(', ', header.DocNum)  AS [text()]
                        FROM INV1 line
                            LEFT JOIN OINV header ON header.DocEntry = line.DocEntry
                        WHERE line.ItemCode = POD.U_BookingNumber
                            AND header.CANCELED = 'N'
                        FOR XML PATH (''), TYPE
                                ).value('text()[1]','nvarchar(max)'), 2, 1000) DocEntry
                    FROM OINV header
                        LEFT JOIN INV1 line ON line.DocEntry = header.DocEntry
                    WHERE line.ItemCode = POD.U_BookingNumber
                        AND header.CANCELED = 'N') as nvarchar(max)
                    )
                ELSE NULL
            END
        ELSE NULL
    END As U_ARDocNum,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_DocNum') THEN
            CASE
                WHEN @TabName = 'BILLING' THEN 
                    CAST((
                        SELECT DISTINCT
                        SUBSTRING(
                                (
                                    SELECT CONCAT(', ', header.DocNum)  AS [text()]
                        FROM INV1 line
                            LEFT JOIN OINV header ON header.DocEntry = line.DocEntry
                        WHERE line.ItemCode = BILLING.U_BookingId
                            AND header.CANCELED = 'N'
                        FOR XML PATH (''), TYPE
                                ).value('text()[1]','nvarchar(max)'), 2, 1000) DocEntry
                    FROM OINV header
                        LEFT JOIN INV1 line ON line.DocEntry = header.DocEntry
                    WHERE line.ItemCode = BILLING.U_BookingId
                        AND header.CANCELED = 'N') as nvarchar(max)
                    )
                WHEN @TabName = 'POD' THEN CAST(POD.U_DocNum as nvarchar(max))
                WHEN @TabName = 'TP' THEN TF.U_DocNum
                WHEN @TabName = 'PRICING' THEN 
                    CAST((
                        SELECT DISTINCT
                        SUBSTRING(
                                (
                                    SELECT CONCAT(', ', header.DocNum)  AS [text()]
                        FROM INV1 line
                            LEFT JOIN OINV header ON header.DocEntry = line.DocEntry
                        WHERE line.ItemCode = PRICING.U_BookingId
                            AND header.CANCELED = 'N'
                        FOR XML PATH (''), TYPE
                                ).value('text()[1]','nvarchar(max)'), 2, 1000) DocEntry
                    FROM OINV header
                        LEFT JOIN INV1 line ON line.DocEntry = header.DocEntry
                    WHERE line.ItemCode = PRICING.U_BookingId
                        AND header.CANCELED = 'N') as nvarchar(max)
                    )
                ELSE NULL
            END
        ELSE NULL
    END AS U_DocNum,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_Paid') THEN
            CASE
                WHEN @TabName = 'TP' OR @TabName = 'PRICING' THEN TF.U_Paid
                ELSE NULL
            END
        ELSE NULL
    END AS U_Paid,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_ActualPaymentDate') THEN
            CASE
                WHEN @TabName = 'TP' THEN
                    SUBSTRING((
                        SELECT
                            CONCAT(', ', CAST(T0.TrsfrDate AS DATE)) AS [text()]
                        FROM OVPM T0 WITH (NOLOCK)
                        INNER JOIN VPM2 T1 ON T1.DocNum = T0.DocEntry
                        LEFT JOIN VPM1 T2 ON T1.DocNum = T2.DocNum
                        LEFT JOIN OPCH T3 ON T1.DocEntry = T3.DocEntry
                        WHERE T0.Canceled <> 'Y' AND T3.DocNum IN (SELECT RTRIM(LTRIM(value)) AS DocNum FROM STRING_SPLIT(TF.U_Paid, ','))
                        FOR XML PATH (''), TYPE).value('text()[1]','nvarchar(max)'), 2, 1000
                    )
                ELSE NULL
            END
        ELSE NULL
    END AS U_ActualPaymentDate,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_PaymentReference') THEN
            CASE
                WHEN @TabName = 'TP' THEN
                    SUBSTRING((
                        SELECT
                            CONCAT(', ', T0.TrsfrRef) AS [text()]
                        FROM OVPM T0 WITH (NOLOCK)
                        INNER JOIN VPM2 T1 ON T1.DocNum = T0.DocEntry
                        LEFT JOIN VPM1 T2 ON T1.DocNum = T2.DocNum
                        LEFT JOIN OPCH T3 ON T1.DocEntry = T3.DocEntry
                        WHERE T0.Canceled <> 'Y' AND T3.DocNum IN (SELECT RTRIM(LTRIM(value)) AS DocNum FROM STRING_SPLIT(TF.U_Paid, ','))
                        FOR XML PATH (''), TYPE).value('text()[1]','nvarchar(max)'), 2, 1000
                    )
                ELSE NULL
            END
        ELSE NULL
    END AS U_PaymentReference,
    CASE
        WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_PaymentStatus') THEN
            CASE
                WHEN @TabName = 'TP' THEN
                    SUBSTRING((
                        SELECT
                            CONCAT(', ', 
                            CASE 
                                WHEN T3.PaidSum - T3.DocTotal <= 0 THEN 'Paid'
                                ELSE 'Unpaid' 
                            END
                            ) AS [text()]
                        FROM OVPM T0 WITH (NOLOCK)
                        INNER JOIN VPM2 T1 ON T1.DocNum = T0.DocEntry
                        LEFT JOIN VPM1 T2 ON T1.DocNum = T2.DocNum
                        LEFT JOIN OPCH T3 ON T1.DocEntry = T3.DocEntry
                        WHERE T0.Canceled <> 'Y' AND T3.DocNum IN (SELECT RTRIM(LTRIM(value)) AS DocNum FROM STRING_SPLIT(TF.U_Paid, ','))
                        FOR XML PATH (''), TYPE).value('text()[1]','nvarchar(max)'), 2, 1000
                    )
                ELSE NULL
            END
        ELSE NULL
    END AS U_PaymentStatus,
    ISNULL(CAST(client.U_GroupLocation as nvarchar(max)), '') AS U_GroupProject,
    CAST(POD.U_Attachment as nvarchar(max)) AS U_Attachment,
    CAST(POD.U_DeliveryOrigin as nvarchar(max)) AS U_DeliveryOrigin,
    CAST(POD.U_Destination as nvarchar(max)) AS U_Destination,
    CASE
        WHEN @TabName = 'POD' THEN CAST(POD.U_Remarks as nvarchar(max))
        WHEN @TabName = 'TP' THEN CAST(TP.U_Remarks as nvarchar(max))
        ELSE NULL
    END AS U_Remarks,
    CAST(POD.U_OtherPODDoc as nvarchar(max)) AS U_OtherPODDoc,
    CAST(POD.U_RemarksPOD as nvarchar(max)) AS U_RemarksPOD,
    CAST(POD.U_PODStatusDetail as nvarchar(max)) AS U_PODStatusDetail,
    CAST(POD.U_BTRemarks as nvarchar(max)) AS U_BTRemarks,
    CAST(POD.U_DestinationClient as nvarchar(max)) AS U_DestinationClient,
    CAST(POD.U_Remarks2 as nvarchar(max)) AS U_Remarks2,
    CAST(POD.U_TripTicketNo as nvarchar(max)) AS U_TripTicketNo,
    CAST(POD.U_WaybillNo as nvarchar(max)) AS U_WaybillNo,
    CAST(POD.U_ShipmentNo as nvarchar(max)) AS U_ShipmentNo,
    CAST(POD.U_DeliveryReceiptNo as nvarchar(max)) AS U_DeliveryReceiptNo,
    CAST(POD.U_SeriesNo as nvarchar(max)) AS U_SeriesNo,
    CAST(POD.U_OutletNo as nvarchar(max)) AS U_OutletNo,
    CAST(POD.U_CBM as nvarchar(max)) AS U_CBM,
    CAST(POD.U_SI_DRNo as nvarchar(max)) AS U_SI_DRNo,
    CAST(POD.U_DeliveryMode as nvarchar(max)) AS U_DeliveryMode,
    CAST(POD.U_SourceWhse as nvarchar(max)) AS U_SourceWhse,
    CAST(POD.U_SONo as nvarchar(max)) AS U_SONo,
    CAST(POD.U_NameCustomer as nvarchar(max)) AS U_NameCustomer,
    CAST(POD.U_CategoryDR as nvarchar(max)) AS U_CategoryDR,
    CAST(POD.U_IDNumber as nvarchar(max)) AS U_IDNumber,
    CAST(POD.U_ApprovalStatus as nvarchar(max)) AS U_ApprovalStatus,
    CAST(PRICING.U_RemarksDTR as nvarchar(max)) AS U_RemarksDTR,
    CAST(PRICING.U_RemarksPOD as nvarchar(max)) AS U_RemarksPOD,
    CAST(POD.U_TotalInvAmount as nvarchar(max)) AS U_TotalInvAmount

--COLUMNS
FROM [dbo].[@PCTP_POD] POD WITH (NOLOCK)
    LEFT JOIN [dbo].[@PCTP_BILLING] BILLING ON POD.U_BookingNumber = BILLING.U_BookingId
    LEFT JOIN [dbo].[@PCTP_TP] TP ON POD.U_BookingNumber = TP.U_BookingId
    LEFT JOIN [dbo].[@PCTP_PRICING] PRICING ON POD.U_BookingNumber = PRICING.U_BookingId
    LEFT JOIN OCRD client ON POD.U_SAPClient = client.CardCode
    LEFT JOIN OCRD trucker ON POD.U_SAPTrucker = trucker.CardCode
    LEFT JOIN OCTG client_group ON client.GroupNum = client_group.GroupNum
    LEFT JOIN OCTG trucker_group ON trucker.GroupNum = trucker_group.GroupNum
    LEFT JOIN LOCAL_TP_FORMULA TF ON TF.U_BookingNumber = POD.U_BookingNumber
WHERE POD.U_BookingNumber IN (SELECT item FROM @BookingIdList)
;  
    
GO  