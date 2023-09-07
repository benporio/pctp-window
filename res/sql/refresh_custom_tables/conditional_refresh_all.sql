DROP TABLE IF EXISTS TMP_TARGET_$serial
SELECT
*
INTO TMP_TARGET_$serial 
FROM (
    -----> issue #30
	SELECT DISTINCT 
		BILLING.U_BookingId AS U_BookingNumber,
        'SO-RELATED-BN' AS ISSUE
	FROM [@PCTP_BILLING] BILLING WITH(NOLOCK)
	-- LEFT JOIN [@PCTP_POD] POD ON POD.U_BookingNumber = BILLING.U_BookingId
	WHERE EXISTS(
		SELECT
			1
		FROM ORDR header WITH(NOLOCK)
			LEFT JOIN RDR1 line ON line.DocEntry = header.DocEntry
		WHERE line.ItemCode = BILLING.U_BookingId
			AND header.CANCELED = 'N'
			AND header.DocNum IN (3698)
	)
	UNION
    -----> issue #20
    SELECT
        SE.U_BookingNumber,
        'SUMMARY-BILLING-DATA-INCONSISTENCY' AS ISSUE
    FROM SUMMARY_EXTRACT SE WITH(NOLOCK)
    LEFT JOIN BILLING_EXTRACT BE ON BE.U_BookingId = SE.U_BookingNumber
    WHERE ((
        (BE.U_BillingStatus <> SE.U_BillingStatus AND REPLACE(BE.U_BillingStatus, ' ', '') <> REPLACE(SE.U_BillingStatus, ' ', '')) 
        OR (
            (
                BE.U_BillingStatus IS NOT NULL AND REPLACE(BE.U_BillingStatus, ' ', '') <> '' 
                AND (SE.U_BillingStatus IS NULL OR REPLACE(SE.U_BillingStatus, ' ', '') = '')
            )
            OR (
                SE.U_BillingStatus IS NOT NULL AND REPLACE(SE.U_BillingStatus, ' ', '') <> '' 
                AND (BE.U_BillingStatus IS NULL OR REPLACE(BE.U_BillingStatus, ' ', '') = '')
            )
        )
    )
    OR (
		(BE.U_InvoiceNo <> SE.U_InvoiceNo AND REPLACE(BE.U_InvoiceNo, ' ', '') <> REPLACE(SE.U_InvoiceNo, ' ', '')) 
		OR (
			(
				BE.U_InvoiceNo IS NOT NULL AND REPLACE(BE.U_InvoiceNo, ' ', '') <> '' 
				AND (SE.U_InvoiceNo IS NULL OR REPLACE(SE.U_InvoiceNo, ' ', '') = '')
			)
			OR (
				SE.U_InvoiceNo IS NOT NULL AND REPLACE(SE.U_InvoiceNo, ' ', '') <> '' 
				AND (BE.U_InvoiceNo IS NULL OR REPLACE(BE.U_InvoiceNo, ' ', '') = '')
			)
		)
	)
	-- OR BE.U_InvoiceNo <> SE.U_InvoiceNo
	OR (
		(BE.U_PODSONum <> SE.U_PODSONum AND REPLACE(BE.U_PODSONum, ' ', '') <> REPLACE(SE.U_PODSONum, ' ', '')) 
		OR (
			(
				BE.U_PODSONum IS NOT NULL AND REPLACE(BE.U_PODSONum, ' ', '') <> '' 
				AND (SE.U_PODSONum IS NULL OR REPLACE(SE.U_PODSONum, ' ', '') = '')
			)
			OR (
				SE.U_PODSONum IS NOT NULL AND REPLACE(SE.U_PODSONum, ' ', '') <> '' 
				AND (BE.U_PODSONum IS NULL OR REPLACE(BE.U_PODSONum, ' ', '') = '')
			)
		)
	)
	-- OR BE.U_PODSONum <> SE.U_PODSONum
	OR (
		(BE.U_DocNum <> SE.U_ARDocNum AND REPLACE(BE.U_DocNum, ' ', '') <> REPLACE(SE.U_ARDocNum, ' ', '')) 
		OR (
			(
				BE.U_DocNum IS NOT NULL AND REPLACE(BE.U_DocNum, ' ', '') <> '' 
				AND (SE.U_ARDocNum IS NULL OR REPLACE(SE.U_ARDocNum, ' ', '') = '')
			)
			OR (
				SE.U_ARDocNum IS NOT NULL AND REPLACE(SE.U_ARDocNum, ' ', '') <> '' 
				AND (BE.U_DocNum IS NULL OR REPLACE(BE.U_DocNum, ' ', '') = '')
			)
		)
	))
	AND BE.U_BookingId IS NOT NULL
	--AND SE.U_BookingDate >= '2023-07-01'
	--AND SE.U_BookingDate <= '2023-08-30'

    UNION
    -----> issue #22
    SELECT
        T0.U_BookingNumber,
        'TP-BILLING-VERIFIED-NOT-REFLECTED' AS ISSUE
    FROM [dbo].[@PCTP_POD] T0 WITH(NOLOCK)
    WHERE 1=1
    AND (CAST(T0.U_PODStatusDetail as nvarchar(max)) LIKE '%Verified%' OR CAST(T0.U_PODStatusDetail as nvarchar(max)) LIKE '%ForAdvanceBilling%')
    AND T0.U_BookingNumber NOT IN (SELECT U_BookingId FROM BILLING_EXTRACT WITH(NOLOCK))
    UNION
    SELECT
        T0.U_BookingNumber,
        'TP-BILLING-VERIFIED-NOT-REFLECTED' AS ISSUE
    FROM [dbo].[@PCTP_POD] T0 WITH(NOLOCK)
    WHERE 1=1
    AND (CAST(T0.U_PODStatusDetail as nvarchar(max)) LIKE '%Verified%')
    AND T0.U_BookingNumber NOT IN (SELECT U_BookingId FROM TP_EXTRACT WITH(NOLOCK))

    UNION
    -----> issue #23
    SELECT
        BE.U_BookingId AS U_BookingNumber,
        'BILLING-TP-PRICING-DATA-INCONSISTENCY' AS ISSUE
    FROM BILLING_EXTRACT BE WITH(NOLOCK)
    LEFT JOIN PRICING_EXTRACT PE ON PE.U_BookingId = BE.U_BookingId
    WHERE (
        TRY_PARSE(PE.U_GrossClientRatesTax AS FLOAT) <> TRY_PARSE(BE.U_GrossInitialRate AS FLOAT)
        OR TRY_PARSE(PE.U_Demurrage AS FLOAT) <> TRY_PARSE(BE.U_Demurrage AS FLOAT)
        OR TRY_PARSE(PE.U_TotalAddtlCharges AS FLOAT) <> TRY_PARSE(BE.U_AddCharges AS FLOAT)
        OR ((
                (TRY_PARSE(PE.U_GrossClientRatesTax AS FLOAT) IS NOT NULL AND TRY_PARSE(PE.U_GrossClientRatesTax AS FLOAT) <> 0)
                AND (TRY_PARSE(BE.U_GrossInitialRate AS FLOAT) IS NULL OR TRY_PARSE(BE.U_GrossInitialRate AS FLOAT) = 0)
            )
            OR (
                (TRY_PARSE(PE.U_Demurrage AS FLOAT) IS NOT NULL AND TRY_PARSE(PE.U_Demurrage AS FLOAT) <> 0)
                AND (TRY_PARSE(BE.U_Demurrage AS FLOAT) IS NULL OR TRY_PARSE(BE.U_Demurrage AS FLOAT) = 0)
            )
            OR (
                (TRY_PARSE(PE.U_TotalAddtlCharges AS FLOAT) IS NOT NULL AND TRY_PARSE(PE.U_TotalAddtlCharges AS FLOAT) <> 0)
                AND (TRY_PARSE(BE.U_AddCharges AS FLOAT) IS NULL OR TRY_PARSE(BE.U_AddCharges AS FLOAT) = 0)
        ))
    )
    UNION
    SELECT
        TE.U_BookingId AS U_BookingNumber,
        'BILLING-TP-PRICING-DATA-INCONSISTENCY' AS ISSUE
    FROM TP_EXTRACT TE WITH(NOLOCK)
    LEFT JOIN PRICING_EXTRACT PE ON PE.U_BookingId = TE.U_BookingId
    WHERE (
        TRY_PARSE(PE.U_GrossTruckerRates AS FLOAT) <> TRY_PARSE(TE.U_GrossTruckerRates AS FLOAT)
        OR TRY_PARSE(PE.U_GrossTruckerRatesTax AS FLOAT) <> TRY_PARSE(TE.U_GrossTruckerRatesN AS FLOAT)
        OR TRY_PARSE(PE.U_RateBasisT AS FLOAT) <> TRY_PARSE(TE.U_RateBasis AS FLOAT)
        OR TRY_PARSE(PE.U_Demurrage2 AS FLOAT) <> TRY_PARSE(TE.U_Demurrage AS FLOAT)
        OR TRY_PARSE(PE.U_AddtlDrop2 AS FLOAT) <> TRY_PARSE(TE.U_AddtlDrop AS FLOAT)
        OR TRY_PARSE(PE.U_BoomTruck2 AS FLOAT) <> TRY_PARSE(TE.U_BoomTruck AS FLOAT)
        OR TRY_PARSE(PE.U_Manpower2 AS FLOAT) <> TRY_PARSE(TE.U_Manpower AS FLOAT)
        OR TRY_PARSE(PE.U_Backload2 AS FLOAT) <> TRY_PARSE(TE.U_BackLoad AS FLOAT)
        OR TRY_PARSE(PE.U_totalAddtlCharges2 AS FLOAT) <> TRY_PARSE(TE.U_Addtlcharges AS FLOAT)
        OR TRY_PARSE(PE.U_Demurrage3 AS FLOAT) <> TRY_PARSE(TE.U_DemurrageN AS FLOAT)
        OR TRY_PARSE(PE.U_AddtlCharges AS FLOAT) <> TRY_PARSE(TE.U_AddtlChargesN AS FLOAT)
        OR ((
                (TRY_PARSE(PE.U_GrossTruckerRates AS FLOAT) IS NOT NULL AND TRY_PARSE(PE.U_GrossTruckerRates AS FLOAT) <> 0)
                AND (TRY_PARSE(TE.U_GrossTruckerRates AS FLOAT) IS NULL OR TRY_PARSE(TE.U_GrossTruckerRates AS FLOAT) = 0)
            )
            OR (
                (TRY_PARSE(PE.U_GrossTruckerRatesTax AS FLOAT) IS NOT NULL AND TRY_PARSE(PE.U_GrossTruckerRatesTax AS FLOAT) <> 0)
                AND (TRY_PARSE(TE.U_GrossTruckerRatesN AS FLOAT) IS NULL OR TRY_PARSE(TE.U_GrossTruckerRatesN AS FLOAT) = 0)
            )
            OR (
                (TRY_PARSE(PE.U_RateBasisT AS FLOAT) IS NOT NULL AND TRY_PARSE(PE.U_RateBasisT AS FLOAT) <> '')
                AND (TRY_PARSE(TE.U_RateBasis AS FLOAT) IS NULL OR TRY_PARSE(TE.U_RateBasis AS FLOAT) = '')
            )
            OR (
                (TRY_PARSE(PE.U_Demurrage2 AS FLOAT) IS NOT NULL AND TRY_PARSE(PE.U_Demurrage2 AS FLOAT) <> 0)
                AND (TRY_PARSE(TE.U_Demurrage AS FLOAT) IS NULL OR TRY_PARSE(TE.U_Demurrage AS FLOAT) = 0)
            )
            OR (
                (TRY_PARSE(PE.U_AddtlDrop2 AS FLOAT) IS NOT NULL AND TRY_PARSE(PE.U_AddtlDrop2 AS FLOAT) <> 0)
                AND (TRY_PARSE(TE.U_AddtlDrop AS FLOAT) IS NULL OR TRY_PARSE(TE.U_AddtlDrop AS FLOAT) = 0)
            )
            OR (
                (TRY_PARSE(PE.U_BoomTruck2 AS FLOAT) IS NOT NULL AND TRY_PARSE(PE.U_BoomTruck2 AS FLOAT) <> 0)
                AND (TRY_PARSE(TE.U_BoomTruck AS FLOAT) IS NULL OR TRY_PARSE(TE.U_BoomTruck AS FLOAT) = 0)
            )
            OR (
                (TRY_PARSE(PE.U_Manpower2 AS FLOAT) IS NOT NULL AND TRY_PARSE(PE.U_Manpower2 AS FLOAT) <> 0)
                AND (TRY_PARSE(TE.U_Manpower AS FLOAT) IS NULL OR TRY_PARSE(TE.U_Manpower AS FLOAT) = 0)
            )
            OR (
                (TRY_PARSE(PE.U_Backload2 AS FLOAT) IS NOT NULL AND TRY_PARSE(PE.U_Backload2 AS FLOAT) <> 0)
                AND (TRY_PARSE(TE.U_BackLoad AS FLOAT) IS NULL OR TRY_PARSE(TE.U_BackLoad AS FLOAT) = 0)
            )
            OR (
                (TRY_PARSE(PE.U_totalAddtlCharges2 AS FLOAT) IS NOT NULL AND TRY_PARSE(PE.U_totalAddtlCharges2 AS FLOAT) <> 0)
                AND (TRY_PARSE(TE.U_Addtlcharges AS FLOAT) IS NULL OR TRY_PARSE(TE.U_Addtlcharges AS FLOAT) = 0)
            )
            OR (
                (TRY_PARSE(PE.U_Demurrage3 AS FLOAT) IS NOT NULL AND TRY_PARSE(PE.U_Demurrage3 AS FLOAT) <> 0)
                AND (TRY_PARSE(TE.U_DemurrageN AS FLOAT) IS NULL OR TRY_PARSE(TE.U_DemurrageN AS FLOAT) = 0)
            )
            OR (
                (TRY_PARSE(PE.U_AddtlCharges AS FLOAT) IS NOT NULL AND TRY_PARSE(PE.U_AddtlCharges AS FLOAT) <> 0)
                AND (TRY_PARSE(TE.U_AddtlChargesN AS FLOAT) IS NULL OR TRY_PARSE(TE.U_AddtlChargesN AS FLOAT) = 0)
        ))
    )

    UNION
    -----> issue #27
    SELECT 
        U_BookingNumber,
        'DUPLICATE' AS ISSUE 
    FROM SUMMARY_EXTRACT WITH(NOLOCK) GROUP BY U_BookingNumber HAVING COUNT(*) > 1
    UNION
    SELECT 
        U_BookingNumber,
        'DUPLICATE' AS ISSUE 
    FROM POD_EXTRACT WITH(NOLOCK) GROUP BY U_BookingNumber HAVING COUNT(*) > 1
    UNION
    SELECT 
        U_BookingNumber,
        'DUPLICATE' AS ISSUE 
    FROM BILLING_EXTRACT WITH(NOLOCK) GROUP BY U_BookingNumber HAVING COUNT(*) > 1
    UNION
    SELECT 
        U_BookingNumber,
        'DUPLICATE' AS ISSUE 
    FROM TP_EXTRACT WITH(NOLOCK) GROUP BY U_BookingNumber HAVING COUNT(*) > 1
    UNION
    SELECT 
        U_BookingNumber,
        'DUPLICATE' AS ISSUE 
    FROM PRICING_EXTRACT WITH(NOLOCK) GROUP BY U_BookingNumber HAVING COUNT(*) > 1
    
) CONDITIONAL_TARGETS
-- LEFT JOIN (SELECT U_BookingNumber, U_BookingDate FROM [@PCTP_POD]) X ON X.U_BookingNumber = CONDITIONAL_TARGETS.U_BookingNumber
WHERE U_BookingNumber IS NOT NULL
-- ORDER BY U_BookingDate DESC, ISSUE ASC
;

