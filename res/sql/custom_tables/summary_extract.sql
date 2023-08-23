DROP TABLE IF EXISTS SUMMARY_EXTRACT
GO
-- SUMMARY
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
    T2.CardName AS U_TruckerName,
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
    -- T0.U_PODStatusPayment,
    dbo.computePODStatusPayment(
        dbo.computeOverdueDays(
            T0.U_ActualHCRecDate,
            dbo.computePODSubmitDeadline(
                T0.U_DeliveryDateDTR,
                ISNULL(T1.U_CDC,0)
            ),
            ISNULL(T0.U_HolidayOrWeekend, 0)
        )
    ) AS 'U_PODStatusPayment',
    tp.U_PaymentReference,
    tp.U_PaymentStatus,
    '' AS U_ProofOfPayment,
    ISNULL(pricing.U_GrossClientRates, 0) 
    + ISNULL(pricing.U_Demurrage, 0)
    + (ISNULL(pricing.U_AddtlDrop,0) + 
    ISNULL(pricing.U_BoomTruck,0) + 
    ISNULL(pricing.U_Manpower,0) + 
    ISNULL(pricing.U_Backload,0))
    + ISNULL(billing.U_ActualBilledRate, 0)
    + ISNULL(billing.U_RateAdjustments, 0)
    + ISNULL(billing.U_ActualDemurrage, 0)
    + ISNULL(billing.U_ActualAddCharges, 0) AS U_TotalRecClients,
    ISNULL(CASE
        WHEN ISNULL(T2.VatStatus,'Y') = 'Y' THEN ISNULL(pricing.U_GrossTruckerRates, 0)
        WHEN ISNULL(T2.VatStatus,'Y') = 'N' THEN (ISNULL(pricing.U_GrossTruckerRates, 0) / 1.12)
    END, 0) 
    + ISNULL(CASE
        WHEN ISNULL(T2.VatStatus,'Y') = 'Y' THEN ISNULL(TRY_PARSE(CAST(pricing.U_Demurrage2 AS nvarchar) AS FLOAT), 0)
        WHEN ISNULL(T2.VatStatus,'Y') = 'N' THEN (ISNULL(TRY_PARSE(CAST(pricing.U_Demurrage2 AS nvarchar) AS FLOAT), 0) / 1.12)
    END, 0) 
    + ISNULL(CASE
        WHEN ISNULL(T2.VatStatus,'Y') = 'Y' THEN 
        (ISNULL(pricing.U_AddtlDrop2, 0) 
        + ISNULL(pricing.U_BoomTruck2, 0) 
        + ISNULL(pricing.U_Manpower2, 0) 
        + ISNULL(pricing.U_Backload2, 0))
        WHEN ISNULL(T2.VatStatus,'Y') = 'N' THEN 
        ((ISNULL(pricing.U_AddtlDrop2, 0) 
        + ISNULL(pricing.U_BoomTruck2, 0) 
        + ISNULL(pricing.U_Manpower2, 0) 
        + ISNULL(pricing.U_Backload2, 0)) / 1.12)
    END, 0) 
    + ISNULL(tp.U_ActualRates, 0) 
    + ISNULL(tp.U_RateAdjustments, 0) 
    + ISNULL(tp.U_ActualDemurrage, 0) 
    + ISNULL(tp.U_ActualCharges, 0) 
    + ISNULL(TRY_PARSE(CAST(tp.U_BoomTruck2 AS nvarchar) AS FLOAT), 0) 
    + ISNULL(tp.U_OtherCharges, 0) 
    - (ISNULL(tp.U_CAandDP,0) + ISNULL(tp.U_Interest,0) + ISNULL(tp.U_OtherDeductions,0) 
    + (ABS(ABS(ISNULL(TF.U_TotalSubPenalty,0)) - ABS(ISNULL(TF.U_TotalPenaltyWaived,0))))) AS U_TotalPayable,
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
    ISNULL((SELECT
        SUM(L.PriceAfVAT)
    FROM OINV H
        LEFT JOIN INV1 L ON H.DocEntry = L.DocEntry
    WHERE H.CANCELED = 'N' AND L.ItemCode = T0.U_BookingNumber), 0) 
    - (ISNULL(pricing.U_GrossClientRates, 0) 
    + ISNULL(pricing.U_Demurrage, 0)
    + (ISNULL(pricing.U_AddtlDrop,0) + 
    ISNULL(pricing.U_BoomTruck,0) + 
    ISNULL(pricing.U_Manpower,0) + 
    ISNULL(pricing.U_Backload,0))
    + ISNULL(billing.U_ActualBilledRate, 0)
    + ISNULL(billing.U_RateAdjustments, 0)
    + ISNULL(billing.U_ActualDemurrage, 0)
    + ISNULL(billing.U_ActualAddCharges, 0)) AS U_VarAR,
    TF.U_TotalAP,
    TF.U_VarTP,
    CASE 
        WHEN TF.U_DocNum IS NULL OR TF.U_DocNum = '' THEN TF.U_Paid
        ELSE 
            CASE 
                WHEN TF.U_Paid IS NULL OR TF.U_Paid = '' THEN TF.U_DocNum 
                ELSE CONCAT(TF.U_DocNum, ', ', TF.U_Paid)
            END
    END AS U_APDocNum,
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
INTO SUMMARY_EXTRACT
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