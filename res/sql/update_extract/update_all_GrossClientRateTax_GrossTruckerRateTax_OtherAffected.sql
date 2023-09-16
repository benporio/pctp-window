-------->>CREATING TARGETS
DROP TABLE IF EXISTS TMP_TARGET_20230915;

DECLARE @FromDate DATE = CAST('2023-09-01' AS DATE);
DECLARE @ToDate DATE = CAST('2023-09-15' AS DATE);

DECLARE @GrossClientRatesTax TABLE(id nvarchar(100), value float);
INSERT INTO @GrossClientRatesTax
SELECT DISTINCT
    POD.U_BookingNumber as id,
    CASE
        WHEN ISNULL(client.VatStatus,'Y') = 'Y' THEN PRICING.U_GrossClientRates
        WHEN ISNULL(client.VatStatus,'Y') = 'N' THEN (PRICING.U_GrossClientRates / 1.12)
    END as value
FROM (
    SELECT 
        U_BookingNumber, U_SAPClient, U_BookingDate
    FROM [dbo].[@PCTP_POD] WITH(NOLOCK)
) POD
LEFT JOIN (
    SELECT 
        U_BookingId, U_GrossClientRates
    FROM [dbo].[@PCTP_PRICING] WITH(NOLOCK)
) PRICING ON PRICING.U_BookingId = POD.U_BookingNumber
LEFT JOIN (SELECT CardCode, VatStatus FROM OCRD WITH(NOLOCK)) client ON POD.U_SAPClient = client.CardCode
WHERE CAST(POD.U_BookingDate AS DATE) >= @FromDate
AND CAST(POD.U_BookingDate AS DATE) <= @ToDate;

DECLARE @GrossTruckerRatesTax TABLE(id nvarchar(100), value float);
INSERT INTO @GrossTruckerRatesTax
SELECT DISTINCT
    POD.U_BookingNumber as id,
    CASE
        WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN PRICING.U_GrossTruckerRates
        WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN (PRICING.U_GrossTruckerRates / 1.12)
    END as value
FROM (
    SELECT 
        U_BookingNumber, U_SAPTrucker, U_BookingDate
    FROM [dbo].[@PCTP_POD] WITH(NOLOCK)
) POD
LEFT JOIN (
    SELECT 
        U_BookingId, U_GrossTruckerRates
    FROM [dbo].[@PCTP_PRICING] WITH(NOLOCK)
) PRICING ON PRICING.U_BookingId = POD.U_BookingNumber
LEFT JOIN (SELECT CardCode, VatStatus FROM OCRD WITH(NOLOCK)) trucker ON POD.U_SAPTrucker = trucker.CardCode
WHERE CAST(POD.U_BookingDate AS DATE) >= @FromDate
AND CAST(POD.U_BookingDate AS DATE) <= @ToDate;

DECLARE @TotalInitialClient TABLE(id nvarchar(100), value float);
INSERT INTO @TotalInitialClient
SELECT DISTINCT
    POD.U_BookingNumber as id,
    CASE
        WHEN ISNULL(client.VatStatus,'Y') = 'Y' THEN 
            (ISNULL(PRICING.U_AddtlDrop, 0) + ISNULL(PRICING.U_BoomTruck, 0) + ISNULL(PRICING.U_Manpower, 0) + ISNULL(PRICING.U_Backload, 0))
        WHEN ISNULL(client.VatStatus,'Y') = 'N' THEN 
            ((ISNULL(PRICING.U_AddtlDrop, 0) + ISNULL(PRICING.U_BoomTruck, 0) + ISNULL(PRICING.U_Manpower, 0) + ISNULL(PRICING.U_Backload, 0)) / 1.12)
    END 
    + (SELECT value FROM @GrossClientRatesTax WHERE id = POD.U_BookingNumber)
    + CASE
        WHEN ISNULL(client.VatStatus,'Y') = 'Y' THEN ISNULL(PRICING.U_Demurrage, 0)
        WHEN ISNULL(client.VatStatus,'Y') = 'N' THEN (ISNULL(PRICING.U_Demurrage, 0) / 1.12)
    END as value