UPDATE [@FirstratesTP] 
SET U_Amount = NULL
WHERE U_Amount = 'NaN' AND U_BN IN (SELECT U_BookingNumber FROM TMP_TARGET_$serial WITH (NOLOCK));

UPDATE [@FirstratesTP] 
SET U_AddlAmount = NULL
WHERE U_AddlAmount = 'NaN' AND U_BN IN (SELECT U_BookingNumber FROM TMP_TARGET_$serial WITH (NOLOCK));

DECLARE @BookingIdsCSV NVARCHAR(MAX);
SET @BookingIdsCSV = SUBSTRING((
    SELECT  
        CONCAT(', ', U_BookingNumber) AS [text()]
    FROM TMP_TARGET_$serial WITH (NOLOCK)
    FOR XML PATH (''), TYPE).value('text()[1]','nvarchar(max)'), 2, 10000000
);

-----> SUMMARY
DELETE FROM SUMMARY_EXTRACT WHERE U_BookingNumber IN (SELECT U_BookingNumber FROM TMP_TARGET_$serial WITH (NOLOCK));

INSERT INTO SUMMARY_EXTRACT
SELECT
    X.Code, X.U_BookingNumber, X.U_BookingDate, X.U_ClientName, X.U_SAPClient, X.U_ClientVatStatus, X.U_TruckerName, X.U_SAPTrucker, X.U_TruckerVatStatus, X.U_VehicleTypeCap, X.U_ISLAND, X.U_ISLAND_D, X.U_IFINTERISLAND, X.U_DeliveryStatus, X.U_DeliveryDateDTR,
    X.U_DeliveryDatePOD, X.U_ClientReceivedDate, X.U_ActualDateRec_Intitial, X.U_InitialHCRecDate, X.U_ActualHCRecDate, X.U_DateReturned, X.U_VerifiedDateHC, X.U_PTFNo, X.U_DateForwardedBT, X.U_PODSONum, X.U_GrossClientRates,
    X.U_GrossClientRatesTax, X.U_GrossTruckerRates, X.U_GrossTruckerRatesTax, X.U_GrossProfitNet, X.U_TotalInitialClient, X.U_TotalInitialTruckers, X.U_TotalGrossProfit, X.U_BillingStatus, X.U_PODStatusPayment, X.U_PaymentReference,
    X.U_PaymentStatus, X.U_ProofOfPayment, X.U_TotalRecClients, X.U_TotalPayable, X.U_PVNo, X.U_TotalAR, X.U_VarAR, X.U_TotalAP, X.U_VarTP, X.U_APDocNum, X.U_ARDocNum, X.U_DeliveryOrigin, X.U_Destination, X.U_PODStatusDetail, X.U_Remarks, X.U_WaybillNo, X.U_ServiceType,
    X.U_InvoiceNo
