IF (OBJECT_ID('fetchGenericPctpDataRows') IS NOT NULL)
    DROP FUNCTION [dbo].fetchGenericPctpDataRows
GO

CREATE FUNCTION [dbo].fetchGenericPctpDataRows( 
    @BookingIds nvarchar(max)
)
RETURNS @T TABLE(
    su_Code nvarchar(500),
    po_Code nvarchar(500),
    bi_Code nvarchar(500),
    tp_Code nvarchar(500),
    pr_Code nvarchar(500),
    po_DisableTableRow nvarchar(5),
    bi_DisableTableRow nvarchar(5),
    tp_DisableTableRow nvarchar(5),
    bi_DisableSomeFields nvarchar(30),
    tp_DisableSomeFields nvarchar(30),
    pr_DisableSomeFields nvarchar(30),
    pr_DisableSomeFields2 nvarchar(30),
    U_BookingDate DATETIME,
    U_BookingNumber nvarchar(500),
    U_BookingId nvarchar(500),
    bi_U_PODNum nvarchar(500),
    tp_U_PODNum nvarchar(500),
    pr_U_PODNum nvarchar(500),
    U_PODSONum nvarchar(500),
    U_CustomerName nvarchar(500),
    U_GrossClientRates nvarchar(500), -- NUMERIC(19,6)
    U_GrossInitialRate nvarchar(500),
    U_Demurrage nvarchar(500),
    tp_U_Demurrage nvarchar(500),
    tp_U_AddtlDrop nvarchar(500),
    pr_U_AddtlDrop nvarchar(500),
    tp_U_BoomTruck nvarchar(500),
    pr_U_BoomTruck nvarchar(500),
    tp_U_BoomTruck2 nvarchar(500),
    pr_U_BoomTruck2 nvarchar(500),
    U_TPBoomTruck2 nvarchar(500),
    tp_U_Manpower nvarchar(500),
    pr_U_Manpower nvarchar(500),
    po_U_BackLoad nvarchar(500),
    tp_U_BackLoad nvarchar(500),
    pr_U_BackLoad nvarchar(500),
    U_TotalAddtlCharges nvarchar(500),
    U_Demurrage2 nvarchar(500),
    U_AddtlDrop2 nvarchar(500),
    U_Manpower2 nvarchar(500),
    U_Backload2 nvarchar(500),
    U_totalAddtlCharges2 nvarchar(500),
    U_Demurrage3 nvarchar(500),
    U_GrossProfit nvarchar(500),
    tp_U_Addtlcharges nvarchar(500),
    pr_U_Addtlcharges nvarchar(500),
    U_DemurrageN nvarchar(500),
    U_AddtlChargesN nvarchar(500),
    U_ActualRates nvarchar(500),
    tp_U_RateAdjustments nvarchar(500),
    bi_U_RateAdjustments nvarchar(500),
    U_TPRateAdjustments nvarchar(500),
    bi_U_ActualDemurrage nvarchar(500),
    tp_U_ActualDemurrage nvarchar(500),
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
    tp_U_RateBasis nvarchar(50),
    pr_U_RateBasis nvarchar(50),
    U_GrossTruckerRatesN nvarchar(500),
    tp_U_TaxType nvarchar(50),
    pr_U_TaxType nvarchar(50),
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
    bi_U_BillingTeam nvarchar(100),
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
    su_U_APDocNum nvarchar(50),
    pr_U_APDocNum nvarchar(50),
    U_ServiceType nvarchar(500),
    U_InvoiceNo nvarchar(500),
    U_ARDocNum nvarchar(500),
    po_U_DocNum nvarchar(500),
    tp_U_DocNum nvarchar(500),
    U_DocNum nvarchar(500),
    U_Paid nvarchar(500),
    U_ORRefNo nvarchar(500),
    U_ActualPaymentDate nvarchar(500),
    U_PaymentReference nvarchar(500),
    U_PaymentStatus nvarchar(500),
    U_Remarks nvarchar(500),
    tp_U_Remarks nvarchar(500),
    U_GroupProject nvarchar(500),
    U_Attachment nvarchar(500),
    U_DeliveryOrigin nvarchar(500),
    U_Destination nvarchar(500),
    U_OtherPODDoc nvarchar(4000),
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

    --VARIABLES
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
            U_BookingNumber, U_DeliveryDateDTR, U_ClientReceivedDate, U_WaivedDays, U_SAPClient
        FROM [dbo].[@PCTP_POD] WITH(NOLOCK)
    ) POD
    LEFT JOIN (SELECT CardCode, U_DCD FROM OCRD WITH(NOLOCK)) client ON POD.U_SAPClient = client.CardCode
    WHERE POD.U_BookingNumber IN (SELECT item FROM @BookingIdList);

    DECLARE @ClientPenaltyCalc TABLE(id nvarchar(100), value float);
    INSERT INTO @ClientPenaltyCalc
    SELECT DISTINCT
        POD.U_BookingNumber as id,
        dbo.computeClientPenaltyCalc(
            (SELECT value FROM @ClientSubOverdue WHERE id = POD.U_BookingNumber)
        ) as value
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
        dbo.computePODSubmitDeadline(
            POD.U_DeliveryDateDTR,
            ISNULL(client.U_CDC,0)
        ) as value
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
        dbo.computeOverdueDays(
            POD.U_ActualHCRecDate,
            (SELECT value FROM @PODSubmitDeadline WHERE id = POD.U_BookingNumber),
            ISNULL(POD.U_HolidayOrWeekend, 0)
        ) as value
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
        dbo.computePODStatusPayment(
            (SELECT value FROM @OverdueDays WHERE id = POD.U_BookingNumber)
        ) as value
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
        dbo.computeInteluckPenaltyCalc(
            (SELECT value FROM @PODStatusPayment WHERE id = POD.U_BookingNumber),
            (SELECT value FROM @OverdueDays WHERE id = POD.U_BookingNumber)
        ) as value
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
            WHEN ISNULL(client.VatStatus,'Y') = 'Y' THEN PRICING.U_GrossClientRates
            WHEN ISNULL(client.VatStatus,'Y') = 'N' THEN (PRICING.U_GrossClientRates / 1.12)
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
            WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN PRICING.U_GrossTruckerRates
            WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN (PRICING.U_GrossTruckerRates / 1.12)
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
        (
            ISNULL(PRICING.U_AddtlDrop, 0) 
            + ISNULL(PRICING.U_BoomTruck, 0) 
            + ISNULL(PRICING.U_Manpower, 0) 
            + ISNULL(PRICING.U_Backload, 0)
        ) as value
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
            WHEN ISNULL(client.VatStatus,'Y') = 'Y' THEN 
                (SELECT value FROM @TotalAddtlCharges WHERE id = POD.U_BookingNumber)
            WHEN ISNULL(client.VatStatus,'Y') = 'N' THEN 
                ((SELECT value FROM @TotalAddtlCharges WHERE id = POD.U_BookingNumber) / 1.12)
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
        (SELECT value FROM @AddtlCharges2 WHERE id = POD.U_BookingNumber) 
        + (SELECT value FROM @GrossClientRatesTax WHERE id = POD.U_BookingNumber)
        + CASE
            WHEN ISNULL(client.VatStatus,'Y') = 'Y' THEN ISNULL(PRICING.U_Demurrage, 0)
            WHEN ISNULL(client.VatStatus,'Y') = 'N' THEN (ISNULL(PRICING.U_Demurrage, 0) / 1.12)
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
        dbo.computeLostPenaltyCalc(
            (SELECT value FROM @PODStatusPayment WHERE id = POD.U_BookingNumber),
            POD.U_InitialHCRecDate,
            POD.U_DeliveryDateDTR,
            (SELECT value FROM @TotalInitialTruckers WHERE id = POD.U_BookingNumber)
        ) as value
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
        dbo.computeTotalSubPenalties(
            (SELECT value FROM @ClientPenaltyCalc WHERE id = POD.U_BookingNumber),
            (SELECT value FROM @InteluckPenaltyCalc WHERE id = POD.U_BookingNumber),
            (SELECT value FROM @LostPenaltyCalc WHERE id = POD.U_BookingNumber),
            ISNULL(POD.U_PenaltiesManual,0)
        ) as value
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
        dbo.computeTotalPenaltyWaived(
            (SELECT value FROM @TotalSubPenalties WHERE id = POD.U_BookingNumber),
            ISNULL(POD.U_PercPenaltyCharge,0)
        ) as value
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
        ISNULL((
            SELECT
                SUM(L.PriceAfVAT)
            FROM OINV H WITH(NOLOCK)
            LEFT JOIN (SELECT DocEntry, ItemCode, PriceAfVAT FROM INV1 WITH(NOLOCK)) L ON H.DocEntry = L.DocEntry
            WHERE H.CANCELED = 'N' AND L.ItemCode = POD.U_BookingNumber
        ), 0) as value
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
        + ISNULL(BILLING.U_ActualAddCharges, 0) as value
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
        ISNULL(TP.U_CAandDP,0) + ISNULL(TP.U_Interest,0) + ISNULL(TP.U_OtherDeductions,0) 
        + (ABS(
            ABS(ISNULL((SELECT value FROM @TotalSubPenalties WHERE id = POD.U_BookingNumber),0)) 
            - ABS(ISNULL((SELECT value FROM @TotalPenaltyWaived WHERE id = POD.U_BookingNumber),0))
        )) as value
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
                ).value('text()[1]','nvarchar(max)'), 2, 1000) as nvarchar(max)) as value
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
                ).value('text()[1]','nvarchar(max)'), 2, 1000) as nvarchar(max)) as value
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
        ABS((SELECT value FROM @TotalSubPenalties WHERE id = POD.U_BookingNumber)) 
        - (SELECT value FROM @TotalPenaltyWaived WHERE id = POD.U_BookingNumber) as value
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
        ISNULL((
            ISNULL(TRY_PARSE(ratessub.U_Amount AS FLOAT), 0)
            + ISNULL(TP.U_RateAdjustments, 0) 
            + ISNULL(TRY_PARSE(ratessub.U_AddlAmount AS FLOAT), 0)
        ) 
        - 
        (SELECT value FROM @TotalPenalty WHERE id = POD.U_BookingNumber), 0) as value 
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
        ABS((SELECT value FROM @TotalPenaltyWaived WHERE id = POD.U_BookingNumber)), 0) as value 
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
                WHEN (
                    SELECT DISTINCT COUNT(*)
            FROM OPCH H LEFT JOIN PCH1 L ON H.DocEntry = L.DocEntry
            WHERE H.CANCELED = 'N'
                AND (L.ItemCode = TP.U_BookingId OR REPLACE(REPLACE(RTRIM(LTRIM(TP.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(H.U_PVNo)) + '%')
                ) > 1
                THEN 'Y'
                ELSE 'N'
            END AS DisableTableRow,
            CASE
                WHEN (
                    SELECT DISTINCT COUNT(*)
            FROM OPCH H LEFT JOIN PCH1 L ON H.DocEntry = L.DocEntry
            WHERE H.CANCELED = 'N'
                AND (L.ItemCode = TP.U_BookingId) OR (REPLACE(REPLACE(RTRIM(LTRIM(TP.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(H.U_PVNo)) + '%')
                ) = 1
                THEN 'DisableSomeFields'
                ELSE ''
            END AS DisableSomeFields,
            CAST((SELECT value FROM @TotalAP WHERE id = TP.U_BookingId) AS NUMERIC(19,6)) AS U_TotalAP,
            CAST(
                (SELECT value FROM @TotalAP WHERE id = TP.U_BookingId) 
                - (TP.U_TotalPayable + TP.U_CAandDP + TP.U_Interest) 
            AS NUMERIC(19,6)) AS U_VarTP,
            (SELECT value FROM @DocNum WHERE id = TP.U_BookingId) AS U_DocNum,
            (SELECT value FROM @Paid WHERE id = TP.U_BookingId) As U_Paid,
            CAST((SELECT value FROM @LostPenaltyCalc WHERE id = TP.U_BookingId) AS NUMERIC(19,6)) AS U_LostPenaltyCalc,
            CAST(ISNULL(ABS((SELECT value FROM @TotalSubPenalties WHERE id = TP.U_BookingId)), 0) AS NUMERIC(19,6)) AS U_TotalSubPenalty,
            CAST((SELECT value FROM @TotalPenaltyWaived WHERE id = TP.U_BookingId) AS NUMERIC(19,6)) AS U_TotalPenaltyWaived,
            CAST((SELECT value FROM @InteluckPenaltyCalc WHERE id = TP.U_BookingId) AS NUMERIC(19,6)) AS U_InteluckPenaltyCalc,
            (SELECT value FROM @ClientSubOverdue WHERE id = TP.U_BookingId) AS U_ClientSubOverdue,
            CAST((SELECT value FROM @ClientPenaltyCalc WHERE id = TP.U_BookingId) AS NUMERIC(19,6)) AS U_ClientPenaltyCalc
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
        CAST(POD.Code AS nvarchar(500)) As su_Code,
        CAST(POD.U_BookingNumber AS nvarchar(500)) As po_Code,
        CAST(BILLING.Code AS nvarchar(500)) As bi_Code,
        CAST(TP.Code AS nvarchar(500)) As tp_Code,
        CAST(PRICING.Code AS nvarchar(500)) As pr_Code,
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
        END As po_DisableTableRow,
        CASE
            WHEN (SELECT DISTINCT COUNT(*)
        FROM OINV H LEFT JOIN INV1 L ON H.DocEntry = L.DocEntry
        WHERE L.ItemCode = BILLING.U_BookingId AND H.CANCELED = 'N') > 1
            THEN 'Y'
            ELSE 'N'
        END As bi_DisableTableRow,
        TF.DisableTableRow As tp_DisableTableRow,
        CASE
            WHEN (SELECT DISTINCT COUNT(*)
        FROM OINV H LEFT JOIN INV1 L ON H.DocEntry = L.DocEntry
        WHERE L.ItemCode = BILLING.U_BookingId AND H.CANCELED = 'N') = 1
            THEN 'DisableSomeFields'
            ELSE ''
        END AS bi_DisableSomeFields,
        TF.DisableSomeFields AS tp_DisableSomeFields,
        CASE
            WHEN (SELECT DISTINCT COUNT(*)
        FROM OINV H LEFT JOIN INV1 L ON H.DocEntry = L.DocEntry
        WHERE L.ItemCode = PRICING.U_BookingId AND H.CANCELED = 'N') > 0
            THEN 'DisableFieldsForBilling'
            ELSE ''
        END AS pr_DisableSomeFields,
        CASE
            WHEN EXISTS(
                SELECT 1
        FROM OPCH H, PCH1 L
        WHERE H.DocEntry = L.DocEntry AND H.CANCELED = 'N'
            AND (L.ItemCode = PRICING.U_BookingId
            OR (REPLACE(REPLACE(RTRIM(LTRIM(tp.U_PVNo)), ' ', ''), ',', '') LIKE '%' + RTRIM(LTRIM(H.U_PVNo)) + '%')))
            THEN 'DisableFieldsForTp'
            ELSE ''
        END AS pr_DisableSomeFields2,
        CAST(POD.U_BookingDate AS DATE) AS U_BookingDate,
        CAST(POD.U_BookingNumber AS nvarchar(500)) AS U_BookingNumber,
        CAST(POD.U_BookingNumber AS nvarchar(500)) AS U_BookingId,
        CAST(BILLING.U_BookingId AS nvarchar(500)) AS bi_U_PODNum,
        CAST(TP.U_BookingId AS nvarchar(500)) AS tp_U_PODNum,
        CAST(PRICING.U_BookingId AS nvarchar(500)) AS pr_U_PODNum,
        (SELECT value FROM @PODSONum WHERE id = POD.U_BookingNumber) AS U_PODSONum,
        CAST(client.CardName AS nvarchar(500)) AS U_CustomerName,
        PRICING.U_GrossClientRates AS U_GrossClientRates,
        CAST((SELECT value FROM @GrossClientRatesTax WHERE id = POD.U_BookingNumber) AS NUMERIC(19,6)) AS U_GrossInitialRate,
        ISNULL(PRICING.U_Demurrage, 0) AS U_Demurrage,
        ISNULL(PRICING.U_Demurrage2, 0) AS tp_U_Demurrage,
        ISNULL(PRICING.U_AddtlDrop2, 0) AS tp_U_AddtlDrop,
        ISNULL(PRICING.U_AddtlDrop, 0) AS pr_U_AddtlDrop,
        ISNULL(PRICING.U_BoomTruck2, 0) AS tp_U_BoomTruck,
        ISNULL(PRICING.U_BoomTruck, 0) AS pr_U_BoomTruck,
        ISNULL(TP.U_BoomTruck2, 0) AS tp_U_BoomTruck2,
        CAST(ISNULL(PRICING.U_BoomTruck2, 0) AS nvarchar(500)) AS pr_U_BoomTruck2,
        ISNULL(TP.U_BoomTruck2, 0) AS U_TPBoomTruck2,
        ISNULL(PRICING.U_Manpower2, 0) AS tp_U_Manpower,
        ISNULL(PRICING.U_Manpower, 0) AS pr_U_Manpower,
        CAST(POD.U_BackLoad AS nvarchar(500)) AS po_U_BackLoad,
        CAST(ISNULL(PRICING.U_Backload2, 0) AS nvarchar(500)) AS tp_U_BackLoad,
        CAST(ISNULL(PRICING.U_Backload, 0) AS nvarchar(500)) AS pr_U_BackLoad,
        CAST((SELECT value FROM @TotalAddtlCharges WHERE id = POD.U_BookingNumber) AS NUMERIC(19,6)) AS U_TotalAddtlCharges,
        ISNULL(PRICING.U_Demurrage2, 0) AS U_Demurrage2,
        ISNULL(PRICING.U_AddtlDrop2, 0) AS U_AddtlDrop2,
        ISNULL(PRICING.U_Manpower2, 0) AS U_Manpower2,
        ISNULL(PRICING.U_Backload2, 0) AS U_Backload2,
        ISNULL(PRICING.U_AddtlDrop2, 0) 
        + ISNULL(PRICING.U_BoomTruck2, 0) 
        + ISNULL(PRICING.U_Manpower2, 0) 
        + ISNULL(PRICING.U_Backload2, 0) AS U_totalAddtlCharges2,
        CASE
            WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN ISNULL(PRICING.U_Demurrage2, 0)
            WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN (ISNULL(PRICING.U_Demurrage2, 0) / 1.12)
        END AS U_Demurrage3,
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
        END)) AS U_GrossProfit,
        ISNULL(pricing.U_AddtlDrop2, 0) 
        + ISNULL(pricing.U_BoomTruck2, 0) 
        + ISNULL(pricing.U_Manpower2, 0) 
        + ISNULL(pricing.U_Backload2, 0) AS tp_U_Addtlcharges,
        CASE
            WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN (ISNULL(PRICING.U_AddtlDrop2, 0) + ISNULL(PRICING.U_BoomTruck2, 0) + ISNULL(PRICING.U_Manpower2, 0) + ISNULL(PRICING.U_Backload2, 0))
            WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN ((ISNULL(PRICING.U_AddtlDrop2, 0) + ISNULL(PRICING.U_BoomTruck2, 0) + ISNULL(PRICING.U_Manpower2, 0) + ISNULL(PRICING.U_Backload2, 0)) / 1.12)
        END AS pr_U_Addtlcharges,
        CASE
            WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN ISNULL(pricing.U_Demurrage2, 0)
            WHEN ISNULL(trucker.VatStatus,'Y') = 'N' THEN (ISNULL(pricing.U_Demurrage2, 0) / 1.12)
        END AS U_DemurrageN,
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
        END AS U_AddtlChargesN,
        ISNULL(TP.U_ActualRates, 0) AS U_ActualRates,
        ISNULL(TP.U_RateAdjustments, 0) AS tp_U_RateAdjustments,
        BILLING.U_RateAdjustments AS bi_U_RateAdjustments,
        ISNULL(TP.U_RateAdjustments, 0) AS U_TPRateAdjustments,
        BILLING.U_ActualDemurrage AS bi_U_ActualDemurrage,
        ISNULL(TP.U_ActualDemurrage, 0) AS tp_U_ActualDemurrage,
        ISNULL(TP.U_ActualDemurrage, 0) AS U_TPActualDemurrage,
        ISNULL(TP.U_ActualCharges, 0) AS U_ActualCharges,
        ISNULL(TP.U_OtherCharges, 0) AS U_OtherCharges,
        CAST((SELECT value FROM @TotalAddtlCharges WHERE id = POD.U_BookingNumber) AS NUMERIC(19,6)) AS U_AddCharges,
        BILLING.U_ActualBilledRate AS U_ActualBilledRate,
        BILLING.U_RateAdjustments AS U_BillingRateAdjustments,
        BILLING.U_ActualDemurrage AS U_BillingActualDemurrage,
        BILLING.U_ActualAddCharges AS U_ActualAddCharges,
        CAST((SELECT value FROM @GrossClientRatesTax WHERE id = POD.U_BookingNumber) AS NUMERIC(19,6)) AS U_GrossClientRatesTax,
        ISNULL(PRICING.U_GrossTruckerRates, 0) AS U_GrossTruckerRates,
        PRICING.U_RateBasisT AS tp_U_RateBasis,
        PRICING.U_RateBasis AS pr_U_RateBasis,
        CAST((SELECT value FROM @GrossTruckerRatesTax WHERE id = POD.U_BookingNumber) AS NUMERIC(19,6)) AS U_GrossTruckerRatesN,
        CASE
            WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN 'VAT' ELSE 'NONVAT'
        END AS tp_U_TaxType,
        CASE
            WHEN ISNULL(client.VatStatus,'Y') = 'Y' THEN 'VAT' ELSE 'NONVAT'
        END AS pr_U_TaxType,
        CAST((SELECT value FROM @GrossTruckerRatesTax WHERE id = POD.U_BookingNumber) AS NUMERIC(19,6)) AS U_GrossTruckerRatesTax,
        PRICING.U_RateBasisT AS U_RateBasisT,
        CASE
            WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN 'VAT' ELSE 'NONVAT'
        END AS U_TaxTypeT,
        CASE
            WHEN ISNULL(client.VatStatus,'Y') = 'Y' THEN ISNULL(PRICING.U_Demurrage, 0)
            WHEN ISNULL(client.VatStatus,'Y') = 'N' THEN (ISNULL(PRICING.U_Demurrage, 0) / 1.12)
        END AS U_Demurrage4,
        CAST((SELECT value FROM @AddtlCharges2 WHERE id = POD.U_BookingNumber) AS NUMERIC(19,6)) AS U_AddtlCharges2,
        PRICING.U_GrossProfitC AS U_GrossProfitC,
        CAST(((SELECT value FROM @GrossClientRatesTax WHERE id = POD.U_BookingNumber) 
        - (SELECT value FROM @GrossTruckerRatesTax WHERE id = POD.U_BookingNumber)) AS NUMERIC(19,6)) AS U_GrossProfitNet,
        CAST((SELECT value FROM @TotalInitialClient WHERE id = POD.U_BookingNumber) AS NUMERIC(19,6)) AS U_TotalInitialClient,
        CAST((SELECT value FROM @TotalInitialTruckers WHERE id = POD.U_BookingNumber) AS NUMERIC(19,6)) AS U_TotalInitialTruckers,
        CAST((SELECT value FROM @TotalInitialClient WHERE id = POD.U_BookingNumber) 
        - (SELECT value FROM @TotalInitialTruckers WHERE id = POD.U_BookingNumber) AS NUMERIC(19,6)) AS U_TotalGrossProfit,
        PRICING.U_ClientTag AS U_ClientTag2,
        client.CardName AS U_ClientName,
        POD.U_SAPClient,
        POD.U_SAPClient AS U_ClientTag,
        ISNULL(client.U_GroupLocation, PRICING.U_ClientProject) AS U_ClientProject,
        CASE
            WHEN ISNULL(client.VatStatus,'Y') = 'Y' THEN 'VAT' ELSE 'NONVAT'
        END AS U_ClientVatStatus,
        trucker.CardName AS U_TruckerName,
        POD.U_SAPTrucker AS U_TruckerSAP,
        POD.U_SAPTrucker AS U_TruckerTag,
        CASE
            WHEN ISNULL(trucker.VatStatus,'Y') = 'Y' THEN 'VAT' ELSE 'NONVAT'
        END AS U_TruckerVatStatus,
        TP.U_TPStatus,
        CAST(DATEADD(day, 15, POD.U_BookingDate) AS DATE) AS U_Aging,
        POD.U_ISLAND,
        POD.U_ISLAND_D,
        POD.U_IFINTERISLAND,
        CAST(POD.U_VERIFICATION_TAT AS nvarchar(50)) AS U_VERIFICATION_TAT,
        CAST(POD.U_POD_TAT AS nvarchar(50)) AS U_POD_TAT,
        CAST(POD.U_ActualDateRec_Intitial AS DATE),
        POD.U_SAPTrucker,
        POD.U_PlateNumber,
        POD.U_VehicleTypeCap,
        POD.U_DeliveryStatus,
        CAST(POD.U_DeliveryDateDTR AS DATE),
        CAST(POD.U_DeliveryDatePOD AS DATE),
        POD.U_NoOfDrops,
        POD.U_TripType,
        POD.U_Receivedby,
        CAST(POD.U_ClientReceivedDate AS DATE),
        CAST(POD.U_InitialHCRecDate AS DATE),
        CAST(POD.U_ActualHCRecDate AS DATE),
        CAST(POD.U_DateReturned AS DATE),
        POD.U_PODinCharge,
        CAST(POD.U_VerifiedDateHC AS DATE),
        POD.U_PTFNo,
        CAST(POD.U_DateForwardedBT AS DATE),
        CAST(POD.U_BillingDeadline AS DATE),
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
        END AS U_BillingStatus,
        POD.U_SINo,
        BILLING.U_BillingTeam As bi_U_BillingTeam,
        POD.U_BillingTeam As U_BillingTeam,
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
            WHEN ISNULL(POD.U_DayOfTheWeek,'') = '' THEN DATENAME(dw, POD.U_BookingDate)
            ELSE POD.U_DayOfTheWeek 
        END AS U_DayOfTheWeek,
        POD.U_TimeIn,
        POD.U_TimeOut,
        POD.U_TotalNoExceed,
        POD.U_TotalNoExceed AS U_TotalExceed,
        POD.U_ODOIn,
        POD.U_ODOOut,
        POD.U_TotalUsage,
        CASE 
            WHEN ISNULL(POD.U_ClientReceivedDate,'') = '' THEN 'PENDING' 
            ELSE 'SUBMITTED' 
        END AS U_ClientSubStatus,
        TF.U_ClientSubOverdue AS U_ClientSubOverdue,
        TF.U_ClientPenaltyCalc AS U_ClientPenaltyCalc,
        (SELECT value FROM @PODStatusPayment WHERE id = POD.U_BookingNumber) AS U_PODStatusPayment,
        '' AS U_ProofOfPayment,
        CAST((SELECT value FROM @TotalRecClients WHERE id = POD.U_BookingNumber) AS NUMERIC(19,6)) AS U_TotalRecClients,
        BILLING.U_CheckingTotalBilled,
        BILLING.U_Checking,
        BILLING.U_CWT2307,
        BILLING.U_SOLineNum,
        BILLING.U_ARInvLineNum,
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
        - (SELECT value FROM @TOTALDEDUCTIONS WHERE id = POD.U_BookingNumber)) AS NUMERIC(19,6)) AS U_TotalPayable,
        ISNULL(TF.U_TotalSubPenalty, 0) AS U_TotalSubPenalty,
        CASE 
            WHEN substring(TP.U_PVNo, 1, 2) <> ' ,' THEN TP.U_PVNo
            ELSE substring(TP.U_PVNo, 3, 100)
        END AS U_PVNo,
        TP.U_TPincharge,
        ISNULL(TP.U_CAandDP,0) AS U_CAandDP,
        ISNULL(TP.U_Interest,0) AS U_Interest,
        ISNULL(TP.U_OtherDeductions,0) AS U_OtherDeductions,
        CAST((SELECT value FROM @TOTALDEDUCTIONS WHERE id = POD.U_BookingNumber) AS NUMERIC(19,6)) AS U_TOTALDEDUCTIONS,
        TP.U_REMARKS1,
        CAST((SELECT value FROM @TotalAR WHERE id = POD.U_BookingNumber) AS NUMERIC(19,6)) AS U_TotalAR,
        CAST((SELECT value FROM @TotalAR WHERE id = POD.U_BookingNumber) 
        - (SELECT value FROM @TotalRecClients WHERE id = POD.U_BookingNumber) AS NUMERIC(19,6)) AS U_VarAR,
        TF.U_TotalAP,
        TF.U_VarTP AS U_VarTP,
        '' AS U_APInvLineNum,
        CAST((SELECT value FROM @PODSubmitDeadline WHERE id = POD.U_BookingNumber) AS DATE) AS U_PODSubmitDeadline,
        (SELECT value FROM @OverdueDays WHERE id = POD.U_BookingNumber) AS U_OverdueDays,
        TF.U_InteluckPenaltyCalc,
        POD.U_WaivedDays,
        POD.U_HolidayOrWeekend,
        TP.U_EWT2307,
        TF.U_LostPenaltyCalc,
        CAST((SELECT value FROM @TotalSubPenalties WHERE id = POD.U_BookingNumber) AS NUMERIC(19,6)) AS U_TotalSubPenalties,
        CASE 
            WHEN ISNULL(POD.U_Waived,'') = '' THEN 'N' 
            ELSE POD.U_Waived 
        END AS U_Waived,
        POD.U_PercPenaltyCharge,
        POD.U_Approvedby,
        ISNULL(TF.U_TotalPenaltyWaived, 0) AS U_TotalPenaltyWaived,
        CAST((SELECT value FROM @TotalPenalty WHERE id = POD.U_BookingNumber) AS NUMERIC(19,6)) AS U_TotalPenalty,
        ISNULL(TP.U_TotalPayableRec, 0) AS U_TotalPayableRec,
        CASE 
            WHEN TF.U_DocNum IS NULL OR TF.U_DocNum = '' THEN TF.U_Paid
            ELSE 
                CASE 
                    WHEN TF.U_Paid IS NULL OR TF.U_Paid = '' THEN TF.U_DocNum 
                    ELSE CONCAT(TF.U_DocNum, ', ', TF.U_Paid)
                END
        END As su_U_APDocNum,
        TF.U_DocNum As pr_U_APDocNum,
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
            WHERE line.ItemCode = POD.U_BookingNumber
                AND header.CANCELED = 'N'
            FOR XML PATH (''), TYPE
                    ).value('text()[1]','nvarchar(max)'), 2, 1000) DocEntry
        FROM OINV header
            LEFT JOIN INV1 line ON line.DocEntry = header.DocEntry
        WHERE line.ItemCode = POD.U_BookingNumber
            AND header.CANCELED = 'N') as nvarchar(500)
        ) AS U_InvoiceNo,
        CAST(SUBSTRING((
                    SELECT DISTINCT CONCAT(', ', header.DocNum)  AS [text()]
        FROM INV1 line WITH (NOLOCK)
            LEFT JOIN (SELECT DocEntry, DocNum, CANCELED FROM OINV WITH (NOLOCK)) header ON header.DocEntry = line.DocEntry
        WHERE line.ItemCode = POD.U_BookingNumber
            AND header.CANCELED = 'N'
        FOR XML PATH (''), TYPE
                ).value('text()[1]','nvarchar(max)'), 2, 1000) as nvarchar(500)) As U_ARDocNum,
        CAST(POD.U_DocNum as nvarchar(500)) AS po_U_DocNum,
        TF.U_DocNum AS tp_U_DocNum,
        CAST(SUBSTRING((
                    SELECT DISTINCT CONCAT(', ', header.DocNum)  AS [text()]
        FROM INV1 line WITH (NOLOCK)
            LEFT JOIN (SELECT DocEntry, DocNum, CANCELED FROM OINV WITH (NOLOCK)) header ON header.DocEntry = line.DocEntry
        WHERE line.ItemCode = POD.U_BookingNumber
            AND header.CANCELED = 'N'
        FOR XML PATH (''), TYPE
                ).value('text()[1]','nvarchar(max)'), 2, 1000) as nvarchar(500)) AS U_DocNum,
        TF.U_Paid,
        SUBSTRING((
            SELECT
                CONCAT(', ', T0.U_OR_Ref) AS [text()]
            FROM OPCH T0 WITH (NOLOCK)
            WHERE T0.Canceled <> 'Y' AND T0.DocNum IN (SELECT RTRIM(LTRIM(value)) AS DocNum FROM STRING_SPLIT(TF.U_Paid, ','))
            FOR XML PATH (''), TYPE).value('text()[1]','nvarchar(max)'), 2, 1000
        ) AS U_ORRefNo,
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
        ) AS U_ActualPaymentDate,
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
        CAST(POD.U_Remarks as nvarchar(500)) AS U_Remarks,
        CAST(TP.U_Remarks as nvarchar(500)) AS tp_U_Remarks,
        ISNULL(CAST(client.U_GroupLocation as nvarchar(500)), '') AS U_GroupProject,
        CAST(POD.U_Attachment as nvarchar(500)) AS U_Attachment,
        CAST(POD.U_DeliveryOrigin as nvarchar(500)) AS U_DeliveryOrigin,
        CAST(POD.U_Destination as nvarchar(500)) AS U_Destination,
        CAST(POD.U_OtherPODDoc as nvarchar(4000)) AS U_OtherPODDoc,
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
    WHERE POD.U_BookingNumber IN (SELECT item FROM @BookingIdList);

  RETURN
END;