FROM (
    SELECT 
        U_BookingNumber, U_SAPClient, U_BookingDate
    FROM [dbo].[@PCTP_POD] WITH(NOLOCK)
) POD
LEFT JOIN (
    SELECT 
        U_BookingId, 
        U_AddtlDrop, U_BoomTruck, U_Manpower, U_Backload,
        U_GrossClientRates, U_Demurrage
    FROM [dbo].[@PCTP_PRICING] WITH(NOLOCK)
) PRICING ON PRICING.U_BookingId = POD.U_BookingNumber
LEFT JOIN (SELECT CardCode, VatStatus FROM OCRD WITH(NOLOCK)) client ON POD.U_SAPClient = client.CardCode
WHERE CAST(POD.U_BookingDate AS DATE) >= @FromDate
AND CAST(POD.U_BookingDate AS DATE) <= @ToDate;

DECLARE @TotalInitialTruckers TABLE(id nvarchar(100), value float);
INSERT INTO @TotalInitialTruckers
SELECT DISTINCT
    POD.U_BookingNumber as id,
    (SELECT value FROM @GrossTruckerRatesTax WHERE id = POD.U_BookingNumber) 
    + CASE
        WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN ISNULL(PRICING.U_Demurrage2, 0)
        WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN (ISNULL(PRICING.U_Demurrage2, 0) / 1.12)
    END + CASE
        WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN (ISNULL(PRICING.U_AddtlDrop2, 0) + ISNULL(PRICING.U_BoomTruck2, 0) + ISNULL(PRICING.U_Manpower2, 0) + ISNULL(PRICING.U_Backload2, 0))
        WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN ((ISNULL(PRICING.U_AddtlDrop2, 0) + ISNULL(PRICING.U_BoomTruck2, 0) + ISNULL(PRICING.U_Manpower2, 0) + ISNULL(PRICING.U_Backload2, 0)) / 1.12)
    END as value
FROM (
    SELECT 
        U_BookingNumber, U_SAPTrucker, U_BookingDate
    FROM [dbo].[@PCTP_POD] WITH(NOLOCK)
) POD
LEFT JOIN (
    SELECT 
        U_BookingId, 
        U_GrossTruckerRates, U_Demurrage2,
        U_AddtlDrop2, U_BoomTruck2, U_Manpower2, U_Backload2
    FROM [dbo].[@PCTP_PRICING] WITH(NOLOCK)
) PRICING ON PRICING.U_BookingId = POD.U_BookingNumber
LEFT JOIN (SELECT CardCode, VatStatus FROM OCRD WITH(NOLOCK)) trucker ON POD.U_SAPTrucker = trucker.CardCode
WHERE CAST(POD.U_BookingDate AS DATE) >= @FromDate
AND CAST(POD.U_BookingDate AS DATE) <= @ToDate;

DECLARE @PODSubmitDeadline TABLE(id nvarchar(100), value date);
INSERT INTO @PODSubmitDeadline
SELECT DISTINCT
    POD.U_BookingNumber as id,
    dbo.computePODSubmitDeadline(
        POD.U_DeliveryDateDTR,
        ISNULL(client.U_CDC,0)
    ) as value
FROM (
    SELECT 
        U_BookingNumber, U_DeliveryDateDTR, U_SAPClient, U_BookingDate
    FROM [dbo].[@PCTP_POD] WITH(NOLOCK)
) POD
LEFT JOIN (SELECT CardCode, U_CDC FROM OCRD WITH(NOLOCK)) client ON POD.U_SAPClient = client.CardCode
WHERE CAST(POD.U_BookingDate AS DATE) >= @FromDate
AND CAST(POD.U_BookingDate AS DATE) <= @ToDate;