FROM [dbo].fetchPctpDataRows('SUMMARY', @BookingIdsCSV, DEFAULT) X;

-----> POD
DELETE FROM POD_EXTRACT WHERE U_BookingNumber IN (SELECT U_BookingNumber FROM TMP_TARGET_$serial WITH (NOLOCK));

INSERT INTO POD_EXTRACT
SELECT
    X.DisableTableRow, X.Code, X.U_BookingDate, X.U_BookingNumber, X.U_PODSONum, X.U_ClientName, X.U_SAPClient, X.U_TruckerName, X.U_ISLAND, X.U_ISLAND_D, 
    X.U_IFINTERISLAND, X.U_VERIFICATION_TAT, X.U_POD_TAT, X.U_ActualDateRec_Intitial, X.U_SAPTrucker, X.U_PlateNumber, X.U_VehicleTypeCap, 
    X.U_DeliveryStatus, X.U_DeliveryDateDTR, X.U_DeliveryDatePOD, X.U_NoOfDrops, X.U_TripType, X.U_Receivedby, X.U_ClientReceivedDate, 
    X.U_InitialHCRecDate, X.U_ActualHCRecDate, X.U_DateReturned, X.U_PODinCharge, X.U_VerifiedDateHC, X.U_PTFNo, X.U_DateForwardedBT, X.U_BillingDeadline, 
    X.U_BillingStatus, X.U_ServiceType, X.U_SINo, X.U_BillingTeam, X.U_SOBNumber, X.U_ForwardLoad, X.U_BackLoad, X.U_TypeOfAccessorial, X.U_TimeInEmptyDem, 
    X.U_TimeOutEmptyDem, X.U_VerifiedEmptyDem, X.U_TimeInLoadedDem, X.U_TimeOutLoadedDem, X.U_VerifiedLoadedDem, X.U_TimeInAdvLoading, X.U_PenaltiesManual, 
    X.U_DayOfTheWeek, X.U_TimeIn, X.U_TimeOut, X.U_TotalNoExceed, X.U_ODOIn, X.U_ODOOut, X.U_TotalUsage, X.U_ClientSubStatus, X.U_ClientSubOverdue, 
    X.U_ClientPenaltyCalc, X.U_PODStatusPayment, X.U_PODSubmitDeadline, X.U_OverdueDays, X.U_InteluckPenaltyCalc, X.U_WaivedDays, X.U_HolidayOrWeekend, 
    X.U_LostPenaltyCalc, X.U_TotalSubPenalties, X.U_Waived, X.U_PercPenaltyCharge, X.U_Approvedby, X.U_TotalPenaltyWaived, X.U_GroupProject, X.U_Attachment, X.U_DeliveryOrigin, X.U_Destination, X.U_Remarks, X.U_OtherPODDoc, X.U_RemarksPOD, 
    X.U_PODStatusDetail, X.U_BTRemarks, X.U_DestinationClient, X.U_Remarks2, X.U_DocNum, X.U_TripTicketNo, X.U_WaybillNo, X.U_ShipmentNo, X.U_DeliveryReceiptNo, 
    X.U_SeriesNo, X.U_OutletNo, X.U_CBM, X.U_SI_DRNo, X.U_DeliveryMode, X.U_SourceWhse, X.U_SONo, X.U_NameCustomer, X.U_CategoryDR, X.U_IDNumber, X.U_ApprovalStatus, 
    X.U_TotalInvAmount
