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
    pod.U_InitialHCRecDate AS U_InitialHCRecDate,
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
    + (ABS(ABS(ISNULL(TF.U_TotalSubPenalty,0)) - ABS(ISNULL(TF.U_TotalPenaltyWaived,0))))) AS U_TotalPayable,
    T0.U_EWT2307,
    ISNULL(T0.U_TotalPayableRec, 0) AS U_TotalPayableRec,

    CASE 
    WHEN substring(T0.U_PVNo, 1, 2) <> ' ,'
      THEN T0.U_PVNo
    ELSE substring(T0.U_PVNo, 3, 100)
    END AS U_PVNo,

    T0.U_ORRefNo,
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

    
    -- T0.U_ActualPaymentDate,
    -- T0.U_PaymentReference,
    -- T0.U_PaymentStatus,

    SUBSTRING((
        SELECT
            CONCAT(', ', CAST(T0.TrsfrDate AS DATE)) AS [text()]
        FROM OVPM T0 WITH (NOLOCK)
        INNER JOIN VPM2 T1 ON T1.DocNum = T0.DocEntry
        LEFT JOIN VPM1 T2 ON T1.DocNum = T2.DocNum
        LEFT JOIN OPCH T3 ON T1.DocEntry = T3.DocEntry
        WHERE T0.Canceled <> 'Y' AND T3.DocNum IN (SELECT RTRIM(LTRIM(value)) AS DocNum FROM STRING_SPLIT(TF.U_Paid, ','))
        FOR XML PATH (''), TYPE).value('text()[1]','nvarchar(max)'), 2, 1000
    ) AS U_ActualPaymentDate,
    SUBSTRING((
        SELECT
            CONCAT(', ', T0.TrsfrRef) AS [text()]
        FROM OVPM T0 WITH (NOLOCK)
        INNER JOIN VPM2 T1 ON T1.DocNum = T0.DocEntry
        LEFT JOIN VPM1 T2 ON T1.DocNum = T2.DocNum
        LEFT JOIN OPCH T3 ON T1.DocEntry = T3.DocEntry
        WHERE T0.Canceled <> 'Y' AND T3.DocNum IN (SELECT RTRIM(LTRIM(value)) AS DocNum FROM STRING_SPLIT(TF.U_Paid, ','))
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
        FROM OVPM T0 WITH (NOLOCK)
        INNER JOIN VPM2 T1 ON T1.DocNum = T0.DocEntry
        LEFT JOIN VPM1 T2 ON T1.DocNum = T2.DocNum
        LEFT JOIN OPCH T3 ON T1.DocEntry = T3.DocEntry
        WHERE T0.Canceled <> 'Y' AND T3.DocNum IN (SELECT RTRIM(LTRIM(value)) AS DocNum FROM STRING_SPLIT(TF.U_Paid, ','))
        FOR XML PATH (''), TYPE).value('text()[1]','nvarchar(max)'), 2, 1000
    ) AS U_PaymentStatus,

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
FROM [dbo].[@PCTP_TP] T0  WITH (NOLOCK)
    INNER JOIN [dbo].[@PCTP_POD] pod ON T0.U_BookingId = pod.U_BookingNumber AND CAST(pod.U_PODStatusDetail as nvarchar(max)) LIKE '%Verified%'
    --JOINS
    LEFT JOIN [dbo].[@PCTP_PRICING] pricing ON T0.U_BookingId = pricing.U_BookingId
    LEFT JOIN [dbo].[@PCTP_BILLING] billing ON T0.U_BookingId = billing.U_BookingId
    LEFT JOIN OCRD T4 ON pod.U_SAPClient = T4.CardCode
    LEFT JOIN OCRD T5 ON T5.CardCode = pod.U_SAPTrucker
    LEFT JOIN OCTG T6 ON T5.GroupNum = T6.GroupNum
    LEFT JOIN TP_FORMULA TF ON TF.U_BookingId = T0.U_BookingId
    LEFT JOIN BILLING_EXTRACT BE ON BE.U_BookingNumber = T0.U_BookingId
--JOINS