DECLARE @OverdueDays TABLE(id nvarchar(100), value int);
INSERT INTO @OverdueDays
SELECT DISTINCT
    POD.U_BookingNumber as id,
    dbo.computeOverdueDays(
        POD.U_ActualHCRecDate,
        (SELECT value FROM @PODSubmitDeadline WHERE id = POD.U_BookingNumber),
        ISNULL(POD.U_HolidayOrWeekend, 0)
    ) as value
FROM (
    SELECT 
        U_BookingNumber, U_ActualHCRecDate, U_HolidayOrWeekend, U_BookingDate
    FROM [dbo].[@PCTP_POD] WITH(NOLOCK)
) POD
WHERE CAST(POD.U_BookingDate AS DATE) >= @FromDate
AND CAST(POD.U_BookingDate AS DATE) <= @ToDate;

DECLARE @PODStatusPayment TABLE(id nvarchar(100), value nvarchar(6));
INSERT INTO @PODStatusPayment
SELECT DISTINCT
    POD.U_BookingNumber as id,
    dbo.computePODStatusPayment(
        (SELECT value FROM @OverdueDays WHERE id = POD.U_BookingNumber)
    ) as value
FROM (
    SELECT 
        U_BookingNumber, U_BookingDate
    FROM [dbo].[@PCTP_POD] WITH(NOLOCK)
) POD
WHERE CAST(POD.U_BookingDate AS DATE) >= @FromDate
AND CAST(POD.U_BookingDate AS DATE) <= @ToDate;

DECLARE @LostPenaltyCalc TABLE(id nvarchar(100), value float);
INSERT INTO @LostPenaltyCalc
SELECT DISTINCT
    POD.U_BookingNumber as id,
    dbo.computeLostPenaltyCalc(
        (SELECT value FROM @PODStatusPayment WHERE id = POD.U_BookingNumber),
        POD.U_InitialHCRecDate,
        POD.U_DeliveryDateDTR,
        (SELECT value FROM @TotalInitialTruckers WHERE id = POD.U_BookingNumber)
    ) as value
FROM (
    SELECT 
        U_BookingNumber, U_SAPTrucker, U_InitialHCRecDate, U_DeliveryDateDTR, U_BookingDate
    FROM [dbo].[@PCTP_POD] WITH(NOLOCK)
) POD
LEFT JOIN (
    SELECT 
        U_BookingId, 
        U_GrossTruckerRates, 
        U_Demurrage2, 
        U_AddtlDrop2, U_BoomTruck2, U_Manpower2, U_Backload2
    FROM [dbo].[@PCTP_PRICING] WITH(NOLOCK)
) PRICING ON PRICING.U_BookingId = POD.U_BookingNumber
LEFT JOIN (SELECT CardCode, VatStatus FROM OCRD WITH(NOLOCK)) trucker ON POD.U_SAPTrucker = trucker.CardCode
WHERE CAST(POD.U_BookingDate AS DATE) >= @FromDate
AND CAST(POD.U_BookingDate AS DATE) <= @ToDate;

DECLARE @ClientSubOverdue TABLE(id nvarchar(100), value int);
INSERT INTO @ClientSubOverdue
SELECT DISTINCT
    POD.U_BookingNumber as id,
    dbo.computeClientSubOverdue(
        POD.U_DeliveryDateDTR,
        POD.U_ClientReceivedDate,
        ISNULL(POD.U_WaivedDays, 0),
        CAST(ISNULL(client.U_DCD,0) as int)
    ) as value
FROM (
    SELECT 
        U_BookingNumber, U_DeliveryDateDTR, U_ClientReceivedDate, U_WaivedDays, U_SAPClient, U_BookingDate
    FROM [dbo].[@PCTP_POD] WITH(NOLOCK)
) POD
LEFT JOIN (SELECT CardCode, U_DCD FROM OCRD WITH(NOLOCK)) client ON POD.U_SAPClient = client.CardCode
WHERE CAST(POD.U_BookingDate AS DATE) >= @FromDate
AND CAST(POD.U_BookingDate AS DATE) <= @ToDate;