FROM [dbo].fetchPctpDataRows('POD', @BookingIdsCSV, DEFAULT) X;

-----> BILLING
DELETE FROM BILLING_EXTRACT WHERE U_BookingNumber IN (SELECT U_BookingNumber FROM TMP_TARGET_$serial WITH (NOLOCK));

INSERT INTO BILLING_EXTRACT
SELECT
    X.U_BookingNumber, X.DisableTableRow, X.DisableSomeFields, X.Code, X.U_BookingId, X.U_BookingDate, X.U_PODNum, X.U_PODSONum, X.U_CustomerName, X.U_SAPClient, X.U_PlateNumber, X.U_VehicleTypeCap, X.U_DeliveryStatus, X.U_DeliveryDatePOD,
    X.U_NoOfDrops, X.U_TripType, X.U_ClientReceivedDate, X.U_ActualHCRecDate, X.U_PODinCharge, X.U_VerifiedDateHC, X.U_PTFNo, X.U_DateForwardedBT, X.U_BillingDeadline, X.U_BillingStatus, X.U_BillingTeam, X.U_GrossInitialRate, X.U_Demurrage,
    X.U_AddCharges, X.U_ActualBilledRate, X.U_RateAdjustments, X.U_ActualDemurrage, X.U_ActualAddCharges, X.U_TotalRecClients, X.U_CheckingTotalBilled, X.U_Checking, X.U_CWT2307, X.U_SOBNumber, X.U_ForwardLoad, X.U_BackLoad,
    X.U_TypeOfAccessorial, X.U_TimeInEmptyDem, X.U_TimeOutEmptyDem, X.U_VerifiedEmptyDem, X.U_TimeInLoadedDem, X.U_TimeOutLoadedDem, X.U_VerifiedLoadedDem, X.U_TimeInAdvLoading, X.U_DayOfTheWeek, X.U_TimeIn, X.U_TimeOut,
    X.U_TotalExceed, X.U_ODOIn, X.U_ODOOut, X.U_TotalUsage, X.U_SOLineNum, X.U_ARInvLineNum, X.U_TotalAR, X.U_VarAR, X.U_ServiceType, X.U_DocNum, X.U_InvoiceNo, X.U_DeliveryReceiptNo, X.U_SeriesNo, X.U_GroupProject, X.U_DeliveryOrigin,
    X.U_Destination, X.U_OtherPODDoc, X.U_RemarksPOD, X.U_PODStatusDetail, X.U_BTRemarks, X.U_DestinationClient, X.U_Remarks, X.U_Attachment, X.U_SI_DRNo, X.U_TripTicketNo, X.U_WaybillNo, X.U_ShipmentManifestNo, X.U_OutletNo, X.U_CBM,
    X.U_DeliveryMode, X.U_SourceWhse, X.U_SONo, X.U_NameCustomer, X.U_CategoryDR, X.U_IDNumber, X.U_Status, X.U_TotalInvAmount
