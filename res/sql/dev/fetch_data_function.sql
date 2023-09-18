IF (OBJECT_ID('fetchPctpDataRows') IS NOT NULL)
    DROP FUNCTION [dbo].fetchPctpDataRows
GO

CREATE FUNCTION [dbo].fetchPctpDataRows(
    @TabName nvarchar(20),   
    @BookingIds nvarchar(max),   
    @AccessColumns nvarchar(30) = 'ALL' 
)
RETURNS @T TABLE(
    Code nvarchar(500),
    DisableTableRow nvarchar(5),
    DisableSomeFields nvarchar(30),
    DisableSomeFields2 nvarchar(30),
    U_BookingDate DATETIME,
    U_BookingNumber nvarchar(500),
    U_BookingId nvarchar(500),
    U_PODNum nvarchar(500),
    U_PODSONum nvarchar(500),
    U_CustomerName nvarchar(500),
    U_GrossClientRates nvarchar(500), -- NUMERIC(19,6)
    U_GrossInitialRate nvarchar(500),
    U_Demurrage nvarchar(500),
    U_AddtlDrop nvarchar(500),
    U_BoomTruck nvarchar(500),
    U_BoomTruck2 nvarchar(500),
    U_TPBoomTruck2 nvarchar(500),
    U_Manpower nvarchar(500),
    U_BackLoad nvarchar(500),
    U_TotalAddtlCharges nvarchar(500),
    U_Demurrage2 nvarchar(500),
    U_AddtlDrop2 nvarchar(500),
    U_Manpower2 nvarchar(500),
    U_Backload2 nvarchar(500),
    U_totalAddtlCharges2 nvarchar(500),
    U_Demurrage3 nvarchar(500),
    U_GrossProfit nvarchar(500),
    U_Addtlcharges nvarchar(500),
    U_DemurrageN nvarchar(500),
    U_AddtlChargesN nvarchar(500),
    U_ActualRates nvarchar(500),
    U_RateAdjustments nvarchar(500),
    U_TPRateAdjustments nvarchar(500),
    U_ActualDemurrage nvarchar(500),
    U_TPActualDemurrage nvarchar(500),
    U_ActualCharges nvarchar(500),
    U_OtherCharges nvarchar(500),
    U_AddCharges nvarchar(500),
    U_ActualBilledRate nvarchar(500),
    U_BillingRateAdjustments nvarchar(500),
    U_BillingActualDemurrage nvarchar(500),
    U_ActualAddCharges nvarchar(500),
    U_GrossClientRatesTax nvarchar(500),
    U_GrossTruckerRates nvarchar(500),
    U_RateBasis nvarchar(50),
    U_GrossTruckerRatesN nvarchar(500),
    U_TaxType nvarchar(50),
    U_GrossTruckerRatesTax nvarchar(500),
    U_RateBasisT nvarchar(50),
    U_TaxTypeT nvarchar(50),
    U_Demurrage4 nvarchar(500),
    U_AddtlCharges2 nvarchar(500),
    U_GrossProfitC nvarchar(500),
    U_GrossProfitNet nvarchar(500),
    U_TotalInitialClient nvarchar(500),
    U_TotalInitialTruckers nvarchar(500),
    U_TotalGrossProfit nvarchar(500),
    U_ClientTag2 nvarchar(100),
    U_ClientName nvarchar(500),
    U_SAPClient nvarchar(500),
    U_ClientTag nvarchar(500),
    U_ClientProject nvarchar(100),
    U_ClientVatStatus nvarchar(20),
    U_TruckerName nvarchar(500),
    U_TruckerSAP nvarchar(500),
    U_TruckerTag nvarchar(500),
    U_TruckerVatStatus nvarchar(20),
    U_TPStatus nvarchar(500),
    U_Aging DATETIME,
    U_ISLAND nvarchar(50),
    U_ISLAND_D nvarchar(50),
    U_IFINTERISLAND nvarchar(10),
    U_VERIFICATION_TAT nvarchar(50),
    U_POD_TAT nvarchar(50),
    U_ActualDateRec_Intitial DATETIME,
    U_SAPTrucker nvarchar(100),
    U_PlateNumber nvarchar(50),
    U_VehicleTypeCap nvarchar(50),
    U_DeliveryStatus nvarchar(50),
    U_DeliveryDateDTR DATETIME,
    U_DeliveryDatePOD DATETIME,
    U_NoOfDrops nvarchar(500),
    U_TripType nvarchar(100),
    U_Receivedby nvarchar(100),
    U_ClientReceivedDate DATETIME,
    U_InitialHCRecDate DATETIME,
    U_ActualHCRecDate DATETIME,
    U_DateReturned DATETIME,
    U_PODinCharge nvarchar(100),
    U_VerifiedDateHC DATETIME,
    U_PTFNo nvarchar(100),
    U_DateForwardedBT DATETIME,
    U_BillingDeadline DATETIME,
    U_BillingStatus nvarchar(100),
    U_SINo nvarchar(100),
    U_BillingTeam nvarchar(100),
    U_SOBNumber nvarchar(100),
    U_ForwardLoad nvarchar(100),
    U_TypeOfAccessorial nvarchar(50),
    U_TimeInEmptyDem nvarchar(50),
    U_TimeOutEmptyDem nvarchar(50),
    U_VerifiedEmptyDem nvarchar(50),
    U_TimeInLoadedDem nvarchar(50),
    U_TimeOutLoadedDem nvarchar(50),
    U_VerifiedLoadedDem nvarchar(50),
    U_TimeInAdvLoading nvarchar(50),
    U_PenaltiesManual nvarchar(500),
    U_DayOfTheWeek nvarchar(50),
    U_TimeIn nvarchar(50),
    U_TimeOut nvarchar(50),
    U_TotalExceed nvarchar(500),
    U_TotalNoExceed nvarchar(500),
    U_ODOIn nvarchar(50),
    U_ODOOut nvarchar(50),
    U_TotalUsage nvarchar(500),
    U_ClientSubStatus nvarchar(50),
    U_ClientSubOverdue nvarchar(50),
    U_ClientPenaltyCalc nvarchar(50),
    U_PODStatusPayment nvarchar(50),
    U_ProofOfPayment nvarchar(50),
    U_TotalRecClients nvarchar(500),
    U_CheckingTotalBilled nvarchar(500),
    U_Checking nvarchar(500),
    U_CWT2307 nvarchar(500),
    U_SOLineNum nvarchar(10),
    U_ARInvLineNum nvarchar(10),
    U_TotalPayable nvarchar(500),
    U_TotalSubPenalty nvarchar(500),
    U_PVNo nvarchar(500),
    U_TPincharge nvarchar(500),
    U_CAandDP nvarchar(500),
    U_Interest nvarchar(500),
    U_OtherDeductions nvarchar(500),
    U_TOTALDEDUCTIONS nvarchar(500),
    U_REMARKS1 nvarchar(500),
    U_TotalAR nvarchar(500),
    U_VarAR nvarchar(500),
    U_TotalAP nvarchar(500),
    U_VarTP nvarchar(500),
    U_APInvLineNum nvarchar(10),
    U_PODSubmitDeadline DATETIME,
    U_OverdueDays nvarchar(25),
    U_InteluckPenaltyCalc nvarchar(50),
    U_WaivedDays nvarchar(50),
    U_HolidayOrWeekend nvarchar(50),
    U_EWT2307 nvarchar(500),
    U_LostPenaltyCalc nvarchar(50),
    U_TotalSubPenalties nvarchar(50),
    U_Waived nvarchar(50),
    U_PercPenaltyCharge nvarchar(50),
    U_Approvedby nvarchar(100),
    U_TotalPenaltyWaived nvarchar(50),
    U_TotalPenalty nvarchar(500),
    U_TotalPayableRec nvarchar(500),
    U_APDocNum nvarchar(50),
    U_ServiceType nvarchar(500),
    U_InvoiceNo nvarchar(500),
    U_ARDocNum nvarchar(500),
    U_DocNum nvarchar(500),
    U_Paid nvarchar(500),
    U_ORRefNo nvarchar(500),
    U_ActualPaymentDate nvarchar(500),
    U_PaymentReference nvarchar(500),
    U_PaymentStatus nvarchar(500),
    U_Remarks nvarchar(500),
    U_GroupProject nvarchar(500),
    U_Attachment nvarchar(500),
    U_DeliveryOrigin nvarchar(500),
    U_Destination nvarchar(500),
    U_OtherPODDoc nvarchar(1000),
    U_RemarksPOD nvarchar(500),
    U_PODStatusDetail nvarchar(500),
    U_BTRemarks nvarchar(500),
    U_DestinationClient nvarchar(500),
    U_Remarks2 nvarchar(500),
    U_TripTicketNo nvarchar(500),
    U_WaybillNo nvarchar(500),
    U_ShipmentNo nvarchar(500),
    U_ShipmentManifestNo nvarchar(500),
    U_DeliveryReceiptNo nvarchar(500),
    U_SeriesNo nvarchar(500),
    U_OutletNo nvarchar(500),
    U_CBM nvarchar(500),
    U_SI_DRNo nvarchar(500),
    U_DeliveryMode nvarchar(500),
    U_SourceWhse nvarchar(500),
    U_SONo nvarchar(500),
    U_NameCustomer nvarchar(500),
    U_CategoryDR nvarchar(500),
    U_IDNumber nvarchar(500),
    U_ApprovalStatus nvarchar(500),
    U_Status nvarchar(500),
    U_RemarksDTR nvarchar(500),
    U_TotalInvAmount nvarchar(500),
    U_PODDocNum nvarchar(500)
)
AS
BEGIN
    --BOOKING IDS
    DECLARE @BookingIdList TABLE(item nvarchar(500));
    INSERT INTO @BookingIdList
    SELECT 
    RTRIM(LTRIM(value)) AS item
    FROM STRING_SPLIT(@BookingIds, ',');

    --ACCESS COLUMNS
    DECLARE @AccessColumnList TABLE(item nvarchar(500));
    INSERT INTO @AccessColumnList
    SELECT 
    RTRIM(LTRIM(value)) AS item
    FROM STRING_SPLIT(@AccessColumns, ',');

    --VARIABLES
    DECLARE @ClientSubOverdue TABLE(id nvarchar(100), value int);
    INSERT INTO @ClientSubOverdue
    SELECT DISTINCT
        POD.U_BookingNumber as id,
        CASE
            WHEN @TabName = 'SUMMARY' OR @TabName = 'POD' OR @TabName = 'TP' OR @TabName = 'PRICING' THEN
                dbo.computeClientSubOverdue(
                    POD.U_DeliveryDateDTR,
                    POD.U_ClientReceivedDate,
                    ISNULL(POD.U_WaivedDays, 0),
                    CAST(ISNULL(client.U_DCD,0) as int)
                )
            ELSE NULL
        END as value
    FROM (
        SELECT 
            U_BookingNumber, U_DeliveryDateDTR, U_ClientReceivedDate, U_WaivedDays, U_SAPClient
        FROM [dbo].[@PCTP_POD] WITH(NOLOCK)
    ) POD
    LEFT JOIN (SELECT CardCode, U_DCD FROM OCRD WITH(NOLOCK)) client ON POD.U_SAPClient = client.CardCode
    WHERE POD.U_BookingNumber IN (SELECT item FROM @BookingIdList);

    DECLARE @ClientPenaltyCalc TABLE(id nvarchar(100), value float);
    INSERT INTO @ClientPenaltyCalc
    SELECT DISTINCT
        POD.U_BookingNumber as id,
        CASE
            WHEN @TabName = 'SUMMARY' OR @TabName = 'POD' OR @TabName = 'TP' OR @TabName = 'PRICING' THEN
                dbo.computeClientPenaltyCalc(
                    (SELECT value FROM @ClientSubOverdue WHERE id = POD.U_BookingNumber)
                )
            ELSE NULL
        END as value
    FROM (
        SELECT 
            U_BookingNumber
        FROM [dbo].[@PCTP_POD] WITH(NOLOCK)
    ) POD 
    WHERE POD.U_BookingNumber IN (SELECT item FROM @BookingIdList);

    DECLARE @PODSubmitDeadline TABLE(id nvarchar(100), value date);
    INSERT INTO @PODSubmitDeadline
    SELECT DISTINCT
        POD.U_BookingNumber as id,
        CASE
            WHEN @TabName = 'SUMMARY' OR @TabName = 'TP' OR @TabName = 'PRICING' THEN
                dbo.computePODSubmitDeadline(
                    POD.U_DeliveryDateDTR,
                    ISNULL(client.U_CDC,0)
                )
            ELSE NULL
        END as value
    FROM (
        SELECT 
            U_BookingNumber, U_DeliveryDateDTR, U_SAPClient
        FROM [dbo].[@PCTP_POD] WITH(NOLOCK)
    ) POD
    LEFT JOIN (SELECT CardCode, U_CDC FROM OCRD WITH(NOLOCK)) client ON POD.U_SAPClient = client.CardCode
    WHERE POD.U_BookingNumber IN (SELECT item FROM @BookingIdList);

    DECLARE @OverdueDays TABLE(id nvarchar(100), value int);
    INSERT INTO @OverdueDays
    SELECT DISTINCT
        POD.U_BookingNumber as id,
        CASE
            WHEN @TabName = 'SUMMARY' OR @TabName = 'POD' OR @TabName = 'TP' OR @TabName = 'PRICING' THEN
                dbo.computeOverdueDays(
                    POD.U_ActualHCRecDate,
                    (SELECT value FROM @PODSubmitDeadline WHERE id = POD.U_BookingNumber),
                    ISNULL(POD.U_HolidayOrWeekend, 0)
                )
            ELSE NULL
        END as value
    FROM (
        SELECT 
            U_BookingNumber, U_ActualHCRecDate, U_HolidayOrWeekend
        FROM [dbo].[@PCTP_POD] WITH(NOLOCK)
    ) POD
    WHERE POD.U_BookingNumber IN (SELECT item FROM @BookingIdList);

    DECLARE @PODStatusPayment TABLE(id nvarchar(100), value nvarchar(6));
    INSERT INTO @PODStatusPayment
    SELECT DISTINCT
        POD.U_BookingNumber as id,
        CASE
            WHEN @TabName = 'SUMMARY' OR @TabName = 'POD' OR @TabName = 'TP' OR @TabName = 'PRICING' THEN
                dbo.computePODStatusPayment(
                    (SELECT value FROM @OverdueDays WHERE id = POD.U_BookingNumber)
                )
            ELSE NULL
        END as value
    FROM (
        SELECT 
            U_BookingNumber
        FROM [dbo].[@PCTP_POD] WITH(NOLOCK)
    ) POD
    WHERE POD.U_BookingNumber IN (SELECT item FROM @BookingIdList);

    DECLARE @InteluckPenaltyCalc TABLE(id nvarchar(100), value float);
    INSERT INTO @InteluckPenaltyCalc
    SELECT DISTINCT
        POD.U_BookingNumber as id,
        CASE
            WHEN @TabName = 'SUMMARY' OR @TabName = 'POD' OR @TabName = 'TP' OR @TabName = 'PRICING' THEN
                dbo.computeInteluckPenaltyCalc(
                    (SELECT value FROM @PODStatusPayment WHERE id = POD.U_BookingNumber),
                    (SELECT value FROM @OverdueDays WHERE id = POD.U_BookingNumber)
                )
            ELSE NULL
        END as value
    FROM (
        SELECT 
            U_BookingNumber
        FROM [dbo].[@PCTP_POD] WITH(NOLOCK)
    ) POD
    WHERE POD.U_BookingNumber IN (SELECT item FROM @BookingIdList);

    DECLARE @GrossClientRatesTax TABLE(id nvarchar(100), value float);
    INSERT INTO @GrossClientRatesTax
    SELECT DISTINCT
        POD.U_BookingNumber as id,
        CASE
            WHEN @TabName = 'SUMMARY' OR @TabName = 'BILLING' OR @TabName = 'PRICING' THEN
                CASE
                    WHEN ISNULL(client.VatStatus,'Y') = 'Y' THEN PRICING.U_GrossClientRates
                    WHEN ISNULL(client.VatStatus,'Y') = 'N' THEN (PRICING.U_GrossClientRates / 1.12)
                END 
            ELSE NULL
        END as value
    FROM (
        SELECT 
            U_BookingNumber, U_SAPClient
        FROM [dbo].[@PCTP_POD] WITH(NOLOCK)
    ) POD
    LEFT JOIN (
        SELECT 
            U_BookingId, U_GrossClientRates
        FROM [dbo].[@PCTP_PRICING] WITH(NOLOCK)
    ) PRICING ON PRICING.U_BookingId = POD.U_BookingNumber
    LEFT JOIN (SELECT CardCode, VatStatus FROM OCRD WITH(NOLOCK)) client ON POD.U_SAPClient = client.CardCode
    WHERE POD.U_BookingNumber IN (SELECT item FROM @BookingIdList);

    DECLARE @GrossTruckerRatesTax TABLE(id nvarchar(100), value float);
    INSERT INTO @GrossTruckerRatesTax
    SELECT DISTINCT
        POD.U_BookingNumber as id,
        CASE
            WHEN @TabName = 'SUMMARY' OR @TabName = 'POD' OR @TabName = 'TP' OR @TabName = 'PRICING' THEN
                CASE
                    WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN PRICING.U_GrossTruckerRates
                    WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN (PRICING.U_GrossTruckerRates / 1.12)
                END
            ELSE NULL
        END as value
    FROM (
        SELECT 
            U_BookingNumber, U_SAPTrucker
        FROM [dbo].[@PCTP_POD] WITH(NOLOCK)
    ) POD
    LEFT JOIN (
        SELECT 
            U_BookingId, U_GrossTruckerRates
        FROM [dbo].[@PCTP_PRICING] WITH(NOLOCK)
    ) PRICING ON PRICING.U_BookingId = POD.U_BookingNumber
    LEFT JOIN (SELECT CardCode, VatStatus FROM OCRD WITH(NOLOCK)) trucker ON POD.U_SAPTrucker = trucker.CardCode
    WHERE POD.U_BookingNumber IN (SELECT item FROM @BookingIdList);

    DECLARE @TotalAddtlCharges TABLE(id nvarchar(100), value float);
    INSERT INTO @TotalAddtlCharges
    SELECT DISTINCT
        POD.U_BookingNumber as id,
        CASE
            WHEN @TabName = 'PRICING' OR @TabName = 'BILLING' THEN
                (
                    ISNULL(PRICING.U_AddtlDrop, 0) 
                    + ISNULL(PRICING.U_BoomTruck, 0) 
                    + ISNULL(PRICING.U_Manpower, 0) 
                    + ISNULL(PRICING.U_Backload, 0)
                )
            ELSE NULL
        END as value
    FROM (
        SELECT 
            U_BookingNumber
        FROM [dbo].[@PCTP_POD] WITH(NOLOCK)
    ) POD
    LEFT JOIN (
        SELECT 
            U_BookingId, U_AddtlDrop, U_BoomTruck, U_Manpower, U_Backload
        FROM [dbo].[@PCTP_PRICING] WITH(NOLOCK)
    ) PRICING ON PRICING.U_BookingId = POD.U_BookingNumber
    WHERE POD.U_BookingNumber IN (SELECT item FROM @BookingIdList);

    DECLARE @AddtlCharges2 TABLE(id nvarchar(100), value float);
    INSERT INTO @AddtlCharges2
    SELECT DISTINCT
        POD.U_BookingNumber as id,
        CASE
            WHEN @TabName = 'PRICING' THEN
                CASE
                    WHEN ISNULL(client.VatStatus,'Y') = 'Y' THEN 
                        (SELECT value FROM @TotalAddtlCharges WHERE id = POD.U_BookingNumber)
                    WHEN ISNULL(client.VatStatus,'Y') = 'N' THEN 
                        ((SELECT value FROM @TotalAddtlCharges WHERE id = POD.U_BookingNumber) / 1.12)
                END
            ELSE NULL
        END as value
    FROM (
        SELECT 
            U_BookingNumber, U_SAPClient
        FROM [dbo].[@PCTP_POD] WITH(NOLOCK)
    ) POD
    LEFT JOIN (SELECT CardCode, VatStatus FROM OCRD WITH(NOLOCK)) client ON POD.U_SAPClient = client.CardCode
    WHERE POD.U_BookingNumber IN (SELECT item FROM @BookingIdList);

    DECLARE @TotalInitialClient TABLE(id nvarchar(100), value float);
    INSERT INTO @TotalInitialClient
    SELECT DISTINCT
        POD.U_BookingNumber as id,
        CASE
            WHEN @TabName = 'SUMMARY' OR @TabName = 'PRICING' THEN
                (SELECT value FROM @AddtlCharges2 WHERE id = POD.U_BookingNumber) 
                + (SELECT value FROM @GrossClientRatesTax WHERE id = POD.U_BookingNumber)
                + CASE
                    WHEN ISNULL(client.VatStatus,'Y') = 'Y' THEN ISNULL(PRICING.U_Demurrage, 0)
                    WHEN ISNULL(client.VatStatus,'Y') = 'N' THEN (ISNULL(PRICING.U_Demurrage, 0) / 1.12)
                END
            ELSE NULL
        END as value
    FROM (
        SELECT 
            U_BookingNumber, U_SAPClient
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
    WHERE POD.U_BookingNumber IN (SELECT item FROM @BookingIdList);

    DECLARE @TotalInitialTruckers TABLE(id nvarchar(100), value float);
    INSERT INTO @TotalInitialTruckers
    SELECT DISTINCT
        POD.U_BookingNumber as id,
        CASE
            WHEN @TabName = 'SUMMARY' OR @TabName = 'POD' OR @TabName = 'TP' OR @TabName = 'PRICING' THEN
                (SELECT value FROM @GrossTruckerRatesTax WHERE id = POD.U_BookingNumber) 
                + CASE
                    WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN ISNULL(PRICING.U_Demurrage2, 0)
                    WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN (ISNULL(PRICING.U_Demurrage2, 0) / 1.12)
                END + CASE
                    WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN (ISNULL(PRICING.U_AddtlDrop2, 0) + ISNULL(PRICING.U_BoomTruck2, 0) + ISNULL(PRICING.U_Manpower2, 0) + ISNULL(PRICING.U_Backload2, 0))
                    WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN ((ISNULL(PRICING.U_AddtlDrop2, 0) + ISNULL(PRICING.U_BoomTruck2, 0) + ISNULL(PRICING.U_Manpower2, 0) + ISNULL(PRICING.U_Backload2, 0)) / 1.12)
                END
            ELSE NULL
        END as value
    FROM (
        SELECT 
            U_BookingNumber, U_SAPTrucker
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
    WHERE POD.U_BookingNumber IN (SELECT item FROM @BookingIdList);

    DECLARE @LostPenaltyCalc TABLE(id nvarchar(100), value float);
    INSERT INTO @LostPenaltyCalc
    SELECT DISTINCT
        POD.U_BookingNumber as id,
        CASE
            WHEN @TabName = 'SUMMARY' OR @TabName = 'POD' OR @TabName = 'TP' OR @TabName = 'PRICING' THEN
                dbo.computeLostPenaltyCalc(
                    (SELECT value FROM @PODStatusPayment WHERE id = POD.U_BookingNumber),
                    POD.U_InitialHCRecDate,
                    POD.U_DeliveryDateDTR,
                    (SELECT value FROM @TotalInitialTruckers WHERE id = POD.U_BookingNumber)
                )
            ELSE NULL
        END as value
    FROM (
        SELECT 
            U_BookingNumber, U_SAPTrucker, U_InitialHCRecDate, U_DeliveryDateDTR
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
    WHERE POD.U_BookingNumber IN (SELECT item FROM @BookingIdList);

    DECLARE @TotalSubPenalties TABLE(id nvarchar(100), value float);
    INSERT INTO @TotalSubPenalties
    SELECT DISTINCT
        POD.U_BookingNumber as id,
        CASE
            WHEN @TabName = 'SUMMARY' OR @TabName = 'POD' OR @TabName = 'TP' OR @TabName = 'PRICING' THEN
                dbo.computeTotalSubPenalties(
                    (SELECT value FROM @ClientPenaltyCalc WHERE id = POD.U_BookingNumber),
                    (SELECT value FROM @InteluckPenaltyCalc WHERE id = POD.U_BookingNumber),
                    (SELECT value FROM @LostPenaltyCalc WHERE id = POD.U_BookingNumber),
                    ISNULL(POD.U_PenaltiesManual,0)
                )
            ELSE NULL
        END as value
    FROM (
        SELECT 
            U_BookingNumber, U_PenaltiesManual
        FROM [dbo].[@PCTP_POD] WITH(NOLOCK)
    ) POD
    WHERE POD.U_BookingNumber IN (SELECT item FROM @BookingIdList);

    DECLARE @TotalPenaltyWaived TABLE(id nvarchar(100), value float);
    INSERT INTO @TotalPenaltyWaived
    SELECT DISTINCT
        POD.U_BookingNumber as id,
        CASE
            WHEN @TabName = 'SUMMARY' OR @TabName = 'POD' OR @TabName = 'TP' OR @TabName = 'PRICING' THEN
                dbo.computeTotalPenaltyWaived(
                    (SELECT value FROM @TotalSubPenalties WHERE id = POD.U_BookingNumber),
                    ISNULL(POD.U_PercPenaltyCharge,0)
                )
            ELSE NULL
        END as value
    FROM (
        SELECT 
            U_BookingNumber, U_PercPenaltyCharge
        FROM [dbo].[@PCTP_POD] WITH(NOLOCK)
    ) POD
    WHERE POD.U_BookingNumber IN (SELECT item FROM @BookingIdList);

    DECLARE @TotalAR TABLE(id nvarchar(100), value float);
    INSERT INTO @TotalAR
    SELECT DISTINCT
        POD.U_BookingNumber as id,
        CASE
            WHEN @TabName = 'SUMMARY' OR @TabName = 'BILLING' OR @TabName = 'PRICING' THEN
                ISNULL((
                    SELECT
                        SUM(L.PriceAfVAT)
                    FROM OINV H WITH(NOLOCK)
                    LEFT JOIN (SELECT DocEntry, ItemCode, PriceAfVAT FROM INV1 WITH(NOLOCK)) L ON H.DocEntry = L.DocEntry
                    WHERE H.CANCELED = 'N' AND L.ItemCode = POD.U_BookingNumber
                ), 0)
            ELSE NULL
        END as value
    FROM (
        SELECT 
            U_BookingNumber
        FROM [dbo].[@PCTP_POD] WITH(NOLOCK)
    ) POD
    WHERE POD.U_BookingNumber IN (SELECT item FROM @BookingIdList);

    DECLARE @TotalRecClients TABLE(id nvarchar(100), value float);
    INSERT INTO @TotalRecClients
    SELECT DISTINCT
        POD.U_BookingNumber as id,
        CASE
            WHEN @TabName = 'SUMMARY' OR @TabName = 'BILLING' OR @TabName = 'PRICING' THEN
                (
                    CASE
                        WHEN ISNULL(client.VatStatus,'Y') = 'Y' THEN ISNULL(PRICING.U_GrossClientRates, 0)
                        WHEN ISNULL(client.VatStatus,'Y') = 'N' THEN (ISNULL(PRICING.U_GrossClientRates, 0) / 1.12)
                    END
                ) --BILLING.U_GrossInitialRate
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
        END as value
    FROM (
        SELECT 
            U_BookingNumber, U_SAPClient
        FROM [dbo].[@PCTP_POD] WITH(NOLOCK)
    ) POD
    LEFT JOIN (
        SELECT 
            U_BookingId, 
            U_GrossClientRates, 
            U_Demurrage, U_AddtlDrop, U_BoomTruck, U_Manpower, U_Backload
        FROM [dbo].[@PCTP_PRICING] WITH(NOLOCK)
    ) PRICING ON PRICING.U_BookingId = POD.U_BookingNumber
    LEFT JOIN (
        SELECT 
            U_BookingId, 
            U_ActualBilledRate, U_RateAdjustments, U_ActualDemurrage, U_ActualAddCharges
        FROM [dbo].[@PCTP_BILLING] WITH(NOLOCK)
    ) BILLING ON BILLING.U_BookingId = POD.U_BookingNumber
    LEFT JOIN (SELECT CardCode, VatStatus FROM OCRD WITH(NOLOCK)) client ON POD.U_SAPClient = client.CardCode
    WHERE POD.U_BookingNumber IN (SELECT item FROM @BookingIdList);

    DECLARE @TOTALDEDUCTIONS TABLE(id nvarchar(100), value float);
    INSERT INTO @TOTALDEDUCTIONS
    SELECT DISTINCT
        POD.U_BookingNumber as id,
        CASE
            WHEN @TabName = 'SUMMARY' OR @TabName = 'TP' OR @TabName = 'PRICING' THEN
                ISNULL(TP.U_CAandDP,0) + ISNULL(TP.U_Interest,0) + ISNULL(TP.U_OtherDeductions,0) 
                + (ABS(
                    ABS(ISNULL((SELECT value FROM @TotalSubPenalties WHERE id = POD.U_BookingNumber),0)) 
                    - ABS(ISNULL((SELECT value FROM @TotalPenaltyWaived WHERE id = POD.U_BookingNumber),0))
                ))
            ELSE NULL
        END as value
    FROM (
        SELECT 
            U_BookingNumber
        FROM [dbo].[@PCTP_POD] WITH(NOLOCK)
    ) POD
    LEFT JOIN (
        SELECT 
            U_BookingId, 
            U_CAandDP, U_Interest, U_OtherDeductions
        FROM [dbo].[@PCTP_TP] WITH(NOLOCK)
    ) TP ON TP.U_BookingId = POD.U_BookingNumber
    WHERE POD.U_BookingNumber IN (SELECT item FROM @BookingIdList);

    DECLARE @Paid TABLE(id nvarchar(100), value nvarchar(100));
    INSERT INTO @Paid
    SELECT DISTINCT
        POD.U_BookingNumber as id,
        CASE
            WHEN @TabName = 'SUMMARY' OR @TabName = 'TP' OR @TabName = 'PRICING' THEN
                CAST(SUBSTRING((
                            SELECT CONCAT(', ', header.DocNum)  AS [text()]
                FROM (
                    SELECT
                        DocEntry, ItemCode
                    FROM PCH1 WITH (NOLOCK)
                ) line
                    LEFT JOIN (SELECT DocNum, DocEntry, CANCELED, PaidSum, U_PVNo FROM OPCH WITH (NOLOCK)) header ON header.DocEntry = line.DocEntry
                WHERE header.CANCELED = 'N' AND header.PaidSum > 0 AND (line.ItemCode = POD.U_BookingNumber
                    or REPLACE(REPLACE(RTRIM(LTRIM(TP.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%')
                FOR XML PATH (''), TYPE
                        ).value('text()[1]','nvarchar(max)'), 2, 1000) as nvarchar(max))
            ELSE NULL
        END as value
    FROM (
        SELECT 
            U_BookingNumber
        FROM [dbo].[@PCTP_POD] WITH(NOLOCK)
    ) POD
    LEFT JOIN (
        SELECT 
            U_BookingId, U_PVNo
        FROM [dbo].[@PCTP_TP] WITH(NOLOCK)
    ) TP ON TP.U_BookingId = POD.U_BookingNumber
    WHERE POD.U_BookingNumber IN (SELECT item FROM @BookingIdList);

    DECLARE @DocNum TABLE(id nvarchar(100), value nvarchar(100));
    INSERT INTO @DocNum
    SELECT DISTINCT
        POD.U_BookingNumber as id,
        CASE
            WHEN @TabName = 'SUMMARY' OR @TabName = 'TP' OR @TabName = 'PRICING' THEN
                CAST(SUBSTRING((
                            SELECT CONCAT(', ', header.DocNum)  AS [text()]
                FROM (
                    SELECT
                        DocEntry, ItemCode
                    FROM PCH1 WITH (NOLOCK)
                ) line
                    LEFT JOIN (SELECT DocNum, DocEntry, CANCELED, PaidSum, U_PVNo FROM OPCH WITH (NOLOCK)) header ON header.DocEntry = line.DocEntry
                WHERE header.CANCELED = 'N' AND header.PaidSum = 0 AND (line.ItemCode = POD.U_BookingNumber
                    or REPLACE(REPLACE(RTRIM(LTRIM(TP.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(header.U_PVNo)) + '%')
                FOR XML PATH (''), TYPE
                        ).value('text()[1]','nvarchar(max)'), 2, 1000) as nvarchar(max))
            ELSE NULL
        END as value
    FROM (
        SELECT 
            U_BookingNumber
        FROM [dbo].[@PCTP_POD] WITH(NOLOCK)
    ) POD
    LEFT JOIN (
        SELECT 
            U_BookingId, U_PVNo
        FROM [dbo].[@PCTP_TP] WITH(NOLOCK)
    ) TP ON TP.U_BookingId = POD.U_BookingNumber
    WHERE POD.U_BookingNumber IN (SELECT item FROM @BookingIdList);

    DECLARE @TotalPenalty TABLE(id nvarchar(100), value float);
    INSERT INTO @TotalPenalty
    SELECT DISTINCT
        POD.U_BookingNumber as id,
        CASE
            WHEN @TabName = 'TP' THEN
                ABS((SELECT value FROM @TotalSubPenalties WHERE id = POD.U_BookingNumber)) 
                - (SELECT value FROM @TotalPenaltyWaived WHERE id = POD.U_BookingNumber)
            ELSE NULL
        END as value
    FROM (
        SELECT 
            U_BookingNumber
        FROM [dbo].[@PCTP_POD] WITH(NOLOCK)
    ) POD
    WHERE POD.U_BookingNumber IN (SELECT item FROM @BookingIdList);

    DECLARE @1stPV TABLE(id nvarchar(100), value float);
    INSERT INTO @1stPV
    SELECT DISTINCT 
        POD.U_BookingNumber as id,
        CASE
            WHEN @TabName = 'SUMMARY' OR @TabName = 'TP' OR @TabName = 'PRICING' THEN
                ISNULL((
                ISNULL(TRY_PARSE(ratessub.U_Amount AS FLOAT), 0)
                + ISNULL(TP.U_RateAdjustments, 0) 
                + ISNULL(TRY_PARSE(ratessub.U_AddlAmount AS FLOAT), 0)
                ) 
                - 
                (SELECT value FROM @TotalPenalty WHERE id = POD.U_BookingNumber), 0)
            ELSE NULL
        END as value 
    FROM (
        SELECT 
            U_BookingNumber
        FROM [dbo].[@PCTP_POD] WITH(NOLOCK)
    ) POD
    INNER JOIN (
        SELECT
            U_BookingId,
            U_RateAdjustments,
            U_PVNo
        FROM [dbo].[@PCTP_TP] WITH(NOLOCK)
    ) TP ON TP.U_BookingId = POD.U_BookingNumber
    LEFT JOIN [@FirstratesTP] ratessub ON ratessub.U_BN = TP.U_BookingId AND ratessub.U_PVNo = SUBSTRING(TP.U_PVNo, 1, 9)
    WHERE POD.U_BookingNumber IN (SELECT item FROM @BookingIdList);

    DECLARE @2ndPV TABLE(id nvarchar(100), value float);
    INSERT INTO @2ndPV
    SELECT DISTINCT 
        POD.U_BookingNumber as id,
        CASE
            WHEN @TabName = 'SUMMARY' OR @TabName = 'TP' OR @TabName = 'PRICING' THEN
                ISNULL((
                CASE 
                    WHEN T5.U_Rates LIKE '%U_GrossTruckerRates%' THEN 
                    CASE 
                        WHEN ISNULL(trucker.VatStatus, 'Y') = 'Y' THEN PRICING.U_GrossTruckerRates 
                        WHEN ISNULL(trucker.VatStatus, 'Y') = 'N' THEN (PRICING.U_GrossTruckerRates / 1.12) 
                    END 
                    ELSE 0.00 
                END 
                + 
                CASE 
                    WHEN T5.U_Rates LIKE '%U_ActualRates%' THEN ISNULL(NULLIF(CAST(TP.U_ActualRates AS FLOAT), ''), 0) 
                    ELSE 0.00 
                END 
                + 
                CASE 
                    WHEN T5.U_Rates LIKE '%U_RateAdjustments%' THEN ISNULL(NULLIF(CAST(TP.U_RateAdjustments AS FLOAT), ''), 0) 
                    ELSE 0.00 
                END 
                + 
                CASE 
                    WHEN T5.U_Rates LIKE '%U_DemurrageN%' THEN 
                    CASE 
                        WHEN ISNULL(trucker.VatStatus, 'Y') = 'Y' THEN PRICING.U_Demurrage2 
                        WHEN ISNULL(trucker.VatStatus, 'Y') = 'N' THEN (PRICING.U_Demurrage2 / 1.12) 
                    END 
                    ELSE 0.00 
                END 
                + 
                CASE 
                    WHEN T5.U_Rates LIKE '%U_totalAddtlCharges2%' THEN ISNULL(NULLIF(CAST(TP.U_ActualCharges AS FLOAT), ''), 0) 
                    ELSE 0.00 
                END 
                + 
                CASE 
                    WHEN T5.U_Rates LIKE '%U_ActualDemurrage%' THEN ISNULL(NULLIF(CAST(TP.U_ActualDemurrage AS FLOAT), ''), 0) 
                    ELSE 0.00 
                END 
                + 
                CASE 
                    WHEN T5.U_Rates LIKE '%U_ActualCharges%' THEN ISNULL(NULLIF(CAST(TP.U_ActualCharges AS FLOAT), ''), 0) 
                    ELSE 0.00 
                END 
                + 
                CASE 
                    WHEN T5.U_Rates LIKE '%U_BoomTruck2%' THEN ISNULL(NULLIF(CAST(TP.U_BoomTruck2 AS FLOAT), ''), 0) 
                    ELSE 0.00 
                END 
                + 
                CASE 
                    WHEN T5.U_Rates LIKE '%U_OtherCharges%' THEN ISNULL(NULLIF(CAST(TP.U_OtherCharges AS FLOAT), ''), 0) 
                    ELSE 0.00 
                END
                ) 
                - 
                ISNULL(TP.U_OtherDeductions, 0) 
                + 
                ABS((SELECT value FROM @TotalPenaltyWaived WHERE id = POD.U_BookingNumber)), 0)
            ELSE NULL
        END as value 
    FROM (
        SELECT 
            U_BookingNumber, U_SAPTrucker
        FROM [dbo].[@PCTP_POD] WITH(NOLOCK)
    ) POD
    INNER JOIN (
        SELECT
            U_BookingId, U_PVNo,
            U_ActualRates, U_RateAdjustments, 
            U_ActualCharges, U_ActualDemurrage, U_BoomTruck2, U_OtherCharges, U_OtherDeductions
        FROM [dbo].[@PCTP_TP] WITH(NOLOCK)
    ) TP ON TP.U_BookingId = POD.U_BookingNumber 
    INNER JOIN (SELECT CardCode, VatStatus FROM OCRD WITH(NOLOCK)) trucker ON POD.U_SAPTrucker = trucker.CardCode 
    INNER JOIN (
        SELECT
            U_BookingId,
            U_GrossTruckerRates, U_Demurrage2
        FROM [dbo].[@PCTP_PRICING] WITH(NOLOCK)
    ) PRICING ON TP.U_BookingId = PRICING.U_BookingId
    INNER JOIN [@RATESPERPV] T5 ON T5.Code = SUBSTRING(TP.U_PVNo, 11, 19)
    WHERE POD.U_BookingNumber IN (SELECT item FROM @BookingIdList);

    DECLARE @TotalAP TABLE(id nvarchar(100), value float);
    INSERT INTO @TotalAP
    SELECT DISTINCT
        POD.U_BookingNumber as id,
        CASE
            WHEN @TabName = 'SUMMARY' OR @TabName = 'TP' OR @TabName = 'PRICING' THEN
                CASE
                    WHEN (
                        (SELECT value FROM @DocNum WHERE id = POD.U_BookingNumber) LIKE '%[0-9]%'
                        OR (SELECT value FROM @Paid WHERE id = POD.U_BookingNumber) LIKE '%[0-9]%'
                    ) THEN
                        -- Either 1 Paid only or 1 Unpaid only, use @1stPV, otherwise @2ndPV
                        CASE
                            WHEN (
                                (
                                    CHARINDEX(',', TP.U_PVNo) = 0
                                    OR
                                    (
                                        (SELECT value FROM @DocNum WHERE id = POD.U_BookingNumber) LIKE '%[0-9]%'
                                        AND CHARINDEX(',', (SELECT value FROM @DocNum WHERE id = POD.U_BookingNumber)) = 0
                                        AND (SELECT value FROM @Paid WHERE id = POD.U_BookingNumber) IS NULL
                                    )
                                    OR 
                                    (
                                        (SELECT value FROM @Paid WHERE id = POD.U_BookingNumber) LIKE '%[0-9]%'
                                        AND CHARINDEX(',', (SELECT value FROM @Paid WHERE id = POD.U_BookingNumber)) = 0
                                        AND (SELECT value FROM @DocNum WHERE id = POD.U_BookingNumber) IS NULL
                                    )
                                )
                            ) THEN 
                                (SELECT value FROM @1stPV WHERE id = POD.U_BookingNumber)
                            ELSE 
                                (SELECT value FROM @2ndPV WHERE id = POD.U_BookingNumber) + (SELECT value FROM @1stPV WHERE id = POD.U_BookingNumber)
                        END
                    ELSE 0.00
                END
            ELSE NULL
        END as value
    FROM (
        SELECT 
            U_BookingNumber
        FROM [dbo].[@PCTP_POD] WITH(NOLOCK)
    ) POD
    LEFT JOIN (
        SELECT
            U_BookingId,
            U_GrossTruckerRates, U_PVNo
        FROM [dbo].[@PCTP_TP] WITH(NOLOCK)
    ) TP ON TP.U_BookingId = POD.U_BookingNumber
    -- LEFT JOIN (SELECT CardCode, VatStatus FROM OCRD WITH(NOLOCK)) client ON POD.U_SAPClient = client.CardCode
    -- LEFT JOIN (SELECT CardCode, VatStatus FROM OCRD WITH(NOLOCK)) trucker ON POD.U_SAPTrucker = trucker.CardCode
    WHERE POD.U_BookingNumber IN (SELECT item FROM @BookingIdList);

    DECLARE @PODSONum TABLE(id nvarchar(100), value nvarchar(100));
    INSERT INTO @PODSONum
    SELECT DISTINCT
        POD.U_BookingNumber as id,
        CAST((
            SELECT TOP 1
            header.DocNum
        FROM (
            SELECT DocEntry, DocNum, CANCELED FROM ORDR WITH(NOLOCK)
        ) header
        LEFT JOIN (
            SELECT DocEntry, ItemCode FROM RDR1 WITH(NOLOCK)
        ) line ON line.DocEntry = header.DocEntry
        WHERE line.ItemCode = POD.U_BookingNumber
            AND header.CANCELED = 'N'
        ) AS nvarchar(100)) as value
    FROM (
        SELECT 
            U_BookingNumber
        FROM [dbo].[@PCTP_POD] WITH(NOLOCK)
    ) POD
    WHERE POD.U_BookingNumber IN (SELECT item FROM @BookingIdList);

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
            TP.U_BookingId AS U_BookingNumber,
            CASE
                WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'DisableTableRow') THEN
                    CASE
                        WHEN @TabName = 'TP' THEN
                            CASE
                                WHEN (
                                    SELECT DISTINCT COUNT(*)
                            FROM OPCH H LEFT JOIN PCH1 L ON H.DocEntry = L.DocEntry
                            WHERE H.CANCELED = 'N'
                                AND (L.ItemCode = TP.U_BookingId OR REPLACE(REPLACE(RTRIM(LTRIM(TP.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(H.U_PVNo)) + '%')
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
                                AND (L.ItemCode = TP.U_BookingId) OR (REPLACE(REPLACE(RTRIM(LTRIM(TP.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(H.U_PVNo)) + '%')
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
                            CAST((SELECT value FROM @TotalAP WHERE id = TP.U_BookingId) AS NUMERIC(19,6))
                        ELSE NULL
                    END
                ELSE NULL
            END AS U_TotalAP,
            CASE
                WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_VarTP') THEN
                    CASE
                        WHEN @TabName = 'SUMMARY' OR @TabName = 'TP' OR @TabName = 'PRICING' THEN
                            CAST((SELECT value FROM @TotalAP WHERE id = TP.U_BookingId) - (TP.U_TotalPayable + TP.U_CAandDP + TP.U_Interest) AS NUMERIC(19,6))
                        ELSE NULL
                    END
                ELSE NULL
            END AS U_VarTP,
            CASE
                WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_DocNum') THEN
                    CASE
                        WHEN @TabName = 'SUMMARY' OR @TabName = 'TP' OR @TabName = 'PRICING' THEN
                            (SELECT value FROM @DocNum WHERE id = TP.U_BookingId)
                        ELSE NULL
                    END
                ELSE NULL
            END AS U_DocNum,
            CASE
                WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_Paid') THEN
                    CASE
                        WHEN @TabName = 'SUMMARY' OR @TabName = 'TP' OR @TabName = 'PRICING' THEN 
                            (SELECT value FROM @Paid WHERE id = TP.U_BookingId)
                        ELSE NULL
                    END
                ELSE NULL
            END As U_Paid,
            CASE
                WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_LostPenaltyCalc') THEN
                    CASE
                        WHEN @TabName = 'SUMMARY' OR @TabName = 'POD' OR @TabName = 'TP' OR @TabName = 'PRICING' THEN
                            CAST((SELECT value FROM @LostPenaltyCalc WHERE id = TP.U_BookingId) AS NUMERIC(19,6))
                        ELSE NULL
                    END
                ELSE NULL
            END AS U_LostPenaltyCalc,
            CASE
                WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_TotalSubPenalty') THEN
                    CASE
                        WHEN @TabName = 'SUMMARY' OR @TabName = 'POD' OR @TabName = 'TP' OR @TabName = 'PRICING' THEN
                            CAST(ISNULL(ABS((SELECT value FROM @TotalSubPenalties WHERE id = TP.U_BookingId)), 0) AS NUMERIC(19,6))
                        ELSE NULL
                    END
                ELSE NULL
            END AS U_TotalSubPenalty,
            CASE
                WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_TotalPenaltyWaived') THEN
                    CASE
                        WHEN @TabName = 'SUMMARY' OR @TabName = 'POD' OR @TabName = 'TP' OR @TabName = 'PRICING' THEN
                            CAST((SELECT value FROM @TotalPenaltyWaived WHERE id = TP.U_BookingId) AS NUMERIC(19,6))
                        ELSE NULL
                    END
                ELSE NULL
            END AS U_TotalPenaltyWaived,
            CASE
                WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_InteluckPenaltyCalc') THEN
                    CASE
                        WHEN @TabName = 'SUMMARY' OR @TabName = 'POD' OR @TabName = 'TP' OR @TabName = 'PRICING' THEN
                            CAST((SELECT value FROM @InteluckPenaltyCalc WHERE id = TP.U_BookingId) AS NUMERIC(19,6))
                        ELSE NULL
                    END
                ELSE NULL
            END AS U_InteluckPenaltyCalc,
            CASE
                WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_ClientSubOverdue') THEN
                    CASE
                        WHEN @TabName = 'SUMMARY' OR @TabName = 'POD' OR @TabName = 'TP' OR @TabName = 'PRICING' THEN
                            (SELECT value FROM @ClientSubOverdue WHERE id = TP.U_BookingId)
                        ELSE NULL
                    END
                ELSE NULL
            END AS U_ClientSubOverdue,
            CASE
                WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_ClientPenaltyCalc') THEN
                    CASE
                        WHEN @TabName = 'SUMMARY' OR @TabName = 'POD' OR @TabName = 'TP' OR @TabName = 'PRICING' THEN
                            CAST((SELECT value FROM @ClientPenaltyCalc WHERE id = TP.U_BookingId) AS NUMERIC(19,6))
                        ELSE NULL
                    END
                ELSE NULL
            END AS U_ClientPenaltyCalc
        FROM (
            SELECT
                U_BookingId, U_PVNo, U_TotalPayable, U_CAandDP, U_Interest
            FROM [dbo].[@PCTP_TP] WITH (NOLOCK)
        ) TP
        WHERE TP.U_BookingId IN (SELECT item FROM @BookingIdList) 
    )

    --->MAIN_QUERY
    INSERT INTO @T
    SELECT
        --COLUMNS
        CASE
            WHEN @TabName = 'SUMMARY' THEN CAST(POD.Code AS nvarchar(500))
            WHEN @TabName = 'POD' THEN CAST(POD.U_BookingNumber AS nvarchar(500))
            WHEN @TabName = 'BILLING' THEN CAST(BILLING.Code AS nvarchar(500))
            WHEN @TabName = 'TP' THEN CAST(TP.Code AS nvarchar(500))
            WHEN @TabName = 'PRICING' THEN CAST(PRICING.Code AS nvarchar(500))
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
            WHEN @TabName = 'SUMMARY' THEN CAST(POD.U_BookingNumber AS nvarchar(500))
            WHEN @TabName = 'POD' THEN CAST(POD.U_BookingNumber AS nvarchar(500))
            WHEN @TabName = 'BILLING' THEN CAST(BILLING.U_BookingId AS nvarchar(500))
            WHEN @TabName = 'TP' THEN CAST(TP.U_BookingId AS nvarchar(500))
            WHEN @TabName = 'PRICING' THEN CAST(PRICING.U_BookingId AS nvarchar(500))
            ELSE NULL
        END AS U_BookingNumber,
        CASE
            WHEN @TabName = 'SUMMARY' THEN CAST(POD.U_BookingNumber AS nvarchar(500))
            WHEN @TabName = 'POD' THEN CAST(POD.U_BookingNumber AS nvarchar(500))
            WHEN @TabName = 'BILLING' THEN CAST(BILLING.U_BookingId AS nvarchar(500))
            WHEN @TabName = 'TP' THEN CAST(TP.U_BookingId AS nvarchar(500))
            WHEN @TabName = 'PRICING' THEN CAST(PRICING.U_BookingId AS nvarchar(500))
            ELSE NULL
        END AS U_BookingId,
        CASE
            WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_PODNum') THEN
                CASE
                    WHEN @TabName = 'BILLING' THEN CAST(BILLING.U_BookingId AS nvarchar(500))
                    WHEN @TabName = 'TP' THEN CAST(TP.U_BookingId AS nvarchar(500))
                    WHEN @TabName = 'PRICING' THEN CAST(PRICING.U_BookingId AS nvarchar(500))
                    ELSE NULL
                END
            ELSE NULL
        END AS U_PODNum,
        CASE
            WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_PODSONum') THEN
                (SELECT value FROM @PODSONum WHERE id = POD.U_BookingNumber)
            ELSE NULL
        END AS U_PODSONum,
        CAST(client.CardName AS nvarchar(500)) AS U_CustomerName,
        PRICING.U_GrossClientRates AS U_GrossClientRates,
        CASE
            WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_GrossInitialRate') THEN
                CASE
                    WHEN @TabName = 'BILLING' THEN 
                        CAST((SELECT value FROM @GrossClientRatesTax WHERE id = POD.U_BookingNumber) AS NUMERIC(19,6))
                    ELSE NULL
                END
            ELSE NULL
        END AS U_GrossInitialRate,
        -- PRICING.U_GrossClientRates AS U_GrossInitialRate, --BILLING.U_GrossInitialRate
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
                    WHEN @TabName = 'TP' THEN ISNULL(TP.U_BoomTruck2, 0)
                    WHEN @TabName = 'PRICING' THEN CAST(ISNULL(PRICING.U_BoomTruck2, 0) AS nvarchar(500))
                    ELSE NULL
                END
            ELSE NULL
        END AS U_BoomTruck2,
        ISNULL(TP.U_BoomTruck2, 0) AS U_TPBoomTruck2,
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
                    WHEN @TabName = 'POD' THEN CAST(POD.U_BackLoad AS nvarchar(500))
                    WHEN @TabName = 'TP' THEN CAST(ISNULL(PRICING.U_Backload2, 0) AS nvarchar(500))
                    WHEN @TabName = 'PRICING' THEN CAST(ISNULL(PRICING.U_Backload, 0) AS nvarchar(500))
                    ELSE NULL
                END
            ELSE NULL
        END AS U_BackLoad,
        CASE
            WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_TotalAddtlCharges') THEN
                CASE
                    WHEN @TabName = 'PRICING' THEN 
                        CAST((SELECT value FROM @TotalAddtlCharges WHERE id = POD.U_BookingNumber) AS NUMERIC(19,6))
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
                    WHEN @TabName = 'BILLING' THEN BILLING.U_RateAdjustments
                    ELSE NULL
                END
            ELSE NULL
        END AS U_RateAdjustments,
        ISNULL(TP.U_RateAdjustments, 0) AS U_TPRateAdjustments,
        CASE
            WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_ActualDemurrage') THEN
                CASE
                    WHEN @TabName = 'BILLING' THEN BILLING.U_ActualDemurrage
                    WHEN @TabName = 'TP' THEN ISNULL(TP.U_ActualDemurrage, 0)
                    ELSE NULL
                END
            ELSE NULL
        END AS U_ActualDemurrage,
        ISNULL(TP.U_ActualDemurrage, 0) AS U_TPActualDemurrage,
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
                CAST((SELECT value FROM @TotalAddtlCharges WHERE id = POD.U_BookingNumber) AS NUMERIC(19,6))
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
            WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_BillingRateAdjustments') THEN
                CASE
                    WHEN @TabName = 'PRICING' THEN BILLING.U_RateAdjustments
                    ELSE NULL
                END
            ELSE NULL
        END AS U_BillingRateAdjustments,
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
                    WHEN @TabName = 'PRICING' OR @TabName = 'BILLING' OR @TabName = 'SUMMARY' THEN 
                        CAST((SELECT value FROM @GrossClientRatesTax WHERE id = POD.U_BookingNumber) AS NUMERIC(19,6))
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
                        CAST((SELECT value FROM @GrossTruckerRatesTax WHERE id = POD.U_BookingNumber) AS NUMERIC(19,6))
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
                        CAST((SELECT value FROM @GrossTruckerRatesTax WHERE id = POD.U_BookingNumber) AS NUMERIC(19,6))
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
                        CAST((SELECT value FROM @AddtlCharges2 WHERE id = POD.U_BookingNumber) AS NUMERIC(19,6))
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
                        CAST(((SELECT value FROM @GrossClientRatesTax WHERE id = POD.U_BookingNumber) 
                        - (SELECT value FROM @GrossTruckerRatesTax WHERE id = POD.U_BookingNumber)) AS NUMERIC(19,6))
                    ELSE NULL
                END
            ELSE NULL
        END AS U_GrossProfitNet,
        CASE
            WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_TotalInitialClient') THEN
                CASE
                    WHEN @TabName = 'SUMMARY' OR @TabName = 'PRICING' THEN
                        CAST((SELECT value FROM @TotalInitialClient WHERE id = POD.U_BookingNumber) AS NUMERIC(19,6))
                    ELSE NULL
                END
            ELSE NULL
        END AS U_TotalInitialClient,
        CASE
            WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_TotalInitialTruckers') THEN
                CASE
                    WHEN @TabName = 'SUMMARY' OR @TabName = 'TP' OR @TabName = 'PRICING' THEN
                        CAST((SELECT value FROM @TotalInitialTruckers WHERE id = POD.U_BookingNumber) AS NUMERIC(19,6))
                    ELSE NULL
                END
            ELSE NULL
        END AS U_TotalInitialTruckers,
        CASE
            WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_TotalGrossProfit') THEN
                CASE
                    WHEN @TabName = 'SUMMARY' OR @TabName = 'PRICING' THEN
                        CAST((SELECT value FROM @TotalInitialClient WHERE id = POD.U_BookingNumber) 
                        - (SELECT value FROM @TotalInitialTruckers WHERE id = POD.U_BookingNumber) AS NUMERIC(19,6))
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
        CAST(POD.U_VERIFICATION_TAT AS nvarchar(50)) AS U_VERIFICATION_TAT,
        CAST(POD.U_POD_TAT AS nvarchar(50)) AS U_POD_TAT,
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
                CASE 
                    WHEN @TabName = 'SUMMARY' OR @TabName = 'POD' OR @TabName = 'BILLING' THEN
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
                                WHEN BILLING.U_BillingStatus IS NULL OR BILLING.U_BillingStatus = '' THEN POD.U_BillingStatus
                                ELSE BILLING.U_BillingStatus 
                            END
                        END
                    ELSE NULL 
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
        POD.U_TotalNoExceed AS U_TotalExceed,
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
                    WHEN @TabName = 'SUMMARY' OR @TabName = 'TP' OR @TabName = 'POD' THEN TF.U_ClientSubOverdue
                    ELSE NULL
                END
            ELSE NULL
        END AS U_ClientSubOverdue,
        CASE
            WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_ClientPenaltyCalc') THEN
                CASE
                    WHEN @TabName = 'SUMMARY' OR @TabName = 'TP' OR @TabName = 'POD' THEN TF.U_ClientPenaltyCalc
                    ELSE NULL
                END
            ELSE NULL
        END AS U_ClientPenaltyCalc,
        CASE
            WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_PODStatusPayment') THEN
                CASE
                    WHEN @TabName = 'SUMMARY' OR @TabName = 'POD' OR @TabName = 'TP' THEN 
                        (SELECT value FROM @PODStatusPayment WHERE id = POD.U_BookingNumber)
                    ELSE NULL
                END
            ELSE NULL
        END AS U_PODStatusPayment,
        '' AS U_ProofOfPayment,
        CASE
            WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_TotalRecClients') THEN
                CASE
                    WHEN @TabName = 'SUMMARY' OR @TabName = 'BILLING' OR @TabName = 'PRICING' THEN
                        CAST((SELECT value FROM @TotalRecClients WHERE id = POD.U_BookingNumber) AS NUMERIC(19,6))
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
            WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_TotalPayable') THEN
                CASE
                    WHEN @TabName = 'SUMMARY' OR @TabName = 'TP' OR @TabName = 'PRICING' THEN
                        CAST((ISNULL(CASE
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
                        - (SELECT value FROM @TOTALDEDUCTIONS WHERE id = POD.U_BookingNumber)) AS NUMERIC(19,6))
                    ELSE NULL
                END
            ELSE NULL
        END AS U_TotalPayable,
        CASE
            WHEN @TabName = 'SUMMARY' OR @TabName = 'POD' OR @TabName = 'TP' OR @TabName = 'PRICING' THEN ISNULL(TF.U_TotalSubPenalty, 0)
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
        TP.U_TPincharge,
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
                        CAST((SELECT value FROM @TOTALDEDUCTIONS WHERE id = POD.U_BookingNumber) AS NUMERIC(19,6))
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
                        CAST((SELECT value FROM @TotalAR WHERE id = POD.U_BookingNumber) AS NUMERIC(19,6))
                    ELSE NULL
                END
            ELSE NULL
        END AS U_TotalAR,
        CASE
            WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_VarAR') THEN
                CASE
                    WHEN @TabName = 'SUMMARY' OR @TabName = 'BILLING' OR @TabName = 'PRICING' THEN
                        CAST((SELECT value FROM @TotalAR WHERE id = POD.U_BookingNumber) 
                        - (SELECT value FROM @TotalRecClients WHERE id = POD.U_BookingNumber) AS NUMERIC(19,6))
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
            WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_PODSubmitDeadline') THEN
                CASE
                    WHEN @TabName = 'POD' THEN 
                        (SELECT value FROM @PODSubmitDeadline WHERE id = POD.U_BookingNumber)
                    ELSE NULL
                END
            ELSE NULL
        END AS U_PODSubmitDeadline,
        CASE
            WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_OverdueDays') THEN
                CASE
                    WHEN @TabName = 'POD' THEN 
                        (SELECT value FROM @OverdueDays WHERE id = POD.U_BookingNumber)
                    ELSE NULL
                END
            ELSE NULL
        END AS U_OverdueDays,
        CASE
            WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_InteluckPenaltyCalc') THEN
                CASE
                    WHEN @TabName = 'SUMMARY' OR @TabName = 'TP' OR @TabName = 'POD' THEN TF.U_InteluckPenaltyCalc
                    ELSE NULL
                END
            ELSE NULL
        END AS U_InteluckPenaltyCalc,
        POD.U_WaivedDays,
        POD.U_HolidayOrWeekend,
        TP.U_EWT2307,
        CASE
            WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_LostPenaltyCalc') THEN
                CASE
                    WHEN @TabName = 'TP' OR @TabName = 'POD' OR @TabName = 'SUMMARY' THEN TF.U_LostPenaltyCalc
                    ELSE NULL
                END
            ELSE NULL
        END AS U_LostPenaltyCalc,
        CASE
            WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_TotalSubPenalties') THEN
                CASE
                    WHEN @TabName = 'POD' THEN 
                        CAST((SELECT value FROM @TotalSubPenalties WHERE id = POD.U_BookingNumber) AS NUMERIC(19,6))
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
                    WHEN @TabName = 'SUMMARY' OR @TabName = 'POD' OR @TabName = 'TP' THEN ISNULL(TF.U_TotalPenaltyWaived, 0)
                    ELSE NULL
                END
            ELSE NULL
        END AS U_TotalPenaltyWaived,
        CAST((SELECT value FROM @TotalPenalty WHERE id = POD.U_BookingNumber) AS NUMERIC(19,6)) AS U_TotalPenalty,
        ISNULL(TP.U_TotalPayableRec, 0) AS U_TotalPayableRec,
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
                            ) as nvarchar(500)
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
                            AND header.CANCELED = 'N') as nvarchar(500)
                        )
                    ELSE NULL
                END
            ELSE NULL
        END AS U_InvoiceNo,
        CASE
            WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_ARDocNum') THEN
                CASE
                    WHEN @TabName = 'SUMMARY' THEN 
                        CAST(SUBSTRING((
                                    SELECT CONCAT(', ', header.DocNum)  AS [text()]
                        FROM INV1 line WITH (NOLOCK)
                            LEFT JOIN (SELECT DocEntry, DocNum, CANCELED FROM OINV WITH (NOLOCK)) header ON header.DocEntry = line.DocEntry
                        WHERE line.ItemCode = POD.U_BookingNumber
                            AND header.CANCELED = 'N'
                        FOR XML PATH (''), TYPE
                                ).value('text()[1]','nvarchar(max)'), 2, 1000) as nvarchar(500))
                    ELSE NULL
                END
            ELSE NULL
        END As U_ARDocNum,
        CASE
            WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_DocNum') THEN
                CASE
                    WHEN @TabName = 'BILLING' OR @TabName = 'PRICING' THEN 
                        CAST(SUBSTRING((
                                    SELECT CONCAT(', ', header.DocNum)  AS [text()]
                        FROM INV1 line WITH (NOLOCK)
                            LEFT JOIN (SELECT DocEntry, DocNum, CANCELED FROM OINV WITH (NOLOCK)) header ON header.DocEntry = line.DocEntry
                        WHERE line.ItemCode = POD.U_BookingNumber
                            AND header.CANCELED = 'N'
                        FOR XML PATH (''), TYPE
                                ).value('text()[1]','nvarchar(max)'), 2, 1000) as nvarchar(500))
                    WHEN @TabName = 'POD' THEN CAST(POD.U_DocNum as nvarchar(500))
                    WHEN @TabName = 'TP' THEN TF.U_DocNum
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
            WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_ORRefNo') THEN
                CASE
                    WHEN @TabName = 'TP' THEN
                        SUBSTRING((
                            SELECT
                                CONCAT(', ', T0.U_OR_Ref) AS [text()]
                            FROM OPCH T0 WITH (NOLOCK)
                            WHERE T0.Canceled <> 'Y' AND T0.DocNum IN (SELECT RTRIM(LTRIM(value)) AS DocNum FROM STRING_SPLIT(TF.U_Paid, ','))
                            FOR XML PATH (''), TYPE).value('text()[1]','nvarchar(max)'), 2, 1000
                        )
                    ELSE NULL
                END
            ELSE NULL
        END AS U_ORRefNo,
        CASE
            WHEN EXISTS(SELECT item FROM @AccessColumnList WHERE item = 'ALL' OR item = 'U_ActualPaymentDate') THEN
                CASE
                    WHEN @TabName = 'TP' THEN
                        SUBSTRING((
                            SELECT
                                CONCAT(CASE WHEN T0.TrsfrDate IS NOT NULL THEN CONCAT(', ', CAST(T0.TrsfrDate AS DATE))
                                ELSE '' END,
                                CASE WHEN T2.DueDate IS NOT NULL THEN CONCAT(', ', CAST(T2.DueDate AS DATE))
                                ELSE '' END) AS [text()]
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
                                CONCAT(CASE WHEN T0.TrsfrRef IS NOT NULL THEN CONCAT(', ', T0.TrsfrRef)
                                ELSE '' END,
                                CASE WHEN T2.CheckNum IS NOT NULL THEN CONCAT(', ', T2.CheckNum)
                                ELSE '' END) AS [text()]
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
        CASE
            WHEN @TabName = 'POD' OR @TabName = 'SUMMARY' THEN CAST(POD.U_Remarks as nvarchar(500))
            WHEN @TabName = 'TP' THEN CAST(TP.U_Remarks as nvarchar(500))
            ELSE NULL
        END AS U_Remarks,
        ISNULL(CAST(client.U_GroupLocation as nvarchar(500)), '') AS U_GroupProject,
        CAST(POD.U_Attachment as nvarchar(500)) AS U_Attachment,
        CAST(POD.U_DeliveryOrigin as nvarchar(500)) AS U_DeliveryOrigin,
        CAST(POD.U_Destination as nvarchar(500)) AS U_Destination,
        CAST(POD.U_OtherPODDoc as nvarchar(1000)) AS U_OtherPODDoc,
        CAST(POD.U_RemarksPOD as nvarchar(500)) AS U_RemarksPOD,
        CAST(POD.U_PODStatusDetail as nvarchar(500)) AS U_PODStatusDetail,
        CAST(POD.U_BTRemarks as nvarchar(500)) AS U_BTRemarks,
        CAST(POD.U_DestinationClient as nvarchar(500)) AS U_DestinationClient,
        CAST(POD.U_Remarks2 as nvarchar(500)) AS U_Remarks2,
        CAST(POD.U_TripTicketNo as nvarchar(500)) AS U_TripTicketNo,
        CAST(POD.U_WaybillNo as nvarchar(500)) AS U_WaybillNo,
        CAST(POD.U_ShipmentNo as nvarchar(500)) AS U_ShipmentNo,
        CAST(POD.U_ShipmentNo as nvarchar(500)) AS U_ShipmentManifestNo,
        CAST(POD.U_DeliveryReceiptNo as nvarchar(500)) AS U_DeliveryReceiptNo,
        CAST(POD.U_SeriesNo as nvarchar(500)) AS U_SeriesNo,
        CAST(POD.U_OutletNo as nvarchar(500)) AS U_OutletNo,
        CAST(POD.U_CBM as nvarchar(500)) AS U_CBM,
        CAST(POD.U_SI_DRNo as nvarchar(500)) AS U_SI_DRNo,
        CAST(POD.U_DeliveryMode as nvarchar(500)) AS U_DeliveryMode,
        CAST(POD.U_SourceWhse as nvarchar(500)) AS U_SourceWhse,
        CAST(POD.U_SONo as nvarchar(500)) AS U_SONo,
        CAST(POD.U_NameCustomer as nvarchar(500)) AS U_NameCustomer,
        CAST(POD.U_CategoryDR as nvarchar(500)) AS U_CategoryDR,
        CAST(POD.U_IDNumber as nvarchar(500)) AS U_IDNumber,
        CAST(POD.U_ApprovalStatus as nvarchar(500)) AS U_ApprovalStatus,
        CAST(POD.U_ApprovalStatus as nvarchar(500)) AS U_Status,
        CAST(PRICING.U_RemarksDTR as nvarchar(500)) AS U_RemarksDTR,
        CAST(POD.U_TotalInvAmount as nvarchar(500)) AS U_TotalInvAmount,
        CAST(POD.U_DocNum as nvarchar(500)) AS U_PODDocNum

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
    AND (CASE
        WHEN @TabName = 'BILLING' THEN 
            CASE WHEN (CAST(POD.U_PODStatusDetail as nvarchar(500)) LIKE '%Verified%' OR CAST(POD.U_PODStatusDetail as nvarchar(500)) LIKE '%ForAdvanceBilling%') THEN 1
            ELSE 0 END
        WHEN @TabName = 'TP' THEN 
            CASE WHEN CAST(POD.U_PODStatusDetail as nvarchar(500)) LIKE '%Verified%' THEN 1
            ELSE 0 END
        ELSE 1
    END) = 1

  RETURN
END;