DECLARE @ClientPenaltyCalc TABLE(id nvarchar(100), value float);
INSERT INTO @ClientPenaltyCalc
SELECT DISTINCT
    POD.U_BookingNumber as id,
    dbo.computeClientPenaltyCalc(
        (SELECT value FROM @ClientSubOverdue WHERE id = POD.U_BookingNumber)
    ) as value
FROM (
    SELECT 
        U_BookingNumber, U_BookingDate
    FROM [dbo].[@PCTP_POD] WITH(NOLOCK)
) POD
WHERE CAST(POD.U_BookingDate AS DATE) >= @FromDate
AND CAST(POD.U_BookingDate AS DATE) <= @ToDate;

DECLARE @InteluckPenaltyCalc TABLE(id nvarchar(100), value int);
INSERT INTO @InteluckPenaltyCalc
SELECT DISTINCT
    POD.U_BookingNumber as id,
    dbo.computeInteluckPenaltyCalc(
        (SELECT value FROM @PODStatusPayment WHERE id = POD.U_BookingNumber),
        (SELECT value FROM @OverdueDays WHERE id = POD.U_BookingNumber)
    ) as value
FROM (
    SELECT 
        U_BookingNumber, U_BookingDate
    FROM [dbo].[@PCTP_POD] WITH(NOLOCK)
) POD
WHERE CAST(POD.U_BookingDate AS DATE) >= @FromDate
AND CAST(POD.U_BookingDate AS DATE) <= @ToDate;

DECLARE @TotalSubPenalties TABLE(id nvarchar(100), value float);
INSERT INTO @TotalSubPenalties
SELECT DISTINCT
    POD.U_BookingNumber as id,
    dbo.computeTotalSubPenalties(
        (SELECT value FROM @ClientPenaltyCalc WHERE id = POD.U_BookingNumber),
        (SELECT value FROM @InteluckPenaltyCalc WHERE id = POD.U_BookingNumber),
        (SELECT value FROM @LostPenaltyCalc WHERE id = POD.U_BookingNumber),
        ISNULL(POD.U_PenaltiesManual,0)
    ) as value
FROM (
    SELECT 
        U_BookingNumber, U_PenaltiesManual, U_BookingDate
    FROM [dbo].[@PCTP_POD] WITH(NOLOCK)
) POD
WHERE CAST(POD.U_BookingDate AS DATE) >= @FromDate
AND CAST(POD.U_BookingDate AS DATE) <= @ToDate;

DECLARE @TotalPenaltyWaived TABLE(id nvarchar(100), value float);
INSERT INTO @TotalPenaltyWaived
SELECT DISTINCT
    POD.U_BookingNumber as id,
    dbo.computeTotalPenaltyWaived(
        (SELECT value FROM @TotalSubPenalties WHERE id = POD.U_BookingNumber),
        ISNULL(POD.U_PercPenaltyCharge,0)
    ) as value
FROM (
    SELECT 
        U_BookingNumber, U_BookingDate, U_PercPenaltyCharge
    FROM [dbo].[@PCTP_POD] WITH(NOLOCK)
) POD
WHERE CAST(POD.U_BookingDate AS DATE) >= @FromDate
AND CAST(POD.U_BookingDate AS DATE) <= @ToDate;

SELECT DISTINCT
    POD.U_BookingNumber,
    (SELECT value FROM @GrossClientRatesTax WHERE id = POD.U_BookingNumber)  as U_GrossClientRatesTax,
    (SELECT value FROM @GrossTruckerRatesTax WHERE id = POD.U_BookingNumber) as U_GrossTruckerRatesTax, --U_GrossTruckerRatesN
    (SELECT value FROM @GrossClientRatesTax WHERE id = POD.U_BookingNumber) 
    - (SELECT value FROM @GrossTruckerRatesTax WHERE id = POD.U_BookingNumber) as U_GrossProfitNet,
    (SELECT value FROM @TotalInitialClient WHERE id = POD.U_BookingNumber) as U_TotalInitialClient,
    (SELECT value FROM @TotalInitialTruckers WHERE id = POD.U_BookingNumber) as U_TotalInitialTruckers,
    (SELECT value FROM @TotalInitialClient WHERE id = POD.U_BookingNumber) 
    - (SELECT value FROM @TotalInitialTruckers WHERE id = POD.U_BookingNumber) as U_TotalGrossProfit,
    (SELECT value FROM @LostPenaltyCalc WHERE id = POD.U_BookingNumber) as U_LostPenaltyCalc,
    (SELECT value FROM @TotalSubPenalties WHERE id = POD.U_BookingNumber) as U_TotalSubPenalties,
    ABS((SELECT value FROM @TotalSubPenalties WHERE id = POD.U_BookingNumber)) 
    - (SELECT value FROM @TotalPenaltyWaived WHERE id = POD.U_BookingNumber) as U_TotalPenalty