FROM [dbo].fetchPctpDataRows('BILLING', @BookingIdsCSV, DEFAULT) X;

-----> TP
DELETE FROM TP_EXTRACT WHERE U_BookingNumber IN (SELECT U_BookingNumber FROM TMP_TARGET_$serial WITH (NOLOCK));

INSERT INTO TP_EXTRACT
SELECT
    '' AS WaivedDaysx, '' AS xHolidayOrWeekend,
    X.DisableTableRow, X.U_BookingNumber, X.DisableSomeFields, X.Code, X.U_BookingId, X.U_BookingDate, X.U_PODNum, X.U_PODSONum, X.U_ClientName, X.U_TruckerName, X.U_TruckerSAP, X.U_PlateNumber, X.U_VehicleTypeCap, X.U_ISLAND, X.U_ISLAND_D, 
    X.U_IFINTERISLAND, X.U_DeliveryStatus, X.U_DeliveryDatePOD, X.U_NoOfDrops, X.U_TripType, X.U_Receivedby, X.U_ClientReceivedDate, X.U_ActualDateRec_Intitial, X.U_ActualHCRecDate, X.U_DateReturned, X.U_PODinCharge, X.U_VerifiedDateHC, 
    X.U_TPStatus, X.U_Aging, X.U_GrossTruckerRates, X.U_RateBasis, X.U_GrossTruckerRatesN, X.U_TaxType, X.U_Demurrage, X.U_AddtlDrop, X.U_BoomTruck, X.U_BoomTruck2, X.U_Manpower, X.U_BackLoad, X.U_Addtlcharges, X.U_DemurrageN, 
    X.U_AddtlChargesN, X.U_ActualRates, X.U_RateAdjustments, X.U_ActualDemurrage, X.U_ActualCharges, X.U_OtherCharges, X.U_ClientSubOverdue, X.U_ClientPenaltyCalc, X.U_InteluckPenaltyCalc, 
    X.U_InitialHCRecDate, X.U_DeliveryDateDTR, X.U_TotalInitialTruckers, X.U_LostPenaltyCalc, X.U_TotalSubPenalty, X.U_TotalPenaltyWaived, X.U_TotalPenalty, X.U_TotalPayable, X.U_EWT2307, X.U_TotalPayableRec, X.U_PVNo, X.U_ORRefNo, X.U_TPincharge, 
    X.U_CAandDP, X.U_Interest, X.U_OtherDeductions, X.U_TOTALDEDUCTIONS, X.U_REMARKS1, X.U_TotalAP, X.U_VarTP, X.U_APInvLineNum, X.U_PercPenaltyCharge, X.U_DocNum, X.U_Paid, X.U_OtherPODDoc, X.U_DeliveryOrigin, X.U_Remarks2, 
    X.U_RemarksPOD, X.U_GroupProject, X.U_Destination, X.U_Remarks, X.U_Attachment, X.U_TripTicketNo, X.U_WaybillNo, X.U_ShipmentManifestNo, X.U_DeliveryReceiptNo, X.U_SeriesNo, X.U_ActualPaymentDate, X.U_PaymentReference, 
    X.U_PaymentStatus
