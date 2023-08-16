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
    ISNULL(T0.U_GrossClientRates, 0) 
    + ISNULL(T0.U_Demurrage, 0)
    + (ISNULL(T0.U_AddtlDrop,0) + 
    ISNULL(T0.U_BoomTruck,0) + 
    ISNULL(T0.U_Manpower,0) + 
    ISNULL(T0.U_Backload,0))
    + ISNULL(billing.U_ActualBilledRate, 0)
    + ISNULL(billing.U_RateAdjustments, 0)
    + ISNULL(billing.U_ActualDemurrage, 0)
    + ISNULL(billing.U_ActualAddCharges, 0) AS U_TotalRecClients,
    (SELECT
        SUM(L.PriceAfVAT)
    FROM OINV H
        LEFT JOIN INV1 L ON H.DocEntry = L.DocEntry
    WHERE H.CANCELED = 'N' AND L.ItemCode = T0.U_BookingId) AS U_TotalAR,
    ISNULL((SELECT
        SUM(L.PriceAfVAT)
    FROM OINV H
        LEFT JOIN INV1 L ON H.DocEntry = L.DocEntry
    WHERE H.CANCELED = 'N' AND L.ItemCode = T0.U_BookingId), 0) 
    - (ISNULL(T0.U_GrossClientRates, 0) 
    + ISNULL(T0.U_Demurrage, 0)
    + (ISNULL(T0.U_AddtlDrop,0) + 
    ISNULL(T0.U_BoomTruck,0) + 
    ISNULL(T0.U_Manpower,0) + 
    ISNULL(T0.U_Backload,0))
    + ISNULL(billing.U_ActualBilledRate, 0)
    + ISNULL(billing.U_RateAdjustments, 0)
    + ISNULL(billing.U_ActualDemurrage, 0)
    + ISNULL(billing.U_ActualAddCharges, 0)) AS U_VarAR,
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
    ISNULL(CASE
        WHEN ISNULL(T2.VatStatus,'Y') = 'Y' THEN ISNULL(T0.U_GrossTruckerRates, 0)
        WHEN ISNULL(T2.VatStatus,'Y') = 'N' THEN (ISNULL(T0.U_GrossTruckerRates, 0) / 1.12)
    END, 0) 
    + ISNULL(CASE
        WHEN ISNULL(T2.VatStatus,'Y') = 'Y' THEN ISNULL(TRY_PARSE(CAST(T0.U_Demurrage2 AS nvarchar) AS FLOAT), 0)
        WHEN ISNULL(T2.VatStatus,'Y') = 'N' THEN (ISNULL(TRY_PARSE(CAST(T0.U_Demurrage2 AS nvarchar) AS FLOAT), 0) / 1.12)
    END, 0) 
    + ISNULL(CASE
        WHEN ISNULL(T2.VatStatus,'Y') = 'Y' THEN 
        (ISNULL(T0.U_AddtlDrop2, 0) 
        + ISNULL(T0.U_BoomTruck2, 0) 
        + ISNULL(T0.U_Manpower2, 0) 
        + ISNULL(T0.U_Backload2, 0))
        WHEN ISNULL(T2.VatStatus,'Y') = 'N' THEN 
        ((ISNULL(T0.U_AddtlDrop2, 0) 
        + ISNULL(T0.U_BoomTruck2, 0) 
        + ISNULL(T0.U_Manpower2, 0) 
        + ISNULL(T0.U_Backload2, 0)) / 1.12)
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
WHERE T0.U_BookingId IN (SELECT U_BookingNumber FROM TMP_TARGET_$serial WITH (NOLOCK));


    DELETE FROM PRICING_EXTRACT WHERE U_BookingNumber IN (SELECT U_BookingNumber FROM TMP_TARGET_$serial WITH (NOLOCK));


    INSERT INTO PRICING_EXTRACT
SELECT
    X.U_BookingNumber, X.DisableSomeFields, X.DisableSomeFields2, X.Code, X.U_BookingId, X.U_BookingDate, X.U_PODNum, X.U_CustomerName, X.U_ClientTag, X.U_ClientProject, X.U_TruckerName, X.U_TruckerTag, X.U_VehicleTypeCap, X.U_DeliveryStatus,
    X.U_TripType, X.U_NoOfDrops, X.U_GrossClientRates, X.U_ISLAND, X.U_ISLAND_D, X.U_IFINTERISLAND, X.U_GrossClientRatesTax, X.U_RateBasis, X.U_TaxType, X.U_GrossProfitNet, X.U_Demurrage, X.U_AddtlDrop, X.U_BoomTruck, X.U_Manpower, X.U_Backload,
    X.U_TotalAddtlCharges, X.U_Demurrage2, X.U_AddtlDrop2, X.U_BoomTruck2, X.U_Manpower2, X.U_Backload2, X.U_totalAddtlCharges2, X.U_Demurrage3, X.U_AddtlCharges, X.U_GrossProfit, X.U_TotalInitialClient, X.U_TotalInitialTruckers, X.U_TotalGrossProfit,
    X.U_ClientTag2, X.U_GrossTruckerRates, X.U_GrossTruckerRatesTax, X.U_RateBasisT, X.U_TaxTypeT, X.U_Demurrage4, X.U_AddtlCharges2, X.U_GrossProfitC, X.BillingNum, X.TPNum, X.U_ActualBilledRate, X.U_BillingRateAdjustments,
    X.U_BillingActualDemurrage, X.U_ActualAddCharges, X.U_TotalRecClients, X.U_TotalAR, X.U_VarAR, X.U_PODSONum, X.U_ActualRates, X.U_TPRateAdjustments, X.U_TPActualDemurrage, X.U_ActualCharges, X.U_TPBoomTruck2, X.U_OtherCharges,
    X.U_TotalPayable, X.U_PVNo, X.U_TotalAP, X.U_VarTP, X.U_APDocNum, X.U_Paid, X.U_DocNum, X.U_DeliveryOrigin, X.U_Destination, X.U_RemarksDTR, X.U_RemarksPOD, X.U_PODDocNum
FROM TMP_UPDATE_PRICING_EXTRACT_$serial X;


    DROP TABLE IF EXISTS TMP_UPDATE_PRICING_EXTRACT_$serial;


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