INTO TMP_TARGET_20230915
FROM (
    SELECT 
        U_BookingNumber, U_BookingDate
    FROM [dbo].[@PCTP_POD] WITH(NOLOCK)
) POD
WHERE CAST(POD.U_BookingDate AS DATE) >= @FromDate
AND CAST(POD.U_BookingDate AS DATE) <= @ToDate;

-------->>SUMMARY_EXTRACT

UPDATE SUMMARY_EXTRACT
SET 
    U_GrossClientRatesTax = TMP.U_GrossClientRatesTax,
    U_GrossTruckerRatesTax = TMP.U_GrossTruckerRatesTax,
    U_GrossProfitNet = TMP.U_GrossProfitNet,
    U_TotalInitialClient = TMP.U_TotalInitialClient,
    U_TotalInitialTruckers = TMP.U_TotalInitialTruckers,
    U_TotalGrossProfit = TMP.U_TotalGrossProfit
FROM TMP_TARGET_20230915 TMP
WHERE TMP.U_BookingNumber = SUMMARY_EXTRACT.U_BookingNumber

-------->>POD_EXTRACT

UPDATE POD_EXTRACT
SET 
    U_LostPenaltyCalc = TMP.U_LostPenaltyCalc,
    U_TotalSubPenalties = TMP.U_TotalSubPenalties
FROM TMP_TARGET_20230915 TMP
WHERE TMP.U_BookingNumber = POD_EXTRACT.U_BookingNumber

-------->>BILLING_EXTRACT

UPDATE BILLING_EXTRACT
SET 
    U_GrossInitialRate = TMP.U_GrossClientRatesTax
FROM TMP_TARGET_20230915 TMP
WHERE TMP.U_BookingNumber = BILLING_EXTRACT.U_BookingNumber

-------->>TP_EXTRACT

UPDATE TP_EXTRACT
SET 
    U_GrossTruckerRatesN = TMP.U_GrossTruckerRatesTax,
    U_TotalInitialTruckers = TMP.U_TotalInitialTruckers,
    U_LostPenaltyCalc = TMP.U_LostPenaltyCalc,
    U_TotalSubPenalty = TMP.U_TotalSubPenalties,
    U_TotalPenalty = TMP.U_TotalPenalty
FROM TMP_TARGET_20230915 TMP
WHERE TMP.U_BookingNumber = TP_EXTRACT.U_BookingNumber

-------->>PRICING_EXTRACT

UPDATE PRICING_EXTRACT
SET 
    U_GrossClientRatesTax = TMP.U_GrossClientRatesTax,
    U_GrossTruckerRatesTax = TMP.U_GrossTruckerRatesTax,
    U_GrossProfitNet = TMP.U_GrossProfitNet,
    U_TotalInitialClient = TMP.U_TotalInitialClient,
    U_TotalInitialTruckers = TMP.U_TotalInitialTruckers,
    U_TotalGrossProfit = TMP.U_TotalGrossProfit
FROM TMP_TARGET_20230915 TMP
WHERE TMP.U_BookingNumber = PRICING_EXTRACT.U_BookingNumber

-------->>DELETING TMP_TARGET_20230915

DROP TABLE IF EXISTS TMP_TARGET_20230915