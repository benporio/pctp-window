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

DELETE FROM PCTP_UNIFIED WHERE U_BookingNumber IN ($bookingIds);

INSERT INTO PCTP_UNIFIED
SELECT su_Code, po_Code, bi_Code, tp_Code, pr_Code, po_DisableTableRow, bi_DisableTableRow, tp_DisableTableRow, bi_DisableSomeFields, tp_DisableSomeFields, pr_DisableSomeFields, pr_DisableSomeFields2, U_BookingDate, 
        U_BookingNumber, bi_U_PODNum, tp_U_PODNum, pr_U_PODNum, U_PODSONum, U_CustomerName, U_GrossClientRates, U_GrossInitialRate, U_Demurrage, tp_U_Demurrage, tp_U_AddtlDrop, pr_U_AddtlDrop, 
        tp_U_BoomTruck, pr_U_BoomTruck, tp_U_BoomTruck2, pr_U_BoomTruck2, U_TPBoomTruck2, tp_U_Manpower, pr_U_Manpower, po_U_BackLoad, tp_U_BackLoad, pr_U_BackLoad, U_TotalAddtlCharges, U_Demurrage2, U_AddtlDrop2, 
        U_Manpower2, U_Backload2, U_totalAddtlCharges2, U_Demurrage3, U_GrossProfit, tp_U_Addtlcharges, pr_U_Addtlcharges, U_DemurrageN, U_AddtlChargesN, U_ActualRates, tp_U_RateAdjustments, bi_U_RateAdjustments, 
        U_TPRateAdjustments, bi_U_ActualDemurrage, tp_U_ActualDemurrage, U_TPActualDemurrage, U_ActualCharges, U_OtherCharges, U_AddCharges, U_ActualBilledRate, U_BillingRateAdjustments, U_BillingActualDemurrage, 
        U_ActualAddCharges, U_GrossClientRatesTax, U_GrossTruckerRates, tp_U_RateBasis, pr_U_RateBasis, U_GrossTruckerRatesN, tp_U_TaxType, pr_U_TaxType, U_GrossTruckerRatesTax, U_RateBasisT, U_TaxTypeT, U_Demurrage4, 
        U_AddtlCharges2, U_GrossProfitC, U_GrossProfitNet, U_TotalInitialClient, U_TotalInitialTruckers, U_TotalGrossProfit, U_ClientTag2, U_ClientName, U_SAPClient, U_ClientTag, U_ClientProject, U_ClientVatStatus, U_TruckerName, 
        U_TruckerSAP, U_TruckerTag, U_TruckerVatStatus, U_TPStatus, U_Aging, U_ISLAND, U_ISLAND_D, U_IFINTERISLAND, U_VERIFICATION_TAT, U_POD_TAT, U_ActualDateRec_Intitial, U_SAPTrucker, U_PlateNumber, U_VehicleTypeCap, 
        U_DeliveryStatus, U_DeliveryDateDTR, U_DeliveryDatePOD, U_NoOfDrops, U_TripType, U_Receivedby, U_ClientReceivedDate, U_InitialHCRecDate, U_ActualHCRecDate, U_DateReturned, U_PODinCharge, U_VerifiedDateHC, U_PTFNo, 
        U_DateForwardedBT, U_BillingDeadline, U_BillingStatus, U_SINo, bi_U_BillingTeam, U_BillingTeam, U_SOBNumber, U_ForwardLoad, U_TypeOfAccessorial, U_TimeInEmptyDem, U_TimeOutEmptyDem, U_VerifiedEmptyDem, 
        U_TimeInLoadedDem, U_TimeOutLoadedDem, U_VerifiedLoadedDem, U_TimeInAdvLoading, U_PenaltiesManual, U_DayOfTheWeek, U_TimeIn, U_TimeOut, U_TotalExceed, U_TotalNoExceed, U_ODOIn, U_ODOOut, U_TotalUsage, 
        U_ClientSubStatus, U_ClientSubOverdue, U_ClientPenaltyCalc, U_PODStatusPayment, U_ProofOfPayment, U_TotalRecClients, U_CheckingTotalBilled, U_Checking, U_CWT2307, U_SOLineNum, U_ARInvLineNum, U_TotalPayable, 
        U_TotalSubPenalty, U_PVNo, U_TPincharge, U_CAandDP, U_Interest, U_OtherDeductions, U_TOTALDEDUCTIONS, U_REMARKS1, U_TotalAR, U_VarAR, U_TotalAP, U_VarTP, U_APInvLineNum, U_PODSubmitDeadline, U_OverdueDays, 
        U_InteluckPenaltyCalc, U_WaivedDays, U_HolidayOrWeekend, U_EWT2307, U_LostPenaltyCalc, U_TotalSubPenalties, U_Waived, U_PercPenaltyCharge, U_Approvedby, U_TotalPenaltyWaived, U_TotalPenalty, U_TotalPayableRec, 
        su_U_APDocNum, pr_U_APDocNum, U_ServiceType, U_InvoiceNo, U_ARDocNum, po_U_DocNum, tp_U_DocNum, U_DocNum, U_Paid, U_ORRefNo, U_ActualPaymentDate, U_PaymentReference, U_PaymentStatus, U_Remarks, 
        tp_U_Remarks, U_GroupProject, U_Attachment, U_DeliveryOrigin, U_Destination, U_OtherPODDoc, U_RemarksPOD, U_PODStatusDetail, U_BTRemarks, U_DestinationClient, U_Remarks2, U_TripTicketNo, U_WaybillNo, U_ShipmentNo, 
        U_ShipmentManifestNo, U_DeliveryReceiptNo, U_SeriesNo, U_OutletNo, U_CBM, U_SI_DRNo, U_DeliveryMode, U_SourceWhse, U_SONo, U_NameCustomer, U_CategoryDR, U_IDNumber, U_ApprovalStatus, U_Status, U_RemarksDTR, 
        U_TotalInvAmount, U_PODDocNum, U_BookingId
FROM [dbo].fetchGenericPctpDataRows(@BookingIdsCSV) X;