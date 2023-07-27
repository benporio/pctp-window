SELECT


    --COLUMNS
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
    T0.Code,
    T0.U_BookingId,
    T0.U_BookingDate,
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
    pricing.U_GrossTruckerRates AS U_GrossTruckerRates,
    pricing.U_RateBasisT AS U_RateBasis,
    CASE
        WHEN ISNULL(T5.VatStatus,'Y') = 'Y' THEN pricing.U_GrossTruckerRates
        WHEN ISNULL(T5.VatStatus,'Y') = 'N' THEN (pricing.U_GrossTruckerRates / 1.12)
    END AS 'U_GrossTruckerRatesN',
    CASE
       WHEN ISNULL(T5.VatStatus,'Y') = 'Y' THEN 'VAT' ELSE 'NONVAT'
    END AS 'U_TaxType',
    pricing.U_Demurrage2 AS U_Demurrage,
    pricing.U_AddtlDrop2 AS U_AddtlDrop,
    pricing.U_BoomTruck2 AS U_BoomTruck,
    T0.U_BoomTruck2,
    pricing.U_Manpower2 AS U_Manpower,
    pricing.U_Backload2 AS U_BackLoad,
    -- pricing.U_totalAddtlCharges2 AS U_Addtlcharges,
    pricing.U_AddtlDrop2 + pricing.U_BoomTruck2 + pricing.U_Manpower2 + pricing.U_Backload2 AS U_Addtlcharges,
    CASE
        WHEN ISNULL(T5.VatStatus,'Y') = 'Y' THEN pricing.U_Demurrage2
        WHEN ISNULL(T5.VatStatus,'Y') = 'N' THEN (pricing.U_Demurrage2 / 1.12)
    END AS 'U_DemurrageN',

    CASE
        WHEN ISNULL(T5.VatStatus,'Y') = 'Y' THEN (pricing.U_AddtlDrop2 + pricing.U_BoomTruck2 + pricing.U_Manpower2 + pricing.U_Backload2)
        WHEN ISNULL(T5.VatStatus,'Y') = 'N' THEN ((pricing.U_AddtlDrop2 + pricing.U_BoomTruck2 + pricing.U_Manpower2 + pricing.U_Backload2) / 1.12)
    END AS 'U_AddtlChargesN',

    -- pricing.U_AddtlCharges AS U_AddtlChargesN,
    T0.U_ActualRates,
    T0.U_RateAdjustments,
    T0.U_ActualDemurrage,
    T0.U_ActualCharges,
    T0.U_OtherCharges,
    ISNULL(pod.U_WaivedDays, 0) AS WaivedDaysx,
    TF.U_ClientSubOverdue,
    TF.U_ClientPenaltyCalc,
    ISNULL(pod.U_HolidayOrWeekend, 0) AS xHolidayOrWeekend,
    TF.U_InteluckPenaltyCalc,
    pod.U_InitialHCRecDate,
    pod.U_DeliveryDateDTR,
    pricing.U_TotalInitialTruckers,
    TF.U_LostPenaltyCalc,
    TF.U_TotalSubPenalty,
    TF.U_TotalPenaltyWaived,
    T0.U_TotalPenalty,
    T0.U_TotalPayable,
    T0.U_EWT2307,
    T0.U_TotalPayableRec,

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
    ISNULL(T0.U_TOTALDEDUCTIONS,0) AS U_TOTALDEDUCTIONS,
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
FROM [dbo].[@PCTP_TP] T0
    RIGHT JOIN [dbo].[@PCTP_POD] pod ON T0.U_BookingId = pod.U_BookingNumber AND CAST(pod.U_PODStatusDetail as nvarchar(max)) LIKE '%Verified%'
    LEFT JOIN [dbo].[@PCTP_PRICING] pricing ON T0.U_BookingId = pricing.U_BookingId
    LEFT JOIN [dbo].[@PCTP_BILLING] billing ON T0.U_BookingId = billing.U_BookingId
    LEFT JOIN OCRD T4 ON pod.U_SAPClient = T4.CardCode
    LEFT JOIN OCRD T5 ON T5.CardCode = pod.U_SAPTrucker
    LEFT JOIN OCTG T6 ON T5.GroupNum = T6.GroupNum
    LEFT JOIN TP_FORMULA TF ON TF.U_BookingId = T0.U_BookingId

--WHERE T0.U_BookingId IN ('TPTEST62291237FQV','TPTEST62291478UJB','TPTEST62291699QFM','TPTEST62291046FJV')