FROM [dbo].fetchPctpDataRows('TP', @BookingIdsCSV, DEFAULT) X;

-----> PRICING
DELETE FROM PRICING_EXTRACT WHERE U_BookingNumber IN (SELECT U_BookingNumber FROM TMP_TARGET_$serial WITH (NOLOCK));

INSERT INTO PRICING_EXTRACT
SELECT
    X.U_BookingNumber, X.DisableSomeFields, X.DisableSomeFields2, X.Code, X.U_BookingId, X.U_BookingDate, X.U_PODNum, X.U_CustomerName, X.U_ClientTag, X.U_ClientProject, X.U_TruckerName, X.U_TruckerTag, X.U_VehicleTypeCap, X.U_DeliveryStatus,
    X.U_TripType, X.U_NoOfDrops, X.U_GrossClientRates, X.U_ISLAND, X.U_ISLAND_D, X.U_IFINTERISLAND, X.U_GrossClientRatesTax, X.U_RateBasis, X.U_TaxType, X.U_GrossProfitNet, X.U_Demurrage, X.U_AddtlDrop, X.U_BoomTruck, X.U_Manpower, X.U_Backload,
    X.U_TotalAddtlCharges, X.U_Demurrage2, X.U_AddtlDrop2, X.U_BoomTruck2, X.U_Manpower2, X.U_Backload2, X.U_totalAddtlCharges2, X.U_Demurrage3, X.U_AddtlCharges, X.U_GrossProfit, X.U_TotalInitialClient, X.U_TotalInitialTruckers, X.U_TotalGrossProfit,
    X.U_ClientTag2, X.U_GrossTruckerRates, X.U_GrossTruckerRatesTax, X.U_RateBasisT, X.U_TaxTypeT, X.U_Demurrage4, X.U_AddtlCharges2, X.U_GrossProfitC, X.U_ActualBilledRate, X.U_BillingRateAdjustments,
    X.U_BillingActualDemurrage, X.U_ActualAddCharges, X.U_TotalRecClients, X.U_TotalAR, X.U_VarAR, X.U_PODSONum, X.U_ActualRates, X.U_TPRateAdjustments, X.U_TPActualDemurrage, X.U_ActualCharges, X.U_TPBoomTruck2, X.U_OtherCharges,
    X.U_TotalPayable, X.U_PVNo, X.U_TotalAP, X.U_VarTP, X.U_APDocNum, X.U_Paid, X.U_DocNum, X.U_DeliveryOrigin, X.U_Destination, X.U_RemarksDTR, X.U_RemarksPOD, X.U_PODDocNum
FROM [dbo].fetchPctpDataRows('PRICING', @BookingIdsCSV, DEFAULT) X;

DROP TABLE IF EXISTS TMP_TARGET_$serial