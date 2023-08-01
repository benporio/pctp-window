CREATE PROCEDURE HumanResources.uspGetEmployeesTest2   
    @TabName nvarchar(20) CHECK (@TabName in ('SUMMARY', 'POD', 'BILLING', 'TP', 'PRICING')),   
    @BookingIds nvarchar(50)   
AS   

SET NOCOUNT ON;  

SELECT
    --COLUMNS
    CASE
        WHEN @TabName = 'SUMMARY' THEN POD.Code
        WHEN @TabName = 'POD' THEN POD.U_BookingNumber
        WHEN @TabName = 'BILLING' THEN BILLING.Code
        WHEN @TabName = 'TP' THEN TP.Code
        WHEN @TabName = 'PRICING' THEN PRICING.Code
    END As Code,
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
    END AS DisableTableRow,
    POD.U_BookingDate,
    POD.U_BookingNumber,
    POD.U_BookingNumber AS U_BookingId,
    CASE
        WHEN EXISTS(SELECT 1
    FROM ORDR header
    WHERE header.CANCELED = 'N' AND header.DocEntry = BILLING.U_PODSONum) THEN BILLING.U_PODSONum
        ELSE ''
    END AS U_PODSONum,
    PRICING.U_GrossClientRates,
    CASE
        WHEN ISNULL(client.VatStatus,'Y') = 'Y' THEN PRICING.U_GrossClientRates
        WHEN ISNULL(client.VatStatus,'Y') = 'N' THEN (PRICING.U_GrossClientRates / 1.12)
    END AS U_GrossClientRatesTax,
    PRICING.U_GrossTruckerRates,
    CASE
        WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN PRICING.U_GrossTruckerRates
        WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN (PRICING.U_GrossTruckerRates / 1.12)
    END AS U_GrossTruckerRatesTax,
    (CASE
        WHEN ISNULL(client.VatStatus,'Y') = 'Y' THEN PRICING.U_GrossClientRates
        WHEN ISNULL(client.VatStatus,'Y') = 'N' THEN (PRICING.U_GrossClientRates / 1.12)
    END) - (CASE
        WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN PRICING.U_GrossTruckerRates
        WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN (PRICING.U_GrossTruckerRates / 1.12)
    END) AS U_GrossProfitNet,
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
    END  AS U_TotalInitialClient,
    CASE
        WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN ISNULL(PRICING.U_GrossTruckerRates, 0)
        WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN (ISNULL(PRICING.U_GrossTruckerRates, 0) / 1.12)
    END + CASE
        WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN ISNULL(PRICING.U_Demurrage2, 0)
        WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN (ISNULL(PRICING.U_Demurrage2, 0) / 1.12)
    END + CASE
        WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN (ISNULL(PRICING.U_AddtlDrop2, 0) + ISNULL(PRICING.U_BoomTruck2, 0) + ISNULL(PRICING.U_Manpower2, 0) + ISNULL(PRICING.U_Backload2, 0))
        WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN ((ISNULL(PRICING.U_AddtlDrop2, 0) + ISNULL(PRICING.U_BoomTruck2, 0) + ISNULL(PRICING.U_Manpower2, 0) + ISNULL(PRICING.U_Backload2, 0)) / 1.12)
    END AS U_TotalInitialTruckers,
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
    END) AS U_TotalGrossProfit,
    client.CardName AS U_ClientName,
    POD.U_SAPClient,
    CASE
      WHEN ISNULL(client.VatStatus,'Y') = 'Y' THEN 'VAT' ELSE 'NONVAT'
    END AS 'U_ClientVatStatus',
    trucker.CardName AS U_TruckerName,
    CASE
       WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN 'VAT' ELSE 'NONVAT'
    END AS 'U_TruckerVatStatus',
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
    ) ELSE 
        CASE 
            WHEN @TabName = 'BILLING' THEN BILLING.U_BillingStatus 
            ELSE POD.U_BillingStatus 
        END
    END AS U_BillingStatus,
    POD.U_ServiceType,
    POD.U_SINo,
    POD.U_BillingTeam,
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
    CASE WHEN ISNULL(POD.U_DayOfTheWeek,'') = '' THEN DATENAME(dw, POD.U_BookingDate)
    ELSE POD.U_DayOfTheWeek END AS 'U_DayOfTheWeek',
    POD.U_TimeIn,
    POD.U_TimeOut,
    POD.U_TotalNoExceed,
    POD.U_ODOIn,
    POD.U_ODOOut,
    POD.U_TotalUsage,
    CASE WHEN ISNULL(POD.U_ClientReceivedDate,'') = '' THEN 'PENDING' 
    ELSE 'SUBMITTED' 
    END AS 'U_ClientSubStatus',
    dbo.computeClientSubOverdue(
        POD.U_DeliveryDateDTR,
        POD.U_ClientReceivedDate,
        ISNULL(POD.U_WaivedDays, 0),
        CAST(ISNULL(client.U_DCD,0) as int)
    ) AS 'U_ClientSubOverdue',
    dbo.computeClientPenaltyCalc(
        dbo.computeClientSubOverdue(
            POD.U_DeliveryDateDTR,
            POD.U_ClientReceivedDate,
            ISNULL(POD.U_WaivedDays, 0),
            CAST(ISNULL(client.U_DCD,0) as int)
        )
    ) AS 'U_ClientPenaltyCalc',
    dbo.computePODStatusPayment(
        dbo.computeOverdueDays(
            POD.U_ActualHCRecDate,
            dbo.computePODSubmitDeadline(
                POD.U_DeliveryDateDTR,
                ISNULL(client.U_CDC,0)
            ),
            ISNULL(POD.U_HolidayOrWeekend, 0)
        )
    ) AS 'U_PODStatusPayment',
    TP.U_PaymentReference,
    TP.U_PaymentStatus,
    '' AS U_ProofOfPayment,
    ISNULL(PRICING.U_GrossClientRates, 0) 
    + ISNULL(PRICING.U_Demurrage, 0)
    + (ISNULL(PRICING.U_AddtlDrop,0) + 
    ISNULL(PRICING.U_BoomTruck,0) + 
    ISNULL(PRICING.U_Manpower,0) + 
    ISNULL(PRICING.U_Backload,0))
    + ISNULL(BILLING.U_ActualBilledRate, 0)
    + ISNULL(BILLING.U_RateAdjustments, 0)
    + ISNULL(BILLING.U_ActualDemurrage, 0)
    + ISNULL(BILLING.U_ActualAddCharges, 0) AS U_TotalRecClients,
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
    + (ABS(ABS(ISNULL(TF.U_TotalSubPenalty,0)) - ABS(ISNULL(TF.U_TotalPenaltyWaived,0))))) AS U_TotalPayable,
    CASE 
    WHEN substring(TP.U_PVNo, 1, 2) <> ' ,'
      THEN TP.U_PVNo
    ELSE substring(TP.U_PVNo, 3, 100)
    END AS U_PVNo,
    (SELECT
        SUM(L.PriceAfVAT)
    FROM OINV H
        LEFT JOIN INV1 L ON H.DocEntry = L.DocEntry
    WHERE H.CANCELED = 'N' AND L.ItemCode = POD.U_BookingNumber) AS U_TotalAR,
    ISNULL((SELECT
        SUM(L.PriceAfVAT)
    FROM OINV H
        LEFT JOIN INV1 L ON H.DocEntry = L.DocEntry
    WHERE H.CANCELED = 'N' AND L.ItemCode = T0.U_BookingNumber), 0) 
    - (ISNULL(PRICING.U_GrossClientRates, 0) 
    + ISNULL(PRICING.U_Demurrage, 0)
    + (ISNULL(PRICING.U_AddtlDrop,0) + 
    ISNULL(PRICING.U_BoomTruck,0) + 
    ISNULL(PRICING.U_Manpower,0) + 
    ISNULL(PRICING.U_Backload,0))
    + ISNULL(BILLING.U_ActualBilledRate, 0)
    + ISNULL(BILLING.U_RateAdjustments, 0)
    + ISNULL(BILLING.U_ActualDemurrage, 0)
    + ISNULL(BILLING.U_ActualAddCharges, 0)) AS U_VarAR,
    TF.U_TotalAP,
    TF.U_VarTP,
    dbo.computePODSubmitDeadline(
        POD.U_DeliveryDateDTR,
        ISNULL(client.U_CDC,0)
    ) AS 'U_PODSubmitDeadline',
    dbo.computeOverdueDays(
        POD.U_ActualHCRecDate,
        dbo.computePODSubmitDeadline(
            POD.U_DeliveryDateDTR,
            ISNULL(client.U_CDC,0)
        ),
        ISNULL(POD.U_HolidayOrWeekend, 0)
    ) AS 'U_OverdueDays',
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
    ) AS 'U_InteluckPenaltyCalc',
    POD.U_WaivedDays,
    POD.U_HolidayOrWeekend,
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
    ) AS 'U_LostPenaltyCalc',
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
    ) AS U_TotalSubPenalties,
    CASE WHEN ISNULL(POD.U_Waived,'') = '' THEN 'N' 
    ELSE POD.U_Waived END AS 'U_Waived',
    POD.U_PercPenaltyCharge,
    POD.U_Approvedby,
    dbo.computeTotalPenaltyWaived(
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
        ),
        ISNULL(POD.U_PercPenaltyCharge,0)
    ) AS U_TotalPenaltyWaived,
    ISNULL(BILLING.Code,'') 'BillingNum',
    ISNULL(TP.Code,'') 'TPNum',
    ISNULL(PRICING.Code,'') 'PricingNum',
    ISNULL(client.U_CDC,0) 'CDC',
    ISNULL(client.U_DCD,0) 'DCD',
    ISNULL(PRICING.U_GrossTruckerRates,0) 'GrossTruckerRates',
    ISNULL(CAST(client.U_GroupLocation as nvarchar(max)), '') AS U_GroupProject,
    CAST(POD.U_Attachment as nvarchar(max)) AS U_Attachment,
    CAST(POD.U_DeliveryOrigin as nvarchar(max)) AS U_DeliveryOrigin,
    CAST(POD.U_Destination as nvarchar(max)) AS U_Destination,
    CAST(POD.U_Remarks as nvarchar(max)) AS U_Remarks,
    CAST(POD.U_OtherPODDoc as nvarchar(max)) AS U_OtherPODDoc,
    CAST(POD.U_RemarksPOD as nvarchar(max)) AS U_RemarksPOD,
    CAST(POD.U_PODStatusDetail as nvarchar(max)) AS U_PODStatusDetail,
    CAST(POD.U_BTRemarks as nvarchar(max)) AS U_BTRemarks,
    CAST(POD.U_DestinationClient as nvarchar(max)) AS U_DestinationClient,
    CAST(POD.U_Remarks2 as nvarchar(max)) AS U_Remarks2,
    CAST(POD.U_DocNum as nvarchar(max)) AS U_DocNum,
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
    CAST(POD.U_TotalInvAmount as nvarchar(max)) AS U_TotalInvAmount

--COLUMNS
FROM [dbo].[@PCTP_POD] POD WITH (NOLOCK)
    LEFT JOIN [dbo].[@PCTP_BILLING] BILLING ON POD.U_BookingNumber = BILLING.U_BookingId
    LEFT JOIN [dbo].[@PCTP_TP] TP ON POD.U_BookingNumber = TP.U_BookingId
    LEFT JOIN [dbo].[@PCTP_PRICING] PRICING ON POD.U_BookingNumber = PRICING.U_BookingId
    LEFT JOIN OCRD client ON POD.U_SAPClient = client.CardCode
    LEFT JOIN OCRD trucker ON POD.U_SAPTrucker = trucker.CardCode
    LEFT JOIN TP_FORMULA TF ON TF.U_BookingId = T0.U_BookingNumber
;  
    
GO  